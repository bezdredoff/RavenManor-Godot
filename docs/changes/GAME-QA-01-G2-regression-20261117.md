# GAME-QA-01 — G2 regression and release acceptance readiness (2026-11-17)

Task IDs: GAME-QA-01; related GAME-LOOP-01, GAME-LOOP-01A, CODE-10-01, CODE-11-01, GFX-11-T09.
Changes: Reconcile merged #267; retain G1–G4 release gate and all functional checks; add missing Windows G2 runner parity and require exact-once registered critical suites; clarify shipped Pages packaging vs actual browser boot.
Verification: Audited main `0d1886b0d01491047dbd900b260757623c6ef9bc` (run [43974385365](https://github.com/bezdredoff/RavenManor-Godot/actions/runs/43974385365) SUCCESS). PR #276 first exact head `6ba1d3ae46b399af71228174b852fc2e0a786f59`: [run 43981227524](https://github.com/bezdredoff/RavenManor-Godot/actions/runs/43981227524) **SUCCESS** (data-contracts, godot-runtime, room-builder, art-pipeline, web-package, build). Evidence-only follow-up final-head CI pending; no local Godot/PowerShell or live browser execution asserted.
Owner QA: Windows desktop, real Web and physical phone NOT_RUN; owner acceptance PENDING; HC/CB production geometry and future Agent B/D handoffs remain BLOCKED.
Status impact: GAME-QA-01 remains partial and approvalState=pending in qa-infrastructure only; #267 MERGED, new QA follow-up review pending. This document does not approve content, art, doors or launch.

## Scope and previously merged baseline

- Merged #267 introduced `docs/changes/GAME-QA-01-release-gate.md`, `test_game_qa_release_gate.py` and its data-runner registration; **do not repeat or erase that baseline**. Its own final exact-head run [43964409306](https://github.com/bezdredoff/RavenManor-Godot/actions/runs/43964409306) passed all six jobs.
- Merged #271 covers canonical VN JSON ordinals and snapshot gates; merged #274 covers Evelyn atlas/preview (not the gameplay actor switch). At audited main `0d1886b0d01491047dbd900b260757623c6ef9bc`, all six CI jobs and Pages deployment succeeded: [43974385365](https://github.com/bezdredoff/RavenManor-Godot/actions/runs/43974385365).
- Existing `game_loop_01a_hotspot_bridge_smoke.gd` already verifies fail-closed source selection, denied speculative click, physically confirmed segments, availability recheck, paused/cancelled requests, safe-anchor fallback, once-only restoration/rewards, failed store writes and reloading. Existing `map_game_01a_navigation_source_smoke.gd` asserts unapproved geometry is unavailable and approved fixtures can be routed. Existing `session_lifecycle_e2e_smoke.gd` tests Continue, VN cursor, Match-3 checkpoint, failed write/reset and corrupt recovery. These remain source-backed test fixtures, not approval of a production map.
- The narrower change here registers **nine existing, previously absent Windows invocations** and makes all relevant G2 smoke registrations exactly-once blocking in both runners. No game implementation or new story source is added. UPDS-first: reuse the existing Raven/UPDS behavioral parity suites (`main_menu_upds_parity`, VN shell/read history, Match-3/session); no donor code or second save logic imported.

## Explicit acceptance matrix

**Evidence vocabulary:** REGISTERED means an executable check exists and is blocking (not a claim it ran at this PR head); PASS requires actual run/commit URL; NOT_RUN means no direct execution; BLOCKED means a known missing production dependency; OWNER_PASS requires recorded human review. Every automated item below is registered in `scripts/check.sh`; after this PR, the core G2 set is also in `check.ps1`. Future unmet G2 acceptance does not fail functional CI.

| Gate / existing ID | Executable regression or human command | Acceptance criterion | Baseline evidence / remaining gate | Owner |
| --- | --- | --- | --- | --- |
| G1 / GAME-LOOP-01A | `map_game_01a_navigation_source_smoke.gd`, `game_loop_01a_hotspot_bridge_smoke.gd` | Default production geometry fails closed; QA requires opt-in; no free tap | REGISTERED / main CI PASS on fixture; real HC/CB BLOCKED | B / A |
| G2 / GAME-LOOP-01 | `manor_navigation_graph_smoke.gd`, `map_qa_06_room_transitions_smoke.gd`, `map_qa_07b_integrated_first_floor_smoke.gd` | Authored legs, threshold/return anchors, locked doors; no teleport | REGISTERED / fixture-only; approved HC/CB physical acceptance BLOCKED | A / owner |
| G2 / GAME-LOOP-01A | `game_loop_01a_hotspot_bridge_smoke.gd` | Speculative click cannot fire action; route arrival revalidates availability | REGISTERED / fixture CI PASS | B |
| G2 / GAME-LOOP-01A | `game_loop_01a_hotspot_bridge_smoke.gd`, `game_pause_smoke.gd` | Duplicate input/ack cannot duplicate rewards; pause/resume/cancel respects safe checkpoint | REGISTERED / fixture CI PASS | B |
| G2 / CODE-11-01 | `session_lifecycle_e2e_smoke.gd`, `main_menu_upds_parity_smoke.gd` | New Game/Continue, save/reload, failed write and corrupt recovery | REGISTERED / existing vertical-slice parity; gameplay room restore after B merge BLOCKED | B |
| G2 / GAME-LOOP-01 | `game_loop_characterization_smoke.gd`, `restoration_restore_smoke.gd`, `match3_session_smoke.gd` | Exactly-once reward/restoration; no second reducer/store | REGISTERED / fixture CI PASS | B |
| G2 / GAME-LOOP-01 | `main_menu_match3_campaign_smoke.gd`; **new standalone Agent B smoke after merge** | Existing optional Match-3 menu route works; new menu→G2 gameplay host and Continue go to restored anchor | Existing route REGISTERED; new G2 route BLOCKED until Agent B code/test merges | B → QA |
| G2 / GFX-11-T09 | `bake_atlas.gd -- --check`, `preview_smoke.gd`; **Agent D active-actor smoke after merge** | Evelyn pixels/animation reproducible; gameplay map actor is Evelyn not Onoe | Bake/preview REGISTERED; production actor selection BLOCKED until Agent D merge; phone readability NOT_RUN | D → QA / owner |
| G2 / CODE-07-02 | `match3_checkpoint_smoke.gd`, `match3_viewport_input_smoke.gd`, `match3_session_smoke.gd` | No duplicate first-clear/reward, retry/reset and pointer input behave | REGISTERED / main CI PASS | B / QA |
| G3 / CODE-03-03 | `vn_locale_save_parity_smoke.gd`, `vn_english_localization_smoke.gd`, `vn_belarusian_localization_smoke.gd` | RU/BE/EN scenes, persisted language and line cursor | REGISTERED / fixture CI PASS; owner proofreading NOT_RUN | C / owner |
| G3 / CODE-08-01 | `vn_production_runtime_dispatch_smoke.gd`, `vn_read_skip_smoke.gd`, `campaign_season1_audit_smoke.gd` | Approved-only scene dispatch, read-only Skip, no fabricated Season 1 execution | REGISTERED / full 27-scene sequence BLOCKED | C / owner |
| G4 / CODE-10-01 | `device_matrix_reachability_smoke.gd`, `vn_shell_safe_area_smoke.gd`, `upds_match3_mobile_hud_smoke.gd` | 320×568 / 390×844 / 430×932 controls reachable, portrait HUD and VN safe area | Headless fixture REGISTERED; native touch/safe-area OWNER_PASS NOT_RUN | QA / owner |
| G4 / PROC-008 | `.github/workflows/pages.yml` export/build jobs + `test_pages_packages_the_shipped_game_not_just_dashboard` | Build contains actual `index.html`, `index.wasm`, `index.pck` and deploy job | Static packaging CI PASS on main; **not browser runtime proof**; live Pages boot/refresh/offline NOT_RUN | QA / owner |
| G4 / GAME-QA-01 | Windows + Web + physical-device checklist below; exact-head CI | Every criterion documented with device/version, SHA, console, screenshot and recovery | NOT_RUN / owner release sign-off PENDING | Owner |

## Commands and run evidence

- Python contract: `python3 -m unittest discover -s tests/raven -p 'test_game_qa_release_gate.py' -v`.
- Linux full functional+data checks: `bash scripts/check_data.sh && bash scripts/check.sh` with Godot **4.7.2** on PATH (in CI data and runtime jobs may run independently with `RAVEN_SKIP_DATA_CHECKS=1 bash scripts/check.sh`).
- Single Godot smoke (replace filename with any row above): `godot --headless --path . --script res://tests/raven/game_loop_01a_hotspot_bridge_smoke.gd --quit-after 240`.
- Windows local: `py -m unittest discover -s tests/raven -p test_game_qa_release_gate.py -v`; then `.\check.ps1 -GodotPath 'C:\Path\To\Godot_v4.7.2-stable_win64_console.exe'`.
- Existing release baseline: [main run 43974385365](https://github.com/bezdredoff/RavenManor-Godot/actions/runs/43974385365) SUCCESS at `0d1886b0d01491047dbd900b260757623c6ef9bc`. PR #276 [run 43981227524](https://github.com/bezdredoff/RavenManor-Godot/actions/runs/43981227524) **SUCCESS on head `6ba1d3ae46b399af71228174b852fc2e0a786f59`** (all six checks). Final evidence-update head CI must also succeed; record final link on PR after it completes. No local Godot/Windows/browser/phone run was performed in this authoring session.
- Required final PR acceptance: six required jobs (`data-contracts`, `godot-runtime`, `room-builder`, `art-pipeline`, `web-package`, `build`) all SUCCESS on the exact PR-head SHA; do not infer from a prior run.

## Manual acceptance — reproducible checklist

- [ ] **Windows desktop (owner):** fresh isolated Godot user-data profile; New Game → menu → G2 gameplay host (once B lands), navigate Hall→Corridor→Bedroom→Corridor→Hall on **approved** HC/CB; click a hotspot while locked or too far away, then repeat after authorized arrival. Check pause/resume/cancel and no free tap; take start/arrival/locked-state screenshots, engine output, version, PR SHA.
- [ ] **Windows save/Continue (owner):** back up the `user://` campaign file/key `raven-manor-campaign-v1` and recovery value `raven-manor-campaign-v1:recovery-v1` before tests. Save in Bedroom safe anchor, fully close, restart Continue; verify room/actor/anchor and rewards unchanged. Exercise a corrupt **copy in an isolated profile only** and verify recovery prompt/back-up. Never overwrite an owner's live save. Capture pre/post snapshots with sensitive paths redacted.
- [ ] **Desktop browser / Pages (owner):** load the actual production Pages **game entrypoint**, not `/dashboard/`, in normal and private windows. Verify real canvas/menu, New Game, VN, Match-3, sound user gesture, Continue, refresh, network offline/online, cache restart. Capture browser URL, screenshot, Console and Network (failed .wasm/.pck/JS requests, 404/COOP/COEP), browser version, SHA and Pages Actions run. Only checking exported files is insufficient. **NOT_RUN**.
- [ ] **Real portrait phone (owner):** at relevant 320×568, 390×844 and 430×932 viewports and available physical phones, test RU/BE/EN, safe-area/notch, settings, reduced motion, portrait VN, Skip/choices, Match-3 swipe/hint/retry, hotspot reachability, background/resume and touchscreen scrolling. Screenshot each tested configuration and record device model, OS, browser, resolution and orientation. Headless width emulation does not equal physical-phone PASS. **NOT_RUN**.
- [ ] **Cross-device regression (owner):** Evelyn idle/walk/cancel visible without Onoe replacement, consistent foot placement at HC/CB thresholds, room occlusion, no clipping; check FPS and reduced motion on real phone after Agent D merge. **BLOCKED/NOT_RUN**.
- [ ] **Post-test recovery (owner):** record SHA/build/device; stop game, restore backed-up isolated test-save (or delete only the disposable profile), restart; confirm normal Continue. Attach console log + screenshots + test-save recovery result to PR/QA evidence. Leave original player save untouched.

## Pages browser smoke classification

`pages.yml` currently exports a Godot Web release, verifies three artifacts, builds the dashboard and uploads/deploys Pages on `main`. No workflow step launches the exported **game in a browser**, confirms Godot's loaded scene or exercises persistence. Browser-smoke jobs for Room Builder/art-handbook/dashboard do **not** certify the shipped gameplay entrypoint. The new Python test protects only packaging contracts. Live engine initialization, CORS/isolation, cache/service-worker and save semantics remain explicit **NOT_RUN** manual checks until a separately coordinated browser harness/deployment validation exists. Do not weaken functional CI or modify workflows to pretend this is covered.

## Parallel merge window / no future-feature breakage

QA is sole writer of runner registration. Agents B/C/D provide standalone test paths, expected success output and exact commands. QA registers those tests only after their implementation is merged on main (or a coordinated integration window); unmerged code is never preloaded. Agent A/owner must approve HC/CB geometry before production route is asserted. Current tests remain blocking; absent future G2 product criteria remain BLOCKED in this matrix, not an artificial CI failure. No changes to gameplay runtime, approved geometry/art, catalogs, reducer/store, project.godot or workflows.

## PR #276 run results and traceability

- First exact PR head: `6ba1d3ae46b399af71228174b852fc2e0a786f59`; [Actions 43981227524](https://github.com/bezdredoff/RavenManor-Godot/actions/runs/43981227524) **SUCCESS** — `data-contracts`, `godot-runtime`, `room-builder`, `art-pipeline`, `web-package`, aggregate `build` all completed successfully. `deploy` correctly SKIPPED on a PR.
- This is real GitHub CI execution of Godot and Python tests, **not** a claim that local Windows, live browser or phone tests ran. The final evidence-only commit requires its own exact-head run; link to be recorded on PR without another code change.

## Owner QA and status impact

Previous #267 = MERGED/CI-PASSED, while GAME-QA-01 parent = **partial**, QA automated and owner/device approval **pending**. This bounded PR adds test runner parity, not acceptance of the game. After exact-head CI, record the new link and SHA; after real owner checks, reconcile the QA shard separately using evidence.
