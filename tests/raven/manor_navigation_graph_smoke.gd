extends SceneTree

const Snapshot = preload("res://scripts/raven/raven_snapshot.gd")
const Reducer = preload("res://scripts/raven/raven_reducer.gd")
const Graph = preload("res://scripts/raven/manor_navigation_graph.gd")
const RouteSession = preload("res://scripts/raven/manor_route_session.gd")
const GeometryAdapter = preload("res://scripts/raven/manor_navigation_geometry_adapter.gd")
const WorldMap = preload("res://data/raven/season1_world_map.json")
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
	_verify_producer_contracts(graph_data)
	_verify_in_flight_gate_change(graph_data)
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
	var original_start: Array = source_data["anchors"][0]["position"].duplicate(true)
	assert(Vector2(float(original_start[0]), float(original_start[1])) == Vector2(400, 300), "Fixture baseline coordinates")
	var preview: Dictionary = GeometryAdapter.apply_preview(source_data, candidate)
	assert(preview.ok)
	assert(preview.updatedAnchorCount == 1)
	assert(not preview.data.provenance.productionReady)
	assert(preview.data.provenance.geometryStatus == "candidate-preview")
	assert(source_data["anchors"][0]["position"] == original_start, "Source graph may not be modified by preview overlay")
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


## Synthetic WORLD-PLAN fixture: deliberately not the old independent greybox positions.
## The art and Builder PRs are not required/loaded by this independent CI shard.
func _world_plan_points() -> Dictionary:
	return {
		"RM-NAV-HALL-SPAWN": [850, 700],
		"RM-NAV-HS-001": [600, 580],
		"RM-NAV-HALL-CORRIDOR-NEAR": [1170, 585],
		"RM-NAV-HALL-CORRIDOR-FAR": [1230, 585],
		"RM-NAV-HS-003": [1280, 800],
		"RM-NAV-CORRIDOR-CENTER": [1320, 760],
		"RM-NAV-HS-005": [1390, 600],
		"RM-NAV-BEDROOM-NEAR": [1430, 585],
		"RM-NAV-BEDROOM-FAR": [1470, 585],
		"RM-NAV-BEDROOM-CENTER": [1600, 650],
		"RM-NAV-HS-002": [1750, 670],
		"RM-NAV-HS-004": [1800, 580],
		"RM-NAV-HALL-TEA": [710, 720]
	}


func _builder_fixture(canonical: Dictionary, world: Dictionary) -> Dictionary:
	var draft := {
		"schemaVersion": 2, "kind": "raven-first-floor-draft",
		"provenance": "TEST-ONLY: synthetic XY coordinates; not accepted art",
		"calibration": {
			"imageRect": [0, 0, 1000, 1000],
			"worldRect": [0, 0, world.worldSize[0], world.worldSize[1]],
			"controlPoints": [
				{"pixel":[0, 0], "world":[0, 0]},
				{"pixel":[1000, 1000], "world": world.worldSize.duplicate(true)}
			]
		},
		"roomRegions": [], "doorPlacements": [], "navigationAnchors": []
	}
	for room in world.rooms:
		draft.roomRegions.append({"id": room.id, "rect": room.rect.duplicate(true)})
	for door in world.doors:
		draft.doorPlacements.append({
			"id": door.id, "rooms": [world.rooms[int(door.a)].id, world.rooms[int(door.b)].id if int(door.b) >= 0 else null],
			"point": door.point.duplicate(true), "width": 80
		})
	for anchor in canonical.anchors:
		draft.navigationAnchors.append({
			"id": anchor.id, "roomId": anchor.roomId,
			"point": _world_plan_points()[anchor.id].duplicate(true)
		})
	return draft


func _art_fixture(canonical: Dictionary, world: Dictionary) -> Dictionary:
	var reference := {
		"schemaVersion": 1, "contractId": "raven.first-floor-art",
		"productionReady": false, "integrationAllowed": false,
		"coordinateSystems": {
			"worldPlan": {"origin": "reference_season1_world_map"},
			"greyboxGraph": {"directMappingToWorldPlan": false}
		},
		"rooms": [], "doors": [], "navigationReferenceAnchors": []
	}
	for room in world.rooms:
		reference.rooms.append({"id": room.id, "referenceWorldPlanRect": room.rect.duplicate(true)})
	for door in world.doors:
		reference.doors.append({
			"id": door.id, "roomIds":[world.rooms[int(door.a)].id, world.rooms[int(door.b)].id if int(door.b) >= 0 else null],
			"referenceWorldPlanPoint": door.point.duplicate(true)
		})
	for anchor in canonical.anchors:
		reference.navigationReferenceAnchors.append({
			"id": anchor.id, "roomId": anchor.roomId, "kind": anchor.kind,
			"referenceSpace": "independent_greybox",
			"referenceGreyboxPoint": anchor.position.duplicate(true),
			"sourcePixelFootpoint": null, "calibratedWorldPlanPoint": null
		})
	return reference


func _verify_producer_contracts(canonical: Dictionary) -> void:
	var world: Dictionary = WorldMap.data
	var source_copy: Dictionary = canonical.duplicate(true)
	var draft: Dictionary = _builder_fixture(canonical, world)
	var valid: Dictionary = GeometryAdapter.from_builder_draft(canonical, draft, world)
	assert(valid.ok, "Complete B v2 world-plan coordinates should produce an isolated preview")
	assert(valid.complete and valid.updatedAnchorCount == canonical.anchors.size())
	assert(not valid.runtimeApproved and not valid.data.provenance.productionReady)
	assert(valid.data.provenance.coordinateSpace == "world-plan")
	assert(valid.data.edges == canonical.edges, "Never rewrite canonical route topology")
	assert(valid.data.anchors[0].position == _world_plan_points()["RM-NAV-HALL-SPAWN"])
	assert(canonical == source_copy, "World-plan overlay must not modify original greybox data")
	var graph := Graph.new()
	graph.rebuild(Snapshot.fresh(), valid.data)
	assert(graph.position("RM-NAV-HALL-SPAWN") == Vector2(850,700))
	assert(graph.route_to_hotspot("RM-NAV-HALL-SPAWN", "RM-HS-002").is_empty())
	var state := Snapshot.fresh()
	state.unlockedDoors.append("RM-DOOR-CORRIDOR-BEDROOM")
	graph.rebuild(state, valid.data)
	assert(not graph.route_to_hotspot("RM-NAV-HALL-SPAWN", "RM-HS-002").is_empty())

	# B's current one-anchor "RM-NAV-HALL-CHECK" sample is NOT a canonical
	# gameplay anchor. Missing/unknown anchors and mismatched IDs fail closed.
	var invalid: Dictionary = draft.duplicate(true)
	invalid.navigationAnchors[0].id = "RM-NAV-HALL-CHECK"
	assert(not GeometryAdapter.from_builder_draft(canonical, invalid, world).ok)
	invalid = draft.duplicate(true)
	invalid.navigationAnchors.pop_back()
	assert(not GeometryAdapter.from_builder_draft(canonical, invalid, world).ok)
	invalid = draft.duplicate(true)
	invalid.navigationAnchors[0].roomId = "RM-ROOM-BEDROOM"
	assert(not GeometryAdapter.from_builder_draft(canonical, invalid, world).ok)
	invalid = draft.duplicate(true)
	invalid.navigationAnchors[0].point = [3000, 30]
	assert(not GeometryAdapter.from_builder_draft(canonical, invalid, world).ok)
	invalid = draft.duplicate(true)
	invalid.navigationAnchors[0].point = [NAN, 700]
	assert(not GeometryAdapter.from_builder_draft(canonical, invalid, world).ok)
	invalid = draft.duplicate(true)
	invalid.navigationAnchors[0].point = ["850", 700]
	assert(not GeometryAdapter.from_builder_draft(canonical, invalid, world).ok)
	invalid = draft.duplicate(true)
	invalid.doorPlacements[2].rooms = ["RM-ROOM-HALL", "RM-ROOM-BEDROOM"]
	assert(not GeometryAdapter.from_builder_draft(canonical, invalid, world).ok)
	invalid = draft.duplicate(true)
	invalid.doorPlacements[2].id = "RM-DOOR-UNKNOWN"
	assert(not GeometryAdapter.from_builder_draft(canonical, invalid, world).ok)
	invalid = draft.duplicate(true)
	invalid.roomRegions[1].id = "RM-ROOM-HALL-UNKNOWN"
	assert(not GeometryAdapter.from_builder_draft(canonical, invalid, world).ok)
	invalid = draft.duplicate(true)
	invalid.calibration.worldRect = [0, 0, 1000, 1000]
	assert(not GeometryAdapter.from_builder_draft(canonical, invalid, world).ok)
	invalid = draft.duplicate(true)
	invalid.calibration.controlPoints = []
	assert(not GeometryAdapter.from_builder_draft(canonical, invalid, world).ok)
	invalid = draft.duplicate(true)
	invalid.productionReady = true
	assert(not GeometryAdapter.from_builder_draft(canonical, invalid, world).ok)
	var outer_project := {"schemaVersion":1, "firstFloorDraft": draft}
	assert(GeometryAdapter.from_builder_draft(canonical, outer_project, world).ok, "B's nested v2 inside project v1 must work")

	# A manifest references known IDs but its referenceGreyboxPoint is in a
	# DIFFERENT space. Even valid IDs do not produce usable movement coordinates.
	var art: Dictionary = _art_fixture(canonical, world)
	var audit: Dictionary = GeometryAdapter.audit_art_reference(canonical, art, world)
	assert(audit.ok and audit.idCount == 13 and audit.calibratedCount == 0)
	assert(not audit.usableNavigationData)
	art.navigationReferenceAnchors[0].referenceGreyboxPoint = [99999, 99999]
	assert(GeometryAdapter.audit_art_reference(canonical, art, world).ok, "Greybox value must not be interpreted as world position")
	art = _art_fixture(canonical, world)
	art.navigationReferenceAnchors[0].id = "RM-NAV-UNKNOWN"
	assert(not GeometryAdapter.audit_art_reference(canonical, art, world).ok)
	art = _art_fixture(canonical, world)
	art.navigationReferenceAnchors[0].roomId = "RM-ROOM-CORRIDOR"
	assert(not GeometryAdapter.audit_art_reference(canonical, art, world).ok)
	art = _art_fixture(canonical, world)
	art.doors[2].roomIds = ["RM-ROOM-HALL", "RM-ROOM-BEDROOM"]
	assert(not GeometryAdapter.audit_art_reference(canonical, art, world).ok)
	art = _art_fixture(canonical, world)
	art.coordinateSystems.greyboxGraph.directMappingToWorldPlan = true
	assert(not GeometryAdapter.audit_art_reference(canonical, art, world).ok)
	art = _art_fixture(canonical, world)
	art.navigationReferenceAnchors[0].calibratedWorldPlanPoint = [INF, 500]
	assert(not GeometryAdapter.audit_art_reference(canonical, art, world).ok)
	assert(canonical == source_copy)


func _verify_in_flight_gate_change(canonical: Dictionary) -> void:
	var open := Snapshot.fresh()
	open.unlockedDoors.append("RM-DOOR-CORRIDOR-BEDROOM")
	var graph := Graph.new()
	graph.rebuild(open, canonical)
	var session := RouteSession.new(graph)
	assert(session.restore(open) == "RM-NAV-HALL-SPAWN")
	assert(session.request_hotspot("RM-HS-002").ok)
	var hops := 0
	while session.current_anchor() != "RM-NAV-BEDROOM-NEAR":
		var step: Dictionary = session.next_segment()
		assert(step.has("toAnchorId"))
		assert(session.finish_segment(str(step.toAnchorId)).ok)
		hops += 1
		assert(hops < 15)
	var crossing: Dictionary = session.next_segment()
	assert(crossing.toAnchorId == "RM-NAV-BEDROOM-FAR")
	var locked := Snapshot.fresh()
	graph.rebuild(locked, canonical)
	var failure: Dictionary = session.finish_segment(str(crossing.toAnchorId))
	assert(not failure.ok and failure.error == "segment-blocked")
	assert(failure.rollbackAnchorId == "RM-NAV-BEDROOM-NEAR")
	assert(session.current_anchor() == "RM-NAV-BEDROOM-NEAR")
	assert(session.in_flight_anchor().is_empty() and session.pending_hotspot().is_empty())
	var event: Dictionary = session.checkpoint_event("nav-gate-mid-segment")
	assert(event.anchorId == "RM-NAV-CORRIDOR-CENTER", "Never checkpoint through a closed threshold")
	assert(session.next_segment().is_empty())
	assert(not session.request_hotspot("RM-HS-002").ok)
