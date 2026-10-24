# RM-MAP-S1 — Full continuous map greybox (engineering preview)

**Status:** implemented as a standalone Prototype Lab test mode; full-season *physical layout remains unapproved*. This is a proposed seamless-floor feasibility prototype, not a new art bible, canonical floorplan or replacement for the accepted RM-VS-01 runtime.

## Play it
From Prototype Lab choose **5 · Whole Manor Map · S1 GREYBOX**. Or run `res://scenes/raven/season1_map_greybox.tscn`.

- Drag/pan around a single approximately 2150×2250 logical-unit layout; use wheel to zoom on desktop, button to recenter on Evelyn. Tap/click a block representing an object to have the map avatar route to a designated approach point.
- The UI shows eight area footprints: Entry, Hall, Archive, Corridor, Bedroom, Bathroom, Kitchen, Conservatory.
- It shows **11 canonical door relations** including four blocked future destinations: East Wing, Upper Floor, Service Wing and Garden. Door icons are green if navigable and red if blocked.
- Press **ВСЕ ПРОХОДЫ: ТЕСТ** to try physically connected paths across all seven currently explorable door edges *without changing saved progress*. Toggle **ПО СЮЖЕТНЫМ GATE** to respect door flags in the existing Raven save. This is an engineering override, never a gameplay unlock.
- Click a repair-related furniture block and **MATCH-3** to launch its referenced level directly in *isolated Content Preview*. Return to the map using **← Карта**. Match-3 preview does not alter Raven save.
- **До / После** recolors the selected block as a **local visual-state diagnostic only**. It does not award work points or commit a restoration.
- The map shows a schematic circle for Evelyn, not Onoe or approved canonical character art; all furnishings are bounding-box placeholders.

## Source data and systems
- `data/raven/season1_world_map.json` owns room rectangles, shared global logical coordinates, physical doors, major furniture bounds, near-object interaction anchors, and authored local route detours.
- `scripts/raven/season1_map_greybox.gd` uses `AStar2D` through room centers, actual portal nodes and selected detours, while drawing all areas in the **same world transform**.
- Main plot and accepted `RM-VS-01` are unchanged; game/save logic is neither migrated nor replaced.
- The Hall split staircase, locked doors under its landing, clock near Archive and seating group preserve approved architectural decisions.
- Bath has a physical footprint even though the vertical slice only needs a compact specialist vignette.
- The new graph **is independent of** `manor_greybox_graph.json`, which continues to serve accepted first-chapter navigation; consolidation must wait for layout approval and migration/alias verification.

## Design restrictions / QA still required
1. All footprints/door placements are **proposed**, not architectural measurements. In particular, global camera angle and projected wall heights still need validation with a map-scale mildly-chibi sprite.
2. Boundaries and large objects are drawn as schematic blocks. Their outlines visualize collisions but **there is no full polygon collider-based dynamic avoidance engine** yet; authored guidepoints route around known obstacles. Do not assert production collision correctness until all furnishings and edges pass route-obstruction tests.
3. No actual finalized room artwork, layered wall cutaway, Y-sort, physical door opening, fog-of-war, map stream chunks or full mobile-release touch QA.
4. Touch drag/tap and portrait overlay must be checked on device. Mouse wheel zoom is available; pinch-to-zoom is not implemented.
5. Selected prop→isolated Match-3 is a UI integration smoke only, not a transactional repair reward loop. First-chapter actual progression remains in `RM-VS-01`.
6. Need one complete 390×844 portrait capture + narrow/tall captures, walking from Hall to Conservatory, Bedroom and Archive in test mode, then repeat in gated mode. Validate map viewport, occluders and collision footprints before commissioning room assets.

## S1 geometrical approval gate
Approve ONLY after physically inspectable gameplay test establishes continuous camera travel and reliable reachability of each room's planned interaction anchors. Changes should update door route anchors and furniture bounds **before** generating painted rooms or VN/map sprite sheets. See `docs/assets/RM_MAP_S1_CONTIGUOUS_LAYOUT_GATE.md`.
