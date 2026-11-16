extends "res://scripts/raven/onoe_segment_mover.gd"

const EvelynVisual = preload("res://assets/raven/chibi/evelyn/g1_candidate/repair_v1/evelyn_visual.gd")

func _ready() -> void:
	_visual = EvelynVisual.new()
	_visual.name = "EvelynVisual"
	add_child(_visual)
	_visual.set_display_height(sprite_height)
	_visual.set_ground_speed(move_speed)

func start_segment(segment: Dictionary) -> bool:
	# Reuse the original mover; adjust candidate animation cadence only.
	var started: bool = super.start_segment(segment)
	if started:
		_visual.set_ground_speed(move_speed)
	return started
