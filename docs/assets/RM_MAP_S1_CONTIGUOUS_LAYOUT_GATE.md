# RM-MAP-S1 — contiguous first-floor map feasibility gate (DRAFT)

2026-10-24 | **Proposed for spatial review, not approved architecture, production art or implemented full Godot map.**

## Motivation
Do not commission final room backgrounds or prop sheets from room-by-room hero-perspective art. The entire traversable season-1 region must be a single consistent global-coordinate, shallow top-down 3/4 map with camera pan/scroll, shared character scale, depth masks and real physical room adjacencies. No cutscene teleport between adjacent rooms. The user must be able to select an object/repair hotspot and have Evelyn follow an authored, collision-safe route to it (or receive gated feedback).

## Approved logical topology (Stage 2 v0.2)
- ENTRY ↔ HALL ↔ CORRIDOR ↔ BEDROOM, BATHROOM, KITCHEN ↔ CONSERVATORY.
- HALL ↔ ARCHIVE (the library).
- HALL ↔ EAST-WING **not traversable S1**, physically beneath the central landing of the *approved bifurcated staircase*; HALL → UPPER FLOOR stairs **not traversable S1**.
- KITCHEN ↔ SERVICE WING **not traversable S1**; CONSERVATORY ↔ BACK GARDEN **not traversable S1**.
- These eleven existing `RM-DOOR-*` edges preserve their canonical IDs. No invented direct Hall→Bedroom or Hall→Conservatory connection.
- Stage 1's six story zones = Hall, Bedroom, Bathroom compact vignette, Kitchen, Archive, Conservatory. Entry is threshold, Corridor is light passage.
- Hall accepted owner design: staircase split, east-wing locked door under central landing, cream/dark geometric floor, burgundy rug, clock left by Archive, two armchairs + small table by Archive, restrained eccentric portraits, covers ONLY on the two armchairs. Do not revoke artistic approval when adjusting wall spacing.

## Existing proof and gaps
- `data/raven/manor_greybox_graph.json` currently has 12 anchors and 10 edges, Hall→Corridor→Bedroom **only**; positions are greybox, roomArtCalibration pending, productionReady=false.
- `docs/preproduction/stage2/05_manor_graph.md` defines full connectivity but explicitly NOT metric drawing; Stage 2 `07b` has portrait camera/door concept but does not provide shared production transforms.
- Stage 2 old Bedroom door prerequisites (both repairs plus clue) conflict with current approved runtime flow: **bedroom access hotspot HS-005 first; bedroom restoration after entry; bathroom repair later**. Adopt current `docs/DECISIONS.md` and actual content contract; historical Stage 2 remains provenance only. Keep IDs.
- The current scroll/prototype is not proof of full seamless global map.

## Proposed metric layout method
1. Author room polygons and **wall segments** in a shared continuous world coordinate system; include inside and outside wall thickness, doorway openings and corridor connectors.
2. Use *one orthographic/shallow three-quarter projection* with constant tile-to-character-foot scale (room illustrations may scroll and be streamed, but use the same transform). Treat visible walls as occluding upper layers, not giant perspective paintings.
3. Use side-by-side room footprints satisfying graph constraints. Reject a drawing where doors open into unmatched walls, hitboxes or hidden voids.
4. Hall positioning: ENTRY on camera-near edge; ARCHIVE portal left; CORRIDOR portal right or practical rear-right, east-wing door deep center under landing; upper-floor blocked stairs. Exact orientation of residential corridor beyond Hall portal is an unresolved design choice; it **may bend** (L-turn) to conserve camera pan and align bedroom/bath/kitchen service wet wall.
5. Corridor connects bedroom+bath+kitchen on explicit door faces. Bath shares service shaft logic with kitchen; one compact bathroom vignette can occupy a **physical footprint** even without full walkable gameplay interior.
6. Kitchen and conservatory physically share a glazed wall/door and align exterior/garden direction.
7. Add entrances and nonplayable silhouettes for locked wings; *do not draw explorable inaccessible full rooms*.
8. Reserve circulation before furnishing. Every door has a near/far landing footprint, turning pocket, blocked/open visual geometry, collision boundary, nav edges, camera handoff and foreground alpha mask.
9. Every movable/repairable prop has: semantic room location → calibrated world anchor → accessible interaction standing zone → collision bounds → optional UI marker and saved restore state.
10. Keep decorative clusters along walls/niches; ensure player and hotspot labels are visible at 390×844 and narrow/tall, even while camera scrolls.

## What to build as feasibility greybox **before more room approval sheets**
**Pass 1: pure plan**
- Polygon footprints for Hall, Archive, Corridor, Bedroom, Bathroom, Kitchen, Conservatory + Entry.
- Eleven doorway relations incl future locked stubs and stair obstruction.
- World-coordinate origin, orientation, unified floor/wall elevations, zoom and top-down angle.
- Wall+door openings and shared edges are validated geometrically.

**Pass 2: travel and camera**
- One Evelyn placeholder of known measured pixel size; authored multi-room graph with deterministic safe routing.
- Click Hall clock, Bedroom bed, Bathroom plumbing, Kitchen worktop, Archive ledger, Conservatory plant; each routes to a legal approach anchor if available, otherwise shows dependency.
- Scroll/drag freely through discovered map extent, and recenter character. Camera motion is *continuous* across portals, no room jump or silhouette scaling.
- Validate locked wing/stair properly blocks passage while remains understandable visually.
- Overlay translucent wall and prop footprints, corridors, foreground masks, VN HUD/task targets.

**Pass 3: furnishing-pressure test**
- Add only bounding boxes of **all primary furnishings** from `docs/assets/ROOM_OBJECT_REGISTER.csv` and `RM_ROOM_HALL_APPROVAL_SHEET.md` before any textured art.
- Map path clearances for both seated cluster and clock near Archive; don't put chair in doorway or under player root.
- Test usability of every planned repair hotspot, including hidden/available/repaired states and camera pan constraints.
- Mark incompatible props as reposition/cut/resize *before generating them*.

## Minimum machine-readable map data proposed
```json
{
  "schemaVersion": 1,
  "provenance": {"geometryStatus": "season1-layout-proposal", "productionReady": false},
  "world": {"units": "logical_design_units", "projection": "shared_shallow_top_down", "scale": "pending_calibration"},
  "rooms": [{"roomId": "RM-ROOM-HALL", "footprint": "polygon_pending", "wallSegments": "pending"}],
  "doors": [{"doorId": "RM-DOOR-HALL-ARCHIVE", "portalOpening": "pending", "approachAnchors": "both_sides_pending"}],
  "props": [{"assetId": "RM-ASSET-HALL-...", "footprint": "pending", "interactionAnchor": "pending", "depthRule": "pending"}]
}
```
This is a **schema illustration**, not executable data.

## Gate acceptance
- [ ] Every traversable S1 door has physically adjoining room polygons and no wall overlaps.
- [ ] Exactly one consistent world scale/camera projection; map sprites do not resize between rooms.
- [ ] Continuous camera pan via Hall/Corridor/Kitchen to Conservatory, and Hall/Archive; no jumps.
- [ ] Paths cannot clip walls, stairs, furniture, doorframes; route targets remain approachable.
- [ ] Locked East Wing, upper stair, service wing and garden are visible boundaries without path links.
- [ ] Six primary rooms plus Corridor and Entry have credible furnishable footprints, not just story hotspots.
- [ ] Save/load restores current room, valid safe anchor, doors/repairs and camera position or intentional recenter.
- [ ] Mobile portrait 390×844, narrow and tall tests for pan, recenter and target hit areas.
- [ ] An actual screenshot/video of *the whole contiguous map with prop collision boxes* and the successful travel path tests are reviewed by owner.

## Consequence
**Pause detailed room decoration/art generation until this gate passes.** Completed Hall art-direction approval remains intact, but its exact geometry and object anchors may change in the overall plan. Follow with room-specific detailed art specs once footprints are frozen. 
