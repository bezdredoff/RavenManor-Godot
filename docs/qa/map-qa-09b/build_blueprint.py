"""Original underlay + code-native proposed floor/door geometry; no image editing."""
import hashlib
import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[3]


def main():
    doc = json.loads((ROOT/'assets/raven/map/qa/drafts/map_qa_09b_opening_blueprint.v1.json').read_text(encoding='utf-8'))
    source = ROOT/doc['source']['path']
    assert hashlib.sha256(source.read_bytes()).hexdigest() == doc['source']['sha256']
    art = Image.open(source).convert('RGB')
    draw = ImageDraw.Draw(art)
    font = ImageFont.load_default(size=14)
    small = ImageFont.load_default(size=12)
    lookup = {w['id']:w for w in doc['waypoints']}
    def label(xy, text, color='white', f=font):
        box=draw.textbbox(xy,text,font=f)
        draw.rectangle((box[0]-3,box[1]-2,box[2]+3,box[3]+2),fill='#101720')
        draw.text(xy,text,font=f,fill=color)
    for zone in doc['walkablePolygons']:
        if zone.get('role')=='PROPOSED_FLOOR_PATCH':
            draw.polygon([tuple(p) for p in zone['pointsPx']],fill='#345e70',outline='#7fe5ff',width=2)
    for c in doc['sharedDoorContacts']:
        x,y=lookup[c['waypointIds'][0]]['pointPx'];nx,ny=c['normalPx'];tx,ty=-ny,nx
        for sign in [-1,1]:
            a,b=x+tx*24*sign,y+ty*24*sign
            draw.line((a-nx*8,b-ny*8,a+nx*8,b+ny*8),fill='#ffd17b',width=5)
        draw.ellipse((x-4,y-4,x+4,y+4),fill='#ffd17b')
        label((x+10,y-20),c['id'].removeprefix('QA-09B-')+' PROPOSED','#ffd17b')
    for proposal in doc['architectureProposals']:
        pts=[tuple(p) for p in proposal['pointsPx']]
        for a,b in zip(pts,pts[1:]):
            length=((b[0]-a[0])**2+(b[1]-a[1])**2)**.5
            for k in range(0,int(length),16):
                t=k/length;u=min(1,(k+8)/length)
                draw.line((a[0]+(b[0]-a[0])*t,a[1]+(b[1]-a[1])*t,a[0]+(b[0]-a[0])*u,a[1]+(b[1]-a[1])*u),fill='#e4a4ff',width=3)
        label((pts[-1][0]+6,pts[-1][1]-18),'CONCEPT / NO ROUTE','#e4a4ff',small)
    label((20,20),'MAP-QA-09B | ARCHITECTURE PROPOSAL | NOT ORIGINAL-IMAGE SEGMENTATION')
    label((20,45),'Blue = NEW floor/backfill; gold = proposed opening; purple = concept without runtime route.')
    label((20,800),'HA: new archive opening. HC: proposed under-landing corridor; foreground/elevation art required.')
    label((20,825),'CB: new bedroom opening. CK: service vestibule; relocate covered cabinet and add enclosure.')
    label((20,850),'All crossings TEST_ONLY, gates closed by default. Original PNG / accepted 08B data unchanged.')
    art.save(Path(__file__).parent/'opening-blueprint.jpg',quality=88,optimize=True)
    print('Rendered editable-geometry blueprint over immutable original')


if __name__=='__main__':main()
