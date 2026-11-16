extends "res://scripts/raven/onoe_segment_mover.gd"

const EvelynVisual = preload("res://assets/raven/chibi/evelyn/g1_candidate/repair_v1/evelyn_visual.gd")

func _ready() -> void:
	_visual = EvelynVisual.new()
	_visual.name = "EvelynVisual"
	add_child(_visual)
	_visual.set_display_height(sprite_height)

func advance(delta: float) -> void:
	var before := position
	# Parent owns validation, position, pause, endpoint clamp and arrival signals.
	super.advance(delta)
	var traveled := before.distance_to(position)
	if traveled > 0.0 and is_instance_valid(_visual):
		_visual.travel(traveled)
