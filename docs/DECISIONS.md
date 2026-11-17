# Approved product decisions / overrides

Updated 2026-11-17 (new decisions appended below). These decisions override conflicting clauses in preserved historical Stage 1/2 files. Do not silently modify old source documents.

| ID | Current decision |
|---|---|
| RM-DEC-001 | Preserve Stage 1 v0.5 narrative, cozy gothic anime, six chapters, stable IDs. |
| RM-DEC-002 | Stage 2 v0.2 geometry: entry → hall → west corridor → bedroom/bathroom/kitchen; library from hall; conservatory from kitchen/service side; first floor only. |
| RM-DEC-003 | Closed future floors and wings are explained by unsafe structure/utilities and electrical wiring, not arbitrary magic locks. |
| RM-DEC-004 | No free tap-to-move. Only hotspot/door/target interaction; natural-looking movement along authored navigation graph. Supersedes earlier free-movement recommendations. |
| RM-DEC-005 | Once unlocked, doors may remain open or visually disappear; retain logical portal, occlusion, accessibility and persistence. No repeated open/close animation required. |
| RM-DEC-006 | Bedroom accessibility independent from bathroom repair. Bedroom work occurs after entry. Supersedes outdated Stage 1/2 slice-gate sequence. |
| RM-DEC-007 | Bathroom can be an exterior corridor-side focus vignette in first integrated slice. |
| RM-DEC-008 | Use Onoe from UPDS as temporary placeholder only; canonical Evelyn and all cast art await unified style approval. |
| RM-DEC-009 | Defer public toolkit, but require modular clean code, explicit APIs, tests and understandable human-readable setup/extension/debug documentation. |
| RM-DEC-010 | Godot 4.7.2 target, deliberate reuse of suitable UPDS VN, Match-3 and save primitives within isolated Raven runtime, rather than engine migration. |
| RM-DEC-011 | Integrate and test greybox before bulk Raven production art. |
| RM-DEC-012 | Onoe artwork is owned by the repository owner and authorized as a technical placeholder in this repository; it remains non-canonical for Evelyn and does not approve a production style. |
| RM-DEC-013 | `RM-HS-005` is the early bedroom-door access hotspot in PR 3. It sets `RM-FLAG-BEDROOM-ACCESS-CLEARED` and unlocks `RM-DOOR-CORRIDOR-BEDROOM`; it no longer waits for bathroom restoration or the childhood clue. `RM-HS-002` remains the bedroom restoration interaction after entry. |
| RM-DEC-014 | PR 3 will deliberately import/adapt the smallest proven UPDS Match-3 and VN runtime components needed for the slice, without importing unrelated UPDS story content or numeric story progression. |
| RM-DEC-015 | `https://github.com/bezdredoff/RavenManor` is the source repository for Raven Manor game bible, narrative, design and source materials. This Godot repository owns executable Godot runtime, integration tests and Web/Pages delivery. Conflicts still follow this repository's explicit product decisions and documented overrides. |
| RM-DEC-016 | No separate public license is needed for the temporary Onoe placeholder. Onoe must be removed when canonical Evelyn art is produced and must not ship as a reusable/public art asset. |
| RM-DEC-017 | Evelyn Raven is the last heir. She left the manor/town years ago and returns because of an unexpected inheritance letter. |
| RM-DEC-018 | Supernatural memories fade progressively while a person remains away from the town; returning restores fragments gradually. The cause is a long-term mystery and is not explained in the opening slice. |
| RM-DEC-019 | Ada, Lucas and Rowan initially present as ordinary people: Ada as the resident housekeeper/caretaker, Lucas as the notary, Rowan as the gardener who comes from outside and lives elsewhere. Their ghost/vampire/werewolf natures are revealed gradually, not explicitly in RM-VS-01. |
| RM-DEC-020 | Early domestic progression is bedroom + bathroom → first night with food delivery while the kitchen is unready → kitchen → Rowan's garden/conservatory work. Library/archive remains a season-one investigation space; its exact placement relative to that sequence is still open. |
| RM-DEC-021 | Match-3 represents preparation work (sorting, cleaning, clearing access, finding parts/documents/clues), not magical repair. Specialist work such as plumbing/electrical/structural/clock/glazing is performed by appropriate specialists after player preparation. |
| RM-DEC-022 | Future room/floor gates use believable physical causes such as partial electricity, damaged roof/floors/structure or unavailable utilities; do not introduce arbitrary magical locks as the default explanation. |
| RM-DEC-023 | RM-VS-01 ends on the first-night/next-morning hook toward kitchen and Rowan/conservatory. It establishes memory gaps/returning fragments but does not explain the memory effect or explicitly reveal Ada/Lucas/Rowan's supernatural nature. |

**Outdated known clauses:** older `04_vertical_slice_flow.md`, Stage 2 hotspot/economy CSV/MD and door FSM may require bathroom repair before bedroom access or repeated door animations. Implement latest product decisions without renaming `RM-*` IDs; record any dependency changes in a migration note. Do not claim the archived documents are synchronized to this override.


## Owner-approved planning amendments — 2026-11-03

| ID | Decision |
|---|---|
| RM-DEC-024 | `work_points` remains the sole restoration currency. Star performance is not a second repair wallet; first-clear awards are idempotent. Preserve the 2/2/2 rewards and 2/4 restoration costs of RM-VS-01. |
| RM-DEC-025 | Keep `RM-LVL-001..003` stable; UPDS-godot's 22 authored levels are a reusable mechanics/layout pool, not an automatically imported school-themed campaign. Add new Raven IDs after pacing and balance review. |
| RM-DEC-026 | Single Raven reducer/campaign store authority for progression and save; UI and UPDS components never persist competing authoritative state. |
| RM-DEC-027 | Scope milestone order: foundation → approved Hall vertical slice → campaign/season → release candidate. Do not equate merged, asset-approved, editor-draft, runtime-integrated and owner-accepted. |
| RM-DEC-028 | Standalone VN Studio prop catalogue is deferred; map props remain necessary. Historical Stage 1/2 contradictory gates are superseded by RM-DEC-004..013. |

See [canonical progression](production/GAME_PROGRESSION_CONTRACT_RU.md) and [consistency audit](production/GAME_CONSISTENCY_AUDIT_RU.md).


## Owner-approved gameplay-art and doorway direction — 2026-11-17

| ID | Decision |
|---|---|
| RM-DEC-029 | The product owner manually reviewed and **approved the corrected Evelyn chibi appearance and walk animation** from merged PR #274 for gameplay use. PR #275 supplies the reusable player-map walker. Preserve the approved atlas/identity; no further sprite redesign or use of Onoe as the player avatar. Technical actor integration and real-phone/foreground tests remain separate; owner visual approval is **not** a claim of game-loop/device acceptance. |
| RM-DEC-030 | The product owner **approves the proposed HC/CB architectural target** presented with PR #278: the Hall↔Corridor passage beneath the central staircase landing (provisional threshold source pixel **[824,400]**, near **[824,424]**, far **[824,384]**) and Corridor↔Bedroom partition opening (threshold **[528,376]**, near **[552,376]**, far **[512,376]**), each proposed **48 px** wide. This is owner approval of the *design direction/positions*, not evidence that a painted flat floor includes real structural headroom or a passable, layered door. The integrated production source must still remain fail-closed until visible passage/backfill, headroom/elevation solution, jambs, foreground occlusion, footpoint collision, bidirectional/locked route tests, safe-anchor persistence and owner inspection of the rendered result are complete. Preserve the approved PNG unless the replacement/overlay is itself reviewed. Do not relabel existing 09B/09C/09D DRAFT_ONLY fixtures as production-ready. Bedroom access remains independent of bathroom repair (RM-DEC-006). |

**Acceptance boundary:** PRs #275–#279 were explicitly authorized for merge on 2026-11-17. Merger of isolated QA code, review overlays or owner approval of doorway direction does not itself enable production navigation or certify a G2 playable loop. Integrator must supply actual production geometry and the ordinary New Game → map → story/Match-3 → save/Continue journey before promoting G2.


## G2 HC/CB production activation authorization — 2026-11-17

| ID | Decision |
|---|---|
| RM-DEC-031 | The owner explicitly marked **step 1 HC/CB V4 visual review `APPROVE`** and gave provisional agreement to proceed beyond step 2 toward a narrowly scoped **G2 production activation PR** on 2026-11-17. Approved V4 means the original golden CB door/floor remain unchanged; HC connects the north wall under the original raised staircase landing; Evelyn uses the already approved walker and original foreground masks. This authorizes a **draft activation candidate and exact-head CI testing**, not automatic merging, full structural headroom certification or final phone/device/G2 release acceptance. Step 2 remains provisional until reproducible real-device evidence; all unverified tests must remain `NOT_RUN`. Preserve the original first-floor bitmap, gameplay/save authority and existing story gates. No change to Chapter II–III canonical scene readiness or 0/7 missing portrait status. |

**G2 release gate:** production-positive New Game → opening VN → Hall → Corridor → Bedroom → Corridor → Hall → VN/Match-3 → Continue must pass on the activation PR without in-memory approval fixture. Review phone/browser evidence and exact-head CI before an owner-authorized merge. An owner-accepted V4 render is not a phone measurement.
