extends Node2D

## Preview-only adapter. Feet/root belong to the inherited segment mover.
const Direction = preload("res://scripts/raven/onoe_visual.gd")
const SHEET = preload("res://assets/raven/chibi/evelyn/g1_candidate/repair_v1/evelyn_walk.png")
const META_PATH := "res://assets/raven/chibi/evelyn/g1_candidate/repair_v1/frames.json"
const NATIVE_HEIGHT := 448.0
const IDLE_FRAME := 1
var _sprite: AnimatedSprite2D
var _height := 62.0
var _reduced := false
var _walking := false
var _phase := 0.25
var _meta: Dictionary

func _ready() -> void:
	_meta = JSON.parse_string(FileAccess.get_file_as_string(META_PATH))
	_sprite = AnimatedSprite2D.new()
	_sprite.name = "AnimatedSprite2D"
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for row in range(3):
		var clip: String = ["down", "up", "side"][row]
		frames.add_animation(clip)
		for column in range(4):
			var texture := AtlasTexture.new()
			texture.atlas = SHEET
			texture.region = Rect2(column * 256, row * 512, 256, 512)
			texture.filter_clip = true
			frames.add_frame(clip, texture)
	_sprite.sprite_frames = frames
	_sprite.animation = "down"
	add_child(_sprite)
	set_display_height(_height)
	set_idle()

func get_sprite() -> AnimatedSprite2D:
	return _sprite

func set_display_height(pixels: float) -> void:
	if not is_finite(pixels) or pixels <= 0.0:
		return
	_height = pixels
	if is_instance_valid(_sprite):
		# Fixed scale/pivot across all twelve baked cells; no frame callback.
		_sprite.scale = Vector2.ONE * (_height / NATIVE_HEIGHT)
		_sprite.position = Vector2(0, -224) * _sprite.scale

func display_height() -> float:
	return _height

func cycle_distance() -> float:
	return _height * float(_meta.cycleTravelInHeights)

func phase() -> float:
	return _phase

func face(direction: Vector2) -> void:
	if not direction.is_finite() or direction.length_squared() <= 0.0001:
		return
	_walking = true
	# Reuse Raven facing, then hold engine playback. ONLY actual root travel
	# advances the phase, including low speed, pause and endpoint clamp.
	Direction.play_sprite_direction(_sprite, direction)
	_sprite.pause()
	_apply_phase()

func travel(distance_px: float) -> void:
	if not _walking or not is_finite(distance_px) or distance_px <= 0.0:
		return
	_phase = fposmod(_phase + distance_px / cycle_distance(), 1.0)
	_apply_phase()

func set_idle() -> void:
	_walking = false
	_sprite.pause()
	_sprite.frame = IDLE_FRAME

func set_reduced_motion(enabled: bool) -> void:
	_reduced = enabled
	_apply_phase()

func _apply_phase() -> void:
	_sprite.frame = int(floor(_phase * 4.0)) % 4 if _walking and not _reduced else IDLE_FRAME
