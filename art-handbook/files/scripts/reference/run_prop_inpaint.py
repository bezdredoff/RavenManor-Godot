import json
import pathlib
import sys
import time
import urllib.request

import numpy as np
from PIL import Image, ImageDraw, PngImagePlugin

ROOT = pathlib.Path(r'D:\AI\RavenManor-GFX01-20261027')
OUT = ROOT / 'production/prop_inpaint_20261101'


def api(path, payload=None):
    request = urllib.request.Request('http://127.0.0.1:8189' + path,
        data=json.dumps(payload).encode() if payload is not None else None,
        headers={'Content-Type': 'application/json', 'Origin': 'http://127.0.0.1:8189'})
    with urllib.request.urlopen(request, timeout=60) as response:
        return json.load(response)


manifest = json.loads((OUT / 'manifest.json').read_text(encoding='utf-8'))
for key in sys.argv[1:]:
    record = manifest['props'][key]
    prompt = json.loads((OUT / (key + '_api.json')).read_text(encoding='utf-8'))
    workflow = json.loads(pathlib.Path(record['workflow']).read_text(encoding='utf-8'))
    saved_history = OUT / (key + '_history.json')
    h = json.loads(saved_history.read_text(encoding='utf-8')) if saved_history.exists() else None
    if h is None or h['status']['status_str'] != 'success':
        try:
            pid = api('/prompt', {'prompt': prompt, 'extra_data': {'extra_pnginfo': {'workflow': workflow}}})['prompt_id']
        except urllib.error.HTTPError as e:
            print(e.read().decode(), flush=True)
            raise
        print(key, 'START', pid, flush=True)
        while True:
            time.sleep(10)
            history = api('/history/' + pid)
            if pid in history:
                h = history[pid]
                saved_history.write_text(json.dumps(h, indent=2), encoding='utf-8')
                break
    else:
        pid = h['prompt'][1]
        print(key, 'RESUME saved generation', flush=True)
    if h['status']['status_str'] != 'success':
        print(h['status'], flush=True)
        raise RuntimeError('Prop inpaint failed: ' + key)
    item = h['outputs']['31']['images'][0]
    path = ROOT / 'output' / item['subfolder'] / item['filename']
    source = pathlib.Path(manifest['sources'][record['source']]['original'])
    a = np.asarray(Image.open(source).convert('RGBA'))
    b = np.array(Image.open(path).convert('RGBA'))
    mask = np.asarray(Image.open(OUT / (record['source'] + '_mask.png')))
    protected = np.ones(a.shape[:2], dtype=bool)
    protected[800:1824, 608:1632] = mask == 0
    # LoadImage -> inverse-alpha MASK -> JoinImageWithAlpha can round alpha
    # down by one 8-bit level. Restore exact source bytes outside the mask in
    # the production export; retain the original ComfyUI output for evidence.
    delta = np.abs(a[protected].astype(int) - b[protected].astype(int))
    assert delta.max() <= 1 and delta[:, :3].max() == 0, 'Unexpected change outside mask'
    b[protected] = a[protected]
    exact_path = path.parent / ('Evelyn_' + key + '.png')
    metadata = PngImagePlugin.PngInfo()
    for meta_key, value in Image.open(path).info.items():
        if isinstance(value, str):
            metadata.add_text(meta_key, value)
    Image.fromarray(b).save(exact_path, pnginfo=metadata)
    assert np.array_equal(a[protected], np.array(Image.open(exact_path))[protected])
    record.update(status='generated_visual_review_pending', prompt_id=pid, image=str(exact_path),
                  raw_comfy_image=str(path), size=list(b.shape[1::-1]), outside_mask_exact=True)
    (OUT / 'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding='utf-8')
    crop = Image.open(exact_path).convert('RGBA').crop((608, 800, 1632, 1824))
    bg = Image.new('RGBA', crop.size, '#e5e4e0')
    bg.alpha_composite(crop)
    bg.convert('RGB').save(OUT / (key + '_review.png'))
    print(key, 'SUCCESS', exact_path, 'outside_mask_exact=True', flush=True)
