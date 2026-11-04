Task IDs: GAME-LOOP-01, PROC-006
Changes: Extract Match-3 session instantiation, checkpoint replay, booster spending through RavenReducer, atomic level reward/checkpoint commit, and save-failure board rollback into raven_match3_session.gd. Vertical slice retains UI/audio/navigation and event serial. No asset/content/save schema modifications.
Verification: New isolated Godot session smoke for checkpoint, replay, failed-write rollback, first-clear reward, optional reward isolation, booster inventory + schema v1. Existing game_loop_characterization, match3_checkpoint, session_lifecycle_e2e, and optional campaign tests remain mandatory. Exact-head CI to run.
Owner QA: Physical mobile/desktop UI and audio QA not done. GAME-QA-01 remains open, not owner-accepted.
Status impact: R2b partial code isolation only; GAME-LOOP-01 remains open, canonical status to be reconciled by integration owner after merge.
