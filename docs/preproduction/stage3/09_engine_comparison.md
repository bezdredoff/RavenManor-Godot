# 09 — Same-scenario engine comparison | Stage 3 v0.1

**Scenario:** click broken clock beyond bedroom door → walk corridor → open door → foreground-masked passage → skirt furniture → reach clock's interaction anchor → validate earned reward → commit repaired clock state to save. For Raven Manor actual main clock is in HALL; this is an artificial apples-to-apples **technical comparison**, not a change to canon.

| Criterion | Godot 4.x | Unity 6 + AI Navigation | RPG Maker MZ |
|---|---|---|---|
| Authoring speed | Good with bespoke room schema; initial tooling needed | Good for 3D/2.5D standard NavMesh; significant 2D accommodation | Fast on tiles, weak for painted arbitrary geometry |
| Arbitrary illustrated 2D map | Native canvas and per-room collision; strong | Possible, but NavMesh is 3D-focused and 2D extension/custom paths often required | Map grid/events assumption conflicts with continuous painted space |
| Path solver | **AStar2D** for explicit anchor graph; **NavigationRegion2D/NavigationAgent2D** for continuous navmesh; do not use both as competing path truth | NavMeshSurface/Agent/Obstacle/Link optimized for world navigation; 2D painted projection needs custom integration | Tile passability and path/event movement; pixel navigation requires plugins |
| Door crossing | Explicit portal state machine, dual anchors, collision toggle after open, **NavigationLink2D optional**; locks checked at gate layer | NavMeshLink or Off-Mesh Link with authored transition + animation logic | Event Pages, switches, conditional Move Routes; rigid for smooth arbitrary walls |
| Dynamic furniture | Change navmesh/obstacles cautiously; avoid rebake per cosmetic prop | Carve NavMeshObstacle for meaningful blockers; careful latency | Tile/events changes; coarse granularity |
| Occlusion and camera | Canvas layers/Y-sort + foreground masks; Camera2D presets, zoom/pan | SortingGroup/2D Sorting layers + Cinemachine; strong editor tooling | Event priority, screen scroll; limited per-pixel foreground |
| Save | Own keyed state by stable IDs with atomic gate/repair commit | Custom ScriptableObject definitions + runtime saved state; separate serialization | Native switches/variables, event page conditions |
| Debug / test | Visible nav polygons, anchor/portal overlays; automated scene and save tests | Navmesh debug/scene tests strong; extra orchestration | Event test fast, automated tests more limited |
| Reuse / support | High for purpose-built 2D toolkit | High if team already invested in Unity; higher architecture overhead here | Low for original layered portrait map navigation |

**Recommendation [INFERENCE]:** Godot 4.x with `AStar2D` corridor graph for VS, manual per-room walkable polygons, deliberate traversal/occlusion contract. Bake-off `NavigationAgent2D` when branching walkable geometry increases. Do not add an addon before a concrete baseline failure.

**Primary docs:** https://docs.godotengine.org/en/stable/tutorials/navigation/ ; https://docs.godotengine.org/en/stable/classes/class_astar2d.html ; https://docs.godotengine.org/en/stable/classes/class_navigationagent2d.html ; https://docs.unity3d.com/Packages/com.unity.ai.navigation@2.0/manual/index.html ; https://www.rpgmakerweb.com/products/rpg-maker-mz . 

**Validation needed:** exact engine version, 2D/3D nav APIs and plugin compatibility must be pinned and smoke-tested on target Android portrait and save reload before adoption. This is design research, NOT an implementation test.