extends SceneTree
## MAP-EDIT-04A: the original 10 NO-GO polygons are editable DRAFT_ONLY data.
## Exercise native selection, corner drag, insert/remove, explicit Apply,
## blocked-point recovery, persisted MAP-QA-07B source and original immutability.
const Routes = preload("res://addons/room_builder_routes/route_document.gd")
const View = preload("res://addons/room_builder_routes/route_editor_view.gd")
const Adapter = preload("res://scripts/raven/first_floor_integrated_draft_adapter.gd")
const Preview = preload("res://addons/room_builder_routes/route_preview_source.gd")
const SOURCE := "res://assets/raven/map/qa/first_floor_hall_pilot.v1.json"
const PROJECT := "res://assets/raven/map/qa/drafts/hall_routes_draft.v1.json"
const CANONICAL := "res://data/raven/manor_greybox_graph.json"
const ART := "res://a_detailed_top_down_isometric_game_map_illustratio.png"
const TEMP := "user://room_builder_routes/map_edit_04a_default_nogo_smoke.json"
const BEDROOM := "RM-ROOM-BEDROOM"
const TABLE := "QA-HALL-NOGO-TEA-TABLE"


func _initialize() -> void:
	call_deferred("_run")


func _mouse(at: Vector2, pressed: bool) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = at
	return event


func _zone(doc: Dictionary, group: String, id: String) -> Dictionary:
	for zone in doc.get(group, []):
		if str(zone["id"]) == id:
			return zone
	return {}


func _run() -> void:
	var before_source := FileAccess.get_file_as_string(SOURCE)
	var before_project := FileAccess.get_file_as_string(PROJECT)
	var before_canonical := FileAccess.get_file_as_string(CANONICAL)
	var before_art := FileAccess.get_sha256(ART)
	assert(not before_source.is_empty() and not before_project.is_empty() and not before_canonical.is_empty())
	var parsed: Dictionary = Routes.load_draft(PROJECT)
	assert(parsed.get("ok", false), str(parsed.get("error", "")))
	var original: Dictionary = parsed["document"]
	assert(original["noGoPolygons"].size() == 10)
	assert(original["walkablePolygons"].size() == 5)
	var before_json := JSON.stringify(original)

	# Every ORIGINAL polygon is editable, not only QA-EDIT-* rectangles.
	for zone in original["noGoPolygons"]:
		var id := str(zone["id"])
		assert(not id.begins_with("QA-EDIT-"))
		var points: PackedVector2Array = Routes._polygon_points(zone)
		points[0] += Vector2(0.5, 0.5)
		var edit: Dictionary = Routes.set_zone_polygon(original, "noGoPolygons", id, points)
		assert(edit.get("ok", false), id + ": " + str(edit.get("error", "")))
		assert(_zone(edit["document"], "noGoPolygons", id)["id"] == id)
		assert(_zone(edit["document"], "noGoPolygons", id).get("roomId", "") == zone.get("roomId", ""))
	assert(JSON.stringify(original) == before_json, "No preview can mutate the source document")
	var original_bed: Dictionary = _zone(original, "noGoPolygons", "QA-BEDROOM-NOGO-BED")
	assert(Routes.restriction_at(Vector2(300, 300), original)["kind"] == "no-go")
	var extra: Dictionary = Routes.add_zone_rectangle(original, "walkablePolygons",
		Vector2(220, 210), Vector2(396, 400), BEDROOM)
	assert(extra.get("ok", false), str(extra.get("error", "")))
	var expanded: Dictionary = extra["document"]
	assert(not Routes.add_waypoint(expanded, Vector2(300, 300), "New floor", BEDROOM).get("ok", false))
	var smaller_bed := PackedVector2Array([
		Vector2(230, 173), Vector2(260, 173), Vector2(260, 300), Vector2(230, 300)])
	var reduced: Dictionary = Routes.set_zone_polygon(expanded, "noGoPolygons", "QA-BEDROOM-NOGO-BED", smaller_bed)
	assert(reduced.get("ok", false), str(reduced.get("error", "")))
	assert(_zone(reduced["document"], "noGoPolygons", "QA-BEDROOM-NOGO-BED")["roomId"] == BEDROOM)
	assert(original_bed["pointsPx"] != _zone(reduced["document"], "noGoPolygons", "QA-BEDROOM-NOGO-BED")["pointsPx"])
	assert(Routes.restriction_at(Vector2(300, 300), reduced["document"])["kind"] == "allowed")
	var new_wp: Dictionary = Routes.add_waypoint(reduced["document"], Vector2(300, 300),
		"Formerly blocked by default bed", BEDROOM)
	assert(new_wp.get("ok", false), str(new_wp.get("error", "")))
	assert(Routes.room_for_id(new_wp["document"], str(new_wp["id"])) == BEDROOM)

	# Never commit invalid polygons or strand existing points/routes.
	var invalid: PackedVector2Array = Routes._polygon_points(_zone(original, "noGoPolygons", TABLE))
	invalid[0] = Vector2(-1, 532)
	assert(not Routes.set_zone_polygon(original, "noGoPolygons", TABLE, invalid).get("ok", false))
	var bowtie := PackedVector2Array([Vector2(790, 532), Vector2(882, 623),
		Vector2(882, 532), Vector2(790, 623)])
	assert(not Routes.set_zone_polygon(original, "noGoPolygons", TABLE, bowtie).get("ok", false))
	var cover_spawn := PackedVector2Array([
		Vector2(790, 532), Vector2(882, 532), Vector2(882, 760), Vector2(790, 760)])
	assert(not Routes.set_zone_polygon(original, "noGoPolygons", TABLE, cover_spawn).get("ok", false))
	assert(not Routes.remove_zone_corner(original, "noGoPolygons", TABLE, -1).get("ok", false))
	var added: Dictionary = Routes.insert_zone_corner(original, "noGoPolygons", TABLE,
		0, Vector2(830, 532))
	assert(added.get("ok", false), str(added.get("error", "")))
	assert(_zone(added["document"], "noGoPolygons", TABLE)["pointsPx"].size() == 5)
	var removed: Dictionary = Routes.remove_zone_corner(added["document"], "noGoPolygons", TABLE, 1)
	assert(removed.get("ok", false), str(removed.get("error", "")))
	assert(_zone(removed["document"], "noGoPolygons", TABLE)["pointsPx"].size() == 4)

	# Native Godot UI. All source polygon names must be in the selector.
	var view = View.new()
	root.add_child(view)
	view._set_document(original, false)
	assert(view.zone_ids.size() == 15)
	for zone in original["noGoPolygons"]:
		var idx := -1
		for i in range(view.zone_ids.size()):
			if view.zone_ids[i]["id"] == zone["id"]:
				idx = i
				break
		assert(idx >= 0, str(zone["id"]) + " must be selectable")
		view._on_zone_selected(idx)
		assert(view.selected_zone_id == zone["id"] and view.canvas.selected_zone == zone["id"])
		assert(view.canvas.selected_zone_points().size() == zone["pointsPx"].size())
	view._set_mode("Zones")
	assert(view.canvas.show_constraints or view.current_mode == "Zones")
	# Click original table's red interior: direct map selection, no cell/waypoint needed.
	view.canvas._gui_input(_mouse(view.canvas.image_to_screen(Vector2(840, 580)), true))
	view.canvas._gui_input(_mouse(view.canvas.image_to_screen(Vector2(840, 580)), false))
	assert(view.selected_zone_id == TABLE and view.selected_zone_group == "noGoPolygons")
	var untouched := JSON.stringify(view.document)
	var corner: Vector2 = Routes._vector(_zone(view.document, "noGoPolygons", TABLE)["pointsPx"][0])
	var target := corner + Vector2(10, 10)
	view.canvas._gui_input(_mouse(view.canvas.image_to_screen(corner), true))
	var motion := InputEventMouseMotion.new()
	motion.position = view.canvas.image_to_screen(target)
	view.canvas._gui_input(motion)
	view.canvas._gui_input(_mouse(view.canvas.image_to_screen(target), false))
	assert(view.zone_proposal.get("ok", false), str(view.zone_proposal.get("error", "")))
	assert(not view.zone_apply_button.disabled)
	assert(JSON.stringify(view.document) == untouched, "Dragging a default NO-GO must only preview")
	view._apply_zone_preview()
	assert(JSON.stringify(view.document) != untouched)
	assert(view.dirty_label.text.contains("UNSAVED"))
	assert(_zone(view.document, "noGoPolygons", TABLE)["id"] == TABLE)
	assert(view.history.size() > 0)
	view._undo()
	assert(JSON.stringify(view.document) == untouched)
	view._redo()
	assert(Routes._vector(_zone(view.document, "noGoPolygons", TABLE)["pointsPx"][0]) == target)
	# Corner insertion/deletion remains an explicit reviewed draft change.
	view._on_canvas_zone_chosen("noGoPolygons", TABLE)
	view._begin_zone_insert()
	var p0: Vector2 = Routes._vector(_zone(view.document, "noGoPolygons", TABLE)["pointsPx"][0])
	var p1: Vector2 = Routes._vector(_zone(view.document, "noGoPolygons", TABLE)["pointsPx"][1])
	var midpoint := p0.lerp(p1, 0.5)
	view.canvas._gui_input(_mouse(view.canvas.image_to_screen(midpoint), true))
	view.canvas._gui_input(_mouse(view.canvas.image_to_screen(midpoint), false))
	assert(view.zone_proposal.get("ok", false), str(view.zone_proposal.get("error", "")))
	assert(_zone(view.zone_proposal["document"], "noGoPolygons", TABLE)["pointsPx"].size() == 5)
	view._apply_zone_preview()
	assert(_zone(view.document, "noGoPolygons", TABLE)["pointsPx"].size() == 5)
	view._on_canvas_zone_chosen("noGoPolygons", TABLE)
	view._on_canvas_zone_vertex(1)
	view._remove_zone_corner()
	assert(view.zone_proposal.get("ok", false))
	view._apply_zone_preview()
	assert(_zone(view.document, "noGoPolygons", TABLE)["pointsPx"].size() == 4)
	var committed := JSON.stringify(view.document)
	view._on_canvas_zone_chosen("noGoPolygons", TABLE)
	var bad_points: PackedVector2Array = Routes._polygon_points(_zone(view.document, "noGoPolygons", TABLE))
	bad_points[0] = Vector2(-8, 520)
	view._preview_zone_polygon(bad_points)
	assert(not view.zone_proposal.get("ok", false) and view.zone_apply_button.disabled)
	assert(not view.canvas.zone_edit_valid)
	view._discard_zone_edit()
	assert(JSON.stringify(view.document) == committed)
	# Native list and direct canvas must also select the default green polygons.
	view.canvas._gui_input(_mouse(view.canvas.image_to_screen(Vector2(836, 746)), true))
	view.canvas._gui_input(_mouse(view.canvas.image_to_screen(Vector2(836, 746)), false))
	assert(view.selected_zone_group == "walkablePolygons")
	view.queue_free()

	assert(Routes.save_draft(TEMP, new_wp["document"]).get("ok", false))
	var loaded: Dictionary = Routes.load_draft(TEMP)
	assert(loaded.get("ok", false), str(loaded.get("error", "")))
	assert(_zone(loaded["document"], "noGoPolygons", "QA-BEDROOM-NOGO-BED")["pointsPx"].size() == 4)
	var runtime: Dictionary = Adapter.load_source(Preview.USER, TEMP)
	assert(runtime.get("ok", false), str(runtime.get("error", "")))
	assert(runtime["contract"]["approval"] == "TEST_ONLY")
	assert(runtime["document"]["approval"] == "DRAFT_ONLY")
	assert(runtime["waypointCount"] == original["waypoints"].size() + 1)
	assert(FileAccess.get_file_as_string(SOURCE) == before_source)
	assert(FileAccess.get_file_as_string(PROJECT) == before_project)
	assert(FileAccess.get_file_as_string(CANONICAL) == before_canonical)
	assert(FileAccess.get_sha256(ART) == before_art)
	assert(DirAccess.remove_absolute(ProjectSettings.globalize_path(TEMP)) == OK)
	print("MAP-EDIT-04A original NO-GO polygon editing and runtime draft compatibility passed")
	quit()
