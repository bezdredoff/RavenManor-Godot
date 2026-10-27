# Raven Manor — project context

**Historical baseline reconciled 2026-10-26:** Stage 1 v0.5 narrative and Stage 2 v0.2 architecture remain the approved source baseline; Stage 3 v0.2 research remains planning evidence. Godot 4.7.2 Raven foundation, authored Hall → Corridor → Bedroom navigation, standalone `RM-VS-01` vertical slice (VN, three Match-3 levels, restorations, clue/night/save), Prototype Lab launcher, isolated previews and CI/Web deployment are **implemented on main**. Owner accepted engineering Prototype Lab on 2026-10-24.

The subsequent independent whole-season continuous-map feasibility preview has eight proposed area footprints/11 door relations, portrait-oriented 65°/0.74× preferred framing, and preliminary AI1/AI2/SVG/PLAN art comparisons. Eight generated Hall PNG files and their provenance/reconstructed prompts landed in merged PR #17; they are **not** spatially calibrated or approved as final artwork.

**Room Builder PWA v0.1** (merged PR #18) supports finger/stylus-oriented flat room layout, locally imported PNGs/sprite sheets, JSON/PNG export and offline-capable installation. PR #19 fixed the public `/builder/` route under simultaneous custom Actions and branch/Jekyll Pages publication. The user confirms the public tools load and work; complete Android S Pen and production scene/device QA is still unrecorded. Standalone JSON → Godot output is draft-only, not wired to the canonical graph or production scene.

**NEXT:** `RM-PIPE-001`, prove a spatially calibrated, layered, independently editable Hall scene starting from Room Builder and ending in a reversible Godot preview and controlled art generation. See `docs/NEXT_PLAN.md`, `docs/ROOM_PIPELINE_NEXT_GATE.md`, `docs/STATUS.md`.

Source-repository boundary: [bezdredoff/RavenManor](https://github.com/bezdredoff/RavenManor) provides game bible, narrative and source-design materials; [bezdredoff/RavenManor-Godot](https://github.com/bezdredoff/RavenManor-Godot) provides executable Godot, tests, Web delivery, source art pilot and Room Builder. Latest explicit owner decisions in `docs/DECISIONS.md` supersede older conflicting Stage documents, which remain historical. The imported 70-requirement audit referred to UPDS-godot, not a completed current Raven audit.

## Narrative/runtime sync (2026-10-26)

The latest product-owner story decisions are now mirrored into the executable repository in `docs/NARRATIVE_GAMEPLAY_INTEGRATION.md` and `data/raven/season1_narrative.json`. They preserve all existing save/progression IDs while correcting the playable fiction: Evelyn returns as the last heir because of an inheritance letter; memory of the supernatural faded while she was away and returns only in fragments; Ada/Lucas/Rowan initially read as housekeeper/notary/gardener; Match-3 is preparation work and specialist repairs remain specialist work.

`RM-VS-01` now begins with the inheritance/arrival beat before bedroom access, uses bedroom sorting plus bathroom diagnosis/preparation, reaches a usable bedroom+bathroom for the first night, uses food delivery while the kitchen remains unsafe/unready, and ends by pointing toward kitchen plus Rowan's garden/conservatory visit. It deliberately does **not** reveal the cause of the memory effect or explicitly confirm Ada/Lucas/Rowan's supernatural nature.

## Product synopsis

Raven Manor is a portrait-first cozy gothic-anime narrative Match-3 restoration game. Evelyn Raven, the last heir, returns to the family manor after an unexpected inheritance letter and rediscovers a town she remembers incompletely. Outside the town, memories tied to supernatural life fade progressively with time away; returning restores fragments without immediately explaining why. Mystery, tenderness and eccentric humor, not horror.

Season one: six chapters across entrance, hall, west/residential corridor, bedroom, bathroom, kitchen, library/archive and conservatory, with unsafe upper/future wings temporarily closed for structural, utility or wiring reasons. Ada is a resident ghost housekeeper, Rowan is a werewolf gardener and Lucas is a vampire notary; reveals occur gradually.

Core loop: short VN scene → selected hotspot → sorting/cleaning/clearing/finding Match-3 preparation → first-clear work points → visible restoration or specialist action → new clue/state/door. Match-3 does not fictionally perform plumbing/electrical/structural repairs itself.

`RM-VS-01`: Hall → Corridor → Bedroom access independent from bathroom repair; authored graph routing; 3 Match-3 first-clear rewards (2/2/2); bedroom restoration cost 2; bathroom specialist vignette cost 4; clue and Ada scenes; first night and persisted resume.

Constraints: no free tap-to-move, only authored hotspot/door routes in the accepted slice. Doors may remain visually open once unlocked. Bathroom may be a corridor-side vignette. Onoe art is owned/authorized only as a technical placeholder, not canonical Evelyn. Preserve stable `RM-*` IDs, separately designed VN vs mildly-chibi map characters, coherent style gating and provenance before bulk art.

## Production context update — 2026-10-27

The current executable branch now includes source-verbatim UPDS Match-3 gameplay/paging/preferences (merged #46), plus upstream board shape, tile-motion, easing, tutorial predicates and real Godot smoke from merged [PR #54](https://github.com/bezdredoff/RavenManor-Godot/pull/54). This **does not yet replace Raven's Match-3 greybox with the complete UPDS screen**. CODE-02-00 is merged; CODE-02-01/02 continue with input, frame/HUD integration and mobile QA; GFX-10 remains subject to art acceptance.

The phone-to-GitHub ZIP/candidate PR/independent CI flow has real owner-confirmed upload evidence from merged [PR #56](https://github.com/bezdredoff/RavenManor-Godot/pull/56); remaining malicious-archive live and phone artifact review gates keep MOB-04 in progress. The working dashboard and current statuses are defined by the paired CODE/GFX roadmaps, `code_work_packages.json` and `production_progress.json`. Do not infer current progress from the historical v0.1 narrative/room-builder paragraphs above.
