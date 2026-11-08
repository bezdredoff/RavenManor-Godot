import json
import tempfile
import unittest
from copy import deepcopy
from pathlib import Path

from scripts.raven.tools.import_first_floor_draft import (
    ROOT, scene_from_first_floor, validate_first_floor,
)
from scripts.raven.tools.import_room_builder_game import scene_from_project

PROJECT = json.loads((ROOT / "tests/fixtures/first_floor_draft_valid.json").read_text(encoding="utf-8"))
WORLD = json.loads((ROOT / "data/raven/season1_world_map.json").read_text(encoding="utf-8"))


class FirstFloorDraftImportTests(unittest.TestCase):
    def test_deterministic_draft_scene_and_machine_readable_export(self):
        with tempfile.TemporaryDirectory() as temp:
            output = Path(temp)
            scene, result = scene_from_project(PROJECT, output)
            self.assertEqual(scene.name, "RM_FIRST_FLOOR_DRAFT_v2.tscn")
            self.assertEqual((result["rooms"], result["doors"], result["anchors"]), (8, 11, 1))
            txt = scene.read_text(encoding="utf-8")
            self.assertIn('metadata/geometry_approval = "DRAFT_ONLY"', txt)
            self.assertIn('metadata/navigation_authority = "NONE"', txt)
            self.assertIn('metadata/door_id = "RM-DOOR-HALL-CORRIDOR"', txt)
            self.assertIn('metadata/anchor_id = "RM-NAV-HALL-CHECK"', txt)
            self.assertIn("BasePainting", txt)
            self.assertNotIn("StaticBody2D", txt)
            self.assertNotIn("NavigationRegion2D", txt)
            manifest = Path(result["manifest"])
            data = json.loads(manifest.read_text(encoding="utf-8"))
            self.assertEqual(data["source"], PROJECT["firstFloorDraft"])
            self.assertEqual(len(data["comparison"]["roomDeltas"]), 8)
            before = (scene.read_bytes(), manifest.read_bytes())
            again, counts = scene_from_first_floor(PROJECT, output)
            self.assertEqual(counts, result)
            self.assertEqual((again.read_bytes(), manifest.read_bytes()), before)
            self.assertEqual(len(list((output / "assets/raven/generated/first_floor").glob("*.png"))), 1)

    def test_missing_asset_fails_before_any_output(self):
        project = deepcopy(PROJECT)
        project["firstFloorDraft"]["baseImage"] = {"path": "assets/raven/not-present-first-floor.png", "pixelSize": [1, 1]}
        with tempfile.TemporaryDirectory() as temp:
            with self.assertRaisesRegex(ValueError, "Missing asset"):
                scene_from_first_floor(project, Path(temp))
            self.assertEqual(list(Path(temp).iterdir()), [])

    def test_bad_schema_version_fails_closed(self):
        project = deepcopy(PROJECT)
        project["firstFloorDraft"]["schemaVersion"] = 3
        with self.assertRaisesRegex(ValueError, "schemaVersion"):
            validate_first_floor(project, WORLD)
        project = deepcopy(PROJECT)
        project["schemaVersion"] = 2
        with self.assertRaisesRegex(ValueError, "schemaVersion"):
            validate_first_floor(project, WORLD)

    def test_duplicate_ids_and_unknown_ids(self):
        project = deepcopy(PROJECT)
        project["firstFloorDraft"]["roomRegions"].append(deepcopy(project["firstFloorDraft"]["roomRegions"][0]))
        with self.assertRaisesRegex(ValueError, "duplicate ID"):
            validate_first_floor(project, WORLD)
        project = deepcopy(PROJECT)
        project["firstFloorDraft"]["doorPlacements"][0]["id"] = "RM-DOOR-UNKNOWN"
        with self.assertRaisesRegex(ValueError, "Unknown door ID"):
            validate_first_floor(project, WORLD)
        project = deepcopy(PROJECT)
        project["firstFloorDraft"]["roomRegions"][0]["id"] = "RM-ROOM-UNKNOWN"
        with self.assertRaisesRegex(ValueError, "Unknown room ID"):
            validate_first_floor(project, WORLD)

    def test_invalid_door_placement_and_pair(self):
        project = deepcopy(PROJECT)
        project["firstFloorDraft"]["doorPlacements"][0]["point"] = [200, 200]
        with self.assertRaisesRegex(ValueError, "Invalid door placement"):
            validate_first_floor(project, WORLD)
        project = deepcopy(PROJECT)
        project["firstFloorDraft"]["doorPlacements"][0]["rooms"][0] = "RM-ROOM-KITCHEN"
        with self.assertRaisesRegex(ValueError, "invalid room references"):
            validate_first_floor(project, WORLD)

    def test_calibration_mismatch_and_bad_dimensions(self):
        project = deepcopy(PROJECT)
        project["firstFloorDraft"]["calibration"]["controlPoints"][1]["world"] = [1234, 567]
        with self.assertRaisesRegex(ValueError, "Mismatched calibration"):
            validate_first_floor(project, WORLD)
        project = deepcopy(PROJECT)
        project["firstFloorDraft"]["baseImage"]["pixelSize"] = [400, 600]
        with self.assertRaisesRegex(ValueError, "actual PNG dimensions"):
            validate_first_floor(project, WORLD)
        project = deepcopy(PROJECT)
        project["firstFloorDraft"]["roomRegions"][0]["rect"][2] = 10000
        with self.assertRaisesRegex(ValueError, "room geometry"):
            validate_first_floor(project, WORLD)

    def test_duplicate_nav_points_and_invalid_pivot(self):
        project = deepcopy(PROJECT)
        anchor = deepcopy(project["firstFloorDraft"]["navigationAnchors"][0])
        anchor["id"] = "RM-NAV-HALL-SECOND"
        project["firstFloorDraft"]["navigationAnchors"].append(anchor)
        with self.assertRaisesRegex(ValueError, "Duplicate navigation point"):
            validate_first_floor(project, WORLD)
        project = deepcopy(PROJECT)
        project["firstFloorDraft"]["foregroundObjects"].append({
            "id": "RM-FG-CLOCK", "roomId": "RM-ROOM-HALL",
            "position": [900, 700], "size": [50, 80], "pivot": [25, 90],
            "assetPath": "assets/raven/hall/generated_pilot/props/grandfather_clock.png",
            "occlusion": {"mode": "foot_y"},
        })
        with self.assertRaisesRegex(ValueError, "floor-contact pivot"):
            validate_first_floor(project, WORLD)

    def test_broken_json_is_explicit_error(self):
        with self.assertRaises(json.JSONDecodeError):
            json.loads('{"schemaVersion":1,"firstFloorDraft":')

    def test_opt_in_does_not_change_old_room_import(self):
        old = deepcopy(PROJECT)
        old.pop("firstFloorDraft")
        old["assets"] = [{"id": "decor", "kind": "decor", "w": 20, "h": 20}]
        old["layers"] = [{"id": "objects", "name": "Objects", "visible": True}]
        old["objects"] = [{"id": "obj", "assetId": "decor", "layerId": "objects",
                           "x": 100, "y": 100, "w": 20, "h": 20, "rotation": 0}]
        with tempfile.TemporaryDirectory() as temp:
            path, metrics = scene_from_project(old, Path(temp))
            self.assertTrue(path.name.endswith("_GamePreview.tscn"))
            self.assertEqual(metrics["rendered"], 1)
            self.assertNotIn("import_schema_version = 2", path.read_text(encoding="utf-8"))


if __name__ == "__main__":
    unittest.main()
