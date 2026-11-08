extends SceneTree

const Snapshot = preload("res://scripts/raven/raven_snapshot.gd")
const Reducer = preload("res://scripts/raven/raven_reducer.gd")
const Graph = preload("res://scripts/raven/manor_navigation_graph.gd")
const RouteSession = preload("res://scripts/raven/manor_route_session.gd")
const GeometryAdapter = preload("res://scripts/raven/manor_navigation_geometry_adapter.gd")
const Store = preload("res://scripts/raven/raven_campaign_store.gd")
const MemoryStorage = preload("res://tests/support/memory_storage.gd")


func _initialize() -> void:
	var graph_data: Dictionary = load("res://data/raven/manor_greybox_graph.json").data
	assert(graph_data.provenance.geometryStatus == "greybox")
	assert(graph_data.provenance.productionReady == false, "Greybox anchors must not be presented as production-ready before room-art calibration")
	assert(Graph.production_geometry_is_valid(graph_data))
	var false_claim := graph_data.duplicate(true); false_claim.provenance = graph_data.provenance.duplicate(true); false_claim.provenance.productionReady = true
	assert(not Graph.production_geometry_is_valid(false_claim), "Production-ready geometry requires approved room-art calibration metadata")
	var state := Snapshot.fresh()
	var graph := Graph.new()
	graph.rebuild(state)
	assert(graph.interaction_anchor("RM-HS-001") == "RM-NAV-HS-001")
	assert(graph.interaction_anchor("RM-HS-004") == "RM-NAV-HS-004")
	assert(graph.route("RM-NAV-HALL-SPAWN", "RM-NAV-HS-003") == [
		"RM-NAV-HALL-SPAWN", "RM-NAV-HALL-CORRIDOR-NEAR", "RM-NAV-HALL-CORRIDOR-FAR",
		"RM-NAV-CORRIDOR-CENTER", "RM-NAV-HS-003"
	])
	assert(graph.route("RM-NAV-HALL-SPAWN", "RM-NAV-HS-002").is_empty())
	assert(graph.route("missing", "RM-NAV-HS-001").is_empty())

	var unlock := Reducer.apply(state, {
		"eventId": "nav-test-unlock",
		"type": "door_unlock",
		"doorId": "RM-DOOR-CORRIDOR-BEDROOM",
	})
	assert(unlock.ok)
	state = unlock.state
	graph.rebuild(state)
	var route := graph.route("RM-NAV-HALL-SPAWN", "RM-NAV-HS-002")
	assert(route == [
		"RM-NAV-HALL-SPAWN", "RM-NAV-HALL-CORRIDOR-NEAR", "RM-NAV-HALL-CORRIDOR-FAR",
		"RM-NAV-CORRIDOR-CENTER", "RM-NAV-HS-005", "RM-NAV-BEDROOM-NEAR",
		"RM-NAV-BEDROOM-FAR", "RM-NAV-BEDROOM-CENTER", "RM-NAV-HS-002"
	])
	assert(graph.route("RM-NAV-HALL-SPAWN", "RM-NAV-HS-002") == route, "Route selection must be deterministic")
	assert(graph.route_positions("RM-NAV-BEDROOM-FAR", "RM-NAV-HALL-SPAWN").size() == 7)
	var adapter := MemoryStorage.new()
	assert(Store.new(adapter).save_campaign(state))
	var reloaded := Store.new(adapter).load_campaign()
	var reloaded_graph := Graph.new(); reloaded_graph.rebuild(reloaded)
	assert(not reloaded_graph.route("RM-NAV-HALL-SPAWN", "RM-NAV-HS-002").is_empty(), "Unlocked doorway must survive reload")
	_verify_session_and_adapter(graph_data)
	print("Raven Manor authored navigation graph smoke passed (locked, unlocked, checkpoint, interruption, fixture adapter and deterministic routes).")
	quit()


func _verify_session_and_adapter(source_data: Dictionary) -> void:
	var state := Snapshot.fresh()
	var graph := Graph.new()
	graph.rebuild(state)
	assert(graph.has_anchor("RM-NAV-HALL-SPAWN"))
	assert(not graph.has_anchor("RM-NAV-UNKNOWN"))
	assert(graph.has_door_gate("RM-DOOR-CORRIDOR-BEDROOM"))
	assert(not graph.has_door_gate("RM-DOOR-UNKNOWN"))
	assert(not graph.segment_available("RM-NAV-BEDROOM-NEAR", "RM-NAV-BEDROOM-FAR"))
	assert(not graph.segment_available("RM-NAV-UNKNOWN", "RM-NAV-HALL-SPAWN"))
	assert(graph.route_to_hotspot("RM-NAV-HALL-SPAWN", "RM-HS-003") == graph.route("RM-NAV-HALL-SPAWN", "RM-NAV-HS-003"))
	assert(graph.route_to_hotspot("RM-NAV-HALL-SPAWN", "RM-HS-NOT-REAL").is_empty())
	assert(graph.route_to_hotspot("RM-NAV-HALL-SPAWN", "RM-HS-002").is_empty())

	# Hall -> Corridor -> Bedroom is gated only by its door, NOT by bathroom restoration.
	var session := RouteSession.new(graph)
	assert(session.restore(state) == "RM-NAV-HALL-SPAWN")
	assert(not session.request_hotspot("RM-HS-002").ok)
	assert(not session.request_hotspot("RM-HS-UNKNOWN").ok)
	assert(session.next_segment().is_empty(), "Unreachable/unknown hotspots must not move")
	assert(session.request_hotspot("RM-HS-003").ok)
	assert(session.request_hotspot("RM-HS-003").status == "unchanged", "Repeat selection is idempotent")
	var first: Dictionary = session.next_segment()
	assert(first.fromAnchorId == "RM-NAV-HALL-SPAWN")
	assert(first.toAnchorId == "RM-NAV-HALL-CORRIDOR-NEAR")
	assert(session.next_segment().is_empty(), "One movement command per acknowledged segment")
	assert(not session.finish_segment("RM-NAV-HS-003").ok, "Wrong arrival must be rejected")
	assert(session.current_anchor() == "RM-NAV-HALL-SPAWN")
	assert(session.request_hotspot("RM-HS-001").status == "queued", "A replacement waits until the in-flight segment completes")
	assert(session.next_segment().is_empty())
	assert(session.finish_segment(first.toAnchorId).status == "continue")
	var replacement: Dictionary = session.next_segment()
	assert(replacement.fromAnchorId == "RM-NAV-HALL-CORRIDOR-NEAR")
	assert(replacement.toAnchorId == "RM-NAV-HALL-SPAWN", "Replace route from confirmed anchor, not a mid-tween coordinate")
	assert(session.cancel().finishCurrentSegment)
	assert(session.next_segment().is_empty(), "Cancellation cannot start a new segment")
	assert(session.finish_segment(replacement.toAnchorId).status == "cancelled")
	assert(session.current_anchor() == "RM-NAV-HALL-SPAWN")
	assert(not session.cancel().finishCurrentSegment)
	assert(session.checkpoint_event("nav-test-safepoint").anchorId == "RM-NAV-HALL-SPAWN")

	# A door becoming unavailable between segments stops before that edge.
	assert(session.request_hotspot("RM-HS-003").ok)
	first = session.next_segment()
	assert(session.finish_segment(first.toAnchorId).ok)
	var locked := state.duplicate(true)
	locked.unlockedDoors = []
	graph.rebuild(locked)
	assert(session.next_segment().is_empty(), "A stale route must not pass a newly locked door")
	assert(session.pending_hotspot().is_empty())
	assert(session.current_anchor() == "RM-NAV-HALL-CORRIDOR-NEAR")
	assert(session.checkpoint_event("nav-test-locked").anchorId == "RM-NAV-HALL-SPAWN")

	# Explicit restoration edge fixtures are honored without modifying canonical data.
	var gated_data := source_data.duplicate(true)
	gated_data["edges"][2]["restorationId"] = "RM-REST-001"
	graph.rebuild(state, gated_data)
	assert(graph.route_to_hotspot("RM-NAV-HALL-SPAWN", "RM-HS-003").is_empty())
	var prepared := state.duplicate(true)
	prepared.completedRestorations.append("RM-REST-001")
	graph.rebuild(prepared, gated_data)
	assert(not graph.route_to_hotspot("RM-NAV-HALL-SPAWN", "RM-HS-003").is_empty())

	var unlock := Reducer.apply(state, {"eventId":"nav-session-unlock", "type":"door_unlock", "doorId":"RM-DOOR-CORRIDOR-BEDROOM"})
	assert(unlock.ok)
	state = unlock.state
	assert(state.completedRestorations.is_empty(), "Bedroom access must not require bathroom repair")
	graph.rebuild(state)
	assert(graph.segment_available("RM-NAV-BEDROOM-NEAR", "RM-NAV-BEDROOM-FAR"))
	assert(session.restore(state) == "RM-NAV-HALL-SPAWN")
	assert(session.request_hotspot("RM-HS-002").ok)
	var hops := 0
	while not session.pending_hotspot().is_empty():
		var step: Dictionary = session.next_segment()
		assert(step.has("toAnchorId"), "Every command must target an authored anchor")
		assert(graph.segment_available(str(step.fromAnchorId), str(step.toAnchorId)))
		var reached: Dictionary = session.finish_segment(str(step.toAnchorId))
		assert(reached.ok)
		hops += 1
		assert(hops < 20, "Hall -> Corridor -> Bedroom must terminate")
	assert(hops == 8)
	assert(session.current_anchor() == "RM-NAV-HS-002")
	var save_event: Dictionary = session.checkpoint_event("nav-session-position")
	assert(save_event.type == "position_checkpoint")
	assert(save_event.anchorId == "RM-NAV-BEDROOM-CENTER")
	assert(save_event.roomId == "RM-ROOM-BEDROOM")
	assert(graph.checkpoint_event("RM-NAV-HS-002", "invalid").is_empty())
	assert(graph.checkpoint_event("RM-NAV-BEDROOM-CENTER", "").is_empty())
	var changed := Reducer.apply(state, save_event)
	assert(changed.ok)
	var saved: Dictionary = changed.state
	assert(graph.safe_checkpoint_anchor(saved) == "RM-NAV-BEDROOM-CENTER")
	var adapter := MemoryStorage.new()
	assert(Store.new(adapter).save_campaign(saved))
	var restored: Dictionary = Store.new(adapter).load_campaign()
	assert(restored.lastRoomId == "RM-ROOM-BEDROOM")
	assert(session.restore(restored) == "RM-NAV-BEDROOM-CENTER")
	var invalid_checkpoint := restored.duplicate(true)
	invalid_checkpoint.lastSafeAnchorId = "RM-NAV-HS-002" # Interaction, not safe.
	assert(graph.safe_checkpoint_anchor(invalid_checkpoint) == "RM-NAV-BEDROOM-CENTER")
	invalid_checkpoint.lastSafeAnchorId = "INVALID"
	invalid_checkpoint.lastRoomId = "RM-ROOM-BEDROOM"
	graph.rebuild(Snapshot.fresh())
	assert(graph.safe_checkpoint_anchor(invalid_checkpoint) == "RM-NAV-HALL-SPAWN", "Inconsistent locked bedroom save must fall back safely")

	# Art/Builder fixture can change ONLY preview positions; neither routes nor gates nor save.
	var candidate := {
		"schemaVersion": 1, "coordinateSpace": "world-plan", "productionReady": false,
		"anchors": [{"id": "RM-NAV-HALL-SPAWN", "roomId": "RM-ROOM-HALL", "position": [410.0, 315.0]}]
	}
	var preview: Dictionary = GeometryAdapter.apply_preview(source_data, candidate)
	assert(preview.ok)
	assert(preview.updatedAnchorCount == 1)
	assert(not preview.data.provenance.productionReady)
	assert(preview.data.provenance.geometryStatus == "candidate-preview")
	assert(source_data.anchors[0].position == [400, 300], "Source graph may not be modified")
	assert(preview.data.edges == source_data.edges, "Fixture must not rewrite gates or topology")
	graph.rebuild(state, preview.data)
	assert(graph.position("RM-NAV-HALL-SPAWN") == Vector2(410, 315))
	assert(not graph.route_to_hotspot("RM-NAV-HALL-SPAWN", "RM-HS-002").is_empty())
	assert(Graph.production_geometry_is_valid(preview.data))
	var bad := candidate.duplicate(true)
	bad["anchors"][0]["id"] = "RM-NAV-UNKNOWN"
	assert(not GeometryAdapter.apply_preview(source_data, bad).ok)
	bad = candidate.duplicate(true)
	bad["anchors"][0]["roomId"] = "RM-ROOM-BEDROOM"
	assert(not GeometryAdapter.apply_preview(source_data, bad).ok)
	bad = candidate.duplicate(true)
	bad["anchors"][0]["position"] = [INF, 315.0]
	assert(not GeometryAdapter.apply_preview(source_data, bad).ok)
	bad = candidate.duplicate(true)
	bad["anchors"].append(bad["anchors"][0].duplicate(true))
	assert(not GeometryAdapter.apply_preview(source_data, bad).ok)
	bad = candidate.duplicate(true)
	bad.productionReady = true
	assert(not GeometryAdapter.apply_preview(source_data, bad).ok)
	bad = candidate.duplicate(true)
	bad.coordinateSpace = "projected-screen"
	assert(not GeometryAdapter.apply_preview(source_data, bad).ok)
