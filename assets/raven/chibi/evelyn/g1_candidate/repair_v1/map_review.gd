extends Node

func _ready() -> void:
	call_deferred("_setup")

func _setup() -> void:
	var host = get_parent()
	host.camera.zoom = Vector2.ONE * 0.74
	host._clamp_camera()
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(8, 726)
	panel.custom_minimum_size.x = 374
	layer.add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	var title := Label.new()
	title.text = "EVELYN · CANDIDATE / OWNER MOTION QA"
	title.add_theme_font_size_override("font_size", 13)
	box.add_child(title)
	var reduced := CheckButton.new()
	reduced.text = "Reduced motion"
	reduced.toggled.connect(func(enabled: bool): host.actor.visual().set_reduced_motion(enabled))
	box.add_child(reduced)
	var closeup := Button.new()
	closeup.text = "Close-up / frame inspector"
	closeup.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/raven/tests/evelyn_chibi_preview.tscn"))
	box.add_child(closeup)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-map="):
			_capture(arg.trim_prefix("--capture-map="))

func _capture(path: String) -> void:
	await get_tree().create_timer(0.2).timeout
	await RenderingServer.frame_post_draw
	var error := get_viewport().get_texture().get_image().save_png(path)
	print("Evelyn map capture: ", error)
	get_tree().quit(error)
