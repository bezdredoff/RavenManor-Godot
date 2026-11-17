extends Node2D
## Candidate masks over the immutable approved painting. No added floor tiles.
## The only architectural addition is the HC wall joining the two painted ends.
@export var foreground := false

const ORIGINAL = preload("res://a_detailed_top_down_isometric_game_map_illustratio.png")
const HC_WALL := Rect2(764, 398, 134, 26)
const HC_WALL_SOURCE := Rect2(675, 398, 80, 26)

func _draw() -> void:
	if foreground:
		_foreground_hc()
		_foreground_cb()
	else:
		_join_hc_wall()

func _source_patch(destination: Rect2, source: Rect2) -> void:
	draw_texture_rect_region(ORIGINAL, destination, source)

func _join_hc_wall() -> void:
	# Continue the adjacent horizontal wall above the under-stair passage.
	# Reuse the same painting's trim; leave all original ground below untouched.
	_source_patch(HC_WALL, HC_WALL_SOURCE)

func _foreground_hc() -> void:
	# The joined wall and original raised landing occlude a ground-level walker.
	# No parquet rectangle, hanging side rails or invented southern lintel.
	_join_hc_wall()
	_source_patch(Rect2(748, 424, 160, 56), Rect2(748, 424, 160, 56))

func _foreground_cb() -> void:
	# Preserve the original partition AND its golden door exactly where painted.
	# Evelyn passes behind this wall/door instead of through a new floor strip.
	_source_patch(Rect2(516, 280, 24, 132), Rect2(516, 280, 24, 132))
