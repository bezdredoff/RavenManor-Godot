extends Node2D
## MAP-QA-06: synthetic two-room handoff. Does not load or persist a campaign.
## F6 scenes/raven/tests/room_transition_synthetic.tscn
const Controller = preload("res://scripts/raven/manor_room_transition_controller.gd")
const FIXTURE_PATH := "res://data/raven/qa/room_transitions_synthetic.v1.json"
const LAB_PATH := "res://scenes/raven/prototype_launcher.tscn"

@onready var actor = $Onoe
var controller = Controller.new()
var feedback: Label
var room_label: Label
var _active_token := 0


func _ready() -> void:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE_PATH))
	if not raw is Dictionary or not controller.configure(raw, "QA-ROOM-A", "QA-A-ENTRY"):
		push_error("MAP-QA-06 synthetic data invalid: " + controller.error_text)
		return
	actor.position = controller.anchor_position("QA-A-ENTRY") # Initial QA spawn only.
	actor.move_speed = 205.0
	actor.set_sprite_height(68.0)
	actor.segment_completed.connect(_on_segment_completed)
	controller.transition_ready.connect(_on_handoff_ready)
	controller.transition_rejected.connect(_on_rejection)
	controller.transition_diagnostic.connect(_on_diagnostic)
	_build_ui()
	_show("Choose A → B. Onoe walks to the authorized approach before switching.")
	queue_redraw()


func _draw() -> void:
	if controller.room_id().is_empty():
		return
	var is_a := controller.room_id() == "QA-ROOM-A"
	draw_rect(Rect2(48, 60, 392, 295), Color("#273348") if is_a else Color("#304438"))
	draw_rect(Rect2(48, 60, 392, 295), Color("#b4c8d5"), false, 4.0)
	draw_rect(Rect2(376, 250, 44, 45), Color("#d6b96f") if controller.door_status("QA-DOOR-A-B") == "open" else Color("#904b52"))
	var graph = controller.room_graph(controller.room_id())
	for edge in graph.active_edges():
		draw_line(graph.position(str(edge["from"])), graph.position(str(edge["to"])), Color("#74c4ef"), 2.0)
	for id in graph.anchors():
		var entry: Dictionary = graph.anchor(id)
		var color := Color("#f9d989") if entry.get("kind") == "safe" else Color("#a2ffdf")
		if str(entry.get("kind", "")) == "transition":
			color = Color("#ffb7e5")
		draw_circle(graph.position(str(id)), 7.0, color)
		var shortened := str(id).replace("QA-A-", "").replace("QA-B-", "")
		draw_string(ThemeDB.fallback_font, graph.position(str(id)) + Vector2(9, -8),
			shortened, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#fff8e7"))


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	room_label = Label.new()
	room_label.position = Vector2(9, 9)
	room_label.add_theme_font_size_override("font_size", 17)
	room_label.add_theme_color_override("font_color", Color("#eddaaa"))
	layer.add_child(room_label)
	var panel := PanelContainer.new()
	panel.position = Vector2(8, 380)
	panel.custom_minimum_size = Vector2(375, 0)
	layer.add_child(panel)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 4)
	panel.add_child(stack)
	var row1 := HBoxContainer.new()
	stack.add_child(row1)
	_add_button(row1, "A → B", func(): _request("QA-TR-A-B"))
	_add_button(row1, "B → A", func(): _request("QA-TR-B-A"))
	_add_button(row1, "Walk within room", _walk_side)
	var row2 := HBoxContainer.new()
	stack.add_child(row2)
	_add_button(row2, "Locked door", func(): _request("QA-TR-A-LOCKED"))
	_add_button(row2, "Future door", func(): _request("QA-TR-A-FUTURE"))
	_add_button(row2, "Virtual portal", func(): _request("QA-TR-A-VIRTUAL"))
	var row3 := HBoxContainer.new()
	stack.add_child(row3)
	_add_button(row3, "Gate: approach", func(): _toggle_gate("QA-DOOR-APPROACH"))
	_add_button(row3, "Gate: A ↔ B", func(): _toggle_gate("QA-DOOR-A-B"))
	var row4 := HBoxContainer.new()
	stack.add_child(row4)
	_add_button(row4, "Cancel request", _cancel_request)
	_add_button(row4, "Pause/resume", _toggle_pause)
	_add_button(row4, "← Lab", func(): get_tree().change_scene_to_file(LAB_PATH))
	feedback = Label.new()
	feedback.custom_minimum_size = Vector2(352, 90)
	feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback.add_theme_font_size_override("font_size", 12)
	stack.add_child(feedback)


func _add_button(parent: HBoxContainer, title: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = title
	button.add_theme_font_size_override("font_size", 11)
	button.pressed.connect(callback)
	parent.add_child(button)


func _request(transition_id: String) -> void:
	var result: Dictionary = controller.request_transition(transition_id, actor)
	_show("%s: %s" % [transition_id, str(result.get("status", result.get("error", "?")))])
	_pump()


func _walk_side() -> void:
	var hotspot := "QA-HS-A-SIDE" if controller.room_id() == "QA-ROOM-A" else "QA-HS-B-SIDE"
	var result: Dictionary = controller.request_room_hotspot(hotspot, actor)
	_show("Walk to %s: %s" % [hotspot, str(result.get("status", result.get("error", "?")))])
	_pump()


func _pump() -> void:
	if controller.in_safe_hold() or actor.has_active_segment():
		return
	var segment: Dictionary = controller.next_segment(actor)
	if segment.is_empty() or segment.get("arrived", false):
		_refresh()
		return
	_active_token = int(segment["segmentToken"])
	if not actor.start_segment(segment):
		controller.report_dispatch_failure(_active_token)
		_show("SAFE HOLD: actor rejected authorized segment; reload F6 (no teleport).")
	else:
		_show("Walking %s → %s" % [str(segment.fromAnchorId), str(segment.toAnchorId)])


func _on_segment_completed(arrived_id: String, physical_feet: Vector2) -> void:
	var result: Dictionary = controller.accept_segment_arrival(_active_token, arrived_id, physical_feet, actor)
	if not bool(result.get("ok", false)):
		_show("Arrival rejected: " + str(result.get("error", "?")))
		return
	_show("Reached %s. %s" % [arrived_id, str(result.get("status", ""))])
	_pump()


func _on_handoff_ready(_result: Dictionary) -> void:
	# Explicit host-controlled handoff: the controller validates the physical
	# approach again; this callback replaces only synthetic room visuals.
	var outcome: Dictionary = controller.commit_transition(actor)
	if outcome.get("ok", false):
		_show("SWITCHED %s → %s at approved %s. Return: %s" % [
			str(outcome.fromRoomId), str(outcome.roomId),
			str(outcome.entryAnchorId), str(outcome.reverseTransitionId)])
		queue_redraw()
	else:
		_show("Handoff denied: " + str(outcome.get("error", "")))


func _on_rejection(id: String, reason: String) -> void:
	_show("REJECTED %s: %s (feet unchanged)" % [id, reason])


func _on_diagnostic(id: String, reason: String) -> void:
	_show("QA DIAGNOSTIC %s: %s; room unchanged" % [id, reason])


func _toggle_gate(id: String) -> void:
	var status := "gated" if controller.door_status(id) == "open" else "open"
	controller.set_test_door_status(id, status, actor)
	if status == "open" and controller.in_safe_hold():
		if controller.resume_held_segment(actor):
			_show("Gate reopened; resume held physical segment (transition cancelled).")
		else:
			_show("Gate reopened but hard hold requires manual restart; no snapping.")
	else:
		_show("%s → %s; no campaign mutation" % [id, status])
	queue_redraw()


func _toggle_pause() -> void:
	if controller.in_safe_hold():
		_show("SAFE HOLD; reopen the blocking gate or restart demonstration.")
		return
	if actor.is_paused():
		actor.resume_segment()
	else:
		actor.pause_segment()
	_refresh()


func _cancel_request() -> void:
	var result: Dictionary = controller.cancel_transition()
	_show("Cancel: %s. Active movement finishes without switching." % str(result))
	_refresh()


func _show(message: String) -> void:
	if not is_instance_valid(feedback):
		return
	feedback.text = "%s\nRoom: %s | confirmed: %s | pending: %s\nActor feet: %s | hold: %s" % [
		message, controller.room_id(), controller.confirmed_anchor(),
		controller.pending_transition(), str(actor.position.round()), str(controller.in_safe_hold())]
	_refresh()


func _refresh() -> void:
	if is_instance_valid(room_label):
		room_label.text = "MAP-QA-06 · %s · SYNTHETIC TEST ONLY" % controller.room_id()
