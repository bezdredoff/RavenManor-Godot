extends Node2D

## Onoe's technical sprite set, extracted from Hall and Whole Manor greyboxes.
## Node2D.position is the FEET / floor-contact position in its parent's space.
## The image is already painted; this script never projects or moves the root.
const WALK = preload("res://assets/prototypes/onoe/onoe_walk_sheet_v1.png")
const SIDE = preload("res://assets/prototypes/onoe/onoe_side_walk_v2.png")

var _sprite: AnimatedSprite2D
var _height_px: float = 104.0


static func build_sprite_frames() -> SpriteFrames:
	var result := SpriteFrames.new()
	result.remove_animation("default")
	for clip in [["down", 0], ["up", 3]]:
		result.add_animation(str(clip[0]))
		result.set_animation_speed(str(clip[0]), 7.0)
		result.set_animation_loop(str(clip[0]), true)
		for column in range(4):
			var atlas := AtlasTexture.new()
			atlas.atlas = WALK
			atlas.region = Rect2(column * 256, int(clip[1]) * 384, 256, 384)
			result.add_frame(str(clip[0]), atlas)
	result.add_animation("side")
	result.set_animation_speed("side", 10.0)
	result.set_animation_loop("side", true)
	for column in range(8):
		var atlas := AtlasTexture.new()
		atlas.atlas = SIDE
		atlas.region = Rect2(column * 272, 0, 272, 724)
		result.add_frame("side", atlas)
	return result


static func play_sprite_direction(target: AnimatedSprite2D, direction: Vector2) -> void:
	if target == null or direction.length_squared() <= 0.0001:
		return
	var clip := "side" if absf(direction.x) > absf(direction.y) else ("down" if direction.y > 0.0 else "up")
	if target.animation != clip:
		target.animation = clip
	target.flip_h = clip == "side" and direction.x < 0.0
	if not target.is_playing():
		target.play()


func _ready() -> void:
	_sprite = AnimatedSprite2D.new()
	_sprite.name = "AnimatedSprite2D"
	_sprite.sprite_frames = build_sprite_frames()
	_sprite.animation = "down"
	add_child(_sprite)
	set_idle()
	_apply_footpoint()


func get_sprite() -> AnimatedSprite2D:
	return _sprite


func set_display_height(pixels: float) -> void:
	if not is_finite(pixels) or pixels <= 0.0:
		return
	_height_px = pixels
	if is_instance_valid(_sprite):
		_apply_footpoint()


func display_height() -> float:
	return _height_px


func face(direction: Vector2) -> void:
	if direction.length_squared() <= 0.0001 or not is_instance_valid(_sprite):
		return
	play_sprite_direction(_sprite, direction)
	_apply_footpoint()


func set_idle() -> void:
	if not is_instance_valid(_sprite):
		return
	_sprite.stop()
	_sprite.frame = 0
	_apply_footpoint()


func _apply_footpoint() -> void:
	if not is_instance_valid(_sprite):
		return
	# Both clips have different native heights; the floor-contact y stays 0.
	var native_height := 724.0 if _sprite.animation == "side" else 384.0
	_sprite.scale = Vector2.ONE * (_height_px / native_height)
	_sprite.position = Vector2(0.0, -_height_px * 0.5)
