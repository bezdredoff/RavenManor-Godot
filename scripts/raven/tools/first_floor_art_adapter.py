#!/usr/bin/env python3
"""Read-only adapter: Agent A's raven.first-floor-art/v1 -> Room Builder draft/v2.

Treat the image raster, provisional world plan and independent greybox anchors
as distinct spaces. Registration is UNRESOLVED; no fake pixel->world transform.
Never change the producer's manifest or canonical gameplay assets.
"""
import copy
import hashlib
import json
import re
import struct
from pathlib import Path

try:
    from scripts.raven.tools.import_first_floor_draft import ROOT, WORLD_MAP, repo_asset, ROOM, DOOR
except ModuleNotFoundError as error:
    if error.name != "scripts":
        raise
    from import_first_floor_draft import ROOT, WORLD_MAP, repo_asset, ROOM, DOOR

SOURCE_ID = "raven.first-floor-art"
SOURCE_VERSION = 1
DRAFT_VERSION = 2
PNG_SIGNATURE = bytes([137, 80, 78, 71, 13, 10, 26, 10])


def expect(condition, message):
    if not condition:
        raise ValueError("Art manifest v1: " + message)


def unique(rows, label):
    expect(isinstance(rows, list), f"{label} must be an array")
    ids = []
    for row in rows:
        expect(isinstance(row, dict) and isinstance(row.get("id"), str) and row["id"], f"{label} invalid ID")
        ids.append(row["id"])
    expect(len(ids) == len(set(ids)), f"{label}: duplicate ID")


def measured_source(manifest):
    source = manifest.get("source")
    expect(isinstance(source, dict), "source is required")
    path = source.get("path")
    raw = repo_asset(path).read_bytes()
    expect(raw.startswith(PNG_SIGNATURE) and raw[12:16] == b"IHDR" and len(raw) >= 24, "bad source PNG")
    w, h = struct.unpack(">II", raw[16:24])
    expect(0 < w <= 16384 and 0 < h <= 16384, "bad PNG dimensions")
    observed = hashlib.sha256(raw).hexdigest()
    git_blob = hashlib.sha1(f"blob {len(raw)}".encode("ascii") + bytes([0]) + raw).hexdigest()
    expect(source.get("format") == "PNG", "source format must be PNG")
    expect(source.get("byteSize") == len(raw), "source byteSize mismatched")
    expect(source.get("gitBlobSha") == git_blob, "source gitBlobSha mismatched")
    expect(source.get("sha256") in (None, observed), "source SHA256 mismatched")
    expect(source.get("dimensionsPx") is None or source["dimensionsPx"] == [w, h], "source dimensionsPx mismatched")
    return {"path": path, "pixelSize": [w, h], "sha256": observed, "gitBlobSha": git_blob}


def adapt_art_manifest(data, reference=None):
    """Return full v1 Room Builder project with optional v2 unregistered draft.

    Input is preserved exactly in firstFloorDraft.producerManifest for roundtrip.
    Required PNG source hashes/size are inspected from bytes, never guessed.
    """
    reference = reference if reference is not None else json.loads(WORLD_MAP.read_text("utf-8"))
    expect(isinstance(data, dict), "expected JSON object")
    expect(data.get("schemaVersion") == SOURCE_VERSION and data.get("contractId") == SOURCE_ID,
           "incompatible schemaVersion or contractId")
    expect(data.get("productionReady") is False and data.get("integrationAllowed") is False,
           "cannot promote art manifest into gameplay")
    for key in ("rooms", "doors", "objects", "navigationReferenceAnchors", "layers"):
        unique(data.get(key), key)
    image = measured_source(data)
    systems = data.get("coordinateSystems")
    expect(isinstance(systems, dict), "coordinateSystems is required")
    plan = systems.get("worldPlan")
    mapping = systems.get("worldPlanToSourcePixel")
    greybox = systems.get("greyboxGraph")
    expect(isinstance(plan, dict) and plan.get("extent") == reference.get("worldSize"),
           "worldPlan extent differs from provisional map")
    expect(isinstance(mapping, dict) and mapping.get("status") == "unresolved" and
           mapping.get("matrix") is None and mapping.get("allowInterpolation") is False and
           mapping.get("controlPoints") == [], "pixel-to-plan mapping not unresolved")
    expect(isinstance(greybox, dict) and greybox.get("directMappingToWorldPlan") is False,
           "greybox coordinates cannot map implicitly to world-plan")
    source_rooms = {r["id"]: r for r in reference["rooms"]}
    source_doors = {d["id"]: d for d in reference["doors"]}
    rectangles = []
    for room in data["rooms"]:
        rid = room["id"]
        expect(ROOM.fullmatch(rid) is not None and rid in source_rooms, "unknown room " + rid)
        rect = room.get("referenceWorldPlanRect")
        expect(rect == source_rooms[rid]["rect"], "room drift: " + rid)
        expect(room.get("sourcePixelPolygon") is None, "unapproved source pixel polygon " + rid)
        rectangles.append({"id": rid, "rect": copy.deepcopy(rect), "coordinateSpace": "world-plan",
                           "referenceOnly": True})
    expect(len(rectangles) == len(source_rooms), "missing reference rooms")
    placements = []
    for door in data["doors"]:
        did = door["id"]
        expect(DOOR.fullmatch(did) is not None and did in source_doors, "unknown door " + did)
        original = source_doors[did]
        room_ids = [reference["rooms"][i]["id"] if i >= 0 else None for i in (original["a"], original["b"])]
        expect(door.get("roomIds") == room_ids and door.get("referenceWorldPlanPoint") == original["point"],
               "door reference mismatch: " + did)
        expect(door.get("sourcePixelPoint") is None, "unreviewed source pixel door " + did)
        # Existing v2 requires numeric width; mark editor placeholder explicitly.
        placements.append({"id": did, "rooms": room_ids, "point": copy.deepcopy(original["point"]),
                           "width": 80, "widthAuthority": "editor_placeholder_not_art",
                           "coordinateSpace": "world-plan", "referenceOnly": True})
    expect(len(placements) == len(source_doors), "missing reference doors")
    for anchor in data["navigationReferenceAnchors"]:
        expect(anchor.get("roomId") in source_rooms and anchor.get("referenceSpace") == "independent_greybox" and
               anchor.get("sourcePixelFootpoint") is None, "unreviewed greybox anchor " + anchor["id"])
    for obj in data["objects"]:
        expect(obj.get("roomId") in source_rooms and str(obj["id"]).startswith("RM-ASSET-") and
               obj.get("sourcePixelPivot") is None and obj.get("foregroundCutoutPath") is None,
               "unreviewed sprite/foreground " + obj["id"])
    draft = {
        "schemaVersion": DRAFT_VERSION, "kind": "raven-first-floor-draft",
        "provenance": "Agent A art manifest v1: reference-only, image registration unresolved",
        "baseImage": image,
        "registration": {"status": "unresolved", "imageSpace": "image-pixel",
                         "referenceSpace": "world-plan", "previewSpace": "screen-projected",
                         "pixelToWorld": None, "navigationAllowed": False},
        "calibration": {
            "status": "unresolved", "imageRect": [0, 0, *image["pixelSize"]],
            "worldRect": [0, 0, *reference["worldSize"]], "controlPoints": [],
        },
        "roomRegions": rectangles, "doorPlacements": placements,
        # Agent A's greybox graph coords are deliberately not world plan points.
        "navigationAnchors": [], "foregroundObjects": [],
        "producerManifest": copy.deepcopy(data),
    }
    return {"schemaVersion": 1, "id": "first-floor-art-v1-review",
            "title": "First-floor image: UNREGISTERED Agent A review",
            "roomId": "RM-ROOM-HALL", "width": 700, "height": 690, "grid": 25,
            "assets": [], "layers": [], "objects": [],
            "anchors": [], "walls": [], "openings": [], "firstFloorDraft": draft}
