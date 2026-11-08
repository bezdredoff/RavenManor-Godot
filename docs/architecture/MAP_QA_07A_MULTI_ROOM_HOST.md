# MAP-QA-07A — First-floor multi-room playable foundation

Domain: manor-map. This is an isolated TEST_ONLY integration demonstration, not approved Corridor/Bedroom geometry or production navigation.

## Architecture and ownership

- The scene **scenes/raven/tests/first_floor_multi_room_host.tscn** contains the existing OnoeSegmentMover actor, a Camera2D, a room-visual layer and a route-overlay layer.
- **scripts/raven/first_floor_multi_room_host.gd** handles room display, current graph selection, camera limits/smoothing, actor lifecycle, input-facing requests, room handoff rendering and an in-memory state proposal. It does not own routing or door policy.
- The existing MAP-QA-06 **ManorRoomTransitionController** is authoritative for door availability, verified physical approach, next segments, arrival tokens, safe entry anchors and commit. The host never directly relocates Onoe between rooms. The existing **ManorNavigationGraph**, **ManorRouteSession** and **OnoeSegmentMover** are reused unchanged.
- **scripts/raven/first_floor_multi_room_fixture.gd** creates an in-memory contract from the validated MAP-QA-03 Hall graph plus synthetic Corridor and Bedroom. Hall art is the approved 1672×941 first-floor PNG; Hall navigation is still DRAFT_ONLY. The Hall QA virtual portal is MOCKED as TEST_ONLY for Stage A, not asserted to be a real door.
- Neither the native Route Editor (#246), firstFloorDraft, approved production art, source Hall graph files, save reducer/store, project.godot nor Prototype Lab launcher is changed.

The Stage A demonstration is Hall → synthetic Corridor → synthetic Bedroom → synthetic Corridor → Hall with explicit reversible descriptors, safe entry anchors, hotpots, a locked test door and a gate toggle.

## Stage B input contract

Call **host.configure_host(contract, room_specs, initial_room, initial_safe_anchor, gate_snapshot)** once before movement. Input contract is the existing MAP-QA-06 raven-authored-room-transitions schemaVersion 1, with rooms carrying graph anchors and edges, door descriptors, reverses and safe entry anchors. The separate room_specs keyed by room ID must provide:

- source: synthetic, hall-qa or approved-art
- bounds: [left, top, width, height] in source-image pixels
- cameraZoom and actorHeight
- texturePath for actual art (required for hall-qa and approved-art).

The host validates visual availability before configuring the controller. It refuses missing destinations or invalid room metadata rather than entering a black screen. It refuses manual room switching: only MAP-QA-06 verified transition completion triggers room swap.

Future Agent A must supply per-room graph geometry, room bounds, door approaches and **approved** safe entries. Future Agent B must compile native route-editor draft data into the existing MAP-QA-06 graph shape and validate source identity upstream. The host intentionally does not parse editor drafts, perform grid-to-pixel transforms or promote draft-only geometry into campaign.

**replace_room_graph(room_id, compiled_graph)** is the exact future integration seam. Replacement is allowed only while settled, outside pending handoff and safe hold, and only when current physical feet still coincide with an authorized safe entry anchor. A fresh MAP-QA-06 controller validates the candidate before replacing the old session. No corrective teleport is allowed.

The copy returned by **state_proposal()** includes roomId, lastSafeAnchorId, returnSpawnAnchorId, lastTransitionId and transitionComplete. It is an isolated test record. A future production adapter would submit a reviewed checkpoint proposal to the sole campaign store/reducer; **this PR does not load or mutate a campaign save**.

Camera2D uses per-room limit bounds and smooth follow within each room. It resets smoothing on an inter-room source-coordinate switch, preventing a long pan over unrendered space. Route overlay is optional. Input remains hotspot/door-only: never unrestricted touch-to-walk.

## Manual Godot F6 test

1. Open **scenes/raven/tests/first_floor_multi_room_qa.tscn**, run F6. Confirm approved Hall PNG, Onoe and TEST ONLY header. This demo is intentionally not added to shared Prototype Lab launcher.
2. Use Hall → Cor., Cor. → Bed, Bed → Cor., Cor. → Hall. Confirm Onoe actually walks to each door approach before room changes and returns to QA-HALL-RETURN-SAFE.
3. Use Walk side inside Corridor/Bedroom, click Hall → Cor. repeatedly, and try Locked. Duplicate requests must not start a new leg; locked requests must leave feet and room unchanged.
4. Toggle Gate while approaching a door, then reopen. The pending handoff must be cancelled without snapping feet. Pause/Resume, Cancel and Routes (F3) must work. Space toggles pause.
5. Test portrait/mobile framing and actor size manually; this is NOT yet evidence of owner/device acceptance. Click ← Lab to exit.

## Automated checks

The scoped smoke is **tests/raven/map_qa_07a_multi_room_smoke.gd**. It covers A→B→C→B→A, missing destination visuals/anchor, lock and unknown transition, duplicate requests, mid-segment pause, cancel, gate closure, graph replacement/invalid replacement, camera bounds, Onoe physical positioning, in-memory state defensive copying and unchanged campaign snapshot fixture.

Run:
- godot --headless --path . --script res://tests/raven/map_qa_07a_multi_room_smoke.gd --quit-after 180
- godot --headless --path . --script res://tests/raven/map_qa_03_hall_movement_smoke.gd --quit-after 120
- godot --headless --path . --script res://tests/raven/map_qa_06_room_transitions_smoke.gd --quit-after 150
- godot --headless --path . --script res://tests/raven/season1_map_smoke.gd --quit-after 120
- godot --headless --path . --script res://tests/raven/prototype_lab_smoke.gd --quit-after 120
- bash scripts/check.sh

**Integration-owner follow-up:** register the new MAP-QA-07A smoke once in shared scripts/check.sh, after MAP-QA-06. Agent A/B may edit this shared registry concurrently, so it is intentionally omitted here to avoid conflicts. Until that registration is merged, regular green CI **does not demonstrate that the new MAP-QA-07A smoke executed**. Existing regression checks remain registered.

## Reuse and constraints

UPDS-godot at commit **3deed628efd6c22bcd1717f7c545b7d3ca865781** has no room_transition result in a code search. Reuse classification for Raven: **reuse-as-is** MAP-QA-06 controller, RouteSession, NavigationGraph and OnoeSegmentMover; **adapter** existing Camera2D and Hall QA geometry; **new** only this small visual host, fixture and test UI. No donor private story/assets, no second campaign save model.

The physical Hall↔Corridor doorway is NOT verified. Corridor and Bedroom rooms remain synthetic placeholders, not production geometry. MAP-QA-05 and MAP-EDIT-02 have independent merge and owner acceptance gates. Mobile framing, asset/occlusion correctness and actual manual QA remain HUMAN_PENDING. CODE-05-02 and RM-GAP-006 remain partial.
