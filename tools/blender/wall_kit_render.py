"""Render the full wall kit: four styles, seven pieces, plus a manifest of anchors.

    blender -b -noaudio -P tools/blender/wall_kit.py

Every piece is procedural. The manifest records the world size, the alpha bounding box and the
projected position of the pivot (0,0,0 — inner face at the floor, start of the run), which is
what the Room Builder needs to place a sprite on a wall line.
"""
from __future__ import annotations

import json
import math
import sys
from pathlib import Path

import bpy
from bpy_extras.object_utils import world_to_camera_view
from mathutils import Vector

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import kit_geometry as kit  # noqa: E402

ROOT = HERE.parents[1]
OUT = ROOT / "build/blender_kit"
ELEVATION = 50.0
AZIMUTH = 0.0          # front-facing billboards for the builder
SIZE = (640, 640)

STYLES = {
    "grand": {"plinth": (0.16, 0.10, 0.07), "wainscot": (0.33, 0.19, 0.12),
              "rail": (0.72, 0.56, 0.26), "upper": (0.42, 0.16, 0.13),
              "crown": (0.16, 0.10, 0.07), "wood": (0.30, 0.17, 0.10),
              "stone": (0.58, 0.53, 0.46), "metal": 0.85},
    "residential": {"plinth": (0.20, 0.14, 0.10), "wainscot": (0.40, 0.28, 0.18),
                    "rail": (0.62, 0.50, 0.32), "upper": (0.34, 0.20, 0.19),
                    "crown": (0.20, 0.14, 0.10), "wood": (0.38, 0.25, 0.15),
                    "stone": (0.60, 0.56, 0.50), "metal": 0.3},
    "service": {"plinth": (0.26, 0.26, 0.25), "wainscot": (0.44, 0.44, 0.41),
                "rail": (0.36, 0.38, 0.37), "upper": (0.52, 0.51, 0.48),
                "crown": (0.26, 0.26, 0.25), "wood": (0.38, 0.33, 0.26),
                "stone": (0.58, 0.57, 0.54), "metal": 0.2},
    "glass": {"plinth": (0.22, 0.25, 0.24), "wainscot": (0.28, 0.32, 0.31),
              "rail": (0.55, 0.62, 0.58), "upper": (0.62, 0.70, 0.68),
              "crown": (0.22, 0.25, 0.24), "wood": (0.30, 0.33, 0.30),
              "stone": (0.55, 0.58, 0.55), "metal": 0.6},
}

DOOR = (112.5, 187.5, 0.0, 130.0)
ARCH = dict(open_x0=95.0, open_x1=205.0, z0=0.0, z_spring=85.0, z_apex=170.0)
WINDOW = (115.0, 185.0, 60.0, 150.0)

PIECES = ("straight", "corner", "end_pillar", "door", "arch", "window", "stair")


def piece(name: str) -> dict[str, list[kit.Box]]:
    if name == "straight":
        return {"wall": kit.straight(400.0)}
    if name == "corner":
        return {"wall": kit.corner(300.0)}
    if name == "end_pillar":
        return {"wall": kit.end_pillar(320.0)}
    if name == "door":
        return {"wall": kit.wall_with_openings(300.0, [DOOR]), "wood": kit.door_leaf(*DOOR)}
    if name == "arch":
        return {"wall": kit.wall_with_arch(300.0, **ARCH), "stone": kit.arch_surround(**ARCH)}
    if name == "window":
        frame, glass = kit.window_parts(*WINDOW)
        return {"wall": kit.straight(300.0), "stone": frame, "glass": [glass]}
    if name == "stair":
        return {"wall": kit.stair_opening(360.0, 100.0, 260.0, kit.HEIGHT)}
    raise ValueError("unknown piece " + name)


def material(name, colour, roughness=0.65, metallic=0.0):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (*colour, 1.0)
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Metallic"].default_value = metallic
    return mat


def band_for(z: float) -> str:
    for index, (z0, z1, _p) in enumerate(kit.PROFILE):
        if z0 <= z <= z1:
            return ("plinth", "wainscot", "rail", "upper", "crown")[index]
    return "upper"


def add_mesh(name, boxes, material, bevel=1.2):
    verts, faces = [], []
    for x0, y0, z0, x1, y1, z1 in boxes:
        base = len(verts)
        verts += [(x0, y0, z0), (x1, y0, z0), (x1, y1, z0), (x0, y1, z0),
                  (x0, y0, z1), (x1, y0, z1), (x1, y1, z1), (x0, y1, z1)]
        faces += [(base + 0, base + 3, base + 2, base + 1),
                  (base + 4, base + 5, base + 6, base + 7),
                  (base + 0, base + 1, base + 5, base + 4),
                  (base + 1, base + 2, base + 6, base + 5),
                  (base + 2, base + 3, base + 7, base + 6),
                  (base + 3, base + 0, base + 4, base + 7)]
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(verts, [], faces)
    mesh.validate()
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    obj.data.materials.append(material)
    if bevel:
        mod = obj.modifiers.new("bevel", "BEVEL")
        mod.width = bevel
        mod.segments = 2
        mod.limit_method = "ANGLE"
        mod.angle_limit = math.radians(40)
    return obj


def bounds(groups: dict[str, list[kit.Box]]):
    boxes = [box for boxes in groups.values() for box in boxes]
    xs = [b[0] for b in boxes] + [b[3] for b in boxes]
    ys = [b[1] for b in boxes] + [b[4] for b in boxes]
    zs = [b[2] for b in boxes] + [b[5] for b in boxes]
    return min(xs), min(ys), min(zs), max(xs), max(ys), max(zs)


def build_scene(style: str, groups: dict[str, list[kit.Box]]):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    palette = STYLES[style]
    mats = {band: material(f"{style}_{band}", palette[band]) for band in
            ("plinth", "wainscot", "rail", "upper", "crown")}
    mats["rail"] = material(f"{style}_rail", palette["rail"], roughness=0.35,
                            metallic=palette["metal"])
    mats["wood"] = material(f"{style}_wood", palette["wood"], roughness=0.5)
    mats["stone"] = material(f"{style}_stone", palette["stone"], roughness=0.75)
    mats["glass"] = material(f"{style}_glass", (0.78, 0.86, 0.9), roughness=0.05)
    mats["glass"].node_tree.nodes["Principled BSDF"].inputs["Transmission Weight"].default_value = 0.85

    for group, boxes in groups.items():
        if group == "wall":
            per_band: dict[str, list[kit.Box]] = {}
            for box in boxes:
                per_band.setdefault(band_for((box[2] + box[5]) / 2), []).append(box)
            for band, band_boxes in per_band.items():
                add_mesh(f"{style}_{band}", band_boxes, mats[band])
        else:
            add_mesh(f"{style}_{group}", boxes, mats[group])

    x0, y0, z0, x1, y1, z1 = bounds(groups)
    target = Vector(((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2))
    extent = max(x1 - x0, z1 - z0, y1 - y0) * 1.25

    theta, phi = math.radians(ELEVATION), math.radians(AZIMUTH)
    distance = 2400.0
    position = target + Vector((distance * math.cos(theta) * math.sin(phi),
                                distance * math.cos(theta) * math.cos(phi),
                                distance * math.sin(theta)))
    bpy.ops.object.camera_add(location=position)
    cam = bpy.context.object
    cam.data.type = "ORTHO"
    cam.data.ortho_scale = extent
    cam.data.clip_start = 1.0
    cam.data.clip_end = 20000.0
    cam.rotation_euler = (target - position).to_track_quat("-Z", "Y").to_euler()
    bpy.context.scene.camera = cam

    bpy.ops.object.light_add(type="SUN", location=(0, 0, 800))
    sun = bpy.context.object
    sun.data.energy = 2.4
    sun.data.color = (1.0, 0.90, 0.76)
    sun.rotation_euler = (math.radians(-52), 0.0, math.radians(-18))
    for offset, energy, colour in (((1.0, 0.6, 0.9), 260000, (1.0, 0.86, 0.70)),
                                   ((-0.8, 1.0, 0.7), 140000, (0.60, 0.72, 1.0))):
        loc = target + Vector((offset[0] * extent, offset[1] * extent, offset[2] * extent))
        bpy.ops.object.light_add(type="AREA", location=loc)
        lamp = bpy.context.object
        lamp.data.energy = energy * extent / 400
        lamp.data.color = colour
        lamp.data.size = extent
        lamp.rotation_euler = (target - loc).to_track_quat("-Z", "Y").to_euler()

    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.samples = 40
    scene.view_settings.exposure = -0.4
    scene.cycles.use_denoising = True
    scene.render.resolution_x, scene.render.resolution_y = SIZE
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    return cam


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    manifest = {"schemaVersion": 1, "camera": {"elevation": ELEVATION, "azimuth": AZIMUTH},
                "pixels": list(SIZE), "pieces": []}
    for style in STYLES:
        folder = OUT / style
        folder.mkdir(parents=True, exist_ok=True)
        materials_manifest = {}
        for name in PIECES:
            groups = piece(name)
            cam = build_scene(style, groups)
            bpy.context.scene.render.filepath = str(folder / f"{name}.png")
            bpy.ops.render.render(write_still=True)
            anchor = world_to_camera_view(bpy.context.scene, cam, Vector((0, 0, 0)))
            x0, y0, z0, x1, y1, z1 = bounds(groups)
            materials_manifest[name] = {
                "file": f"{style}/{name}.png",
                "worldSize": [round(x1 - x0, 2), round(y1 - y0, 2), round(z1 - z0, 2)],
                "worldBounds": [round(v, 2) for v in (x0, y0, z0, x1, y1, z1)],
                "pixelsPerUnit": round(SIZE[0] / cam.data.ortho_scale, 4),
                "anchor": [round(anchor.x * SIZE[0], 1), round((1 - anchor.y) * SIZE[1], 1)],
            }
            print(f"rendered {style}/{name} anchor={materials_manifest[name]['anchor']}")
        manifest["pieces"].append({"style": style, "items": materials_manifest})
    (OUT / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print("manifest ->", OUT / "manifest.json")


main()
