"""GAME-QA-01: keep the blocking release smoke registration honest.

This is a contract test for the two local runners, not a replacement for
Godot or physical-device acceptance. It prevents a release gate from naming a
missing script or silently dropping one of the already-approved critical
journey suites.
"""

from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[2]


class ReleaseGateRunnerContractTest(unittest.TestCase):
    def test_registered_godot_scripts_exist(self):
        runners = [ROOT / "scripts" / "check.sh", ROOT / "check.ps1"]
        for runner in runners:
            text = runner.read_text(encoding="utf-8")
            scripts = re.findall(r"res://tests/raven/([^'\" ]+\.gd)", text)
            self.assertTrue(scripts, runner.name)
            for script in scripts:
                self.assertTrue(
                    (ROOT / "tests" / "raven" / script).is_file(),
                    f"{runner.name} registers missing test {script}",
                )

    def test_release_critical_smokes_remain_registered_in_both_runners(self):
        required = (
            "main_menu_upds_parity_smoke.gd",
            "game_loop_01a_hotspot_bridge_smoke.gd",
            "match3_checkpoint_smoke.gd",
            "match3_viewport_input_smoke.gd",
            "vn_locale_save_parity_smoke.gd",
            "campaign_season1_audit_smoke.gd",
            "device_matrix_reachability_smoke.gd",
        )
        for runner_name in ("scripts/check.sh", "check.ps1"):
            text = (ROOT / runner_name).read_text(encoding="utf-8")
            for script in required:
                self.assertIn(script, text, f"{runner_name} dropped {script}")


if __name__ == "__main__":
    unittest.main()
