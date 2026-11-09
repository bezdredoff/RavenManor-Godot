extends SceneTree
## MAP-EDIT-04: real stroke conversion, native mouse drag, document commit and 07B bridge.
const Routes = preload("res://addons/room_builder_routes/route_document.gd")
const Freehand = preload("res://addons/room_builder_routes/route_freehand.gd")
const View = preload("res://addons/room_builder_routes/route_editor_view.gd")
const Adapter = preload("res://scripts/raven/first_floor_integrated_draft_adapter.gd")
const Preview = preload("res://addons/room_builder_routes/route_preview_source.gd")
const ART := "res://a_detailed_top_down_isometric_game_map_illustratio.png"
const SOURCE := "res://assets/raven/map/qa/first_floor_hall_pilot.v1.json"
const PROJECT := "res://assets/raven/map/qa/drafts/hall_routes_draft.v1.json"
const CANONICAL := "res://data/raven/manor_greybox_graph.json"
const TEMP := "user://room_builder_routes/map_edit_04_freehand_smoke.json"
const HALL := "RM-ROOM-HALL"
const CORRIDOR := "RM-ROOM-CORRIDOR"
const A := Vector2(112, 112)
const B := Vector2(400, 112)
const C := Vector2(400, 272)


func _initialize() -> void:
	call_deferred("_run")


func _fixture() -> Dictionary:
	var source: Dictionary = Routes.import_hall()
	assert(source.get("ok", false), str(source.get("error", "")))
	var zone: Dictionary = Routes.add_zone_rectangle(source["document"], "walkablePolygons",
		Vector2(64, 64), Vector2(480, 320), HALL)
	assert(zone.get("ok", false), str(zone.get("error", "")))
	var doc: Dictionary = zone["document"]
	var ids: Array = []
	for point in [A, B, C]:
		var added: Dictionary = Routes.add_waypoint(doc, point, "Freehand test point", HALL)
		assert(added.get("ok", false), str(added.get("error", "")))
		doc = added["document"]
		ids.append(str(added["id"]))
	return {"doc": doc, "a": ids[0], "b": ids[1], "c": ids[2]}


func _assert_orthogonal(candidate: Dictionary) -> void:
	assert(candidate.get("ok", false), str(candidate.get("error", "")))
	var cells: Array = candidate["cells"]
	assert(cells.size() >= 2)
	for i in range(1, cells.size()):
		var a: Dictionary = Routes.parse_cell(str(cells[i - 1]))
		var b: Dictionary = Routes.parse_cell(str(cells[i]))
		assert(absi(int(a.col) - int(b.col)) + absi(int(a.row) - int(b.row)) == 1,
			"Freehand output must have single orthogonal steps")
	assert(candidate["document"]["approval"] == "DRAFT_ONLY")
	assert(Routes.validate(candidate["document"]).ok)


func _mouse(button: int, pressed: bool, point: Vector2) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = button
	event.pressed = pressed
	event.position = point
	return event


func _run() -> void:
	var source_before := FileAccess.get_file_as_string(SOURCE)
	var project_before := FileAccess.get_file_as_string(PROJECT)
	var canonical_before := FileAccess.get_file_as_string(CANONICAL)
	var art_sha := FileAccess.get_sha256(ART)
	assert(not source_before.is_empty() and not project_before.is_empty() and not canonical_before.is_empty())
	var f := _fixture()
	var doc: Dictionary = f["doc"]
	var a: String = f["a"]
	var b: String = f["b"]
	var c: String = f["c"]
	var original_json := JSON.stringify(doc)

	var horizontal: Dictionary = Freehand.convert(doc, HALL, a, b,
		PackedVector2Array([A, Vector2(240, 112), B]))
	_assert_orthogonal(horizontal)
	assert(horizontal["cells"][0] == Routes.pixel_to_cell(A, doc))
	assert(horizontal["cells"].back() == Routes.pixel_to_cell(B, doc))
	assert(horizontal["cells"].size() == 10)
	assert(JSON.stringify(doc) == original_json, "Proposal must be read-only")
	var vertical: Dictionary = Freehand.convert(doc, HALL, b, c,
		PackedVector2Array([B, Vector2(400, 208), C]))
	_assert_orthogonal(vertical)
	var bent: Dictionary = Freehand.convert(doc, HALL, a, c,
		PackedVector2Array([A, B, C]))
	_assert_orthogonal(bent)
	assert(bent["cells"].has(Routes.pixel_to_cell(B, doc)))
	var turns: Dictionary = Freehand.convert(doc, HALL, a, b,
		PackedVector2Array([A, Vector2(240, 112), Vector2(240, 272), C, B]))
	_assert_orthogonal(turns)
	var noisy: Dictionary = Freehand.convert(doc, HALL, a, b,
		PackedVector2Array([A, Vector2(112.5, 112.2), Vector2(145, 111.8),
			Vector2(176, 112), Vector2(241, 112.2), B]), 4.0)
	_assert_orthogonal(noisy)
	var sparse: Dictionary = Freehand.convert(doc, HALL, a, c,
		PackedVector2Array([A, C]))
	_assert_orthogonal(sparse)
	assert(sparse["cells"].size() > 2)
	var repeats: Dictionary = Freehand.convert(doc, HALL, a, b,
		PackedVector2Array([A, A, Vector2(113, 112), Vector2(116, 112), B]))
	_assert_orthogonal(repeats)
	assert(not Freehand.convert(doc, HALL, a, b,
		PackedVector2Array([A, Vector2(176, 112), Vector2(144, 112), B])).ok,
		"Actual backtracking requires owner review; do not silently trim the stroke")

	assert(not Freehand.convert(doc, HALL, "unknown", b, PackedVector2Array([A, B])).ok)
	assert(not Freehand.convert(doc, HALL, a, a, PackedVector2Array([A, A])).ok)
	assert(not Freehand.convert(doc, HALL, a, b, PackedVector2Array([Vector2(240, 112), B])).ok)
	assert(not Freehand.convert(doc, HALL, a, b, PackedVector2Array([A, Vector2(240, 272)])).ok)
	assert(not Freehand.convert(doc, HALL, a, b, PackedVector2Array([A, Vector2(-2, 112), B])).ok)
	assert(not Freehand.convert(doc, HALL, a, b, PackedVector2Array([A, Vector2(40, 112), B])).ok,
		"Stroke outside all WALKABLE regions must fail")
	var cross_room: Dictionary = Routes.add_waypoint(doc, Vector2(112, 208), "Other room", CORRIDOR)
	assert(cross_room.ok)
	assert(not Freehand.convert(cross_room["document"], HALL, a, str(cross_room["id"]),
		PackedVector2Array([A, Vector2(112, 208)])).ok)

	var wrong_owner := Routes.add_zone_rectangle(doc, "walkablePolygons",
		Vector2(220, 90), Vector2(252, 142), CORRIDOR)
	assert(wrong_owner.ok)
	var crossed_room := Freehand.convert(wrong_owner["document"], HALL, a, b,
		PackedVector2Array([A, B]))
	assert(not crossed_room.ok and str(crossed_room["error"]).contains("CORRIDOR"))
	# Native-added zones have explicit room ownership; original calls with no
	# ownership remain readable but cannot grant an implicit room shortcut.
	var unowned := Routes.add_zone_rectangle(doc, "walkablePolygons",
		Vector2(450, 90), Vector2(470, 140))
	assert(unowned.ok)
	assert(not unowned["document"]["walkablePolygons"].back().has("roomId"))

	var with_nogo: Dictionary = Routes.add_zone_rectangle(doc, "noGoPolygons",
		Vector2(220, 90), Vector2(252, 142))
	assert(with_nogo.ok, str(with_nogo.get("error", "")))
	var obstructed: Dictionary = Freehand.convert(with_nogo["document"], HALL, a, b,
		PackedVector2Array([A, B]))
	assert(not obstructed.ok and str(obstructed["error"]).contains("obstacle"))
	assert(obstructed["invalidAt"].is_finite())
	var with_block: Dictionary = Routes.set_blocked(doc, "H4", true)
	assert(with_block.ok, str(with_block.get("error", "")))
	assert(not Freehand.convert(with_block["document"], HALL, a, b,
		PackedVector2Array([A, B])).ok)

	var one_way: Dictionary = Routes.set_route_direction(horizontal["document"], str(horizontal["routeId"]), false)
	assert(one_way.ok)
	var redrawn: Dictionary = Freehand.convert(one_way["document"], HALL, a, b,
		PackedVector2Array([A, Vector2(240, 112), B]), 2.0, str(horizontal["routeId"]))
	_assert_orthogonal(redrawn)
	assert(redrawn["routeId"] == horizontal["routeId"])
	assert(redrawn["document"]["routes"].back()["id"] == horizontal["routeId"])
	assert(not redrawn["document"]["routes"].back()["bidirectional"])
	assert(not redrawn["document"]["routes"].back()["provisional"])
	assert(not Freehand.convert(one_way["document"], HALL, a, c,
		PackedVector2Array([A, C]), 4.0, str(horizontal["routeId"])).ok)

	# Actual Godot native Control: simulate mouse-press, movement, release, then
	# explicit Apply. Headless SceneTree input is not substituted for a commit.
	var view = View.new()
	root.add_child(view)
	view._set_document(doc, false)
	view._change_room(HALL)
	view._set_mode("Freehand")
	assert(view.mode_picker.item_count == 9)
	assert(view.freehand_bar.visible and view.freehand_apply_button.disabled)
	assert(view.find_child("MainToolbar", true, false).get_combined_minimum_size().y < 65.0)
	view._begin_new_freehand()
	for i in range(view.route_from.item_count):
		if view.route_from.get_item_text(i) == a:
			view.route_from.select(i)
		if view.route_to.get_item_text(i) == b:
			view.route_to.select(i)
	var untouched := JSON.stringify(view.document)
	view.canvas._gui_input(_mouse(MOUSE_BUTTON_LEFT, true, view.canvas.image_to_screen(A)))
	var moving := InputEventMouseMotion.new()
	moving.position = view.canvas.image_to_screen(Vector2(240, 112))
	view.canvas._gui_input(moving)
	view.canvas._gui_input(_mouse(MOUSE_BUTTON_LEFT, false, view.canvas.image_to_screen(B)))
	assert(view.freehand_proposal.get("ok", false), str(view.freehand_proposal.get("error", "")))
	assert(not view.freehand_apply_button.disabled)
	assert(JSON.stringify(view.document) == untouched, "Mouse release cannot commit")
	view._apply_freehand()
	assert(view.document["routes"].size() == doc["routes"].size() + 1)
	assert(view.dirty_label.text.contains("UNSAVED"))
	assert(not view.document["routes"].back()["provisional"])
	assert(JSON.stringify(view.document) != untouched)
	var new_id: String = str(view.selected_route)
	view._undo()
	assert(JSON.stringify(view.document) == untouched)
	view._redo()
	assert(str(view.document["routes"].back()["id"]) == new_id)
	# Rejected preview followed by discard must leave document byte-identical.
	var committed_json := JSON.stringify(view.document)
	view._on_freehand_finished(PackedVector2Array([A, Vector2(-1, 112), B]))
	assert(not view.freehand_proposal.get("ok", false) and view.freehand_apply_button.disabled)
	view._discard_freehand()
	assert(JSON.stringify(view.document) == committed_json)
	view._redraw_selected_freehand()
	assert(view.current_mode == "Freehand" and view.selected_route == new_id)
	view._on_freehand_finished(PackedVector2Array([A, Vector2(240, 112), B]))
	assert(view.freehand_proposal.ok)
	view._apply_freehand()
	assert(view.selected_route == new_id and view.document["routes"].back()["id"] == new_id)
	assert(Routes.save_draft(TEMP, view.document).ok)
	var loaded := Routes.load_draft(TEMP)
	assert(loaded.ok and loaded.document["routes"].back()["id"] == new_id)
	assert(JSON.stringify(loaded.document) == JSON.stringify(JSON.parse_string(JSON.stringify(view.document))))
	var runtime: Dictionary = Adapter.load_source(Preview.USER, TEMP)
	assert(runtime.get("ok", false), str(runtime.get("error", "")))
	assert(runtime["routeCount"] == doc["routes"].size() + 1)
	assert(runtime["document"]["approval"] == "DRAFT_ONLY")
	assert(runtime["contract"]["approval"] == "TEST_ONLY")
	var preview: Dictionary = Routes.route_preview(view.document, a, b)
	assert(preview.get("ok", false), str(preview.get("error", "")))
	assert(preview["points"].size() >= 2)
	view.queue_free()

	assert(FileAccess.get_file_as_string(SOURCE) == source_before)
	assert(FileAccess.get_file_as_string(PROJECT) == project_before)
	assert(FileAccess.get_file_as_string(CANONICAL) == canonical_before)
	assert(FileAccess.get_sha256(ART) == art_sha)
	assert(DirAccess.remove_absolute(ProjectSettings.globalize_path(TEMP)) == OK)
	print("MAP-EDIT-04 freehand routes and MAP-QA-07B integration smoke passed")
	quit()
