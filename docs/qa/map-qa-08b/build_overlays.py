"""Render hand-inspected candidate annotations, never automatic segmentation.

Run from any directory: python -X utf8 docs/qa/map-qa-08b/build_overlays.py
Requires Pillow. The immutable original is the full-resolution underlay.
"""
import hashlib
import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[3]
OUT = Path(__file__).resolve().parent
DOC = ROOT / 'assets/raven/map/qa/drafts/map_qa_08_visual_candidate.v1.json'


def cell_point(name, grid):
    letters = ''.join(c for c in name if c.isalpha())
    column = 0
    for c in letters:
        column = column * 26 + ord(c) - 64
    row = int(name[len(letters):])
    return ((column - .5) * grid['cellWidth'] + grid['origin'][0],
            (row - .5) * grid['cellHeight'] + grid['origin'][1])


def main():
    doc = json.loads(DOC.read_text(encoding='utf-8'))
    original = ROOT / doc['source']['path']
    assert hashlib.sha256(original.read_bytes()).hexdigest() == doc['source']['sha256']
    art = Image.open(original).convert('RGBA')
    assert art.size == (1672, 941)
    font = ImageFont.load_default(size=14)
    small = ImageFont.load_default(size=12)
    waypoints = {w['id']: w for w in doc['waypoints']}
    room_labels = {'BEDROOM': (407, 179), 'CORRIDOR': (749, 305),
                   'ARCHIVE': (350, 470), 'HALL': (816, 720), 'KITCHEN': (1178, 535)}

    def label(draw, xy, text, color='white', f=font):
        x, y = xy
        box = draw.textbbox((x, y), text, font=f)
        draw.rectangle((box[0]-3, box[1]-2, box[2]+3, box[3]+2), fill=(12, 18, 25, 230))
        draw.text((x, y), text, font=f, fill=color)

    def graph(draw, labels=True):
        for route in doc['routes']:
            points = [tuple(waypoints[route['from']]['pointPx'])]
            points += [cell_point(c, doc['grid']) for c in route['cells'][1:-1]]
            points += [tuple(waypoints[route['to']]['pointPx'])]
            draw.line(points, fill='#ffdf66', width=3)
            # All routes are bidirectional; two endpoint arrows show this.
            for a, b in [(points[1], points[0]), (points[-2], points[-1])]:
                dx, dy = b[0]-a[0], b[1]-a[1]
                length = max(1, (dx*dx+dy*dy)**.5)
                ux, uy = dx/length, dy/length
                draw.polygon([b, (b[0]-ux*8-uy*4, b[1]-uy*8+ux*4),
                              (b[0]-ux*8+uy*4, b[1]-uy*8-ux*4)], fill='#ffdf66')
        for i, wp in enumerate(doc['waypoints'], 1):
            x, y = wp['pointPx']
            draw.ellipse((x-5, y-5, x+5, y+5), fill='#63e8ff', outline='black', width=1)
            if labels:
                label(draw, (x+6, y-17), str(i), '#63e8ff', small)

    for kind, filename in [('segmentation', 'A-floor-segmentation.jpg'),
                           ('graph', 'B-navigation-graph.jpg'),
                           ('story', 'C-story-destinations.jpg'),
                           ('doors', 'D-door-candidates.jpg')]:
        layer = Image.new('RGBA', art.size)
        draw = ImageDraw.Draw(layer)
        if kind == 'segmentation':
            for group, color in [('walkablePolygons', (40, 235, 115, 95)),
                                 ('noGoPolygons', (255, 65, 65, 115))]:
                for zone in doc[group]:
                    points = [tuple(p) for p in zone['pointsPx']]
                    draw.polygon(points, fill=color, outline=color[:3]+(255,), width=2)
        if kind in ['segmentation', 'doors']:
            for area in doc['uncertainAreas']:
                box = area['boundsPx']
                draw.rectangle(box, fill=(234, 111, 255, 35), outline='#e893ff', width=2)
                label(draw, (box[0]+6, box[1]+6), area['id']+' ?', '#e893ff')
        if kind in ['graph', 'story']:
            graph(draw, labels=kind == 'graph')
        if kind == 'story':
            for i, poi in enumerate(doc['storyTargets'], 1):
                stop = poi.get('safeStopPointPx')
                if stop:
                    x, y = stop
                    draw.ellipse((x-12, y-12, x+12, y+12), outline='#63ffad', width=2)
                    label(draw, (x+12, y+5), 'P'+str(i), '#63ffad', small)
                    obj = poi.get('interactionObjectPointPx')
                    if obj:
                        draw.line([tuple(stop), tuple(obj)], fill='#fbbcff', width=2)
                        ox, oy = obj
                        draw.rectangle((ox-4, oy-4, ox+4, oy+4), outline='#fbbcff', width=2)
            label(draw, (20, 770), 'HS001 Hall / HS002 bed / HS003 bath / HS005 bedroom approach: candidate staging')
            label(draw, (20, 794), 'HS004 childhood object: UNRESOLVED. NPC circles are staging, not authored NPC positions.')
            label(draw, (20, 818), 'Unplaced: Hall tea chairs, plan, clock, portraits; power, archive window/door; Entry/Glass/Garden.')
        if kind == 'doors':
            for i, door in enumerate(doc['doorCandidates'], 1):
                point = door.get('thresholdCandidatePx')
                if not point:
                    continue
                x, y = point
                color = '#ff6d74' if door['locked'] else '#f8d777'
                draw.rectangle((x-7, y-7, x+7, y+7), outline=color, width=3)
                label(draw, (x+10, y-20), 'D'+str(i)+' ?', color)
                for key in ['nearSidePointPx', 'farSidePointPx']:
                    stop = door.get(key)
                    if stop:
                        sx, sy = stop
                        draw.line([tuple(point), tuple(stop)], fill=color, width=2)
                        draw.ellipse((sx-6, sy-6, sx+6, sy+6), outline=color, width=2)
            label(draw, (20, 770), 'D1 Entry; D2 Archive; D4 Bedroom; D5 Bath: visual candidates only; no runtime links.')
            label(draw, (20, 794), 'D3 Hall-Corridor / D6 Corridor-Kitchen / D7 Kitchen-Glass: no proven continuous floor.')
            label(draw, (20, 818), 'D8 east wing / D9 stairs / D10 service / D11 garden: locked or unresolved. TEST_ONLY fixtures separate.')
        for room, xy in room_labels.items():
            label(draw, xy, room, '#ffffff')
        label(draw, (20, 20), 'MAP-QA-08B | '+kind.upper()+' | AI_DRAFT / OWNER UNAPPROVED')
        label(draw, (20, 44), '1672 x 941 image pixels | manually traced proxies, NOT certified segmentation or collision')
        Image.alpha_composite(art, layer).convert('RGB').save(OUT/filename, quality=87, optimize=True)

    rows = ['# Annotation keys', '', 'Generated from the candidate; coordinates are original image pixels.', '',
            '| Map B | Waypoint | Room | Feet px |', '|---|---|---|---|']
    for i, wp in enumerate(doc['waypoints'], 1):
        rows.append(f"| {i} | {wp['id']} | {wp['roomId']} | {wp['pointPx']} |")
    rows += ['', '| Map C | POI / story | Status | Stop |', '|---|---|---|---|']
    for i, poi in enumerate(doc['storyTargets'], 1):
        refs = ', '.join(poi.get('relatedHotspotIds', [])+poi.get('relatedStoryIds', []))
        rows.append(f"| P{i} | {poi['id']} / {refs} | {poi['status']} | {poi.get('safeStopPointPx')} |")
    rows += ['', '| Map D | Door | Status | Uncertainty |', '|---|---|---|---|']
    for i, door in enumerate(doc['doorCandidates'], 1):
        rows.append(f"| D{i} | {door['doorId']} | {door['status']} | {door['uncertaintyReason']} |")
    (OUT/'annotation-keys.md').write_text('\n'.join(rows)+'\n', encoding='utf-8')
    print('Rendered four 1672x941 overlays and annotation keys')


if __name__ == '__main__':
    main()
