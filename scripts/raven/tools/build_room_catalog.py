#!/usr/bin/env python3
"""Build the PWA JSON catalog deterministically from the canonical first-season CSV.

Run at repository root: python3 scripts/raven/tools/build_room_catalog.py
CI: python3 scripts/raven/tools/build_room_catalog.py --check
"""
import argparse
import csv
import json
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
SOURCE = ROOT / 'docs/assets/ROOM_OBJECT_REGISTER.csv'
OUTPUT = ROOT / 'tools/room-builder/catalog/room-items.json'
ROOM_NAMES = {
    'RM-ROOM-ENTRY': 'Вход и крыльцо',
    'RM-ROOM-HALL': 'Парадный холл',
    'RM-ROOM-CORRIDOR': 'Жилой коридор',
    'RM-ROOM-BEDROOM': 'Спальня Эвелин',
    'RM-ROOM-BATHROOM': 'Ванная (виньетка)',
    'RM-ROOM-KITCHEN': 'Кухня',
    'RM-ROOM-ARCHIVE': 'Библиотека / архив',
    'RM-ROOM-CONSERVATORY': 'Оранжерея',
}
# Source PNGs are reference-only; NONE are a released/approved state variant.
PILOT = {
    'RM-ASSET-HALL-002': ['props/grandfather_clock.png'],
    'RM-ASSET-HALL-006': ['props/ancestor_gallery_composite.png'],
    'RM-ASSET-HALL-007': ['props/entry_console.png'],
    'RM-ASSET-HALL-010': ['props/burgundy_runner.png'],
    'RM-ASSET-HALL-017': ['props/armchair_clean.png'],
    'RM-ASSET-HALL-018': ['props/armchair_clean.png'],
    'RM-ASSET-HALL-019': ['props/round_side_table.png'],
}
MULTI = {
    'RM-ASSET-HALL-011': 2,
    'RM-ASSET-BEDROOM-003': 2,
    'RM-ASSET-ARCHIVE-003': 2,
    'RM-ASSET-CONSERVATORY-009': 3,
}
FAMILY = {
    'RM-ASSET-HALL-017': 'RM-FAMILY-VICTORIAN-ARMCHAIR',
    'RM-ASSET-HALL-018': 'RM-FAMILY-VICTORIAN-ARMCHAIR',
}


def build(rows):
    items = []
    ids = set()
    for row in rows:
        id_ = row['asset_id']
        if id_ in ids or row['room_id'] not in ROOM_NAMES or row['source_status'] != 'PROPOSED':
            raise ValueError(f'Duplicate, unsupported room or unexpectedly approved row: {id_}')
        ids.add(id_)
        items.append({
            'id': id_, 'roomId': row['room_id'], 'name': row['asset_name_ru'],
            'anchor': row['placement_anchor'], 'states': row['state_variants'].split('/'),
            'layer': row['layer_family'], 'priority': row['production_priority'],
            'approval': row['source_status'], 'familyKey': FAMILY.get(id_, id_),
            'plannedInstances': MULTI.get(id_, 1),
            'pilotImages': [f'assets/raven/hall/generated_pilot/{path}' for path in PILOT.get(id_, [])],
        })
    counts = Counter(item['roomId'] for item in items)
    return {'schemaVersion': 1, 'title': 'Raven Manor · season 1 production proposal',
            'source': 'docs/assets/ROOM_OBJECT_REGISTER.csv',
            'note': 'All rows PROPOSED; pilot PNGs are experimental references, not approved per-state assets. Editor sizes are schematic.',
            'rooms': [{'id': rid, 'name': name, 'count': counts[rid]} for rid, name in ROOM_NAMES.items()],
            'items': items}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true', help='Check committed JSON matches the CSV exactly')
    args = parser.parse_args()
    with SOURCE.open(encoding='utf-8', newline='') as f:
        value = build(list(csv.DictReader(f)))
    if args.check:
        try:
            committed = json.loads(OUTPUT.read_text(encoding='utf-8'))
        except FileNotFoundError:
            print('Missing generated catalog', file=sys.stderr)
            return 1
        if committed != value:
            print('Catalog is stale. Run build_room_catalog.py, then mirror static PWA assets.', file=sys.stderr)
            return 1
        print(f'Catalog matches CSV: {len(value["items"])} positions, {len(value["rooms"])} rooms')
    else:
        OUTPUT.parent.mkdir(parents=True, exist_ok=True)
        OUTPUT.write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
        print(f'Wrote {len(value["items"])} positions to {OUTPUT}')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())