extends Node2D
## Hall Tea physical-footpoint review ONLY; not a production scene or save authority.
## Renders the accepted bitmap/HC-CB foreground, approved Evelyn, RouteSession and
## an opt-in in-memory DRAFT_ONLY delta from MAP-TEA-01.
const Candidate = preload("res://scripts/raven/map_tea_01_candidate.gd")
const Graph = preload("res://scripts/raven/manor_navigation_graph.gd")
const RouteSession = preload("res://scripts/raven/manor_route_session.gd")
const DoorArt = preload("res://scripts/raven/map_prod_01_hc_cb_art.gd")
const Evelyn = preload("res://scenes/raven/actors/evelyn_walker.tscn")
const ART = preload("res://a_detailed_top_down_isometric_game_map_illustratio.png")
const OFFSET := Vector2(128, 128)
const HALL := "RM-ROOM-HALL"
const TARGET := "RM-HS-TEA-TABLE"
const ARRIVAL := "RM-NAV-HALL-TEA"

var source: Dictionary = {}
var graph
var session
var actor: Node2D
var camera: Camera2D
var ui_layer: CanvasLayer
var status_label: Label
var ready_for_review := false
var overlay_enabled := true
var arrival_acknowledged := false

func _ready() -> void:
	source = Candidate.inspect()
	if not bool(source.get("ok", false)):
		push_error("MAP-TEA-01: " + str(source.get("error", "invalid candidate")))
		return
	var background := Sprite2D.new()
	background.texture = ART
	background.centered = false
	background.position = OFFSET
	background.z_index = -20
	add_child(background)
	var back = DoorArt.new()
	back.z_index = 2
	back.position = OFFSET
	add_child(back)
	actor = Evelyn.instantiate()
	actor.z_index = 8
	add_child(actor)
	var foreground = DoorArt.new()
	foreground.foreground = true
	foreground.z_index = 12
	foreground.position = OFFSET
	add_child(foreground)
	camera = Camera2D.new()
	camera.position = Vector2(970, 782)
	camera.zoom = Vector2.ONE * 1.45
	camera.position_smoothing_enabled = false
	add_child(camera)
	camera.make_current()
	graph = Graph.new()
	graph.rebuild({}, source["plan"])
	actor.set_sprite_height(62.0)
	actor.move_speed = 130.0
	actor.segment_completed.connect(_on_segment_completed)
	_make_ui()
	if not reset_to("RM-NAV-HALL-SPAWN"):
		push_error("MAP-TEA-01: unable to locate Hall safe spawn")
		return
	ready_for_review = true
	queue_redraw()

func reset_to(anchor_id: String) -> bool:
	if graph == null or not graph.has_anchor(anchor_id) or actor.has_active_segment():
		return false
	if str(graph.anchor(anchor_id).get("roomId", "")) != HALL or anchor_id == ARRIVAL:
		return false
	session = RouteSession.new(graph)
	if not session.start_at(anchor_id):
		return false
	actor.position = graph.position(anchor_id)
	actor.show_idle()
	arrival_acknowledged = false
	_note("Reset REVIEW start " + anchor_id + " (never saved / gameplay teleport)")
	queue_redraw()
	return true

func walk_to_tea() -> Dictionary:
	if not ready_for_review or session == null:
		return {"ok": false, "error": "not-ready"}
	var result: Dictionary = session.request_hotspot(TARGET)
	if bool(result.get("ok", false)):
		_pump()
		_note("Tea table tap: authored route to " + ARRIVAL)
	return result

func _pump() -> void:
	if actor.has_active_segment():
		return
	var leg: Dictionary = session.next_segment()
	if leg.get("arrived", false):
		arrival_acknowledged = true
		_note("ARRIVED by authored route; VN gate remains OFF")
	elif not leg.is_empty() and not actor.start_segment(leg):
		push_error("MAP-TEA-01: walker rejected RouteSession segment")
	queue_redraw()

func _on_segment_completed(id: String, feet: Vector2) -> void:
	if feet.distance_to(graph.position(id)) > 0.01:
		push_error("MAP-TEA-01: arrival not at authored footpoint")
		return
	var result: Dictionary = session.finish_segment(id)
	if not bool(result.get("ok", false)):
		push_error("MAP-TEA-01: RouteSession rejected arrival")
		return
	match str(result.get("status", "")):
		"continue":
			_pump()
		"arrived":
			arrival_acknowledged = str(result.get("hotspotId", "")) == TARGET
			_note("PHYSICAL ARRIVAL " + str(feet) + " | VN gate not activated")
		"cancelled":
			_note("Cancelled at confirmed anchor: " + id)
	queue_redraw()

func cancel_route() -> Dictionary:
	if session == null:
		return {"ok": false, "error": "no-session"}
	var response: Dictionary = session.cancel()
	_note("Cancel requested; in-flight segment is completed first")
	return response

func pause_route() -> bool:
	if actor == null:
		return false
	var ok: bool = actor.resume_segment() if actor.is_paused() else actor.pause_segment()
	_note("Resume movement" if not actor.is_paused() else "Pause movement")
	return ok

func toggle_overlay() -> void:
	overlay_enabled = not overlay_enabled
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if not ready_for_review:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var tap: Vector2 = _image_to_world(source["spec"]["physicalReview"]["tableTapCentreImage"])
		if get_global_mouse_position().distance_to(tap) <= 30.0:
			walk_to_tea()
			get_viewport().set_input_as_handled()

func _image_to_world(pos: Array) -> Vector2:
	return Vector2(float(pos[0]), float(pos[1])) + OFFSET

func _poly(zone: Dictionary) -> PackedVector2Array:
	var result := PackedVector2Array()
	for pair in zone.get("pointsPx", []):
		result.append(_image_to_world(pair))
	return result

func _draw() -> void:
	if not overlay_enabled or not bool(source.get("ok", false)):
		return
	var constraints: Dictionary = source["plan"]["physicalConstraints"]
	for zone in constraints.get("walkablePolygons", []):
		if str(zone.get("roomId", "")) != HALL:
			continue
		var walkable := _poly(zone)
		draw_colored_polygon(walkable, Color(0.14, 0.8, 0.36, 0.13))
		draw_polyline(walkable, Color(0.2, 0.9, 0.4, 0.55), 1.4, true)
	for zone in constraints.get("noGoPolygons", []):
		if str(zone.get("roomId", "")) != HALL:
			continue
		var blocked := _poly(zone)
		draw_colored_polygon(blocked, Color(0.95, 0.13, 0.16, 0.3))
		draw_polyline(blocked, Color(1, 0.32, 0.34, 0.8), 2.0, true)
	var anchors: Dictionary = graph.anchors()
	for edge in source["plan"]["edges"]:
		var a: String = str(edge.get("from", ""))
		var b: String = str(edge.get("to", ""))
		if anchors.has(a) and anchors.has(b) and anchors[a].get("roomId") == HALL and anchors[b].get("roomId") == HALL:
			draw_line(graph.position(a), graph.position(b), Color(0.2, 0.78, 1.0, 0.85), 2.0, true)
	for id in anchors:
		var entry: Dictionary = anchors[id]
		if str(entry.get("roomId", "")) != HALL:
			continue
		draw_circle(graph.position(id), 2.6, Color(0.3, 0.92, 1.0, 0.95))
	var table_tap := _image_to_world(source["spec"]["physicalReview"]["tableTapCentreImage"])
	draw_circle(table_tap, 8.0, Color(1.0, 0.83, 0.22, 0.4))
	draw_arc(table_tap, 23.0, 0, TAU, 40, Color(1.0, 0.83, 0.22, 0.8), 1.8, true)
	draw_circle(graph.position(ARRIVAL), 8.0, Color(1.0, 0.9, 0.15, 0.92))
	draw_arc(graph.position(ARRIVAL), 12.0, 0, TAU, 40, Color(1, 1, 1, 0.9), 1.5, true)

func _make_ui() -> void:
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	ui_layer.add_child(panel)
	var column := VBoxContainer.new()
	panel.add_child(column)
	var heading := Label.new()
	heading.text = "MAP-TEA-01 | HALL TEA TEST_ONLY | production unchanged"
	column.add_child(heading)
	var actions := HFlowContainer.new()
	column.add_child(actions)
	_button(actions, "Hall safe spawn", func(): reset_to("RM-NAV-HALL-SPAWN"))
	_button(actions, "Hall after Corridor", func(): reset_to("RM-NAV-HALL-CORRIDOR-NEAR"))
	_button(actions, "Hall other anchor", func(): reset_to("RM-NAV-HS-001"))
	_button(actions, "Tap tea table", walk_to_tea)
	_button(actions, "Pause / Resume", pause_route)
	_button(actions, "Cancel", cancel_route)
	_button(actions, "Route/NO-GO overlay", toggle_overlay)
	status_label = Label.new()
	status_label.text = "DRAFT_ONLY"
	column.add_child(status_label)

func _button(parent: Node, title: String, callback: Callable) -> void:
	var item := Button.new()
	item.text = title
	item.custom_minimum_size = Vector2(125, 38)
	item.pressed.connect(callback)
	parent.add_child(item)

func _note(value: String) -> void:
	if is_instance_valid(status_label):
		status_label.text = value
