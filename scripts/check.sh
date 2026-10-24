#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-godot}"

run_check() {
	local stage="$1" expected="$2"
	shift 2
	local output
	output="$($GODOT_BIN --headless --path "$ROOT" "$@" 2>&1)" || { printf '%s\n' "$output"; return 1; }
	[[ -z "$expected" || "$output" == *"$expected"* ]]
	[[ "$output" != *"SCRIPT ERROR:"* ]]
	printf '%s passed.\n' "$stage"
}

run_check 'Project import' '' --editor --quit
for script in core/save_storage.gd raven/raven_ids.gd raven/raven_snapshot.gd raven/raven_reducer.gd raven/raven_campaign_store.gd raven/manor_navigation_graph.gd raven/manor_greybox.gd raven/prototype_launcher.gd raven/foundation_lab.gd raven/raven_match3_game.gd raven/raven_vn_player.gd raven/raven_slice_director.gd raven/vertical_slice.gd; do
	run_check "Parse $script" '' --check-only --script "res://scripts/$script"
done
run_check 'Raven foundation smoke' 'Raven Manor foundation smoke passed' --script res://tests/raven/raven_foundation_smoke.gd --quit-after 120
run_check 'Raven navigation graph smoke' 'Raven Manor authored navigation graph smoke passed' --script res://tests/raven/manor_navigation_graph_smoke.gd --quit-after 120
run_check 'Prototype Lab smoke' 'Raven Manor Prototype Lab smoke passed' --script res://tests/raven/prototype_lab_smoke.gd --quit-after 120
run_check 'RM-VS-01 vertical slice smoke' 'Raven Manor RM-VS-01 smoke passed' --script res://tests/raven/vertical_slice_smoke.gd --quit-after 120
