Task IDs: GAME-LOOP-01, GAME-QA-01
Changes: Add a runtime characterization smoke for story Match-3 win, failed reward/checkpoint save rollback, retry, restoration, booster grant, VN resume and optional campaign non-progression; register it in the full blocking Raven check.
Verification: New test is executed by scripts/check.sh in GitHub CI; exact-head results pending when authored. Existing test coverage inspected: vertical_slice_smoke, session_lifecycle_e2e_smoke, match3_checkpoint_smoke and main_menu_match3_campaign_smoke.
Owner QA: Automated characterization only. Manual mobile gameplay, animation, sound, Hall geometry, difficulty/balance and end-to-end acceptance remain pending under GAME-QA-01.
Status impact: No implementation or accepted-status claims; GAME-LOOP-01/GAME-QA-01 remain open. No game logic, save schema, source art or asset approval changes in this PR.
