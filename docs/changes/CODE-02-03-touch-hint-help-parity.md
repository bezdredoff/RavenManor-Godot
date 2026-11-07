# CODE-02-03 — Match-3 touch / hint / help presentation parity

Task IDs: CODE-02-03 (parent tracking entry). Prerequisites already merged on main: CODE-02-01 (cancelled-touch, PR #199) and CODE-02-06 (viewport pointer + modal recovery, PR #175).

**Base SHA:** 17cf9d913f51921206765017d87b91d9bde083bf

## Scope of this change

The 2026-10-27 owner phone-QA reported four regressions:

1. touch+mouse swipe not working on iPhone and desktop — already fixed by CODE-02-06 (real Viewport dispatch, dual GUI/global pointer ownership) and CODE-02-01 (cancelled-touch discard).
2. hint visually highlighting only one tile instead of two — the hint *index* path already returns and stores two tiles, but the two hinted tiles shared the **same cream border as the tap-selection**, so the hint was visually indistinguishable from a single selection. Fixed here.
3. 'Как играть' opening an inline accordion instead of a modal — already fixed by CODE-02-06 (AcceptDialog modal; legacy inline `help_panel` kept hidden).
4. overall presentation diverges from UPDS — the hint presentation parity gap is closed here; full polished help overlay and art remain GAME-M3-01/GFX scope.

This change is therefore the minimal remaining fix: make the two hinted tiles visibly distinct (UPDS teal glow + white-gold inner ring) from the gold tap-selection, plus targeted smoke coverage.

## UPDS-first reuse decision

**Donor:** `bezdredoff/UPDS-godot@3deed628efd6c22bcd1717f7c545b7d3ca865781` (local donor checkout `C:/Users/bezdr/Downloads/godot-upds`).

- `scripts/match3/match3_screen.gd` blob `76b42df35d4857f242d3f6bc06b9f989d43ad0a3` — inspected `_render_board` (hinted style: teal `#7ddfd8` border 3px + teal glow `shadow_size 15`, distinct from gold `#fff2a8` selection), `HintInnerRing` (white-gold `#fff8d7` 2px inner ring, `z_index 20`), and `_show_hint`/`_reveal_hint` (`hinted_indices = [int(hint.first), int(hint.second)]`).
- `scripts/match3/match3_help_overlay.gd` blob `af3921c745f557131667c2dcd60bca10404a15d3` — read-only reference (parchment modal with backdrop/tab/sections); the current Raven `AcceptDialog` modal is retained (full polished overlay remains GAME-M3-01 scope, per CODE-02-06 evidence).

**Decision: adapter.** The distinct hint visual is adapted into the existing Raven `match3_board_presenter.gd` (`_build` + `_paint_selection`) rather than adding a second rules/rendering engine. No donor art/fonts imported; the donor's looping hint pulse animation is deferred (motion polish, GFX-10-06 scope) — a static teal glow + inner ring is sufficient for two-tile visibility.

Changes:

- `scripts/match3/match3_board_presenter.gd`
  - `_build`: each cell now carries a `HintRing` `Panel` (white-gold `#fff8d7`, 2px, `z_index 20`, hidden by default, `MOUSE_FILTER_IGNORE`).
  - `_paint_selection`: split the single `chosen` style into `selected` (gold `#f5e8c8`, 5px, lightened) vs `hinted` (teal `#7ddfd8`, 3px, teal glow `shadow_size 15`) vs blocker/neutral (unchanged). Hides/shows `HintRing` per `highlighted`. `highlighted` continues to serve both the persistent hint and the live drag preview (both are "would-swap" indicators, matching UPDS semantics).
- `tests/raven/match3_viewport_input_smoke.gd` (extended): after `show_hint()`, asserts both hinted tiles use the teal border + glow + visible `HintRing`, and a neutral tile uses no hint decoration.

Verification:

- `READ_ONLY`: `data/raven/production/progress/match3.json` entry CODE-02-03 (pre-fix evidence), root/`scripts/match3`/`scripts/raven` AGENTS, orchestration + data-contracts + CODE-02-06 QA docs, donor `match3_screen.gd`/`match3_help_overlay.gd`.
- `EXECUTED_PASS`: `godot --headless --path . --editor --quit` (asset import).
- `EXECUTED_PASS`: `res://tests/raven/match3_viewport_input_smoke.gd` — "Raven Match-3 viewport pointer and modal smoke passed" (includes new two-tile hint visual assertions).
- `EXECUTED_PASS`: `res://tests/raven/upds_match3_presentation_states_smoke.gd` — blocker-marker retention after hint unchanged.
- `EXECUTED_PASS`: `match3_upds_shell_smoke.gd`, `upds_match3_interactive_board_smoke.gd`, `upds_match3_visual_primitives_smoke.gd`, `upds_match3_mobile_hud_smoke.gd`, `match3_checkpoint_smoke.gd`, `content_preview_match3_qa_smoke.gd`, `main_menu_match3_campaign_smoke.gd`, `match3_session_smoke.gd`, `match3_booster_ui_smoke.gd`, `game_loop_characterization_smoke.gd`, `vertical_slice_smoke.gd`.
- `EXECUTED_PASS`: full project check via `check.ps1 -GodotPath <console exe>` — all data/governance audits (progress shards, backlog, dependencies, workstreams, acceptance) and 81 Godot smoke stages pass, including `Match-3 viewport pointer and modal passed`.
- `NOT_RUN` as-is: `bash scripts/check.sh` is environment-blocked on this host — the native Windows `python3`/Godot binaries cannot resolve the git-bash POSIX `$ROOT` path (`Invalid project path ... /c/Users/...`). The equivalent `check.ps1` (Windows-native paths) was run instead and passes.
- Note: the first `check.ps1` attempt failed at `vn_studio_migration_smoke.gd` because a prior session left a deterministic export bundle under `user://vn_studio_conversions/...` (dated 2026-11-05, unrelated to Match-3). After removing that stale bundle the full check passed.

Owner QA: Not claimed. This is a presentation-only fix with automated smoke coverage. Physical iPhone/desktop browser swipe, two-tile hint legibility and the full UPDS help overlay still require owner/device QA. CODE-02-03 remains non-accepted.

Status impact: CODE-02-03 -> PR_review in the match3 shard (evidence appended; qaState automated; approvalState pending).

## Rollback

Revert this commit. No data migration, no new assets, no schema/save change.
