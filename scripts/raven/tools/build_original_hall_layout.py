#!/usr/bin/env python3
"""Regenerate the original Hall authored-layout mirror FROM EXISTING Godot sources.

This replicates the existing map, without flipping left/right, introducing
new furniture positions, or treating experimental art as approved.

python3 scripts/raven/tools/build_original_hall_layout.py
python3 scripts/raven/tools/build_original_hall_layout.py --check
"""
import argparse
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
MAP_PATH = ROOT / "data/raven/season1_world_map.json"
VISUALS_PATH = ROOT / "data/raven/hall_visual_contract.json"
OUTPUTS = [
    ROOT / "examples/room_builder_hall_original.json",
    ROOT / "tests/fixtures/hall_room_builder_export_sample.json",
]
KINDS = {
    "rug": "decor", "clock": "interaction",
    "chair-left": "furniture", "chair-right": "furniture",
    "round-table": "furniture", "console": "furniture", "gallery": "furniture",
}


def build_original_layout(world, visual):
    room_id = "RM-ROOM-HALL"
    room_idx = next(i for i, x in enumerate(world["rooms"]) if x["id"] == room_id)
    wx, wy, w, h = world["rooms"][room_idx]["rect"]
    if visual["roomWorldRect"] != [wx, wy, w, h] or len(visual["sprites"]) != 7:
        raise ValueError("Godot Hall geometry and the pilot layout must agree")
    assets = [
        {"id": "catalog:" + s["assetRefId"], "label": s["id"],
         "kind": KINDS[s["id"]], "w": s["rect"][2], "h": s["rect"][3],
         "color": "#80627a"}
        for s in visual["sprites"]
    ]
    assets.append(
        {"id": "character:onoe", "label": "Оноэ · test only",
         "kind": "character", "w": 60, "h": 90, "color": "#af93a3"}
    )
    objects = [
        {"id": "original-" + s["id"], "assetId": "catalog:" + s["assetRefId"],
         "assetRefId": s["assetRefId"],
         "layerId": "floor" if s["mode"] == "floor" else "objects",
         "x": s["rect"][0] - wx, "y": s["rect"][1] - wy,
         "w": s["rect"][2], "h": s["rect"][3],
         "rotation": 0, "state": s["state"], "hotspotId": ""}
        for s in visual["sprites"]
    ]
    objects.append(
        {"id": "original-onoe", "assetId": "character:onoe",
         "layerId": "objects", "x": visual["actor"]["foot"][0] - wx - 30,
         "y": visual["actor"]["foot"][1] - wy - 90,
         "w": 60, "h": 90, "rotation": 0, "state": "test"}
    )
    footprints = [
        {"id": p["id"], "title": p["title"],
         "x": p["rect"][0] - wx, "y": p["rect"][1] - wy,
         "w": p["rect"][2], "h": p["rect"][3]}
        for p in world["props"] if p["room"] == room_idx
    ]
    anchors = [
        {"id": d["id"], "x": d["point"][0] - wx, "y": d["point"][1] - wy,
         "kind": "door", "status": d["status"]}
        for d in world["doors"] if d["a"] == room_idx or d["b"] == room_idx
    ]
    anchors.append({"id": "RM-NAV-HALL-SPAWN", "x": 350, "y": 620, "kind": "safe"})
    return {
        "schemaVersion": 1, "roomId": room_id,
        "title": "Холл · исходная расстановка карты Godot (черновик)",
        "width": w, "height": h, "grid": 25, "visualContractVersion": 1,
        "sourceLayout": {
            "kind": "mirror-existing-godot-placement",
            "worldRect": [wx, wy, w, h],
            "worldMap": "data/raven/season1_world_map.json",
            "visualManifest": "data/raven/hall_visual_contract.json",
            "horizontalFlip": False, "status": "PROPOSED"
        },
        "layers": [
            {"id": "floor", "name": "Пол и ковры",
             "visible": True, "locked": False},
            {"id": "objects", "name": "Мебель и декор",
             "visible": True, "locked": False},
            {"id": "foreground", "name": "Передний план",
             "visible": True, "locked": False}
        ],
        "assets": assets, "objects": objects, "anchors": anchors,
        "referenceFootprints": footprints,
        "provenance": (
            "Exact copy of current Godot provisional world-map Hall geometry + "
            "existing pilot seven-sprite composition. No left/right flip. "
            "Not approved for production."
        )
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    result = build_original_layout(
        json.loads(MAP_PATH.read_text(encoding="utf-8")),
        json.loads(VISUALS_PATH.read_text(encoding="utf-8"))
    )
    content = json.dumps(result, ensure_ascii=False, indent=2) + "\n"
    for output in OUTPUTS:
        if args.check:
            if not output.exists() or output.read_text(encoding="utf-8") != content:
                raise SystemExit("Out-of-sync original Hall: " + str(output))
        else:
            output.parent.mkdir(parents=True, exist_ok=True)
            output.write_text(content, encoding="utf-8")
    print(f"Original Hall synchronized from existing Godot: "
          f"{len(result['objects'])} objects, "
          f"{len(result['anchors'])} anchors, "
          f"{len(result['referenceFootprints'])} collision references")


if __name__ == "__main__":
    main()
