import unittest
import json
from copy import deepcopy
from pathlib import Path
from scripts.raven.tools.sync_hall_preview import ROOT, convert

CONTRACT = json.loads((ROOT / "data/raven/hall_visual_contract.json").read_text(encoding="utf-8"))

def draft():
    wx, wy, w, h = CONTRACT["roomWorldRect"]
    objs = []
    for i, entry in enumerate(CONTRACT["sprites"]):
        x,y,bw,bh = entry["rect"]
        objs.append({"id":f"instance-{i}","assetRefId":entry["assetRefId"],
                     "x":x-wx,"y":y-wy,"w":bw,"h":bh,
                     "rotation":0,"state":entry["state"]})
    return {"schemaVersion":1,"roomId":"RM-ROOM-HALL","width":w,"height":h,
            "visualContractVersion":1,"objects":objs}

class HallVisualBridgeTests(unittest.TestCase):
    def test_exact_baseline_round_trip(self):
        result=convert(draft(),CONTRACT)
        self.assertEqual(result["status"],"DRAFT_ONLY")
        self.assertEqual(len(result["sprites"]),7)
        self.assertEqual([o["rect"] for o in result["sprites"]],[s["rect"] for s in CONTRACT["sprites"]])
    def test_move_and_remove_do_not_touch_manifest(self):
        doc=draft()
        doc["objects"][1]["x"]+=25
        doc["objects"].pop()
        result=convert(doc,CONTRACT)
        self.assertEqual(len(result["sprites"]),6)
        self.assertEqual(result["sprites"][1]["rect"][0],CONTRACT["sprites"][1]["rect"][0]+25)
        self.assertEqual(CONTRACT["sprites"][1]["rect"][0],575)
    def test_no_fake_geometry_or_unapproved_states(self):
        doc=draft();doc["width"]=1000
        with self.assertRaises(ValueError):convert(doc,CONTRACT)
        doc=draft();doc["objects"][1]["state"]="repaired"
        with self.assertRaises(ValueError):convert(doc,CONTRACT)
        doc=draft();doc["objects"][1]["rotation"]=45
        with self.assertRaises(ValueError):convert(doc,CONTRACT)
    def test_duplicate_and_malformed_data_rejected(self):
        doc=draft();doc["objects"].append(deepcopy(doc["objects"][1]))
        with self.assertRaises(ValueError):convert(doc,CONTRACT)
        doc=draft();doc["objects"][1]["w"]=float("nan")
        with self.assertRaises(ValueError):convert(doc,CONTRACT)
        doc=draft();doc["objects"][1]["assetRefId"]=doc["objects"][0]["assetRefId"]
        with self.assertRaises(ValueError):convert(doc,CONTRACT)
    def test_foreign_decor_is_ignored_but_not_relabelled(self):
        doc=draft();doc["objects"].append({"id":"decoration","assetRefId":"RM-ASSET-HALL-999"})
        result=convert(doc,CONTRACT)
        self.assertEqual(len(result["sprites"]),7)

if __name__ == "__main__":
    unittest.main()
