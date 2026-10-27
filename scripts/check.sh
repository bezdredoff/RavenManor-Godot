#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-godot}"

# Production catalogs are checked independently of the playable runtime.
python3 "$ROOT/scripts/raven/tools/validate_production_narrative.py"
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
	if [[ "$output" == *"SCRIPT ERROR:"* ]]; then
		printf 'ERROR: %s reported a Godot script error\n' "$stage" >&2
		printf '%s\n' "$output" >&2
		return 1
	fi
	printf '%s passed.\n' "$stage"
}

run_check 'Project import' '' --editor --quit
for script in core/save_storage.gd raven/raven_ids.gd raven/raven_snapshot.gd raven/raven_reducer.gd raven/raven_campaign_store.gd raven/manor_navigation_graph.gd raven/manor_greybox.gd raven/prototype_launcher.gd raven/foundation_lab.gd raven/raven_match3_game.gd raven/raven_vn_player.gd raven/raven_production_localization.gd raven/hall_tea_vn.gd raven/raven_slice_director.gd raven/vertical_slice.gd raven/content_preview.gd raven/season1_map_greybox.gd; do
	run_check "Parse $script" '' --check-only --script "res://scripts/$script"
done
run_check 'Raven foundation smoke' 'Raven Manor foundation smoke passed' --script res://tests/raven/raven_foundation_smoke.gd --quit-after 120
run_check 'Raven navigation graph smoke' 'Raven Manor authored navigation graph smoke passed' --script res://tests/raven/manor_navigation_graph_smoke.gd --quit-after 120
run_check 'Prototype Lab smoke' 'Raven Manor Prototype Lab smoke passed' --script res://tests/raven/prototype_lab_smoke.gd --quit-after 120
run_check 'RM-VS-01 vertical slice smoke' 'Raven Manor RM-VS-01 smoke passed' --script res://tests/raven/vertical_slice_smoke.gd --quit-after 120
run_check 'Narrative production contract smoke' 'Raven Manor production narrative contract smoke passed' --script res://tests/raven/production_narrative_smoke.gd --quit-after 120
run_check 'Layered Hall VN pilot smoke' 'Raven Manor Hall tea VN pilot smoke passed' --script res://tests/raven/hall_tea_vn_smoke.gd --quit-after 120
run_check 'Whole season1 map smoke' 'Raven Manor continuous season1 map smoke passed' --script res://tests/raven/season1_map_smoke.gd --quit-after 120
