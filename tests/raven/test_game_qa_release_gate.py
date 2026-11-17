"""GAME-QA-01: blocking runner/package registration, not future G2 acceptance.

The already-implemented smoke suites remain blocking on both local runners.
Owner-approved HC/CB direction and the merged Evelyn gameplay walker are now
covered by isolated smoke. Production geometry, normal menu-to-G2 route and
physical Web/mobile acceptance are deliberately NOT asserted here.
"""
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[2]
RUNNERS = ("scripts/check.sh", "check.ps1")
SCRIPT_RE = re.compile(r"res://tests/raven/([A-Za-z0-9_/-]+\.gd)")
CRITICAL_G2 = (
    "manor_navigation_graph_smoke.gd",
    "map_game_01a_navigation_source_smoke.gd",
    "map_qa_06_room_transitions_smoke.gd",
    "map_qa_07b_integrated_first_floor_smoke.gd",
    "game_loop_01a_hotspot_bridge_smoke.gd",
    "game_loop_characterization_smoke.gd",
    "game_pause_smoke.gd",
    "restoration_restore_smoke.gd",
    "session_lifecycle_e2e_smoke.gd",
    "main_menu_upds_parity_smoke.gd",
    "main_menu_match3_campaign_smoke.gd",
    "match3_session_smoke.gd",
    "match3_checkpoint_smoke.gd",
    "match3_viewport_input_smoke.gd",
    "vn_production_runtime_dispatch_smoke.gd",
    "vn_locale_save_parity_smoke.gd",
    "vn_read_skip_smoke.gd",
    "vn_shell_safe_area_smoke.gd",
    "vn_english_localization_smoke.gd",
    "vn_belarusian_localization_smoke.gd",
    "device_matrix_reachability_smoke.gd",
    "gfx_07_01_evelyn_gameplay_host_smoke.gd",
    "map_qa_09d_hc_cb_architectural_smoke.gd",
    "game_loop_g2_host_smoke.gd",
)


class ReleaseGateRunnerContractTest(unittest.TestCase):
    def _registered(self, runner: str) -> list[str]:
        text = (ROOT / runner).read_text(encoding="utf-8")
        scripts = SCRIPT_RE.findall(text)
        self.assertTrue(scripts, f"{runner} has no Godot tests")
        return scripts

    def test_registered_godot_scripts_exist_and_are_not_duplicated(self):
        for runner in RUNNERS:
            scripts = self._registered(runner)
            self.assertEqual(len(scripts), len(set(scripts)),
                             f"{runner} has a duplicate Godot smoke registration")
            for script in scripts:
                self.assertTrue((ROOT / "tests" / "raven" / script).is_file(),
                                f"{runner} registers missing test {script}")

    def test_implemented_g2_regressions_stay_blocking_in_both_runners(self):
        for runner in RUNNERS:
            scripts = self._registered(runner)
            for script in CRITICAL_G2:
                self.assertEqual(scripts.count(script), 1,
                                 f"{runner} must run exactly once: {script}")

    def test_evelyn_bake_and_preview_remain_blocking(self):
        for runner in RUNNERS:
            text = (ROOT / runner).read_text(encoding="utf-8")
            for name in ("bake_atlas.gd", "preview_smoke.gd"):
                path = "res://assets/raven/chibi/evelyn/g1_candidate/repair_v1/" + name
                self.assertEqual(text.count(path), 1,
                                 f"{runner} lost/duplicated existing Evelyn check: {name}")

    def test_data_runner_invokes_contract_check_once(self):
        for runner in ("scripts/check_data.sh", "check.ps1"):
            text = (ROOT / runner).read_text(encoding="utf-8")
            self.assertEqual(text.count("test_game_qa_release_gate.py"), 1,
                             f"{runner} lost/duplicated GAME-QA-01 data test")
        self.assertIn('bash "$ROOT/scripts/check_data.sh"',
                      (ROOT / "scripts/check.sh").read_text(encoding="utf-8"))

    def test_pages_packages_the_shipped_game_not_just_dashboard(self):
        """Static artifact contract; NOT an actual browser/game-boot assertion."""
        workflow = (ROOT / ".github/workflows/pages.yml").read_text(encoding="utf-8")
        for item in (
            '--export-release "GitHub Pages Web" build/web/index.html',
            "test -f build/web/index.html",
            "test -f build/web/index.wasm",
            "test -f build/web/index.pck",
            "test -s build/web/dashboard/index.html",
            "actions/deploy-pages@v5",
        ):
            self.assertIn(item, workflow, f"Pages packaging lost {item}")


if __name__ == "__main__":
    unittest.main()
