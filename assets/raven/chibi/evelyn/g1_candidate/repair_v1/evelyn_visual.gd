extends Node2D

## Candidate-only visual. Root is physical feet; movement is inherited unchanged.
const Direction = preload("res://scripts/raven/onoe_visual.gd")
const SHEET = preload("res://assets/raven/chibi/evelyn/g1_candidate/repair_v1/evelyn_walk.png")
const META_PATH = "res://assets/raven/chibi/evelyn/g1_candidate/repair_v1/frames.json"
const CLEAN_ALPHA = preload("res://assets/raven/chibi/evelyn/g1_candidate/repair_v1/clean_alpha.gdshader")
var _sprite: AnimatedSprite2D
var _height := 62.0
var _reduced := false
var _walking := false
var _ground_speed := 130.0
# A full 4-frame loop should cover roughly 0.8 visible character heights.
# This is an isolated candidate cadence estimate, not visual gait approval.
const CYCLE_STRIDE_IN_HEIGHTS := 0.8
const BASE_FPS := 6.0
var _meta: Dictionary

func _ready() -> void:
	_meta = JSON.parse_string(FileAccess.get_file_as_string(META_PATH))
	_sprite = AnimatedSprite2D.new()
	_sprite.name = "AnimatedSprite2D"
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for row in range(3):
		var clip: String = ["down", "up", "side"][row]
		frames.add_animation(clip)
		frames.set_animation_speed(clip, 6.0)
		for column in range(4):
			var texture := AtlasTexture.new()
			texture.atlas = SHEET
			var rect: Array = _meta.frames[clip][column].region
			texture.region = Rect2(rect[0], rect[1], rect[2], rect[3])
			texture.filter_clip = true
			frames.add_frame(clip, texture)
	_sprite.sprite_frames = frames
	_sprite.animation = "down"
	var alpha_material := ShaderMaterial.new()
	alpha_material.shader = CLEAN_ALPHA
	_sprite.material = alpha_material
	add_child(_sprite)
	_sprite.frame_changed.connect(_align)
	_apply_cadence()
	set_idle()

func get_sprite() -> AnimatedSprite2D:
	return _sprite

func set_display_height(pixels: float) -> void:
	if is_finite(pixels) and pixels > 0.0:
		_height = pixels
		if is_instance_valid(_sprite):
			_align()
			_apply_cadence()

func display_height() -> float:
	return _height

func set_ground_speed(source_px_per_second: float) -> void:
	if not is_finite(source_px_per_second) or source_px_per_second <= 0.0:
		return
	_ground_speed = source_px_per_second
	_apply_cadence()

func _apply_cadence() -> void:
	if not is_instance_valid(_sprite):
		return
	var travel_per_cycle := maxf(_height * CYCLE_STRIDE_IN_HEIGHTS, 1.0)
	var target_fps := clampf(_ground_speed * 4.0 / travel_per_cycle, 4.0, 18.0)
	_sprite.speed_scale = target_fps / BASE_FPS

func face(direction: Vector2) -> void:
	if not direction.is_finite() or direction.length_squared() <= 0.0001:
		return
	_walking = true
	Direction.play_sprite_direction(_sprite, direction)
	if _reduced:
		_sprite.stop()
		_sprite.frame = 0
	_align()

func set_idle() -> void:
	_walking = false
	_sprite.stop()
	_sprite.frame = 0
	_align()

func set_reduced_motion(enabled: bool) -> void:
	_reduced = enabled
	if enabled:
		_sprite.stop()
		_sprite.frame = 0
	elif _walking:
		_sprite.play()
	_align()

func _align() -> void:
	var data: Dictionary = _meta.frames[str(_sprite.animation)][_sprite.frame]
	var factor := _height / float(data.visibleHeight)
	var pivot := Vector2(float(data.pivot[0]), float(data.pivot[1]))
	_sprite.scale = Vector2.ONE * factor
	var offset := Vector2(float(data.region[2]), float(data.region[3])) * 0.5 - pivot
	# AnimatedSprite2D flips around its own origin, not the measured source pivot.
	if _sprite.flip_h:
		offset.x = -offset.x
	_sprite.position = offset * factor
