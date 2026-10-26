import json
import unittest
from copy import deepcopy

from scripts.raven.tools.build_hall_calibration import ROOT, build

WORLD = json.loads((ROOT / "data/raven/season1_world_map.json").read_text(encoding="utf8"))
VISUALS = json.loads((ROOT / "data/raven/hall_visual_contract.json").read_text(encoding="utf8"))
CALIBRATION = json.loads((ROOT / "data/raven/hall_calibration.json").read_text(encoding="utf8"))


class HallCalibrationTests(unittest.TestCase):
    def test_exactly_reproduces_source_map(self):
        self.assertEqual(build(WORLD, VISUALS), CALIBRATION)
        self.assertEqual(CALIBRATION["status"], "CALIBRATION_ONLY_UNAPPROVED")
        self.assertFalse(any(CALIBRATION["gates"].values()))
        self.assertEqual(len(CALIBRATION["doors"]), 5)
        self.assertEqual(len(CALIBRATION["stairs"]), 2)
        self.assertEqual(len(CALIBRATION["candidateSeatFootprints"]), 3)
        self.assertEqual([p["id"] for p in CALIBRATION["stairs"]],
                         ["RM-ASSET-HALL-STAIRS-L", "RM-ASSET-HALL-STAIRS-R"])

    def test_doors_match_world_and_future_are_not_active(self):
        doors = {d["id"]: d for d in WORLD["doors"]}
        for proposal in CALIBRATION["doors"]:
            original = doors[proposal["id"]]
            self.assertEqual(original["point"], proposal["point"])
            self.assertEqual(original["status"], proposal["status"])
            if original["status"] == "future":
                self.assertEqual(proposal["kind"], "future-only")

    def test_candidate_feet_are_strict_subsets_of_existing_group_and_cutouts(self):
        cx,cy,cw,ch=CALIBRATION["originalSeatCollider"]
        sprites = {sprite["assetRefId"]:sprite for sprite in VISUALS["sprites"]}
        for item in CALIBRATION["candidateSeatFootprints"]:
            x,y,w,h=item["rect"]
            sx,sy,sw,sh=sprites[item["assetRefId"]]["rect"]
            self.assertGreater(w,0);self.assertGreater(h,0)
            self.assertGreaterEqual(x,cx);self.assertGreaterEqual(y,cy)
            self.assertLessEqual(x+w,cx+cw);self.assertLessEqual(y+h,cy+ch)
            self.assertGreaterEqual(x,sx);self.assertGreaterEqual(y,sy)
            self.assertLessEqual(x+w,sx+sw);self.assertLessEqual(y+h,sy+sh)
            self.assertEqual(item["status"],"UNAPPROVED")
        self.assertNotEqual([item["rect"] for item in CALIBRATION["candidateSeatFootprints"]],
                            [CALIBRATION["originalSeatCollider"]]*3)

    def test_stair_validation_prevents_silent_relayout(self):
        wrong=deepcopy(VISUALS);wrong["roomWorldRect"][2]+=100
        with self.assertRaises(ValueError):build(WORLD,wrong)
        wrong=deepcopy(WORLD)
        next(p for p in wrong["props"] if p["id"]=="RM-ASSET-HALL-SEATS")["rect"][0]+=200
        with self.assertRaises(ValueError):build(wrong,VISUALS)


if __name__=="__main__":
    unittest.main()
