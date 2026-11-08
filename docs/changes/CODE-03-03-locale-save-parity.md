Task IDs: CODE-03-03 (bounded increment: tri-locale VN save/reload parity smoke)

Changes:
- New headless Godot smoke `tests/raven/vn_locale_save_parity_smoke.gd` (registered in `check.ps1` and `scripts/check.sh`; no runtime, save schema, catalog or content file touched, no duplicate game content created).
  * Reuses the existing playable path only: `vertical_slice.gd` + `raven_campaign_store.gd` over `tests/support/memory_storage.gd`, `raven_vn_read_history.gd` Skip rules, `raven_production_localization.gd` copy and the existing RM-BEAT-00-01 prologue lines. Language preference is an isolated `user://raven_locale_save_parity_smoke.cfg`, removed at the end; the player's real language setting is never read or written as an assertion target.
  * Per locale (ru, be, en): verifies stable RM line IDs are locale-independent, advances two VN lines with `_advance_vn()` and asserts cursor `{beatId, lineIndex=2}` plus read history `[L001, L002]` are persisted.
  * Explicit Save, then a rebuilt scene as Continue: cursor and read history are restored, and the visible copy matches the selected locale — dialogue text, scene title, nameplate speaker and Next label — including both localized history entries.
  * Paging/Auto must not move the restored line: Continue starts on page 1, paging to the last page leaves line index, stored cursor and read history unchanged (measured 2 pages for `RM-BEAT-00-01-L003` in all three locales; the suite fails if no locale paginates), Auto is off after Continue and a stray auto timeout does not advance the line.
  * Skip in each locale: with L001/L002 already read and the cursor rewound to line 1, Skip lands exactly on the first unread line (L003), does not mark it read, disables the Skip button, persists the new cursor, does not complete the scene, does not advance the story beat and a repeated Skip does not cross the unread text.

Verification:
- `Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/raven/vn_locale_save_parity_smoke.gd --quit-after 240` — EXECUTED_PASS ("Raven tri-locale VN save/reload parity smoke passed"), exit 0, 0 `SCRIPT ERROR` lines, no ObjectDB leak warning.
- `Godot_v4.7.2-stable_win64_console.exe --headless --editor --path . --quit` — EXECUTED_PASS (regenerated the local `.godot` import cache of this fresh worktree; before it, preloaded webp/png assets reported "no resource loaders" for existing tests too). Not a change to tracked files.
- Negative control — EXECUTED_FAIL (expected): a deliberately inverted Continue expectation produced `SCRIPT ERROR: Assertion failed: ru: Continue lost the line`, proving the assertions execute; reverted before commit.
- Regression context, all EXECUTED_PASS, exit 0, 0 `SCRIPT ERROR`: `vn_read_skip_smoke.gd` (600), `session_lifecycle_e2e_smoke.gd` (240), `vn_english_localization_smoke.gd` (240), `vn_belarusian_localization_smoke.gd` (240).
- Data/shard gates EXECUTED_PASS: `progress_shards.py` (215 overrides, 125 assignments, 15 domains), `validate_backlog_dependencies.py` (0 errors), `validate_active_workstreams.py` (0 errors), `validate_backlog_acceptance.py` (0 errors), `reconcile_gap_statuses.py --check` (0 structural errors), `build_production_dashboard.py --check` (250 tasks, 28 stages), `python3 -m unittest scripts/raven/tools/test_progress_shards.py` (5 tests OK).
- `check.ps1 -GodotPath ...` — NOT_RUN: blocked by the unattended-session approval policy on this host (PowerShell script execution not permitted). The target headless smoke above is the local gate; exact-head CI runs the full suite.
- `bash scripts/check.sh` — NOT_RUN by task instruction: on this MSYS host it passes POSIX paths to native python3/Godot and fails before any test.

Owner QA: not performed. No native Windows/mobile run, device resolution, visual or audio check is claimed; the added evidence is headless and in-memory only.

Status impact: CODE-03-03 stays `status: ready`, `implementationState: partial`, `qaState: automated`; only an evidence line and `updated` date were appended to `data/raven/production/progress/vn-runtime.json`. No PR, no merge, no acceptance, no owner/device verification inferred.

Risk and rollback: test-only change plus runner registration and evidence text. No runtime, save schema, catalog, scene or content file changed. The smoke uses in-memory campaign storage and a self-removed `user://` preference file. Rollback: revert this commit.
