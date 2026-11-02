"""Companion offline check of native Godot VNS5-06D1 review bundles."""
import copy
import json
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))
from scripts.raven.tools import prepare_vn_promotion as stage  # noqa: E402


class OfflineGodotBundleTests(unittest.TestCase):
    def setUp(self):
        self.source = {key: stage.load(stage.BASE / name) for key, name in stage.FILES.items()}
        self.original_sha = {key: stage.digest((stage.BASE / name).read_bytes())
                             for key, name in stage.FILES.items()}
        self.draft_id = "RM-DRAFT-BEAT-0001"
        self.scene_id = "RM-BEAT-07-01"
        self.draft_line_id = self.draft_id + "-L001"
        self.line_id = self.scene_id + "-L001"
        self.author_scene = {
            "sceneId": self.draft_id,
            "title": {"ru": "Проверочная сцена", "be": None, "en": None},
            "status": "draft_not_runtime"
        }
        self.author_line = {
            "id": self.draft_line_id, "sceneId": self.draft_id,
            "speakerId": "RM-CHAR-EVELYN", "delivery": "speech",
            "source": "vn_studio_draft_not_runtime",
            "localized": {"ru": {"text": "Новый диалог."}, "be": None, "en": None}
        }
        scene = copy.deepcopy(self.author_scene)
        scene.update(sceneId=self.scene_id, status="review_only_not_runtime",
                     source="vn_studio_promotion_review_only")
        line = copy.deepcopy(self.author_line)
        line.update(id=self.line_id, sceneId=self.scene_id,
                    source="vn_studio_promotion_review_only")
        files = {stage.FILES[k]: copy.deepcopy(self.source[k])
                 for k in ("catalog", "staging", "routes", "cues")}
        for item in files.values():
            item["status"] = "DRAFT_REVIEW_NOT_RUNTIME"
        files[stage.FILES["catalog"]]["scenes"].append(scene)
        files[stage.FILES["catalog"]]["entries"].append(line)
        sample_shot = copy.deepcopy(self.source["staging"]["sceneShots"][0])
        sample_shot.update(sceneId=self.scene_id)
        files[stage.FILES["staging"]]["sceneShots"].append(sample_shot)
        sample_route = copy.deepcopy(self.source["routes"]["sceneTriggers"][0])
        sample_route.update(sceneId=self.scene_id,
                            ordinal=len(self.source["catalog"]["scenes"]),
                            interactionTarget="review_only_not_playable",
                            notes="Review proposal only")
        sample_route["gate"] = {
            "kind": "draft_unapproved", "ref": "none",
            "approvedRuntime": False, "proposedRuntime": True
        }
        files[stage.FILES["routes"]]["sceneTriggers"].append(sample_route)
        cue = copy.deepcopy(self.source["cues"]["cues"][0])
        cue.update(lineId=self.line_id, sceneId=self.scene_id,
                   speakerId="RM-CHAR-EVELYN", manualReview=True)
        files[stage.FILES["cues"]]["cues"].append(cue)
        self.bundle = {
            "format": stage.PACKAGE_FORMAT, "schemaVersion": 1,
            "reviewRef": "RM-SYNTHETIC-REVIEW-NOT-APPROVAL",
            "sourceSha256": self.original_sha["catalog"],
            "stageSourceSha256": self.original_sha["staging"],
            "routeSourceSha256": self.original_sha["routes"],
            "castSourceSha256": self.original_sha["cast"],
            "cueSourceSha256": self.original_sha["cues"],
            "sceneIdMap": {self.draft_id: self.scene_id},
            "lineIdMap": {self.draft_line_id: self.line_id},
            "routeProposals": {self.scene_id: {
                "kind": "scene_complete",
                "ref": self.source["catalog"]["scenes"][0]["sceneId"],
                "interactionTarget": "review-placeholder"}},
            "files": files,
            "retainedDraft": {
                "authoredScenes": [self.author_scene],
                "authoredLines": [self.author_line],
                "storyGraphPatches": {}, "textPatches": {},
                "stagePatches": {}, "stageV2Patches": {}, "stageFxPatches": {},
                "promotionSceneIdMap": {self.draft_id: self.scene_id}},
            "releaseBlockers": [
                "Review-only route is not gameplay",
                "Needs release owner approval",
                "Requires save migration and branch runtime parity"
            ],
            "runtimeApplied": False, "readyForRuntime": False,
            "requiresHumanReview": True, "requiresFollowUpPromotion": True
        }

    def verify(self):
        return stage.verify(self.bundle, package_sha="0" * 64)

    def blocked(self, pattern):
        with self.assertRaisesRegex(stage.BundleError, pattern):
            self.verify()

    def test_positive_exact_native_schema_and_source_immutability(self):
        files = self.verify()
        self.assertEqual(set(files), set(stage.CANDIDATE_NAMES) |
                         {"offline_integrity_manifest.json"})
        manifest = json.loads(files["offline_integrity_manifest.json"])
        self.assertFalse(manifest["readyForRuntime"])
        self.assertFalse(manifest["runtimeApplied"])
        self.assertTrue(manifest["cannotAutoApply"])
        self.assertEqual(manifest["sceneCount"], 29)
        self.assertEqual(manifest["lineCount"], 281)
        self.assertEqual(manifest["sourcePackageSha256"], "0" * 64)
        self.assertEqual(set(manifest["candidateSha256"]), set(stage.CANDIDATE_NAMES))
        with tempfile.TemporaryDirectory() as tmp:
            dest = Path(tmp) / "candidate"
            stage.write_once(dest, files)
            self.assertTrue((dest / stage.FILES["routes"]).is_file())
            self.assertEqual(json.loads((dest / stage.FILES["catalog"]).read_text())
                             ["scenes"][-1]["sceneId"], self.scene_id)
            with self.assertRaisesRegex(stage.BundleError, "already exists"):
                stage.write_once(dest, files)
        for kind, name in stage.FILES.items():
            self.assertEqual(self.original_sha[kind], stage.digest((stage.BASE / name).read_bytes()),
                             "Canonical source mutated: " + name)

    def test_offline_cli_check_only_and_immutable_export(self):
        with tempfile.TemporaryDirectory() as tmp:
            src = Path(tmp) / "godot-review.json"
            src.write_text(json.dumps(self.bundle, ensure_ascii=False), encoding="utf-8")
            self.assertEqual(stage.main(["--package", str(src), "--check-only"]), 0)
            self.assertFalse((Path(tmp) / "output").exists())
            target = Path(tmp) / "output"
            self.assertEqual(stage.main(["--package", str(src), "--output", str(target)]), 0)
            self.assertEqual(stage.main(["--package", str(src), "--output", str(target)]), 2)

    def test_source_and_review_sha_tampering(self):
        self.bundle["cueSourceSha256"] = "bad"
        self.blocked("cue.*SHA drift")
        self.bundle["cueSourceSha256"] = self.original_sha["cues"]
        with self.assertRaisesRegex(stage.BundleError, "byte SHA"):
            stage.verify(self.bundle, package_sha=None)

    def test_staging_route_and_cue_must_remain_review_only(self):
        self.bundle["files"][stage.FILES["routes"]]["sceneTriggers"][-1]["gate"]["approvedRuntime"] = True
        self.blocked("Runtime route is forbidden")
        self.bundle["files"][stage.FILES["routes"]]["sceneTriggers"][-1]["gate"]["approvedRuntime"] = False
        self.bundle["files"][stage.FILES["cues"]]["cues"][-1]["manualReview"] = False
        self.blocked("Cue status")
        self.bundle["files"][stage.FILES["cues"]]["cues"][-1]["manualReview"] = True
        self.bundle["readyForRuntime"] = True
        self.blocked("non-runtime review")

    def test_reject_missing_registries_unknown_assets_and_id_collision(self):
        self.bundle["files"][stage.FILES["staging"]]["sceneShots"].pop()
        self.blocked("Scene, shot and route")
        self.bundle["files"][stage.FILES["staging"]]["sceneShots"].append({
            **copy.deepcopy(self.source["staging"]["sceneShots"][0]),
            "sceneId": self.scene_id, "backgroundId": "BG-UNKNOWN"})
        self.blocked("Invalid master")
        self.bundle["files"][stage.FILES["staging"]]["sceneShots"][-1]["backgroundId"] = (
            self.source["staging"]["sceneShots"][0]["backgroundId"])
        self.bundle["lineIdMap"][self.draft_line_id] = self.source["catalog"]["entries"][0]["id"]
        self.blocked("colliding")

    def test_prevent_existing_source_modifications(self):
        self.bundle["files"][stage.FILES["catalog"]]["scenes"][0]["title"]["ru"] = "changed"
        self.blocked("Canonical scene changed")
        self.bundle["files"][stage.FILES["catalog"]]["scenes"][0] = (
            copy.deepcopy(self.source["catalog"]["scenes"][0]))
        self.bundle["files"][stage.FILES["routes"]]["sceneTriggers"][0]["gate"]["kind"] = "draft_unapproved"
        self.blocked("Canonical route changed")

    def test_reviewed_text_patches_must_match_source(self):
        old = self.source["catalog"]["entries"][0]["id"]
        self.bundle["files"][stage.FILES["catalog"]]["entries"][0]["localized"]["ru"]["text"] = "new"
        self.blocked("Unreviewed canonical line mutation")
        self.bundle["retainedDraft"]["textPatches"][old] = {"ru": "new"}
        self.verify()
        self.bundle["retainedDraft"]["textPatches"][old] = {"en": "different"}
        self.blocked("Unreviewed canonical line mutation")

    def test_registered_new_dialogue_and_graph_runtime_gates(self):
        self.bundle["files"][stage.FILES["catalog"]]["entries"][-1]["speakerId"] = "UNKNOWN"
        self.blocked("New line differs")
        self.bundle["files"][stage.FILES["catalog"]]["entries"][-1]["speakerId"] = "RM-CHAR-EVELYN"
        self.bundle["retainedDraft"]["storyGraphPatches"] = {
            self.draft_id: {"sceneId": self.draft_id,
                            "edges": [{"kind": "choice", "targetId": self.scene_id}]}}
        self.blocked("Playable Story Map branch")

    def test_old_cue_and_unknown_voice_preserved(self):
        # Existing unknown-voice dialogue remains accepted exactly as canonical.
        self.verify()
        self.bundle["files"][stage.FILES["cues"]]["cues"][0]["poseId"] = "bad"
        self.blocked("Canonical cue changed")


if __name__ == "__main__":
    unittest.main()
