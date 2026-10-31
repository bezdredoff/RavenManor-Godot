#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-godot}"

# Production catalogs are checked independently of the playable runtime.
python3 "$ROOT/scripts/raven/tools/validate_production_narrative.py"
python3 "$ROOT/scripts/raven/tools/validate_code_plan.py"
python3 "$ROOT/scripts/raven/tools/build_production_dashboard.py" --check
python3 -m unittest scripts/raven/tools/test_production_dashboard_mobile.py scripts/raven/tools/test_pr_governance.py scripts/raven/tools/test_audit_upds_vn.py
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
for script in core/save_storage.gd raven/raven_ids.gd raven/raven_snapshot.gd raven/raven_reducer.gd raven/raven_campaign_store.gd raven/manor_navigation_graph.gd raven/manor_greybox.gd raven/prototype_launcher.gd raven/foundation_lab.gd raven/raven_match3_game.gd shared/upds/match3_game.gd shared/upds/dialogue_paging.gd shared/upds/player_preferences.gd shared/upds/seeded_random.gd ui/css_motion.gd match3/match3_board_shape.gd match3/match3_tile_motion_layer.gd match3/match3_tutorials.gd match3/match3_drag_model.gd match3/match3_mobile_layout.gd match3/match3_frame_visuals.gd match3/match3_board_presenter.gd raven/raven_match3_theme.gd raven/raven_menu_copy.gd raven/upds_match3_campaign_adapter.gd raven/raven_vn_player.gd raven/raven_production_localization.gd raven/hall_tea_vn.gd raven/raven_slice_director.gd raven/vertical_slice.gd raven/content_preview.gd raven/season1_map_greybox.gd; do
	run_check "Parse $script" '' --check-only --script "res://scripts/$script"
done
run_check 'Raven foundation smoke' 'Raven Manor foundation smoke passed' --script res://tests/raven/raven_foundation_smoke.gd --quit-after 120
run_check 'Raven navigation graph smoke' 'Raven Manor authored navigation graph smoke passed' --script res://tests/raven/manor_navigation_graph_smoke.gd --quit-after 120
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
run_check 'Layered Hall VN pilot smoke' 'Raven Manor Hall tea VN pilot smoke passed' --script res://tests/raven/hall_tea_vn_smoke.gd --quit-after 120
run_check 'Hall VN runtime UI smoke' 'Raven Manor Hall VN UI runtime smoke passed' --script res://tests/raven/hall_tea_vn_ui_smoke.gd --quit-after 240
run_check 'Whole season1 map smoke' 'Raven Manor continuous season1 map smoke passed' --script res://tests/raven/season1_map_smoke.gd --quit-after 120
