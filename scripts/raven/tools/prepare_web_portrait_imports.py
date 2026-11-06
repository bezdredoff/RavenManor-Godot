#!/usr/bin/env python3
"""Apply a Web-export-only Godot texture import limit to approved VN portraits.

Called only by web-package, after checkout and before the first Godot import.
The script changes .webp.import descriptors in the ephemeral CI workspace.
Approved source WebPs, their hashes and the production asset catalog are NEVER
rewritten, and local Godot Editor / VN Studio retain full-resolution originals.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import re

CATALOG = Path("data/raven/production/vn_character_catalog.json")
PORTRAIT_ROOT = Path("assets/raven/characters")
LIMIT_PARAMETER = re.compile(r"(?m)^process/size_limit=(\d+)$")
COMPRESS_MODE = re.compile(r"(?m)^compress/mode=(\d+)$")
SOURCE_PARAMETER = re.compile(r'(?m)^source_file="([^"]+)"$')
EXPECTED_CURRENT_COUNT = 62
WEB_MAX_SIDE = 1024


def selected_paths(project: Path, expected_count: int = EXPECTED_CURRENT_COUNT) -> list[Path]:
    catalog = json.loads((project / CATALOG).read_text(encoding="utf-8"))
    entries = catalog.get("entries")
    if not isinstance(entries, list):
        raise ValueError("VN character catalog must have entries[]")
    if len(entries) < expected_count:
        raise ValueError(f"Expected at least {expected_count} portraits, got {len(entries)}")
    root = (project / PORTRAIT_ROOT).resolve()
    chosen: set[Path] = set()
    for entry in entries:
        if entry.get("status") != "accepted" or not entry.get("approved"):
            raise ValueError(f"Unapproved VN portrait in runtime catalog: {entry.get('id')}")
        uri = entry.get("path")
        if not isinstance(uri, str) or not uri.startswith("res://"):
            raise ValueError(f"Invalid portrait path: {uri!r}")
        path = (project / uri[6:]).resolve()
        if not path.is_relative_to(root) or path.suffix.lower() != ".webp":
            raise ValueError(f"Portrait path escaped assets/raven/characters: {uri}")
        if not path.is_file():
            raise FileNotFoundError(path)
        if path in chosen:
            raise ValueError(f"Duplicate approved portrait path: {uri}")
        chosen.add(path)
    return sorted(chosen)


def with_import_limit(descriptor: str, source: str, max_side: int) -> str:
    sizes = LIMIT_PARAMETER.findall(descriptor)
    modes = COMPRESS_MODE.findall(descriptor)
    sources = SOURCE_PARAMETER.findall(descriptor)
    if len(sizes) != 1 or len(modes) != 1 or len(sources) != 1:
        raise ValueError("Godot .import descriptor lacks unique size/mode/source fields")
    if sources[0] != source:
        raise ValueError(f"Unexpected .import source: {sources[0]} != {source}")
    if sizes[0] not in {"0", str(max_side)}:
        raise ValueError(f"Unexpected existing import size limit: {sizes[0]}")
    if modes[0] != "0":
        raise ValueError("Portrait import is not lossless; refusing to change compression")
    return LIMIT_PARAMETER.sub(f"process/size_limit={max_side}", descriptor, count=1)


def prepare(project: Path, max_side: int = WEB_MAX_SIDE,
            expected_count: int = EXPECTED_CURRENT_COUNT) -> dict[str, int]:
    if max_side != WEB_MAX_SIDE:
        raise ValueError(f"Web portrait trial is locked to {WEB_MAX_SIDE}px")
    project = project.resolve()
    portraits = selected_paths(project, expected_count)
    before_hashes = {p: hashlib.sha256(p.read_bytes()).hexdigest() for p in portraits}
    changes = []
    for path in portraits:
        descriptor_path = path.with_suffix(path.suffix + ".import")
        if not descriptor_path.is_file():
            raise FileNotFoundError(descriptor_path)
        original = descriptor_path.read_text(encoding="utf-8")
        expected_source = "res://" + path.relative_to(project).as_posix()
        updated = with_import_limit(original, expected_source, max_side)
        changes.append((descriptor_path, original, updated))
    # Every descriptor is validated before mutating a single one.
    modified = 0
    for path, old, new in changes:
        if old != new:
            path.write_text(new, encoding="utf-8")
            modified += 1
    # CI contract: no approved master can be rewritten.
    for path, digest in before_hashes.items():
        if hashlib.sha256(path.read_bytes()).hexdigest() != digest:
            raise RuntimeError(f"Approved portrait master changed: {path}")
    return {"catalogued": len(portraits), "modified": modified, "limit": max_side}


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--project-root", type=Path, default=Path("."))
    parser.add_argument("--size-limit", type=int, default=WEB_MAX_SIDE)
    args = parser.parse_args()
    result = prepare(args.project_root, args.size_limit)
    print("Web-only portrait import: {catalogued} approved files, "
          "{modified} .import overrides, longest edge <= {limit}px".format(**result))
    print("Original .webp assets and catalog remain unchanged.")


if __name__ == "__main__":
    main()
