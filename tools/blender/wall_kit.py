"""Build and render the Raven Manor wall kit in Blender, with a light-leak check.

Run headless:
    blender -b -noaudio -P tools/blender/wall_kit.py

Renders one style (four are planned) plus two leak probes: the current corner geometry and the
previous one, where both arms started at zero and left the exterior corner post empty. The
probe puts an emissive magenta world behind the walls, so any pinhole at the joint shows up as
magenta pixels that can be counted instead of argued about.
"""
from __future__ import annotations

import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import kit_geometry as kit  # noqa: E402

ROOT = HERE.parents[1]
OUT = ROOT / "build/blender_kit/grand"
ELEVATION = 50.0
AZIMUTH = 45.0
SIZE = (640, 640)

STYLE = {
    "plinth": (0.16, 0.10, 0.07),
    "wainscot": (0.33, 0.19, 0.12),
    "rail": (0.72, 0.56, 0.26),
    "upper": (0.42, 0.16, 0.13),
    "crown": (0.16, 0.10, 0.07),
}


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def material(name, colour, roughness=0.6, metallic=0.0):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (*colour, 1.0)
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Metallic"].default_value = metallic
    return mat


def slot_for(z_center: float) -> str:
    for index, (z0, z1, _p) in enumerate(kit.PROFILE):
        if z0 <= z_center <= z1:
            return ("plinth", "wainscot", "rail", "upper", "crown")[index]
    return "upper"


def build(name, boxes, materials, bevel=1.4):
    collection = bpy.data.collections.new(name)
    bpy.context.scene.collection.children.link(collection)
    for index, (x0, y0, z0, x1, y1, z1) in enumerate(boxes):
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=((x0 + x1) / 2, (y0 + y1) / 2,
                                                            (z0 + z1) / 2))
        obj = bpy.context.object
        obj.name = f"{name}_{index}"
        obj.scale = (x1 - x0, y1 - y0, z1 - z0)
        bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
        obj.data.materials.append(materials[slot_for((z0 + z1) / 2)])
        if bevel:
            mod = obj.modifiers.new("bevel", "BEVEL")
            mod.width = bevel
            mod.segments = 2
        for coll in obj.users_collection:
            coll.objects.unlink(obj)
        collection.objects.link(obj)
    return collection


def camera(target, ortho_scale, elevation=ELEVATION, azimuth=AZIMUTH):
    bpy.ops.object.empty_add(location=Vector(target))
    focus = bpy.context.object
    theta, phi = math.radians(elevation), math.radians(azimuth)
    distance = 1200.0
    position = Vector(target) + Vector((distance * math.cos(theta) * math.sin(phi),
                                        distance * math.cos(theta) * math.cos(phi),
                                        distance * math.sin(theta)))
    bpy.ops.object.camera_add(location=position)
    cam = bpy.context.object
    cam.data.type = "ORTHO"
    cam.data.ortho_scale = ortho_scale
    cam.data.clip_start = 1.0
    cam.data.clip_end = 8000.0
    track = cam.constraints.new("TRACK_TO")
    track.target = focus
    track.track_axis = "TRACK_NEGATIVE_Z"
    track.up_axis = "UP_Y"
    bpy.context.scene.camera = cam
    return cam


def lights(target):
    bpy.ops.object.light_add(type="SUN", location=(0, 0, 500))
    sun = bpy.context.object
    sun.data.energy = 3.6
    sun.data.color = (1.0, 0.90, 0.76)
    sun.rotation_euler = (math.radians(48), math.radians(12), math.radians(-35))

    def area(location, energy, colour, size):
        bpy.ops.object.light_add(type="AREA", location=location)
        lamp = bpy.context.object
        lamp.data.energy = energy
        lamp.data.color = colour
        lamp.data.size = size
        lamp.rotation_euler = (Vector(target) - lamp.location).to_track_quat("-Z", "Y").to_euler()

    area((520, 260, 420), 700000, (1.0, 0.86, 0.70), 400)
    area((-260, 520, 300), 400000, (0.60, 0.72, 1.0), 420)


def configure(transparent=True, magenta=False):
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.samples = 48
    scene.cycles.use_denoising = True
    scene.render.resolution_x, scene.render.resolution_y = SIZE
    scene.render.film_transparent = transparent
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    if magenta:
        scene.world = bpy.data.worlds.new("probe")
        scene.world.use_nodes = True
        background = scene.world.node_tree.nodes["Background"]
        background.inputs[0].default_value = (0.0, 0.0, 0.0, 1.0)
        background.inputs[1].default_value = 0.0
        scene.view_settings.view_transform = "Standard"


def render(path):
    path.parent.mkdir(parents=True, exist_ok=True)
    bpy.context.scene.render.filepath = str(path)
    bpy.ops.render.render(write_still=True)


def alpha_map(path):
    image = bpy.data.images.load(str(path))
    pixels = list(image.pixels)
    return [pixels[index + 3] for index in range(0, len(pixels), 4)]





def scene_with(boxes, target, ortho_scale, floor=True, azimuth=AZIMUTH):
    reset()
    materials = {key: material(key, colour) for key, colour in STYLE.items()}
    materials["rail"] = material("rail", STYLE["rail"], roughness=0.3, metallic=0.85)
    materials["floor"] = material("floor", (0.80, 0.76, 0.68), roughness=0.65)
    build("kit", boxes, materials)
    if floor:
        bpy.ops.mesh.primitive_plane_add(size=900, location=(kit.LENGTH / 2, kit.LENGTH / 2, 0))
        bpy.context.object.data.materials.append(materials["floor"])
    lights(Vector(target))
    camera(target, ortho_scale, azimuth=azimuth)


def main():
    report = {}

    # Beauty renders of the pieces.
    pieces = {"straight": kit.straight(), "corner": kit.corner(), "end_pillar": kit.end_pillar()}
    for name, boxes in pieces.items():
        scene_with(boxes, (kit.LENGTH * 0.45, kit.LENGTH * 0.45, 90), 470)
        configure(transparent=True)
        render(OUT / f"{name}.png")
        report[name] = kit.piece_report(name, boxes)

    # Leak probes: tight frame on the corner, magenta world behind the walls.
    for name, boxes in (("corner", kit.corner()), ("corner_legacy", kit.legacy_corner())):
        # Probe camera sits outside the corner: a joint gap is then a hole in the silhouette,
        # countable as transparent pixels against the film.
        scene_with(boxes, (-kit.THICKNESS / 2, -kit.THICKNESS / 2, 100), 130, floor=False,
                   azimuth=225.0)
        configure(transparent=True)
        path = OUT / f"leak_{name}.png"
        render(path)
        report[f"alpha_{name}"] = alpha_map(path)

    # The leak is the slit: background in the old corner but solid wall in the new one.
    fixed, legacy = report.pop("alpha_corner"), report.pop("alpha_corner_legacy")
    report["corner_leak_pixels"] = sum(1 for f, l in zip(fixed, legacy) if f >= 0.5 and l < 0.5)
    report["corner_leak_legacy_pixels"] = sum(1 for f, l in zip(fixed, legacy) if f < 0.5 and l >= 0.5)
    report["corner_leak_geometry"] = round(kit.corner_leak([kit.corner()]), 4)
    report["corner_leak_geometry_legacy"] = round(kit.corner_leak([kit.legacy_corner()]), 4)

    import json
    (OUT / "report.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report, indent=2))


main()
