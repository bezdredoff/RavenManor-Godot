extends Node2D
## MAP-QA-07B playable QA: no production scene, save, or free tap-to-move.
## Transitions are EXPLICIT TEST_ONLY fixtures over separate authored islands.
const Adapter = preload("res://scripts/raven/first_floor_integrated_draft_adapter.gd")
const Routes = preload("res://addons/room_builder_routes/route_document.gd")
const Preview = preload("res://addons/room_builder_routes/route_preview_source.gd")
const HostScene = preload("res://scenes/raven/tests/first_floor_multi_room_host.tscn")
const HALL := "RM-ROOM-HALL"
const PICK_RADIUS := 28.0

var host
var _loaded: Dictionary = {}
var _source_kind := Preview.PROJECT
var _source_path := ""
var _debug := false
var _manual_camera := false
var _destination_ids: Array[String] = []
var _room_ids: Array[String] = []
var _destination_picker: OptionButton
var _room_picker: OptionButton
var _status: Label
var _header: Label


func _ready() -> void:
	_make_ui()
	load_source(Preview.PROJECT)


func load_source(kind: String, path: String = "", start_room: String = HALL) -> bool:
	if is_instance_valid(host):
		if host.actor.has_active_segment() or not host.controller.pending_transition().is_empty() \
				or not host.controller.ready_transition().is_empty() or host.controller.in_safe_hold():
			_message("RELOAD REJECTED: moving, pending handoff or safe hold")
			return false
		var graph = host.current_graph()
		var anchor: String = host.controller.confirmed_anchor()
		if graph != null and str(graph.anchor(anchor).get("kind", "")) != "safe":
			_message("RELOAD REJECTED: move to a safe anchor first")
			return false
	var candidate: Dictionary = Adapter.load_source(kind, path)
	if not bool(candidate.get("ok", false)):
		_message("INVALID DRAFT · NO FALLBACK: " + str(candidate.get("error", "unknown")))
		return false
	return _install(candidate, start_room)


func restart_island(room: String) -> bool:
	# Explicit QA-only restart, not a door or an inferred physical connection.
	if _loaded.is_empty():
		return false
	if not _loaded.get("starts", {}).has(room):
		_message("Unconnected/unsupported authored room: " + room)
		return false
	if is_instance_valid(host) and (host.actor.has_active_segment() \
			or not host.controller.pending_transition().is_empty() \
			or not host.controller.ready_transition().is_empty() \
			or host.controller.in_safe_hold()):
		_message("Island restart refused during movement or handoff")
		return false
	return _install(_loaded, room)


func _install(candidate: Dictionary, start_room: String) -> bool:
	var starts: Dictionary = candidate.get("starts", {})
	if not starts.has(start_room):
		_message("No safe starting anchor in " + start_room)
		return false
	var next_host = HostScene.instantiate()
	add_child(next_host)
	if not next_host.configure_host(candidate["contract"], candidate["visuals"],
			start_room, str(starts[start_room])):
		var error: String = next_host.last_error
		next_host.queue_free()
		_message("Host configuration rejected: " + error)
		return false
	var previous = host
	host = next_host
	if is_instance_valid(previous):
		previous.queue_free()
	_loaded = candidate
	_source_kind = str(candidate["sourceKind"])
	_source_path = str(candidate["sourcePath"])
	_manual_camera = false
	host.room_changed.connect(_on_room_changed)
	host.movement_rejected.connect(_on_rejected)
	if _debug:
		host.toggle_routes()
	_refresh_destinations()
	_refresh_rooms()
	queue_redraw()
	_message("Loaded persisted " + _source_kind + "; TEST_ONLY portals; all image-pixel routes DRAFT_ONLY")
	return true


func walk_waypoint(id: String) -> Dictionary:
	if not is_instance_valid(host) or not host.ready_for_test:
		return {"ok":false, "error":"host-not-ready"}
	if not host.current_graph().has_anchor(id):
		return {"ok":false, "error":"waypoint-outside-active-room"}
	var hotspot: String = str(host.current_graph().anchor(id).get("hotspotId", ""))
	if hotspot.is_empty():
		return {"ok":false, "error":"not-a-waypoint-hotspot"}
	var result: Dictionary = host.request_hotspot(hotspot)
	_message("Walk " + id + ": " + str(result.get("status", result.get("error", "unknown"))))
	return result


func transition(id: String) -> Dictionary:
	if not is_instance_valid(host):
		return {"ok":false, "error":"host-not-ready"}
	var result: Dictionary = host.request_transition(id)
	_message("TEST_ONLY " + id + ": " + str(result.get("status", result.get("error", "?"))))
	return result


func toggle_debug() -> void:
	_debug = not _debug
	if is_instance_valid(host):
		host.toggle_routes()
	queue_redraw()
	_message("Debug overlay " + ("ON" if _debug else "OFF"))


func _draw() -> void:
	if not _debug or not is_instance_valid(host) or _loaded.is_empty():
		return
	var doc: Dictionary = _loaded.get("document", {})
	if doc.is_empty():
		return
	var current: String = host.active_room_id
	var font: Font = ThemeDB.fallback_font
	for region in doc.get("walkablePolygons", []):
		var points := _polygon(region)
		if points.size() > 2:
			draw_colored_polygon(points, Color(0.22, 0.9, 0.48, 0.08))
			_outline(points, Color(0.22, 0.9, 0.48, 0.45))
	for region in doc.get("noGoPolygons", []):
		var points := _polygon(region)
		if points.size() > 2:
			draw_colored_polygon(points, Color(1.0, 0.22, 0.24, 0.13))
			_outline(points, Color(1.0, 0.22, 0.24, 0.7))
	for cell in doc.get("blockedCells", []):
		var pt: Vector2 = Routes.cell_to_pixel(str(cell), doc)
		if pt.is_finite():
			var grid: Dictionary = doc["grid"]
			draw_rect(Rect2(pt - Vector2(float(grid["cellWidth"]), float(grid["cellHeight"])) * 0.5,
				Vector2(float(grid["cellWidth"]), float(grid["cellHeight"]))),
				Color(1, 0.15, 0.2, 0.5), true)
	var owned: Dictionary = {}
	for wp in doc.get("waypoints", []):
		var id := str(wp["id"])
		var room := str(wp.get("roomId", ""))
		if room.is_empty() and id.begins_with("QA-HALL-"):
			room = HALL
		owned[id] = room
	for route in doc.get("routes", []):
		if str(owned.get(str(route["from"]), "")) != current:
			continue
		var points: PackedVector2Array = Routes.route_points(route, doc)
		var color := Color("#ffbf75") if bool(route.get("provisional", true)) else Color("#69e9f1")
		for i in range(1, points.size()):
			draw_line(points[i - 1], points[i], color, 3.0)
	for wp in doc.get("waypoints", []):
		if str(owned.get(str(wp["id"]), "")) != current:
			continue
		var p := Routes._vector(wp["pointPx"])
		draw_circle(p, 6.0, Color("#f8e8ac"))
		draw_string(font, p + Vector2(10, -8), str(wp["id"]), HORIZONTAL_ALIGNMENT_LEFT,
			-1, 12, Color("#fef6e6"))


func _polygon(region: Dictionary) -> PackedVector2Array:
	var points := PackedVector2Array()
	for raw in region.get("pointsPx", []):
		points.append(Routes._vector(raw))
	return points


func _outline(points: PackedVector2Array, color: Color) -> void:
	for i in range(points.size()):
		draw_line(points[i], points[(i + 1) % points.size()], color, 1.5)


func _unhandled_input(event: InputEvent) -> void:
	if not is_instance_valid(host):
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_F3: toggle_debug()
			KEY_SPACE: _pause()
			KEY_R: load_source(_source_kind, _source_path)
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom(1.12)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom(1.0 / 1.12)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			var selected := ""
			var distance: float = PICK_RADIUS / host.camera.zoom.x
			var point: Vector2 = get_global_mouse_position()
			for id in host.current_graph().anchors():
				var anchor: Dictionary = host.current_graph().anchor(str(id))
				if not str(anchor.get("hotspotId", "")).is_empty():
					var d: float = point.distance_to(host.current_graph().position(str(id)))
					if d < distance:
						distance = d
						selected = str(id)
			if not selected.is_empty():
				walk_waypoint(selected)
	if event is InputEventMouseMotion and _manual_camera and \
			(event.button_mask & MOUSE_BUTTON_MASK_MIDDLE) != 0:
		host.camera.position -= event.relative / host.camera.zoom


func _zoom(factor: float) -> void:
	host.camera.zoom = Vector2.ONE * clampf(host.camera.zoom.x * factor, 0.45, 2.6)


func _toggle_follow() -> void:
	_manual_camera = not _manual_camera
	host.set_process(not _manual_camera)
	if not _manual_camera:
		host.camera.position = host.actor.position
	_message("Middle-drag pan" if _manual_camera else "Follow Onoe")


func _pause() -> void:
	if host.actor.is_paused():
		_message("Resume: " + str(host.resume_movement()))
	else:
		_message("Pause: " + str(host.pause_movement()))


func _on_room_changed(_event: Dictionary) -> void:
	_refresh_destinations()
	queue_redraw()
	_message("Room changed after physical approach; TEST_ONLY handoff")


func _on_rejected(reason: String) -> void:
	_message("REJECTED: " + reason)


func _refresh_destinations() -> void:
	if not is_instance_valid(_destination_picker) or not is_instance_valid(host):
		return
	_destination_picker.clear()
	_destination_ids.clear()
	for id in host.current_graph().anchors():
		var anchor: Dictionary = host.current_graph().anchor(str(id))
		if not str(anchor.get("hotspotId", "")).is_empty():
			_destination_ids.append(str(id))
			_destination_picker.add_item(str(id))


func _refresh_rooms() -> void:
	if not is_instance_valid(_room_picker):
		return
	_room_picker.clear()
	_room_ids.clear()
	for room in _loaded.get("starts", {}):
		_room_ids.append(str(room))
		_room_picker.add_item(str(room))


func _picked_destination() -> void:
	var index := _destination_picker.selected
	if index >= 0 and index < _destination_ids.size():
		walk_waypoint(_destination_ids[index])


func _picked_room() -> void:
	var index := _room_picker.selected
	if index >= 0 and index < _room_ids.size():
		restart_island(_room_ids[index])


func _set_gate() -> void:
	if not is_instance_valid(host):
		return
	var id := "QA-07B-DOOR-HC"
	var next := "gated" if host.controller.door_status(id) == "open" else "open"
	_message("TEST_ONLY gate " + next + ": " + str(host.test_gate(id, next)))


func _message(message: String) -> void:
	if not is_instance_valid(_status) or not is_instance_valid(_header):
		return
	var room: String = host.active_room_id if is_instance_valid(host) else "NONE"
	var anchor: String = host.controller.confirmed_anchor() if is_instance_valid(host) else "NONE"
	_header.text = "MAP-QA-07B · %s · DRAFT_ONLY / TEST_ONLY" % room
	_status.text = "%s\n%s · %s · anchor %s · %d WP / %d routes · unresolved %d" % [
		message, _source_kind, _source_path, anchor,
		int(_loaded.get("waypointCount", 0)), int(_loaded.get("routeCount", 0)),
		int(_loaded.get("unresolvedCount", 0))]


func _make_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_left = 6
	panel.offset_right = -6
	panel.offset_top = -212
	panel.offset_bottom = -6
	layer.add_child(panel)
	var rows := VBoxContainer.new()
	panel.add_child(rows)
	_header = Label.new()
	_header.add_theme_font_size_override("font_size", 14)
	rows.add_child(_header)
	var sources := HBoxContainer.new()
	rows.add_child(sources)
	_button(sources, "Project draft", func(): load_source(Preview.PROJECT))
	_button(sources, "Saved user", func(): load_source(Preview.USER))
	_button(sources, "Original Hall", func(): load_source(Preview.BASELINE))
	_button(sources, "Reload", func(): load_source(_source_kind, _source_path))
	var targets := HBoxContainer.new()
	rows.add_child(targets)
	_destination_picker = OptionButton.new()
	_destination_picker.custom_minimum_size.x = 210
	targets.add_child(_destination_picker)
	_button(targets, "Walk waypoint", _picked_destination)
	_room_picker = OptionButton.new()
	_room_picker.custom_minimum_size.x = 200
	targets.add_child(_room_picker)
	_button(targets, "Restart island (QA)", _picked_room)
	var doors := HBoxContainer.new()
	rows.add_child(doors)
	_button(doors, "Hall → Corridor", func(): transition("QA-07B-TR-HC"))
	_button(doors, "Corridor → Bedroom", func(): transition("QA-07B-TR-CB"))
	_button(doors, "Bedroom → Corridor", func(): transition("QA-07B-TR-BC"))
	_button(doors, "Corridor → Hall", func(): transition("QA-07B-TR-CH"))
	_button(doors, "Locked", func(): transition("QA-07B-TR-LOCKED"))
	var actions := HBoxContainer.new()
	rows.add_child(actions)
	_button(actions, "Gate", _set_gate)
	_button(actions, "Pause", _pause)
	_button(actions, "Cancel", func(): _message(str(host.cancel_request())))
	_button(actions, "F3 Overlay", toggle_debug)
	_button(actions, "Pan / Follow", _toggle_follow)
	_button(actions, "+", func(): _zoom(1.12))
	_button(actions, "−", func(): _zoom(1.0 / 1.12))
	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.add_theme_font_size_override("font_size", 11)
	rows.add_child(_status)


func _button(parent: Node, label: String, action: Callable) -> void:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size.y = 26.0
	button.add_theme_font_size_override("font_size", 11)
	button.pressed.connect(action)
	parent.add_child(button)
