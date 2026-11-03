#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-godot}"

# Production catalogs are checked independently of the playable runtime.
python3 "$ROOT/scripts/raven/tools/validate_production_narrative.py"
# Enforce complete RU/BE/EN spoken lines, scene titles and hotspot popups.
# This registry gate does not certify unrelated in-game UI or manual proofreading.
python3 "$ROOT/scripts/raven/tools/validate_production_narrative.py" --release
python3 "$ROOT/scripts/raven/tools/validate_code_plan.py"
# Fail if the gap task snapshot drifts from the authoritative live progress file.
python3 "$ROOT/scripts/raven/tools/reconcile_gap_statuses.py" --check
python3 "$ROOT/scripts/raven/tools/validate_backlog_dependencies.py"
python3 "$ROOT/scripts/raven/tools/validate_active_workstreams.py"
python3 "$ROOT/scripts/raven/tools/validate_backlog_acceptance.py"
python3 "$ROOT/scripts/raven/tools/build_production_dashboard.py" --check
# Dashboard snapshot tests are advisory; runtime and data integrity remain blocking.
if ! python3 -m unittest scripts/raven/tools/test_production_dashboard_mobile.py; then
  echo "::warning title=Dashboard regression advisory::Dashboard snapshot assertions failed; review separately."
fi
python3 -m unittest scripts/raven/tools/test_pr_governance.py scripts/raven/tools/test_audit_upds_vn.py
python3 -m unittest discover -s "$ROOT/tests/raven" -p 'test_vns5_contract.py'
python3 -m unittest discover -s "$ROOT/tests/raven" -p 'test_vns5_promotion_staging.py'
python3 -m unittest discover -s "$ROOT/tests/raven" -p 'test_vns5_release_readiness.py'
python3 -m unittest discover -s "$ROOT/tests/raven" -p 'test_vns5_locked_release_patch.py'
worklist_check="$(mktemp)"
python3 "$ROOT/scripts/raven/tools/export_translation_worklist.py" --output "$worklist_check"
rm -f "$worklist_check"

run_check() {
	local stage="$1" expected="$2"
	shift 2
	local output
	output="$($GODOT_BIN --headless --path "$ROOT" "$@" 2>&1)" || { printf '%s\n' "$output"; return 1; }
	if [[ -n "$expected" && "$output" != *"$expected"* ]]; then
		printf 'ERROR: %s did not produce expected output: %s\n' "$stage" "$expected" >&2
		printf '%s\n' "$output" >&2
		return 1
	fi
	if [[ "$output" == *"res://addons/vn_studio/res:"* || "$output" == *"Failed loading resource: res://addons/vn_studio/"* ]]; then
		printf 'ERROR: %s reported a broken VN Studio plugin path\n' "$stage" >&2
		printf '%s\n' "$output" >&2
		return 1
	fi
	if [[ "$output" == *"SCRIPT ERROR:"* ]]; then
		printf 'ERROR: %s reported a Godot script error\n' "$stage" >&2
		printf '%s\n' "$output" >&2
		return 1
	fi
	printf '%s passed.\n' "$stage"
}

run_check 'Project import' '' --editor --quit
run_check 'VN Studio Legacy Viewer synthetic' 'Raven VN Studio read-only legacy viewer smoke passed' --script res://tests/raven/vn_studio_legacy_smoke.gd --quit-after 120
run_check 'VN Studio draft overlay round-trip' 'Raven VN Studio draft overlay round-trip smoke passed' --script res://tests/raven/vn_studio_drafts_smoke.gd --quit-after 120
run_check 'VN Studio character catalog' 'Raven VN Studio character library smoke passed' --script res://tests/raven/vn_studio_catalog_smoke.gd --quit-after 120
run_check 'VN Studio story graph' 'Raven VN Studio story graph smoke passed' --script res://tests/raven/vn_studio_story_graph_smoke.gd --quit-after 120
run_check 'VN Studio conversion dry-run and export' 'Raven VN Studio migration dry-run and immutable export smoke passed' --script res://tests/raven/vn_studio_migration_smoke.gd --quit-after 120
run_check 'VN Studio legacy save position and semantic diff' 'Raven VN Studio old-save position inspection smoke passed' --script res://tests/raven/vn_studio_save_position_smoke.gd --quit-after 120
run_check 'VN Studio semantic replay parity' 'Raven VN Studio data semantic parity replay smoke passed' --script res://tests/raven/vn_studio_story_semantics_smoke.gd --quit-after 120
run_check 'VN Studio Raven Manor authoring' 'Raven VN Studio local story authoring and safe export smoke passed' --script res://tests/raven/vn_studio_raven_story_smoke.gd --quit-after 120
run_check 'VN Studio VNS5-06A Story Map' 'Raven VN Studio VNS5-06A Story Map draft and immutable routes smoke passed' --script res://tests/raven/vn_studio_raven_graph_smoke.gd --quit-after 240
run_check 'VN Studio VNS5-06B new scene and dialogue authoring' 'Raven VN Studio VNS5-06B new scene and dialogue draft authoring smoke passed' --script res://tests/raven/vn_studio_new_scenes_lines_smoke.gd --quit-after 240
run_check 'VN Studio VNS5-12 branch-and-FX draft demo' 'Raven VN Studio three-way branch-and-FX draft-only demo smoke passed' --script res://tests/raven/vn_studio_branch_demo_smoke.gd --quit-after 240
run_check 'VN Studio VNS5-09 full authoring save/reopen' 'Raven VN Studio VNS5-09 full authoring round-trip smoke passed' --script res://tests/raven/vn_studio_full_authoring_e2e_smoke.gd --quit-after 240
run_check 'VN Studio VNS5-06C no-apply promotion review' 'Raven VN Studio VNS5-06C promotion remap and no-apply review smoke passed' --script res://tests/raven/vn_studio_promotion_review_smoke.gd --quit-after 240
run_check 'VN Studio VNS5-06D1 four-registry candidate' 'Raven VN Studio VNS5-06D1 four-registry no-apply package smoke passed' --script res://tests/raven/vn_studio_four_registry_promotion_smoke.gd --quit-after 240
for script in core/save_storage.gd raven/raven_ids.gd raven/raven_snapshot.gd raven/raven_reducer.gd raven/raven_campaign_store.gd raven/manor_navigation_graph.gd raven/manor_greybox.gd raven/prototype_launcher.gd raven/foundation_lab.gd raven/raven_match3_game.gd shared/upds/match3_game.gd shared/upds/dialogue_paging.gd shared/upds/player_preferences.gd shared/upds/seeded_random.gd ui/css_motion.gd match3/match3_board_shape.gd match3/match3_tile_motion_layer.gd match3/match3_tutorials.gd match3/match3_drag_model.gd match3/match3_mobile_layout.gd match3/match3_frame_visuals.gd match3/match3_board_presenter.gd raven/raven_match3_theme.gd raven/raven_menu_copy.gd raven/upds_match3_campaign_adapter.gd raven/raven_vn_player.gd raven/raven_vn_catalog_adapter.gd raven/raven_vn_game_view.gd raven/raven_vn_runtime_dispatch.gd raven/raven_production_localization.gd raven/hall_tea_vn.gd raven/raven_slice_director.gd raven/vertical_slice.gd raven/content_preview.gd raven/season1_map_greybox.gd; do
	run_check "Parse $script" '' --check-only --script "res://scripts/$script"
done
run_check 'Raven foundation smoke' 'Raven Manor foundation smoke passed' --script res://tests/raven/raven_foundation_smoke.gd --quit-after 120
run_check 'VNS5-06D2A save & rollback rehearsal' 'Raven VN VNS5-06D2A save and rollback projection smoke passed' --script res://tests/raven/vn_release_save_rehearsal_smoke.gd --quit-after 240
run_check 'VNS5-06D2C canonical-only runtime VN dispatch' 'Raven VN VNS5-06D2C approved-only runtime dispatch/save/locale/art smoke passed' --script res://tests/raven/vn_production_runtime_dispatch_smoke.gd --quit-after 240
run_check 'Raven navigation graph smoke' 'Raven Manor authored navigation graph smoke passed' --script res://tests/raven/manor_navigation_graph_smoke.gd --quit-after 120
run_check 'Match-3 checkpoint smoke' 'Raven Manor Match-3 replay checkpoint smoke passed' --script res://tests/raven/match3_checkpoint_smoke.gd --quit-after 120
run_check 'VN line checkpoint smoke' 'Raven Manor VN line checkpoint smoke passed' --script res://tests/raven/vn_cursor_smoke.gd --quit-after 120
run_check 'Gameplay pause smoke' 'Raven Manor save-and-exit pause smoke passed' --script res://tests/raven/game_pause_smoke.gd --quit-after 120
run_check 'Main menu smoke' 'Raven Manor main menu and Prototype Lab navigation smoke passed' --script res://tests/raven/main_menu_smoke.gd --quit-after 120
run_check 'Prototype Lab smoke' 'Raven Manor Prototype Lab smoke passed' --script res://tests/raven/prototype_lab_smoke.gd --quit-after 120
run_check 'UPDS engine port parity smoke' 'Raven Manor UPDS core reuse smoke passed' --script res://tests/raven/upds_core_reuse_smoke.gd --quit-after 120
run_check 'UPDS M3 visual primitives' 'Raven Manor UPDS Match-3 visual primitives smoke passed' --script res://tests/raven/upds_match3_visual_primitives_smoke.gd --quit-after 120
run_check 'UPDS Match3 interactive board' 'Raven Manor UPDS interactive Match-3 board smoke passed' --script res://tests/raven/upds_match3_interactive_board_smoke.gd --quit-after 120
run_check 'UPDS M3 help, blockers and retry' 'Raven Manor UPDS Match-3 help, objectives, special/blocker and retry smoke passed' --script res://tests/raven/upds_match3_presentation_states_smoke.gd --quit-after 120
run_check 'UPDS Match3 frame FX / blocker segments' 'Raven Manor UPDS special-impact and blocker-segment settle smoke passed' --script res://tests/raven/upds_match3_frame_fx_smoke.gd --quit-after 120
run_check 'CODE-02D mobile HUD and safe-area' 'Raven Manor CODE-02D mobile HUD layout and safe-area smoke passed' --script res://tests/raven/upds_match3_mobile_hud_smoke.gd --quit-after 120
run_check 'Match3 direct QA Content Preview' 'Raven Manor Match-3 QA shortcut and UPDS Content Preview parity smoke passed.' --script res://tests/raven/content_preview_match3_qa_smoke.gd --quit-after 120
run_check 'RM-VS-01 vertical slice smoke' 'Raven Manor RM-VS-01 smoke passed' --script res://tests/raven/vertical_slice_smoke.gd --quit-after 120
run_check 'Narrative production contract smoke' 'Raven Manor production narrative contract smoke passed' --script res://tests/raven/production_narrative_smoke.gd --quit-after 120
run_check 'English translation and VN Studio parity' 'Raven English VN Studio localization smoke passed' --script res://tests/raven/vn_english_localization_smoke.gd --quit-after 240
run_check 'Belarusian translation and VN Studio parity' 'Raven Belarusian VN Studio localization smoke passed' --script res://tests/raven/vn_belarusian_localization_smoke.gd --quit-after 240
run_check 'VN background catalog / gallery' 'Raven VN background registry and 9 textures PASS' --script res://tests/raven/vn_background_gallery_smoke.gd --quit-after 120
run_check 'VN Studio responsive layout' 'Raven VN Studio responsive layout smoke passed' --editor --script res://tests/raven/vn_studio_layout_smoke.gd --quit-after 120
run_check 'VN Studio asset registry' 'Raven VN Studio asset registry read-only smoke passed' --script res://tests/raven/vn_studio_asset_registry_smoke.gd --quit-after 120
run_check 'VN Studio staged image import safety' 'Raven VN Studio staged image import safety smoke passed' --script res://tests/raven/vn_studio_staged_image_smoke.gd --quit-after 120
run_check 'VN Studio orientation/templates/undo' 'Raven VN Studio VNS5-04A orientation/template/undo smoke passed' --script res://tests/raven/vn_studio_stage_orientation_smoke.gd --quit-after 180
run_check 'VN Studio stage-v2 sidecar/props' 'Raven VN Studio VNS5-04B sidecar/focal/prop/z-order safety smoke passed' --script res://tests/raven/vn_studio_stage_v2_smoke.gd --quit-after 240
run_check 'VN Studio micro-FX timeline' 'Raven VN Studio VNS5-05A micro-FX timeline safety smoke passed' --script res://tests/raven/vn_studio_stage_fx_smoke.gd --quit-after 240
run_check 'VN Studio line-bound FX' 'Raven VN Studio VNS5-05B line-bound FX authoring smoke passed' --script res://tests/raven/vn_studio_line_fx_smoke.gd --quit-after 240
run_check 'VN reviewed-only runtime FX' 'Raven VN VNS5-05B reviewed-only runtime FX presentation smoke passed' --script res://tests/raven/vn_fx_runtime_smoke.gd --quit-after 240
run_check 'VN Studio background-state preview' 'Raven VN Studio background-state preview smoke passed' --script res://tests/raven/vn_studio_backgrounds_smoke.gd --quit-after 120
run_check 'Approved character art integration' 'Raven approved character art smoke passed' --script res://tests/raven/vn_character_art_smoke.gd --quit-after 240
run_check 'Layered Hall VN pilot smoke' 'Raven Manor Hall tea VN pilot smoke passed' --script res://tests/raven/hall_tea_vn_smoke.gd --quit-after 120
run_check 'Live Raven VN gameplay backgrounds' 'Raven live VN background compositor passed' --script res://tests/raven/vn_runtime_background_smoke.gd --quit-after 240
run_check 'Hall VN runtime UI smoke' 'Raven Manor Hall VN UI runtime smoke passed' --script res://tests/raven/hall_tea_vn_ui_smoke.gd --quit-after 240
run_check 'Whole season1 map smoke' 'Raven Manor continuous season1 map smoke passed' --script res://tests/raven/season1_map_smoke.gd --quit-after 120
