#!/usr/bin/env python3
"""Convert a Room Builder export into a DRAFT-only projected Godot review scene.

No gameplay changes: no collision bodies, nav, character positions or campaign
save changes. The generator builds a visible 65-degree room composition from
catalog pilot art, locally embedded PNG/JPEG/WebP, and marked placeholders.

python3 scripts/raven/tools/import_room_builder_game.py path/to/export.json
Run/inspect the resulting scenes/raven/generated/RM_ROOM_*_GamePreview.tscn.
"""
import argparse
import base64
import binascii
import hashlib
import json
import math
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
WORLD_MAP = ROOT / "data/raven/season1_world_map.json"
HALL_CONTRACT = ROOT / "data/raven/hall_visual_contract.json"
URI = re.compile(r"^data:image/(png|jpeg|webp);base64,([a-zA-Z0-9+/=]+)$")
ROOM_ID = re.compile(r"^RM-ROOM-[A-Z0-9-]+$")
SAFE = re.compile(r"[^a-zA-Z0-9_-]+")
MAX_IMAGE = 16 * 1024 * 1024
MAX_OBJECTS = 20000
FLOOR_RATIO = math.sin(math.radians(65))


def num(value, label):
    if isinstance(value, bool) or not isinstance(value, (float, int)) or not math.isfinite(value):
        raise ValueError(f"{label} must be a finite number")
    return float(value)


def numeric_str(value):
    return f"{float(value):.4f}"


def q(value):
    return json.dumps(str(value), ensure_ascii=False)


def safe(value):
    return SAFE.sub("_", str(value))[:90] or "Unknown"


def vec(x, y):
    return f"Vector2({numeric_str(x)}, {numeric_str(y)})"


def validate_room(project, reference):
    if not isinstance(project, dict) or project.get("schemaVersion") != 1:
        raise ValueError("Expected Room Builder project schemaVersion 1")
    room_id = project.get("roomId")
    if not isinstance(room_id, str) or not ROOM_ID.fullmatch(room_id):
        raise ValueError("Invalid RM-ROOM ID")
    matching = [r for r in reference["rooms"] if r["id"] == room_id]
    if len(matching) != 1:
        raise ValueError("Room does not exist in proposed Godot world map: " + room_id)
    world_rect = matching[0]["rect"]
    width = num(project.get("width"), "width")
    height = num(project.get("height"), "height")
    if (width, height) != tuple(map(float, world_rect[2:])):
        raise ValueError(
            f"{room_id}: draft {width:g} x {height:g} does not match Godot "
            f"{world_rect[2]} x {world_rect[3]}; create a separate map-sized draft, "
            "do not silently rescale furniture."
        )
    assets_list, layer_list, objects = (project.get(k) for k in ("assets", "layers", "objects"))
    if not isinstance(assets_list, list) or not isinstance(layer_list, list) or not isinstance(objects, list):
        raise ValueError("Project must provide assets/layers/objects arrays")
    if len(assets_list) > 2000 or len(layer_list) > 50 or len(objects) > MAX_OBJECTS:
        raise ValueError("Room document exceeds editor limits")
    assets = {}
    for a in assets_list:
        if not isinstance(a, dict) or not isinstance(a.get("id"), str) or a["id"] in assets:
            raise ValueError("Invalid/duplicate asset ID")
        if not isinstance(a.get("kind"), str):
            raise ValueError("Asset kind missing: " + a["id"])
        assets[a["id"]] = a
    layers = {}
    for i, layer in enumerate(layer_list):
        if not isinstance(layer, dict) or not isinstance(layer.get("id"), str) or layer["id"] in layers:
            raise ValueError("Invalid/duplicate layer ID")
        layers[layer["id"]] = (i, layer)
    ids = set()
    for i, obj in enumerate(objects):
        if not isinstance(obj, dict) or not isinstance(obj.get("id"), str) or obj["id"] in ids:
            raise ValueError(f"Invalid/duplicate object #{i}")
        ids.add(obj["id"])
        if obj.get("assetId") not in assets or obj.get("layerId") not in layers:
            raise ValueError(f"Object #{i} has missing asset or layer")
        for key in ("x", "y", "w", "h", "rotation"):
            num(obj.get(key, 0 if key == "rotation" else None), f"object #{i} {key}")
        if not (0 < obj["w"] <= 8000 and 0 < obj["h"] <= 8000):
            raise ValueError("Invalid object width/height")
    walls, openings = project.get("walls", []), project.get("openings", [])
    if not isinstance(walls, list) or not isinstance(openings, list) or len(walls) > 4000 or len(openings) > 2000:
        raise ValueError("Invalid walls/openings arrays")
    wall_ids = set()
    for i, wall in enumerate(walls):
        if not isinstance(wall, dict) or not isinstance(wall.get("id"), str) or wall["id"] in wall_ids:
            raise ValueError(f"Invalid/duplicate wall #{i}")
        coords = [num(wall.get(k), f"wall #{i} {k}") for k in ("ax", "ay", "bx", "by")]
        thickness = num(wall.get("thickness"), f"wall #{i} thickness")
        if wall.get("style") not in {"grand", "residential", "service", "glass"} or not 4 <= thickness <= 100:
            raise ValueError(f"Invalid wall style/thickness #{i}")
        if coords[0] == coords[2] and coords[1] == coords[3]:
            raise ValueError("Wall must have a positive length")
        if coords[0] != coords[2] and coords[1] != coords[3]:
            raise ValueError("Walls must be orthogonal")
        if not all(0 <= value <= (width if index % 2 == 0 else height) for index, value in enumerate(coords)):
            raise ValueError("Wall lies outside room")
        wall_ids.add(wall["id"])
    opening_ids = set()
    for i, opening in enumerate(openings):
        if not isinstance(opening, dict) or not isinstance(opening.get("id"), str) or opening["id"] in opening_ids or opening.get("wallId") not in wall_ids:
            raise ValueError(f"Invalid/duplicate opening #{i}")
        if opening.get("kind") not in {"door", "double_door", "arch", "window", "glass", "stair"}:
            raise ValueError("Invalid opening kind")
        width_value, offset = num(opening.get("width"), "opening width"), num(opening.get("offset"), "opening offset")
        wall = next(w for w in walls if w["id"] == opening["wallId"])
        wall_length = math.hypot(wall["bx"]-wall["ax"], wall["by"]-wall["ay"])
        if width_value < 16 or width_value > wall_length or not 0 <= offset <= 1:
            raise ValueError("Invalid opening dimensions")
        door_id = opening.get("doorId", "")
        if door_id and not re.fullmatch(r"RM-DOOR-[A-Z0-9-]+", door_id):
            raise ValueError("Invalid RM-DOOR ID")
        opening_ids.add(opening["id"])
    for wall in walls:
        wall_length = math.hypot(wall["bx"]-wall["ax"], wall["by"]-wall["ay"])
        intervals = []
        for opening in (item for item in openings if item["wallId"] == wall["id"]):
            half = min(float(opening["width"])/2, wall_length/2)
            center = max(half, min(wall_length-half, float(opening["offset"])*wall_length))
            intervals.append((center-half, center+half))
        intervals.sort()
        if any(current[0] < previous[1] for previous, current in zip(intervals, intervals[1:])):
            raise ValueError("Openings on one wall overlap")
    return world_rect, assets, layers, objects, walls, openings


def piloted_hall_texture(obj, asset, contract):
    if asset.get("kind") == "character" or contract is None:
        return None
    ref = obj.get("assetRefId")
    source = next((s for s in contract["sprites"] if s["assetRefId"] == ref), None)
    if not source or obj.get("state", source["state"]) != source["state"]:
        return None  # Never label an experimental clean PNG as a broken/dirty state.
    if abs(num(obj.get("rotation", 0), "rotation")) > 0.0001:
        return None  # Rotated pilot is not certified to match the original editor mask.
    file_name = source["file"]
    if not re.fullmatch(r"[a-z_]+\.png", file_name):
        raise ValueError("Unsafe pilot texture name")
    texture = ROOT / "assets/raven/hall/generated_pilot/props" / file_name
    if not texture.is_file():
        # In an externally copied checkout missing optional pilot art, render placeholder.
        return None
    return texture, source["mode"]


def scene_from_project(project, output_root=ROOT, reference=None, contract=None):
    """Write an isolated game-projected scene. Return (scene path, metrics)."""
    reference = reference or json.loads(WORLD_MAP.read_text(encoding="utf-8"))
    contract = contract or json.loads(HALL_CONTRACT.read_text(encoding="utf-8"))
    world_rect, assets, layers, objects, walls, openings = validate_room(project, reference)
    room_id = project["roomId"]
    w, h = float(world_rect[2]), float(world_rect[3])
    scene_dir = output_root / "scenes/raven/generated"
    image_dir = output_root / "assets/raven/generated" / safe(room_id.replace('-', '_'))

    # Prepare every output before touching any files. Every imported texture is
    # hashed by identity so assets with sanitization-colliding IDs stay distinct.
    local_images = {}
    local_bytes = {}
    prepared = []
    metrics = {"objects": len(objects), "walls": len(walls), "openings": len(openings),
               "rendered": 0, "pilot": 0, "embedded": 0,
               "placeholders": 0, "ignoredCharacters": 0}
    for obj in objects:
        asset = assets[obj["assetId"]]
        if asset["kind"] == "character":
            metrics["ignoredCharacters"] += 1
            continue  # Only room/map composition is exported, not test actors.
        if layers[obj["layerId"]][1].get("visible", True) is False:
            continue
        pilot = piloted_hall_texture(obj, asset, contract if room_id == "RM-ROOM-HALL" else None)
        texture, mode, provenance = (pilot[0], pilot[1], "PILOT") if pilot else (None, "", "PLACEHOLDER")
        raw_uri = asset.get("image")
        if not texture and isinstance(raw_uri, str):
            match = URI.fullmatch(raw_uri)
            if not match:
                raise ValueError("Embedded image must be a PNG/JPEG/WebP data URI")
            if len(raw_uri) > MAX_IMAGE * 2:
                raise ValueError("Embedded image data URI too large")
            try:
                binary = base64.b64decode(match.group(2), validate=True)
            except (binascii.Error, ValueError) as exc:
                raise ValueError("Invalid embedded image base64") from exc
            if len(binary) > MAX_IMAGE or not binary:
                raise ValueError("Embedded image exceeds 16 MB or empty")
            ext = {"png": "png", "jpeg": "jpg", "webp": "webp"}[match.group(1)]
            digest = hashlib.sha256(asset["id"].encode("utf8")).hexdigest()[:14]
            filename = safe(asset["id"])[:46] + "_" + digest + "." + ext
            texture = image_dir / filename
            local_bytes[texture] = binary
            local_images[asset["id"]] = texture
            mode = "floor" if asset["kind"] == "tile" or obj["layerId"] == "floor" else "upright"
            provenance = "EMBEDDED"
        if not mode:
            mode = "floor" if asset["kind"] == "tile" or obj["layerId"] == "floor" else "upright"
        metrics["rendered"] += 1
        metrics[{"PILOT": "pilot", "EMBEDDED": "embedded", "PLACEHOLDER": "placeholders"}[provenance]] += 1
        prepared.append((obj, asset, texture, mode, provenance))

    def resource_path(path):
        if path.is_relative_to(output_root):
            return "res://" + path.relative_to(output_root).as_posix()
        if path.is_relative_to(ROOT):
            return "res://" + path.relative_to(ROOT).as_posix()
        raise ValueError("Texture lies outside Godot repository")

    textures = sorted({resource_path(path) for _, _, path, _, _ in prepared if path})
    # The actual Hall background is the SAME original PILOT image Builder displays.
    hall_bg = ROOT / "assets/raven/hall/generated_pilot/backgrounds/hall_twin_staircases.png"
    if room_id == "RM-ROOM-HALL" and hall_bg.is_file():
        textures.append(resource_path(hall_bg))
    textures = sorted(set(textures))
    ids = {path: str(i + 1) for i, path in enumerate(textures)}
    lines = [f"[gd_scene load_steps={len(textures) + 1} format=3]", ""]
    for path in textures:
        lines.append(f'[ext_resource type="Texture2D" path={q(path)} id={q(ids[path])}]')
    summary = f'{metrics["pilot"]} pilot, {metrics["embedded"]} embedded, {metrics["placeholders"]} placeholders'
    lines.extend(["", f'[node name={q(safe(room_id.replace('-', '_')) + "_GamePreview")} type="Node2D"]',
                  'metadata/geometry_approval = "DRAFT_ONLY"',
                  'metadata/import_kind = "ROOM_BUILDER_GAME_VISUAL_ONLY"',
                  'metadata/game_camera_degrees = 65',
                  'metadata/ignore_test_characters = true',
                  f'metadata/room_id = {q(room_id)}',
                  f'metadata/world_origin = {vec(world_rect[0], world_rect[1])}',
                  f'metadata/source_size = {vec(w, h)}',
                  f'metadata/summary = {q(summary)}', ""])

    # Explicit screen-space 65° projection in preview. No physics bodies or
    # navigational edge mutations. Camera is centered for review at native
    # Godot prototype zoom; users can adjust it in Godot Inspector.
    lines.extend(['[node name="ReviewCamera" type="Camera2D" parent="."]',
                  f'position = {vec(w / 2, h * FLOOR_RATIO / 2)}',
                  'zoom = Vector2(0.7400, 0.7400)', 'enabled = true', ""])
    lines.extend(['[node name="DraftFloor" type="Polygon2D" parent="."]',
                  'color = Color(0.36, 0.32, 0.34, 1)',
                  f'polygon = PackedVector2Array(0, 0, {numeric_str(w)}, 0, {numeric_str(w)}, {numeric_str(h * FLOOR_RATIO)}, 0, {numeric_str(h * FLOOR_RATIO)})',
                  'z_index = -3000', ""])

    if walls:
        lines.extend(['[node name="DraftWalls" type="Node2D" parent="."]',
                      'metadata/status = "DRAFT_VISUAL_ONLY_NO_PHYSICS"', ""])
        style_colors = {"grand": "0.37, 0.27, 0.25", "residential": "0.42, 0.35, 0.33",
                        "service": "0.35, 0.38, 0.39", "glass": "0.32, 0.44, 0.42"}
        for i, wall in enumerate(walls):
            ax, ay, bx, by = (float(wall[k]) for k in ("ax", "ay", "bx", "by"))
            length = math.hypot(bx-ax, by-ay)
            intervals = []
            for opening in (o for o in openings if o["wallId"] == wall["id"]):
                half = min(float(opening["width"])/2, length/2)
                center = max(half, min(length-half, float(opening["offset"])*length))
                intervals.append((center-half, center+half))
            intervals.sort()
            runs, cursor = [], 0.0
            for start, end in intervals:
                if start > cursor:
                    runs.append((cursor, start))
                cursor = max(cursor, end)
            if cursor < length:
                runs.append((cursor, length))
            dx, dy = (bx-ax)/length, (by-ay)/length
            for run_index, (start, end) in enumerate(runs):
                sx, sy, ex, ey = ax+dx*start, ay+dy*start, ax+dx*end, ay+dy*end
                lines.extend([f'[node name={q("Wall_" + safe(wall["id"]) + "_" + str(i) + "_" + str(run_index))} type="Line2D" parent="DraftWalls"]',
                              f'points = PackedVector2Array({numeric_str(sx)}, {numeric_str(sy * FLOOR_RATIO)}, {numeric_str(ex)}, {numeric_str(ey * FLOOR_RATIO)})',
                              f'width = {numeric_str(wall["thickness"])}',
                              f'default_color = Color({style_colors[wall["style"]]}, 1)',
                              f'metadata/builder_wall_id = {q(wall["id"])}',
                              f'metadata/wall_style = {q(wall["style"])}',
                              'metadata/physics_authority = "NONE_DRAFT_ONLY"', ""])
        for i, opening in enumerate(openings):
            wall = next(w for w in walls if w["id"] == opening["wallId"])
            ox = float(wall["ax"]) + (float(wall["bx"])-float(wall["ax"])) * float(opening["offset"])
            oy = float(wall["ay"]) + (float(wall["by"])-float(wall["ay"])) * float(opening["offset"])
            lines.extend([f'[node name={q("Opening_" + safe(opening["id"]) + "_" + str(i))} type="Marker2D" parent="DraftWalls"]',
                          f'position = {vec(ox, oy * FLOOR_RATIO)}',
                          f'metadata/builder_opening_id = {q(opening["id"])}',
                          f'metadata/wall_id = {q(opening["wallId"])}',
                          f'metadata/opening_kind = {q(opening["kind"])}',
                          f'metadata/opening_width = {numeric_str(opening["width"])}',
                          f'metadata/door_id = {q(opening.get("doorId", ""))}',
                          f'metadata/foreground_occluder_requested = {str(bool(opening.get("foreground", True))).lower()}',
                          'metadata/approval = "DRAFT_ONLY"', ""])

    if room_id == "RM-ROOM-HALL" and hall_bg.is_file():
        bg = resource_path(hall_bg)
        lines.extend(['[node name="HallPilotBackground" type="TextureRect" parent="."]',
                      f'texture = ExtResource({q(ids[bg])})', 'expand_mode = 1',
                      'stretch_mode = 0', f'offset_right = {numeric_str(w)}',
                      f'offset_bottom = {numeric_str(h * FLOOR_RATIO)}', 'z_index = -2500',
                      'metadata/approval = "PILOT_NOT_APPROVED"', ""])

    for index, (obj, asset, texture, mode, provenance) in enumerate(prepared):
        x, y, ow, oh = [float(obj[k]) for k in ("x", "y", "w", "h")]
        rect_h = oh * FLOOR_RATIO if mode == "floor" else oh
        visual_y = y * FLOOR_RATIO if mode == "floor" else (y + oh) * FLOOR_RATIO - oh
        visual_x = x
        z = -1500 if mode == "floor" else min(3000, max(-1000, int(y + oh)))
        if obj["layerId"] == "foreground":
            z = 3100  # explicit author foreground overrides foot sorting
        node = safe(obj["id"]) + "_" + str(index)
        lines.extend([f'[node name={q(node)} type="Node2D" parent="."]',
                      f'position = {vec(visual_x + ow / 2, visual_y + rect_h / 2)}',
                      f'rotation_degrees = {numeric_str(obj.get("rotation", 0))}',
                      f'z_index = {z}',
                      f'metadata/builder_instance_id = {q(obj["id"])}',
                      f'metadata/asset_id = {q(obj["assetId"])}',
                      f'metadata/asset_ref_id = {q(obj.get("assetRefId", ""))}',
                      f'metadata/hotspot_id = {q(obj.get("hotspotId", ""))}',
                      f'metadata/visual_state = {q(obj.get("state", "default"))}',
                      f'metadata/world_local_top_left = {vec(x, y)}',
                      f'metadata/world_local_size = {vec(ow, oh)}',
                      f'metadata/art_provenance = {q(provenance)}',
                      f'metadata/visual_mode = {q(mode)}', ""])
        child_path = q(node)
        if texture:
            path = resource_path(texture)
            lines.extend([f'[node name="Art" type="TextureRect" parent={child_path}]',
                          f'texture = ExtResource({q(ids[path])})',
                          'expand_mode = 1', 'stretch_mode = 0',
                          f'offset_left = {numeric_str(-ow / 2)}',
                          f'offset_top = {numeric_str(-rect_h / 2)}',
                          f'offset_right = {numeric_str(ow / 2)}',
                          f'offset_bottom = {numeric_str(rect_h / 2)}', ""])
        else:
            color = asset.get("color", "#80627a").lstrip("#")
            if not re.fullmatch(r"[0-9a-fA-F]{6}", color):
                color = "80627a"
            rgb = [int(color[i:i+2], 16) / 255 for i in (0, 2, 4)]
            lines.extend([f'[node name="UnrenderedPlaceholder" type="Polygon2D" parent={child_path}]',
                          f'color = Color({numeric_str(rgb[0])}, {numeric_str(rgb[1])}, {numeric_str(rgb[2])}, 0.85)',
                          f'polygon = PackedVector2Array({numeric_str(-ow / 2)}, {numeric_str(-rect_h / 2)}, {numeric_str(ow / 2)}, {numeric_str(-rect_h / 2)}, {numeric_str(ow / 2)}, {numeric_str(rect_h / 2)}, {numeric_str(-ow / 2)}, {numeric_str(rect_h / 2)})',
                          'metadata/approval = "UNRENDERED_PLACEHOLDER"', ""])

    # Anchors are review markers only: exported metadata cannot change story
    # navigation, locked doors, interactive hitboxes or persistent object state.
    for i, anchor in enumerate(project.get("anchors", [])):
        if not isinstance(anchor, dict) or not all(key in anchor for key in ("id", "x", "y")):
            continue
        ax, ay = num(anchor["x"], "anchor x"), num(anchor["y"], "anchor y")
        lines.extend([f'[node name={q("Anchor_" + safe(anchor["id"]) + "_" + str(i))} type="Marker2D" parent="."]',
                      f'position = {vec(ax, ay * FLOOR_RATIO)}',
                      f'metadata/nav_id = {q(anchor["id"])}',
                      f'metadata/hotspot_id = {q(anchor.get("hotspotId", ""))}', ""])

    # Exact map collision/architectural reference outlines from the original
    # Godot feasibility map. They are OFF by default, review only: never
    # instantiate StaticBody2D, collision shapes or navigation modifications.
    footprints = project.get("referenceFootprints", [])
    if not isinstance(footprints, list) or len(footprints) > 1000:
        raise ValueError("Invalid reference footprints")
    if footprints:
        lines.extend(['[node name="ReferenceGeometry" type="Node2D" parent="."]',
                      "visible = false", 'metadata/status = "MAP_GEOMETRY_GUIDES_ONLY"', ""])
        seen_refs = set()
        for i, footprint in enumerate(footprints):
            if not isinstance(footprint, dict) or not isinstance(footprint.get("id"), str):
                raise ValueError("Missing footprint reference ID")
            if footprint["id"] in seen_refs:
                raise ValueError("Duplicate footprint reference")
            seen_refs.add(footprint["id"])
            gx, gy, gw, gh = (num(footprint.get(key), "reference "+key)
                              for key in ("x", "y", "w", "h"))
            if not (0 < gw <= 8000 and 0 < gh <= 8000):
                raise ValueError("Invalid reference footprint size")
            points = [
                vec(gx, gy * FLOOR_RATIO),
                vec(gx + gw, gy * FLOOR_RATIO),
                vec(gx + gw, (gy + gh) * FLOOR_RATIO),
                vec(gx, (gy + gh) * FLOOR_RATIO),
                vec(gx, gy * FLOOR_RATIO)
            ]
            lines.extend([
                f'[node name={q("MapFootprint_" + safe(footprint["id"]) + "_" + str(i))} type="Line2D" parent="ReferenceGeometry"]',
                "points = PackedVector2Array(" + ", ".join(x[len("Vector2("):-1] for x in points) + ")",
                'default_color = Color(0.98, 0.76, 0.37, 0.78)',
                "width = 2.0000",
                f'metadata/source_prop_id = {q(footprint["id"])}',
                f'metadata/world_local_top_left = {vec(gx, gy)}',
                f'metadata/world_local_size = {vec(gw, gh)}', ""
            ])

    scene_path = scene_dir / (safe(room_id.replace('-', '_')) + "_GamePreview.tscn")
    scene_dir.mkdir(parents=True, exist_ok=True)
    for path, binary in local_bytes.items():
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(binary)
    scene_path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    return scene_path, metrics


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("json_path", type=Path, help="The downloaded Builder room JSON")
    parser.add_argument("--output-root", type=Path, default=ROOT, help="Godot checkout root")
    args = parser.parse_args()
    if args.json_path.stat().st_size > 45 * 1024 * 1024:
        parser.error("JSON exceeds 45 MB")
    document = json.loads(args.json_path.read_text(encoding="utf-8"))
    path, metrics = scene_from_project(document, args.output_root)
    print(f"Imported DRAFT game-projected room: {path}\n"
          f"  {metrics['rendered']} placed room items: {metrics['pilot']} pilot PNG, "
          f"{metrics['embedded']} embedded PNG/JPEG/WebP, {metrics['placeholders']} placeholders\n"
          f"  {metrics['ignoredCharacters']} editor characters deliberately excluded\n"
          "Open .tscn in Godot (F6 to run the current scene). No game nav/collision/save change.")


if __name__ == "__main__":
    main()
