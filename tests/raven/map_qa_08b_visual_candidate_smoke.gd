extends SceneTree
## Independent candidate: real compiler, per-room physical mover, draft round-trip.
const Routes = preload("res://addons/room_builder_routes/route_document.gd")
const Adapter = preload("res://scripts/raven/first_floor_integrated_draft_adapter.gd")
const Preview = preload("res://addons/room_builder_routes/route_preview_source.gd")
const Host = preload("res://scenes/raven/tests/first_floor_multi_room_host.tscn")
const View = preload("res://addons/room_builder_routes/route_editor_view.gd")
const Freehand = preload("res://addons/room_builder_routes/route_freehand.gd")
const Demo = preload("res://scenes/raven/tests/first_floor_integrated_qa.tscn")
const PATH := "res://assets/raven/map/qa/drafts/map_qa_08_visual_candidate.v1.json"
const SAVE := "user://room_builder_routes/map_qa_08b_roundtrip.json"
var _doc: Dictionary

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var loaded := Routes.load_draft(PATH)
	assert(loaded.get("ok", false), str(loaded.get("error", "")))
	var doc: Dictionary = loaded.document
	_doc = doc
	assert(doc.taskId == "MAP-QA-08B" and doc.coordinateSpace == "image-pixel")
	assert(FileAccess.get_sha256("res://" + Routes.IMAGE_PATH) == Routes.IMAGE_SHA256)
	assert(doc.walkablePolygons.size() == 5 and doc.noGoPolygons.size() >= 15)
	assert(doc.waypoints.size() == 26 and doc.routes.size() == 21)
	for group in ["walkablePolygons", "noGoPolygons", "waypoints", "routes"]:
		for item in doc[group]:
			assert(item.origin == "AI_DRAFT")
			assert(item.calibrationStatus != "PRODUCTION_APPROVED")
	for route in doc.routes:
		assert(not route.provisional and route.cells.size() >= 2 and route.bidirectional)
	var reference: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/raven/map/qa/drafts/map_qa_08_story_targets.v1.json"))
	assert(doc.storyTargets.size() >= reference.targetPoints.size())
	for target in reference.targetPoints:
		var found := false
		for actual in doc.storyTargets:
			if target.id != actual.id:
				continue
			found = true
			assert(target.relatedHotspotIds == actual.relatedHotspotIds)
			assert(target.relatedStoryIds == actual.relatedStoryIds)
			assert(actual.status in ["VISUALLY_CONFIRMED_CANDIDATE", "UNRESOLVED", "OUT_OF_SCOPE"])
		assert(found)
	assert(doc.doorCandidates.size() == 11)
	for door in doc.doorCandidates:
		assert(not door.get("physicalPortalApproved", false))
		assert(door.status != "PRODUCTION_APPROVED")
	assert(Routes.save_draft(SAVE, doc).get("ok", false))
	var roundtrip := Routes.load_draft(SAVE)
	assert(roundtrip.get("ok", false))
	assert(JSON.stringify(doc) == JSON.stringify(roundtrip.document))
	var view = View.new()
	root.add_child(view)
	view._load_visual_candidate()
	assert(view.last_project_path == PATH and view.document.taskId == "MAP-QA-08B")
	var before := JSON.stringify(view.document)
	view._preview_clear_ai()
	assert(view.clear_ai_proposal.get("ok", false))
	view._confirm_clear_ai()
	assert(view.document.noGoPolygons.is_empty() and view.document.walkablePolygons.is_empty())
	view._undo()
	assert(JSON.stringify(view.document) == before)
	view._redo()
	assert(view.document.walkableBoundaryMode == "OPEN")
	view._undo()
	# Candidate routes use the existing freehand authoring workflow unchanged.
	var stroke := PackedVector2Array([Vector2(440, 344), Vector2(440, 280)])
	var proposal := Freehand.convert(doc, "RM-ROOM-BEDROOM", "QA-BEDROOM-RUG", "QA-08B-BEDROOM-NIGHT", stroke)
	assert(proposal.get("ok", false), str(proposal.get("error", "")))
	var added := Routes.add_waypoint(doc, Vector2(472, 312), "Manual bedroom point", "RM-ROOM-BEDROOM")
	assert(added.get("ok", false))
	assert(Routes.room_for_id(added.document, added.id) == "RM-ROOM-BEDROOM")
	view.queue_free()
	var candidate := Adapter.load_source(Preview.PROJECT, PATH)
	assert(candidate.get("ok", false), str(candidate.get("error", "")))
	assert(candidate.contract.rooms.size() == 5)
	assert(candidate.contract.transitions.size() == 5)
	for transition in candidate.contract.transitions:
		assert(transition.authority == "TEST_ONLY" and not transition.physicalPortalApproved)
	var compiled := Routes.compile_qa_graph(doc)
	assert(compiled.get("ok", false))
	assert(compiled.graph.route("QA-HALL-SPAWN", "QA-BEDROOM-RUG").is_empty())
	# Every target in every island is reached physically, then traversed in reverse.
	for room in candidate.contract.rooms:
		var host = Host.instantiate()
		root.add_child(host)
		await process_frame
		var start: String = candidate.starts[room.id]
		assert(host.configure_host(candidate.contract, candidate.visuals, room.id, start))
		assert(host.actor.sprite_height == 62.0)
		for wp in doc.waypoints:
			if wp.roomId != room.id or wp.id == start:
				continue
			assert(not compiled.graph.route(start, wp.id).is_empty())
			assert(host.request_hotspot(str(host.current_graph().anchor(wp.id).hotspotId)).get("ok", false))
			_drive(host)
			assert(host.controller.confirmed_anchor() == wp.id)
			assert(host.actor.position.distance_to(Routes._vector(wp.pointPx)) < 0.01)
			assert(host.request_hotspot(str(host.current_graph().anchor(start).hotspotId)).get("ok", false))
			_drive(host)
			assert(host.controller.confirmed_anchor() == start)
		host.toggle_routes()
		assert(host.route_overlay.visible)
		host.queue_free()
	# Old project source remains a separate selectable 22/19 regression baseline.
	var old := Adapter.load_source(Preview.PROJECT)
	assert(old.get("ok", false) and old.waypointCount == 22 and old.routeCount == 19)
	var demo = Demo.instantiate()
	root.add_child(demo)
	await process_frame
	assert(demo.load_source(Preview.PROJECT, PATH))
	assert(demo._source_path == PATH)
	assert(demo.walk_waypoint("QA-HALL-CENTRE").get("ok", false))
	assert(demo.host.pause_movement())
	var paused: Vector2 = demo.host.actor.position
	demo.host.actor.advance(10.0)
	assert(demo.host.actor.position == paused)
	assert(demo.host.resume_movement())
	_drive(demo.host)
	demo.toggle_debug()
	assert(demo.host.route_overlay.visible)
	demo._toggle_follow()
	assert(demo._manual_camera)
	demo._toggle_follow()
	assert(not demo._manual_camera)
	assert(demo.walk_waypoint("QA-HALL-SPAWN").get("ok", false))
	assert(demo.host.cancel_request().get("finishCurrentSegment", false))
	_drive(demo.host)
	demo.queue_free()
	print("MAP-QA-08B visual candidate geometry and physical movement passed")
	quit()

func _drive(host: Node) -> void:
	for i in range(2000):
		if not host.actor.has_active_segment():
			return
		# Small substeps exercise actual movement rather than only segment endpoints.
		host.actor.advance(0.025)
		assert(Routes.restriction_at(host.actor.position, _doc).kind == "allowed")
		for zone in _doc.noGoPolygons:
			var points := Routes._polygon_points(zone)
			for edge in points.size():
				var closest := Geometry2D.get_closest_point_to_segment(host.actor.position, points[edge], points[(edge + 1) % points.size()])
				assert(host.actor.position.distance_to(closest) >= 12.0, "12px feet proxy touches " + str(zone.id))
	assert(false, "Physical mover did not arrive")
