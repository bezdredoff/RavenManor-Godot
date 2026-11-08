extends Node2D
## MAP-QA-07A reusable visual host over MAP-QA-06. It never owns save data,
## door handoff policy, route finding, or a second Onoe mover.
const Controller = preload("res://scripts/raven/manor_room_transition_controller.gd")
const HALL_ART := "res://a_detailed_top_down_isometric_game_map_illustratio.png"

signal room_changed(details: Dictionary)
signal movement_rejected(reason: String)

@onready var actor = $Onoe
@onready var camera: Camera2D = $Camera2D
@onready var room_visuals: Node2D = $RoomVisuals
@onready var route_overlay: Node2D = $RouteOverlay

var controller = Controller.new()
var active_room_id := ""
var last_error := ""
var last_transition: Dictionary = {}
var ready_for_test := false
var _contract: Dictionary = {}
var _room_specs: Dictionary = {}
var _gate_snapshot: Dictionary = {}
var _segment_token := 0
var _overlay_enabled := false
var _state: Dictionary = {}


func configure_host(contract: Dictionary, room_specs: Dictionary, initial_room: String, initial_anchor: String, gate_snapshot: Dictionary = {}) -> bool:
	if ready_for_test or actor.has_active_segment():
		return _fail("host-already-running")
	if not _check_visual_contract(contract, room_specs):
		return false
	var trial = Controller.new()
	if not trial.configure(contract, initial_room, initial_anchor, gate_snapshot):
		return _fail("transition-contract:" + trial.error_text)
	_contract = contract.duplicate(true)
	_room_specs = room_specs.duplicate(true)
	_gate_snapshot = gate_snapshot.duplicate(true)
	_bind(trial)
	active_room_id = controller.room_id()
	# Authorized initial spawn ONLY; inter-room relocation stays in MAP-QA-06.
	actor.position = controller.anchor_position(initial_anchor)
	actor.set_sprite_height(62.0)
	actor.move_speed = 130.0
	actor.segment_completed.connect(_on_actor_segment_completed)
	_state = {"roomId": active_room_id, "lastSafeAnchorId": initial_anchor,
		"returnSpawnAnchorId": "", "lastTransitionId": "", "transitionComplete": false}
	ready_for_test = true
	camera.make_current()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	_show_active_room()
	camera.reset_smoothing()
	return true


func request_transition(transition_id: String) -> Dictionary:
	if not ready_for_test:
		return {"ok": false, "error": "host-not-configured"}
	var result: Dictionary = controller.request_transition(transition_id, actor)
	if bool(result.get("ok", false)):
		_pump()
	else:
		last_error = str(result.get("error", "transition-rejected"))
	return result


func request_hotspot(hotspot_id: String) -> Dictionary:
	if not ready_for_test:
		return {"ok": false, "error": "host-not-configured"}
	var result: Dictionary = controller.request_room_hotspot(hotspot_id, actor)
	if bool(result.get("ok", false)):
		_pump()
	else:
		last_error = str(result.get("error", "hotspot-rejected"))
	return result


func cancel_request() -> Dictionary:
	if not ready_for_test:
		return {"ok": false, "error": "host-not-configured"}
	return controller.cancel_transition()


func pause_movement() -> bool:
	return ready_for_test and actor.pause_segment()


func resume_movement() -> bool:
	return ready_for_test and not controller.in_safe_hold() and actor.resume_segment()


func toggle_routes() -> void:
	_overlay_enabled = not _overlay_enabled
	route_overlay.visible = _overlay_enabled


func test_gate(door_id: String, status: String) -> bool:
	if not ready_for_test or _contract.get("approval") != "TEST_ONLY":
		return false
	if not controller.set_test_door_status(door_id, status, actor):
		return false
	var unlocked: Array = []
	for entry in _contract.get("doors", []):
		var id := str(entry.get("id", ""))
		if controller.door_status(id) == "open":
			unlocked.append(id)
	_gate_snapshot = {"unlockedDoors": unlocked}
	return true


func resume_gate_hold() -> bool:
	return ready_for_test and controller.resume_held_segment(actor)


func state_proposal() -> Dictionary:
	# In-memory boundary only. Caller must never persist this automatically.
	return _state.duplicate(true)


func current_graph():
	return controller.room_graph(active_room_id) if ready_for_test else null


func replace_room_graph(room_id: String, graph_data: Dictionary) -> bool:
	# Adapter boundary for MAP-QA-05 / MAP-EDIT-02. No mid-leg reconfigure,
	# implicit anchor snapping, stale handoff, or production draft promotion.
	if not ready_for_test or actor.has_active_segment() or controller.in_safe_hold():
		return _fail("graph-replacement-unsafe")
	if not controller.pending_transition().is_empty() or not controller.ready_transition().is_empty():
		return _fail("graph-replacement-during-transition")
	var current_anchor := controller.confirmed_anchor()
	var previous_position: Vector2 = actor.position
	var candidate := _contract.duplicate(true)
	var found := false
	for room in candidate.get("rooms", []):
		if str(room.get("id", "")) == room_id:
			room["graph"] = graph_data.duplicate(true)
			found = true
			break
	if not found:
		return _fail("unknown-room")
	var trial = Controller.new()
	if not trial.configure(candidate, active_room_id, current_anchor, _gate_snapshot):
		return _fail("replacement-invalid:" + trial.error_text)
	if trial.anchor_position(current_anchor).distance_to(previous_position) > Controller.FOOT_TOLERANCE:
		return _fail("replacement-would-relocate-actor")
	_contract = candidate
	_bind(trial)
	_show_active_room()
	assert(actor.position == previous_position)
	return true


func _bind(next_controller) -> void:
	controller = next_controller
	controller.transition_ready.connect(_on_transition_ready)
	controller.transition_completed.connect(_on_transition_completed)
	controller.transition_rejected.connect(_on_transition_rejected)


func _pump() -> void:
	if not ready_for_test or actor.has_active_segment() or controller.in_safe_hold():
		return
	var segment: Dictionary = controller.next_segment(actor)
	if segment.is_empty() or bool(segment.get("arrived", false)):
		return
	_segment_token = int(segment.get("segmentToken", 0))
	if not actor.start_segment(segment):
		controller.report_dispatch_failure(_segment_token)
		_fail("actor-dispatch-refused")


func _on_actor_segment_completed(anchor_id: String, feet: Vector2) -> void:
	var result: Dictionary = controller.accept_segment_arrival(_segment_token, anchor_id, feet, actor)
	if not bool(result.get("ok", false)):
		_fail("physical-arrival-rejected:" + str(result.get("error", "")))
		return
	var graph = current_graph()
	if graph != null and str(graph.anchor(controller.confirmed_anchor()).get("kind", "")) == "safe":
		_state["lastSafeAnchorId"] = controller.confirmed_anchor()
	_pump()


func _on_transition_ready(_details: Dictionary) -> void:
	# Physical approach was confirmed by MAP-QA-06. Reject missing visuals
	# before asking it to commit (and intentionally relocate) the actor.
	var destination := str(_details.get("destinationRoomId", ""))
	if not _room_specs.has(destination):
		controller.cancel_transition()
		_fail("missing-destination-visual")
		return
	var result: Dictionary = controller.commit_transition(actor)
	if not bool(result.get("ok", false)):
		_fail("handoff-rejected:" + str(result.get("error", "")))


func _on_transition_completed(details: Dictionary) -> void:
	active_room_id = str(details.get("roomId", ""))
	last_transition = details.duplicate(true)
	_state = {"roomId": active_room_id, "lastSafeAnchorId": str(details.get("entryAnchorId", "")),
		"returnSpawnAnchorId": str(details.get("entryAnchorId", "")),
		"lastTransitionId": str(details.get("transitionId", "")), "transitionComplete": true}
	_show_active_room()
	# Smoothing follows Onoe within a room. Reset on a room coordinate-space
	# switch so the camera never sweeps through an unrendered intermediate area.
	camera.reset_smoothing()
	room_changed.emit(details.duplicate(true))


func _on_transition_rejected(_id: String, reason: String) -> void:
	_fail(reason)


func _process(_delta: float) -> void:
	if ready_for_test:
		camera.position = actor.position


func _check_visual_contract(contract: Dictionary, specs: Dictionary) -> bool:
	if contract.get("approval") not in ["TEST_ONLY", "PRODUCTION_APPROVED"]:
		return _fail("visuals-require-authorized-contract")
	for room in contract.get("rooms", []):
		if not room is Dictionary:
			return _fail("invalid-room-visual-record")
		var id := str(room.get("id", ""))
		if not specs.has(id) or not specs[id] is Dictionary:
			return _fail("missing-room-visual:" + id)
		var spec: Dictionary = specs[id]
		var values: Variant = spec.get("bounds", [])
		if not values is Array or values.size() != 4:
			return _fail("invalid-camera-bounds:" + id)
		for value in values:
			if not (value is int or value is float) or not is_finite(float(value)):
				return _fail("invalid-camera-bounds:" + id)
		if float(values[2]) <= 0.0 or float(values[3]) <= 0.0:
			return _fail("invalid-camera-bounds:" + id)
		var source := str(spec.get("source", ""))
		if source not in ["synthetic", "hall-qa", "approved-art"]:
			return _fail("invalid-visual-authority:" + id)
		var path := str(spec.get("texturePath", ""))
		if source == "hall-qa" and path != HALL_ART:
			return _fail("hall-art-identity-mismatch")
		if source != "synthetic" and (path.is_empty() or not ResourceLoader.exists(path)):
			return _fail("missing-room-texture:" + id)
		var zoom := float(spec.get("cameraZoom", 0.8))
		if not is_finite(zoom) or zoom <= 0.0 or zoom > 4.0:
			return _fail("invalid-camera-zoom:" + id)
	return true


func _show_active_room() -> void:
	for child in room_visuals.get_children():
		child.queue_free()
	for child in route_overlay.get_children():
		child.queue_free()
	var spec: Dictionary = _room_specs[active_room_id]
	var bounds: Array = spec["bounds"]
	var frame := Rect2(float(bounds[0]), float(bounds[1]), float(bounds[2]), float(bounds[3]))
	if str(spec.get("source", "")) == "synthetic":
		var tile := ColorRect.new()
		tile.color = Color("#343b50") if active_room_id.contains("CORRIDOR") else Color("#4a3547")
		tile.position = frame.position
		tile.size = frame.size
		tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
		room_visuals.add_child(tile)
		var label := Label.new()
		label.text = "TEST ONLY · %s · NOT APPROVED GEOMETRY" % active_room_id
		label.position = frame.position + Vector2(25, 38)
		label.add_theme_font_size_override("font_size", 19)
		room_visuals.add_child(label)
	else:
		var art := Sprite2D.new()
		art.texture = load(str(spec.get("texturePath", "")))
		art.centered = false
		art.position = frame.position
		room_visuals.add_child(art)
	_draw_graph()
	camera.limit_left = int(floor(frame.position.x))
	camera.limit_top = int(floor(frame.position.y))
	camera.limit_right = int(ceil(frame.end.x))
	camera.limit_bottom = int(ceil(frame.end.y))
	camera.zoom = Vector2.ONE * float(spec.get("cameraZoom", 0.8))
	camera.position = actor.position
	actor.set_sprite_height(float(spec.get("actorHeight", 70.0)))
	route_overlay.visible = _overlay_enabled


func _draw_graph() -> void:
	var graph = current_graph()
	if graph == null:
		return
	for edge in graph.active_edges():
		var line := Line2D.new()
		line.width = 3.0
		line.default_color = Color("#78d9ef")
		line.points = PackedVector2Array([graph.position(str(edge.get("from", ""))),
			graph.position(str(edge.get("to", "")))])
		route_overlay.add_child(line)
	for id in graph.anchors():
		var dot := ColorRect.new()
		dot.color = Color("#f9d989") if graph.anchor(str(id)).get("kind") == "safe" else Color("#ed9ad9")
		dot.size = Vector2(12, 12)
		dot.position = graph.position(str(id)) - Vector2(6, 6)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		route_overlay.add_child(dot)


func _fail(reason: String) -> bool:
	last_error = reason
	movement_rejected.emit(reason)
	return false
