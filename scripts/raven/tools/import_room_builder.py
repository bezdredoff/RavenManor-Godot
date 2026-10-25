#!/usr/bin/env python3
"""Import a Raven Room Builder JSON into a NON-CANONICAL Godot scene.
Run at the repository root: python3 scripts/raven/tools/import_room_builder.py room.json
Does not touch approved navigation, save state or existing greybox scenes.
"""
import argparse
import base64
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
DATA_URI = re.compile(r'^data:image/(png|jpeg|webp);base64,([a-zA-Z0-9+/=]+)$')
SAFE = re.compile(r'[^A-Za-z0-9_-]+')

def name(value):
    return SAFE.sub('_', str(value))[:90] or 'Unnamed'

def quoted(s):
    return json.dumps(str(s), ensure_ascii=False)

def f(n):
    return f'{float(n):.4f}'

def scene_from_project(data, output_root=ROOT):
    if data.get('schemaVersion') != 1:
        raise ValueError('Unsupported room builder version')
    if not re.fullmatch(r'RM-ROOM-[A-Z0-9-]+', data.get('roomId', '')):
        raise ValueError('Invalid room ID')
    room = name(data['roomId'])
    assets = {a['id']: a for a in data.get('assets', [])}
    layers = {a['id']: i for i, a in enumerate(data.get('layers', []))}
    dest = output_root / 'assets' / 'raven' / 'generated' / room
    scene_dir = output_root / 'scenes' / 'raven' / 'generated'
    dest.mkdir(parents=True, exist_ok=True)
    scene_dir.mkdir(parents=True, exist_ok=True)
    textures = []
    keys = {}
    for asset in assets.values():
        match = DATA_URI.match(asset.get('image', ''))
        if not match:
            continue
        ext = {'png': 'png', 'jpeg': 'jpg', 'webp': 'webp'}[match.group(1)]
        binary = base64.b64decode(match.group(2), validate=True)
        if len(binary) > 16 * 1024 * 1024:
            raise ValueError('Asset exceeds 16 MB')
        path = dest / f"{name(asset['id'])}.{ext}"
        path.write_bytes(binary)
        rid = f'tex_{len(keys)+1}'
        keys[asset['id']] = rid
        textures.append(f'[ext_resource type="Texture2D" path="res://{path.relative_to(output_root).as_posix()}" id="{rid}"]')
    lines = [f'[gd_scene load_steps={len(textures)+1} format=3]', *textures, '',
             f'[node name={quoted(room)} type="Node2D"]',
             'metadata/builder_version = 1',
             f'metadata/room_id = {quoted(data["roomId"])}',
             'metadata/geometry_approval = "DRAFT_ONLY"', '']
    for index, obj in enumerate(data.get('objects', [])):
        a = assets.get(obj.get('assetId'))
        if not a or obj.get('layerId') not in layers:
            raise ValueError(f'Unknown asset or layer in object {index}')
        w, h = float(obj['w']), float(obj['h'])
        if not 0 < w <= 8000 or not 0 < h <= 8000:
            raise ValueError('Invalid object size')
        x = float(obj['x']) + w/2
        y = float(obj['y']) + h/2
        obj_name = name(obj.get('id', f'object_{index}'))
        lines.extend([f'[node name={quoted(obj_name)} type="Node2D" parent="."]',
                     f'position = Vector2({f(x)}, {f(y)})',
                     f'rotation_degrees = {f(obj.get("rotation",0))}',
                     f'z_index = {layers[obj["layerId"]]}',
                     f'metadata/asset_id = {quoted(obj["assetId"])}',
                     f'metadata/asset_ref_id = {quoted(obj.get("assetRefId", ""))}',
                     f'metadata/hotspot_id = {quoted(obj.get("hotspotId", ""))}',
                     f'metadata/visual_state = {quoted(obj.get("state", "default"))}', '',])
        if obj['assetId'] in keys:
            aw, ah = max(1.0,float(a['w'])), max(1.0,float(a['h']))
            # Sprite base dimensions follow source imported sprite cell size.
            lines.extend([f'[node name="Art" type="Sprite2D" parent={quoted(obj_name)}]',
                          f'texture = ExtResource("{keys[obj["assetId"]]}")',
                          f'scale = Vector2({f(w/aw)}, {f(h/ah)})', ''])
        else:
            color = a.get('color', '#80627a').lstrip('#')
            if not re.fullmatch(r'[0-9a-fA-F]{6}', color): color = '80627a'
            rgb = [int(color[i:i+2],16)/255 for i in (0,2,4)]
            lines.extend([f'[node name="Placeholder" type="Polygon2D" parent={quoted(obj_name)}]',
                          f'color = Color({f(rgb[0])}, {f(rgb[1])}, {f(rgb[2])}, 1)',
                          f'polygon = PackedVector2Array({f(-w/2)}, {f(-h/2)}, {f(w/2)}, {f(-h/2)}, {f(w/2)}, {f(h/2)}, {f(-w/2)}, {f(h/2)})', ''])
    for a in data.get('anchors', []):
        if not all(k in a for k in ('id','x','y')):
            continue
        lines.extend([f'[node name={quoted(name(a["id"]))} type="Marker2D" parent="."]',
                      f'position = Vector2({f(a["x"])}, {f(a["y"])})',
                      f'metadata/nav_id = {quoted(a["id"])}',
                      f'metadata/hotspot_id = {quoted(a.get("hotspotId", ""))}', ''])
    path = scene_dir / (room+'.tscn')
    path.write_text('\n'.join(lines), encoding='utf-8')
    return path

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('json_path',type=Path)
    args=parser.parse_args()
    data=json.loads(args.json_path.read_text(encoding='utf-8'))
    print('Created DRAFT scene:', scene_from_project(data))

if __name__=='__main__': main()