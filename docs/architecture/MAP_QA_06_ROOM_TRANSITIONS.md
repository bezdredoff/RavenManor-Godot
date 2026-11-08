# MAP-QA-06 — Reusable authored room transitions

Status: TEST_ONLY technical slice. Godot 4.7.2. This implementation neither invents Corridor/Bedroom geometry nor writes campaign saves.

## Reused code and canonical contracts

The coordinator is scripts/raven/manor_room_transition_controller.gd. It reuses ManorNavigationGraph (AStar2D, segment_available, doorId/unlockedDoors), ManorRouteSession (authored hotspot navigation, queued targets, acknowledged segments) and OnoeSegmentMover (physical footpoint). None of these existing modules was modified.

The current data/raven/season1_world_map.json uses door statuses open / gated / future. The snapshot allows doors through unlockedDoors; it initially unlocks RM-DOOR-HALL-CORRIDOR. The controller rejects future regardless of unlocks, and for open/gated checks the authoritative unlockedDoors list when supplied. A test-only mutable door adapter is intentionally NOT a production unlock event.

UPDS reuse gate: searched bezdredoff/UPDS-godot@3deed628efd6c22bcd1717f7c545b7d3ca865781 for room_transition; no equivalent authored-room handoff code was identified. Raven-specific graph, session and Onoe mover are reused as-is. New functionality here is only the coordinator; no UPDS story, save or asset imported.

## Data descriptor contract v1

Data file: data/raven/qa/room_transitions_synthetic.v1.json (synthetic only, not production geometry).

The root requires schemaVersion=1, kind=raven-authored-room-transitions, approval=TEST_ONLY or PRODUCTION_APPROVED, rooms, doors and transitions. Each room has id, label and a graph containing anchors (id, roomId, kind, position=[x,y], optional hotspotId) and direct authored edges (from, to, optional doorId). Each door has id and status from open/gated/future. Each transition has all of:

| Key | Meaning |
| --- | --- |
| id | Unique transition identity |
| sourceRoomId | Current authoritative room |
| destinationRoomId | Target room; never inferred from a clicked point |
| approachAnchorId | Authored source-room anchor containing hotspotId |
| destinationEntryAnchorId | Explicit reviewed safe entry anchor in destination graph |
| reverseTransitionId | Reciprocal descriptor ID, or empty for unavailable/virtual |
| doorId | Explicit gate ID, or empty for a gate-free QA diagnostic |
| authority | TEST_ONLY, QA_VIRTUAL or PRODUCTION_APPROVED |

For QA_VIRTUAL, destinationEntryAnchorId and reverseTransitionId MUST be empty: diagnostic only, never a physical switch. The fixture contains QA-ROOM-A / QA-ROOM-B and QA-* door/anchor IDs; none of these are canonical RM-* identifiers.

Configuration rejects duplicate IDs, invalid room references, wrong-room anchors, NaN/Inf coordinates, invalid edge endpoints, missing approach hotspots, missing destination safe anchors, unknown gate IDs and nonreciprocal reverse descriptors. A production descriptor requires a production-approved root contract. This does NOT itself approve Hall art or real portal geometry.

## Host integration protocol

1. Configure the controller with validated data, current room, initial safe entry ID and a gate snapshot. Only initial test spawn is placed directly by the host.
2. On explicit doorway intent call request_transition(id, actor), which validates current room, door state and actor provenance, then queues the existing RouteSession hotspot route. Regular room interactions can use request_room_hotspot.
3. Call next_segment(actor), and pass its segment with segmentToken to OnoeSegmentMover.start_segment. If actor refuses to start it, call report_dispatch_failure(token) and enter safe hold; never snap the feet.
4. Only when OnoeSegmentMover emits segment_completed(toId, actualFeet), call accept_segment_arrival(token, toId, actualFeet, actor). It checks the token, physical position, exact anchor, direct gate and RouteSession acknowledgement. Stale, duplicate or premature arrivals do not switch rooms.
5. When the actual approach is confirmed, transition_ready emits, but no room switch happens yet. A virtual QA portal instead emits transition_diagnostic once and remains in the source room.
6. The host explicitly calls commit_transition(actor). The controller rechecks gate, approach, target safe entry, and prepares a new RouteSession. Only then it relocates the actor to the destination entry coordinate, emits transition_completed with entry anchor, reverseTransitionId, and checkpointProposal. The synthetic host changes placeholder room visuals. Production scene change and campaign handoff are NOT wired in this PR.

While moving, duplicate requests are idempotent. A new route request may replace queued intent but never interrupts the current physical segment. cancel_transition clears intent and allows that leg to finish. No click by itself can commit a transition.

## Door closure / physical reconciliation policy

Existing ManorRouteSession.finish_segment may return segment-blocked with rollbackAnchorId if a gate closes during a leg. Its rollback ID is NOT permission to teleport actor.position.

The test-only set_test_door_status rebuilds the existing room graph when a QA gate closes. If the gate belongs to the in-flight leg, the controller pauses Onoe at the actual physical XY, cancels transition intent, and enters safe hold. Reopen and call resume_held_segment explicitly: the same physical leg continues and eventually acknowledges a cancelled destination, with no room switch.

If the gate closes at/after physical arrival before acknowledgement, enter HARD HOLD. Preserve physical XY and keep the session unconfirmed; refuse further transitions. A production host needs an approved recovery animation/route or deliberate restart. No invisible snap to the former confirmed anchor. If the inter-room door closes at a confirmed approach, cancel ready handoff, retain the current room and feet, emit a rejection.

## Save/checkpoint boundary (reviewed but NOT implemented)

Snapshot v1 fields: lastRoomId, lastSafeAnchorId, unlockedDoors; no durable return/entry-history field. Existing raven_reducer.gd handles position_checkpoint events with eventId, roomId and anchorId; raven_campaign_store.gd exclusively writes state. This PR imports neither the reducer nor store and never writes user://.

Upon a successful real scene handoff, a future integration owner should validate the safe destination anchor against the canonical graph, assign a unique idempotent eventId to checkpointProposal, call reducer/store, then handle persistence failures. Do not persist returnTransitionId/entryPosition in v1: a durable return history requires reviewed schema versioning and migration. The synthetic result is an IN-MEMORY proposal, not a save event.

## Demonstration, tests, QA

Open scenes/raven/tests/room_transition_synthetic.tscn in the Godot 4.7.2 editor and press F6 (Run Current Scene). A → B: blue Room A, Onoe walks to the pink approach and then appears at safe entry in green Room B. Walk within room, then B → A, to see reverse safe entry. Locked door and Future door reject. Virtual portal walks to a QA point and emits a diagnostic without switching. Gate: approach, toggled mid-leg, pauses real feet; reopen resumes the cancelled leg. Gate: A ↔ B can deny a ready handoff. Cancel request finishes the current physical leg. F6 restart resets fixture-only doors.

Run:
- godot --headless --path . --script res://tests/raven/map_qa_06_room_transitions_smoke.gd --quit-after 150
- bash scripts/check.sh
- Verify existing navigation, Onoe, Hall and Prototype Lab smokes remain green.

The only shared runner edit is a single MAP-QA-06 registration in scripts/check.sh, required for exact-head CI coverage. Manual desktop/touch/portrait-size occlusion and scale QA remain pending. No approved PNG, Hall QA dataset, manifest, Room Builder, game UI, VN/Match-3, reducer/store, or progress shard touched. MAP-QA-06 is a scoped unregistered technical slice: do not infer an accepted or merged CODE-05-02 parent task. Rollback: remove new controller, demo, fixture, smoke and its one runner invocation.
