#!/usr/bin/env python3
"""Audit the actual Godot Web export without copying or uploading additional artifacts.

Export console logs list PCK entry paths; .import remaps attribute imported
texture bytes to their source asset. These are *raw imported file sizes*, not
claims about their byte-by-byte compressed contribution inside the PCK.
"""
from __future__ import annotations

import argparse
from collections import defaultdict
from pathlib import Path
import re

PACKED_RE = re.compile(r"Storing File:\s+res://([^\r\n\x1b]+)")
REMAP_RE = re.compile(r'^\s*path(?:\.[^=]+)?="res://([^"]+)"', re.MULTILINE)
DENIED_PREFIXES = (
    "addons/vn_studio/",
    "data/raven/production/progress/",
    "examples/",
)
DENIED_EXACT = frozenset({
    "data/raven/production/code_work_packages.json",
    "data/raven/production/gap_work_packages.json",
    "data/raven/production/active_workstreams.json",
    "data/raven/production/p2_reentry_policy.json",
    "data/raven/production/production_progress.json",
})


def packed_paths(log: str) -> list[str]:
    return [p.strip() for p in PACKED_RE.findall(log)]


def imported_source_map(root: Path) -> dict[str, str]:
    result: dict[str, str] = {}
    for descriptor in root.rglob("*.import"):
        source = descriptor.relative_to(root).as_posix().removesuffix(".import")
        text = descriptor.read_text(encoding="utf-8")
        for imported in REMAP_RE.findall(text):
            if imported.startswith(".godot/imported/"):
                result[imported] = source
    return result


def bucket(source: str) -> str:
    for prefix in (
        "assets/raven/characters/",
        "assets/raven/vn_backgrounds/",
        "assets/raven/hall/",
        "assets/raven/match3/",
        "assets/prototypes/",
    ):
        if source.startswith(prefix):
            return prefix.removesuffix("/")
    if source.startswith(".godot/imported/"):
        return "unattributed/imported"
    return source.split("/", 1)[0]


def analyze(root: Path, web: Path, export_log: str) -> dict:
    pck = web / "index.pck"
    wasm = web / "index.wasm"
    if not pck.is_file() or not wasm.is_file():
        raise ValueError("Expected index.pck and index.wasm in Web export")
    paths = packed_paths(export_log)
    if len(paths) < 10:
        raise ValueError("Godot export log did not list enough packed entries")
    prohibited = sorted({
        path for path in paths
        if path.startswith(DENIED_PREFIXES) or path in DENIED_EXACT
    })
    if prohibited:
        raise ValueError("Editor/production resources still packed: " + ", ".join(prohibited[:12]))
    lookup = imported_source_map(root)
    by_bucket: dict[str, int] = defaultdict(int)
    imported: list[tuple[str, int]] = []
    missing: list[str] = []
    for path in paths:
        file = root / path
        if path.startswith(".godot/imported/"):
            if not file.is_file():
                missing.append(path)
                continue
            size = file.stat().st_size
            source = lookup.get(path, path)
            by_bucket[bucket(source)] += size
            imported.append((source, size))
    return {
        "pck_bytes": pck.stat().st_size,
        "wasm_bytes": wasm.stat().st_size,
        "web_total_bytes": sum(f.stat().st_size for f in web.rglob("*") if f.is_file()),
        "dashboard_bytes": sum(f.stat().st_size for f in (web / "dashboard").rglob("*") if f.is_file()),
        "packed_entries": len(paths),
        "texture_entries": len(imported),
        "texture_raw_bytes": sum(size for _, size in imported),
        "texture_groups": sorted(by_bucket.items(), key=lambda x: -x[1]),
        "largest_textures": sorted(imported, key=lambda x: -x[1])[:12],
        "unresolved_textures": missing,
    }


def report(data: dict) -> str:
    mb = lambda x: f"{x / 1048576:.2f} MiB"
    out = [
        "### Raven Web PCK footprint (actual export, advisory)",
        "",
        "| Item | Size / count |",
        "| --- | ---: |",
        f"| Godot index.pck | {mb(data['pck_bytes'])} |",
        f"| WebAssembly index.wasm | {mb(data['wasm_bytes'])} |",
        f"| Entire unpacked Web folder | {mb(data['web_total_bytes'])} |",
        f"| Production dashboard | {mb(data['dashboard_bytes'])} |",
        f"| PCK log entries | {data['packed_entries']} |",
        f"| Imported textures | {data['texture_entries']} |",
        f"| Sum of raw imported textures | {mb(data['texture_raw_bytes'])} |",
        "",
        "Imported texture bytes are measured from export-stage .ctex files; "
        "they are not a precise per-resource decomposition of compressed PCK bytes.",
        "",
        "| Imported texture source group | Raw imported size |",
        "| --- | ---: |",
    ]
    out += [f"| {name} | {mb(size)} |" for name, size in data["texture_groups"]]
    out += ["", "| Largest imported textures | Raw size |", "| --- | ---: |"]
    out += [f"| {name} | {mb(size)} |" for name, size in data["largest_textures"]]
    if data["unresolved_textures"]:
        out += ["", "WARNING: missing source for imported entries: "
                + ", ".join(data["unresolved_textures"][:10])]
    return "\n".join(out) + "\n"


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--project-root", type=Path, required=True)
    p.add_argument("--web-root", type=Path, required=True)
    p.add_argument("--export-log", type=Path, required=True)
    p.add_argument("--summary", type=Path)
    args = p.parse_args()
    data = analyze(args.project_root.resolve(), args.web_root.resolve(),
                   args.export_log.read_text(encoding="utf-8", errors="replace"))
    output = report(data)
    print(output)
    if args.summary:
        with args.summary.open("a", encoding="utf-8") as f:
            f.write(output)


if __name__ == "__main__":
    main()
