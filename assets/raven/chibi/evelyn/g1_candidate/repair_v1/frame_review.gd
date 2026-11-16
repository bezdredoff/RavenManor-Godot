extends Node2D

const Visual = preload("res://assets/raven/chibi/evelyn/g1_candidate/repair_v1/evelyn_visual.gd")
var actors: Array[Node2D] = []
var _playing := true
var _light := false

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("28252e"))
	_label("EVELYN · MOTION REVIEW CANDIDATE", Vector2(12, 14), 16)
	_label("VN-led repair · visual approval pending", Vector2(12, 39), 12)
	var bar := HFlowContainer.new()
	bar.position = Vector2(12, 65)
	bar.size.x = 366
	add_child(bar)
	_button(bar, "Play / idle", _toggle_play)
	_button(bar, "Next frame", _step)
	_button(bar, "Light / dark", _background)
	_button(bar, "Map routes", func(): get_tree().change_scene_to_file("res://scenes/raven/tests/evelyn_chibi_map_preview.tscn"))
	var directions := [Vector2.DOWN, Vector2.UP, Vector2.RIGHT, Vector2.LEFT]
	for i in range(4):
		var visual = Visual.new()
		visual.position = Vector2(49 + i*97, 334)
		add_child(visual)
		visual.set_display_height(178)
		visual.face(directions[i])
		actors.append(visual)
		_label(["DOWN", "UP", "RIGHT", "LEFT"][i], Vector2(22 + i*97, 345), 12)
		var small = Visual.new()
		small.position = Vector2(49 + i*97, 440)
		add_child(small)
		small.set_display_height(62 * 0.74)
		small.face(directions[i])
		actors.append(small)
	_label("Map size: 62 source px × 0.74 = 45.88 screen px", Vector2(12, 465), 12)
	var reduced := CheckButton.new()
	reduced.position = Vector2(12, 490)
	reduced.text = "Reduced motion: hold facing, retain travel"
	reduced.toggled.connect(func(value: bool):
		for visual in actors:
			visual.set_reduced_motion(value))
	add_child(reduced)
	var reference := Sprite2D.new()
	reference.texture = preload("res://assets/raven/characters/evelyn/base_neutral.webp")
	reference.scale = Vector2.ONE * (224.0 / 1920.0)
	reference.position = Vector2(100, 665)
	add_child(reference)
	var selected := Sprite2D.new()
	var texture := AtlasTexture.new()
	texture.atlas = preload("res://assets/raven/chibi/evelyn/g1_candidate/repair_v1/evelyn_walk.png")
	texture.region = Rect2(256, 0, 256, 512)
	selected.texture = texture
	selected.material = actors[0].get_sprite().material
	selected.scale = Vector2.ONE * (224.0 / 512.0)
	selected.position = Vector2(286, 665)
	add_child(selected)
	_label("Approved VN", Vector2(57, 790), 13)
	_label("Current candidate", Vector2(234, 790), 13)
	_label("Feet guides show registered contact; inspect gait visually.", Vector2(12, 819), 11)
	queue_redraw()
	if OS.get_cmdline_user_args().has("--light"):
		_background()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="):
			_capture(arg.trim_prefix("--capture="))

func _process(delta: float) -> void:
	if _playing:
		for visual in actors:
			# Same body-relative speed at both zooms. This is a stationary gait
			# inspector; only the map host supplies physical root displacement.
			visual.travel(delta * visual.display_height() * (55.0 / 62.0))

func _draw() -> void:
	for i in range(4):
		var x := 49.0 + i*97
		for y in [334.0, 440.0]:
			draw_line(Vector2(x-30, y), Vector2(x+30, y), Color("b69f74"), 1)
			draw_line(Vector2(x, y-4), Vector2(x, y+4), Color("b69f74"), 1)

func _label(value: String, at: Vector2, size_px: int) -> void:
	var label := Label.new()
	label.text = value
	label.position = at
	label.add_theme_font_size_override("font_size", size_px)
	add_child(label)

func _button(parent: Control, value: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size.y = 34
	button.pressed.connect(callback)
	parent.add_child(button)

func _toggle_play() -> void:
	_playing = not _playing
	for visual in actors:
		if _playing:
			var sprite: AnimatedSprite2D = visual.get_sprite()
			var direction := Vector2.UP if sprite.animation == "up" else Vector2.DOWN
			if sprite.animation == "side":
				direction = Vector2.LEFT if sprite.flip_h else Vector2.RIGHT
			visual.face(direction)
		else:
			visual.set_idle()

func _step() -> void:
	_playing = false
	for visual in actors:
		if visual._reduced:
			continue
		var sprite: AnimatedSprite2D = visual.get_sprite()
		sprite.pause()
		sprite.frame = (sprite.frame + 1) % 4

func _background() -> void:
	_light = not _light
	RenderingServer.set_default_clear_color(Color("ddd9cf") if _light else Color("28252e"))
	for label in find_children("*", "Label", true, false):
		label.add_theme_color_override("font_color", Color("28252e") if _light else Color.WHITE)
	for check in find_children("*", "CheckButton", true, false):
		check.add_theme_color_override("font_color", Color("28252e") if _light else Color.WHITE)

func _capture(path: String) -> void:
	await get_tree().create_timer(0.2).timeout
	await RenderingServer.frame_post_draw
	var error := get_viewport().get_texture().get_image().save_png(path)
	print("Evelyn review capture: ", error)
	get_tree().quit(error)
