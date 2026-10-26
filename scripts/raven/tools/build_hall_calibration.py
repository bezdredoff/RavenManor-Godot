#!/usr/bin/env python3
"""Build diagnostic Hall calibration markers from existing map and visual art bounds.

No acceptance of world topology or gameplay collision. Candidate seating
footprints are deliberately labelled UNAPPROVED and are contained entirely
within the existing collision cluster.

  python3 scripts/raven/tools/build_hall_calibration.py
  python3 scripts/raven/tools/build_hall_calibration.py --check
"""
import argparse
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[3]
MAP=ROOT/"data/raven/season1_world_map.json"
SPRITES=ROOT/"data/raven/hall_visual_contract.json"
OUTPUT=ROOT/"data/raven/hall_calibration.json"


def build(world,visual):
    room_id="RM-ROOM-HALL"
    idx=next(i for i,r in enumerate(world["rooms"]) if r["id"]==room_id)
    room=world["rooms"][idx]["rect"]
    if room!=visual["roomWorldRect"]:
        raise ValueError("Calibrated Hall source map differs from visual rect")
    seat=next(p for p in world["props"] if p["id"]=="RM-ASSET-HALL-SEATS")
    cluster=seat["rect"]
    candidates=[]
    for sprite in visual["sprites"]:
        if sprite["id"] not in ["chair-left","chair-right","round-table"]:
            continue
        x,y,w,h=sprite["rect"]
        chair=sprite["id"].startswith("chair")
        inset=round(w*(0.10 if chair else 0.12))
        rise=round(h*(0.68 if chair else 0.52))
        dims=[x+inset,y+rise,w-inset*2,round(h*(0.32 if chair else 0.42))]
        if not (cluster[0]<=dims[0] and cluster[1]<=dims[1]
                and dims[0]+dims[2]<=cluster[0]+cluster[2]
                and dims[1]+dims[3]<=cluster[1]+cluster[3]):
            raise ValueError("Seat candidate lies outside existing cluster")
        candidates.append({"assetRefId":sprite["assetRefId"],"kind":sprite["id"],
                           "rect":dims,"origin":"pilot-cutout-derived-proposal",
                           "status":"UNAPPROVED"})
    return {"schemaVersion":1,"roomId":room_id,"roomWorldRect":room,
            "status":"CALIBRATION_ONLY_UNAPPROVED",
            "reason":"Sourced portal centers and staircase geometry from the canonical feasibility map. Seats contact-box test candidates are art-derived guesses, not approved physical colliders.",
            "sourceMap":"data/raven/season1_world_map.json",
            "sourceSprites":"data/raven/hall_visual_contract.json",
            "originalSeatCollider":cluster,
            "doors":[{"id":d["id"],"point":d["point"],"status":d["status"],
                      "kind":"future-only" if d["status"]=="future" else "portal-candidate"}
                     for d in world["doors"] if d["a"]==idx or d["b"]==idx],
            "stairs":[{"id":p["id"],"rect":p["rect"],"style":"tread-guides-only",
                       "treads":6,"status":"UNAPPROVED"}
                      for p in world["props"] if p["room"]==idx and "STAIRS" in p["id"]],
            "candidateSeatFootprints":candidates,
            "gates":{"replaceCanonicalCollider":False,"applyToCampaign":False,
                     "approvedBackground":False,"acceptedPixelMargins":False}}


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check",action="store_true")
    a=parser.parse_args()
    result=build(json.loads(MAP.read_text(encoding="utf-8")),
                 json.loads(SPRITES.read_text(encoding="utf-8")))
    text=json.dumps(result,ensure_ascii=False,indent=2)+"\n"
    if a.check:
        if not OUTPUT.exists() or OUTPUT.read_text(encoding="utf-8")!=text:
            raise SystemExit("Hall calibration out of sync with source map/sprites")
    else:
        OUTPUT.write_text(text,encoding="utf-8")
    print("Hall calibration verified:",len(result["doors"]),"doors,",
          len(result["stairs"]),"staircases,",
          len(result["candidateSeatFootprints"]),"test seat contact boxes")


if __name__=="__main__":
    main()
