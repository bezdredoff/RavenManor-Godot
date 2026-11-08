# CODE-05-02 — Manor navigation integration contract for A/B/C (draft v1)

**As-of:** 2026-11-08 · **Owner:** `manor-map` · **Status:** ISOLATED_MODULE_ONLY, not accepted geometry/gameplay.
**GitHub:** [PR #238](https://github.com/bezdredoff/RavenManor-Godot/pull/238), art producer [#239](https://github.com/bezdredoff/RavenManor-Godot/pull/239), Room Builder producer [#240](https://github.com/bezdredoff/RavenManor-Godot/pull/240).
**Reference `main`:** `4c4145a935419b5cfaa69e8e1bde90a71717ed7a`; re-check before integration.

## Authority, spaces, ownership

| Input | Source | Coordinates | Import to AStar? |
| --- | --- | --- | --- |
| Current authored graph | `data/raven/manor_greybox_graph.json` | **independent-greybox** XY | Existing pilot only |
| Art source raster | root `a_detailed_top_down_isometric_game_map_illustratio.png` (blob `b50bc36cffd3d3aca7e81a0cea28bb3d0c0e9563`) | Image **sourcePixel** XY | **NEVER** |
| Agent A v1 art manifest | `assets/raven/map/first_floor_manifest.v1.json` in #239 | `referenceGreyboxPoint` is still independent-greybox; `sourcePixelFootpoint` is null; `calibratedWorldPlanPoint` pending | **NO** until explicit calibrated export |
| Agent B v2 Room Builder | `firstFloorDraft.navigationAnchors[].point` in #240 | **unprojected world-plan** XY under `calibration.worldRect` | preview-only, **after all 13 IDs/rooms/frame pass** |
| Game prototype screen | `season1_map_greybox.gd` | projection: screenX=offsetX+zoom*worldX; screenY=offsetY+zoom*sin(65°)*worldY | **NEVER** as graph data |

**World-plan provisional reference**: origin `(0,0)`, x right, y down; extent `[2150,2250]`, from `data/raven/season1_world_map.json`. This world frame and room footprint are **not physically owner-accepted**. No automatic mapping between independent-greybox and world-plan is defined. Agent A's pixel→world mapping remains unresolved; image landmark or projected screen values are not a substitute. The scene must apply display projection **once** after receiving world coordinates. B already renders its painted base without double-applying `sin(65°)`; distinguish the PNG render surface from world-plane actor positions.

**Critical hazard:** Old Hall graph spawn `RM-NAV-HALL-SPAWN=[400,300]` is NOT inside B's proposed world Hall rect `[500,150,700,690]`. Identity reinterpretation yields a silently displaced actor. Partial 13-anchor overlays mix coordinate systems; `apply_preview` remains a *diagnostic-only* backwards-compatible helper. Production-facing integration MUST use `from_builder_draft` with all anchors, or a separately reviewed full v1 `world-plan` candidate.

## Producer A/B/C handshake

1. **A** preserves all 13 `RM-NAV-*` IDs, room ownership and kinds in `navigationReferenceAnchors`. `referenceGreyboxPoint`/pixel positions are never forwarded. A may add nullable `calibratedWorldPlanPoint` after measured image registration with source hash, residuals and explicit approval metadata; the current manifest has **0/13 calibrated points** and `integrationAllowed=false`.
2. **B** preserves 8 `RM-ROOM-*` room identities and 11 door IDs/pairs from `season1_world_map.json`. Its optional nested `firstFloorDraft` schemaVersion **2** inside a **v1** Room Builder project remains DRAFT_ONLY. `navigationAnchors` must contain **exactly the 13 canonical `RM-NAV-*` IDs**, each with the same `roomId`, finite `point:[worldX,worldY]` in its registered room and fixed world frame. B's standalone fixture `RM-NAV-HALL-CHECK` is only a noncanonical marker and intentionally fails the navigation consumer.
3. **C** may call `GeometryAdapter.audit_art_reference(canonical, art_manifest, world_map)` for **ID parity only**, then `GeometryAdapter.from_builder_draft(canonical, project_or_draft, world_map)` for a complete DRAFT_ONLY overlay. Both inspect inputs read-only; neither mutates campaign state, approved map data, collisions or game scenes. Result `data.provenance.coordinateSpace="world-plan"`, `productionReady=false`, `runtimeApproved=false`.
4. All producer IDs/room relationships must be reconciled; **near/far anchors on two sides of a door** must be visually calibrated and checked for actual clearance. Anchors are movement *feet* pivots; not object center, sprite top-left or pixel coordinates. No new RM-* IDs or door gates without an integration decision.
5. No actor is placed into the new illustration until Hall→Corridor→Bedroom continuity, door semantics, stairs, obstacle clearance, actor depth, masking, all paths and human touch/device QA are independently accepted. Future east wing/upper floors remain inaccessible.

**v1 consumer candidate representation** (after explicit calibration, never copied from the greybox):

```json
{
  "schemaVersion": 1,
  "coordinateSpace": "world-plan",
  "productionReady": false,
  "anchors": [
    {"id":"RM-NAV-HALL-SPAWN","roomId":"RM-ROOM-HALL","position":[850,700]}
  ]
}
```

The single-anchor array above shows a *record shape*, **not a valid production-facing complete set**. The strict B adapter requires all 13. The numeric values above are synthetic fixture examples; **not calibrated painting positions**. `apply_preview` is retained for isolated diagnostics but must not be called as the game's full replacement geometry.

## Godot host API and lifecycle (INTEGRATION OWNER ONLY)

Dependencies: `Graph = preload("res://scripts/raven/manor_navigation_graph.gd")`, `Session = preload("res://scripts/raven/manor_route_session.gd")`. Keep one graph and one session for the actor; existing `manor_greybox.gd` already owns actor, Tween and input hotspots. Do **not** create a second movement/save authority. The code below describes sequence, not a patch to shared scene:

```gdscript
var graph := Graph.new()
graph.rebuild(snapshot, reviewed_preview_or_existing_greybox)
var route_session := Session.new(graph)
var feet_anchor: String = route_session.restore(snapshot)
actor.position = graph.position(feet_anchor)

# On authored hotspot press ONLY (or a reviewed door mapped to a hotspot).
var request: Dictionary = route_session.request_hotspot("RM-HS-005")
if request.ok:
    dispatch_next_segment()

func dispatch_next_segment() -> void:
    var step: Dictionary = route_session.next_segment()
    if step.is_empty():
        return # No reachable authorized segment, not free-point movement.
    if step.get("arrived", false):
        on_hotspot_reached(step.hotspotId)
        return
    # Existing actor/controller drives *one* authored step.
    # Move feet step.fromPosition -> step.toPosition; do NOT immediately ack.
    move_actor_one_segment(step)

# Called from animation/physics after feet really reach the segment endpoint:
var ack: Dictionary = route_session.finish_segment(step.toAnchorId)
if not ack.ok:
    if ack.error == "segment-blocked":
        stop_actor_tween()
        actor.position = graph.position(ack.rollbackAnchorId)
    return
if ack.status == "arrived":
    on_hotspot_reached(ack.hotspotId)
elif ack.status == "continue":
    dispatch_next_segment()
# ack.status == "cancelled" or "blocked": remain stationary.

# On selection replacement:
route_session.request_hotspot(new_hotspot_id) # queue if moving
# On user cancel:
var result := route_session.cancel()
# If result.finishCurrentSegment, finish current safe segment first; 
# do not kill tween then jump from old anchor across the wall.

# After safe movement/rest, not during a Tween:
var position_event := route_session.checkpoint_event(next_unique_event_id())
if not position_event.is_empty():
    # Process with existing RavenReducer -> RavenCampaignStore.
    # No second save file and no new event schema.
    commit_existing_campaign_event(position_event)
```

**Door gate changes:** rebuild the graph from the current authoritative snapshot after a successful reducer `door_unlock` or on state restore. This game has no ordinary door-close event in the current reducer; simulated gate closure in tests ensures the handler fails closed. Before every new segment the route session checks `segment_available`. If a gate changes mid-crossing, a later `finish_segment` explicitly refuses arrival with `segment-blocked` and provides the previous confirmed anchor for a controlled rollback; host must stop/correct visual motion without persisting a blocked-room checkpoint. For a physical actor, the integration owner must also stop collision traversal *as soon as the gate changes*, before crossing an occupied threshold—this module does not implement physics.

**Room transition:** intermediate `transition` anchors on opposing sides of an authored door are ordinary graph segments with a `doorId` gate, not arbitrary scene-teleport destinations. Only after `finish_segment` acknowledges the far-side anchor may the host trigger room-specific visuals/camera/occlusion and enter an interior vignette. `RM-HS-005` (corridor door clearance) unlocks `RM-DOOR-CORRIDOR-BEDROOM` via existing reducer story events. `RM-HS-002` remains **inside** bedroom for restoration. Bathroom vignette must not gate bedroom travel. Locked east wing has no route until later accepted story/navigation work.

**Save/resume:** only `kind:"safe"` anchors may be emitted via `position_checkpoint`, with existing `roomId/anchorId`. At an interaction anchor, the session chooses the last *confirmed safe* anchor, never a mid-edge interpolated point. `safe_checkpoint_anchor` validates room ownership, known ID, graph reachability and safe kind; unknown/historical IDs fall back to a valid reachable safe point (Hall if necessary). Campaign schema stays v1, and current VN/Match-3 switches keep using their existing state authority. Test corrupted or stale checkpoint recovery and manually review VN/Match-3 return placement in a later integration PR.

## Explicit pending changes to canonical scene (NOT in #238)

- Replace the preview-only `season1_map_greybox.gd` free grid-target approach with hosted reviewed AStar2D-author anchor routing, retaining grid/walls only for collision diagnostics if useful; or adapt existing `manor_greybox.gd` Tween to call this session's per-segment API. One final scene, one movement authority.
- Verify the actual image world transform versus B's v2 calibration (no double projection), door near/far pairs, logical room boundaries and hotspot hit targets.
- Add geometry-based blocked threshold/door collision; precise separate footprints for two chairs, round table, clock, staircase, desks and route corridors. Add actor feet Y-sort and clean foreground masks; no art-overlay acceptance by visual analogy alone.
- Hook graph refresh after reducer/store state changes and before physical movement. Implement recovery when collision geometry invalidates old checkpoint; coordinate version changes require separate reviewed migration.
- Test Hall→Corridor→Bedroom, bedroom without Bathroom, locked/unlocked door persistence, cancellation/replacement and gate change during Tween, all VN/Match-3 transitions, real mobile 390×844 / 412×915 / 430×932 and tablet touch/S Pen, plus reviewable screenshots.
- All edits to `scenes/raven/**`, `vertical_slice.gd`, canonical graph/map JSON, project settings, shared reducer/save and any schema require **separate single-writer integration PR** after approval.

## Evidence and status

CI executes `tests/raven/manor_navigation_graph_smoke.gd` in `scripts/check.sh`. The new fixture tests compare A/B IDs and strict world-space conversion without importing or modifying the currently unmerged A/B PR files. Art and Builder CI on their own PRs do not prove that combined physical navigation works. `CODE-05-02` remains partial P0 pending geometry and scene acceptance, as do RM-GAP-001/006. The only authoritative Raven campaign store remains existing schemaVersion=1 reducer/store.

**STOP/UNKNOWN:** missing actual calibrated world points, world/pixel mapping, wall/door collider clearance, foreground masks, owner approval and real device QA. Do not mark `productionReady:true` or call the preview game-ready.
