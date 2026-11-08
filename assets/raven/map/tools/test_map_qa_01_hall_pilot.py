"""MAP-QA-01: isolated, non-production Hall image-pixel route contract checks.

Run: python3 -m unittest assets.raven.map.tools.test_map_qa_01_hall_pilot -v
No change to the canonical graph, Room Builder or campaign state is made.
"""
from __future__ import annotations

import copy
import hashlib
import json
import math
import struct
import unittest
from collections import deque
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
PILOT = ROOT / "assets/raven/map/qa/first_floor_hall_pilot.v1.json"
MANIFEST = ROOT / "assets/raven/map/first_floor_manifest.v1.json"
GRAPH = ROOT / "data/raven/manor_greybox_graph.json"


def read_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def numeric_xy(value: object, width: int, height: int) -> bool:
    return (isinstance(value, list) and len(value) == 2
            and all(isinstance(v, (int, float)) and not isinstance(v, bool)
                    and math.isfinite(v) for v in value)
            and 0 <= value[0] < width and 0 <= value[1] < height)


def in_polygon(point: list[float], poly: list[list[float]]) -> bool:
    # Ray-casting with boundary-inclusive test; suitable for deterministic QA-only XY.
    x, y = point
    enclosed = False
    for i, v in enumerate(poly):
        w = poly[(i + 1) % len(poly)]
        dx, dy = w[0] - v[0], w[1] - v[1]
        cross = (x - v[0]) * dy - (y - v[1]) * dx
        if abs(cross) < 1e-7 and min(v[0], w[0]) <= x <= max(v[0], w[0]) and min(v[1], w[1]) <= y <= max(v[1], w[1]):
            return True
        if (v[1] > y) != (w[1] > y):
            intersect_x = v[0] + (y - v[1]) * dx / dy
            if x < intersect_x:
                enclosed = not enclosed
    return enclosed


def segment_stays_walkable(
    start: list[float], end: list[float], walkable: list[dict], nogo: list[dict]
) -> bool:
    """Classify entire authored segments using polygon boundary intersections.

    Split at all boundary crossings (including collinear overlap endpoints),
    then test every breakpoint and interval midpoint. This detects thin no-go
    strips and concave floor excursions missed by fixed-distance sampling.
    """
    def cross(a: list[float], b: list[float]) -> float:
        return a[0] * b[1] - a[1] * b[0]

    def subtract(a: list[float], b: list[float]) -> list[float]:
        return [a[0] - b[0], a[1] - b[1]]

    def cut_parameters(c: list[float], d: list[float]) -> list[float]:
        r, v = subtract(end, start), subtract(d, c)
        q = subtract(c, start)
        den = cross(r, v)
        if abs(den) < 1e-10:
            if abs(cross(q, r)) > 1e-8:
                return []
            rr = r[0] * r[0] + r[1] * r[1]
            if rr < 1e-12:
                return []
            cuts = [sum((p[k] - start[k]) * r[k] for k in (0, 1)) / rr
                    for p in (c, d)]
            return [max(0.0, min(1.0, t)) for t in cuts if -1e-10 <= t <= 1 + 1e-10]
        t, u = cross(q, v) / den, cross(q, r) / den
        return [max(0.0, min(1.0, t))] if -1e-10 <= t <= 1 + 1e-10 and -1e-10 <= u <= 1 + 1e-10 else []

    def allowed(t: float) -> bool:
        p = [start[k] + (end[k] - start[k]) * t for k in (0, 1)]
        return (any(in_polygon(p, z["pointsPx"]) for z in walkable)
                and not any(in_polygon(p, z["pointsPx"]) for z in nogo))

    cuts = [0.0, 1.0]
    for zone in walkable + nogo:
        boundary = zone["pointsPx"]
        for i, point in enumerate(boundary):
            cuts.extend(cut_parameters(point, boundary[(i + 1) % len(boundary)]))
    cuts.sort()
    distinct: list[float] = []
    for t in cuts:
        if not distinct or t - distinct[-1] > 1e-10:
            distinct.append(t)
    return all(allowed(t) for t in distinct) and all(
        allowed((left + right) * 0.5)
        for left, right in zip(distinct, distinct[1:])
    )


def audit(data: dict, manifest: dict, graph: dict, check_png: bool = True) -> list[str]:
    errors: list[str] = []
    def require(condition: bool, reason: str) -> None:
        if not condition:
            errors.append(reason)

    require(data.get("schemaVersion") == 1 and data.get("kind") == "raven-first-floor-hall-qa-pilot", "invalid schema")
    require(data.get("taskId") == "MAP-QA-01" and data.get("ownerDomain") == "environment-art", "wrong owner")
    require(data.get("approval") == "DRAFT_ONLY" and data.get("productionReady") is False
            and data.get("integrationAllowed") is False and data.get("canonicalNavigationAuthority") is False,
            "production promotion forbidden")
    image = manifest["source"]
    source = data.get("source", {})
    require(source.get("path") == image["path"]
            and source.get("gitBlobSha") == image["gitBlobSha"]
            and source.get("sha256") == image["sha256"]
            and source.get("dimensionsPx") == [1672, 941], "source fingerprint mismatch")
    if check_png:
        png = ROOT / source.get("path", "NONEXISTENT")
        if not png.is_file():
            errors.append("approved PNG is missing")
        else:
            blob = png.read_bytes()
            require(len(blob) == image["byteSize"] and hashlib.sha256(blob).hexdigest() == image["sha256"], "approved PNG bytes changed")
            require(len(blob) >= 24 and blob[:8] == bytes((137, 80, 78, 71, 13, 10, 26, 10))
                    and struct.unpack(">II", blob[16:24]) == (1672, 941), "PNG dimensions changed")
    coords = data.get("coordinateSpaces", {})
    require(coords.get("pilot") == "image-pixel" and coords.get("pixelToWorldPlan") is None
            and coords.get("worldPlanAuthority") is False
            and coords.get("apply65DegreeProjectionToBaseImage") is False
            and coords.get("alreadyPaintedPerspective") is True, "unsafe coordinate conversion")
    canon = data.get("canonicalReferences", {})
    expected = {(a["id"], a["roomId"], a["kind"]) for a in graph["anchors"]}
    seen = [(a.get("id"), a.get("roomId"), a.get("kind")) for a in canon.get("anchorIdentities", [])]
    require(len(seen) == len(expected) == 13 and len(set(seen)) == 13 and set(seen) == expected
            and canon.get("transferredCoordinateCount") == 0
            and all(set(a) == {"id", "roomId", "kind"} for a in canon.get("anchorIdentities", [])), "13 canonical ID/room/kind references drifted or contain coordinates")
    require(canon.get("roomId") == "RM-ROOM-HALL" and canon.get("logicalDoorId") == "RM-DOOR-HALL-CORRIDOR", "canonical Hall references changed")
    manifest_anchors = manifest.get("navigationReferenceAnchors", [])
    require(manifest.get("productionReady") is False and manifest.get("integrationAllowed") is False
            and len(manifest_anchors) == len(expected)
            and {(a.get("id"), a.get("roomId"), a.get("kind")) for a in manifest_anchors} == expected
            and all(a.get("sourcePixelFootpoint") is None and a.get("calibratedWorldPlanPoint") is None
                    for a in manifest_anchors), "QA pixels promoted to canonical world-plan geometry")
    w, h = 1672, 941
    polygons = data.get("walkablePolygons", [])
    nogo = data.get("noGoPolygons", [])
    zone_ids = [z.get("id") for z in polygons + nogo]
    require(len(zone_ids) == len(set(zone_ids)), "duplicate zone ID")
    for zone in polygons + nogo:
        points = zone.get("pointsPx", [])
        require(len(points) >= 3 and all(numeric_xy(p, w, h) for p in points), "invalid polygon: " + str(zone.get("id")))
    def walkable(p: list[float]) -> bool:
        return (any(in_polygon(p, z["pointsPx"]) for z in polygons)
                and not any(in_polygon(p, z["pointsPx"]) for z in nogo))
    points = data.get("waypoints", [])
    by_id = {p.get("id"): p for p in points}
    require(len(points) == len(by_id) and len(points) == 7
            and all(isinstance(p.get("id"), str) and p["id"].startswith("QA-HALL-") for p in points), "duplicate/missing waypoint IDs")
    require(len(polygons) == 1 and len(nogo) >= 3, "missing walkable or no-go zones")
    canonical_hotspots = {a.get("hotspotId") for a in graph["anchors"] if a.get("hotspotId")}
    interactions = [p.get("hotspotRef") for p in points if p.get("kind") == "interaction"]
    require(len(interactions) == 1
            and all(isinstance(ref, str) and ref in canonical_hotspots for ref in interactions)
            and all("hotspotRef" not in p for p in points if p.get("kind") != "interaction"),
            "invalid QA hotspot reference")
    require(sum(p.get("kind") == "spawn" for p in points) == 1
            and sum(p.get("kind") == "movement" for p in points) == 3
            and sum(p.get("kind") == "interaction" for p in points) == 1, "missing required point roles")
    for waypoint in points:
        point = waypoint.get("pointPx")
        require(numeric_xy(point, w, h), "off-image waypoint: " + str(waypoint.get("id")))
        if numeric_xy(point, w, h) and all(len(z.get("pointsPx", [])) >= 3 for z in polygons + nogo):
            require(walkable(point), "non-walkable waypoint: " + str(waypoint.get("id")))
    start = data.get("actor", {}).get("initialPointId")
    require(start in by_id and by_id[start].get("kind") == "spawn", "start does not exist")
    edges = data.get("edges", [])
    require(len(edges) >= 6, "not enough authored edges")
    adjacency = {key: set() for key in by_id}
    seen_edges: set[frozenset[str]] = set()
    for edge in edges:
        a, b = edge.get("from"), edge.get("to")
        if a not in by_id or b not in by_id or a == b:
            errors.append("edge references missing/same point")
            continue
        require(edge.get("bidirectional") is True, "unexpected one-way QA route")
        edge_id = frozenset((a, b))
        require(edge_id not in seen_edges, "duplicate authored edge")
        seen_edges.add(edge_id)
        adjacency[a].add(b)
        adjacency[b].add(a)
        start_xy, end_xy = by_id[a].get("pointPx"), by_id[b].get("pointPx")
        if numeric_xy(start_xy, w, h) and numeric_xy(end_xy, w, h):
            if not segment_stays_walkable(start_xy, end_xy, polygons, nogo):
                errors.append(f"route intersects no-go/outside floor: {a}->{b}")
    visited: set[str] = set()
    queue = deque([start] if start in adjacency else [])
    while queue:
        node = queue.popleft()
        if node in visited:
            continue
        visited.add(node)
        queue.extend(adjacency[node] - visited)
    require(visited == set(by_id), "waypoint graph is disconnected")
    portal = data.get("virtualPortal", {})
    require(portal.get("id") == "QA-PORTAL-HALL-CORRIDOR"
            and portal.get("status") == "QA_VIRTUAL_NOT_VISIBLE_PHYSICAL_DOOR"
            and portal.get("physicalDoorConfirmed") is False
            and portal.get("canonicalDoorRef") == "RM-DOOR-HALL-CORRIDOR"
            and portal.get("fromRoomId") == "RM-ROOM-HALL"
            and portal.get("toRoomId") == "RM-ROOM-CORRIDOR"
            and portal.get("activateOnArrivalOnly") is True
            and portal.get("transition") == "switch-active-area"
            and portal.get("farSideSpawnPointPx") is None
            and portal.get("liveDoorGateWrites") is False
            and portal.get("requiresSeparateCorridorPilot") is True, "virtual portal claims physical/runtime approval")
    manifest_doors = {door.get("id"): door for door in manifest.get("doors", [])}
    door = manifest_doors.get(portal.get("canonicalDoorRef"), {})
    require(door.get("roomIds") == ["RM-ROOM-HALL", "RM-ROOM-CORRIDOR"]
            and door.get("sourcePixelPoint") is None
            and door.get("authoritativeForMovement") is False,
            "virtual portal impersonates an approved physical door")
    ap, rp = portal.get("approachPointId"), portal.get("returnSpawnPointId")
    require(ap in by_id and rp in by_id and ap != rp
            and by_id.get(ap, {}).get("kind") == "portal_approach"
            and by_id.get(rp, {}).get("kind") == "return_spawn"
            and rp in adjacency.get(ap, set()), "portal approach or return spawn disconnected")
    require(data.get("actor", {}).get("coordinateMeaning", "").startswith("standing foot contact"), "actor feet pivot unspecified")
    return errors


class HallPilotTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.pilot = read_json(PILOT)
        cls.manifest = read_json(MANIFEST)
        cls.graph = read_json(GRAPH)

    def test_real_approved_png_and_complete_contract(self) -> None:
        self.assertEqual(audit(self.pilot, self.manifest, self.graph), [])

    def test_no_approval_claim(self) -> None:
        changed = copy.deepcopy(self.pilot)
        changed["integrationAllowed"] = True
        self.assertIn("production promotion forbidden", audit(changed, self.manifest, self.graph, False))

    def test_reject_drifted_png(self) -> None:
        changed = copy.deepcopy(self.pilot)
        changed["source"]["sha256"] = "0" * 64
        self.assertIn("source fingerprint mismatch", audit(changed, self.manifest, self.graph, False))

    def test_reject_non_image_pixel_frame(self) -> None:
        changed = copy.deepcopy(self.pilot)
        changed["coordinateSpaces"]["pilot"] = "world-plan"
        self.assertIn("unsafe coordinate conversion", audit(changed, self.manifest, self.graph, False))

    def test_reject_displaced_waypoint(self) -> None:
        changed = copy.deepcopy(self.pilot)
        changed["waypoints"][0]["pointPx"] = [1672, 941]
        self.assertTrue(any("off-image waypoint" in e for e in audit(changed, self.manifest, self.graph, False)))

    def test_reject_unknown_edge(self) -> None:
        changed = copy.deepcopy(self.pilot)
        changed["edges"][0]["to"] = "QA-HALL-NONEXISTENT"
        self.assertIn("edge references missing/same point", audit(changed, self.manifest, self.graph, False))

    def test_reject_disconnected_route(self) -> None:
        changed = copy.deepcopy(self.pilot)
        changed["edges"] = [e for e in changed["edges"] if "QA-HALL-WEST" not in (e["from"], e["to"])]
        self.assertIn("waypoint graph is disconnected", audit(changed, self.manifest, self.graph, False))

    def test_reject_invalid_portal(self) -> None:
        changed = copy.deepcopy(self.pilot)
        changed["virtualPortal"]["approachPointId"] = "QA-HALL-NONEXISTENT"
        self.assertIn("portal approach or return spawn disconnected", audit(changed, self.manifest, self.graph, False))

    def test_reject_duplicate_waypoint_and_edge(self) -> None:
        changed = copy.deepcopy(self.pilot)
        changed["waypoints"][1]["id"] = changed["waypoints"][0]["id"]
        self.assertIn("duplicate/missing waypoint IDs", audit(changed, self.manifest, self.graph, False))
        changed = copy.deepcopy(self.pilot)
        changed["edges"].append(copy.deepcopy(changed["edges"][0]))
        self.assertIn("duplicate authored edge", audit(changed, self.manifest, self.graph, False))

    def test_reject_invalid_hotspot_and_coordinate_promotion(self) -> None:
        changed = copy.deepcopy(self.pilot)
        changed["waypoints"][4]["hotspotRef"] = "RM-HS-UNKNOWN"
        self.assertIn("invalid QA hotspot reference", audit(changed, self.manifest, self.graph, False))
        manifest = copy.deepcopy(self.manifest)
        manifest["navigationReferenceAnchors"][0]["sourcePixelFootpoint"] = [836, 746]
        self.assertIn("QA pixels promoted to canonical world-plan geometry",
                      audit(self.pilot, manifest, self.graph, False))

    def test_reject_narrow_no_go_crossing_between_old_samples(self) -> None:
        changed = copy.deepcopy(self.pilot)
        changed["noGoPolygons"].append({
            "id": "QA-HALL-TEST-THIN", "reason": "synthetic obstacle test only",
            "pointsPx": [[834, 721.55], [838, 721.55], [838, 721.65], [834, 721.65]],
        })
        self.assertTrue(any("route intersects no-go/outside floor" in e
                            for e in audit(changed, self.manifest, self.graph, False)))

    def test_segment_rejects_concave_floor_excursion_and_thin_obstacle(self) -> None:
        floor = [{"pointsPx": [[0, 0], [10, 0], [10, 10], [6, 10],
                               [6, 4], [4, 4], [4, 10], [0, 10]]}]
        self.assertFalse(segment_stays_walkable([2, 8], [8, 8], floor, []))
        self.assertTrue(segment_stays_walkable([1, 2], [9, 2], floor, []))
        self.assertFalse(segment_stays_walkable(
            [1, 2], [9, 2], floor,
            [{"pointsPx": [[5, 1], [5.01, 1], [5.01, 3], [5, 3]]}],
        ))

    def test_reject_portal_promotion_and_arrival_contract(self) -> None:
        changed = copy.deepcopy(self.pilot)
        changed["virtualPortal"]["farSideSpawnPointPx"] = [959, 746]
        self.assertIn("virtual portal claims physical/runtime approval",
                      audit(changed, self.manifest, self.graph, False))
        changed = copy.deepcopy(self.pilot)
        changed["virtualPortal"]["activateOnArrivalOnly"] = False
        self.assertIn("virtual portal claims physical/runtime approval",
                      audit(changed, self.manifest, self.graph, False))

    def test_reject_canonical_reference_drift(self) -> None:
        changed = copy.deepcopy(self.pilot)
        changed["canonicalReferences"]["anchorIdentities"][0]["roomId"] = "RM-ROOM-BEDROOM"
        self.assertIn("13 canonical ID/room/kind references drifted or contain coordinates",
                      audit(changed, self.manifest, self.graph, False))


if __name__ == "__main__":
    unittest.main()
