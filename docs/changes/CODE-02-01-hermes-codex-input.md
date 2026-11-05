Task IDs: CODE-02-01

Changes:
- Fixed a concrete touch lifecycle defect in `scripts/match3/match3_board_presenter.gd`: an owning `InputEventScreenTouch` release marked `canceled` now clears the gesture and preview instead of being interpreted as a completed swipe.
- Added the regression to the existing targeted `tests/raven/match3_viewport_input_smoke.gd`. The two test names in the worker allowlist did not exist; this is the existing Viewport/ScrollContainer input test used by the project.
- No Match-3 rules, rewards, campaign/save state, story content, shared runners or art were changed.
- Donor audit: `bezdredoff/UPDS-godot@3deed628efd6c22bcd1717f7c545b7d3ca865781`, `scripts/match3/match3_screen.gd`, blob `76b42df35d4857f242d3f6bc06b9f989d43ad0a3`, functions `_on_tile_gui_input`, `_begin_tile_drag`, `_update_tile_drag`, `_end_tile_drag`, `_drag_neighbour`. The donor treats every touch release as completion and has no cancellation branch. Reuse decision: `adapt` the extracted Raven pointer lifecycle while retaining donor thresholds, direction and neighbour rules.

Verification:
- Before fix: Godot 4.7.2 headless `res://tests/raven/match3_viewport_input_smoke.gd` reproduced `Assertion failed: Cancelled touch drag committed a move` at the new regression assertion. The failed SceneTree remained alive until the command timeout; this is a failing regression, not a test pass.
- After fix: the same headless test exited 0 with `Raven Match-3 viewport pointer and modal smoke passed`; Godot also reported the test's pre-existing two ObjectDB leak warning.
- Affected regression set passed on Godot 4.7.2: `match3_viewport_input_smoke.gd`, `upds_match3_interactive_board_smoke.gd`, `match3_checkpoint_smoke.gd`, `match3_session_smoke.gd`, and `game_loop_characterization_smoke.gd`. The characterization smoke intentionally printed its exercised save-failure error and still exited 0 with its expected pass marker.
- Full Godot `scripts/check.sh` suite passed with `RAVEN_SKIP_DATA_CHECKS=1` through a scratch-only Windows path adapter; this includes all script parse checks and project Godot smokes. No repository runner was modified.
- Required status checks passed: `python scripts/raven/tools/progress_shards.py` (`214` unique overrides, `124` assignments) and `python scripts/raven/tools/build_production_dashboard.py --check` (`249` tasks, `28` stages).
- The standalone full `scripts/check_data.sh` attempt reached its Python unit tests but failed in the pre-existing Windows path-separator assertion `test_sharded_dashboard.ShardedDashboardTests.test_canonical_shards_and_provenance` (`sourceFiles` uses Windows separators while the test requires `/progress/index.json`). This unrelated check was not changed or claimed passing.

Owner QA:
- Pending physical mobile/Web cancellation testing (OS interruption/system gesture), complete CODE-02-01 device coverage, visual/art review and product-owner acceptance.

Status impact:
- `CODE-02-01` is `PR_review` for open PR https://github.com/bezdredoff/RavenManor-Godot/pull/199, covering this correctness slice only. The broad input/mobile/art task remains partial; no merge, device verification or acceptance is claimed. Hermes executor: configured Codex runtime/model gpt-5.6-sol; orchestrator reviewed and publishes the diff. The existing test path match3_viewport_input_smoke.gd is approved for this slice (initial brief transposed the filename).
Additional worker verification: full Godot portion of scripts/check.sh passed; shard/dashboard validators passed. Native Windows full data suite remains limited by the existing path-separator assertion. Linux PR-head CI is required.
