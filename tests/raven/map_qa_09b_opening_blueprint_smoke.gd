extends SceneTree
const Routes = preload("res://addons/room_builder_routes/route_document.gd")
const Freehand = preload("res://addons/room_builder_routes/route_freehand.gd")
const Blueprint = preload("res://scripts/raven/first_floor_opening_blueprint.gd")
const Adapter = preload("res://scripts/raven/first_floor_integrated_draft_adapter.gd")
const Preview = preload("res://addons/room_builder_routes/route_preview_source.gd")
const Scene = preload("res://scenes/raven/tests/first_floor_integrated_qa.tscn")
const View = preload("res://addons/room_builder_routes/route_editor_view.gd")
const SAVE := "user://room_builder_routes/09b_blueprint_roundtrip.json"
var _doc: Dictionary

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var baseline := FileAccess.get_file_as_string(Blueprint.PATH.get_base_dir()+"/map_qa_08_visual_candidate.v1.json")
	var loaded := Routes.load_draft(Blueprint.PATH)
	assert(loaded.get("ok", false), str(loaded.get("error", "")))
	_doc = loaded.document
	assert(_doc.waypoints.size() == 34 and _doc.routes.size() == 29)
	assert(_doc.sharedDoorContacts.size() == 4)
	assert(Routes.save_draft(SAVE, _doc).get("ok", false))
	var saved := Adapter.load_source(Preview.USER, SAVE)
	assert(saved.get("ok", false), str(saved.get("error", "")))
	assert(saved.contract.transitions.size() == 8 and saved.openingBlueprint)
	var qa = Scene.instantiate()
	root.add_child(qa)
	await process_frame
	assert(qa.load_source(Preview.PROJECT, Blueprint.PATH))
	for contact in _doc.sharedDoorContacts:
		assert(not contact.physicalPortalApproved and contact.authority == "TEST_ONLY")
		var pair: Array = contact.waypointIds
		var point := Routes._vector(Routes._waypoint_lookup(_doc)[pair[0]].pointPx)
		assert(Freehand._room_error(_doc, contact.roomIds[0], point).is_empty())
		assert(Freehand._room_error(_doc, contact.roomIds[1], point).is_empty())
		assert(qa.restart_island(contact.roomIds[0]))
		var id := str(contact.id)+"-AB"
		assert(qa.transition(id).get("error") == "locked-door")
		assert(qa.host.test_gate(contact.doorId, "open"))
		var before_handoff: Array[Vector2] = []
		qa.host.actor.segment_completed.connect(func(anchor, feet):
			if anchor == pair[0] or anchor == pair[1]:
				before_handoff.append(feet))
		assert(qa.transition(id).get("ok", false))
		_drive(qa.host)
		assert(qa.host.active_room_id == contact.roomIds[1])
		assert(qa.host.actor.position == point)
		assert(before_handoff.size() >= 1 and before_handoff.back() == point)
		# Move away on the destination graph before walking back over the sill.
		assert(qa.walk_waypoint(qa._loaded.starts[contact.roomIds[1]]).get("ok", false))
		_drive(qa.host)
		assert(qa.transition(str(contact.id)+"-BA").get("ok", false))
		_drive(qa.host)
		assert(qa.host.active_room_id == contact.roomIds[0])
		assert(qa.host.actor.position == point)
		await process_frame
	# Exported paired contacts must coincide before the QA adapter accepts them.
	var bad: Dictionary = _doc.duplicate(true)
	bad.sharedDoorContacts[0].roomIds[0] = "RM-ROOM-KITCHEN"
	assert(not Routes.validate(bad).get("ok", false))
	bad = _doc.duplicate(true)
	bad.sharedDoorContacts[0].doorId = "RM-DOOR-CORRIDOR-KITCHEN"
	assert(Routes.save_draft(SAVE, bad).get("ok", false))
	assert(not Adapter.load_source(Preview.USER, SAVE).get("ok", false))
	var misaligned := Routes.move_waypoint(_doc, "QA-09B-HA-B", Vector2(610,608))
	assert(misaligned.get("ok", false))
	assert(Routes.save_draft(SAVE, misaligned.document).get("ok", false))
	assert(not Adapter.load_source(Preview.USER, SAVE).get("ok", false))
	var disposable: Dictionary = _doc.duplicate(true)
	for route in _doc.routes:
		if route.get("from") == "QA-09B-HA-A" or route.get("to") == "QA-09B-HA-A":
			var removed := Routes.delete_route(disposable, route.id)
			assert(removed.get("ok", false))
			disposable = removed.document
	var deleted := Routes.delete_waypoint(disposable, "QA-09B-HA-A")
	assert(deleted.get("ok", false))
	assert(deleted.document.sharedDoorContacts.size() == 3)
	assert(qa.restart_island("RM-ROOM-HALL"))
	assert(qa.host.test_gate("RM-DOOR-HALL-CORRIDOR", "open"))
	assert(qa.transition("QA-09B-HC-AB").get("ok", false))
	qa.host.actor.advance(0.025)
	assert(qa.host.pause_movement())
	var paused: Vector2 = qa.host.actor.position
	qa.host.actor.advance(10.0)
	assert(qa.host.actor.position == paused)
	assert(qa.host.resume_movement())
	assert(qa.host.test_gate("RM-DOOR-HALL-CORRIDOR", "gated"))
	_drive(qa.host)
	assert(qa.host.active_room_id == "RM-ROOM-HALL")
	var view = View.new()
	root.add_child(view)
	view._load_project_path(Blueprint.PATH)
	assert(view.last_project_path == Blueprint.PATH)
	view._preview_clear_ai()
	view._confirm_clear_ai()
	view._undo()
	assert(view.document.walkablePolygons.size() == 15)
	view.queue_free()
	qa.queue_free()
	assert(FileAccess.get_file_as_string(Blueprint.PATH.get_base_dir()+"/map_qa_08_visual_candidate.v1.json") == baseline)
	print("MAP-QA-09B editable opening blueprint and zero-jump threshold crossings passed")
	quit()

func _drive(host: Node) -> void:
	for tick in range(5000):
		if not host.actor.has_active_segment():
			return
		var previous: Vector2 = host.actor.position
		host.actor.advance(0.025)
		assert(previous.distance_to(host.actor.position) <= 3.251, "Room handoff must not relocate Onoe")
		assert(Routes.restriction_at(host.actor.position, _doc).kind == "allowed")
		for zone in _doc.noGoPolygons:
			var points := Routes._polygon_points(zone)
			for i in points.size():
				var closest := Geometry2D.get_closest_point_to_segment(host.actor.position, points[i], points[(i+1)%points.size()])
				assert(host.actor.position.distance_to(closest) >= 11.99, "12px feet proxy hits "+str(zone.id))
	assert(false, "Blueprint movement did not settle")
