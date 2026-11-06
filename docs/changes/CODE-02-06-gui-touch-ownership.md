# CODE-02-06 — Direct tile GUI touch ownership after compatibility mouse press

Task IDs: CODE-02-06 (P0, partial Match-3 input and UI parity); related CODE-02-01 (P1, earlier cancelled touch work already merged).

Changes: align Raven direct tile GUI pointer acquisition with the already-established viewport _input touch-over-mouse priority; add a regression for browser compatibility mouse, multitouch, genuine touch swipe, trailing mouse and normal desktop mouse. Only the presenter, its existing Match-3 test, owning status shard and this unique change record are modified.

Verification: source and donor read-only comparison completed. Local Godot executable NOT_AVAILABLE; local Godot runtime tests NOT_RUN. Required headless Viewport/ScrollContainer smoke and full scripts/check.sh must pass on exact PR head in GitHub Actions before merge. Physical device/browser QA NOT_RUN.

Owner QA: verify a real swipe on mobile Web after emulated mouse events, second finger non-ownership, only one move per swipe, unblocked desktop mouse click/swipe, and Help/Hint after gesture cancellation. RU/EN/BE, reduced motion, and 320/340/360/390/430-px physical presentation are not certified by this slice.

Status impact: CODE-02-06 remains P0, implementationState partial, approval pending. Merged #208 is reconciled to its verified merge commit and CI in the match3 shard; review/merge/device approval for this follow-up is separately tracked.

## Fresh baseline and ownership
- Raven: `bezdredoff/RavenManor-Godot@f79e2097787ed3bde14236fd2e475ab1e12ee519`, 2026-11-06; open PRs checked: none before creating branch.
- Branch: `agent/match3/CODE-02-06-gui-touch-ownership`, owner: `match3`.
- Write allowlist: `scripts/match3/match3_board_presenter.gd`, `tests/raven/match3_viewport_input_smoke.gd`, `data/raven/production/progress/match3.json`, `docs/changes/CODE-02-06-gui-touch-ownership.md`.
- Read only: UPDS donor, Raven shared engine, VN, Hall, Room Builder, other task shards. Absolutely no new save/reducer/IDs/art or `vertical_slice.gd` changes.

## UPDS-first reuse decision
- Native donor: `bezdredoff/UPDS-godot@3deed628efd6c22bcd1717f7c545b7d3ca865781`.
- Source: `scripts/match3/match3_screen.gd`, Git blob `76b42df35d4857f242d3f6bc06b9f989d43ad0a3`; relevant functions `_on_tile_gui_input`, `_tile_event_position`, `_begin_tile_drag`, `_end_tile_drag`.
- UPDS donor owns the core gesture contract/board and does **not** cover mixed mouse-compatibility/touch ownership in Raven's dual `_input` and `_on_cell_gui_input` dispatch. Raven `_input` already treats a real touch press as authoritative after an earlier compatibility mouse press (#177).
- Decision: **adapter**. Reuse the existing Raven `_cancel_gesture()`, `_last_touch_ms`, direct tile input and donor-derived `Drag.target_for_drag` without importing another controller or modifying `scripts/shared/upds/`.

## Repro / expected behavior
1. Synthesize a GUI left-button press on a legal hinted tile; old code owns `mouse`.
2. Deliver an actual touch press on the tile without a mouse release. **Before this PR**, old direct GUI code ignores the touch because `_gesture_index >= 0`. After this PR, `touch` replaces `mouse` and owns finger index 17.
3. Deliver the trailing compatibility mouse release, then a different-finger release. Both must leave touch ownership unchanged and spend zero moves.
4. Release the real finger across the legal hinted pair: exactly one move. A subsequent compatibility mouse event must not create a second gesture.
5. Reset the synthetic suppression timestamp and verify direct mouse press-and-swipe still commits a legal move.

## Verification commands
- `godot --headless --path . --script res://tests/raven/match3_viewport_input_smoke.gd --quit-after 240`
- `bash scripts/check.sh` (all blocking functional tests)
- `python3 scripts/raven/tools/progress_shards.py` and `python3 scripts/raven/tools/build_production_dashboard.py --check`
- Exact-head GitHub Actions jobs: `data-contracts`, `godot-runtime`, `room-builder`, `art-pipeline`, `web-package`, `build`.

## Risks / rollback
- Event ordering differs across browser versions and mobile OSs; this test simulates valid GUI callbacks, not physical input.
- Desktop mouse suppression applies only for the same existing 650-ms window used by the viewport path.
- Revert this one PR without altering saved games; no schema migration or state data changes.
