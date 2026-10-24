# Approved product decisions / overrides

Updated 2026-10-24. These decisions override conflicting clauses in preserved historical Stage 1/2 files. Do not silently modify old source documents.

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

**Outdated known clauses:** older `04_vertical_slice_flow.md`, Stage 2 hotspot/economy CSV/MD and door FSM may require bathroom repair before bedroom access or repeated door animations. Implement latest product decisions without renaming `RM-*` IDs; record any dependency changes in a migration note. Do not claim the archived documents are synchronized to this override.
