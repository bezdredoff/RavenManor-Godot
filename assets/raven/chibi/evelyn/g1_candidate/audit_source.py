"""Measure the rejected source without editing pixels. Not a visual approval test.

Run from any directory: python audit_source.py --check
Requires Pillow. --check verifies recorded evidence and the blocked handoff contract.
It does NOT mean the sprite passes production requirements.
"""
import argparse
import hashlib
import json
from pathlib import Path

from PIL import Image

HERE = Path(__file__).resolve().parent


def measure():
    spec = json.loads((HERE / "atlas_spec.json").read_text(encoding="utf-8"))
    source = HERE / spec["rejectedSource"]
    with Image.open(source) as image:
        if image.mode != "RGBA" or list(image.size) != spec["target"]["atlasSize"]:
            raise ValueError("Unexpected raw source dimensions/mode")
        alpha = image.getchannel("A")
        histogram = alpha.histogram()
        count = image.width * image.height
        cells = []
        for row, facing in enumerate(spec["target"]["rows"]):
            for column in range(4):
                cell = alpha.crop((column * 256, row * 512,
                                   (column + 1) * 256, (row + 1) * 512))
                bounds = cell.point(lambda value: 255 if value > 32 else 0).getbbox()
                # >32 excludes haze for measurement ONLY. Never alter source alpha.
                cells.append({"facing": facing, "column": column,
                              "alphaAbove32BoundsExclusive": list(bounds) if bounds else None,
                              "productionValidated": False})
        return {
            "sourceSha256": hashlib.sha256(source.read_bytes()).hexdigest(),
            "mode": image.mode, "size": list(image.size),
            "zeroAlphaPixels": histogram[0], "totalPixels": count,
            "lowNonzeroAlphaPixels1to15": sum(histogram[1:16]),
            "nonzeroAlphaFraction": round(1 - histogram[0] / count, 6),
            "cells": cells,
            "result": "REJECTED_ART_NOT_PRODUCTION_ATLAS",
            "visualJudgments": "See HANDOFF.md; alpha bounds do not prove anatomy, identity, ground contact or walking quality."
        }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    result = measure()
    if args.check:
        recorded = json.loads((HERE / "source_audit.json").read_text(encoding="utf-8"))
        spec = json.loads((HERE / "atlas_spec.json").read_text(encoding="utf-8"))
        if result != recorded:
            raise ValueError("Source audit drift: remeasure and review changed evidence")
        if (spec["runtimeAtlas"] is not None or spec["validatedFrames"]
                or spec["ownerApproved"] or spec["state"] != "art_blocked"):
            raise ValueError("Rejected handoff must not masquerade as approved runtime art")
        print("PASS: rejected-source evidence reproducible; production art remains BLOCKED")
    else:
        print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
