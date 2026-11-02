"""VNS5-06D2B: locked source-diff staging, exact approvals and rollback safety."""
import copy
import json
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))
from scripts.raven.tools import stage_vn_release_patch as locked  # noqa: E402
from scripts.raven.tools import prepare_vn_promotion as d1  # noqa: E402
from scripts.raven.tools import plan_vn_release as d2a  # noqa: E402
from test_vns5_release_readiness import ReleaseReadinessTest  # noqa: E402


class LockedReleaseStagingTest(unittest.TestCase):
    def setUp(self):
        fixture = ReleaseReadinessTest()
        fixture.setUp()
        self.addCleanup(fixture.doCleanups)
        self.fixture = fixture
        self.base = fixture.folder
        self.audit = self.base / "d2a_audit"
        self.report = fixture.verify()
        d2a.write_audit_once(self.audit, self.report)
        self.bundle = fixture.bundle
        self.package = fixture.package
        self.staging = fixture.staging
        self.decision_file = self.base / "review-decision.json"
        self.decision = {
            "format": locked.FORMAT, "schemaVersion": 1,
            "releaseMode": locked.LOCKED,
            "packageSha256": locked._digest(self.package.read_bytes()),
            "auditReportSha256": locked._digest(
                (self.audit / "release_readiness_report.json").read_bytes()),
            "reviewRef": self.bundle["reviewRef"],
            "storyReviewRef": "TEST-STORY-NOT-APPROVAL",
            "artReviewRef": "TEST-ART-NOT-APPROVAL",
            "localizationReviewRef": "TEST-LOCALE-NOT-APPROVAL",
            "saveReviewRef": "TEST-SAVE-NOT-APPROVAL",
            "acceptedSceneIds": sorted(self.bundle["sceneIdMap"].values()),
            "acceptedLineIds": sorted(self.bundle["lineIdMap"].values()),
            "acceptedRouteProposals": copy.deepcopy(self.bundle["routeProposals"]),
            "unresolvedBlockers": self.report["blockers"].copy(),
            "enableRuntime": False, "applyToRepo": False
        }
        self.write_decision()
        self.old_sources = {name: locked._digest(p.read_bytes())
                            for name, p in d2a.ROLLBACK_SOURCES.items()}

    def write_decision(self):
        self.decision_file.write_text(json.dumps(self.decision, ensure_ascii=False),
                                      encoding="utf-8")

    def verify(self):
        return locked.stage(self.package, self.staging, self.audit, self.decision_file)

    def block(self, message: str):
        self.write_decision()
        with self.assertRaisesRegex(d1.BundleError, message):
            self.verify()

    def test_positive_locked_candidate_and_exact_rollback(self):
        content = self.verify()
        self.assertEqual(content["manifest"]["format"], locked.OUTPUT_FORMAT)
        self.assertFalse(content["manifest"]["readyForRuntime"])
        self.assertFalse(content["manifest"]["runtimeApplied"])
        self.assertFalse(content["manifest"]["canMergeToProduction"])
        self.assertEqual(content["manifest"]["unresolvedBlockers"], self.report["blockers"])
        story = json.loads(content["staged"]["foundation_catalog.json"])
        source = json.loads(content["rollback"]["foundation_catalog.json"])
        self.assertEqual(story["storyBeats"],
                         source["storyBeats"] + [self.fixture.fixture.scene_id])
        self.assertEqual(story["schemaVersion"], 1)
        self.assertEqual(len(content["staged"]), 5)
        self.assertEqual(len(content["rollback"]), 7)
        route = json.loads(content["staged"][d1.FILES["routes"]])["sceneTriggers"][-1]
        self.assertEqual(route["gate"]["kind"], "draft_unapproved")
        self.assertFalse(route["gate"]["approvedRuntime"])
        out = self.base / "release-candidate"
        locked.write_once(out, content, [self.staging, self.audit,
                                         self.package, self.decision_file])
        self.assertEqual(set(p.name for p in out.iterdir()),
                         {"candidate", "rollback", "locked_release_patch_manifest.json"})
        manifest = json.loads((out / "locked_release_patch_manifest.json").read_text())
        self.assertEqual(manifest["sourceGodotPackageSha256"],
                         locked._digest(self.package.read_bytes()))
        self.assertEqual(set(p.name for p in (out / "candidate").iterdir()),
                         set(locked.STAGED_NAMES))
        self.assertEqual(set(p.name for p in (out / "rollback").iterdir()),
                         set(locked.BACKUP_NAMES))
        for name, sha in self.old_sources.items():
            self.assertEqual(locked._digest(d2a.ROLLBACK_SOURCES[name].read_bytes()), sha)
        with self.assertRaisesRegex(d1.BundleError, "already exists"):
            locked.write_once(out, content, [self.staging, self.audit,
                                             self.package, self.decision_file])

    def test_cli_check_only_and_export(self):
        self.assertEqual(locked.main(["--package", str(self.package),
                                      "--staging", str(self.staging),
                                      "--audit", str(self.audit),
                                      "--decision", str(self.decision_file),
                                      "--check-only"]), 0)
        folder = self.base / "cli-stage"
        self.assertFalse(folder.exists())
        self.assertEqual(locked.main(["--package", str(self.package),
                                      "--staging", str(self.staging),
                                      "--audit", str(self.audit),
                                      "--decision", str(self.decision_file),
                                      "--output", str(folder)]), 0)
        self.assertTrue((folder / "candidate" / "foundation_catalog.json").exists())
        self.assertEqual(locked.main(["--package", str(self.package),
                                      "--staging", str(self.staging),
                                      "--audit", str(self.audit),
                                      "--decision", str(self.decision_file),
                                      "--output", str(folder)]), 2)

    def test_reject_missing_or_fake_decision_approval(self):
        self.decision["format"] = "arbitrary"
        self.block("Unsupported release review decision")
        self.decision["format"] = locked.FORMAT
        self.decision["enableRuntime"] = True
        self.block("Runtime activation")
        self.decision["enableRuntime"] = False
        self.decision["applyToRepo"] = True
        self.block("Runtime activation")
        self.decision["applyToRepo"] = False
        self.decision["storyReviewRef"] = ""
        self.block("storyReviewRef")
        self.decision["storyReviewRef"] = "SYNTHETIC"
        self.decision["unrelatedScript"] = "res://evil.gd"
        self.block("missing/foreign fields")

    def test_reject_unknown_scene_line_and_proposed_route_change(self):
        self.decision["acceptedSceneIds"] = []
        self.block("all and only")
        self.decision["acceptedSceneIds"] = sorted(self.bundle["sceneIdMap"].values())
        self.decision["acceptedLineIds"] = ["RM-BEAT-XX-01"]
        self.block("all and only")
        self.decision["acceptedLineIds"] = sorted(self.bundle["lineIdMap"].values())
        self.decision["acceptedRouteProposals"][self.fixture.fixture.scene_id]["ref"] = "RM-BEAT-999"
        self.block("Route decisions")
        self.decision["acceptedRouteProposals"] = self.bundle["routeProposals"].copy()
        self.decision["unresolvedBlockers"] = []
        self.block("Every D2A release blocker")

    def test_reject_package_and_audit_hash_tamper(self):
        self.decision["packageSha256"] = "a" * 64
        self.block("exact bytes")
        self.decision["packageSha256"] = locked._digest(self.package.read_bytes())
        self.decision["auditReportSha256"] = "b" * 64
        self.block("exact bytes")

    def test_reject_missing_rollback_or_changed_baseline(self):
        source = self.audit / "rollback" / "foundation_catalog.json"
        source.write_text(source.read_text() + " ", encoding="utf-8")
        with self.assertRaisesRegex(d1.BundleError, "checksum mismatch"):
            self.verify()
        source.write_bytes((ROOT / "data/raven/foundation_catalog.json").read_bytes())
        backup = self.audit / "rollback" / "save_contract.json"
        backup.unlink()
        with self.assertRaisesRegex(d1.BundleError, "rollback must contain"):
            self.verify()

    def test_reject_stale_audit_or_unexpected_artifact(self):
        report_file = self.audit / "release_readiness_report.json"
        data = json.loads(report_file.read_text())
        data["readyForRuntime"] = True
        report_file.write_text(json.dumps(data))
        with self.assertRaisesRegex(d1.BundleError, "stale, modified"):
            self.verify()
        report_file.write_text(json.dumps(self.report, ensure_ascii=False, indent=2) + "\n")
        (self.audit / "unexpected.json").write_text("{}")
        with self.assertRaisesRegex(d1.BundleError, "Unexpected or missing D2A"):
            self.verify()

    def test_guard_external_destination_and_sources_unchanged(self):
        content = self.verify()
        with self.assertRaisesRegex(d1.BundleError, "overlaps repository"):
            locked.write_once(ROOT / "not-safe", content,
                              [self.staging, self.audit, self.package, self.decision_file])
        with self.assertRaisesRegex(d1.BundleError, "overlaps repository"):
            locked.write_once(self.staging / "nested-output", content,
                              [self.staging, self.audit, self.package, self.decision_file])
        self.assertFalse((ROOT / "not-safe").exists())
        for name, sha in self.old_sources.items():
            self.assertEqual(locked._digest(d2a.ROLLBACK_SOURCES[name].read_bytes()), sha)


if __name__ == "__main__":
    unittest.main()
