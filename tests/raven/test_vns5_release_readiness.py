"""VNS5-06D2A: audited no-apply release rehearsal + rollback/fail-closed gates."""
import copy
import json
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))
from scripts.raven.tools import prepare_vn_promotion as stage  # noqa: E402
from scripts.raven.tools import plan_vn_release as release  # noqa: E402
from test_vns5_promotion_staging import OfflineGodotBundleTests  # noqa: E402


class ReleaseReadinessTest(unittest.TestCase):
    def setUp(self):
        self.fixture = OfflineGodotBundleTests()
        self.fixture.setUp()
        self.bundle = copy.deepcopy(self.fixture.bundle)
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.folder = Path(self.tmp.name)
        self.package = self.folder / "godot-review.json"
        self.staging = self.folder / "extracted"
        self.raw = (json.dumps(self.bundle, ensure_ascii=False, indent=2) + "\n").encode()
        self.package.write_bytes(self.raw)
        staged = stage.verify(self.bundle, package_sha=release._sha(self.raw))
        stage.write_once(self.staging, staged)
        self.before = {name: release._sha(path.read_bytes())
                       for name, path in release.ROLLBACK_SOURCES.items()}

    def verify(self):
        return release.audit(self.bundle, self.raw, self.staging)

    def test_report_and_transaction_backup_are_review_only(self):
        audit = self.verify()
        self.assertEqual(audit["format"], release.AUDIT_FORMAT)
        self.assertEqual(audit["status"], "NOT_RELEASE_READY")
        self.assertGreaterEqual(len(audit["blockers"]), 8)
        self.assertFalse(audit["readyForRuntime"])
        self.assertFalse(audit["runtimeApplied"])
        self.assertTrue(audit["saveCompatibility"]["existingSavesRemainUnmodified"])
        self.assertFalse(audit["saveCompatibility"]["oldSaveMigrationVerifiedForRuntime"])
        self.assertIn(self.fixture.scene_id,
                      audit["saveCompatibility"]["newStoryBeatsMissing"])
        self.assertTrue(any("Snapshot.normalize would drop" in z for z in audit["blockers"]))
        self.assertTrue(any("performance cue still manualReview" in z for z in audit["blockers"]))
        self.assertTrue(any("missing EN release translation" in z for z in audit["blockers"]))
        self.assertTrue(any("runtime scene presenter" in z for z in audit["blockers"]))
        self.assertEqual(audit["diffSummary"]["newScenes"], [self.fixture.scene_id])
        self.assertEqual(audit["diffSummary"]["newLines"], [self.fixture.line_id])
        folder = self.folder / "rollback_audit"
        release.write_audit_once(folder, audit)
        report = json.loads((folder / "release_readiness_report.json").read_text())
        self.assertEqual(report["sourceGodotPackageSha256"], release._sha(self.raw))
        self.assertEqual(set(p.name for p in (folder / "rollback").iterdir()), set(self.before))
        for name, sha in self.before.items():
            self.assertEqual(release._sha((folder / "rollback" / name).read_bytes()), sha)
            self.assertEqual(release._sha(release.ROLLBACK_SOURCES[name].read_bytes()), sha)
        with self.assertRaisesRegex(stage.BundleError, "already exists"):
            release.write_audit_once(folder, audit)

    def test_cli_check_and_guard_refuse_premature_release(self):
        self.assertEqual(release.main(["--package", str(self.package),
                                       "--staging", str(self.staging),
                                       "--check-only"]), 0)
        self.assertEqual(release.main(["--package", str(self.package),
                                       "--staging", str(self.staging),
                                       "--require-ready", "--check-only"]), 2)
        target = self.folder / "audited"
        self.assertEqual(release.main(["--package", str(self.package),
                                       "--staging", str(self.staging),
                                       "--output", str(target)]), 0)
        self.assertTrue((target / "release_readiness_report.json").exists())
        self.assertEqual(release.main(["--package", str(self.package),
                                       "--staging", str(self.staging),
                                       "--output", str(target)]), 2)

    def test_reject_manipulation_of_extracted_files(self):
        file_path = self.staging / stage.FILES["routes"]
        content = file_path.read_text(encoding="utf-8")
        file_path.write_text(content + " ", encoding="utf-8")
        with self.assertRaisesRegex(stage.BundleError, "changed after integrity"):
            self.verify()

    def test_reject_manifest_corruption(self):
        manifest_path = self.staging / "offline_integrity_manifest.json"
        manifest = json.loads(manifest_path.read_text())
        manifest["sourcePackageSha256"] = "0" * 64
        manifest_path.write_text(json.dumps(manifest))
        with self.assertRaisesRegex(stage.BundleError, "exact Godot bundle"):
            self.verify()

    def test_reject_package_drift_and_symlink(self):
        self.bundle["sourceSha256"] = "f" * 64
        with self.assertRaisesRegex(stage.BundleError, "catalog source SHA drift"):
            self.verify()
        self.bundle["sourceSha256"] = self.fixture.original_sha["catalog"]
        link = self.folder / "linked-review.json"
        link.symlink_to(self.package)
        self.assertEqual(release.main(["--package", str(link),
                                       "--staging", str(self.staging),
                                       "--check-only"]), 2)

    def test_refuse_outside_staging_file_and_unsafe_output(self):
        (self.staging / "untrusted.py").write_text("don't execute", encoding="utf-8")
        with self.assertRaisesRegex(stage.BundleError, "unexpected/missing files"):
            self.verify()
        (self.staging / "untrusted.py").unlink()
        audit = self.verify()
        with self.assertRaisesRegex(stage.BundleError, "outside the repository"):
            release.write_audit_once(ROOT / "data" / "not-a-safe-output", audit)

    def test_cycle_and_unknown_dependency_are_reported(self):
        existing = {"RM-BEAT-00-01"}
        additions = {"RM-BEAT-07-01", "RM-BEAT-07-02"}
        props = {
            "RM-BEAT-07-01": {"kind": "scene_complete", "ref": "RM-BEAT-07-02"},
            "RM-BEAT-07-02": {"kind": "scene_complete", "ref": "RM-BEAT-07-01"}
        }
        blockers, paths = release._dependency_report(props, existing, additions, {"RM-LVL-001"})
        self.assertTrue(any("cycle" in message for message in blockers))
        self.assertEqual(len(paths), 2)
        props["RM-BEAT-07-02"] = {"kind": "first_clear", "ref": "RM-LVL-999"}
        blockers, _ = release._dependency_report(props, existing, additions, {"RM-LVL-001"})
        self.assertTrue(any("unknown Match-3" in message for message in blockers))
        props["RM-BEAT-07-02"] = {"kind": "custom_script", "ref": "res://bad.gd"}
        blockers, _ = release._dependency_report(props, existing, additions, set())
        self.assertTrue(any("not supported" in message for message in blockers))

    def test_no_existing_files_or_saves_were_mutated(self):
        self.verify()
        for name, sha in self.before.items():
            self.assertEqual(release._sha(release.ROLLBACK_SOURCES[name].read_bytes()),
                             sha, "Source changed by a read-only audit")


if __name__ == "__main__":
    unittest.main()
