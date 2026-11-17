# GAME-QA-01 — G2 post-merge regression/acceptance reconciliation (2026-11-17)

Task IDs: GAME-QA-01 (P1); related GAME-LOOP-01, GAME-LOOP-01A, CODE-05-02, CODE-08-01, CODE-10-01, CODE-11-01, GFX-07-01 and GFX-11-T09.
Changes: No duplicate gameplay or tests. Reconcile merged QA #267/#276 and integrated #280 in the owning qa-infrastructure progress shard, preserving partial implementation and pending human/device approval.
Verification: Exact main `ddcc8a646ffbfa60dcfea43849a592bfdddd9f24`, [Actions 44073202009](https://github.com/bezdredoff/RavenManor-Godot/actions/runs/44073202009) SUCCESS including Pages deploy; Godot job log explicitly confirms GFX-07-01 gameplay-host, CODE-05-02/09D HC/CB, and GAME-LOOP-01 G2 host/Continue PASS. Prior exact PR-head runs: #276 [43981606512](https://github.com/bezdredoff/RavenManor-Godot/actions/runs/43981606512) SUCCESS and #280 [44072750669](https://github.com/bezdredoff/RavenManor-Godot/actions/runs/44072750669) SUCCESS. Local Godot, PowerShell, physical browser and phone were NOT_RUN in this reconciliation.
Owner QA: Windows, live deployed Pages game startup/offline/refresh and physical portrait phone NOT_RUN. HC/CB design positions are owner-approved (RM-DEC-030), but physical painted opening/collision/occlusion and production activation are not accepted. Final owner release acceptance PENDING.
Status impact: GAME-QA-01 remains `in_progress`, `implementationState=partial`, `qaState=automated`, `approvalState=pending`, P1. Only `data/raven/production/progress/qa-infrastructure.json` is modified; no other progress shards.

## Exact acceptance matrix after #275–#280 merge

These commands name **existing registered blocking tests**. PASS denotes exact-main GitHub Actions execution of test fixtures, not release certification. Pending production dependencies remain BLOCKED/NOT_RUN rather than intentionally failing the functional CI.

| Gate / task | Executable test or explicit human check | Evidence as of main ddcc8a6 | Remaining decision and owner |
| --- | --- | --- | --- |
| G1 / GAME-LOOP-01A, MAP-GAME-01A | `tests/raven/map_game_01a_navigation_source_smoke.gd`; `tests/raven/game_loop_01a_hotspot_bridge_smoke.gd` | CI PASS; unavailable/unapproved source fails closed; QA opt-in | Real approved production source BLOCKED; campaign-core/manor-map |
| G2 / GAME-LOOP-01A | `tests/raven/game_loop_01a_hotspot_bridge_smoke.gd`; `tests/raven/game_loop_g2_host_smoke.gd` | CI PASS; speculative click does not grant arrival/reward; physical authored arrival rechecks story | Production map journey BLOCKED; campaign-core |
| G2 / CODE-05-02 | `tests/raven/manor_navigation_graph_smoke.gd`, `map_qa_06_room_transitions_smoke.gd`, `map_qa_09d_hc_cb_architectural_smoke.gd` | CI PASS for technical Hall–Corridor–Bedroom–Corridor–Hall QA route, closed/missing gates, physical-footpoint constraints | Painted headroom, cuts, jambs, foreground masks, camera/door collision and production HC/CB need implementation + owner review; manor-map/owner |
| G2 / GAME-LOOP-01 | `tests/raven/game_loop_g2_host_smoke.gd`, `game_pause_smoke.gd`, `restoration_restore_smoke.gd` | CI PASS for pause/resume/cancel, safe checkpoints, rejected repeat input and exact-once reducer effects in QA | Player-facing source/host gating and end-to-end production acceptance BLOCKED; campaign-core |
| G2 / GFX-07-01 | `tests/raven/gfx_07_01_evelyn_gameplay_host_smoke.gd`; Evelyn `bake_atlas.gd -- --check` and `preview_smoke.gd` | CI PASS; approved Evelyn is gameplay-map actor in QA, historic Onoe QA remains intact | Real-phone scale/FPS, room foreground occlusion NOT_RUN; chibi-animation/owner |
| G2 / CODE-11-01 | `tests/raven/main_menu_upds_parity_smoke.gd`, `main_menu_match3_campaign_smoke.gd` plus human `New Game → production map` | Existing menu/vertical-slice tests PASS; **normal New Game still does not launch G2 map** | Menu → production G2 entrypoint BLOCKED until campaign-core integration; owner QA afterwards |
| G2 / CODE-11-01 | `tests/raven/session_lifecycle_e2e_smoke.gd`; `game_loop_g2_host_smoke.gd` | CI PASS for QA save/reload, safe room/anchor Continue and failed/corrupt save handling | Live production room/actor restore and browser persistence NOT_RUN/BLOCKED; campaign-core/owner |
| G2 / CODE-07-02 | `tests/raven/match3_session_smoke.gd`, `match3_checkpoint_smoke.gd`, `main_menu_match3_campaign_smoke.gd` | CI PASS for reward idempotence, retry and checkpoint regression | Real pointer/swipe and portrait usability NOT_RUN; QA/owner |
| G3 / CODE-03-03 | `tests/raven/vn_locale_save_parity_smoke.gd`, `vn_english_localization_smoke.gd`, `vn_belarusian_localization_smoke.gd`, `vn_read_skip_smoke.gd` | CI PASS on RU/BE/EN fixture and read-only Skip/save | Full owner viewport/proofreading and phone interaction NOT_RUN; vn-runtime/owner |
| G3 / CODE-08-01 | `tests/raven/vn_production_runtime_dispatch_smoke.gd` and Season 1 audit | Approved-only dispatch and gates PASS; synthetic readiness is not scene approval | Remaining Chapter II–III and full Season 1 execution BLOCKED; vn-runtime/owner |
| G4 / CODE-10-01 | `tests/raven/device_matrix_reachability_smoke.gd`, `vn_shell_safe_area_smoke.gd`, `upds_match3_mobile_hud_smoke.gd` | Headless portrait layout fixtures PASS | Real 320×568 / 390×844 / 430×932, touch, safe area, reduced motion NOT_RUN; QA/owner |
| G4 / PROC-008 | `.github/workflows/pages.yml`; `test_pages_packages_the_shipped_game_not_just_dashboard` | Exported `index.html`, `index.wasm`, `index.pck` and deploy PASS on main | **No shipped-game browser-boot assertion**. Pages game root, console/network, refresh/offline/Continue NOT_RUN; owner |
| G4 / GAME-QA-01 | Exact-head six-job CI plus signed Windows/Web/phone test ledger | All six mandatory jobs + Pages deploy SUCCESS on main; test fixtures only | Owner release sign-off PENDING |

## Registration and repeatable commands

- Linux full: `bash scripts/check_data.sh && bash scripts/check.sh` (Godot 4.7.2 and dependencies required).
- Data contract only: `python3 -m unittest discover -s tests/raven -p 'test_game_qa_release_gate.py' -v`.
- Windows: `py -m unittest discover -s tests/raven -p test_game_qa_release_gate.py -v`; then `.\\check.ps1 -GodotPath 'C:\\Path\\To\\Godot_v4.7.2-stable_win64_console.exe'`.
- Standalone G2: `godot --headless --path . --script res://tests/raven/game_loop_g2_host_smoke.gd --quit-after 360`.
- Standalone HC/CB: `godot --headless --path . --script res://tests/raven/map_qa_09d_hc_cb_architectural_smoke.gd --quit-after 300`.
- Standalone Evelyn host: `godot --headless --path . --script res://tests/raven/gfx_07_01_evelyn_gameplay_host_smoke.gd --quit-after 300`.
- These runs were verified in Linux GitHub Actions; no local platform executions are claimed. Both `scripts/check.sh` and `check.ps1` already register the three merged G2 tests exactly once, enforced by `test_game_qa_release_gate.py`. No duplicate registration added.

## Concise manual release checklist — ALL NOT_RUN

- [ ] **Windows / owner:** On an isolated user-data profile, record Godot/build SHA, native menu New Game/Continue, VN/Match-3, pause/resume/cancel, story-locked hotspot, approved Hall→Corridor→Bedroom→Corridor→Hall and Evelyn/door foreground screenshots. New Game→G2 map remains BLOCKED until runtime feature exists.
- [ ] **Save/recovery / owner:** Back up `user://` campaign save and recovery key `raven-manor-campaign-v1` / `raven-manor-campaign-v1:recovery-v1`. In disposable profile only, reach Bedroom safe anchor, quit/restart Continue, check room, actor, anchor, rewards. Test corrupt copy, capture log, restore backup, verify original player save untouched.
- [ ] **Pages Web / owner:** Open the actual deployed game **root**, not the dashboard. Verify canvas/engine/menu appears, VN/Match-3 input, reload Continue, storage after refresh, offline→online, audio gesture and browser console/network (.js/.wasm/.pck failures). Record URL, SHA, browser version, screenshot and Console/Network export. Artifact-existence checks are not browser QA.
- [ ] **Real portrait phone / owner:** Record physical device, OS/browser, viewport (cover 320×568, 390×844 and 430×932 as available), screenshot and console. Check RU/BE/EN, notch/safe area, touch targets, Match-3 swipe/help/retry, VN choices/Skip, Evelyn scale/occlusion and background/return. Mark untested viewport/device NOT_RUN, not PASS.
- [ ] **Sign-off / owner:** Attach screenshots, console logs, build SHA, test-save recovery result and PASS/FAIL/BLOCKED per criterion; explicitly approve production geometry and physical passage before enabling G2 source.

## CI and release implication

- #267 MERGED, final exact-head [43964409306](https://github.com/bezdredoff/RavenManor-Godot/actions/runs/43964409306) SUCCESS.
- #276 MERGED as `b77d282471c7c6880db99f75e2acc1776b60c6f7`, final PR head `f23fddf28fc68366e64135cb4d83a1d81359d4f2`, [43981606512](https://github.com/bezdredoff/RavenManor-Godot/actions/runs/43981606512) SUCCESS.
- #280 MERGED as `ddcc8a646ffbfa60dcfea43849a592bfdddd9f24`, PR head `7fe865b19654c9e0d2b2308103dd4241db04b3a1`, [44072750669](https://github.com/bezdredoff/RavenManor-Godot/actions/runs/44072750669) SUCCESS.
- Post-merge **main** [44073202009](https://github.com/bezdredoff/RavenManor-Godot/actions/runs/44073202009) SUCCESS including deploy. Godot-runtime log contains exact PASS markers for Evelyn gameplay host, HC/CB architectural smoke and G2 isolated host/persistence/Continue.
- This post-merge reconciliation PR must receive its own exact-head CI before owner merges; do not infer its CI outcome from main and do not auto-merge.
