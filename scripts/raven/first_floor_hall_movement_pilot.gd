extends Node2D

## MAP-QA-03 isolated image-pixel movement pilot. No campaign/store/reducer access.
## The base PNG already has perspective; camera only translates/uniformly scales.
const PreviewSource = preload("res://addons/room_builder_routes/route_preview_source.gd")
const PreviewLaunch = preload("res://addons/room_builder_routes/route_preview_launch.gd")
const RouteSession = preload("res://scripts/raven/manor_route_session.gd")
const LAUNCHER := "res://scenes/raven/prototype_launcher.tscn"
const PICK_RADIUS_SCREEN := 27.0
const DRAG_THRESHOLD := 14.0

signal portal_transition_requested(portal_id: String, to_room_id: String)

@onready var art: Sprite2D = $Art
@onready var actor = $Onoe
@onready var camera: Camera2D = $Camera2D
@onready var overlay: Node2D = $QAOverlay
@onready var hotspots: Node2D = $Hotspots

var qa = PreviewSource.new()
var source_kind := PreviewSource.BASELINE
var source_path := ""
var session
var ready_for_qa := false
var portal_request_count := 0
var portal_status := "VIRTUAL QA PORTAL: not requested"
var feedback := "Tap an authored waypoint circle to walk. Drag to pan."
var _status_label: Label
var _pause_button: Button
var _foot_marker: Node2D
var _mouse_down := false
var _right_down := false
var _mouse_dragged := false
var _mouse_start := Vector2.ZERO
var _touch_down := false
var _touch_dragged := false
var _touch_start := Vector2.ZERO


func _ready() -> void:
	_build_hud()
	overlay.visible = false
	art.centered = false
	var choice := PreviewLaunch.consume()
	if not choice.get("ok", false):
		ready_for_qa = false
		feedback = "PREVIEW SELECTION REJECTED: " + str(choice.get("error", "unknown"))
		_refresh_hud()
		return
	source_kind = str(choice["kind"])
	qa = PreviewSource.new()
	ready_for_qa = qa.load_source(source_kind, str(choice.get("path", "")))
	if not ready_for_qa:
		feedback = "QA source '%s' rejected: %s" % [source_kind, qa.error_text]
		push_error(feedback)
		_refresh_hud()
		return
	if art.texture == null or art.texture.get_size() != Vector2(1672, 941):
		ready_for_qa = false
		feedback = "Approved PNG missing or dimensions changed"
		push_error(feedback)
		_refresh_hud()
		return
	session = RouteSession.new(qa.graph)
	if not session.start_at("QA-HALL-SPAWN"):
		ready_for_qa = false
		feedback = "Cannot start QA route session"
		_refresh_hud()
		return
	# Only initial placement uses an anchor coordinate. Moving feet are NEVER reset.
	actor.position = qa.waypoint_position("QA-HALL-SPAWN")
	source_path = qa.source_path
	actor.set_sprite_height(62.0)
	actor.move_speed = 130.0
	actor.segment_completed.connect(_on_segment_completed)
	camera.make_current()
	camera.position = Vector2(836, 695)
	camera.zoom = Vector2.ONE * 0.9
	_clamp_camera()
	_build_markers()
	_build_debug_geometry()
	_refresh_hud()


func request_waypoint(point_id: String) -> bool:
	if not ready_for_qa:
		return false
	var hotspot := qa.hotspot_for_waypoint(point_id)
	if hotspot.is_empty():
		feedback = "Rejected unknown QA waypoint: " + point_id
		_refresh_hud()
		return false
	var response: Dictionary = session.request_hotspot(hotspot)
	if not bool(response.get("ok", false)):
		feedback = "Rejected %s: %s" % [point_id, str(response.get("error", "unreachable"))]
		_refresh_hud()
		return false
	feedback = "Requested %s (%s)" % [point_id, str(response.get("status", ""))]
	_pump()
	_refresh_hud()
	return true


func stop_movement() -> bool:
	if not ready_for_qa:
		return false
	var result: Dictionary = session.cancel()
	feedback = "STOP queued: finishing current safe segment" if bool(result.get("finishCurrentSegment", false)) else "STOP: no further segments queued"
	_refresh_hud()
	return true


func pause_movement() -> bool:
	if not ready_for_qa or not actor.pause_segment():
		return false
	feedback = "PAUSED: physical footpoint retained"
	_refresh_hud()
	return true


func resume_movement() -> bool:
	if not ready_for_qa or not actor.resume_segment():
		return false
	feedback = "RESUMED current segment"
	_refresh_hud()
	return true


func set_debug_overlay(enabled: bool) -> void:
	overlay.visible = enabled
	_refresh_hud()


func _pump() -> void:
	if not ready_for_qa or actor.has_active_segment():
		return
	var segment: Dictionary = session.next_segment()
	if segment.is_empty():
		return
	if segment.get("arrived", false):
		_on_hotspot_arrived(str(segment.get("hotspotId", "")))
		return
	if not actor.start_segment(segment):
		# Never force position to make a rejected leg start.
		feedback = "BLOCKED: physical footpoint does not match authorized segment"
		push_warning(feedback)


func _on_segment_completed(arrived_id: String, physical_feet: Vector2) -> void:
	# The mover emits only after real contact. Do not acknowledge a caller's
	# premature assertion or correct a bad position via teleport.
	if physical_feet.distance_to(qa.waypoint_position(arrived_id)) > 0.01:
		feedback = "FAILED footpoint check for " + arrived_id
		push_error(feedback)
		_refresh_hud()
		return
	var result: Dictionary = session.finish_segment(arrived_id)
	if not result.get("ok", false):
		feedback = "Route arrival rejected: " + str(result.get("error", "unknown"))
		_refresh_hud()
		return
	if result.get("status") == "arrived":
		_on_hotspot_arrived(str(result.get("hotspotId", "")))
	else:
		feedback = "Confirmed %s (%s)" % [arrived_id, str(result.get("status", ""))]
	_pump()
	_refresh_hud()


func _on_hotspot_arrived(hotspot_id: String) -> void:
	if qa.is_portal_hotspot(hotspot_id):
		portal_request_count += 1
		portal_status = "VIRTUAL QA PORTAL: Corridor request deferred; no far-side spawn"
		feedback = portal_status
		portal_transition_requested.emit(qa.PORTAL_ID, "RM-ROOM-CORRIDOR")
	else:
		feedback = "Arrived at %s, feet %s" % [session.current_anchor(), str(actor.position)]


func _process(_delta: float) -> void:
	if not ready_for_qa:
		return
	actor.z_index = 20
	if is_instance_valid(_foot_marker):
		_foot_marker.position = actor.position
	_refresh_hud()


func _unhandled_input(event: InputEvent) -> void:
	if not ready_for_qa:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_zoom_by(1.13)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_zoom_by(1.0 / 1.13)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_right_down = event.pressed
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_mouse_down = true
				_mouse_dragged = false
				_mouse_start = event.position
			elif _mouse_down:
				_mouse_down = false
				if not _mouse_dragged:
					_pick_point(event.position)
	elif event is InputEventMouseMotion:
		if _right_down or _mouse_down:
			if _right_down or event.position.distance_to(_mouse_start) > DRAG_THRESHOLD:
				_mouse_dragged = true
				_pan(event.relative)
	elif event is InputEventScreenTouch and event.index == 0:
		if event.pressed:
			_touch_down = true
			_touch_dragged = false
			_touch_start = event.position
		elif _touch_down:
			_touch_down = false
			if not _touch_dragged:
				_pick_point(event.position)
	elif event is InputEventScreenDrag and event.index == 0 and _touch_down:
		if event.position.distance_to(_touch_start) > DRAG_THRESHOLD:
			_touch_dragged = true
			_pan(event.relative)
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_SPACE:
				if actor.is_paused():
					resume_movement()
				else:
					pause_movement()
			KEY_F3:
				set_debug_overlay(not overlay.visible)
			KEY_S:
				stop_movement()


func _pick_point(screen_point: Vector2) -> void:
	# Godot camera's inverse canvas transform: pointer -> exact source pixels.
	var in_image: Vector2 = get_viewport().get_canvas_transform().affine_inverse() * screen_point
	var nearest := ""
	var distance := PICK_RADIUS_SCREEN / camera.zoom.x
	for id in qa.waypoint_ids():
		var d: float = in_image.distance_to(qa.waypoint_position(id))
		if d < distance:
			distance = d
			nearest = id
	if not nearest.is_empty():
		request_waypoint(nearest)


func _pan(screen_delta: Vector2) -> void:
	camera.position -= screen_delta / camera.zoom.x
	_clamp_camera()


func _zoom_by(factor: float) -> void:
	var value := clampf(camera.zoom.x * factor, 0.45, 2.5)
	camera.zoom = Vector2.ONE * value
	_clamp_camera()


func _clamp_camera() -> void:
	var half := get_viewport_rect().size * 0.5 / camera.zoom.x
	camera.position.x = 836.0 if half.x >= 836.0 else clampf(camera.position.x, half.x, 1672.0 - half.x)
	camera.position.y = 470.5 if half.y >= 470.5 else clampf(camera.position.y, half.y, 941.0 - half.y)


func _build_markers() -> void:
	for id in qa.waypoint_ids():
		var marker := Line2D.new()
		marker.name = id
		marker.width = 2.5
		marker.default_color = Color("#f5e7bd") if id != "QA-HALL-PORTAL-APPROACH" else Color("#ff7ad4")
		marker.position = qa.waypoint_position(id)
		var points := PackedVector2Array()
		for i in range(17):
			var angle := float(i) * TAU / 16.0
			points.append(Vector2(cos(angle), sin(angle)) * 9.0)
		marker.points = points
		hotspots.add_child(marker)
	if qa.waypoint_ids().has("QA-HALL-PORTAL-APPROACH"):
		var portal_caption := Label.new()
		portal_caption.text = "VIRTUAL QA PORTAL"
		portal_caption.position = qa.waypoint_position("QA-HALL-PORTAL-APPROACH") + Vector2(12, 8)
		portal_caption.add_theme_font_size_override("font_size", 12)
		portal_caption.add_theme_color_override("font_color", Color("#ffb2e5"))
		hotspots.add_child(portal_caption)


func _build_debug_geometry() -> void:
	for region in qa.data["walkablePolygons"]:
		_polygon(region["pointsPx"], Color(0.20, 0.88, 0.40, 0.19))
	for region in qa.data["noGoPolygons"]:
		_polygon(region["pointsPx"], Color(0.94, 0.22, 0.27, 0.21))
	for edge in qa.graph.active_edges():
		var line := Line2D.new()
		line.width = 2.0
		line.default_color = Color("#efa45b") if bool(edge.get("provisional", false)) else Color(0.27, 0.88, 1.0, 0.9)
		line.points = PackedVector2Array([
			qa.graph.position(str(edge["from"])),
			qa.graph.position(str(edge["to"]))
		])
		overlay.add_child(line)
		# Authored intermediate anchors are actual playable feet targets.
		if str(edge["to"]).contains("-STEP-"):
			var step := Line2D.new()
			step.width = 2.0
			step.default_color = Color("#f9d47d")
			step.points = PackedVector2Array([Vector2(-3, 0), Vector2(3, 0)])
			step.position = qa.graph.position(str(edge["to"]))
			overlay.add_child(step)
	for id in qa.waypoint_ids():
		var label := Label.new()
		label.text = id
		label.add_theme_font_size_override("font_size", 11)
		label.add_theme_color_override("font_color", Color("#fcf4c7"))
		label.position = qa.waypoint_position(id) + Vector2(11, -24)
		overlay.add_child(label)
	_foot_marker = Node2D.new()
	var horizontal := Line2D.new()
	horizontal.width = 2.0
	horizontal.default_color = Color("#fff8ed")
	horizontal.points = PackedVector2Array([Vector2(-7, 0), Vector2(7, 0)])
	_foot_marker.add_child(horizontal)
	var vertical := Line2D.new()
	vertical.width = 2.0
	vertical.default_color = Color("#fff8ed")
	vertical.points = PackedVector2Array([Vector2(0, -7), Vector2(0, 7)])
	_foot_marker.add_child(vertical)
	overlay.add_child(_foot_marker)
	_foot_marker.position = actor.position


func _polygon(values: Array, color: Color) -> void:
	var polygon := Polygon2D.new()
	var points := PackedVector2Array()
	for xy in values:
		points.append(Vector2(float(xy[0]), float(xy[1])))
	polygon.polygon = points
	polygon.color = color
	overlay.add_child(polygon)


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "QaHud"
	add_child(layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(8, 8)
	panel.custom_minimum_size = Vector2(328, 0)
	layer.add_child(panel)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)
	var heading := Label.new()
	heading.text = "MAP-QA-03 · FIRST FLOOR HALL"
	heading.add_theme_color_override("font_color", Color("#e7cea1"))
	vbox.add_child(heading)
	var buttons := HBoxContainer.new()
	vbox.add_child(buttons)
	buttons.add_child(_button("← Lab", func(): get_tree().change_scene_to_file(LAUNCHER)))
	_pause_button = _button("Pause", _toggle_pause)
	buttons.add_child(_pause_button)
	buttons.add_child(_button("Stop", stop_movement))
	buttons.add_child(_button("QA", func(): set_debug_overlay(not overlay.visible)))
	buttons.add_child(_button("−", func(): _zoom_by(1.0 / 1.2)))
	buttons.add_child(_button("+", func(): _zoom_by(1.2)))
	var sources := HFlowContainer.new()
	vbox.add_child(sources)
	sources.add_child(_button("Original", _change_source.bind(PreviewSource.BASELINE)))
	sources.add_child(_button("Saved user", _change_source.bind(PreviewSource.USER)))
	sources.add_child(_button("Project export", _change_source.bind(PreviewSource.PROJECT)))
	_status_label = Label.new()
	_status_label.custom_minimum_size = Vector2(318, 0)
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(_status_label)
	var help := Label.new()
	help.text = "Tap circles · Drag pan · Wheel / ± zoom · Space pause · S stop after leg · F3 QA"
	help.add_theme_font_size_override("font_size", 10)
	vbox.add_child(help)


func _button(title: String, callback: Callable) -> Button:
	var result := Button.new()
	result.text = title
	result.pressed.connect(callback)
	return result


func _change_source(kind: String) -> void:
	# A source change requires a fresh QA scene: no mid-leg graph switch,
	# no interpolation from a stale waypoint and no character teleport.
	var probe = PreviewSource.new()
	if not probe.load_source(kind):
		feedback = "Source %s rejected: %s (current preview unchanged)" % [kind, probe.error_text]
		_refresh_hud()
		return
	var ticket := PreviewLaunch.stage(kind)
	if not ticket.get("ok", false):
		feedback = "Source selection failed: " + str(ticket.get("error", "unknown"))
		_refresh_hud()
		return
	get_tree().reload_current_scene()


func _toggle_pause() -> void:
	if actor.is_paused():
		resume_movement()
	else:
		pause_movement()


func _refresh_hud() -> void:
	if not is_instance_valid(_status_label):
		return
	var motion := "PAUSED" if actor.is_paused() else ("MOVING" if actor.has_active_segment() else "IDLE")
	_pause_button.text = "Resume" if actor.is_paused() else "Pause"
	if not ready_for_qa:
		_status_label.text = "SOURCE: %s\n%s" % [source_kind, feedback]
		return
	var provisional_info := "%d PROVISIONAL edges (straight QA)" % qa.provisional_routes.size() if not qa.provisional_routes.is_empty() else "All edges explicit / original baseline"
	_status_label.text = "SOURCE: %s · %s\n%s | confirmed: %s\nTarget: %s | feet: %s\nPortal: %s\n%s\n%s" % [
		source_kind, source_path.get_file(), motion, session.current_anchor(), session.pending_hotspot(),
		str(actor.position.round()), portal_status, provisional_info, feedback
	]
