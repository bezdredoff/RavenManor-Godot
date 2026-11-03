# Raven Manor — game feature coverage and release gates (2026-11-03)

Legend: **delivered component** is not **owner accepted integrated gameplay**. This is a planning matrix, not a claim of completed live QA.

| Feature / journey | Runtime source | Work packages | Acceptance |
|---|---|---|---|
| New/Continue/Pause/Settings | UPDS menu and Raven preferences adapter | GAME-UI-01, CODE-04-01 | Restart, pause, locale/audio on device |
| Intro VN and scene choices | Raven VN game view / approved story data | CODE-03, VN-RUNTIME-01 | Real playable choices, no draft leakage |
| Hall→Corridor→Bedroom | manor_navigation_graph, room importer | CODE-05-01/02, RM-GAP-001/006 | 65° physical route, collision, occlusion |
| Match-3 board/hints/help | UPDS core, Raven presenter | CODE-02-03/06 | Touch/swipe, two-tile hint, modal Help |
| Level campaign | 3 current RM levels, 22 upstream candidates | GAME-M3-01 | Stable IDs, locks, replay, balanced sequence |
| First-clear rewards and repair | Raven reducer/store | CODE-07-02, GAME-LOOP-01 | Atomic 2/2/2 awards, 2/4 costs, no double charge |
| First session guidance | Story + gameplay UI | GAME-ONBOARD-01 | New player understands tasks and navigation |
| Booster inventory | UPDS upstream feature review | GAME-BOOST-01 | Source audit, acquire/use/reload |
| Journal / clues / objectives | Raven narrative | GAME-JOURNAL-01, CODE-07-03 | No spoilers, correct state, RU/EN/BE |
| Full six chapters | production story catalog | CODE-08-01, CODE-12-W1..W5 | Beat-to-scene map, playable transitions and gates |
| Chapter/season end | Raven story state | GAME-ENDING-01 | No dead-end, saved post-ending state |
| Web/mobile/offline/release | Raven CI/Pages | CODE-10-02, GAME-QA-01, GAME-RELEASE-01 | Evidence-linked device + release checklist |

**Milestones:** Foundation (menu/settings/save/input) → Vertical Slice (Hall, VN, 3 levels, 2 repairs) → Campaign (adapted levels, chapter graph) → Content/Art (map chibi, tiles, audio) → Release Candidate (locales, device/offline, save migration). P2 full-season work enters only after vertical-slice acceptance.
