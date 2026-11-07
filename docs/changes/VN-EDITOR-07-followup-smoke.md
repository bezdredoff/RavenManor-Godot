Task IDs: VN-EDITOR-07 (vn-studio follow-up smoke; reuses VNS5-12 fixture)

Changes:
- Extended the existing VNS5-12 headless smoke `tests/raven/vn_studio_branch_demo_smoke.gd` (no new fixture, no duplicate game content, no new runner entry; the script was already registered in `scripts/check.sh` L45 and `check.ps1` L114):
    * Fail-closed cross-project stale-draft guard on an isolated second root: the five canonical registries are copied byte-identically (sha256 verified) into `user://vns5_12_foreign_project_<usec>`, opened with `Store.open_project`.
      - (a) A VNS5-12 draft locked to the real project root is placed in the other root's draft path: `load_draft` refuses, `stale_draft_info` refuses with the "другому проекту" error, `archive_and_start_fresh` refuses, the foreign draft bytes are unchanged and no recovery backup directory is created.
      - (b) Same-root fingerprint but a source SHA from another project: `load_draft` and `save_local` refuse, recovery reports the preserved fixture (scenes=4, lines=7) instead of importing it, the backup is byte-identical to the stale draft, and the new draft starts empty (change_count=0, no authored scenes/lines/Story Map/FX) locked to the current source SHA.
      - Canonical registries of the synthetic root are unchanged; only synthetic files are removed afterwards.
    * Explicit "three DISTINCT existing FX" assertions: every preview effect must already exist in `StageFx.EFFECTS`, and fade_in / breathe / shake must differ.
    * Existing assertions for the optional A/B/C end-of-draft choice (three `kind=choice` draft wires with A/B/C keys, return links, draft-port wire selection, canonical-port read-only guard, label edit + Undo/Redo) and for UI Play/Pause/Reset, scrub and clip retime (1750 ms) + Undo/Redo on the same fixture are retained unchanged.

Verification:
- `Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/raven/vn_studio_branch_demo_smoke.gd --quit-after 240` — EXECUTED_PASS ("Raven VN Studio three-way branch-and-FX draft-only demo smoke passed"), with pre-existing webp/compressed_texture asset warnings and no SCRIPT ERROR. The same command passed at the base commit before the edit.
- `bash scripts/check.sh` (GODOT_BIN set) — EXECUTED_FAIL, exit 2 before any test: this MSYS shell passes POSIX paths to native `python3` unchanged (`can't open file 'C:\\c\\Users\\...\\validate_production_narrative.py'`). Runner not modified.
- `check.ps1` — NOT_RUN: PowerShell invocation is blocked by the unattended-session approval policy on this host.
- Full `scripts/check.sh` re-run through throwaway `$TMPDIR` path shims (translate only POSIX arguments, repository untouched): data phase PASS until `test_sharded_dashboard.ShardedDashboardTests.test_canonical_shards_and_provenance` FAILs on Windows path separators (`sourceFiles` uses `\`, assertion expects `/progress/index.json`). Proven pre-existing: the same single test fails at HEAD with this change stashed. That file is `scripts/raven/tools/**` (qa-infrastructure, outside this task's allowlist) and was not modified.
- With `RAVEN_SKIP_DATA_CHECKS=1` the Godot suite ran: Project import, Legacy Viewer, draft overlay, character catalog, Story graph PASS; then "VN Studio conversion dry-run and export" FAIL (`Такой экспорт уже существует` — a pre-existing `user://vn_studio_conversions/v1/bundle-0414f88d9918ef82` from 2026-11-05 blocks the no-overwrite export). Unrelated to this diff; local user state was not deleted. Remaining stages after that point NOT_RUN.
- Data validators executed individually: `validate_production_narrative.py` PASS (28 scenes / 280 lines), `validate_code_plan.py` PASS (49 packages, 75 dependencies, 0 errors), `progress_shards.py` PASS (215 overrides, 125 assignments, 15 domains).

Owner QA: not performed. No native Windows mouse/viewport, device or visual run is claimed; the added guard is exercised headlessly only.

Status impact: VN-EDITOR-07 stays `ready` / `implementationState: partial` with no status or acceptance change; only an evidence line is appended to the `vn-studio` shard. No PR, no CI, no merge.

Risk and rollback: test-only change, no runtime, save, canonical catalog or donor content touched. The synthetic second root is created under `user://` and removed by the test itself. Rollback: revert this commit.
