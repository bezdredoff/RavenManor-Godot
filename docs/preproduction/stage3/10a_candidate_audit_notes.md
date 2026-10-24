# 10a — Candidate audit: research update v0.2 (2026-10-24)

Scope: public documentation/repositories only. This is an evidence audit, **not** a runtime installation, build, exported mobile test, or exhaustive line-by-line security review. GitHub self-reported CI/test counts are not independently executed.

| Candidate | Source-backed finding | Decision | Risk/remaining test |
|---|---|---|---|
| Official demos | Official demo repository with permissive examples; engine-version branches must match | **reference only** | Open relevant 2D nav examples in pinned Godot |
| Phantom Camera | MIT Godot 4 camera add-on inspired by Cinemachine | **defer** | Use Camera2D first; A/B portrait focus, zoom, reduced motion |
| Dialogue Manager | Purpose-built nonlinear dialogue plugin; major compatibility depends on Godot branch | **adapt conditionally** | Pin engine and plugin release; check localized font, save flags, iOS/Android export |
| Godot Town Demo | Godot 4.3 scene transitions, enterable buildings, NPC dialogue and collisions | **reference only** | Repo license and test guarantees not independently confirmed; tile maps not painted manor map |
| Ali0600 RPG Template | README declares Godot 4.7, data-driven movement/warps/saves, GitHub CI, substantial test suite | **reference only** | Framework heavier than manor; very recent/unreleased engine requirement; verify LICENSE and reproducibility before copying |
| noidexe/top-down-action-rpg-template | Repository displays MIT license; demo and project files available | **reference only** | Version age and lack of documented CI make direct adoption unjustified |
| quiver-dev/top-down-shooter-core | Godot 4 template, MIT; README explicitly says not standalone | **reject as base** | Shooter/gameplay framework does not map to cozy restoration |
| snddude/godot-interaction_system | MIT minimal plugin; interactable and interaction components use raycasts/colliders with signals | **reference only** | Raycast-based player facing interaction differs from click-hotspot→path→anchor; mobile tap/save integration untested |
| VOID-VVK/InteractionSystem-CS | MIT, Area2D proximity, Godot 4.6+ Mono/.NET 8 | **reject for slice** | Brings C# dependence and proximity-first input to a GDScript painted-map project |
| MASSHUU12/godot-interaction-system | MIT but README explicitly says GitHub repo is no longer maintained; current code moved to Codeberg, C# | **reject GitHub copy** | Repository is stale and adds C# ecosystem |
| Native Area2D hotspot | Standard Godot engine primitive | **adopt** | Must implement click/tap target, graph target, gating, save states and tests ourselves |
| Native AStar2D+Camera2D | Native engine API | **adopt for greybox** | Compare with NavigationAgent2D on same painted corridor/door set before irreversible implementation |

Direct repository URLs:
- https://github.com/godotengine/godot-demo-projects
- https://github.com/ramokz/phantom-camera
- https://github.com/nathanhoad/godot_dialogue_manager
- https://github.com/odylic/godot-town-demo
- https://github.com/Ali0600/rpg-template
- https://github.com/noidexe/top-down-action-rpg-template
- https://github.com/quiver-dev/top-down-shooter-core
- https://github.com/snddude/godot-interaction_system
- https://github.com/VOID-VVK/InteractionSystem-CS
- https://github.com/MASSHUU12/godot-interaction-system

### Evidence thresholds

- **Confirmed by public source:** stated purpose, documented major capabilities, publicly claimed licenses/versions/dependencies.
- **Not verified:** actually passing CI at pinned commit, binary mobile compatibility, absence of undesirable autoload side effects, stable API across pinned releases, latest substantive commit (GitHub page dates can be misleading), exact save migration compatibility.
- **Gate before adoption:** pin Godot stable version + plugin commit, inspect actual LICENSE and dependencies, run mobile touch smoke test and headless reload-after-door-save test. Until those pass, use native components and treat external plugins as optional.