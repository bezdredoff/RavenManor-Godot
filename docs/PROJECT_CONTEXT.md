# Raven Manor — project context

**Status reconciled 2026-10-25:** Stage 1 v0.5 narrative and Stage 2 v0.2 architecture remain the approved source baseline; Stage 3 v0.2 research remains planning evidence. Godot 4.7.2 Raven foundation, authored Hall → Corridor → Bedroom navigation, standalone `RM-VS-01` vertical slice (VN, three Match-3 levels, restorations, clue/night/save), Prototype Lab launcher, isolated previews and CI/Web deployment are **implemented on main**. Owner accepted engineering Prototype Lab on 2026-10-24.

The subsequent independent whole-season continuous-map feasibility preview has eight proposed area footprints/11 door relations, portrait-oriented 65°/0.74× preferred framing, and preliminary AI1/AI2/SVG/PLAN art comparisons. Eight generated Hall PNG files and their provenance/reconstructed prompts landed in merged PR #17; they are **not** spatially calibrated or approved as final artwork.

**Room Builder PWA v0.1** (merged PR #18) supports finger/stylus-oriented flat room layout, locally imported PNGs/sprite sheets, JSON/PNG export and offline-capable installation. PR #19 fixed the public `/builder/` route under simultaneous custom Actions and branch/Jekyll Pages publication. The user confirms the public tools load and work; complete Android S Pen and production scene/device QA is still unrecorded. Standalone JSON → Godot output is draft-only, not wired to the canonical graph or production scene.

**NEXT:** `RM-PIPE-001`, prove a spatially calibrated, layered, independently editable Hall scene starting from Room Builder and ending in a reversible Godot preview and controlled art generation. See `docs/NEXT_PLAN.md`, `docs/ROOM_PIPELINE_NEXT_GATE.md`, `docs/STATUS.md`.

Source-repository boundary: [bezdredoff/RavenManor](https://github.com/bezdredoff/RavenManor) provides game bible, narrative and source-design materials; [bezdredoff/RavenManor-Godot](https://github.com/bezdredoff/RavenManor-Godot) provides executable Godot, tests, Web delivery, source art pilot and Room Builder. Latest explicit owner decisions in `docs/DECISIONS.md` supersede older conflicting Stage documents, which remain historical. The imported 70-requirement audit referred to UPDS-godot, not a completed current Raven audit.

## Product synopsis

Raven Manor is a portrait-first cozy gothic-anime narrative Match-3 restoration game. Evelyn Raven returns to a long-abandoned family manor and rediscovers a town of supernatural residents. Outside the town, memories of supernatural life fade naturally with time. Mystery, tenderness and eccentric humor, not horror.

Season one: six chapters across entrance, hall, west/residential corridor, bedroom, bathroom, kitchen, library/archive and conservatory, with unsafe upper/future wings temporarily closed for structural, utility or wiring reasons. Ada is a resident ghost housekeeper, Rowan is a werewolf gardener and Lucas is a vampire notary; reveals occur gradually.

Core loop: short VN scene → selected hotspot → sorting/cleaning/finding Match-3 → first-clear resource → visible restoration → new clue/state/door. Difficult repairs involve specialists.

`RM-VS-01`: Hall → Corridor → Bedroom access independent from bathroom repair; authored graph routing; 3 Match-3 first-clear rewards (2/2/2); bedroom restoration cost 2; bathroom specialist vignette cost 4; clue and Ada scenes; first night and persisted resume.

Constraints: no free tap-to-move, only authored hotspot/door routes in the accepted slice. Doors may remain visually open once unlocked. Bathroom may be a corridor-side vignette. Onoe art is owned/authorized only as a technical placeholder, not canonical Evelyn. Preserve stable `RM-*` IDs, separately designed VN vs mildly-chibi map characters, coherent style gating and provenance before bulk art.
