Task IDs: GAME-LOOP-01, PROC-006
Changes: Extract Match-3 booster bar, RU/BE/EN copy, disabled/enabled restoration gates, selection label and target hint from vertical_slice.gd into read-only raven_match3_booster_ui.gd. Keep exact button node names, layout/labels/callbacks, save schema and UPDS reuse. No transaction logic changes.
Verification: Added match3_booster_ui_smoke.gd (inventory, gating, locale, callback and no mutation), wired into blocking scripts/check.sh and parse. Existing game_loop_characterization, match3_session, viewport, menu and Match-3 smoke remain mandatory. Exact-head GitHub CI pending.
Owner QA: No physical-device or owner acceptance; GAME-QA-01 remains open.
Status impact: GAME-LOOP-01 still open pending integrated player acceptance. Post-merge status reconciler may record merged R2c without marking GAME-LOOP-01 accepted.
