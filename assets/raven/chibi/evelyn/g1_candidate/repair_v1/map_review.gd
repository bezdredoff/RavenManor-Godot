extends Node

var _review_route := false
var _next_stop := 0
const REVIEW_STOPS := ["QA-HALL-EAST", "QA-HALL-CENTRE", "QA-HALL-TABLE-APPROACH", "QA-HALL-SPAWN", "QA-HALL-WEST", "QA-HALL-SPAWN"]

func _ready() -> void:
	call_deferred("_setup")

func _setup() -> void:
	var host = get_parent()
	host.camera.zoom = Vector2.ONE * 0.74
	host._clamp_camera()
	# Candidate-only review pace: old 130px/s is 2.1 body heights/s.
	# Shared mover and production movement defaults remain authoritative.
	host.actor.move_speed = 55.0
	host.hotspots.visible = false
	for button in host.find_children("*", "Button", true, false):
		if button.text == "Stop":
			button.pressed.connect(_stop_review)
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(8, 672)
	panel.custom_minimum_size.x = 374
	layer.add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	var title := Label.new()
	title.text = "EVELYN · REVIEW CANDIDATE · 55px/s"
	title.add_theme_font_size_override("font_size", 13)
	box.add_child(title)
	var reduced := CheckButton.new()
	reduced.text = "Reduced motion"
	reduced.toggled.connect(func(enabled: bool): host.actor.visual().set_reduced_motion(enabled))
	box.add_child(reduced)
	var markers := CheckButton.new()
	markers.text = "Show authored route targets"
	markers.toggled.connect(func(enabled: bool): host.hotspots.visible = enabled)
	box.add_child(markers)
	var walk := Button.new()
	walk.text = "Walk review route (six authored stops)"
	walk.pressed.connect(func():
		_next_stop = 0
		_review_route = true)
	box.add_child(walk)
	var closeup := Button.new()
	closeup.text = "Close-up / frame inspector"
	closeup.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/raven/tests/evelyn_chibi_preview.tscn"))
	box.add_child(closeup)
	for arg in OS.get_cmdline_user_args():
		if arg == "--review-route":
			_review_route = true
		if arg.begins_with("--capture-map="):
			_capture(arg.trim_prefix("--capture-map="))

func _process(_delta: float) -> void:
	if not _review_route:
		return
	var host = get_parent()
	if host.ready_for_qa and not host.actor.has_active_segment() and _next_stop < REVIEW_STOPS.size():
		assert(host.request_waypoint(REVIEW_STOPS[_next_stop]))
		_next_stop += 1

func _stop_review() -> void:
	_review_route = false

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_S:
		_stop_review()

func _capture(path: String) -> void:
	await get_tree().create_timer(0.2).timeout
	await RenderingServer.frame_post_draw
	var error := get_viewport().get_texture().get_image().save_png(path)
	print("Evelyn map capture: ", error)
	get_tree().quit(error)
