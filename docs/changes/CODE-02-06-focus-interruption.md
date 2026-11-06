# CODE-02-06 — cancel in-flight Match-3 gestures on app/window focus loss

Task IDs: CODE-02-06 (P0, targeted incomplete input sub-slice).

Changes: cancel active swipe ownership on window focus loss or app pause; extend the existing real Viewport/ScrollContainer regression without touching UPDS game rules.

Verification: Godot not installed locally (NOT_RUN); exact-head GitHub Actions mandatory CI pending after correcting change-record format. Simulated focus/pause does not constitute real-device QA.

Owner QA: pending browser and physical mobile interrupted-swipe checks.

Status impact: CODE-02-06 remains P0, partial, PR_review for https://github.com/bezdredoff/RavenManor-Godot/pull/208; owner acceptance still pending.

## Task IDs
- `CODE-02-06` (P0 broad Match-3 input/UI parity, still **partial**).
- Related `CODE-02-01` (P1; #199 already fixed canceled `InputEventScreenTouch` releases; **not duplicated**).

## Baseline / scope
- Raven `main`: `ff8760946da7bc3b0250eac1dbaad37d8b832abb` (2026-11-06); open PRs checked: none before branching.
- Branch: `agent/match3/CODE-02-06-focus-interruption`.
- Exact writable files: `scripts/match3/match3_board_presenter.gd`, `tests/raven/match3_viewport_input_smoke.gd`, `data/raven/production/progress/match3.json`, and this unique change record.
- Excluded: UPDS shared engine, Raven reducers/store/snapshots, canonical IDs, workflows, vertical slice, Hall/VN/editor files, art.

## UPDS-first decision
- Native donor `bezdredoff/UPDS-godot@3deed628efd6c22bcd1717f7c545b7d3ca865781`:
  `scripts/match3/match3_screen.gd`, blob `76b42df35d4857f242d3f6bc06b9f989d43ad0a3`,
  functions `_on_tile_gui_input`, `_begin_tile_drag`, `_update_tile_drag`, `_end_tile_drag`.
- The proven donor drag thresholds and board engine are already reused by Raven
  `match3_drag_model.gd` and `scripts/shared/upds/match3_game.gd`.
- Donor's tile-level drag handler does not implement a portable interruption
  callback for Raven's mixed `_input` + tile GUI routing. Decision: **adapter**,
  reuse Raven's existing `_cancel_gesture()`; do not clone donor input or engine.
- Existing #175/#177 fixes modal/dual-pointer input; #199 handles explicitly
  canceled touch events. This slice handles **lost release due to window defocus
  or app pause** without changing regular touch/mouse/swipe semantics.

## Changes
- Subscribe the board to its `Window.focus_exited` signal when ready.
- On app pause or application focus-out notification, discard only an active
  gesture through the existing cancellation function.
- Clear pointer ownership and preview without consuming moves, granting rewards,
  saving game state, changing selection modes or moving tiles.
- Exercise focus loss and application pause in the existing real
  `Viewport.push_input` + `ScrollContainer` smoke, including late release
  rejection and fresh swipe recovery.

## Verification
- Source-level review: **completed** against the pinned donor and current Raven.
- Regression: `godot --headless --path . --script res://tests/raven/match3_viewport_input_smoke.gd --quit-after 240`.
- Full required suite: `bash scripts/check.sh`.
- On this agent's runtime, the Godot executable is **not installed**;
  tests above are **NOT_RUN locally**. GitHub Actions must establish
  exact-head `data-contracts`, `godot-runtime`, `room-builder`,
  `art-pipeline`, `web-package`, and aggregate `build` before merge.
- Simulated signals in a headless viewport are **not** physical OS/device QA.

## Owner QA (pending)
1. On a phone, begin a Match-3 swipe; switch to another app/lock screen, then
   return and release. Confirm **no ghost move** and no lingering highlight.
2. Make a new swipe. Confirm exactly one legal move.
3. Check browser tab defocus/refocus on desktop; verify that Hint, Help, mouse
   swipe and a fresh touch swipe still behave correctly.
4. Repeat on at least one mobile width (320/340/360/390/430 px).
- Owner/device/art approval: **pending**.

## Status impact
Only `progress/match3.json` evidence is appended; `CODE-02-06` remains
`P0`, `partial` and unaccepted. A PR review is not a merged or
owner-accepted delivery.
