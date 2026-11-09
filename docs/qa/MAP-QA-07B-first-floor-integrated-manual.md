# MAP-QA-07B — Integrated first-floor playable QA (Godot 4.7.2)

**Task:** MAP-QA-07B (technical integration slice of CODE-05-02). **Authority:** DRAFT_ONLY navigation; **all handoffs:** TEST_ONLY. Human geometry/portal/mobile acceptance: **NOT_RUN**.

## F6 entrypoint and repeatable owner workflow

1. Open `scenes/raven/tests/first_floor_integrated_qa.tscn` in Godot 4.7.2 and press **F6**. Default source is the persisted project draft `res://assets/raven/map/qa/drafts/hall_routes_draft.v1.json`. There is no silent fallback if validation fails.
2. Confirm the approved 1672 × 941 first-floor PNG, Onoe on `QA-HALL-SPAWN`, and the header **DRAFT_ONLY / TEST_ONLY**. The scene uses exactly the approved PNG identity and source-image pixel coordinates (no world-plan transformation).
3. Use the **Walk waypoint** picker or click a labeled active-room waypoint on the image. Only authored hotspots are selectable; clicking arbitrary floor pixels does nothing. Movement is driven by the existing NavigationGraph → RouteSession → MAP-QA-06 → OnoeSegmentMover chain.
4. Press **F3 Overlay** (or F3) for waypoint IDs, authored routes including intermediate grid cells (cyan), original uncalibrated provisional Hall edges (orange), candidate walkable floor (green) and no-go/blocked regions (red). The MAP-QA-05 unresolved portals have **no asserted pixel footpoints** and are identified in the source/status, not drawn at invented points. Header shows source and unresolved count.
5. Use **Hall → Corridor → Bedroom → Corridor → Hall**. These are **explicit mocked TEST_ONLY transition fixtures** over AI-authored room graphs, **NOT confirmed physical doorway positions**. Onoe must physically follow an approach route and reach the selected anchor before MAP-QA-06 switches rooms. Check reverse entry anchors and unchanged first-floor background.
6. Use **Locked** or **Gate** to verify a refused door/closing gate cannot produce an unexpected room change. **Pause**, **Cancel**, spacebar, middle-drag **Pan / Follow**, mouse-wheel/+/− zoom are QA-only controls.
7. **Restart island (QA)** allows a separately initialized test in Library/Archive and Kitchen (and Corridor/Bedroom), because those islands have no physically approved doors. **This is an explicit laboratory scene restart, not an in-game transition.** The active graph stays room-owned.
8. To calibrate, open **Project → Project Settings → Plugins → Room Builder · Navigation / Routes**, then **Navigation / Routes**. Choose **Load project draft**, edit the waypoint or orthogonal cells, then **Save user draft** or **Export project draft**. Unsaved edits are never automatically read.
9. Return to the integrated scene, choose **Saved user** for `user://room_builder_routes/hall_routes_draft.v1.json` or **Project draft** for the project export, and use **Reload** only when Onoe is settled on a safe anchor. Reload/reset never splices new geometry into an active segment or keeps a stale route token.
10. Choose **Original Hall** to restore the unchanged seven-waypoint Hall QA baseline (single-room only; room-door buttons reject). Use **Project draft** to return to the five-island candidate.

**Error path:** missing file, wrong PNG/hash/schema, unsupported draft room ownership, bad/missing safe anchor, disconnected/blocked route, unknown/locked door or in-flight reload shows a clear rejection. The previous running graph is kept on failed source selection; never silently replaced with baseline geometry.

## Integration contract / audit

- **Components reused without rewrites:** `route_document.gd` (v1 validation and ordered per-cell compilation), `route_preview_source.gd` (saved source/path restrictions), `manor_navigation_graph.gd`, `manor_route_session.gd`, `manor_room_transition_controller.gd`, `onoe_segment_mover.gd` and `first_floor_multi_room_host.gd`.
- **New boundary:** `scripts/raven/first_floor_integrated_draft_adapter.gd`. The original editor compiler deliberately assigns `RM-ROOM-HALL` to all compiled anchors. This adapter copies and partitions those anchors/edges into room-owned image-pixel graphs using explicit waypoint `roomId`. It assigns compiled `QA-ROUTE-…-STEP-…` anchors to the route's room, validates every edge, and rejects cross-room authored edges. The first seven legacy `QA-HALL-*` anchors are assigned to Hall only by their **exact original seven IDs**.
- **Five source islands, pending owner review:** Hall (9 waypoint/10 routes), Corridor (4/3), Bedroom (3/2), Archive/Library (3/2), Kitchen (3/2); 22 waypoints/19 routes, source draft MAP-QA-05. Room graph includes additional intermediate step anchors. No bathroom walkable graph. Existing original Hall QA remains independently selectable.
- **Physical connections:** zero confirmed in MAP-QA-05; eleven manifest door locations unresolved, seventeen unresolved metadata records total. Two mocked doorway *pairs* are defined with four reversible `QA-07B-TR-*` transitions: Hall ↔ Corridor and Corridor ↔ Bedroom. An additional locked QA request is intentionally rejected. Their approaches/entries reuse actual authored waypoints as **testing anchors**, not asserted door contact locations. Library and Kitchen have no asserted transitions.
- **Source authority:** only `DRAFT_ONLY` saved route drafts, `AI_PROVISIONAL_UNAPPROVED` geometry, `TEST_ONLY` physical handoffs; no `PRODUCTION_APPROVED`. Each QA room visual shows the same actual first-floor artwork. No coordinate-space conversion, canonical nav mutation, production save, campaign, Room Builder schema upgrade, new pathfinder or new movement state machine.
- **Limitation:** existing editor add-waypoint tool does not supply `roomId` for newly created points. Existing route/waypoint edits round-trip; newly created points lacking explicit ownership are **rejected** by the integrated adapter instead of being silently assigned to Hall. Future authoring UX should expose room ownership explicitly.
- **Visual limitations:** artwork's composition bounds are not validated collision boundaries; no actor-footprint clearance, occlusion or room-specific camera crop approval. Existing debug/no-go markings are provisional. Pan/zoom/device framing must be visually assessed.

## Automated verification

```bash
godot --headless --path . --script res://tests/raven/map_qa_07b_integrated_first_floor_smoke.gd --quit-after 240
bash scripts/check.sh
```

The new smoke exercises real movement along persisted edited Corridor points and authored cell-step anchors, strict five-room ownership, one-way routes, original Hall baseline, invalid draft rejection, pause/cancel, physical approach → Hall–Corridor–Bedroom–Corridor–Hall handoffs, locked/unknown/gated door behavior, F6 scene/reload, snapshot isolation. Registered **once** after MAP-QA-07A; keep MAP-QA-01/02/03/04/05/06/07A, MAP-EDIT-01/02, Whole Manor and Prototype Lab regression gates unchanged.

**Acceptance evidence:** GitHub Actions exact-head CI is required; until it runs this document makes no claim of passing tests. Actual editor F6 visuals, touch/mobile, character size, overlay clarity, route clearance and safe door locations remain **HUMAN_PENDING**. Owner can calibrate later; this work does not promote the data to production.

**Rollback:** revert the MAP-QA-07B integration PR (new adapter/scene/script/smoke, single `scripts/check.sh` registration, docs and one status-shard evidence). Approved PNG, canonical manifest/13 anchors, existing Hall pilot and production saves do not change.
