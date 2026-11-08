#!/usr/bin/env python3
"""Strict, deterministic draft-only first-floor scene + metadata exporter.

Consumes the OPTIONAL firstFloorDraft schemaVersion=2 extension of a Room
Builder schemaVersion=1 project. Never writes canonical scenes, navigation,
collisions, campaign state or approved geometry.
"""
import base64
import binascii
import hashlib
import json
import math
import re
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
WORLD_MAP = ROOT / "data/raven/season1_world_map.json"
PNG_DATA = re.compile(r"^data:image/png;base64,([A-Za-z0-9+/=]+)$")
ROOM = re.compile(r"^RM-ROOM-[A-Z0-9-]+$")
DOOR = re.compile(r"^RM-DOOR-[A-Z0-9-]+$")
NAV = re.compile(r"^RM-(?:NAV|ANCHOR)-[A-Z0-9-]+$")
FOREGROUND = re.compile(r"^RM-FG-[A-Z0-9-]+$")
MAX_IMAGE = 20 * 1024 * 1024
MAX_ENTRIES = 1000


def finite(value, label):
    if isinstance(value, bool) or not isinstance(value, (int, float)) or not math.isfinite(value):
        raise ValueError(f"{label}: expected finite number")
    return float(value)


def numbers(value, count, label):
    if not isinstance(value, list) or len(value) != count:
        raise ValueError(f"{label}: expected {count} numbers")
    return [finite(item, label) for item in value]


def records(value, label):
    if not isinstance(value, list) or len(value) > MAX_ENTRIES:
        raise ValueError(f"{label}: expected array with at most {MAX_ENTRIES} entries")
    return value


def unique(entries, field, prefix, label):
    seen = set()
    for index, item in enumerate(entries):
        if not isinstance(item, dict) or not isinstance(item.get(field), str) or not re.fullmatch(prefix, item[field]):
            raise ValueError(f"{label}[{index}]: invalid {field}")
        if item[field] in seen:
            raise ValueError(f"{label}: duplicate ID {item[field]}")
        seen.add(item[field])
    return seen


def repo_asset(value):
    if not isinstance(value, str) or not value or "\\" in value or value.startswith("/"):
        raise ValueError("asset path must be relative to repository root")
    parts = Path(value).parts
    if ".." in parts or "." in parts or not re.fullmatch(r"[A-Za-z0-9_./-]+", value):
        raise ValueError("unsafe asset path: " + value)
    if Path(value).suffix.lower() != ".png":
        raise ValueError("Only PNG draft assets supported: " + value)
    file = (ROOT / value).resolve()
    if not file.is_relative_to(ROOT.resolve()) or not file.is_file():
        raise ValueError("Missing asset: " + value)
    if file.stat().st_size > MAX_IMAGE:
        raise ValueError("Asset exceeds 20 MB: " + value)
    return file


def image_bytes(base):
    if not isinstance(base, dict):
        raise ValueError("baseImage is required")
    if ("path" in base) == ("dataUri" in base):
        raise ValueError("baseImage requires exactly one of path / dataUri")
    if "path" in base:
        blob = repo_asset(base["path"]).read_bytes()
    else:
        uri = base["dataUri"]
        match = PNG_DATA.fullmatch(uri) if isinstance(uri, str) else None
        if not match or len(uri) > MAX_IMAGE * 2:
            raise ValueError("baseImage must contain a valid PNG data URI (<=20 MB)")
        try:
            blob = base64.b64decode(match.group(1), validate=True)
        except (binascii.Error, ValueError) as error:
            raise ValueError("Corrupt PNG base64") from error
    if len(blob) < 24 or len(blob) > MAX_IMAGE or not blob.startswith(b"\x89PNG\r\n\x1a\n") or blob[12:16] != b"IHDR":
        raise ValueError("Missing or invalid PNG image")
    width, height = struct.unpack(">II", blob[16:24])
    if not 0 < width <= 16384 or not 0 < height <= 16384:
        raise ValueError("Invalid PNG pixel dimensions")
    if numbers(base.get("pixelSize"), 2, "baseImage.pixelSize") != [width, height]:
        raise ValueError("baseImage.pixelSize does not match actual PNG dimensions")
    return blob, width, height


def point_in_rect(p, r, tolerance=0):
    return r[0]-tolerance <= p[0] <= r[0]+r[2]+tolerance and r[1]-tolerance <= p[1] <= r[1]+r[3]+tolerance


def preview_report(draft, reference):
    by_room = {r["id"]: r for r in reference["rooms"]}
    by_door = {d["id"]: d for d in reference["doors"]}
    return {
        "roomDeltas": [
            {"id": r["id"], "delta": [round(a-b, 4) for a, b in zip(r["rect"], by_room[r["id"]]["rect"])]}
            for r in draft["roomRegions"]
        ],
        "doorDeltas": [
            {"id": d["id"], "delta": [round(a-b, 4) for a, b in zip(d["point"], by_door[d["id"]]["point"])]}
            for d in draft["doorPlacements"]
        ],
        "authority": "PROPOSED_REFERENCE_ONLY_NOT_APPROVED",
    }


def validate_first_floor(project, reference=None):
    """Validate full document BEFORE output I/O. Return (draft, PNG bytes, report)."""
    reference = reference if reference is not None else json.loads(WORLD_MAP.read_text(encoding="utf-8"))
    if not isinstance(project, dict) or project.get("schemaVersion") != 1:
        raise ValueError("Expected Room Builder project schemaVersion=1 (legacy projects stay unchanged)")
    draft = project.get("firstFloorDraft")
    if not isinstance(draft, dict) or draft.get("schemaVersion") != 2 or draft.get("kind") != "raven-first-floor-draft":
        raise ValueError("Unsupported firstFloorDraft schemaVersion/kind (expected v2)")
    png, pw, ph = image_bytes(draft.get("baseImage"))
    calib = draft.get("calibration")
    if not isinstance(calib, dict):
        raise ValueError("calibration is required")
    image_rect = numbers(calib.get("imageRect"), 4, "calibration.imageRect")
    world_rect = numbers(calib.get("worldRect"), 4, "calibration.worldRect")
    if any(v <= 0 for v in [image_rect[2], image_rect[3], world_rect[2], world_rect[3]]):
        raise ValueError("Calibration dimensions must be positive")
    if image_rect != [0, 0, pw, ph]:
        raise ValueError("Calibration imageRect must cover full PNG; image crop is not supported by v2 importer")
    if not point_in_rect(image_rect[:2], [0, 0, pw, ph]) or not point_in_rect([image_rect[0]+image_rect[2], image_rect[1]+image_rect[3]], [0, 0, pw, ph]):
        raise ValueError("Calibration imageRect lies outside base image")
    registration = draft.get("registration")
    unregistered = isinstance(registration, dict) and registration.get("status") == "unresolved"
    if registration is not None:
        if not unregistered or registration.get("imageSpace") != "image-pixel" or registration.get("referenceSpace") != "world-plan" or registration.get("previewSpace") != "screen-projected" or registration.get("pixelToWorld") is not None or registration.get("navigationAllowed") is not False:
            raise ValueError("Unsupported/unsafe registration: no inferred image-pixel to world-plan transform")
    controls = records(calib.get("controlPoints"), "calibration.controlPoints")
    if unregistered:
        if calib.get("status") != "unresolved" or controls:
            raise ValueError("Unregistered art must not declare calibration control points")
    elif len(controls) < 2:
        raise ValueError("At least two calibration controlPoints are required")
    for i, item in enumerate(controls):
        if not isinstance(item, dict):
            raise ValueError(f"Invalid controlPoint #{i}")
        pixel = numbers(item.get("pixel"), 2, "controlPoint.pixel")
        world = numbers(item.get("world"), 2, "controlPoint.world")
        if not point_in_rect(pixel, image_rect, tolerance=1):
            raise ValueError("Calibration controlPoint outside imageRect")
        mapped = [
            world_rect[j] + (pixel[j]-image_rect[j]) * world_rect[j+2] / image_rect[j+2]
            for j in range(2)
        ]
        if math.dist(mapped, world) > 1:
            raise ValueError(f"Mismatched calibration controlPoint #{i}: mapped {mapped} vs {world}")
    rooms = records(draft.get("roomRegions"), "roomRegions")
    doors = records(draft.get("doorPlacements"), "doorPlacements")
    foreground = records(draft.get("foregroundObjects"), "foregroundObjects")
    anchors = records(draft.get("navigationAnchors"), "navigationAnchors")
    room_ids = unique(rooms, "id", ROOM, "roomRegions")
    unique(doors, "id", DOOR, "doorPlacements")
    unique(foreground, "id", FOREGROUND, "foregroundObjects")
    unique(anchors, "id", NAV, "navigationAnchors")
    known_rooms = {r["id"]: r for r in reference["rooms"]}
    known_doors = {d["id"]: d for d in reference["doors"]}
    indexed_rooms = reference["rooms"]
    rects = {}
    for room in rooms:
        rid = room["id"]
        if rid not in known_rooms:
            raise ValueError("Unknown room ID: " + rid)
        rect = numbers(room.get("rect"), 4, rid + ".rect")
        if not 0 < rect[2] <= 8000 or not 0 < rect[3] <= 8000 or not point_in_rect(rect[:2], world_rect) or not point_in_rect([rect[0]+rect[2], rect[1]+rect[3]], world_rect):
            raise ValueError("Invalid/outside-calibration room geometry: " + rid)
        rects[rid] = rect
    for door in doors:
        did = door["id"]
        if did not in known_doors:
            raise ValueError("Unknown door ID: " + did)
        known = known_doors[did]
        expected = [indexed_rooms[known["a"]]["id"], indexed_rooms[known["b"]]["id"] if known["b"] >= 0 else None]
        if door.get("rooms") != expected:
            raise ValueError(f"Door {did} has invalid room references, expected {expected}")
        if expected[0] not in room_ids or (expected[1] is not None and expected[1] not in room_ids):
            raise ValueError("Door references missing room: " + did)
        pos = numbers(door.get("point"), 2, did + ".point")
        if not point_in_rect(pos, world_rect):
            raise ValueError("Door outside calibrated world: " + did)
        if any(not point_in_rect(pos, rects[rid], tolerance=16) for rid in expected if rid is not None):
            raise ValueError("Invalid door placement (not touching referenced rooms): " + did)
        width = finite(door.get("width"), did + ".width")
        if not 1 <= width <= 500:
            raise ValueError("Invalid door width: " + did)
    visited = set()
    for anchor in anchors:
        rid = anchor.get("roomId")
        if rid not in room_ids:
            raise ValueError("Unknown navigation anchor room ID: " + str(rid))
        point = numbers(anchor.get("point"), 2, anchor["id"] + ".point")
        if not point_in_rect(point, rects[rid], tolerance=1):
            raise ValueError("Navigation anchor outside room: " + anchor["id"])
        key = (rid, round(point[0], 3), round(point[1], 3))
        if key in visited:
            raise ValueError("Duplicate navigation point coordinates in " + rid)
        visited.add(key)
    if unregistered and (anchors or foreground):
        raise ValueError("Unregistered image cannot claim world-plan navigation anchors or foreground pivots")
    for item in foreground:
        pos = numbers(item.get("position"), 2, item["id"] + ".position")
        size = numbers(item.get("size"), 2, item["id"] + ".size")
        pivot = numbers(item.get("pivot"), 2, item["id"] + ".pivot")
        if not 0 < size[0] <= 8000 or not 0 < size[1] <= 8000 or not 0 <= pivot[0] <= size[0] or not 0 <= pivot[1] <= size[1]:
            raise ValueError("Invalid floor-contact pivot or size: " + item["id"])
        if not point_in_rect(pos, world_rect):
            raise ValueError("Foreground pivot outside calibrated world: " + item["id"])
        room = item.get("roomId")
        if room not in room_ids or not point_in_rect(pos, rects[room], tolerance=1):
            raise ValueError("Foreground pivot outside room: " + item["id"])
        repo_asset(item.get("assetPath"))
        occ = item.get("occlusion")
        if not isinstance(occ, dict) or occ.get("mode") not in {"foot_y", "fixed_front", "none"}:
            raise ValueError("Invalid occlusion mode: " + item["id"])
        if occ.get("alphaMaskPath") is not None:
            repo_asset(occ["alphaMaskPath"])
    return draft, png, preview_report(draft, reference)


def q(value):
    return json.dumps(str(value), ensure_ascii=False)


def v(x, y):
    return f"Vector2({x:.4f}, {y:.4f})"


def node_id(s):
    return re.sub(r"[^A-Za-z0-9_]", "_", s)


def scene_from_first_floor(project, output_root=ROOT, reference=None):
    """Return (generated scene, counts). Both output files are deterministic."""
    draft, png, report = validate_first_floor(project, reference)
    output_root = Path(output_root)
    scene_dir = output_root / "scenes/raven/generated"
    digest = hashlib.sha256(png).hexdigest()[:16]
    path = scene_dir / "RM_FIRST_FLOOR_DRAFT_v2.tscn"
    metadata_path = scene_dir / "RM_FIRST_FLOOR_DRAFT_v2.json"
    image_path = output_root / f"assets/raven/generated/first_floor/base_{digest}.png"
    base = draft["baseImage"]
    bg_path = "res://" + base["path"] if "path" in base else "res://" + image_path.relative_to(output_root).as_posix()
    paths = sorted({bg_path} | {"res://" + obj["assetPath"] for obj in draft["foregroundObjects"]})
    ids = {p: str(i+1) for i, p in enumerate(paths)}
    cal = draft["calibration"]
    ix, iy, iw, ih = cal["imageRect"]
    wx, wy, ww, wh = cal["worldRect"]
    unregistered = draft.get("registration", {}).get("status") == "unresolved"
    image_x, image_y = (0, 0) if unregistered else (wx, wy)
    image_w, image_h = (iw, ih) if unregistered else (ww, wh)
    lines = [f"[gd_scene load_steps={len(paths)+1} format=3]", ""]
    lines += [f'[ext_resource type="Texture2D" path={q(p)} id={q(ids[p])}]' for p in paths]
    lines += ["", '[node name="RM_FIRST_FLOOR_DRAFT_v2" type="Node2D"]',
              'metadata/geometry_approval = "DRAFT_ONLY"',
              'metadata/import_kind = "FIRST_FLOOR_IMAGE_REVIEW_ONLY"',
              'metadata/import_schema_version = 2',
              'metadata/physics_authority = "NONE"',
              'metadata/navigation_authority = "NONE"',
              f'metadata/registration_status = {q("UNREGISTERED_IMAGE_PIXEL" if unregistered else "ILLUSTRATIVE_VISUAL_ONLY")}', ""]
    lines += ['[node name="ReviewCamera" type="Camera2D" parent="."]',
              f'position = {v(image_x+image_w/2, image_y+image_h/2)}', 'zoom = Vector2(0.7400, 0.7400)',
              'enabled = true', ""]
    # Image is already painted/projected; DO NOT apply the old 65-degree floor compression twice.
    lines += ['[node name="BasePainting" type="TextureRect" parent="."]',
              f'texture = ExtResource({q(ids[bg_path])})',
              'expand_mode = 1', 'stretch_mode = 0',
              f'offset_left = {image_x:.4f}', f'offset_top = {image_y:.4f}',
              f'offset_right = {image_x+image_w:.4f}', f'offset_bottom = {image_y+image_h:.4f}',
              'z_index = -3000', 'metadata/approval = "OWNER_ART_REFERENCE_NOT_RUNTIME"', ""]
    lines += ['[node name="ReviewGuides" type="Node2D" parent="."]',
              *(['visible = false'] if unregistered else []),
              f'metadata/coordinate_space = {q("world-plan" if unregistered else "illustrative-world-plan")}',
              'metadata/status = "VISUAL_REVIEW_ONLY_NO_PHYSICS"', ""]
    for room in draft["roomRegions"]:
        x, y, w, h = room["rect"]
        node = node_id(room["id"])
        lines += [f'[node name="{node}" type="Line2D" parent="ReviewGuides"]',
                  f'points = PackedVector2Array({x:.4f}, {y:.4f}, {x+w:.4f}, {y:.4f}, {x+w:.4f}, {y+h:.4f}, {x:.4f}, {y+h:.4f}, {x:.4f}, {y:.4f})',
                  'width = 2.0000', 'default_color = Color(0.28, 0.85, 0.92, 0.8)',
                  f'metadata/room_id = {q(room["id"])}', ""]
    for door in draft["doorPlacements"]:
        x, y = door["point"]
        lines += [f'[node name="{node_id(door["id"])}" type="Marker2D" parent="ReviewGuides"]',
                  f'position = {v(x, y)}', f'metadata/door_id = {q(door["id"])}',
                  f'metadata/from_room = {q(door["rooms"][0])}',
                  f'metadata/to_room = {q(door["rooms"][1] or "")}',
                  f'metadata/draft_width = {door["width"]:.4f}', ""]
        lines += [f'[node name="{node_id(door["id"])}_Dot" type="Polygon2D" parent="ReviewGuides"]',
                  f'position = {v(x, y)}',
                  'color = Color(1, 0.57, 0.24, 0.95)',
                  'polygon = PackedVector2Array(-5, -5, 5, -5, 5, 5, -5, 5)', ""]
    for a in draft["navigationAnchors"]:
        x, y = a["point"]
        lines += [f'[node name="{node_id(a["id"])}" type="Marker2D" parent="ReviewGuides"]',
                  f'position = {v(x, y)}', f'metadata/anchor_id = {q(a["id"])}',
                  f'metadata/room_id = {q(a["roomId"])}',
                  'metadata/authoritative_navigation = false', ""]
    for obj in draft["foregroundObjects"]:
        x, y = obj["position"]
        sw, sh = obj["size"]
        px, py = obj["pivot"]
        res = "res://" + obj["assetPath"]
        mode = obj["occlusion"]["mode"]
        z = 3500 if mode == "fixed_front" else (0 if mode == "none" else int(max(-1000, min(3000, y))))
        lines += [f'[node name="{node_id(obj["id"])}" type="TextureRect" parent="."]',
                  f'texture = ExtResource({q(ids[res])})', 'expand_mode = 1', 'stretch_mode = 0',
                  f'offset_left = {x-px:.4f}', f'offset_top = {y-py:.4f}',
                  f'offset_right = {x-px+sw:.4f}', f'offset_bottom = {y-py+sh:.4f}',
                  f'z_index = {z}', f'metadata/foreground_id = {q(obj["id"])}',
                  f'metadata/pivot_world = {v(x, y)}', f'metadata/occlusion_mode = {q(mode)}',
                  'metadata/collision = "NOT_GENERATED"', ""]
    manifest = {"kind": "raven_first_floor_draft_export", "schemaVersion": 2,
                "approval": "DRAFT_ONLY", "source": draft, "comparison": report,
                "coordinateSpaces": {"baseImage": "image-pixel" if unregistered else "illustrative-screen-preview",
                                     "roomRegions": "world-plan", "doorPlacements": "world-plan",
                                     "navigation": "NONE", "screenProjectedToNavigation": "FORBIDDEN"}}
    serialized = json.dumps(manifest, ensure_ascii=False, sort_keys=True, indent=2) + "\n"
    scene_dir.mkdir(parents=True, exist_ok=True)
    if "dataUri" in base:
        image_path.parent.mkdir(parents=True, exist_ok=True)
        image_path.write_bytes(png)
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    metadata_path.write_text(serialized, encoding="utf-8")
    return path, {"rooms": len(draft["roomRegions"]), "doors": len(draft["doorPlacements"]),
                  "anchors": len(draft["navigationAnchors"]), "foreground": len(draft["foregroundObjects"]),
                  "manifest": str(metadata_path), "approval": "DRAFT_ONLY"}


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("json_path", type=Path)
    parser.add_argument("--output-root", type=Path, default=ROOT)
    args = parser.parse_args()
    if args.json_path.stat().st_size > 45 * 1024 * 1024:
        parser.error("JSON exceeds 45 MB")
    project = json.loads(args.json_path.read_text(encoding="utf-8"))
    print(scene_from_first_floor(project, args.output_root))
