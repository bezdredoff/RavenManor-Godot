import unittest
from export_first_floor_contracts import ContractNotReady, builder_v2, navigation_v1, review


def fixture():
    return {
        "productionReady": False, "integrationAllowed": False,
        "source": {"path": "approved.png", "sha256": "a"*64,
                   "dimensionsPx": [200, 100], "metadataStatus": "verified_exact_bytes_on_github_runner"},
        "coordinateSystems": {"worldPlanToSourcePixel": {"status": "unresolved", "controlPoints": []}},
        "rooms": [{"id": "RM-ROOM-HALL", "approvedWorldPlanRect": None}],
        "doors": [{"id": "RM-DOOR-ENTRY-HALL", "roomIds": ["RM-ROOM-HALL", None],
                   "approvedWorldPlanPoint": None, "approvedOpeningWidth": None}],
        "navigationReferenceAnchors": [{"id": "RM-NAV-HALL-SPAWN", "roomId": "RM-ROOM-HALL",
                                        "referenceGreyboxPoint": [400, 300],
                                        "calibratedWorldPlanPoint": None,
                                        "calibratedWorldPlanStatus": "unresolved"}]
    }


class BridgeTests(unittest.TestCase):
    def test_unknown_coordinates_block_b_and_c(self):
        d = fixture()
        self.assertEqual(review(d)["blockedAnchorCount"], 1)
        with self.assertRaises(ContractNotReady):
            builder_v2(d)
        with self.assertRaises(ContractNotReady):
            navigation_v1(d)

    def test_explicit_builder_draft_never_invents_door(self):
        d = fixture()
        pairs = [([0,0],[0,0]), ([200,0],[400,0]), ([0,100],[0,200]), ([200,100],[400,200])]
        d["coordinateSystems"]["worldPlanToSourcePixel"] = {
            "status": "reviewed_for_builder_draft", "builderLinearWorldRect": [0,0,400,200],
            "controlPoints": [{"imagePixel": a, "worldPlan": b, "status": "reviewed"} for a,b in pairs]
        }
        d["rooms"][0]["approvedWorldPlanRect"] = [0,0,400,200]
        v = builder_v2(d)["firstFloorDraft"]
        self.assertEqual(v["schemaVersion"], 2)
        self.assertEqual(v["baseImage"]["pixelSize"], [200,100])
        self.assertEqual(v["doorPlacements"], [])
        self.assertEqual(v["navigationAnchors"], [])
        self.assertFalse(v["provenance"]["productionReady"])
        d["coordinateSystems"]["worldPlanToSourcePixel"]["controlPoints"][3]["worldPlan"]=[390,200]
        with self.assertRaisesRegex(ContractNotReady,"mismatch"):
            builder_v2(d)

    def test_navigation_uses_only_approved_unprojected_anchors(self):
        d=fixture()
        a=d["navigationReferenceAnchors"][0]
        a["calibratedWorldPlanPoint"]=[700,900]
        with self.assertRaises(ContractNotReady):
            navigation_v1(d)
        a["calibratedWorldPlanStatus"]="approved_for_preview"
        v=navigation_v1(d)
        self.assertEqual(v["anchors"][0]["position"],[700.0,900.0])
        self.assertNotEqual(v["anchors"][0]["position"],a["referenceGreyboxPoint"])
        self.assertFalse(v["productionReady"])

    def test_no_production_flag(self):
        d=fixture()
        d["productionReady"]=True
        with self.assertRaises(ContractNotReady):
            review(d)


if __name__ == "__main__":
    unittest.main()
