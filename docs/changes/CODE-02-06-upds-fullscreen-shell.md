# CODE-02-06 — Native UPDS full-screen Match-3 layout adapter

Task IDs: CODE-02-06 (P0, scoped visual/UI parity implementation).

Changes: replace the technical-shell presentation of real story/optional Match-3 with a full-screen 430x932 phone-first layout: 60px burgundy/coral header, title and back/help/settings, separate cream-bordered Goal/Moves cards, centered navy/cream board frame, parchment bark tray, read-only Raven booster controls and bottom Hint/FX/Retry. Reparent existing presenter widgets; no duplicate Match-3 game/session/controller or reward logic.

Verification: donor and Raven source compared; local Godot executable unavailable, tests NOT_RUN locally. Requires exact-head all six blocking CI jobs and Godot screen route, viewport, state and board smoke PASS. Manual screenshot/device QA NOT_RUN, so no claim of pixel-perfect or physical parity.

Owner QA: on desktop and 320/340/360/390/430px phone screenshot compare UPDS original and Raven frame: 60px header, HUD order, board center and no horizontal scrolling, bottom bark/action, full-screen (no technical footer), help from header, settings/pause, hint and motion, boosters and loss retry. Verify one move per swipe/touch, no ghost moves, special/blocker readability, RU/BE/EN text and reduced motion.

Status impact: CODE-02-06 remains P0, partial and not owner/device approved. This stacked PR depends on #222 shared-shell locale integration merging first; do not merge out of order.

## Branch and exact boundaries
- Raven stack base: integration/CODE-02-06-campaign-status-locale at 2d420e7bf5131a3abbeec2c1f1829392c49d5e93 (PR #222; latest head CI success).
- Branch: integration/CODE-02-06-upds-match3-screen-shell. Open this as stacked PR against the #222 branch, not main.
- Paths: scripts/match3/match3_screen_shell.gd, scripts/match3/match3_board_presenter.gd, integration-owned scripts/raven/vertical_slice.gd, tests/raven/main_menu_match3_campaign_smoke.gd, tests/raven/match3_upds_shell_smoke.gd, data/raven/production/progress/match3.json and this note.
- Explicitly excluded: shared UPDS engine, raven reducer/campaign store/snapshot, stable RM IDs, art assets, narrative, VN Studio, Hall, project.godot or GitHub workflows.

## UPDS-first reuse classification
- Native source: bezdredoff/UPDS-godot@3deed628efd6c22bcd1717f7c545b7d3ca865781, scripts/match3/match3_screen.gd blob 76b42df35d4857f242d3f6bc06b9f989d43ad0a3.
- _ready() builds a 60px plum/coral header, title, back/help/settings, Goal and Moves parchment HUD cards, centered outlined navy board, bark tray and separate action controls.
- _fit_match3_hud_geometry/_fit_board_cells handle 320–430px widths; our existing match3_mobile_layout.gd and presenter apply_available_width remain canonical for Raven portrait reflow.
- Decision: **adapter**. Reuse existing Raven Match3Board, UPDS board-shape, donor mechanics/frame FX and Help/hint, preserve Raven theme/images/boosters and only translate shell structure/styles. Do NOT copy donor story, classroom assets, save/session, settings autoloads or Playgama-specific ads.
- Donor font/shaders and multi-stage tutorial/animated end-card may need later separately reviewed parity slices; this PR does not assert screenshot/pixel or device acceptance.

## Reflow and input
- Donor PhoneFrame caps screen to 430×932, centered on desktop. The new Match-3 frame uses exactly that sizing, independent of diagnostic UI.
- Width policy: available_board_width(frame_width) = max(1, frame_width-36), accounting for 12px page gutters plus board-frame border/insets. Board's resize callback still owns tile-size updates; no hard-coded 354px minimum.
- Reparent objective, hint, Help, retry, motion and feedback from the existing Board view, do not wire second event handlers; only the full-screen shell opts into separately rendered Goal and Moves counters.
- Story-gate/bonus-level routing, checkpoint, first-clear, booster inventory, save revisions and navigation remain owned by Raven reducer/store/session. Back in Match-3 opens existing save/exit pause, not an unapproved bypass of story gates.

## Verify / rollback
- godot --headless --path . --script res://tests/raven/match3_upds_shell_smoke.gd --quit-after 180
- godot --headless --path . --script res://tests/raven/main_menu_match3_campaign_smoke.gd --quit-after 180
- bash scripts/check.sh and six mandatory exact-head GitHub CI jobs.
- Rollback this UI-only PR; no save schema migration. After #222 merges, retarget stacked PR to main before final review.
