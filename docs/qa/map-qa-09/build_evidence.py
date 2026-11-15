"""Render original PNG crops, never invent a missing doorway. Requires Pillow."""
import hashlib
import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[3]
OUT = Path(__file__).resolve().parent


def main():
    doc = json.loads((ROOT/'assets/raven/map/qa/drafts/map_qa_09_door_review.v1.json').read_text(encoding='utf-8'))
    route = json.loads((ROOT/'assets/raven/map/qa/drafts/map_qa_08_visual_candidate.v1.json').read_text(encoding='utf-8'))
    image_path = ROOT/doc['source']['path']
    assert hashlib.sha256(image_path.read_bytes()).hexdigest() == doc['source']['sha256']
    original = Image.open(image_path).convert('RGB')
    assert original.size == (1672, 941)
    font = ImageFont.load_default(size=14)
    small = ImageFont.load_default(size=12)
    sheet = Image.new('RGB', (1560, 1790), '#131a22')
    sheet_draw = ImageDraw.Draw(sheet)
    sheet_draw.text((15, 10), 'MAP-QA-09 | Original image evidence | ALL 11 REAL DOORS UNRESOLVED', font=font, fill='white')
    sheet_draw.text((15, 32), 'Red X = unapproved 08B estimate; yellow = entrance landmark. Neither permits a crossing.', font=small, fill='#ffd57d')
    overlay = original.copy()
    overlay_draw = ImageDraw.Draw(overlay)
    lookup = {w['id']: w for w in route['waypoints']}

    def label(draw, xy, text, color='white', f=font):
        box = draw.textbbox(xy, text, font=f)
        draw.rectangle((box[0]-2, box[1]-2, box[2]+2, box[3]+2), fill='#131a22')
        draw.text(xy, text, font=f, fill=color)

    for i, door in enumerate(doc['doors']):
        x, y, w, h = door['reviewRectPx']
        crop = original.crop((x, y, x+w, y+h))
        draw = ImageDraw.Draw(crop)
        old = door['prior08B']['thresholdCandidatePx']
        point = door['thresholdCandidatePx']
        mark = old if old else point
        if mark and x <= mark[0] < x+w and y <= mark[1] < y+h:
            a, b = mark[0]-x, mark[1]-y
            color = '#ff5d7d' if old and not point else '#ffdc76'
            draw.line((a-5, b-5, a+5, b+5), fill=color, width=2)
            draw.line((a-5, b+5, a+5, b-5), fill=color, width=2)
        left, top = (i % 3)*520+10, (i//3)*430+65
        label(sheet_draw, (left, top), f"D{i+1} {door['id']}")
        label(sheet_draw, (left, top+23), door['classification'], '#ffd57d', small)
        crop.thumbnail((500, 320), Image.Resampling.NEAREST)
        # Upscale small native crops without smoothing away wall/trim details.
        if crop.width < 500 and crop.height < 320:
            scale = min(500/crop.width, 320/crop.height)
            crop = crop.resize((int(crop.width*scale), int(crop.height*scale)), Image.Resampling.NEAREST)
        sheet.paste(crop, (left+(500-crop.width)//2, top+51+(320-crop.height)//2))
        label(sheet_draw, (left, top+378), f"Source px [{x},{y},{w},{h}] | crossing disabled", '#a6d9e7', small)
        overlay_draw.rectangle((x, y, x+w, y+h), outline='#ffb36c', width=2)
        label(overlay_draw, (x+3, y+3), f'D{i+1} ?', '#ffdc76')
        for stop in door['roomSideStops']:
            a, b = lookup[stop['waypointId']]['pointPx']
            overlay_draw.ellipse((a-5, b-5, a+5, b+5), fill='#6ce0ff', outline='black', width=1)
    label(overlay_draw, (15, 18), 'MAP-QA-09 | ALL PHYSICAL DOORS UNRESOLVED | AI_DRAFT / OWNER DECISION REQUIRED')
    label(overlay_draw, (15, 43), 'Boxes = evidence crops. Blue = accepted room stops, not threshold contacts. No crossing segments.')
    sheet.save(OUT/'door-contact-sheet.jpg', quality=88, optimize=True)
    overlay.save(OUT/'door-evidence-map.jpg', quality=87, optimize=True)
    table = ['# MAP-QA-09 door evidence', '', '| Key | Door | Evidence | Nearby room stops |', '|---|---|---|---|']
    for i, door in enumerate(doc['doors'], 1):
        stops = '; '.join(s['waypointId'] for s in door['roomSideStops']) or 'None'
        table.append(f"| D{i} | {door['id']} | {door['evidence']} | {stops} |")
    table += ['', 'All physical contacts, opening widths, collision and foreground masks remain unresolved.',
              'The 08B owner confirmation covers room routes/editor QA; it does not approve these doors.']
    (OUT/'door-review-table.md').write_text('\n'.join(table)+'\n', encoding='utf-8')
    print('Rendered 11 original-image crops, evidence map and table')


if __name__ == '__main__':
    main()
