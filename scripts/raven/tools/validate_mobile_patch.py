#!/usr/bin/env python3
"""Read-only Raven mobile delta ZIP safety preflight. Inspired by UPDS delta-v1.

No archive contents are executed and this script does not touch GitHub refs.
Usage: python3 validate_mobile_patch.py archive.zip CURRENT_MAIN_SHA [OUTPUT_DIR]
Output directory is optional; only safe declared files are extracted there.
"""
from __future__ import annotations

import json
import re
import shutil
import stat
import sys
import zipfile
from pathlib import Path, PurePosixPath

MAX_ZIP = 25 * 1024 * 1024
MAX_UNPACKED = 250 * 1024 * 1024
MAX_FILES = 1500
PROTECTED = (
    ".github/", ".git/", "AGENTS.md", "CODEX.md", "DEEPSEEK.md",
    "CHATGPT.md", "docs/DECISIONS.md",
    "scripts/raven/tools/validate_mobile_patch.py",
    "incoming/", "dashboard/status.json", "build/", "addons/",
)
FORBIDDEN_PARTS = {".git", ".godot", "node_modules", "dist", ".vite",
                   "coverage", "__pycache__", ".env"}
SHA_RE = re.compile(r"^[0-9a-fA-F]{40}$")


class PatchError(ValueError):
    pass


def secure_path(raw: str) -> str:
    if not isinstance(raw, str) or not raw or "\\" in raw or raw.startswith("/"):
        raise PatchError(f"invalid relative POSIX path: {raw!r}")
    p = PurePosixPath(raw)
    if p.is_absolute() or any(x in ("", ".", "..") for x in p.parts):
        raise PatchError(f"invalid traversal path: {raw!r}")
    if any(x in FORBIDDEN_PARTS for x in p.parts):
        raise PatchError(f"forbidden directory: {raw}")
    name = str(p)
    if name != raw or any(name == x or name.startswith(x) for x in PROTECTED):
        raise PatchError(f"protected or noncanonical path: {raw}")
    if ":" in raw or "\x00" in raw:
        raise PatchError(f"invalid special path: {raw}")
    return name


def preflight(archive: Path, main_sha: str, output_dir: Path | None = None) -> dict:
    if not SHA_RE.fullmatch(main_sha):
        raise PatchError("current main SHA must be a full 40-hex commit")
    if not archive.is_file() or archive.stat().st_size > MAX_ZIP:
        raise PatchError("missing or >25 MiB archive")
    with zipfile.ZipFile(archive) as zf:
        infos = zf.infolist()
        if not infos or len(infos) > MAX_FILES:
            raise PatchError("archive empty or >1500 entries")
        seen = set()
        total = 0
        for info in infos:
            raw = info.filename
            # directories are not allowed: a file-only deterministic patch
            if info.is_dir() or info.flag_bits & 1:
                raise PatchError(f"directory/encrypted archive entry: {raw}")
            if raw.startswith("/") or "\\" in raw or "//" in raw:
                raise PatchError(f"unsafe zip path: {raw}")
            path = PurePosixPath(raw)
            if ".." in path.parts or "." in path.parts:
                raise PatchError(f"archive traversal: {raw}")
            if any(part in FORBIDDEN_PARTS for part in path.parts):
                raise PatchError(f"forbidden ZIP member: {raw}")
            norm = raw.casefold()
            if norm in seen:
                raise PatchError(f"duplicate/case-fold colliding entry: {raw}")
            seen.add(norm)
            mode = (info.external_attr >> 16) & 0xFFFF
            if stat.S_ISLNK(mode) or (mode and not (stat.S_ISREG(mode) or mode & stat.S_IFMT(mode) == 0)):
                raise PatchError(f"nonregular archive entry: {raw}")
            total += info.file_size
            if total > MAX_UNPACKED:
                raise PatchError("ZIP expands beyond 250 MiB")
        try:
            manifest = json.loads(zf.read("patch-manifest.json"))
        except (KeyError, json.JSONDecodeError) as err:
            raise PatchError(f"missing or invalid patch-manifest.json: {err}") from err
        if manifest.get("format") != "raven-delta-v1":
            raise PatchError("only raven-delta-v1 currently supported")
        if manifest.get("baseSha") != main_sha:
            raise PatchError("stale baseSha; rebase/repackage before import")
        feature = manifest.get("feature")
        if not isinstance(feature, str) or not re.fullmatch(r"[A-Za-z0-9._-]{3,64}", feature):
            raise PatchError("invalid feature identifier")
        task_ids = manifest.get("taskIds")
        if not isinstance(task_ids, list) or not task_ids or any(not isinstance(t,str) or not re.fullmatch(r"[A-Za-z0-9-]{4,48}",t) for t in task_ids):
            raise PatchError("taskIds must contain known-format task identifiers")
        files, deletes = manifest.get("files"), manifest.get("delete")
        if not isinstance(files, list) or not isinstance(deletes, list) or not files:
            raise PatchError("files must be nonempty and delete must be an array")
        if len(files) + len(deletes) > MAX_FILES:
            raise PatchError("too many touched files")
        paths = [secure_path(p) for p in [*files, *deletes]]
        if len(set(paths)) != len(paths) or len(set(p.casefold() for p in paths)) != len(paths):
            raise PatchError("duplicate or overlapping changed/deleted paths")
        declared = {"patch-manifest.json", *(f"files/{p}" for p in files)}
        members = set(x.filename for x in infos)
        if members != declared:
            raise PatchError(f"archive members mismatch; extra={sorted(members-declared)[:3]}, missing={sorted(declared-members)[:3]}")
        if output_dir is not None:
            base = output_dir.resolve()
            if not base.exists() or not base.is_dir():
                raise PatchError("output directory must already exist")
            for path in files:
                dest = (base / path).resolve()
                if base not in dest.parents:
                    raise PatchError("output path escapes target")
                if dest.exists() and dest.is_symlink():
                    raise PatchError(f"destination symlink: {path}")
                dest.parent.mkdir(parents=True, exist_ok=True)
                with zf.open(f"files/{path}") as source, dest.open("wb") as output:
                    shutil.copyfileobj(source, output)
            for path in deletes:
                dest = (base / path).resolve()
                if base not in dest.parents or dest.is_dir():
                    raise PatchError(f"unsafe delete target: {path}")
                if dest.exists():
                    dest.unlink()
    return {"feature":feature,"taskIds":task_ids,"files":len(files),"deleted":len(deletes),"unpackedBytes":total}


def main() -> int:
    if len(sys.argv) not in (3, 4):
        print("usage: validate_mobile_patch.py ARCHIVE.zip CURRENT_MAIN_SHA [OUTPUT_DIR]", file=sys.stderr)
        return 2
    try:
        result = preflight(Path(sys.argv[1]), sys.argv[2], Path(sys.argv[3]) if len(sys.argv) == 4 else None)
        print("Raven mobile ZIP PASS:", json.dumps(result, ensure_ascii=False))
        return 0
    except (PatchError, OSError, zipfile.BadZipFile, UnicodeDecodeError) as err:
        print("Raven mobile ZIP FAIL:", err, file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
