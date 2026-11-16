#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""CODE-05-02 (G1): build the HC/CB door calibration evidence image.

Read-only. Reads the immutable approved PNG and the DRAFT_ONLY calibration
record, then draws the proposed HC/CB thresholds, near/far feet and opening
spans over a copy. Writes docs/qa/map-qa-09c/g1-door-calibration.png.
"""
import json
import os

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
PNG = os.path.join(REPO, "a_detailed_top_down_isometric_game_map_illustratio.png")
CAL = os.path.join(REPO, "assets", "raven", "map", "qa", "drafts",
                   "map_qa_09c_g1_door_calibration.v1.json")
OUT = os.path.join(HERE, "g1-door-calibration.png")

GOLD = (255, 200, 0, 255)
NEAR = (0, 210, 90, 255)   # green = near (approach) foot
FAR = (90, 140, 255, 255)  # blue  = far (entry) foot


def main():
    img = Image.open(PNG).convert("RGB")
    with open(CAL, "r", encoding="utf-8") as f:
        data = json.load(f)
    draw = ImageDraw.Draw(img, "RGBA")

    for door in data["doors"]:
        thr = door["thresholdPx"]
        near = door["nearFootPx"]
        far = door["farFootPx"]
        normal = door["normalPx"]
        perp = [-normal[1], normal[0]]
        half = door["openingWidthPx"] / 2.0
        span_a = [thr[0] + perp[0] * half, thr[1] + perp[1] * half]
        span_b = [thr[0] - perp[0] * half, thr[1] - perp[1] * half]

        # Gold opening span + threshold crosshair.
        draw.line([span_a[0], span_a[1], span_b[0], span_b[1]], fill=GOLD, width=3)
        draw.ellipse([thr[0] - 3, thr[1] - 3, thr[0] + 3, thr[1] + 3], fill=GOLD)
        # Near (approach) and far (entry) feet.
        draw.ellipse([near[0] - 6, near[1] - 6, near[0] + 6, near[1] + 6],
                     outline=NEAR, width=2)
        draw.ellipse([far[0] - 6, far[1] - 6, far[0] + 6, far[1] + 6],
                     outline=FAR, width=2)
        # Arrow from near to far through the threshold.
        draw.line([near[0], near[1], far[0], far[1]], fill=GOLD, width=1)
        draw.text((thr[0] + 8, thr[1] - 16), door["label"].split(" ")[0],
                  fill=(255, 255, 255, 255))

    img.save(OUT)
    print("wrote %s" % OUT)


if __name__ == "__main__":
    main()
