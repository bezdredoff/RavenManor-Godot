import base64
import json
import math
import tempfile
import unittest
from copy import deepcopy
from pathlib import Path

from scripts.raven.tools.import_room_builder_game import ROOT, scene_from_project, validate_room, FLOOR_RATIO

FIXTURE = json.loads((ROOT/"tests/fixtures/hall_room_builder_export_sample.json").read_text(encoding="utf-8"))
WORLD = json.loads((ROOT/"data/raven/season1_world_map.json").read_text(encoding="utf-8"))

class GamePreviewImportTests(unittest.TestCase):
    def test_fixture_to_godot_art_scene(self):
        with tempfile.TemporaryDirectory() as temp:
            path, counts=scene_from_project(FIXTURE,Path(temp))
            text=path.read_text(encoding="utf-8")
            self.assertEqual(path.name,"RM_ROOM_HALL_GamePreview.tscn")
            self.assertEqual(counts["pilot"],7)
            self.assertEqual(counts["ignoredCharacters"],1)
            self.assertEqual(counts["placeholders"],0)
            self.assertIn("HallPilotBackground",text)
            self.assertIn("game_camera_degrees = 65",text)
            self.assertIn('metadata/geometry_approval = "DRAFT_ONLY"',text)
            self.assertIn('metadata/world_origin = Vector2(500.0000, 150.0000)',text)
            self.assertIn('metadata/asset_ref_id = "RM-ASSET-HALL-017"',text)
            self.assertIn('metadata/visual_mode = "upright"',text)
            self.assertIn('metadata/visual_mode = "floor"',text)
            self.assertIn('grandfather_clock.png',text)
            self.assertIn('armchair_clean.png',text)
            self.assertNotIn("character:onoe",text)
            self.assertEqual((path.read_bytes(),counts),
                             (scene_from_project(FIXTURE,Path(temp))[0].read_bytes(),counts))

    def test_full_room_size_must_match_map_proposal(self):
        with tempfile.TemporaryDirectory() as temp:
            wrong=deepcopy(FIXTURE);wrong["width"]=1000
            with self.assertRaisesRegex(ValueError,"does not match Godot"):
                scene_from_project(wrong,Path(temp))
            self.assertFalse((Path(temp)/"scenes").exists())
            wrong=deepcopy(FIXTURE);wrong["roomId"]="RM-ROOM-UNKNOWN"
            with self.assertRaises(ValueError):scene_from_project(wrong,Path(temp))

    def test_unapproved_state_falls_back_to_placeholder_not_false_pilot_art(self):
        with tempfile.TemporaryDirectory() as temp:
            altered=deepcopy(FIXTURE)
            altered["objects"][1]["state"]="repaired"
            path,counts=scene_from_project(altered,Path(temp))
            self.assertEqual(counts["pilot"],6)
            self.assertEqual(counts["placeholders"],1)
            self.assertIn('UNRENDERED_PLACEHOLDER',path.read_text(encoding="utf-8"))

    def test_layer_hidden_assets_missing_ids_and_finite_geometry(self):
        with tempfile.TemporaryDirectory() as temp:
            altered=deepcopy(FIXTURE);altered["layers"][1]["visible"]=False
            _,counts=scene_from_project(altered,Path(temp))
            self.assertEqual(counts["rendered"],1)
            altered=deepcopy(FIXTURE);altered["objects"][0]["w"]=float("nan")
            with self.assertRaises(ValueError):scene_from_project(altered,Path(temp))
            altered=deepcopy(FIXTURE);altered["objects"][0]["assetId"]="not-in-library"
            with self.assertRaises(ValueError):scene_from_project(altered,Path(temp))

    def test_embedded_png_becomes_real_godot_texture(self):
        png=base64.b64decode(
            "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aC1sAAAAASUVORK5CYII="
        )
        altered=deepcopy(FIXTURE)
        altered["assets"].append({"id":"user:lamp","label":"My lamp","kind":"decor","w":40,"h":50,
                                  "image":"data:image/png;base64,"+base64.b64encode(png).decode("ascii")})
        altered["objects"].append({"id":"user-lamp","assetId":"user:lamp","layerId":"objects",
                                   "x":100,"y":100,"w":40,"h":50,"rotation":0})
        with tempfile.TemporaryDirectory() as temp:
            path,counts=scene_from_project(altered,Path(temp))
            self.assertEqual(counts["embedded"],1)
            files=list((Path(temp)/"assets/raven/generated/RM_ROOM_HALL").glob("*.png"))
            self.assertEqual(len(files),1)
            self.assertEqual(files[0].read_bytes(),png)
            self.assertIn('assets/raven/generated/RM_ROOM_HALL/',path.read_text())

    def test_excluded_editor_character_not_imported_as_game_actor(self):
        altered=deepcopy(FIXTURE)
        altered["objects"]=[obj for obj in altered["objects"] if obj["assetId"]=="character:onoe"]
        with tempfile.TemporaryDirectory() as temp:
            path,counts=scene_from_project(altered,Path(temp))
            self.assertEqual(counts["rendered"],0)
            self.assertEqual(counts["ignoredCharacters"],1)
            self.assertNotIn("Onoe",path.read_text())

    def test_source_geometry_mirrored_without_horizontal_flip(self):
        original=json.loads((ROOT/"examples/room_builder_hall_original.json").read_text(encoding="utf-8"))
        self.assertEqual(original["sourceLayout"]["worldRect"],[500,150,700,690])
        self.assertFalse(original["sourceLayout"]["horizontalFlip"])
        self.assertEqual(len(original["referenceFootprints"]),6)
        self.assertEqual(len([a for a in original["anchors"] if a["kind"]=="door"]),5)
        map_source=json.loads((ROOT/"data/raven/season1_world_map.json").read_text(encoding="utf-8"))
        for marker in original["anchors"]:
            if marker["kind"]!="door":continue
            source=next(x for x in map_source["doors"] if x["id"]==marker["id"])
            self.assertEqual([marker["x"]+500,marker["y"]+150],source["point"])
        with tempfile.TemporaryDirectory() as temp:
            scene, counts=scene_from_project(original,Path(temp))
            text=scene.read_text(encoding="utf-8")
            self.assertEqual(counts["rendered"],7)
            self.assertIn('name="ReferenceGeometry" type="Node2D"',text)
            self.assertIn('visible = false',text)
            self.assertIn('RM-ASSET-HALL-STAIRS-L',text)
            self.assertIn('RM-ASSET-HALL-STAIRS-R',text)
            self.assertIn('RM-DOOR-HALL-ARCHIVE',text)
            self.assertIn('RM-DOOR-HALL-CORRIDOR',text)
            self.assertIn('RM-DOOR-ENTRY-HALL',text)

if __name__=="__main__":
    unittest.main()
