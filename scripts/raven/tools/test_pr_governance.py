"""Governance contract: independent agent shards + legacy/generated protection."""
import importlib.util
import tempfile
import unittest
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "guard", Path(__file__).with_name("check_pr_governance.py"))
guard = importlib.util.module_from_spec(spec)
spec.loader.exec_module(guard)


class GovernanceTests(unittest.TestCase):
    note = "docs/changes/GAME-M3-01-scope.md"
    match3 = "data/raven/production/progress/match3.json"

    def test_independent_agent_only_edits_own_shard(self):
        self.assertEqual(guard.missing_files({self.note, self.match3}, "agent/match3/GAME-M3-01"), set())
        self.assertTrue(guard.missing_files({self.note, self.match3}, "agent/vn-studio/VNS5-09"))
        self.assertTrue(guard.missing_files({self.note}, "agent/match3/GAME-M3-01"))
        self.assertTrue(guard.missing_files(
            {self.note, self.match3, "data/raven/production/progress/vn-studio.json"},
            "agent/match3/GAME-M3-01"))
        self.assertTrue(guard.missing_files(
            {self.note, self.match3, "data/raven/production/progress/index.json"},
            "agent/match3/GAME-M3-01"))

    def test_integration_branch_can_coordinate_multiple_domains(self):
        files = {self.note, self.match3, "data/raven/production/progress/vn-studio.json"}
        self.assertEqual(guard.missing_files(files, "process/approved-integration"), set())

    def test_frozen_legacy_status_and_generated_dashboard_are_protected(self):
        for path in guard.PROTECTED:
            self.assertTrue(guard.missing_files({self.note, path}, "process/cleanup"))
        self.assertIn(guard.NOTE_REQUIRED, guard.missing_files({self.match3}, "code/a"))

    def test_note_fields(self):
        note = "docs/changes/PROC-007-domain-gate.md"
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / note
            path.parent.mkdir(parents=True)
            path.write_text("\n".join([
                "Task IDs: PROC-007", "Changes: Gate", "Verification: CI pending",
                "Owner QA: Pending", "Status impact: Per-domain"]), encoding="utf-8")
            self.assertEqual(guard.invalid_notes({note}, Path(directory)), [])
            path.write_text("Task IDs: PROC-007", encoding="utf-8")
            self.assertTrue(any("Owner QA:" in error
                                for error in guard.invalid_notes({note}, Path(directory))))

    def test_numeric_mobile_candidate_exception_is_exact(self):
        self.assertEqual(guard.missing_files(set(), "candidate/mobile-123"), set())
        for ref in ("candidate/mobile-123-evil", "code/mobile-123", "candidate/other"):
            self.assertIn(guard.NOTE_REQUIRED, guard.missing_files(set(), ref))


if __name__ == "__main__":
    unittest.main()
