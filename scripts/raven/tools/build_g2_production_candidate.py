"""Compile the reviewed 09B authoring input into an INACTIVE production world plan.

This is an offline compiler, not a runtime QA navigation mode. Runtime consumes
ordinary world-plan anchors/edges through ManorNavigationSource and its controller.
"""
import argparse
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
SOURCE = ROOT / "assets/raven/map/qa/drafts/map_qa_09b_opening_blueprint.v1.json"
TARGET = ROOT / "data/raven/manor_production_candidate.v1.json"
ART = "res://a_detailed_top_down_isometric_game_map_illustratio.png"
ROOMS = ["RM-ROOM-HALL", "RM-ROOM-CORRIDOR", "RM-ROOM-BEDROOM"]
NAMES = {
    "QA-HALL-SPAWN": "RM-NAV-HALL-SPAWN",
    "QA-HALL-CENTRE": "RM-NAV-HS-001",
    "QA-CORRIDOR-WEST": "RM-NAV-HS-005",
    "QA-08B-CORRIDOR-BATH": "RM-NAV-HS-003",
    "QA-08B-CORRIDOR-CENTRE": "RM-NAV-CORRIDOR-CENTER",
    "QA-BEDROOM-RUG": "RM-NAV-BEDROOM-CENTER",
    "QA-BEDROOM-SOUTH": "RM-NAV-BEDROOM-SOUTH",
    "QA-08B-BEDROOM-REST": "RM-NAV-HS-002",
    "QA-09B-HC-A": "RM-NAV-HALL-CORRIDOR-NEAR",
    "QA-09B-HC-B": "RM-NAV-HALL-CORRIDOR-FAR",
    "QA-09B-CB-A": "RM-NAV-BEDROOM-NEAR",
    "QA-09B-CB-B": "RM-NAV-BEDROOM-FAR",
}
SAFE = {"RM-NAV-HALL-SPAWN", "RM-NAV-CORRIDOR-CENTER", "RM-NAV-BEDROOM-CENTER", "RM-NAV-HALL-TEA"}
PORTALS = {NAMES[x] for x in ("QA-09B-HC-A", "QA-09B-HC-B", "QA-09B-CB-A", "QA-09B-CB-B")}
ROUTES = {f"QA-ROUTE-08B-{i:03}" for i in (1, 7, 8, 10, 21)} | {f"QA-ROUTE-09B-{i:02}" for i in (3, 4, 5, 6)}


def world(point):
    return [point[0] + 128, point[1] + 128]


def cell_point(cell):
    letters = cell.rstrip("0123456789")
    col = 0
    for ch in letters:
        col = col * 26 + ord(ch) - 64
    return [col * 8, int(cell[len(letters):]) * 8]


def build():
    doc = json.loads(SOURCE.read_text(encoding="utf-8"))
    waypoints = {x["id"]: x for x in doc["waypoints"]}
    anchors, edges = {}, []

    def anchor(key, room, point):
        if key in anchors:
            return
        item = {"id": key, "roomId": room, "position": world(point), "kind": "waypoint"}
        if key in SAFE:
            item.update(kind="safe", hotspotId="RM-HS-TEA-TABLE" if key == "RM-NAV-HALL-TEA" else key + "-SAFE")
        elif key in PORTALS:
            item.update(kind="safe", hotspotId=key + "-DOOR", checkpointAllowed=False)
        elif key.startswith("RM-NAV-HS-"):
            item.update(kind="interaction", hotspotId=key.replace("RM-NAV-HS-", "RM-HS-"))
        anchors[key] = item

    # Room-owned starts precede every other anchor, independent of route order.
    for source_id in ("QA-HALL-SPAWN", "QA-08B-CORRIDOR-CENTRE", "QA-BEDROOM-RUG"):
        wp = waypoints[source_id]
        anchor(NAMES[source_id], wp["roomId"], wp["pointPx"])
    for route in doc["routes"]:
        if route["id"] not in ROUTES:
            continue
        ids = []
        for i, cell in enumerate(route["cells"]):
            endpoint = route["from"] if i == 0 else route["to"] if i == len(route["cells"]) - 1 else ""
            key = NAMES[endpoint] if endpoint else route["id"].replace("QA-ROUTE-", "RM-NAV-") + f"-STEP-{i:03}"
            point = waypoints[endpoint]["pointPx"] if endpoint else cell_point(cell)
            if route["id"] == "QA-ROUTE-09B-03" and point == [760, 664]:
                key = "RM-NAV-HALL-TEA"
            anchor(key, route["roomId"], point)
            ids.append(key)
        edges.extend({"from": a, "to": b} for a, b in zip(ids, ids[1:]))
    for a, b, door in [("QA-09B-HC-A", "QA-09B-HC-B", "RM-DOOR-HALL-CORRIDOR"), ("QA-09B-CB-A", "QA-09B-CB-B", "RM-DOOR-CORRIDOR-BEDROOM")]:
        for start, end in [(a, b), (b, a)]:
            edges.append({"from": NAMES[start], "to": NAMES[end], "doorId": door})
    controls = [{"image": point, "world": world(point)} for point in ([824, 400], [528, 376], [824, 760], [440, 344])]
    return {
        "schemaVersion": 1, "kind": "raven-calibrated-production-world-plan",
        "provenance": {
            "approval": "RENDER_REVIEW_PENDING", "productionReady": False,
            "activationEnabled": False, "runtimeAuthority": False, "coordinateSpace": "world-plan",
            "calibrationVersion": 2, "ownerDecision": "RM-DEC-030",
            "authoringSource": SOURCE.relative_to(ROOT).as_posix(),
            "authoringSourceTextSha256": hashlib.sha256(SOURCE.read_text(encoding="utf-8").encode("utf-8")).hexdigest(),
            "authoringSourceHashEncoding": "UTF-8 with LF; independent of Git checkout EOL",
            "roomArtCalibration": {
                "status": "candidate", "version": 2,
                "assetHash": "5e0edf97bd719fb1df95c7e9bea2f134d90adad0bc04d1771acc82a95a4d549a",
                "transform": {"translation": [128, 128], "uniformScale": 1, "controlPoints": controls},
                "scale": {"sourcePixelsPerMetre": 40, "doorClearWidthMetres": 1.2,
                          "footRadiusMetres": 0.3, "status": "DESIGN_TARGET_NOT_SURVEYED",
                          "paintedElevationDegrees": 65, "applySecondProjection": False},
                "rooms": {room: {"texturePath": ART, "bounds": [128, 128, 1672, 941],
                                  "cameraZoom": 1.0, "actorHeight": 62.0,
                                  "artLayer": "hc-cb-v3", "artOrigin": [128, 128]} for room in ROOMS},
            },
        },
        "physicalConstraints": {
            "footRadiusWorld": 12, "noGoPolygons": doc["noGoPolygons"],
            "walkablePolygons": doc["walkablePolygons"], "polygonSpace": "image-pixel",
            "portalWidthWorld": 48, "portalPairs": [[NAMES["QA-09B-HC-A"], NAMES["QA-09B-HC-B"]], [NAMES["QA-09B-CB-A"], NAMES["QA-09B-CB-B"]]],
        },
        "anchors": list(anchors.values()), "edges": edges,
    }


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    content = json.dumps(build(), ensure_ascii=False, indent=2) + "\n"
    if args.check:
        if not TARGET.exists() or TARGET.read_text(encoding="utf-8") != content:
            raise SystemExit("G2 production calibration candidate is stale")
        print("G2 inactive production calibration reproducibility PASS")
    else:
        TARGET.write_text(content, encoding="utf-8")
        print(TARGET.relative_to(ROOT).as_posix())
