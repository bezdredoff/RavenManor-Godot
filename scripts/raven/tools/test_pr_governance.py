"""Regression tests for the Raven PR governance gate."""
import importlib.util
import unittest
from pathlib import Path

PATH = Path(__file__).with_name("check_pr_governance.py")
spec = importlib.util.spec_from_file_location("raven_governance", PATH)
guard = importlib.util.module_from_spec(spec)
spec.loader.exec_module(guard)


class GovernanceTests(unittest.TestCase):
    def test_requires_both_sources_on_regular_code_pr(self):
        self.assertEqual(
            guard.missing_files({"scripts/raven/game.gd"}, "code/new-feature"),
            set(guard.REQUIRED),
        )
        self.assertEqual(
            guard.missing_files({"docs/STATUS.md"}, "docs/status-update"),
            {"data/raven/production/production_progress.json"},
        )
        self.assertEqual(
            guard.missing_files(set(guard.REQUIRED), "code/code-02d-mobile-hud-governance"),
            set(),
        )

    def test_only_true_candidate_branches_bypass(self):
        self.assertEqual(guard.missing_files({"docs/evidence/smoke.txt"}, "candidate/mobile-12345"), set())
        self.assertEqual(
            guard.missing_files({"docs/evidence/smoke.txt"}, "code/mobile-12345"),
            set(guard.REQUIRED),
        )
        self.assertEqual(
            guard.missing_files({"docs/evidence/smoke.txt"}, "candidate/other"),
            set(guard.REQUIRED),
        )


if __name__ == "__main__":
    unittest.main()
