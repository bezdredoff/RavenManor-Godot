"""Real cross-agent contract checks against merged B importer on the approved raster.

These checks intentionally do not assert playable geometry.
"""
import copy
import json
import unittest
from pathlib import Path

from scripts.raven.tools.first_floor_art_adapter import adapt_art_manifest
from scripts.raven.tools.import_first_floor_draft import validate_first_floor

ROOT = Path(__file__).resolve().parents[4]
MANIFEST_PATH = ROOT / "assets/raven/map/first_floor_manifest.v1.json"


class FirstFloorCrossAgentContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.manifest = json.loads(MANIFEST_PATH.read_text("utf-8"))

    def test_a_v1_directly_adapts_to_b_v2_and_validates(self):
        output = adapt_art_manifest(self.manifest)
        self.assertEqual(output["schemaVersion"], 1)
        draft = output["firstFloorDraft"]
        self.assertEqual(draft["schemaVersion"], 2)
        self.assertEqual(draft["kind"], "raven-first-floor-draft")
        self.assertEqual(draft["baseImage"]["pixelSize"], [1672, 941])
        self.assertEqual(draft["baseImage"]["sha256"], self.manifest["source"]["sha256"])
        self.assertEqual(draft["baseImage"]["gitBlobSha"], self.manifest["source"]["gitBlobSha"])
        self.assertEqual(draft["registration"]["status"], "unresolved")
        self.assertIsNone(draft["registration"]["pixelToWorld"])
        self.assertFalse(draft["registration"]["navigationAllowed"])
        self.assertEqual(draft["calibration"]["controlPoints"], [])
        self.assertEqual(len(draft["roomRegions"]), 8)
        self.assertTrue(all(r["referenceOnly"] and r["coordinateSpace"] == "world-plan"
                            for r in draft["roomRegions"]))
        self.assertEqual(len(draft["doorPlacements"]), 11)
        self.assertTrue(all(d["widthAuthority"] == "editor_placeholder_not_art"
                            for d in draft["doorPlacements"]))
        self.assertEqual(draft["foregroundObjects"], [])
        self.assertEqual(draft["navigationAnchors"], [])
        self.assertEqual(draft["producerManifest"], self.manifest)
        # The actual merged B v2 importer validator must accept the converted project.
        resolved, png_bytes, report = validate_first_floor(output)
        self.assertEqual(resolved["baseImage"]["pixelSize"], [1672, 941])
        self.assertEqual(len(png_bytes), 3_126_732)

    def test_all_unapproved_observations_stay_out_of_b_registration(self):
        source = self.manifest
        self.assertEqual([d["sourcePixelPoint"] for d in source["doors"]], [None] * 11)
        self.assertEqual([r["sourcePixelPolygon"] for r in source["rooms"]], [None] * 8)
        self.assertEqual([a["calibratedWorldPlanPoint"] for a in source["navigationReferenceAnchors"]],
                         [None] * 13)
        self.assertEqual([a["sourcePixelFootpoint"] for a in source["navigationReferenceAnchors"]],
                         [None] * 13)
        self.assertFalse(source["productionReady"])
        self.assertFalse(source["integrationAllowed"])
        self.assertEqual(source["pixelLandmarkCandidates"][0]["imagePixelEstimate"], [833, 801])

    def test_b_rejects_promoting_visual_only_pixels_to_door(self):
        modified = copy.deepcopy(self.manifest)
        modified["doors"][0]["sourcePixelPoint"] = [833, 801]
        with self.assertRaisesRegex(ValueError, "unreviewed source pixel door"):
            adapt_art_manifest(modified)

    def test_b_rejects_source_fingerprint_drift(self):
        modified = copy.deepcopy(self.manifest)
        modified["source"]["sha256"] = "0" * 64
        with self.assertRaisesRegex(ValueError, "SHA256 mismatched"):
            adapt_art_manifest(modified)


if __name__ == "__main__":
    unittest.main()
