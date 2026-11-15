# MAP-QA-08A — Story-aware POI targets and visual navigation calibration brief

**Status:** requirements baseline only (not a visually calibrated route network). **Owner:** manor-map. **Authority:** DRAFT_ONLY. **Prerequisites:** merged MAP-EDIT-05 #255; approved first-floor PNG remains immutable. No actual visual inspection of the PNG was performed in this PR, so no coordinates are asserted.

## Why this slice exists

The MAP-QA-05 22-waypoint/19-route document is a provisional test baseline, **not** a constraint to preserve in the next visual route calibration. The actual visual navigation author must inspect the approved 1672×941 PNG and map story-relevant places to reachable character footpoints, without guessing invisible corridors or turning debug/test-only transitions into doors.

Machine-readable inventory: `assets/raven/map/qa/drafts/map_qa_08_story_targets.v1.json`. It links the first-slice five hotspots and later proposed narrative scene triggers to candidate first-floor rooms. Every target has `pointPx: null` until direct pixel inspection; excluded entry/garden/conservatory beats are identified explicitly.

## Required target coverage by playable room

| Room | Story and POI needs | Notes |
| --- | --- | --- |
| Hall | arrival/Ada/Lucas; initial repair-list `RM-HS-001`; chairs/tea table; return/storm; estate plan | Keep furniture and stair feet impassable; hall-to-corridor contact is unresolved |
| Corridor | bedroom's blocked-door interaction `RM-HS-005`; bathroom access `RM-HS-003`; kitchen approach | Bathroom is a **vignette**, not a required full walkable room; no fabricated door line |
| Bedroom | restoration `RM-HS-002`, childhood object `RM-HS-004`, night return | Entry does **not** require bathroom repair; access is a physical jam/obstruction |
| Library/Archive | library door, desk/album, drawer, Lucas, storm window/wet records | Provisional story ordering; route to a safe floor beside furniture |
| Kitchen | ledger/table, electrical safety/preparation; later conservatory approach | Electricity/specialist work is a narrative gate, not a route generator |
| Entry, Conservatory, Garden | Rowan entrance, bench, fence / glass | **VISUAL_ONLY / OUT_OF_SCOPE** for this pass until physical/elevation/floor visibility is verified |

Scene IDs and hotspot IDs are references only; code in this slice never triggers them. All real doors, including `RM-DOOR-HALL-CORRIDOR` and `RM-DOOR-CORRIDOR-BEDROOM`, remain UNRESOLVED with null image-pixel sides. MAP-QA-07B handoffs remain TEST_ONLY. Story document `docs/DECISIONS.md` overrides obsolete Stage 1/2 bedroom-after-bath gates.

## Next implementation handoff: MAP-QA-08B (separate agent)

1. Open and inspect the **actual approved PNG** `a_detailed_top_down_isometric_game_map_illustratio.png` at full 1672×941 resolution. Verify SHA-256 `5e0edf97bd719fb1df95c7e9bea2f134d90adad0bc04d1771acc82a95a4d549a`, not merely a web search result or generated stand-in. Read `docs/DECISIONS.md`, `docs/NARRATIVE_GAMEPLAY_INTEGRATION.md`, `data/raven/production/map_narrative_routes.json`, `docs/qa/MAP-QA-05-first-floor-route-coverage.md`, current editor and QA-07B sources.
2. Use the story target manifest as a list of **intentions**, not as evidence of visible pixel positions. First label room floors, opaque/occluding walls, furniture bottoms, stair landings, obvious thresholds and hidden/uncertain areas on the approved image. Produce a per-feature evidence table with pixel bounding box, source visible/obscured, estimated actor clearance and confidence; do not infer walkability from decorative texture.
3. Build a **new, separate v1 DRAFT_ONLY candidate** at `res://assets/raven/map/qa/drafts/map_qa_08_visual_candidate.v1.json`. Do not overwrite `hall_routes_draft.v1.json` or immutable `first_floor_hall_pilot.v1.json`. Author coherent room-owned WALKABLE and NO-GO polygons first; then POI footpoints at safe floor positions. Avoid default strict AI blockers that owners cannot edit. Keep optional OPEN/REQUIRE policy explicit.
4. Route the character **only within visibly supportable room islands**, avoiding furniture/stairs/walls and one-cell zigzags, with orthogonal grid authored cells and full waypoint ownership. Use exact existing `RouteDocument` schema v1 and `RouteFreehand` / native editor. Reuse current `ManorNavigationGraph`, `RouteSession`, and Onoe movement adapter, not a new pathfinder. When creating fresh candidate, preserve MAP-QA-07B required start anchor IDs `QA-HALL-SPAWN`, `QA-CORRIDOR-WEST`, `QA-BEDROOM-RUG`, `QA-LIBRARY-NORTH`, `QA-KITCHEN-NORTH` (their exact coordinates may be reassessed in a **separate candidate** only); do not silently repurpose real production `RM-*` IDs.
5. Associate each placed point with this manifest's `QA-POI-*` ID and story IDs **in separate metadata**, not arbitrary new runtime `RM-*` gates. If target is absent from the PNG, keep `pointPx: null` and document `UNRESOLVED`. Do not automatically promote a proposed scene to playable, or place Rowan/Garden/Conservatory routes under invisible glazing.
6. Validate every route endpoint, cell adjacency, segment clearance (actual Onoe footprint, not just centre point), per-room reachability and safety under both original and modified constraints; validate JSON save/load round trip. Hall↔Corridor↔Bedroom in F6 is still only the **mocked** test transition until MAP-QA-09 verifies actual door footpoints. Keep all 11 manifest doors null/unapproved. Preserve Pause/Resume/Cancel, Pan/Follow, locked/gated door and Hall-only regression.
7. Add explicit automated tests for new draft structure, measured/uncertain POI traceability, altered zone validity and integrated MAP-QA-07B loading. Run Godot 4.7.2 and `bash scripts/check.sh` plus exact-head GitHub Actions. Provide a visual comparison: approved PNG with route overlay, labelled safe/blocked regions and unresolved gaps (separate QA diagnostic artifact), as well as full-length Onoe movement checks and owner manual acceptance instructions.
8. Only after owner visual review decide which candidate is worth promoting to future production integration. **Never** set `productionReady:true`, move real doors, mutate story/save/actual collision or claim user approval without evidence.

## Acceptance checklist for MAP-QA-08B

- All 16 presently route-relevant entries are either connected inside their own room via safe footpoints **or explicitly unresolved with a concrete image-based reason**; optional/future locations are not hidden in a fake route.
- No route enters bed, table, stairs, wall, plant, unsafe glazing or another room through an unverified threshold.
- A player selecting a target travels via authored anchors, never free tap-to-move or teleport.
- All new cells/routes are editable via Godot Route Editor; source IDs, schema v1 and adapter compatibility are preserved.
- Test-driven reachability is not mistaken for real pixel/actor clearance; unresolved doors remain unresolved until MAP-QA-09.

## Gate for MAP-QA-09 and later

MAP-QA-08B supplies **per-room** internally safe routes and candidate POI pixels. MAP-QA-09 separately confirms door thresholds, near-/far-side footpoints, foreground occlusion and locks. Only afterward can MAP-GAME-01 switch game navigation, then GAME-LOOP-01 connect runtime VN/Match-3. Do not treat this brief or automated tests as that approval.
