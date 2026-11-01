import json
import pathlib
import sys
import time
import urllib.request

import numpy as np
from PIL import Image, PngImagePlugin

ROOT = pathlib.Path(r'D:\AI\RavenManor-GFX01-20261027')
OUT = ROOT / 'production/ada_performance_20261101'


def api(path, payload=None):
    req = urllib.request.Request('http://127.0.0.1:8189' + path,
        data=json.dumps(payload).encode() if payload is not None else None,
        headers={'Content-Type': 'application/json', 'Origin': 'http://127.0.0.1:8189'})
    with urllib.request.urlopen(req, timeout=60) as response:
        return json.load(response)


for key in sys.argv[1:]:
    m = json.loads((OUT / 'manifest.json').read_text(encoding='utf-8'))
    rec = m['actions'][key]
    prompt = json.loads((OUT / (key + '_api.json')).read_text(encoding='utf-8'))
    ui = json.loads(pathlib.Path(rec['workflow']).read_text(encoding='utf-8'))
    hp = OUT / (key + '_history.json')
    h = json.loads(hp.read_text(encoding='utf-8')) if hp.exists() else None
    if h is None or h['status']['status_str'] != 'success':
        pid = api('/prompt', {'prompt': prompt, 'extra_data': {'extra_pnginfo': {'workflow': ui}}})['prompt_id']
        print(key, 'START', pid, flush=True)
        while True:
            time.sleep(10)
            hist = api('/history/' + pid)
            if pid in hist:
                h = hist[pid]
                hp.write_text(json.dumps(h, indent=2), encoding='utf-8')
                break
    if h['status']['status_str'] != 'success':
        print(h['status'], flush=True)
        raise RuntimeError(key)
    item = h['outputs']['31']['images'][0]
    raw = ROOT / 'output' / item['subfolder'] / item['filename']
    a = np.array(Image.open(rec.get('source', m['source'])).convert('RGBA'))
    b = np.array(Image.open(raw).convert('RGBA'))
    x, y, width, height = m['crop']
    mask = np.array(Image.open(rec['mask']))
    protected = np.ones(a.shape[:2], dtype=bool)
    protected[y:y+height, x:x+width] = mask == 0
    delta = np.abs(a[protected].astype(int) - b[protected].astype(int))
    assert delta.max() <= 1 and delta[:, :3].max() == 0, 'Unexpected change outside mask'
    b[protected] = a[protected]
    output = raw.parent / ('Ada_' + key + '.png')
    pnginfo = PngImagePlugin.PngInfo()
    for field, value in Image.open(raw).info.items():
        if isinstance(value, str):
            pnginfo.add_text(field, value)
    Image.fromarray(b).save(output, pnginfo=pnginfo)
    assert np.array_equal(a[protected], np.array(Image.open(output))[protected])
    im = Image.open(output).convert('RGBA').crop((32, 352, 1056, 1376))
    bg = Image.new('RGBA', im.size, '#e5e4e0')
    bg.alpha_composite(im)
    bg.convert('RGB').save(OUT / (key + '_review.png'))
    # Reload before writing so concurrent owner-review notes are preserved.
    m = json.loads((OUT / 'manifest.json').read_text(encoding='utf-8'))
    m['actions'][key].update(status='generated_owner_review_pending', image=str(output),
        prompt_id=h['prompt'][1], source_pixels_outside_mask_exact=True)
    (OUT / 'manifest.json').write_text(json.dumps(m, ensure_ascii=False, indent=2), encoding='utf-8')
    print(key, 'SUCCESS', output, flush=True)
