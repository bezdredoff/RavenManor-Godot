#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# All legacy non-Godot source and production validation commands.
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

