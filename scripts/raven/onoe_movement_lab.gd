extends Node2D

## Standalone visual/interaction lab. NOT registered in Prototype Lab or game flow.
## Arrow keys queue a direction *for after* the current segment. Space = pause.
const DIRECTIONS := [Vector2(150, 0), Vector2(-150, 0), Vector2(0, -120), Vector2(0, 120)]

@onready var onoe = $Onoe
var _next_direction := Vector2.ZERO
var _demo_index := 0
var _number := 0
var _hud: Label


func _ready() -> void:
	var camera := Camera2D.new()
	camera.enabled = true
	add_child(camera)
	_hud = Label.new()
	_hud.text = "ONOE MOVEMENT TEST | arrows: queue next | Space: pause/resume"
	_hud.position = Vector2(-310, -255)
	_hud.add_theme_font_size_override("font_size", 18)
	add_child(_hud)
	onoe.segment_completed.connect(_on_completed)
	onoe.segment_started.connect(_on_started)
	onoe.move_speed = 175.0
	call_deferred("_next_demo_leg")


func _draw() -> void:
	for x in range(-300, 301, 50):
		draw_line(Vector2(float(x), -185), Vector2(float(x), 185), Color("#4c4056"), 1.0)
	for y in range(-185, 186, 50):
		draw_line(Vector2(-300, float(y)), Vector2(300, float(y)), Color("#4c4056"), 1.0)
	draw_circle(Vector2.ZERO, 7.0, Color("#dec77d"))
	draw_rect(Rect2(Vector2(-300, -185), Vector2(600, 370)), Color("#9a819f"), false, 2.0)


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode == KEY_SPACE:
		if onoe.is_paused():
			onoe.resume_segment()
			_hud.text = "Resumed current authorized segment"
		elif onoe.pause_segment():
			_hud.text = "PAUSED: footpoint unchanged, no arrival event"
		return
	var requested := Vector2.ZERO
	match event.keycode:
		KEY_RIGHT: requested = Vector2(150, 0)
		KEY_LEFT: requested = Vector2(-150, 0)
		KEY_UP: requested = Vector2(0, -120)
		KEY_DOWN: requested = Vector2(0, 120)
	if requested == Vector2.ZERO:
		return
	_next_direction = requested
	_hud.text = "Replacement requested: current segment must finish first"
	if not onoe.has_active_segment():
		_next_demo_leg()


func _next_demo_leg() -> void:
	if not is_instance_valid(onoe) or onoe.has_active_segment():
		return
	var offset: Vector2 = _next_direction
	_next_direction = Vector2.ZERO
	if offset == Vector2.ZERO:
		offset = DIRECTIONS[_demo_index % DIRECTIONS.size()]
		_demo_index += 1
	_number += 1
	var here: Vector2 = onoe.position
	var next: Vector2 = here + offset
	onoe.start_segment({
		"fromAnchorId": "LAB-%d" % (_number - 1),
		"toAnchorId": "LAB-%d" % _number,
		"fromPosition": here, "toPosition": next
	})


func _on_started(_from: String, _to: String) -> void:
	_hud.text = "Moving %s | actual feet: %s" % [_to, str(onoe.position)]


func _on_completed(to_id: String, at: Vector2) -> void:
	_hud.text = "Arrived %s at %s (physically)" % [to_id, str(at)]
	if is_instance_valid(onoe):
		get_tree().create_timer(0.3).timeout.connect(_next_demo_leg)
