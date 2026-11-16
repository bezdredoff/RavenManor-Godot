"""Read-only validation. Godot bake_atlas.gd owns import normalization."""
import argparse
import hashlib
import json
from pathlib import Path
from PIL import Image, ImageFilter, ImageChops

HERE = Path(__file__).resolve().parent


def measure():
    path = HERE / "evelyn_walk.png"
    image = Image.open(path)
    assert image.mode == "RGBA" and image.size == (1024, 1536)
    imported = (HERE / "evelyn_walk.png.import").read_text(encoding="utf-8").splitlines()
    for setting in ("compress/mode=0", "mipmaps/generate=false", "process/size_limit=0", "process/premult_alpha=false"):
        assert setting in imported, "Import contract drift: " + setting
    alpha = image.getchannel("A")
    frames = {}
    for row, name in enumerate(("down", "up", "side")):
        frames[name] = []
        for column in range(4):
            cell = image.crop((column*256, row*512, column*256+256, row*512+512))
            bounds = cell.getchannel("A").point(lambda v: 255 if v > 128 else 0).getbbox()
            assert abs(bounds[1] - 32) <= 1 and bounds[3] == 480, (name, column, bounds)
            assert 8 <= bounds[0] < bounds[2] <= 248
            for edge in ((0, 0, 8, 512), (248, 0, 256, 512), (0, 0, 256, 24), (0, 488, 256, 512)):
                assert cell.getchannel("A").crop(edge).getextrema() == (0, 0)
            frames[name].append({"region": [column*256, row*512, 256, 512],
                                 "boundsAlphaAbove128": list(bounds),
                                 "pivot": [128, 480], "visibleHeight": 448})
    opaque = alpha.point(lambda v: 255 if v > 128 else 0)
    nearby = opaque.filter(ImageFilter.MaxFilter(9))
    residue = ImageChops.subtract(alpha.point(lambda v: 255 if v else 0), nearby)
    assert residue.getbbox() is None, "Non-edge alpha residue remains"
    return {"schemaVersion": 2, "sourceSha256": hashlib.sha256(path.read_bytes()).hexdigest(),
            "generationSourceSha256": hashlib.sha256((HERE / "evelyn_walk_source.png").read_bytes()).hexdigest(),
            "atlasSize": [1024, 1536], "frameSize": [256, 512],
            "layout": "uniform 4 columns x 3 rows: down/up/right; left is mirrored right",
            "pivot": [128, 480], "visibleHeight": 448, "idleFrame": 1,
            "walkSequence": [0, 1, 2, 3],
            "frameMeaning": ["opposed contact A", "passing A", "opposed contact B", "passing B"],
            "cycleTravelInHeights": 0.5,
            "cadence": "one cycle per 0.5 displayed heights of ACTUAL root travel; no timer or FPS clamp",
            "zeroAlphaPixels": alpha.histogram()[0], "requiresAlphaMaterial": False,
            "ownerApproved": True,
            "ownerApprovalEvidence": "2026-11-17: owner reviewed merged PR #274 Godot preview and approved Evelyn visual design and animation",
            "productionReplacementAllowed": False, "productionIntegrationVerified": False,
            "deviceVerified": False, "foregroundOcclusionVerified": False, "frames": frames}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    data = measure()
    if args.check:
        assert data == json.loads((HERE / "frames.json").read_text(encoding="utf-8"))
        print("PASS: clean alpha, uniform 12-cell atlas, fixed crown/sole/pivot/hash; owner visual approval recorded")
    else:
        (HERE / "frames.json").write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
        print("Wrote frames.json; visual identity/contact remain review judgments")
