#!/usr/bin/env python3
"""Package an explicit Raven delta from repository files for GitHub phone upload.

Every path is declared; no automatic mass directory sync. This is packaging
only, not GitHub upload or candidate branch creation.
"""
from __future__ import annotations
import argparse
import json
import re
import sys
import zipfile
from pathlib import Path

from validate_mobile_patch import preflight, secure_path, PatchError

ROOT = Path(__file__).resolve().parents[3]


def build(output: Path, base: str, feature: str, tasks: list[str], files: list[str]) -> dict:
    if not re.fullmatch(r"[0-9a-fA-F]{40}", base):
        raise PatchError("base must be exact 40-hex SHA from current Raven main")
    if not re.fullmatch(r"[A-Za-z0-9._-]{3,64}", feature):
        raise PatchError("invalid feature identifier")
    if not tasks or not files:
        raise PatchError("at least one task and changed file required")
    normalized = [secure_path(p) for p in files]
    if len(set(x.casefold() for x in normalized)) != len(normalized):
        raise PatchError("duplicate file paths")
    if not output.parent.exists() or output.exists():
        raise PatchError("output directory must exist and ZIP must not overwrite an earlier uploaded revision")
    for p in normalized:
        path = (ROOT / p).resolve()
        if ROOT not in path.parents or not path.is_file() or path.is_symlink():
            raise PatchError("file must exist within repository (no symlinks): " + p)
    manifest = {"format":"raven-delta-v1","baseSha":base,"feature":feature,"taskIds":tasks,
                "files":normalized,"delete":[]}
    with zipfile.ZipFile(output, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=6) as z:
        z.writestr("patch-manifest.json", json.dumps(manifest, ensure_ascii=False, indent=2))
        for p in normalized:
            z.write(ROOT / p, arcname="files/" + p)
    try:
        return preflight(output, base)
    except Exception:
        output.unlink(missing_ok=True)
        raise


def main() -> int:
    ap=argparse.ArgumentParser()
    ap.add_argument("--base",required=True,help="40-hex current Raven main SHA")
    ap.add_argument("--feature",required=True,help="e.g. CODE-02_R1")
    ap.add_argument("--task",action="append",required=True)
    ap.add_argument("--file",action="append",required=True,help="repository-relative path, repeat")
    ap.add_argument("--output",type=Path,required=True)
    args=ap.parse_args()
    try:
        info=build(args.output,args.base,args.feature,args.task,args.file)
        print("Raven phone ZIP PASS: "+json.dumps(info,ensure_ascii=False))
        return 0
    except (PatchError,OSError,zipfile.BadZipFile) as err:
        print("Raven phone ZIP FAIL: "+str(err),file=sys.stderr)
        return 1


if __name__=="__main__":
    raise SystemExit(main())
