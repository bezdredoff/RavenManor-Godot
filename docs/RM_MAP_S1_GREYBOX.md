# RM-MAP-S1 — Full continuous map greybox (engineering preview)

**Status:** implemented as a standalone Prototype Lab test mode; full-season *physical layout remains unapproved*. This is a proposed seamless-floor feasibility prototype, not a new art bible, canonical floorplan or replacement for the accepted RM-VS-01 runtime.

## Play it
From Prototype Lab choose **5 · Whole Manor Map · S1 GREYBOX**. Or run `res://scenes/raven/season1_map_greybox.tscn`.

- Drag/pan around a single approximately 2150×2250 logical-unit layout. Use mouse wheel or the visible **−/+** buttons to zoom; recenter on the placeholder actor. Tap/click a block to route the animated **Onoe technical placeholder** to an approachable location. Onoe is NOT canonical Evelyn art.
- The UI shows eight area footprints: Entry, Hall, Archive, Corridor, Bedroom, Bathroom, Kitchen, Conservatory.
- It shows **11 canonical door relations** including four blocked future destinations: East Wing, Upper Floor, Service Wing and Garden. Door icons are green if navigable and red if blocked.
- Route planning uses a **25-unit AStarGrid2D grid, diagonal travel disabled**, with wall thickness, currently open door thresholds and padded major furniture obstacles. No unconstrained straight-line shortcuts through objects; target approach is snapped to the nearest valid point.
- Press **ВСЕ ПРОХОДЫ: ТЕСТ** to try physically connected paths across all seven currently explorable door edges *without changing saved progress*. Toggle **ПО СЮЖЕТНЫМ GATE** to respect door flags in the existing Raven save. This is an engineering override, never a gameplay unlock.
- Click a repair-related furniture block and **MATCH-3** to launch its referenced level directly in *isolated Content Preview*. Return to the map using **← Карта**. Match-3 preview does not alter Raven save.
- **До / После** recolors the selected block as a **local visual-state diagnostic only**. It does not award work points or commit a restoration.
- Map actor is **animated Onoe from UPDS owner-created test sheets**: down/up/left-right clips and idle first frame. Sprite stays upright while the floor is shown using a **shallow pseudo-orthographic depth compression (Y × 0.82)** and short shaded rear-wall facades. This is a technical view test, not an approved finished iso/3D pipeline.

## Source data and systems
- `data/raven/season1_world_map.json` owns room rectangles, shared global logical coordinates, physical doors, major furniture bounds, near-object interaction anchors, and authored local route detours.
- `scripts/raven/season1_map_greybox.gd` uses **AStarGrid2D** over one shared world to plan entirely orthogonal legal grid segments. Rooms, walls, door openings and furniture have simplified bounded occupancy. Camera projection is shared across all rooms.
- Main plot and accepted `RM-VS-01` are unchanged; game/save logic is neither migrated nor replaced.
- The Hall split staircase, locked doors under its landing, clock near Archive and seating group preserve approved architectural decisions.
- Bath has a physical footprint even though the vertical slice only needs a compact specialist vignette.
- The new graph **is independent of** `manor_greybox_graph.json`, which continues to serve accepted first-chapter navigation; consolidation must wait for layout approval and migration/alias verification.

## Design restrictions / QA still required
1. All footprints/door placements are **proposed**, not architectural measurements. In particular, global camera angle and projected wall heights still need validation with a map-scale mildly-chibi sprite.
2. Boundaries and 15 major object rectangles block **grid occupancy with padding**, but this is still only approximate bounding-box avoidance, NOT final polygon collider or full dressing collision certification. All additional furniture must join occupancy before style art starts. The first and last few pixels may interpolate from unsnapped standing points; no diagonal grid segments are allowed.
3. No actual finalized room artwork, layered wall cutaway, Y-sort, physical door opening, fog-of-war, map stream chunks or full mobile-release touch QA.
4. Touch drag/tap and portrait overlay must be checked on device. Mouse wheel and −/+ controls zoom; pinch-to-zoom is not implemented.
5. Selected prop→isolated Match-3 is a UI integration smoke only, not a transactional repair reward loop. First-chapter actual progression remains in `RM-VS-01`.
6. Need one complete 390×844 portrait capture + narrow/tall captures, walking from Hall to Conservatory, Bedroom and Archive in test mode, then repeat in gated mode. Check Onoe foot position, screen-space animated sprite scale (~50 logical screen pixels at initial zoom), clipping/occluders, and depth/perspective consistency.
7. This pseudo-orthographic projection is deliberately reversible and data-driven. **Do not change approved room layout IDs or commit to a final angle** until device comparison against an actual layered background.

## S1 geometrical approval gate
Approve ONLY after physically inspectable gameplay test establishes continuous camera travel and reliable reachability of each room's planned interaction anchors. Changes should update door route anchors and furniture bounds **before** generating painted rooms or VN/map sprite sheets. See `docs/assets/RM_MAP_S1_CONTIGUOUS_LAYOUT_GATE.md`.

## Camera & Hall art calibration added in PR #15
- First candidate: **55° down from horizontal**, matching the former depth ratio 0.82. Cycle **45° / 55° / 65°** directly in Prototype Lab; screen→world picking remains the mathematical inverse of the projected plane.
- Turn **Арт: ВКЛ** on/off to compare a measured Hall SVG architecture base, burgundy rug and separate clock/seating/console/portrait visual proxy sprites against the original bounding boxes. **Габариты** reveals collision/interaction bounds.
- Onoe remains a temporary authorization-only actor. These SVG graphics were handcrafted layout-calibration stand-ins, not accepted painterly art, and the generated mood-board images are not spatially authoritative.
- Full generator prompts, isolation and export acceptance: `docs/assets/RM_CAMERA_ART_PILOT.md`.

## Portrait hub framing (owner preference, PR #16)
- **65° downward from horizontal** now starts by default, with floor vertical ratio `sin(65°) ≈ 0.906`. 45° and 55° are diagnostic comparisons only; camera and artwork lock still requires visual phone approval.
- Default hub zoom **0.74×** (candidate comparison presets **0.68× / 0.74× / 0.80×**). Map camera opens on the left-middle of Hall so the clock, seating area, Onoe and under-stair door are legible; the entire Hall and adjacent rooms cannot *all* fit at this zoom and are intentionally explored by scrolling.
- Actor sprite has shared world-height calibration (`ACTOR_WORLD_HEIGHT = 90`), keeping down and side animations consistent and displaying at ~67 logical screen pixels at 0.74×; Onoe remains noncanonical.
- Main HUD is overlaid on a **full-screen map**. Compact translucent top 86px, bottom 90px; technical test toggles are collapsed in **Настр.**, not constantly visible.
- Top controls: minus, numeric zoom preset button, plus, recenter to character, debug settings. Inside settings: story gate test, art toggle, bounds toggle, camera angle, safe viewport overlay, whole-map overview. Match-3 and before/after actions remain in the bottom overlay.
- Debug safe viewport is calculated from current control size, independent of room scale; automatic layout and tests cover **390×844, 412×915, 430×932**. This is logical viewport layout, **not a substitute** for actual iOS/Android browser safe-inset/device testing.
- Match-3 isolation and persistent Raven-save semantics are unchanged. Original world coordinates and collision paths remain unchanged.
