Task IDs: GAME-LOOP-01, PROC-006
Changes: Extract optional Match-3 level listing/unlock/status display, localized return button and step descriptors into read-only raven_optional_campaign_controller.gd. Current vertical_slice keeps game lifecycle/Reducer/save control; zero save schema/content/art changes.
Verification: Add independent controller headless Godot smoke (22 levels, unlocking, callbacks, menu locales and all-complete), register with scripts/check.sh and parse checks, retain main_menu_match3_campaign_smoke and game_loop_characterization_smoke. Exact-head GitHub CI pending.
Owner QA: No new owner/device acceptance; manual GAME-QA-01 remains pending. Full gameplay/scene lifecycle unchanged.
Status impact: GAME-LOOP-01 remains open until complete integrated gameplay acceptance, this is a behavior-preserving R2a extraction. Central status reconciliation follows merge.
