extends RefCounted
## MAP-EDIT-03: native editor usability/ownership and MAP-QA-07B saved runtime bridge.
const Routes = preload("res://addons/room_builder_routes/route_document.gd")
const View = preload("res://addons/room_builder_routes/route_editor_view.gd")
const Integrated = preload("res://scripts/raven/first_floor_integrated_draft_adapter.gd")
const Source = preload("res://addons/room_builder_routes/route_preview_source.gd")
const ORIGINAL := "res://assets/raven/map/qa/first_floor_hall_pilot.v1.json"
const PROJECT := "res://assets/raven/map/qa/drafts/hall_routes_draft.v1.json"
const CANONICAL := "res://data/raven/manor_greybox_graph.json"
const TEMP := "user://room_builder_routes/map_edit_03_roundtrip_smoke.json"
const CORRIDOR := "RM-ROOM-CORRIDOR"
const BEDROOM := "RM-ROOM-BEDROOM"
const HALL := "RM-ROOM-HALL"


static func run(test_root: Window) -> void:
	var source_before := FileAccess.get_file_as_string(ORIGINAL)
	var project_before := FileAccess.get_file_as_string(PROJECT)
	var canonical_before := FileAccess.get_file_as_string(CANONICAL)
	assert(not source_before.is_empty() and not project_before.is_empty() and not canonical_before.is_empty())
	var baseline := Routes.import_hall()
	assert(baseline.get("ok", false))
	assert(Routes.validate(baseline.document).ok)
	assert(Routes.waypoint_room(baseline.document.waypoints[0]) == HALL)
	assert(not baseline.document.waypoints[0].has("roomId"), "Legacy seven Hall IDs remain valid")
	assert(not Routes.add_waypoint(baseline.document, Vector2(840, 730)).get("ok", false),
		"New points cannot silently inherit Hall")
	assert(not Routes.add_waypoint(baseline.document, Vector2(840, 730), "Bad", "RM-ROOM-UNKNOWN").get("ok", false))
	var legacy_added := Routes.add_waypoint(baseline.document, Vector2(840, 730), "Owner", HALL)
	assert(legacy_added.ok)
	assert(Routes.room_for_id(legacy_added.document, legacy_added.id) == HALL)
	assert(Routes.set_waypoint_room(legacy_added.document, legacy_added.id, CORRIDOR).get("ok", false),
		"An unconnected waypoint may change room")
	assert(not Routes.set_waypoint_room(legacy_added.document, legacy_added.id, "invalid").get("ok", false))
	assert(not Routes.set_waypoint_room(legacy_added.document, "does-not-exist", HALL).get("ok", false))
	assert(Routes.room_for_id(legacy_added.document, "QA-HALL-SPAWN") == HALL)
	assert(Routes.add_route(baseline.document, "QA-HALL-SPAWN", "QA-HALL-CENTRE").ok)
	assert(not Routes.set_waypoint_room(baseline.document, "QA-HALL-CENTRE", BEDROOM).ok,
		"Moving a connected waypoint to a different room must reject, never create a cross-room route")
	var bad: Dictionary = baseline.document.duplicate(true)
	bad["waypoints"][0]["roomId"] = "RM-ROOM-UNKNOWN"
	assert(not Routes.validate(bad).ok)

	var loaded := Routes.load_draft(PROJECT)
	assert(loaded.ok, str(loaded.get("error", "")))
	var original: Dictionary = loaded.document
	assert(original["waypoints"].size() == 22 and original["routes"].size() == 19)
	assert(original["approval"] == "DRAFT_ONLY" and not original["productionReady"])
	for wp in original["waypoints"]:
		assert(Routes.ROOM_IDS.has(Routes.waypoint_room(wp)))
	var new_point := Routes.add_waypoint(original, Vector2(912, 336), "New corridor waypoint", CORRIDOR)
	assert(new_point.ok, str(new_point.get("error", "")))
	assert(new_point.id.begins_with("QA-USER-"))
	assert(Routes.room_for_id(new_point.document, new_point.id) == CORRIDOR)
	assert(new_point.document["waypoints"].size() == 23)
	assert(original["waypoints"].size() == 22)
	assert(not Routes.add_route(new_point.document, new_point.id, "QA-BEDROOM-RUG").ok)
	var cross_error := Routes.add_route(new_point.document, new_point.id, "QA-BEDROOM-RUG")
	assert(str(cross_error.get("error", "")).contains("different rooms"))
	var connected := Routes.add_route(new_point.document, "QA-CORRIDOR-CENTRE", new_point.id)
	assert(connected.ok, str(connected.get("error", "")))
	assert(connected.document["routes"].size() == 20)
	assert(connected.document["routes"].back()["roomId"] == CORRIDOR)
	assert(not Routes.set_waypoint_room(connected.document, new_point.id, BEDROOM).ok)
	var authored := Routes.set_route_cells(connected.document, str(connected.id), "AB11 → AC11")
	assert(authored.ok, str(authored.get("error", "")))
	assert(not authored.document["routes"].back()["provisional"])
	assert(authored.document["routes"].back()["cells"] == ["AB11", "AC11"])
	assert(Routes.compile_qa_graph(authored.document).get("ok", false))
	assert(Routes.save_draft(TEMP, authored.document).ok)
	var persisted := Routes.load_draft(TEMP)
	assert(persisted.ok)
	assert(JSON.stringify(persisted.document) == JSON.stringify(JSON.parse_string(JSON.stringify(authored.document))))
	assert(Routes.room_for_id(persisted.document, new_point.id) == CORRIDOR)
	var integrated := Integrated.load_source(Source.USER, TEMP)
	assert(integrated.get("ok", false), str(integrated.get("error", "")))
	assert(integrated["waypointCount"] == 23 and integrated["routeCount"] == 20)
	assert(integrated["contract"]["approval"] == "TEST_ONLY" and integrated["document"]["approval"] == "DRAFT_ONLY")
	var found := false
	for room in integrated["contract"]["rooms"]:
		if room["id"] == CORRIDOR:
			for point in room["graph"]["anchors"]:
				if str(point["id"]) == new_point.id:
					found = true
					assert(point["roomId"] == CORRIDOR)
					assert(Vector2(float(point["position"][0]), float(point["position"][1])) == Vector2(912, 336))
	assert(found, "MAP-QA-07B must accept the new authored Corridor point")

	# Test real native UI controls, not only isolated pure-document APIs.
	var view = View.new()
	test_root.add_child(view)
	view._set_document(original, false)
	view._change_room(CORRIDOR)
	assert(view.active_room == CORRIDOR)
	assert(view.room_picker.selected == Routes.ROOM_IDS.find(CORRIDOR))
	assert(view.waypoint_ids.has("QA-CORRIDOR-CENTRE") and not view.waypoint_ids.has("QA-BEDROOM-RUG"))
	view._set_mode("Add")
	assert(view.active_tool_label.text.contains("Add waypoint"))
	assert(view.tool_help.text.contains("roomId"))
	var before_ui := JSON.stringify(view.document)
	view._on_image_clicked(Vector2(912, 336))
	assert(view.document["waypoints"].size() == 23)
	assert(view.history.size() >= 1)
	assert(view.dirty_label.text.contains("UNSAVED"))
	var ui_id := str(view.selected_waypoint)
	assert(Routes.room_for_id(view.document, ui_id) == CORRIDOR)
	view._undo()
	assert(JSON.stringify(view.document) == before_ui)
	view._redo()
	assert(Routes.room_for_id(view.document, ui_id) == CORRIDOR)
	view._set_mode("Connect")
	view._on_canvas_waypoint("QA-CORRIDOR-CENTRE")
	assert(view.connect_from == "QA-CORRIDOR-CENTRE")
	view._on_canvas_waypoint(ui_id)
	assert(view.connect_from.is_empty())
	assert(view.document["routes"].size() == 20)
	var selected_route := view.selected_route
	assert(not selected_route.is_empty())
	view._set_mode("Routes")
	assert(view.canvas.pick_route(Vector2(832, 336)) == "QA-ROUTE-011",
		"Routes can be selected from line geometry, not only the item list")
	view._on_canvas_route(selected_route)
	assert(view.selected_route == selected_route)
	assert(view.canvas.selected_route == selected_route)
	view._set_mode("Cells")
	view._start_cell_path()
	assert(view.route_cells.text == "AB11")
	view._append_route_cell("AE11")
	assert(view.route_cells.text == "AB11", "Nonadjacent cell cannot pollute route text")
	view._append_route_cell("AC11")
	assert(view.route_cells.text == "AB11 → AC11")
	view._apply_route_cells()
	assert(not view.document["routes"].back()["provisional"])
	var edited_ui := JSON.stringify(view.document)
	view._undo()
	assert(view.document["routes"].back()["provisional"])
	view._redo()
	assert(JSON.stringify(view.document) == edited_ui)
	view._on_canvas_waypoint(ui_id)
	view.waypoint_room_picker.select(Routes.ROOM_IDS.find(BEDROOM))
	view._apply_waypoint_info()
	assert(view.status.text.begins_with("ERROR:"))
	assert(Routes.room_for_id(view.document, ui_id) == CORRIDOR)
	assert(JSON.stringify(view.document) == edited_ui)
	# Save + reload remains valid in live QA; baseline project file untouched.
	assert(Routes.save_draft(TEMP, view.document).ok)
	assert(Integrated.load_source(Source.USER, TEMP).get("ok", false))
	view.queue_free()

	assert(Integrated.load_source(Source.BASELINE).get("ok", false))
	assert(FileAccess.get_file_as_string(ORIGINAL) == source_before)
	assert(FileAccess.get_file_as_string(PROJECT) == project_before)
	assert(FileAccess.get_file_as_string(CANONICAL) == canonical_before)
	assert(DirAccess.remove_absolute(ProjectSettings.globalize_path(TEMP)) == OK)
	print("MAP-EDIT-03 native editor room ownership and authoring workflow smoke passed")
