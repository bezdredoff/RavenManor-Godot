#!/usr/bin/env python3
"""Convert an exported Room Builder Hall JSON to a VISUAL-ONLY Godot preview override.

Run at repo root:
    python3 scripts/raven/tools/sync_hall_preview.py <exported-room.json>

Output: data/raven/hall_builder_preview.json (draft-only, never alters the
canonical map/collision graph/save). Remove that output to restore pilot layout.
"""
import argparse
import json
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
CONTRACT_PATH = ROOT / "data/raven/hall_visual_contract.json"
DEFAULT_OUTPUT = ROOT / "data/raven/hall_builder_preview.json"
MAX_INPUT_BYTES = 45 * 1024 * 1024


def finite_number(value):
    return isinstance(value, (int, float)) and not isinstance(value, bool) and math.isfinite(value)


def convert(project, contract):
    if project.get("schemaVersion") != 1 or project.get("roomId") != "RM-ROOM-HALL":
        raise ValueError("Only Room Builder v1 Hall projects can be previewed")
    wx, wy, w, h = contract["roomWorldRect"]
    if (project.get("width"), project.get("height")) != (w, h):
        raise ValueError("Hall must match proposed Godot rectangle (700 x 690); do not silently scale draft")
    if project.get("visualContractVersion") != 1:
        raise ValueError("First create a fresh Godot-aligned Hall draft in Builder v0.4")
    candidates = {s["assetRefId"]: s for s in contract["sprites"]}
    seen_ids = set()
    seen_assets = set()
    result = []
    objects = project.get("objects")
    if not isinstance(objects, list) or len(objects) > 20000:
        raise ValueError("Invalid or oversized object list")
    for item in objects:
        if not isinstance(item, dict) or not isinstance(item.get("id"), str) or item["id"] in seen_ids:
            raise ValueError("Invalid or duplicate instance ID")
        seen_ids.add(item["id"])
        ref = item.get("assetRefId", "")
        if ref not in candidates:
            continue  # Decorations without an approved pilot cutout stay in Builder for now.
        if ref in seen_assets:
            raise ValueError("Duplicate preview source identity: " + ref)
        seen_assets.add(ref)
        source = candidates[ref]
        rect = [item.get("x"), item.get("y"), item.get("w"), item.get("h")]
        if not all(finite_number(v) for v in rect) or rect[2] <= 0 or rect[3] <= 0:
            raise ValueError("Invalid visual rectangle for " + ref)
        if not (-200 <= rect[0] <= w+200 and -200 <= rect[1] <= h+200) or rect[2] > 1000 or rect[3] > 1000:
            raise ValueError("Visual dimensions outside the reviewable room region")
        if item.get("rotation", 0) not in (0, 0.0):
            raise ValueError("Rotated pilot sprites are not yet supported by the Godot map renderer")
        if item.get("state", source["state"]) != source["state"]:
            # Never export the 'clean' PNG as though it were an approved dirty/broken variant.
            raise ValueError("Visual state needs a distinct approved render before Godot export: " + ref)
        result.append({
            "id": source["id"],
            "assetRefId": ref,
            "mapPropId": source["mapPropId"],
            "file": source["file"],
            "mode": source["mode"],
            "state": source["state"],
            "rect": [round(wx+rect[0], 4), round(wy+rect[1], 4), round(rect[2], 4), round(rect[3], 4)],
        })
    return {
        "schemaVersion": 1,
        "roomId": "RM-ROOM-HALL",
        "status": "DRAFT_ONLY",
        "sourceManifestSchemaVersion": contract["schemaVersion"],
        "note": "Visual-only Builder layout. Godot collider boxes, routes, save and campaign state are NOT changed.",
        "sprites": result,
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("json_path", type=Path)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    args = parser.parse_args()
    if args.json_path.stat().st_size > MAX_INPUT_BYTES:
        parser.error("Room JSON exceeds 45 MB")
    project = json.loads(args.json_path.read_text(encoding="utf-8"))
    contract = json.loads(CONTRACT_PATH.read_text(encoding="utf-8"))
    draft = convert(project, contract)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(draft, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print("DRAFT-ONLY Hall preview:", args.output, "|", len(draft["sprites"]), "pilot visuals")


if __name__ == "__main__":
    main()
