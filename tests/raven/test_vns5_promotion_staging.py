"""VNS5-06D: no-apply candidate staging, approval manifest and negative tests."""
import copy
import json
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))
from scripts.raven.tools import prepare_vn_promotion as stage  # noqa: E402


class PromotionStagingTest(unittest.TestCase):
    def setUp(self):
        self.sources = {key: stage.json_file(stage.DATA / name)
                        for key, name in stage.FILES.items()}
        self.source_sha = {name: stage.digest((stage.DATA / name).read_bytes())
                           for name in stage.FILES.values()}
        self.raw_id = "RM-DRAFT-BEAT-0001"
        self.target = "RM-BEAT-07-01"
        self.source_line_id = self.raw_id + "-L001"
        self.line_id = self.target + "-L001"
        author_scene = {
            "sceneId": self.raw_id,
            "title": {"ru": "Новая глава", "be": None, "en": None},
            "status": "draft_not_runtime"
        }
        author_line = {
            "id": self.source_line_id, "sceneId": self.raw_id,
            "speakerId": "RM-CHAR-EVELYN", "delivery": "speech",
            "source": "vn_studio_draft_not_runtime",
            "localized": {"ru": {"text": "Начало следующей главы."}, "be": None, "en": None}
        }
        added_scene = copy.deepcopy(author_scene)
        added_scene["sceneId"] = self.target
        added_scene["status"] = "proposed_future_runtime"
        added_scene["source"] = "vn_studio_promotion_review_only"
        added_line = copy.deepcopy(author_line)
        added_line["id"] = self.line_id
        added_line["sceneId"] = self.target
        added_line["source"] = "vn_studio_promotion_review_only"
        catalog = copy.deepcopy(self.sources["catalog"])
        catalog["scenes"].append(added_scene)
        catalog["entries"].append(added_line)
        catalog["status"] = "DRAFT_PROMOTION_REVIEW_NOT_RUNTIME"
        self.review = {
            "format": "raven-vn-promotion-review-v1", "schemaVersion": 1,
            "sourceSha256": self.source_sha[stage.FILES["catalog"]],
            "stageSourceSha256": self.source_sha[stage.FILES["staging"]],
            "routeSourceSha256": self.source_sha[stage.FILES["routes"]],
            "castSourceSha256": self.source_sha[stage.FILES["cast"]],
            "reviewCatalog": catalog,
            "idMap": {self.raw_id: self.target},
            "lineIdMap": {self.source_line_id: self.line_id},
            "reviewGraphPatches": {},
            "retainedDraft": {
                "authoredScenes": [author_scene],
                "authoredLines": [author_line],
                "promotionSceneIdMap": {self.raw_id: self.target},
                "storyGraphPatches": {}, "textPatches": {},
                "stagePatches": {}, "stageV2Patches": {}, "stageFxPatches": {}
            },
            "runtimeApplied": False, "readyForRuntime": False,
            "requiresHumanReview": True, "requiresFollowUpPromotion": True
        }
        shot = copy.deepcopy(self.sources["staging"]["sceneShots"][0])
        shot["sceneId"] = self.target
        trigger = copy.deepcopy(self.sources["routes"]["sceneTriggers"][1])
        trigger["sceneId"] = self.target
        trigger["ordinal"] = max(x["ordinal"] for x in self.sources["routes"]["sceneTriggers"]) + 1
        trigger["gate"]["kind"] = "scene_complete"
        trigger["gate"]["ref"] = self.sources["catalog"]["scenes"][0]["sceneId"]
        trigger["gate"]["approvedRuntime"] = False
        trigger["gate"]["proposedRuntime"] = True
        cue = copy.deepcopy(self.sources["cues"]["cues"][0])
        cue["lineId"] = self.line_id
        cue["sceneId"] = self.target
        self.approval = {
            "format": "raven-vn-release-preflight-v1", "schemaVersion": 1,
            "approvalRef": "STORY-REVIEW-001", "artApprovalRef": "ART-REVIEW-001",
            "storyApprovalRef": "STORY-REVIEW-001", "cueApprovalRef": "CUE-REVIEW-001",
            "reviewSha256": "", "cueSourceSha256": self.source_sha[stage.FILES["cues"]],
            "approvedTextLineIds": [],
            "saveReview": {"existingSaves": "preserve", "newScenesDefault": "locked",
                           "reviewRef": "SAVE-CONTRACT-001"},
            "sceneShots": [shot], "sceneTriggers": [trigger], "lineCues": [cue]
        }
        self.refresh_sha()

    def refresh_sha(self):
        self.raw = (json.dumps(self.review, ensure_ascii=False, indent=2) + "\n").encode()
        self.approval["reviewSha256"] = stage.digest(self.raw)

    def build(self):
        return stage.build(self.review, self.approval, review_sha=stage.digest(self.raw))

    def assert_blocked(self, message):
        self.refresh_sha()
        with self.assertRaisesRegex(stage.PromotionError, message):
            self.build()

    def test_positive_staging_and_no_canonical_mutation(self):
        output = self.build()
        self.assertEqual(len(output), 5)
        catalog = json.loads(output[stage.FILES["catalog"]])
        staging = json.loads(output[stage.FILES["staging"]])
        routes = json.loads(output[stage.FILES["routes"]])
        cues = json.loads(output[stage.FILES["cues"]])
        manifest = json.loads(output["promotion_manifest.json"])
        self.assertEqual(len(catalog["scenes"]), 29)
        self.assertEqual(len(catalog["entries"]), 281)
        self.assertEqual(len(staging["sceneShots"]), 29)
        self.assertEqual(len(routes["sceneTriggers"]), 29)
        self.assertEqual(len(cues["cues"]), 281)
        self.assertFalse(manifest["runtimeApplied"])
        self.assertFalse(manifest["readyForRuntime"])
        self.assertTrue(manifest["cannotAutoApply"])
        for name, bytes_data in output.items():
            self.assertEqual(manifest["candidateSha256"].get(name, stage.digest(bytes_data)),
                             stage.digest(bytes_data))
        with tempfile.TemporaryDirectory() as tmp:
            outdir = Path(tmp) / "package"
            stage.write_once(outdir, output)
            self.assertEqual((outdir / stage.FILES["catalog"]).read_bytes(),
                             output[stage.FILES["catalog"]])
            with self.assertRaisesRegex(stage.PromotionError, "exists"):
                stage.write_once(outdir, output)
        for name, sha in self.source_sha.items():
            self.assertEqual(sha, stage.digest((stage.DATA / name).read_bytes()),
                             "Canonical production file was mutated: " + name)

    def test_cli_check_only_and_export(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            review = root / "review.json"
            approval = root / "approval.json"
            review.write_bytes(self.raw)
            approval.write_text(json.dumps(self.approval, ensure_ascii=False), encoding="utf-8")
            self.assertEqual(stage.main(["--review", str(review), "--approval", str(approval),
                                         "--check-only"]), 0)
            out = root / "stage"
            self.assertEqual(stage.main(["--review", str(review), "--approval", str(approval),
                                         "--output", str(out)]), 0)
            self.assertEqual(stage.main(["--review", str(review), "--approval", str(approval),
                                         "--output", str(out)]), 2)

    def test_changed_source_rejected(self):
        self.review["sourceSha256"] = "bad"
        self.assert_blocked("SHA mismatch")
        self.review["sourceSha256"] = self.source_sha[stage.FILES["catalog"]]
        self.approval["cueSourceSha256"] = "drift"
        self.assert_blocked("Line cue file changed")

    def test_unapproved_runtime_and_graph_rejected(self):
        self.review["readyForRuntime"] = True
        self.assert_blocked("must not claim runtime")
        self.review["readyForRuntime"] = False
        self.review["reviewGraphPatches"] = {"RM-BEAT-00-01": {
            "sceneId": "RM-BEAT-00-01", "edges": [{"kind": "choice", "targetId": self.target}]}}
        self.assert_blocked("Playable Story Map branches")

    def test_corrupted_identity_and_text_rejected(self):
        self.review["idMap"][self.raw_id] = self.sources["catalog"]["scenes"][0]["sceneId"]
        self.assert_blocked("collide")
        self.review["idMap"][self.raw_id] = self.target
        self.review["reviewCatalog"]["entries"][0]["localized"]["ru"]["text"] = "Changed without approval"
        self.assert_blocked("Unapproved modification")
        self.approval["approvedTextLineIds"].append(
            self.sources["catalog"]["entries"][0]["id"])
        self.refresh_sha()
        self.assertIsInstance(self.build(), dict)

    def test_gates_must_be_complete(self):
        self.approval["sceneShots"] = []
        self.assert_blocked("requires exactly one reviewed shot")
        self.approval["sceneShots"] = [{
            **self.sources["staging"]["sceneShots"][0], "sceneId": self.target,
            "backgroundId": "BG-NOT-AVAILABLE"}]
        self.assert_blocked("Unknown background")

    def test_unreviewed_route_and_cue_rejected(self):
        self.approval["sceneTriggers"][0]["gate"]["approvedRuntime"] = True
        self.assert_blocked("Only non-runtime")
        self.approval["sceneTriggers"][0]["gate"]["approvedRuntime"] = False
        self.approval["lineCues"][0]["poseId"] = "unapproved-pose"
        self.assert_blocked("Invalid cue pose/emotion")
        self.approval["lineCues"] = []
        self.assert_blocked("requires one reviewed cue")

    def test_save_review_and_approval_bound_to_input(self):
        self.approval["saveReview"]["existingSaves"] = "discard"
        self.assert_blocked("save compatibility")
        self.approval["saveReview"]["existingSaves"] = "preserve"
        self.approval["approvalRef"] = ""
        self.assert_blocked("Missing review reference")
        self.approval["approvalRef"] = "STORY-REVIEW-001"
        self.approval["reviewSha256"] = "bad-sha"
        with self.assertRaisesRegex(stage.PromotionError, "exact input-file SHA"):
            self.build()


if __name__ == "__main__":
    unittest.main()
