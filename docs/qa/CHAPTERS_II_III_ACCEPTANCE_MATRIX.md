# Chapter II–III production acceptance matrix — GAME-QA-03

**Registered ledger:** GAME-QA-01 (qa-infrastructure, P1). **Delivery label:** GAME-QA-03; do not insert an unregistered `GAME-QA-03` task into the status shard.  
**Baseline:** `main@32a8d98d2fd3e75bf7613b8391f5ea7a769abd5a` after #291. **Baseline main CI:** [44173380349](https://github.com/bezdredoff/RavenManor-Godot/actions/runs/44173380349) SUCCESS (six required jobs plus Pages deploy).  
**New QA test:** `tests/raven/vn_chapters_ii_iii_production_gate_smoke.gd` — standalone. Registered exactly once in both shared runners through governance-scoped stacked **[PR #297](https://github.com/bezdredoff/RavenManor-Godot/pull/297)** (not in #294's own diff). **Verified Godot 4.7.2 Linux execution:** PASS for the baseline-with-scenes-disabled configuration in [run 44388667642](https://github.com/bezdredoff/RavenManor-Godot/actions/runs/44388667642), head `97ed88901dc91f7e08ccfac1ff64ad86a1004a5c`, where all six required jobs succeeded and the runtime log printed `GAME-QA-03 Chapter II-III production gate passed.` **After #292 portrait merge:** NOT_RUN, requires a fresh combined exact-head CI. **Physical phone / Windows / owner acceptance:** NOT_RUN / PENDING. Green #294 checks alone cannot prove this standalone execution.

## Evidence definitions

- **PASS:** this exact criterion executed on a cited head SHA and named runner/device.
- **BLOCKED:** a required production approval, contract, authored route or asset is absent.
- **NOT_RUN:** test not executed, even if related code was inspected or a synthetic fixture passed.
- **SYNTHETIC PASS:** deep-copied, test-only sources exercise a future path; not evidence of shipped map activation.
- **FAIL:** attempted criterion failed with reproduced expected/actual evidence.
- A staged, desktop-headless or resized browser viewport **never** means physical-phone PASS. Reducing motion or viewport size in Godot CI alone does not prove actual touch, cropping, safe area, web/offline or performance.

## Canonical scene-by-scene release gates

These counts describe the #291 baseline and are **not** hardcoded as permanent missing-art expectations. The independent smoke re-computes missing pose/emotion combinations and affected cues directly from the live accepted portrait catalog, staging and line cues. Agent A may close the art gaps by changing **true staging/cue pose and emotion**, not by fabricating new portrait identities.

| Beat | Lines per locale | Trigger / authoritative gate | Baseline missing exact accepted art | Baseline production status |
| --- | ---: | --- | --- | --- |
| `RM-BEAT-02-01` Hall Tea | 12 | `RM-HS-TEA-TABLE` → `hall_chair_table`; `scene_complete:RM-BEAT-01-05` plus confirmed physical arrival | Ada `offer_tray/dry_amused` (6 cues) | BLOCKED: no approved VN scene/route/portrait |
| `RM-BEAT-02-02` Rowan | 13 | Entry / `npc_tap:RM-CHAR-ROWAN` after validated NPC arrival | Rowan `point_route/wry` (7) | BLOCKED: NPC token + Entry route + Foundation beat |
| `RM-BEAT-02-03` Ledger | 19 | Kitchen table / `object_tap:PROP-HOUSEHOLD-LEDGER` | Evelyn `investigate/curious` (10) | BLOCKED: object authority + Kitchen route + Foundation beat |
| `RM-BEAT-02-04` Kitchen result | 13 | `specialist_result:kitchen_power_safe` | none | BLOCKED: authoritative specialist result + Kitchen + Foundation beat |
| `RM-BEAT-03-01` Library | 7 | `door_tap:RM-DOOR-HALL-ARCHIVE` | Lucas `folder_present/professional` (2) | BLOCKED: Library door + map + Foundation beat |
| `RM-BEAT-03-02` Album | 13 | `object_tap:PROP-FAMILY-ALBUM` | Lucas `explain/professional` (3) | BLOCKED: Library prop + map + Foundation beat |
| `RM-BEAT-03-03` Memory | 10 | `npc_tap:RM-CHAR-LUCAS` | Evelyn `investigate/worried`; Lucas `explain/serious` (10 combined) | BLOCKED: Lucas presence/token + Foundation beat |
| `RM-BEAT-03-04` Letter | 9 | `object_tap:PROP-LIBRARY-DESK` | Evelyn `investigate/worried` (5) | BLOCKED: desk interaction + Foundation beat |

**Baseline source inventory:** 8 scenes, 96 ordered line IDs, 288 localized RU/BE/EN text cells, 7 unique missing accepted pose×emotion pairs / 43 affected cue occurrences. The baseline catalog has 62 accepted frames (including non-default prop variants) and no repeated accepted asset SHA-256. Accepted backdrops exist for all eight scenes. No current source inventory is itself a phone visual approval.

## Automated regression cases and honest current scope

| ID | Required criterion | New standalone smoke / existing ownership | Current status on #291 |
| --- | --- | --- | --- |
| C23-01 | All eight scene/staging/route IDs, 96 ordered line/cue records, exact speaker and RU/BE/EN nonempty text | **NEW** dynamic source audit; existing `vn_chapters_ii_iii_readiness_fixture.gd` also checks handoff | New test NOT_RUN; existing registered fixture covered by baseline Godot CI |
| C23-02 | Accepted portrait matches exact character, pose, emotion and `defaultForPose=true`; resource loads | **NEW** stage+cue requirement audit, prints current deficits; `_exact_art` requires accepted default and importable path | New test NOT_RUN; current art BLOCKED |
| C23-03 | Accepted art not relabeled: distinct ID, asset path and provenance SHA-256 per accepted frame | **NEW** catalog uniqueness/provenance audit; substitution fixture changes staging/cues only | New test NOT_RUN |
| C23-04 | Complete Chapter I including `RM-BEAT-01-05`; no Hall Tea before predecessor | **NEW** reducer-generated prior-beat snapshot vs missing predecessor; legacy next-scene excludes physically triggered VN | SYNTHETIC pending test; live Chapter I-to-Hall integration NOT_RUN |
| C23-05 | `RM-HS-TEA-TABLE` target, real production source, no unrelated target | **NEW** default `Source.resolve` and `Host.configure` on isolated memory, wrong-hotspot/safe Hall spawn negative; copied route target positive | Production route exists for G2; Hall Tea physical hotspot target BLOCKED |
| C23-06 | Movement, portal pending, wrong room, unreachable/locked target cannot start VN | Existing `game_loop_g2_production_integration_smoke.gd` and `game_loop_g2_host_smoke.gd` test traversal/cancel/locked/collision; **NEW** safe-spawn/unknown target rejection | Baseline G2 automated gates covered; Chapter II arrival full integration NOT_RUN |
| C23-07 | 12 Hall Tea lines × RU/BE/EN, exact speakers, ordered IDs | **NEW SYNTHETIC** copied scenes with accepted portrait metadata, actual canonical text via `Runtime.find_approved` and `RavenVNPlayer` | Not production, new test NOT_RUN |
| C23-08 | Line/page cursor, read-only Skip, choice/Match-3 boundaries | **NEW SYNTHETIC** line cursor/read history/Skip; existing `vn_locale_save_parity_smoke.gd` and `vn_read_skip_smoke.gd` cover actual existing UI paging | VN reused behavior baseline CI; Chapter II rendered view/device NOT_RUN |
| C23-09 | Exactly one `story_beat_seen` after genuine final advance; duplicate does not reward | **NEW SYNTHETIC** 11 nonterminal advances, final advance, reducer event and two idempotency paths; existing campaign reducer tests | New test NOT_RUN; real map-to-VN completion BLOCKED |
| C23-10 | Save/Continue mid-scene, after completion, no replay | **NEW SYNTHETIC** isolated `MemoryStorage`, new Store, saved cursor/history and beat; existing G2 live-host save regression | Isolated test pending; normal game process-restart NOT_RUN |
| C23-11 | Missing art/approval/locale, wrong or unsupported gate must fail closed | **NEW SYNTHETIC** hostile copies; **NEW LIVE** no fake arrival; baseline dispatcher `_gate_satisfied` rejects unknown NPC/object/door/specialist kinds | New test NOT_RUN; canonical future scenes BLOCKED |
| C23-12 | UI tap never equals specialist result; no missing Chapter III path succeeds | **NEW SYNTHETIC** future-scene approval without authoritative state still cannot produce that beat; no fake specialist-result events | Contract-level tests pending; full gameplay authority needs Agent B/C acceptance |
| C23-13 | Corrupt read, write failure and restart never overwrite good save | **NEW** isolated memory failed write, corrupt host configure; existing G2 integration and menu boundary regressions | Existing automated scenarios on baseline CI; process restart/browser NOT_RUN |
| C23-14 | Actual normal launch → Hall Tea → completion/save/Continue | **Future integration E2E**, must be added by Agent B after runtime activation; no test-only geometry | BLOCKED |
| C23-15 | Entry/Kitchen/Library real player flow | Agent map implementation + contract approval + Agent B/C; no QA synthetic result can promote it | BLOCKED |
| C23-16 | Actual phone, web refresh/offline, owner tri-locale rendering | Manual execution matrix below | NOT_RUN |

**Important gap to review with integration owner:** The current dispatcher checks `storyBeatsSeen.has("RM-BEAT-01-05")`; a well-formed but artificially injected snapshot containing only that beat can satisfy this **predicate**. The full Chapter I walkthrough and save-event provenance must therefore be verified through the real host/reducer and normal gameplay path, not inferred from this single Boolean.

## Device/release execution card

Run against a pinned **merged integration SHA**, with a disposable profile/save; record exact SHA, Godot **4.7.2**, build, device model and OS, browser version, DPR, viewport/CSS pixels, portrait/safe-area inset, locale, reduced-motion setting, steps, expected/actual and screenshot/video/log URL. Never label an emulator or desktop-resize as physical phone. Use one evidence row per locale and viewport.

| Environment | RU | BE | EN | Mandatory observations |
| --- | --- | --- | --- | --- |
| **320×568**, responsive web simulation | NOT_RUN | NOT_RUN | NOT_RUN | 12-line Hall Tea, portrait cropping/no overlap, text pagination, table touch hitbox, top/bottom safe margins, readable Skip controls |
| **390×844**, responsive web simulation | NOT_RUN | NOT_RUN | NOT_RUN | Evelyn Hall → table footpoint, tap→travel→VN ordering, portrait scale/slots, UI touch, reduced-motion instant transitions |
| **430×932**, responsive web simulation | NOT_RUN | NOT_RUN | NOT_RUN | safe-area/notch and browser bars, long BE/RU lines, VN title/nameplate, no clipped advance/Skip/choices |
| **Physical phone** (record model/OS/browser) | NOT_RUN | NOT_RUN | NOT_RUN | Real tap/no hover, no double activation, speaker/portrait alignment, finger target size, Home/background, repeat, save/reload |
| **Windows native desktop** | NOT_RUN | NOT_RUN | NOT_RUN | keyboard/mouse and focus, Hall G2→tea→VN→save/quit→Continue, wrong room/locked/door-in-motion, failure injection in disposable storage |
| **Actual exported Web** (online / hard refresh / offline) | NOT_RUN | NOT_RUN | NOT_RUN | production URL loads, save+reload in IndexedDB, service worker/PWA offline behavior measured, reconnect/cache recovery; log network/CORS errors |

For each locale and target viewport: advance every Hall Tea line with long-text pages; confirm current page and line, read-only Skip halts on unseen text and choices, no scene completion on mere paging; capture approved Ada/Evelyn cast visuals and background; run with reduced-motion both on and off. Repeat the player-facing route, skip abuse, double tap, locked door, timeout, cancel, process restart at mid-scene, and final replay attempt. For the kitchen, verify a UI-only tile clear/tap cannot generate `specialist_result:kitchen_power_safe`. For Chapter III, verify closed/unmapped Library/Archive routes remain explicitly blocked.

**Result card:** `case ID | PASS/FAIL/BLOCKED/NOT_RUN | exact SHA | Godot/build | OS/device/browser/DPR/viewport | locale/motion | steps | expected/actual | evidence link | owner+date`. For failed writes/corrupted saves use a *copy*, never a personal real save.

## Integration status — registered in stacked PR #297

After Agent A portrait-reuse and Agent B Hall Tea/runtime and Agent C gate-contract/map branches converge, the integration owner must:

1. Rebase this QA branch, inspect the live eight-scene deficit report, and reconcile any **stale fixed missing-art count assertions** in the existing `vn_chapters_ii_iii_readiness_fixture.gd` (Agent A/VN owner; do **not** disable it). Current manifest and fixture were authored for seven missing variants; they may require the integration owner's source-of-truth update if canonical staging/cues change.
2. Run standalone: `godot --headless --path . --script res://tests/raven/vn_chapters_ii_iii_production_gate_smoke.gd --quit-after 240`. This test is a separate `SceneTree`; **do not** attempt to invoke it as a `RefCounted.run()` fixture. On Windows: `Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/raven/vn_chapters_ii_iii_production_gate_smoke.gd --quit-after 240`. Keep normal-game, actual UI and process-restart positives in a separate merged integration E2E with isolated storage.
3. **DONE in stacked integration [PR #297](https://github.com/bezdredoff/RavenManor-Godot/pull/297):** register the standalone test once in Linux `scripts/check.sh` and once in Windows `check.ps1`, alongside `vn_production_runtime_dispatch_smoke.gd`. Linux GitHub Actions run 44388667642 PASS at `97ed88901dc91f7e08ccfac1ff64ad86a1004a5c`; Windows invocation is statically present but Windows execution remains NOT_RUN. Do not merge the integration PR independently of #294, and rerun on the final combined head after #292 or other integration changes.
4. Revalidate each promoted scene's **actual** `runtime_approved` status, accepted art, Foundation registration, validated room/hotspot/interaction token, physical arrival and final event at the real host boundary. For a future approved NPC/object/door/specialist contract, extend the **authoritative** integration tests rather than making this pure selector permissive.
5. Run `bash scripts/check_data.sh`, `bash scripts/check.sh`, `python3 scripts/raven/tools/progress_shards.py`, `python3 scripts/raven/tools/build_production_dashboard.py --check`. Obtain all six blocking checks on the **exact final PR SHA**, plus actual Godot 4.7.2 script output. Then collect real-device and owner acceptance evidence.
6. Maintain separate **CI PASS / SYNTHETIC PASS / REAL-PRODUCTION PASS / PHYSICAL PHONE PASS / OWNER APPROVED** fields. Do not mark all eight playable because Hall Tea passes. Keep Draft until reviewed by owner; merge only after approval.

**Isolation and rollback:** revert this independent QA test/document/shard PR. No accepted art, world-plan, reducer, snapshot, save schema, VN runtime, project configuration, test runner or CI workflow is changed by GAME-QA-03.
