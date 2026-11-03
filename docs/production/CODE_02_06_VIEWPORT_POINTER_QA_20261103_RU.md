# CODE-02-06 · pointer ownership and modal dismissal

Baseline Raven `913b9cd`; donor `bezdredoff/UPDS-godot@3deed628efd6c22bcd1717f7c545b7d3ca865781`.

## Reuse and exact sources

- `scripts/match3/match3_screen.gd`, blob `76b42df35d4857f242d3f6bc06b9f989d43ad0a3`: `_on_tile_gui_input`, `_tile_event_position`, `_begin_tile_drag`, `_end_tile_drag`, `_show_help` inspected. Reuse existing extracted drag rules/engine/presenter; harden Raven's dual GUI/global pointer adapter without introducing a second rules engine.
- `scripts/match3/match3_help_overlay.gd`, blob `af3921c745f557131667c2dcd60bca10404a15d3`: inspected `closed`, backdrop and modal input blocking. Current Raven AcceptDialog adapter retained; donor depends on fonts, direction marker and asset catalogue. No donor icons/art/fonts imported. Full polished donor overlay remains future GAME-M3-01 scope.

## Fixes

AcceptDialog confirmed/window-close wiring missed Esc/cancel and programmatic hide. Visibility now owns transient Help state. Direct cell events lacked the common handler's emulated-mouse suppression and finger ID check. Hidden presenters could receive global input; visibility now cancels stale gestures and closes Help.

No campaign/save/economy/level changes. Regression uses an isolated copy of the level with a high objective so two successful moves cannot prematurely win. No synthetic completion/asset acceptance.

## Actual verification

`godot --headless --path . --script res://tests/raven/match3_viewport_input_smoke.gd` PASS on Godot 4.7.2: Viewport dispatch inside ScrollContainer, real mouse/touch swipe routes, two-cell hint with unchanged moves, modal lock and stable layout, cancel/hide recovery, second-finger rejection, touch/mouse duplication and hidden view. Native render run and full checks are recorded in subsequent PR/status evidence.

Physical phone/browser QA and full UPDS visual parity remain pending. A headless Viewport is stronger than direct handler calls but is not evidence of browser hit-testing or actual finger hardware.

Rollback: revert this PR; no data migration or new assets. CODE-02-06 remains partial until deployed browser/device acceptance.
