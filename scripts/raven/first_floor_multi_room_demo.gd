extends Node2D
## MAP-QA-07A: standalone F6 lab. Explicit TEST ONLY route and transition buttons.
## No production scene, save singleton, click-to-walk, or Prototype Lab edit.
const Fixture = preload("res://scripts/raven/first_floor_multi_room_fixture.gd")
const LAB := "res://scenes/raven/prototype_launcher.tscn"

@onready var host = $Host
var status_label: Label
var heading_label: Label


func _ready() -> void:
	var fixture: Dictionary = Fixture.build()
	_build_ui()
	if fixture.is_empty() or not host.configure_host(
		fixture.get("contract", {}), fixture.get("visuals", {}),
		str(fixture.get("initialRoomId", "")), str(fixture.get("initialAnchorId", ""))):
		_status("INVALID TEST FIXTURE: " + host.last_error)
		return
	host.room_changed.connect(_on_room_changed)
	host.movement_rejected.connect(_on_rejected)
	_status("Choose Hall → Corridor → Bedroom → Corridor → Hall. Portal mocked for QA only.")


func transition(id: String) -> Dictionary:
	var result: Dictionary = host.request_transition(id)
	_status("%s: %s" % [id, str(result.get("status", result.get("error", "?")))])
	return result


func walk_side() -> Dictionary:
	var id := "QA-HS:QA-HALL-EAST"
	match host.active_room_id:
		"QA-F7-CORRIDOR":
			id = "QA-HS-F7-C-SIDE"
		"QA-F7-BEDROOM":
			id = "QA-HS-F7-B-SIDE"
	var result: Dictionary = host.request_hotspot(id)
	_status("Walk: %s" % str(result.get("status", result.get("error", "?"))))
	return result


func toggle_hall_gate() -> void:
	var door := "QA-F7-DOOR-HC"
	var next := "gated" if host.controller.door_status(door) == "open" else "open"
	if host.test_gate(door, next):
		_status("TEST ONLY %s → %s" % [door, next])
		if next == "open" and host.controller.in_safe_hold():
			_status("Gate reopened; resume permitted: %s" % str(host.resume_gate_hold()))


func _pause() -> void:
	if host.actor.is_paused():
		_status("Resume: %s" % str(host.resume_movement()))
	else:
		_status("Pause: %s" % str(host.pause_movement()))


func _status(message: String) -> void:
	if not is_instance_valid(status_label):
		return
	var room: String = str(host.active_room_id)
	status_label.text = "%s\nRoom %s · anchor %s · feet %s" % [
		message, room, host.controller.confirmed_anchor(), str(host.actor.position.round())]
	heading_label.text = "MAP-QA-07A · %s · TEST ONLY" % room


func _on_room_changed(event: Dictionary) -> void:
	_status("PHYSICAL HANDOFF → %s; reverse %s" % [
		str(event.get("roomId", "")), str(event.get("reverseTransitionId", ""))])


func _on_rejected(reason: String) -> void:
	_status("REJECTED / SAFE HOLD: " + reason)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F3:
			host.toggle_routes()
		elif event.keycode == KEY_SPACE:
			_pause()


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	heading_label = Label.new()
	heading_label.position = Vector2(10, 10)
	heading_label.add_theme_font_size_override("font_size", 15)
	heading_label.add_theme_color_override("font_color", Color("#f2d7aa"))
	layer.add_child(heading_label)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_left = 7
	panel.offset_right = -7
	panel.offset_top = -187
	panel.offset_bottom = -7
	layer.add_child(panel)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 4)
	panel.add_child(rows)
	var moves := GridContainer.new()
	moves.columns = 3
	rows.add_child(moves)
	_add_button(moves, "Hall → Cor.", func(): transition("QA-F7-TR-HC"))
	_add_button(moves, "Cor. → Bed", func(): transition("QA-F7-TR-CB"))
	_add_button(moves, "Bed → Cor.", func(): transition("QA-F7-TR-BC"))
	_add_button(moves, "Cor. → Hall", func(): transition("QA-F7-TR-CH"))
	_add_button(moves, "Walk side", walk_side)
	_add_button(moves, "Locked", func(): transition("QA-F7-TR-LOCKED"))
	var tools := GridContainer.new()
	tools.columns = 4
	rows.add_child(tools)
	_add_button(tools, "Gate", toggle_hall_gate)
	_add_button(tools, "Pause", _pause)
	_add_button(tools, "Routes", host.toggle_routes)
	_add_button(tools, "Cancel", func(): _status(str(host.cancel_request())))
	var footer := HBoxContainer.new()
	rows.add_child(footer)
	_add_button(footer, "← Lab", func(): get_tree().change_scene_to_file(LAB))
	var help := Label.new()
	help.text = "F3 routes · Space pause · no free tap-to-move"
	help.add_theme_font_size_override("font_size", 10)
	footer.add_child(help)
	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_font_size_override("font_size", 11)
	rows.add_child(status_label)


func _add_button(parent: Node, title: String, action: Callable) -> void:
	var button := Button.new()
	button.text = title
	button.custom_minimum_size = Vector2(83, 29)
	button.add_theme_font_size_override("font_size", 11)
	button.pressed.connect(action)
	parent.add_child(button)
