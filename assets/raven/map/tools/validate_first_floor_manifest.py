#!/usr/bin/env python3
"""Validate draft first-floor map art; never approve collision or movement."""
from __future__ import annotations
import argparse
import hashlib
import json
import math
from pathlib import Path
import struct
import sys
import zlib

MANIFEST = Path("assets/raven/map/first_floor_manifest.v1.json")
PNG_SIGNATURE = b'\x89PNG\r\n\x1a\n'


class ContractError(ValueError):
    pass


def png_dimensions(raw: bytes) -> tuple[int, int]:
    """Check PNG signature, all chunks/CRCs and final IEND; no Pillow needed."""
    if len(raw) < 45 or raw[:8] != PNG_SIGNATURE:
        raise ContractError("Source is not a PNG signature")
    offset, first, seen_idat, seen_iend, dimensions = 8, True, False, False, None
    while offset < len(raw):
        if offset + 12 > len(raw):
            raise ContractError("Truncated PNG chunk header")
        size = struct.unpack(">I", raw[offset:offset + 4])[0]
        kind = raw[offset + 4:offset + 8]
        end = offset + 12 + size
        if end > len(raw):
            raise ContractError("Truncated PNG chunk payload")
        crc = struct.unpack(">I", raw[end - 4:end])[0]
        actual = zlib.crc32(raw[offset + 4:end - 4]) & 0xffffffff
        if crc != actual:
            raise ContractError(f"PNG CRC mismatch: {kind!r}")
        if first:
            if kind != b"IHDR" or size != 13:
                raise ContractError("Missing first PNG IHDR")
            width, height = struct.unpack(">II", raw[offset + 8:offset + 16])
            if not (0 < width <= 65535 and 0 < height <= 65535):
                raise ContractError("Invalid PNG dimensions")
            dimensions, first = (width, height), False
        if kind == b"IDAT":
            seen_idat = True
        if kind == b"IEND":
            if size != 0 or end != len(raw):
                raise ContractError("Invalid or non-terminal IEND")
            seen_iend = True
            break
        offset = end
    if not seen_idat or not seen_iend or dimensions is None:
        raise ContractError("Missing PNG IDAT/IEND")
    return dimensions


def project_plan(point: list[float], zoom: float, origin: list[float]) -> list[float]:
    """Plan to existing 65° Godot 2D view; NOT plan to original PNG pixels."""
    if not (0 < zoom < 100) or len(origin) != 2 or len(point) != 2:
        raise ContractError("Invalid projection input")
    if not all(math.isfinite(float(n)) for n in [*point, *origin, zoom]):
        raise ContractError("Nonfinite projection input")
    return [origin[0] + point[0] * zoom,
            origin[1] + point[1] * zoom * math.sin(math.radians(65))]


def unproject_plan(point: list[float], zoom: float, origin: list[float]) -> list[float]:
    return [(point[0] - origin[0]) / zoom,
            (point[1] - origin[1]) / (zoom * math.sin(math.radians(65)))]


def _unique(objects: list[dict], label: str) -> None:
    ids = [obj.get("id") for obj in objects]
    if any(not isinstance(x, str) or not x for x in ids) or len(ids) != len(set(ids)):
        raise ContractError(f"{label}: duplicate or empty IDs")


def _path(root: Path, rel: str) -> Path:
    if not isinstance(rel, str) or not rel or "\\" in rel:
        raise ContractError(f"Invalid asset path {rel!r}")
    p = Path(rel)
    if p.is_absolute() or ".." in p.parts:
        raise ContractError(f"Unsafe asset path {rel!r}")
    resolved = (root / p).resolve()
    if not resolved.is_relative_to(root.resolve()):
        raise ContractError(f"Asset escapes root {rel!r}")
    return resolved


def verify(root: Path, data: dict, require_hash: bool = False) -> list[str]:
    if data.get("schemaVersion") != 1 or data.get("contractId") != "raven.first-floor-art":
        raise ContractError("Unknown manifest schema/contract")
    source = data["source"]
    src = _path(root, source["path"])
    if not src.is_file():
        raise ContractError(f'Source image missing: {source["path"]}')
    raw = src.read_bytes()
    width, height = png_dimensions(raw)
    if source.get("byteSize") != len(raw):
        raise ContractError("Source byte size drifted")
    observed_sha = hashlib.sha256(raw).hexdigest()
    git_blob_sha = hashlib.sha1(f"blob {len(raw)}\0".encode("ascii") + raw).hexdigest()
    if source.get("gitBlobSha") != git_blob_sha:
        raise ContractError("Source Git blob SHA mismatch")
    warnings = []
    if source.get("sha256") is None or source.get("dimensionsPx") is None:
        warnings.append(f"SOURCE_METADATA_PENDING: SHA256={observed_sha} size={width}x{height}")
        if require_hash:
            raise ContractError("Source SHA256/dimensions must be hydrated before strict validation")
    elif source["sha256"] != observed_sha or source["dimensionsPx"] != [width, height]:
        raise ContractError("Source SHA256 or dimensions mismatch")

    groups = {key: data[key] for key in (
        "rooms", "doors", "navigationReferenceAnchors", "objects",
        "layers", "unresolvedQuestions"
    )}
    for optional in ("imageObservations", "pixelLandmarkCandidates", "occlusionCandidates"):
        if optional in data:
            groups[optional] = data[optional]
    for key, items in groups.items():
        _unique(items, key)
    all_ids = [item["id"] for objects in groups.values() for item in objects]
    if len(all_ids) != len(set(all_ids)):
        raise ContractError("Cross-domain duplicate IDs")
    room_ids = {x["id"] for x in data["rooms"]}
    if len(room_ids) != 8:
        raise ContractError("Expected eight reference rooms")
    def pixel_point(point: list, label: str) -> None:
        if (not isinstance(point, list) or len(point) != 2
                or any(isinstance(n, bool) or not isinstance(n, (int, float)) or not math.isfinite(n)
                       for n in point)
                or not (0 <= point[0] < width and 0 <= point[1] < height)):
            raise ContractError(f"Invalid source-pixel point: {label}")

    for door in data["doors"]:
        for rid in door["roomIds"]:
            if rid is not None and rid not in room_ids:
                raise ContractError(f'Unknown room in {door["id"]}: {rid}')
        if door.get("authoritativeForMovement") is True:
            raise ContractError("Artwork cannot grant navigation or collision authority")
        if door.get("sourcePixelPoint") is not None:
            if door.get("calibrationStatus") != "approx_visual_estimate_not_collision":
                raise ContractError("Visual estimate cannot silently become a calibrated doorway")
            pixel_point(door["sourcePixelPoint"], door["id"])
    for anchor in data["navigationReferenceAnchors"]:
        if anchor["roomId"] not in room_ids:
            raise ContractError(f'Unknown anchor room: {anchor["id"]}')
    for obj in data["objects"]:
        if obj["roomId"] not in room_ids:
            raise ContractError(f'Unknown object room: {obj["id"]}')
        if obj["sourcePixelPivot"] is not None:
            raise ContractError("Unapproved physical pixel pivot supplied")
    for layer in data["layers"]:
        if layer["path"] is not None:
            if not _path(root, layer["path"]).is_file():
                raise ContractError(f'Missing referenced asset: {layer["path"]}')
        elif layer["state"] == "available":
            raise ContractError(f'Available layer without path: {layer["id"]}')
    if data.get("referenceSources"):
        refs = {ref["path"]: ref for ref in data["referenceSources"]}
        world_path = "data/raven/season1_world_map.json"
        graph_path = "data/raven/manor_greybox_graph.json"
        if set(refs) != {world_path, graph_path}:
            raise ContractError("Unexpected geometry source references")
        world = json.loads(_path(root, world_path).read_text("utf-8"))
        graph = json.loads(_path(root, graph_path).read_text("utf-8"))
        if world.get("worldSize") != data["coordinateSystems"]["worldPlan"]["extent"]:
            raise ContractError("World plan extent drifted")
        source_rooms = {r["id"]: r for r in world["rooms"]}
        for room in data["rooms"]:
            if room["id"] not in source_rooms or room["referenceWorldPlanRect"] != source_rooms[room["id"]]["rect"]:
                raise ContractError("World plan room geometry drifted")
        source_doors = {d["id"]: d for d in world["doors"]}
        for door in data["doors"]:
            original = source_doors.get(door["id"])
            if original is None or door["referenceWorldPlanPoint"] != original["point"]:
                raise ContractError("World plan doorway drifted")
            expected = [world["rooms"][i]["id"] if i >= 0 else None for i in (original["a"], original["b"])]
            if door["roomIds"] != expected:
                raise ContractError("World plan door-to-room relation drifted")
        source_anchors = {a["id"]: a for a in graph["anchors"]}
        for anchor in data["navigationReferenceAnchors"]:
            original = source_anchors.get(anchor["id"])
            if original is None or anchor["referenceGreyboxPoint"] != original["position"] or anchor["roomId"] != original["roomId"]:
                raise ContractError("Greybox graph anchor drifted")
        source_objects = {o["id"]: o for o in world["props"]}
        for obj in data["objects"]:
            original = source_objects.get(obj["id"])
            if original is None or obj["referenceWorldPlanRect"] != original["rect"]:
                raise ContractError("World plan object footprint drifted")
    for observation in data.get("imageObservations", []):
        if observation.get("roomId") is not None and observation["roomId"] not in room_ids:
            raise ContractError("Unknown visual observation room ID")
        bounds = observation.get("boundsPx")
        if (not isinstance(bounds, list) or len(bounds) != 4
                or not all(isinstance(x, (float, int)) and not isinstance(x, bool) and math.isfinite(x) for x in bounds)
                or not (0 <= bounds[0] < bounds[2] <= width and 0 <= bounds[1] < bounds[3] <= height)):
            raise ContractError("Invalid visual bounds")
        if observation.get("walkablePolygon") is not None or observation.get("ownerGeometryApproval") != "pending":
            raise ContractError("Unapproved visual observation promoted to gameplay")
    for landmark in data.get("pixelLandmarkCandidates", []):
        if landmark.get("worldPlanPoint") is not None:
            raise ContractError("No painted reference may silently adopt provisional world XY")
        if landmark.get("imagePixelEstimate") is not None:
            pixel_point(landmark["imagePixelEstimate"], landmark["id"])
    for occ in data.get("occlusionCandidates", []):
        if occ.get("status") != "unsegmented":
            raise ContractError("Unreviewed occlusion candidate cannot assert a cutout")
        bounds = occ.get("approxBoundsPx")
        if (not isinstance(bounds, list) or len(bounds) != 4
                or not (0 <= bounds[0] < bounds[2] <= width and 0 <= bounds[1] < bounds[3] <= height)):
            raise ContractError("Invalid occlusion review bound")
    annotation = source.get("previewOnlyAnnotationPath")
    if annotation is not None and not _path(root, annotation).is_file():
        raise ContractError("Missing art-audit annotation")
    mapping = data["coordinateSystems"]["worldPlanToSourcePixel"]
    if mapping["status"] != "unresolved" or mapping["matrix"] is not None:
        raise ContractError("Draft must not assert unverified world-to-raster calibration")
    if data["productionReady"] is not False or data["integrationAllowed"] is not False:
        raise ContractError("Draft art cannot enable production integration")
    for zoom in (.35, .74, 1.0, 2.5):
        for p in ([0, 0], [850, 585], [2150, 2250], [-3.5, 12.25]):
            roundtrip = unproject_plan(project_plan(p, zoom, [112, -53]), zoom, [112, -53])
            if any(abs(a - b) > 1e-7 for a, b in zip(p, roundtrip)):
                raise ContractError("Projection inverse roundtrip failed")
    warnings.append("GEOMETRY_UNCALIBRATED: no approved pixel control pairs, polygons or occlusion masks")
    return warnings


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo-root", type=Path, default=Path(__file__).resolve().parents[4])
    ap.add_argument("--manifest", type=Path, default=MANIFEST)
    ap.add_argument("--hydrate", action="store_true", help="fill byte metadata only")
    ap.add_argument("--strict", action="store_true", help="require pinned SHA256 and dimensions")
    args = ap.parse_args()
    root = args.repo_root.resolve()
    try:
        manifest_path = _path(root, str(args.manifest))
        data = json.loads(manifest_path.read_text("utf-8"))
        if args.hydrate:
            source = data["source"]
            raw = _path(root, source["path"]).read_bytes()
            width, height = png_dimensions(raw)
            source["sha256"] = hashlib.sha256(raw).hexdigest()
            source["dimensionsPx"] = [width, height]
            source["byteSize"] = len(raw)
            manifest_path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        warnings = verify(root, data, require_hash=args.strict)
    except (OSError, KeyError, TypeError, ValueError) as exc:
        print(f"FAIL: {exc}", file=sys.stderr)
        return 1
    print("PASS: PNG complete CRC, referenced files, IDs, links and projection roundtrips")
    for msg in warnings:
        print("PENDING:", msg)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
