"""Agent A v1 manifest interoperability: immutable sample from PR #239."""
import copy
import hashlib
import json
import tempfile
import unittest
from pathlib import Path

from scripts.raven.tools.first_floor_art_adapter import adapt_art_manifest, measured_source
from scripts.raven.tools.import_first_floor_draft import ROOT, validate_first_floor
from scripts.raven.tools.import_room_builder_game import scene_from_project

ART = json.loads((ROOT / "tests/fixtures/first_floor_art_A_v1_unapproved.json").read_text("utf-8"))
WORLD = json.loads((ROOT / "data/raven/season1_world_map.json").read_text("utf-8"))


class FirstFloorArtAdapterTests(unittest.TestCase):
    def test_real_owner_png_is_verified_and_manifest_source_is_immutable(self):
        source_before = copy.deepcopy(ART)
        base = measured_source(ART)
        self.assertEqual(base["path"], "a_detailed_top_down_isometric_game_map_illustratio.png")
        self.assertEqual(base["gitBlobSha"], "b50bc36cffd3d3aca7e81a0cea28bb3d0c0e9563")
        self.assertEqual(len(base["sha256"]), 64)
        self.assertEqual(base["pixelSize"][0] > 0, True)
        draft = adapt_art_manifest(ART, WORLD)["firstFloorDraft"]
        self.assertEqual(ART, source_before)
        self.assertEqual(draft["producerManifest"], source_before)
        self.assertEqual(draft["baseImage"], base)
        self.assertEqual(draft["registration"]["status"], "unresolved")
        self.assertEqual(draft["calibration"]["controlPoints"], [])
        self.assertEqual(draft["registration"]["imageSpace"], "image-pixel")
        self.assertEqual(draft["registration"]["referenceSpace"], "world-plan")
        self.assertEqual(draft["registration"]["previewSpace"], "screen-projected")
        self.assertFalse(draft["navigationAnchors"])
        self.assertFalse(draft["foregroundObjects"])
        self.assertTrue(all(x["widthAuthority"] == "editor_placeholder_not_art" for x in draft["doorPlacements"]))
        self.assertEqual(len(draft["roomRegions"]), 8)
        self.assertEqual(len(draft["doorPlacements"]), 11)
        validate_first_floor(adapt_art_manifest(ART, WORLD), WORLD)

    def test_direct_art_manifest_cli_creates_native_pixel_image_not_false_plan_overlay(self):
        with tempfile.TemporaryDirectory() as folder:
            output = Path(folder)
            scene, metrics = scene_from_project(ART, output)
            text = scene.read_text("utf-8")
            base = measured_source(ART)
            self.assertEqual(scene.name, "RM_FIRST_FLOOR_DRAFT_v2.tscn")
            self.assertEqual((metrics["rooms"], metrics["doors"], metrics["anchors"]), (8, 11, 0))
            self.assertIn('metadata/registration_status = "UNREGISTERED_IMAGE_PIXEL"', text)
            self.assertIn("res://a_detailed_top_down_isometric_game_map_illustratio.png", text)
            self.assertIn(f"offset_right = {base['pixelSize'][0]:.4f}", text)
            self.assertIn(f"offset_bottom = {base['pixelSize'][1]:.4f}", text)
            self.assertIn("visible = false", text)
            self.assertNotIn("StaticBody2D", text)
            self.assertNotIn("NavigationRegion2D", text)
            self.assertNotIn("CollisionShape2D", text)
            manifest = json.loads(Path(metrics["manifest"]).read_text("utf-8"))
            self.assertEqual(manifest["source"]["producerManifest"], ART)
            self.assertEqual(manifest["coordinateSpaces"]["baseImage"], "image-pixel")
            self.assertEqual(manifest["coordinateSpaces"]["doorPlacements"], "world-plan")
            self.assertEqual(manifest["coordinateSpaces"]["screenProjectedToNavigation"], "FORBIDDEN")
            original = (scene.read_bytes(), Path(metrics["manifest"]).read_bytes())
            scene2, metrics2 = scene_from_project(ART, output)
            self.assertEqual(metrics, metrics2)
            self.assertEqual(original, (scene2.read_bytes(), Path(metrics["manifest"]).read_bytes()))
            self.assertEqual(list((output / "assets/raven/generated").glob("**/*.png")), [])

    def test_missing_png_and_wrong_binary_identity_fail(self):
        bad = copy.deepcopy(ART)
        bad["source"]["path"] = "assets/raven/map/does-not-exist.png"
        with self.assertRaisesRegex(ValueError, "Missing asset"):
            adapt_art_manifest(bad, WORLD)
        bad = copy.deepcopy(ART)
        bad["source"]["sha256"] = "0" * 64
        with self.assertRaisesRegex(ValueError, "SHA256"):
            adapt_art_manifest(bad, WORLD)
        bad = copy.deepcopy(ART)
        bad["source"]["dimensionsPx"] = [2, 3]
        with self.assertRaisesRegex(ValueError, "dimensionsPx"):
            adapt_art_manifest(bad, WORLD)
        bad = copy.deepcopy(ART)
        bad["source"]["gitBlobSha"] = "f" * 40
        with self.assertRaisesRegex(ValueError, "gitBlobSha"):
            adapt_art_manifest(bad, WORLD)

    def test_incompatible_contract_and_duplicate_ids_fail(self):
        bad = copy.deepcopy(ART)
        bad["schemaVersion"] = 2
        with self.assertRaisesRegex(ValueError, "schemaVersion"):
            adapt_art_manifest(bad, WORLD)
        bad = copy.deepcopy(ART)
        bad["rooms"].append(copy.deepcopy(bad["rooms"][0]))
        with self.assertRaisesRegex(ValueError, "duplicate ID"):
            adapt_art_manifest(bad, WORLD)
        bad = copy.deepcopy(ART)
        bad["coordinateSystems"]["worldPlanToSourcePixel"]["matrix"] = [[1, 0], [0, 1]]
        with self.assertRaisesRegex(ValueError, "mapping not unresolved"):
            adapt_art_manifest(bad, WORLD)

    def test_door_pair_and_point_mismatch_fail(self):
        bad = copy.deepcopy(ART)
        bad["doors"][0]["roomIds"][0] = "RM-ROOM-KITCHEN"
        with self.assertRaisesRegex(ValueError, "door reference mismatch"):
            adapt_art_manifest(bad, WORLD)
        bad = copy.deepcopy(ART)
        bad["doors"][0]["referenceWorldPlanPoint"] = [999, 999]
        with self.assertRaisesRegex(ValueError, "door reference mismatch"):
            adapt_art_manifest(bad, WORLD)
        bad = copy.deepcopy(ART)
        bad["navigationReferenceAnchors"][0]["referenceSpace"] = "world-plan"
        with self.assertRaisesRegex(ValueError, "unreviewed greybox"):
            adapt_art_manifest(bad, WORLD)

    def test_no_synthetic_raster_control_points_or_foreground(self):
        wrapped = adapt_art_manifest(ART, WORLD)
        bad = copy.deepcopy(wrapped)
        bad["firstFloorDraft"]["calibration"]["controlPoints"] = [
            {"pixel": [0, 0], "world": [0, 0]}, {"pixel": [1, 1], "world": [10, 10]}
        ]
        with self.assertRaisesRegex(ValueError, "must not declare calibration"):
            validate_first_floor(bad, WORLD)
        bad = copy.deepcopy(wrapped)
        bad["firstFloorDraft"]["navigationAnchors"] = [
            {"id": "RM-NAV-HALL-UNAUTH", "roomId": "RM-ROOM-HALL", "point": [850, 500]}
        ]
        with self.assertRaisesRegex(ValueError, "cannot claim world-plan navigation"):
            validate_first_floor(bad, WORLD)


if __name__ == "__main__":
    unittest.main()
