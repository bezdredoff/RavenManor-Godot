# GAME-QA-01 — G1 release-gate regression and QA infrastructure

Baseline audited: `origin/main` after PR #266, SHA `832657c`. This PR is QA-only; it does not promote draft geometry, proposed story scenes, art, gameplay, save schema, or production routes.

Task IDs: GAME-QA-01; related CODE-10-01, CODE-11-01, GFX-11-T09.
Changes: Add a G1-G4 acceptance matrix and runner-registration contract test, with no gameplay or map promotion.
Verification: Local Python unittest (2 tests) PASS; prior PR-head CI run 43956784200 failed governance on this evidence format; exact new-head CI is pending.
Owner QA: NOT_RUN on physical devices and live Web; owner approval remains pending.
Status impact: GAME-QA-01 stays PR_review / partial / qaState=automated / approvalState=pending.

## Task IDs

Primary: `GAME-QA-01`. Related: `CODE-10-01`, `CODE-11-01`, `GFX-11-T09`.

## Changes

Added the G1–G4 release acceptance matrix, manual/device checklist, and blocking-vs-advisory evidence rules. Added `tests/raven/test_game_qa_release_gate.py` to verify that both local runners retain the critical smoke registrations and reference existing test files. Registered that contract test in `scripts/check_data.sh` and `check.ps1`. Updated only the `qa-infrastructure` progress shard.

## G1–G4 acceptance matrix

| Gate | Blocking automated evidence | Manual/device evidence still required | Current result |
|---|---|---|---|
| G1 — safe contracts | `main_menu_upds_parity_smoke`, `game_loop_01a_hotspot_bridge_smoke`, `manor_navigation_graph_smoke`, `production_narrative_smoke`, `campaign_season1_audit_smoke`; draft map and proposed scenes fail closed | Windows + Web startup; RU/BE/EN selection; touch/mouse/keyboard; pause/settings; missing/corrupt save copy and Continue behavior | Automated PASS on registered suites; physical/browser checks NOT RUN |
| G2 — first gameplay loop | Existing hotspot/arrival-gate/cancellation/pause-save, restoration exact-once, Match-3 checkpoint/session/viewport and menu/campaign smokes | Hall → Corridor → Bedroom → Corridor → Hall on an approved physical map; locked/unlocked doors, safe room restore, real input, restart/Continue | Automated PASS for fixtures; production geometry/owner acceptance BLOCKED until approved |
| G3 — story waves | `vn_production_runtime_dispatch_smoke`, tri-locale localization, locale-save parity, read-only Skip, save rehearsal and season audit | Every approved chapter in order, choice gates, mid-line resume, chapter transitions, completed-season Continue in RU/BE/EN | Existing partial/staged content remains accurately blocked; no future scene is promoted |
| G4 — release candidate | Device matrix (320×568, 390×844, 430×932), Web import/export contracts, data contracts and exact runner registration | Windows/Web release build, physical portrait touch, desktop browser, refresh/offline/resume, accessibility controls, Pages deployment and owner sign-off | NOT READY: manual/device/Web live evidence and full-season production capability are missing |

## Registered blocking coverage

The existing runners already cover the release-critical automated journeys; this PR adds no duplicate gameplay suite. `test_game_qa_release_gate.py` is a small contract test that verifies both `scripts/check.sh` and `check.ps1` reference existing Godot tests and retain the seven critical smoke families above. It is registered in the data/check path and is intentionally not a dashboard/backlog consistency gate.

Covered by existing tests: New Game/Continue and corrupt/read-failed save handling; language and settings; authored navigation, missing routes, cancellation, pause/resume and safe anchors; hotspot arrival gates; Match-3 start/checkpoint/retry/return and exact-once campaign effects; restoration and persistence; canonical scene dispatch, RU/BE/EN, choices, read-only Skip and save-line resume; staged rollout fail-closed behavior; portrait layout reachability.

Not proven by headless Godot: native touch/stylus, browser refresh/offline cache, audio/haptics, visual readability/art approval, production-map geometry, live Pages deployment, or owner acceptance.

## Manual/device checklist

- [ ] Windows desktop: New Game, Continue, corrupt/missing save recovery, pause/settings, mouse + keyboard.
- [ ] Web desktop: startup, refresh, offline/resume, save/Continue, browser console/network errors.
- [ ] Physical portrait devices at 320×568, 390×844, 430×932: RU/BE/EN, touch targets, safe area, pause/settings, VN choices/Skip, Match-3 swipe/help/retry.
- [ ] Approved-map journey: Hall → Corridor → Bedroom → Corridor → Hall; locks, missing route, cancellation, pause/resume, safe-room anchor restore.
- [ ] Full approved Season 1: chapter order, mid-line resume, exact-once rewards/spending, restart persistence, final/completed-season state.
- [ ] Build/Pages: successful Web export and live deployment; record exact SHA, Actions run URL, browser/device/version and screenshots.

## Evidence classification and ownership

`PASS` means the named automated check actually ran. `NOT RUN` means no evidence was produced. `BLOCKED` means a dependency is intentionally unavailable (currently approved production geometry, full approved chapters, or physical/browser access). `OWNER ACCEPTED` requires explicit owner evidence and is not inferred from CI. Agents A–D integration requirements are not registered here until their PRs land; this PR does not reference nonexistent tests.

No product defect was independently fixed. The release blockers to report to owning agents are the already-audited missing production scene capability/full-season dispatch, unapproved map geometry, and outstanding physical/browser/Web acceptance.

## Verification

Local verification actually run: `python -m unittest discover -s tests/raven -p 'test_game_qa_release_gate.py'` — **PASS, 2 tests**; `git diff --cached --check` — **PASS**. Godot was not available in the local Windows environment. PR #267 CI run `43946777966` previously passed `godot-runtime`, `room-builder`, and `art-pipeline`, but failed only the data-contract evidence-shape check; this follow-up commit is intended to rerun that gate at its new head.

## Owner QA

Owner/device acceptance is **pending**. Required evidence is the physical portrait matrix, Windows/Web input and refresh/offline flow, approved-map journey, full approved Season 1 completion, and Pages deployment. No owner acceptance or device verification is inferred from the local Python test or headless Godot CI.

## Status impact

`GAME-QA-01` remains `PR_review`, `implementationState=partial`, `qaState=automated`, and `approvalState=pending` in `data/raven/production/progress/qa-infrastructure.json`. This update fixes the PR evidence contract only; it does not weaken blocking tests or change unfinished-backlog status.


## PR validation after merge-base CI repair

As of main `4b7f252a846faa829aad124ec17f8f6713ea053d` (after merged #273 and #272), the repository-wide pull-request evidence check now diffs against the first parent of the actual synthetic PR merge commit. Prior red status on #267 at `8fc09ae` was caused by the old workflow comparing against `832657c` and falsely attributing the already merged `campaign-core` and `manor-map` shards to `qa-infrastructure`. This note update requests an exact-new-head CI recheck; do not claim PASS before the checks finish. Existing GAME-QA-01 QA scope and device acceptance remain unchanged.
