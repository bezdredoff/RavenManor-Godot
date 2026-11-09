extends SceneTree
## MAP-QA-07B: integration smoke (real Onoe movement, not scene instantiation).
const Adapter = preload("res://scripts/raven/first_floor_integrated_draft_adapter.gd")
const Routes = preload("res://addons/room_builder_routes/route_document.gd")
const Preview = preload("res://addons/room_builder_routes/route_preview_source.gd")
const HostScene = preload("res://scenes/raven/tests/first_floor_multi_room_host.tscn")
const DemoScene = preload("res://scenes/raven/tests/first_floor_integrated_qa.tscn")
const Snapshot = preload("res://scripts/raven/raven_snapshot.gd")
const HALL := "RM-ROOM-HALL"
const CORRIDOR := "RM-ROOM-CORRIDOR"
const BEDROOM := "RM-ROOM-BEDROOM"
const EDIT_PATH := "user://room_builder_routes/map_qa_07b_smoke.json"
var host


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var before_save := JSON.stringify(Snapshot.fresh())
	var source := Adapter.load_source(Preview.PROJECT)
	assert(source.get("ok", false), str(source.get("error", "")))
	assert(source["contract"]["approval"] == "TEST_ONLY")
	assert(source["contract"]["draftAuthority"] == "DRAFT_ONLY")
	assert(source["document"]["approval"] == "DRAFT_ONLY")
	assert(not source["document"]["productionReady"])
	assert(source["waypointCount"] == 22 and source["routeCount"] == 19)
	assert(source["unresolvedCount"] == 17)
	assert(source["contract"]["rooms"].size() == 5)
	assert(source["contract"]["transitions"].size() == 5)
	var graph_counts := {}
	for room in source["contract"]["rooms"]:
		var data: Dictionary = room["graph"]
		var wp_count := 0
		for anchor in data["anchors"]:
			assert(anchor["roomId"] == room["id"])
			if not str(anchor["id"]).contains("-STEP-"):
				wp_count += 1
		assert(data["provenance"]["productionReady"] == false)
		assert(data["provenance"]["approval"] == "DRAFT_ONLY")
		graph_counts[room["id"]] = wp_count
	assert(graph_counts == {
		"RM-ROOM-HALL":9, "RM-ROOM-CORRIDOR":4, "RM-ROOM-BEDROOM":3,
		"RM-ROOM-ARCHIVE":3, "RM-ROOM-KITCHEN":3})
	# Authored turns are preserved by the EXISTING editor compiler.
	var corridor: Dictionary = _room_graph(source["contract"], CORRIDOR)
	assert(corridor["edges"].size() > 3)
	var route_step := "QA-ROUTE-011-STEP-001"
	var found_step := false
	for anchor in corridor["anchors"]:
		if anchor["id"] == route_step:
			found_step = true
			assert(Vector2(float(anchor["position"][0]), float(anchor["position"][1])) == Vector2(816, 336))
	assert(found_step)
	var archive: Dictionary = _room_graph(source["contract"], "RM-ROOM-ARCHIVE")
	assert(archive["anchors"].size() >= 3)
	# Invalid identity, missing ownership and fabricated cross-room edges fail closed.
	var invalid: Dictionary = source["document"].duplicate(true)
	invalid["source"]["sha256"] = "not-approved"
	assert(not Routes.validate(invalid).get("ok", false))
	invalid = source["document"].duplicate(true)
	invalid["waypoints"][9].erase("roomId")
	var invalid_path := Routes.save_draft(EDIT_PATH, invalid)
	assert(not invalid_path.get("ok", false), "Cannot save invalid schema")
	# One-way authored edge remains one-way (no hidden automatic reverse).
	invalid = source["document"].duplicate(true)
	for r in invalid["routes"]:
		if r["id"] == "QA-ROUTE-014":
			r["bidirectional"] = false
	var check: Dictionary = Routes.compile_qa_graph(invalid)
	assert(check.get("ok", false))
	assert(check["graph"].route("QA-BEDROOM-WINDOW", "QA-BEDROOM-RUG").is_empty())
	assert(not check["graph"].route("QA-BEDROOM-RUG", "QA-BEDROOM-WINDOW").is_empty())
	assert(check["graph"].route("QA-HALL-SPAWN", "QA-BEDROOM-RUG").is_empty())
	# Original 7-point Hall pilot remains separately selectable.
	var original := Adapter.load_source(Preview.BASELINE)
	assert(original.get("ok", false))
	assert(original["contract"]["rooms"].size() == 1)
	assert(original["waypointCount"] == 7 and original["routeCount"] == 7)
	assert(original["contract"]["transitions"].is_empty())

	# Editor save/export → persisted source → different real physical waypoint.
	var edited := Routes.move_waypoint(source["document"], "QA-CORRIDOR-LOWER", Vector2(882, 368))
	assert(edited.get("ok", false), str(edited.get("error", "")))
	assert(Routes.save_draft(EDIT_PATH, edited["document"]).get("ok", false))
	var saved := Adapter.load_source(Preview.USER, EDIT_PATH)
	assert(saved.get("ok", false), str(saved.get("error", "")))
	assert(saved["sourcePath"] == EDIT_PATH)
	assert(_point(corridor, "QA-CORRIDOR-LOWER") == Vector2(880, 368))
	assert(_point(_room_graph(saved["contract"], CORRIDOR), "QA-CORRIDOR-LOWER") == Vector2(882, 368))
	var unmodified := Adapter.load_source(Preview.PROJECT)
	assert(_point(_room_graph(unmodified["contract"], CORRIDOR), "QA-CORRIDOR-LOWER") == Vector2(880, 368),
		"Unsaved/in-memory modifications cannot leak into project draft")
	# Actually move Onoe along ordered compiled cell anchors, not a straight shortcut.
	host = HostScene.instantiate()
	root.add_child(host)
	await process_frame
	assert(host.configure_host(saved["contract"], saved["visuals"], CORRIDOR, "QA-CORRIDOR-WEST"))
	var visited_segments: Array[String] = []
	host.actor.segment_completed.connect(func(id, _feet): visited_segments.append(str(id)))
	assert(host.request_hotspot("QA-HS:QA-CORRIDOR-LOWER").get("ok"))
	_drive_idle()
	assert(host.controller.confirmed_anchor() == "QA-CORRIDOR-LOWER")
	assert(host.actor.position == Vector2(882, 368), "Editor change must alter physical Onoe feet")
	assert(visited_segments.has("QA-ROUTE-011-STEP-001"),
		"Actor must traverse authored intermediate cell anchor")
	assert(visited_segments.has("QA-CORRIDOR-CENTRE"))
	host.toggle_routes()
	assert(host.route_overlay.visible)
	assert(host.request_hotspot("QA-HS:QA-CORRIDOR-WEST").get("ok"))
	assert(host.actor.has_active_segment())
	var paused_at: Vector2 = host.actor.position
	assert(host.pause_movement())
	host.actor.advance(60.0)
	assert(host.actor.position == paused_at)
	assert(host.resume_movement())
	assert(host.cancel_request().get("finishCurrentSegment"))
	_drive_idle()
	assert(host.active_room_id == CORRIDOR)
	host.queue_free()

	# Physical approach + explicit TEST_ONLY handoffs on full image coordinates.
	host = HostScene.instantiate()
	root.add_child(host)
	await process_frame
	var rooms_visited: Array[String] = []
	var arrivals: Array[String] = []
	host.actor.segment_completed.connect(func(id, _feet): arrivals.append(str(id)))
	assert(host.configure_host(source["contract"], source["visuals"], HALL, "QA-HALL-SPAWN"))
	host.room_changed.connect(func(details): rooms_visited.append(str(details.get("roomId", ""))))
	assert(host.actor.position == Vector2(836, 746))
	assert(host.request_transition("QA-07B-TR-LOCKED").get("error") == "locked-door")
	assert(host.request_transition("QA-07B-NOT-A-DOOR").get("error") == "unknown-transition")
	assert(host.request_transition("QA-07B-TR-HC").get("ok"))
	assert(host.active_room_id == HALL, "No room swap on request")
	assert(host.request_transition("QA-07B-TR-HC").get("status") == "unchanged")
	_drive_room(CORRIDOR)
	assert(arrivals.has("QA-HALL-PORTAL-APPROACH"))
	assert(host.actor.position == _point(corridor, "QA-CORRIDOR-WEST"))
	assert(host.controller.confirmed_anchor() == "QA-CORRIDOR-WEST")
	assert(host.request_transition("QA-07B-TR-CB").get("ok"))
	_drive_room(BEDROOM)
	assert(arrivals.has("QA-CORRIDOR-EAST"))
	assert(host.controller.confirmed_anchor() == "QA-BEDROOM-RUG")
	assert(host.actor.position == Vector2(432, 336))
	assert(host.request_transition("QA-07B-TR-BC").get("ok"))
	_drive_room(CORRIDOR)
	assert(host.controller.confirmed_anchor() == "QA-CORRIDOR-EAST")
	assert(host.request_transition("QA-07B-TR-CH").get("ok"))
	_drive_room(HALL)
	assert(host.controller.confirmed_anchor() == "QA-HALL-RETURN-SAFE")
	assert(host.actor.position == Vector2(932, 746))
	assert(rooms_visited == [CORRIDOR, BEDROOM, CORRIDOR, HALL])
	# Gate closure must cancel pending doorway, not force a handoff.
	assert(host.request_transition("QA-07B-TR-HC").get("ok"))
	host.actor.advance(0.1)
	assert(host.test_gate("QA-07B-DOOR-HC", "gated"))
	_drive_idle()
	assert(host.active_room_id == HALL)
	assert(host.controller.pending_transition().is_empty())
	assert(host.request_transition("QA-07B-TR-HC").get("error") == "locked-door")
	host.queue_free()

	# F6 scene must really run; changed editor data must drive same route.
	var demo = DemoScene.instantiate()
	root.add_child(demo)
	await process_frame
	assert(is_instance_valid(demo.host) and demo.host.ready_for_test)
	assert(demo.host.active_room_id == HALL)
	assert(demo.load_source(Preview.USER, EDIT_PATH))
	assert(demo.restart_island(CORRIDOR))
	assert(demo.walk_waypoint("QA-CORRIDOR-LOWER").get("ok"))
	for i in range(60):
		if not demo.host.actor.has_active_segment():
			break
		demo.host.actor.advance(60.0)
	assert(demo.host.actor.position == Vector2(882, 368))
	assert(not demo.load_source(Preview.USER, EDIT_PATH),
		"Reload while at non-safe interaction anchor must be rejected")
	demo.toggle_debug()
	demo.queue_free()
	assert(JSON.stringify(Snapshot.fresh()) == before_save)
	assert(DirAccess.remove_absolute(ProjectSettings.globalize_path(EDIT_PATH)) == OK)
	print("Raven MAP-QA-07B integrated first-floor authored Onoe movement smoke passed")
	quit()


func _room_graph(contract: Dictionary, id: String) -> Dictionary:
	for room in contract.get("rooms", []):
		if room["id"] == id:
			return room["graph"]
	return {}


func _point(graph: Dictionary, id: String) -> Vector2:
	for anchor in graph.get("anchors", []):
		if anchor["id"] == id:
			return Vector2(float(anchor["position"][0]), float(anchor["position"][1]))
	return Vector2.INF


func _drive_room(target: String) -> void:
	for i in range(120):
		if host.active_room_id == target:
			return
		assert(host.actor.has_active_segment(), "No handoff before physical approach")
		host.actor.advance(60.0)
	assert(host.active_room_id == target, "Expected TEST_ONLY room " + target)


func _drive_idle() -> void:
	for i in range(120):
		if not host.actor.has_active_segment():
			return
		host.actor.advance(60.0)
	assert(not host.actor.has_active_segment())
