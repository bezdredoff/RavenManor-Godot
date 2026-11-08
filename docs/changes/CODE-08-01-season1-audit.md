Task IDs: CODE-08-01 (bounded increment: Season 1 executability audit, plus a headless smoke that walks the current executable path)

Changes:
- New test `tests/raven/campaign_season1_audit_smoke.gd` (registered in `check.ps1` and `scripts/check.sh`; no runtime, save, catalog, scene or `project.godot` change).
- The test answers "which of the 28 Season 1 scenes actually run headless" from executable evidence instead of documentation:
  1. It walks the live campaign at UI level: instantiates `scenes/raven/vertical_slice.tscn` with an in-memory store, advances every VN line through `_advance_vn()`, plays the three real Match-3 boards with the engine hint API through `_complete_level()`, and applies the map/restore/clue steps through `_complete_action()`. Asserted: the 15-step `RavenSliceDirector` order, per-scene tri-locale copy contract (RU/BE/EN resolved through `raven_vn_catalog_adapter.gd`), end-of-season economy (0 work points, 2 restorations, hammer x2 + shuffle x2), recorded clue, save/reload resume at `done`, and that all eight played beats are persisted in `storyBeatsSeen`.
  2. It classifies all 28 catalog scenes using production code as the oracle: scene status from `season1_dialogue_catalog.json`, route gate through `RavenVNRuntimeDispatch._gate_satisfied`, save-catalog registration from `foundation_catalog.json`, the staging/background/portrait/line-cue contract through `RavenVNRuntimeDispatch.build_config` on a status-normalised copy of each scene, and a cross-check of the resulting blocker list against `RavenVNRuntimeDispatch.find_approved` for the same scene. If the test's own reading of a line contract disagrees with `build_config`, the smoke fails.
  3. It carries a positive control so it cannot be vacuously green: RM-BEAT-00-02 with a synthetic `runtime_approved` status but the real JSON route registry must still be refused, and the same synthetic scene with int-typed ordinals must be selected and produce playable lines.

Measured audit result (28 authored scenes in `data/raven/production/season1_dialogue_catalog.json`):
- Executable today: 8, all through the legacy RM-VS-01 path (`raven_slice_director.gd` STEPS + `vertical_slice.gd` + `data/raven/rm_vs_01_content.json`): RM-BEAT-00-01, 00-02, 00-03, 01-01, 01-02, 01-03, 01-04, 01-05. Their catalog class is `already_runtime`.
- Not executable by any path: 20.
- Selectable by the production VN dispatcher (`raven_vn_runtime_dispatch.gd`): 0 of 28. After the last legacy beat the campaign reaches `done` with no production scene to continue with, in RU/BE/EN.

Exact blockers, measured per scene (B1..B8 are not "planned work"; each is observed by the smoke):

B1. Scene status gate, 28/28. `raven_vn_runtime_dispatch.gd:15,50,94` accepts only `runtime_approved`. Actual statuses: 8 `already_runtime`, 1 `pilot_runtime`, 18 `proposed_future_runtime`, 1 `optional`. No scene is `runtime_approved`, so no scene can enter production playback.

B2. Route ordinal typing, 28/28. `data/raven/production/map_narrative_routes.json` is a JSON resource, so every `ordinal` decodes as float (0.0..27.0). `raven_vn_runtime_dispatch.gd:61-63` requires `ordinal is int` and skips the route otherwise, before the gate is even evaluated. A fully approved, fully staged scene is still unreachable. Proven by the positive control: stage A (real registry) refused, stage B (same data, int ordinals only) selected.

B3. Route gate flags, 20/28. For RM-BEAT-02-01 .. RM-BEAT-06-POST the trigger has `gate.approvedRuntime=false`, `gate.proposedRuntime=true` (registry status `PROPOSED_NOT_EXECUTABLE`). Dispatcher requires `approvedRuntime=true` and `proposedRuntime=false` (`:53-56`).

B4. Unsupported gate kinds, 20/28. `_gate_satisfied` implements only `scene_complete` and `first_clear` (`:84-89`), but the canonical registry also uses `auto_new_game` (00-01), `restoration_done` (01-02), `clue_recorded` (01-04, 05-03), `npc_tap` (02-02, 03-03, 04-01, 06-01), `object_tap` (02-03, 03-02, 03-04, 04-03, 05-02, 06-02), `door_tap` (03-01), `specialist_result` (02-04, 04-02), `time_phase` (05-01, 05-04) and `optional_postcredits` (06-POST). Those scenes can never be selected regardless of art or status.

B5. Save-catalog registration, 19/28. `data/raven/foundation_catalog.json` registers only 9 story beats (00-01..00-03, 01-01..01-05, 02-01). `RavenReducer` rejects `story_beat_seen` for the other 19 with `unknown-story-beat`, and `RavenSnapshot.normalize` drops unknown beats (`raven_snapshot.gd:48,62`). Their progress could not be saved even if the scene played.

B6. Art/line/cue contract gaps, 18/28. Missing accepted `defaultForPose` portrait variants make `build_config` refuse the whole scene (`:122-153`). Distinct missing pose x emotion combinations observed: RM-CHAR-ADA `offer_tray/dry_amused` (00-03, 02-01, 05-04) and `apron_reach/regretful` (05-02); RM-CHAR-LUCAS `folder_present/professional` (01-01, 03-01, 06-POST), `folder_present/reserved_worry` (06-01), `explain/professional` (03-02), `explain/serious` (03-03); RM-CHAR-EVELYN `investigate/curious` (02-03), `investigate/worried` (03-03, 03-04, 05-03), `decide/determined` (06-01, 06-02); RM-CHAR-ROWAN `point_route/wry` (02-02), `point_route/focused` (04-03, 06-02), `rest_tool/focused` (04-01), `rest_tool/friendly` (05-04).

B7. Cue review gates, 2/28. RM-BEAT-05-02 (13 lines) and RM-BEAT-06-01 (25 lines) carry `line_performance_cues` entries with `manualReview=true`, which `build_config` rejects (`:149`). This is a human/animation review gate, not a mechanical fix.

B8. Offstage speakers, 1/28. RM-BEAT-06-03 lines L004/L006/L008 are spoken by RM-CHAR-ADA while she is absent from the shot cast, and L009 by RM-CHAR-UNKNOWN-VOICE; their cues also set `portraitVisible=false`. The builder allows no offscreen or narrator speaker (`:136-137,151`), so the staging/contract must be redesigned (cast entry or a supported narrator channel).

Per-scene table. Codes: st = status not `runtime_approved`; ord = route ordinal decodes as float; gate = route not approved for runtime; gk-<kind> = gate kind not implemented by the dispatcher; beat = story beat not registered in the save catalog; art(...) = missing pose x emotion portrait variants; cue-art = lines whose cue portrait is missing; review = lines with `manualReview=true`; hidden = cues with `portraitVisible=false`; offstage = speaker absent from the shot cast.

| # | Scene | Catalog status | Playback today | Blocker codes | Contract detail |
|---|---|---|---|---|---|
| 1 | RM-BEAT-00-01 | already_runtime | LEGACY | st, ord, gk-auto_new_game |  |
| 2 | RM-BEAT-00-02 | already_runtime | LEGACY | st, ord |  |
| 3 | RM-BEAT-00-03 | already_runtime | LEGACY | st, ord | art(RM-CHAR-ADA/offer_tray/dry_amused); 2 cue-art |
| 4 | RM-BEAT-01-01 | already_runtime | LEGACY | st, ord | art(RM-CHAR-LUCAS/folder_present/professional); 2 cue-art |
| 5 | RM-BEAT-01-02 | already_runtime | LEGACY | st, ord, gk-restoration_done |  |
| 6 | RM-BEAT-01-03 | already_runtime | LEGACY | st, ord |  |
| 7 | RM-BEAT-01-04 | already_runtime | LEGACY | st, ord, gk-clue_recorded |  |
| 8 | RM-BEAT-01-05 | already_runtime | LEGACY | st, ord |  |
| 9 | RM-BEAT-02-01 | pilot_runtime | none | st, ord, gate | art(RM-CHAR-ADA/offer_tray/dry_amused); 6 cue-art |
| 10 | RM-BEAT-02-02 | proposed_future_runtime | none | st, ord, gate, gk-npc_tap, beat | art(RM-CHAR-ROWAN/point_route/wry); 7 cue-art |
| 11 | RM-BEAT-02-03 | proposed_future_runtime | none | st, ord, gate, gk-object_tap, beat | art(RM-CHAR-EVELYN/investigate/curious); 10 cue-art |
| 12 | RM-BEAT-02-04 | proposed_future_runtime | none | st, ord, gate, gk-specialist_result, beat |  |
| 13 | RM-BEAT-03-01 | proposed_future_runtime | none | st, ord, gate, gk-door_tap, beat | art(RM-CHAR-LUCAS/folder_present/professional); 2 cue-art |
| 14 | RM-BEAT-03-02 | proposed_future_runtime | none | st, ord, gate, gk-object_tap, beat | art(RM-CHAR-LUCAS/explain/professional); 3 cue-art |
| 15 | RM-BEAT-03-03 | proposed_future_runtime | none | st, ord, gate, gk-npc_tap, beat | art(RM-CHAR-EVELYN/investigate/worried; RM-CHAR-LUCAS/explain/serious); 10 cue-art |
| 16 | RM-BEAT-03-04 | proposed_future_runtime | none | st, ord, gate, gk-object_tap, beat | art(RM-CHAR-EVELYN/investigate/worried); 5 cue-art |
| 17 | RM-BEAT-04-01 | proposed_future_runtime | none | st, ord, gate, gk-npc_tap, beat | art(RM-CHAR-ROWAN/rest_tool/focused); 7 cue-art |
| 18 | RM-BEAT-04-02 | proposed_future_runtime | none | st, ord, gate, gk-specialist_result, beat |  |
| 19 | RM-BEAT-04-03 | proposed_future_runtime | none | st, ord, gate, gk-object_tap, beat | art(RM-CHAR-ROWAN/point_route/focused); 3 cue-art |
| 20 | RM-BEAT-04-04 | proposed_future_runtime | none | st, ord, gate, beat |  |
| 21 | RM-BEAT-05-01 | proposed_future_runtime | none | st, ord, gate, gk-time_phase, beat |  |
| 22 | RM-BEAT-05-02 | proposed_future_runtime | none | st, ord, gate, gk-object_tap, beat | art(RM-CHAR-ADA/apron_reach/regretful); 7 cue-art; 13 review |
| 23 | RM-BEAT-05-03 | proposed_future_runtime | none | st, ord, gate, gk-clue_recorded, beat | art(RM-CHAR-EVELYN/investigate/worried); 8 cue-art |
| 24 | RM-BEAT-05-04 | proposed_future_runtime | none | st, ord, gate, gk-time_phase, beat | art(RM-CHAR-ROWAN/rest_tool/friendly; RM-CHAR-ADA/offer_tray/dry_amused); 12 cue-art |
| 25 | RM-BEAT-06-01 | proposed_future_runtime | none | st, ord, gate, gk-npc_tap, beat | art(RM-CHAR-LUCAS/folder_present/reserved_worry; RM-CHAR-EVELYN/decide/determined); 25 cue-art; 25 review |
| 26 | RM-BEAT-06-02 | proposed_future_runtime | none | st, ord, gate, gk-object_tap, beat | art(RM-CHAR-EVELYN/decide/determined; RM-CHAR-ROWAN/point_route/focused); 10 cue-art |
| 27 | RM-BEAT-06-03 | proposed_future_runtime | none | st, ord, gate, beat | 4 cue-art; 4 hidden; 4 offstage |
| 28 | RM-BEAT-06-POST | optional | none | st, ord, gate, gk-optional_postcredits, beat | art(RM-CHAR-LUCAS/folder_present/professional); 4 cue-art |

Cheapest next switch-over candidates on data grounds only: RM-BEAT-02-04, RM-BEAT-04-02, RM-BEAT-04-04, RM-BEAT-05-01 have a complete art/line/cue contract and fail only B1/B2/B3/B4/B5 (status, ordinal typing, route approval, gate kind, save-catalog registration). None of them can be made playable by a test-only change.

Deliberately not done (stop condition: >3 files and integration-zone scope):
1. `scripts/raven/raven_vn_runtime_dispatch.gd` - accept integral JSON floats for `ordinal` (or normalise once at load) and extend `_gate_satisfied` to the remaining gate kinds. Shared core, integrator PR.
2. `data/raven/production/map_narrative_routes.json` - int ordinals and per-scene `approvedRuntime`/`proposedRuntime` flags. Canonical story registry.
3. `data/raven/production/season1_dialogue_catalog.json` - per-scene `runtime_approved` status. Canonical story registry.
4. `data/raven/foundation_catalog.json` - `storyBeats` (and gate refs) for the newly approved scenes. Save authority.
5. `data/raven/production/vn_character_catalog.json` plus accepted art imports - the 13 missing pose x emotion variants (character-art domain, owner art review).
6. `data/raven/production/line_performance_cues.json` for RM-BEAT-05-02 and RM-BEAT-06-01 - human/animation review; RM-BEAT-06-03 needs a staging/contract redesign for offstage speakers.

Verification:
- EXECUTED_PASS: Godot 4.7.2 headless `--script res://tests/raven/campaign_season1_audit_smoke.gd --quit-after 600` prints the 28-line audit table, `AUDIT summary scenes=28 playable=8 blocked=20 production_selectable=0` and `Raven Manor campaign Season 1 audit passed`; stderr empty, ~2 s wall clock.
- EXECUTED_PASS: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File check.ps1 -GodotPath <console exe>` -> exit 0, 85 stages passed, no `SCRIPT ERROR`, no failed stage. That includes the new `Campaign Season 1 executability audit` stage and the neighbouring runtime/data stages this change touches: `RM-VS-01 vertical slice smoke`, `Narrative production contract smoke`, `Whole season1 map smoke`, the VN Studio suite, Match-3 viewport/board suites and the data/governance audits (progress shards, backlog, P2 acceptance).
- NOT_RUN locally: `bash scripts/check.sh` (the brief states it is broken on this Windows host; the PowerShell runner is the local equivalent and covers the same Godot stages minus the check.sh-only ones), GitHub Actions at PR head, device/owner QA.
- Environment note, not a code claim: `vn_studio_migration_smoke.gd` is not idempotent - it refuses to run when its own previous export still exists under `user://vn_studio_conversions/v1/<sha>/bundle-*`. Clearing that stale automated export before the local suite was required; no repository file was touched for it. CI starts from a clean user directory.
- NOT_RUN (by design): production VN dispatch end-to-end with a real approved scene - no scene is `runtime_approved` at this base SHA, and making one executable is an integration/art change outside this task's allowlist.

Owner QA: not performed. Manual checks needed to close CODE-08-01 on a real device (none of them is implied by this smoke): (1) New Game on a clean profile: prologue letter -> road -> gates -> arrival plays line by line in RU, then repeat once in BE and once in EN; assert wording has no placeholder or clipped text on 390x844 and 430x932. (2) Bedroom access step: clear RM-HS-005 from the corridor, confirm the bedroom door physically opens and the bathroom remains unrequired. (3) RM-LVL-001/002/003 are playable by touch only (swipe accuracy, no free tap-to-move), each first clear grants 2 work points exactly once after an app restart. (4) RM-REST-001 (2 points) and RM-REST-002 (4 points, after the plumber flag) complete visually, grant hammer x2 / shuffle x2 exactly once, and booster counts survive relaunch. (5) Clue RM-CLUE-01-CHILDHOOD-OBJECT records from RM-HS-004 and the "first night" + "morning" scenes play to the end. (6) After the last scene the player is not dropped into an empty loop: confirm the current terminal screen ("RM-VS-01 завершён" / map button) is acceptable for a Season 1 preview, and record what the owner expects to happen next. (7) Deliberately close the app mid-scene and mid-Match-3, relaunch, Continue resumes the same line / same board. (8) Record device, OS, resolution, locale and screenshots. Production scenes (02-01 .. 06-POST) stay explicitly out of scope for acceptance: they are not executable, and the blockers above must be fixed in separate integration/art PRs first.

Status impact: CODE-08-01 stays `ready` with `implementationState` `partial`; no status, priority, QA or approval field is changed by this PR. Only audit evidence is appended to the campaign-core shard. No merge, no acceptance, no device claim.
