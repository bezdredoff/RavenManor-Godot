#!/usr/bin/env python3
"""Explicit, fail-closed art manifest -> B draft v2 / C world-plan v1 adapters.

No pixel-to-world estimation or implicit greybox conversion. DRAFT_ONLY.
"""
import argparse
import json
import math
from pathlib import Path


class ContractNotReady(ValueError):
    pass


def numbers(a, count, label):
    if (not isinstance(a, list) or len(a) != count
            or any(isinstance(v, bool) or not isinstance(v, (int, float)) or not math.isfinite(v) for v in a)):
        raise ContractNotReady(f"{label}: finite numbers required")
    return list(map(float, a))


def source_check(m):
    if m.get("productionReady") is not False or m.get("integrationAllowed") is not False:
        raise ContractNotReady("Cannot export production-authoritative art")
    s = m["source"]
    if (s.get("metadataStatus") != "verified_exact_bytes_on_github_runner"
            or not isinstance(s.get("sha256"), str) or len(s["sha256"]) != 64
            or not isinstance(s.get("dimensionsPx"), list)
            or len(s["dimensionsPx"]) != 2 or any(not isinstance(x, int) or x <= 0 for x in s["dimensionsPx"])):
        raise ContractNotReady("Verified original source metadata missing")
    return s


def reviewed_full_anchor_set(m):
    """C's strict consumer requires the full 13 canonical anchor IDs and rooms."""
    originals = m["navigationReferenceAnchors"]
    if len(originals) != 13:
        raise ContractNotReady("Exactly 13 canonical navigation anchors required")
    seen = set()
    result = []
    for a in originals:
        if a["id"] in seen or not a["id"].startswith("RM-NAV-"):
            raise ContractNotReady("Duplicate or noncanonical navigation anchor ID")
        seen.add(a["id"])
        if a.get("calibratedWorldPlanStatus") != "approved_for_preview":
            raise ContractNotReady("All 13 world-plan footpoints must be independently reviewed")
        result.append({
            "id": a["id"], "roomId": a["roomId"],
            "point": numbers(a.get("calibratedWorldPlanPoint"), 2, a["id"])
        })
    return result


def builder_v2(m):
    """Only reviewed linear source-pixel↔world controls and explicit room geometry."""
    s = source_check(m)
    t = m["coordinateSystems"]["worldPlanToSourcePixel"]
    if t.get("status") != "reviewed_for_builder_draft":
        raise ContractNotReady("Builder conversion needs separately reviewed mapping")
    world = numbers(t.get("builderLinearWorldRect"), 4, "builder worldRect")
    if world[2] <= 0 or world[3] <= 0:
        raise ContractNotReady("Invalid Builder worldRect")
    pts = t.get("controlPoints", [])
    if len(pts) < 4 or any(x.get("status") != "reviewed" for x in pts):
        raise ContractNotReady("Four reviewed non-collinear control points required")
    controls = []
    size = s["dimensionsPx"]
    for item in pts:
        p = numbers(item.get("imagePixel"), 2, "image-pixel")
        w = numbers(item.get("worldPlan"), 2, "world-plan")
        expected = [world[0] + p[0]*world[2]/size[0], world[1] + p[1]*world[3]/size[1]]
        if not (0 <= p[0] <= size[0] and 0 <= p[1] <= size[1]) or math.dist(expected, w) > 1:
            raise ContractNotReady("Control outside image or >1 world-unit linear mismatch")
        controls.append({"pixel": p, "world": w})
    pixels = [x["pixel"] for x in controls]
    if not any(abs((b[0]-a[0])*(c[1]-a[1]) - (b[1]-a[1])*(c[0]-a[0])) > 100
               for a in pixels for b in pixels for c in pixels):
        raise ContractNotReady("Collinear controls")
    rooms = [{"id": r["id"], "rect": numbers(r["approvedWorldPlanRect"], 4, r["id"])}
             for r in m["rooms"] if r.get("approvedWorldPlanRect") is not None]
    if not rooms:
        raise ContractNotReady("No independently reviewed walkable room regions")
    room_ids = {r["id"] for r in rooms}
    anchors = reviewed_full_anchor_set(m)
    if any(a["roomId"] not in room_ids for a in anchors):
        raise ContractNotReady("An anchor room is missing from reviewed Builder regions")
    doors = []
    for d in m["doors"]:
        if d.get("approvedWorldPlanPoint") is None or d.get("approvedOpeningWidth") is None:
            continue
        if any(x is not None and x not in room_ids for x in d["roomIds"]):
            continue
        width = float(d["approvedOpeningWidth"])
        if not 1 <= width <= 500 or not math.isfinite(width):
            raise ContractNotReady("Unapproved/invalid door width")
        doors.append({"id": d["id"], "rooms": d["roomIds"],
                      "point": numbers(d["approvedWorldPlanPoint"], 2, d["id"]), "width": width})
    # Only approved authored geometry is mapped; raw pixel landmarks/greybox stay separate.
    return {"schemaVersion": 1, "firstFloorDraft": {
        "schemaVersion": 2, "kind": "raven-first-floor-draft",
        "provenance": {"source": "raven.first-floor-art", "sha256": s["sha256"],
                       "geometryApproval": "reviewed_for_draft_only", "productionReady": False},
        "baseImage": {"path": s["path"], "pixelSize": size},
        "calibration": {"imageRect": [0, 0, *size], "worldRect": world, "controlPoints": controls},
        "roomRegions": rooms, "doorPlacements": doors,
        "foregroundObjects": [], "navigationAnchors": anchors
    }}


def navigation_v1(m):
    source_check(m)
    checked = reviewed_full_anchor_set(m)
    return {"schemaVersion": 1, "coordinateSpace": "world-plan",
            "productionReady": False,
            "anchors": [{"id": a["id"], "roomId": a["roomId"], "position": a["point"]}
                        for a in checked]}


def review(m):
    s = source_check(m)
    return {"sourcePath": s["path"], "sha256": s["sha256"],
            "pixelSize": s["dimensionsPx"],
            "mappingStatus": m["coordinateSystems"]["worldPlanToSourcePixel"]["status"],
            "blockedDoorCount": sum(d.get("approvedWorldPlanPoint") is None for d in m["doors"]),
            "blockedAnchorCount": sum(a.get("calibratedWorldPlanPoint") is None
                                      for a in m["navigationReferenceAnchors"]),
            "integrationAllowed": False}


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--manifest", type=Path, default=Path("assets/raven/map/first_floor_manifest.v1.json"))
    p.add_argument("--target", required=True, choices=("review", "builder", "navigation"))
    p.add_argument("--output", type=Path)
    a = p.parse_args()
    try:
        m = json.loads(a.manifest.read_text(encoding="utf-8"))
        result = {"review": review, "builder": builder_v2, "navigation": navigation_v1}[a.target](m)
    except (ValueError, KeyError, TypeError, OSError) as exc:
        p.exit(2, f"BLOCKED: {exc}\n")
    payload = json.dumps(result, ensure_ascii=False, indent=2) + "\n"
    if a.output:
        a.output.parent.mkdir(parents=True, exist_ok=True)
        a.output.write_text(payload, encoding="utf-8")
    else:
        print(payload, end="")


if __name__ == "__main__":
    main()
