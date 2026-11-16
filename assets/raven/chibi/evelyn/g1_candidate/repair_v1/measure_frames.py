"""Measure only: no bitmap edits. Produces deterministic source pivot metadata.

python measure_frames.py > frames.json
python measure_frames.py --check
"""
import argparse
import hashlib
import json
import statistics
from pathlib import Path
from PIL import Image

HERE = Path(__file__).resolve().parent

def measure():
    path = HERE / "evelyn_walk.png"
    image = Image.open(path)
    assert image.mode == "RGBA" and image.size == (1024, 1536)
    alpha = image.getchannel("A")
    frames = {}
    for row, name in enumerate(("down", "up", "side")):
        frames[name] = []
        # Side frame 4 crosses the requested cell boundary. An explicit split
        # inside the measured empty gutter prevents sampling a neighbour.
        cuts = (0, 256, 512, 754, 1024) if row == 2 else (0, 256, 512, 768, 1024)
        for column in range(4):
            x, width = cuts[column], cuts[column+1]-cuts[column]
            cell = alpha.crop((x, row*512, x+width, row*512+512))
            mask = cell.point(lambda v: 255 if v > 128 else 0)
            left, top, right, bottom = mask.getbbox()
            assert 0 < left < right < width and 0 < top < bottom < 512
            centers = []
            for y in range(top + 12, top + (bottom-top)//4):
                bounds = mask.crop((0, y, width, y+1)).getbbox()
                if bounds:
                    centers.append((bounds[0]+bounds[2])/2)
            frames[name].append({"region": [x, row*512, width, 512],
                                 "boundsAlphaAbove128": [left, top, right, bottom],
                                 "pivot": [statistics.median(centers), bottom],
                                 "visibleHeight": bottom-top})
    histogram = alpha.histogram()
    return {"schemaVersion": 1, "sourceSha256": hashlib.sha256(path.read_bytes()).hexdigest(),
            "atlasSize": [1024, 1536], "layout": "explicit regions; side row split at x754", "fps": 6,
            "zeroAlphaPixels": histogram[0], "lowAlphaPixels1to15": sum(histogram[1:16]),
            "ownerDesignSelected": True, "ownerMotionApproved": False,
            "pivotMethod": "median head-row center x / lowest alpha>128 sole boundary y; per-frame scale normalizes visible height",
            "frames": frames}

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    data = measure()
    if args.check:
        assert data == json.loads((HERE / "frames.json").read_text(encoding="utf-8"))
        print("PASS: atlas hash, 12 bounded frames and deterministic measured pivots; visual motion approval pending")
    else:
        print(json.dumps(data, indent=2))
