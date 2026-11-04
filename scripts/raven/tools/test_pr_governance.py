"""Tests for independent authored PR evidence gate."""
import importlib.util
import tempfile
import unittest
from pathlib import Path

spec = importlib.util.spec_from_file_location("guard", Path(__file__).with_name("check_pr_governance.py"))
guard = importlib.util.module_from_spec(spec)
spec.loader.exec_module(guard)


class GovernanceTests(unittest.TestCase):
    def test_prs_can_use_isolated_notes(self):
        note = "docs/changes/CODE-05-01-room-anchors.md"
        self.assertEqual(guard.missing_files({note, "scripts/raven/game.gd"}, "code/a"), set())
        self.assertEqual(guard.missing_files(set(guard.LEGACY_STATUS), "code/b"), set())
        self.assertIn(guard.NOTE_REQUIRED, guard.missing_files({"docs/STATUS.md"}, "docs/a"))
        self.assertIn(guard.NOTE_REQUIRED, guard.missing_files({"scripts/raven/game.gd"}, "code/b"))

    def test_invalid_dashboard_touch(self):
        note = "docs/changes/PROC-006-gate.md"
        self.assertTrue(guard.missing_files({note, "dashboard/status.json"}, "code/c"))

    def test_note_fields(self):
        note = "docs/changes/PROC-006-gate.md"
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / note
            path.parent.mkdir(parents=True)
            path.write_text("\n".join(["Task IDs: PROC-006", "Changes: Gate", "Verification: CI pending",
                                       "Owner QA: Pending", "Status impact: Post-merge closeout"]), encoding="utf-8")
            self.assertEqual(guard.invalid_notes({note}, Path(directory)), [])
            path.write_text("Task IDs: PROC-006", encoding="utf-8")
            self.assertTrue(any("Owner QA:" in e for e in guard.invalid_notes({note}, Path(directory))))

    def test_numeric_candidates_only(self):
        self.assertEqual(guard.missing_files(set(), "candidate/mobile-123"), set())
        for ref in ("candidate/mobile-123-evil", "code/mobile-123", "candidate/other"):
            self.assertIn(guard.NOTE_REQUIRED, guard.missing_files(set(), ref))


if __name__ == "__main__":
    unittest.main()
