#!/usr/bin/env python3
"""Limit approved VN background imports only in the disposable Godot Web CI checkout.

Unlike the 62 portraits, background .webp.import descriptors are not tracked.
Godot --headless --editor --import must run first to create them. Then this
script changes just those 26 descriptors, and a second Godot editor import
rebuilds the textures before Web export. Original WebP/catalog remain intact.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

from scripts.raven.tools.prepare_web_portrait_imports import with_import_limit

CATALOG = Path("data/raven/production/vn_background_catalog.json")
BACKGROUND_ROOT = Path("assets/raven/vn_backgrounds")
WEB_LONG_EDGE = 1080
MIN_APPROVED = 26


def backgrounds_from_catalog(project: Path, minimum_count: int = MIN_APPROVED) -> list[Path]:
    data = json.loads((project / CATALOG).read_text(encoding="utf-8"))
    entries = data.get("entries")
    if not isinstance(entries, list) or len(entries) < minimum_count:
        raise ValueError(f"Expected >= {minimum_count} background catalog entries")
    root = (project / BACKGROUND_ROOT).resolve()
    selected = set()
    for entry in entries:
        uri = entry.get("path")
        if entry.get("status") != "accepted" or not entry.get("approved"):
            raise ValueError(f"Unapproved VN background: {entry.get('id')}")
        if not isinstance(uri, str) or not uri.startswith("res://"):
            raise ValueError(f"Invalid background URI: {uri!r}")
        source = (project / uri[len("res://"):]).resolve()
        if not source.is_relative_to(root) or source.suffix.lower() != ".webp":
            raise ValueError(f"Background path escaped assets: {uri}")
        if not source.is_file():
            raise FileNotFoundError(source)
        if source in selected:
            raise ValueError(f"Duplicate VN background URI: {uri}")
        selected.add(source)
    return sorted(selected)


def prepare(project: Path, max_side: int = WEB_LONG_EDGE,
            minimum_count: int = MIN_APPROVED) -> dict[str, int]:
    if max_side != WEB_LONG_EDGE:
        raise ValueError(f"VN Web background experiment locked at {WEB_LONG_EDGE}px")
    project = project.resolve()
    sources = backgrounds_from_catalog(project, minimum_count)
    before = {path: hashlib.sha256(path.read_bytes()).hexdigest() for path in sources}
    catalog_digest = hashlib.sha256((project / CATALOG).read_bytes()).hexdigest()
    changes = []
    for source in sources:
        import_file = source.with_suffix(source.suffix + ".import")
        if not import_file.is_file():
            raise FileNotFoundError(
                f"Godot-generated background import descriptor missing: {import_file}. "
                "Run 'godot --headless --editor --path . --import' first."
            )
        old = import_file.read_text(encoding="utf-8")
        uri = "res://" + source.relative_to(project).as_posix()
        new = with_import_limit(old, uri, max_side)
        changes.append((import_file, old, new))
    # Validate every descriptor before applying any of the 26 overrides.
    modified = 0
    for dest, old, new in changes:
        if old != new:
            dest.write_text(new, encoding="utf-8")
            modified += 1
    if any(hashlib.sha256(path.read_bytes()).hexdigest() != digest
           for path, digest in before.items()):
        raise RuntimeError("VN background master modified during Web preparation")
    if hashlib.sha256((project / CATALOG).read_bytes()).hexdigest() != catalog_digest:
        raise RuntimeError("VN background catalog modified during Web preparation")
    return {"catalogued": len(sources), "modified": modified, "max_long_side": max_side}


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--project-root", type=Path, default=Path("."))
    parser.add_argument("--long-side", type=int, default=WEB_LONG_EDGE)
    args = parser.parse_args()
    result = prepare(args.project_root, args.long_side)
    print("Web-only VN backgrounds: {catalogued} accepted, {modified} import overrides; "
          "longest side <= {max_long_side}px".format(**result))
    print("Full-size background masters and runtime catalog are preserved.")


if __name__ == "__main__":
    main()
