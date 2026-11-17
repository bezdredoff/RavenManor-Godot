extends Node2D
## MAP-PROD-01 in-engine composite over the SHA-pinned original painting.
## Geometry is rendered, not an SVG plan. Foreground replicates the immutable
## painting wherever possible, so Evelyn is occluded without opaque QA slabs.
@export var foreground := false

const ORIGINAL = preload("res://a_detailed_top_down_isometric_game_map_illustratio.png")
const DARK := Color("#211b20")
const SHADOW := Color("#121017")
const LIMESTONE := Color("#b3a18b")
const LIMESTONE_LIGHT := Color("#d8c4a3")
const WOOD := Color("#412c24")
const BRASS := Color("#b99555")
const BRASS_LIGHT := Color("#dec184")

func _draw() -> void:
	if foreground:
		_foreground_hc()
		_foreground_cb()
	else:
		_hc_passage()
		_cb_passage()

func _box(x: float, y: float, w: float, h: float, color: Color) -> void:
	draw_rect(Rect2(x, y, w, h), color, true)

func _line(a: Vector2, b: Vector2, color: Color, width: float = 1.0) -> void:
	draw_line(a, b, color, width, true)

func _source_patch(destination: Rect2, source: Rect2) -> void:
	# Texture reuse is strictly local within the same immutable approved map,
	# using its real painted parquet rather than flat solid-color fill.
	draw_texture_rect_region(ORIGINAL, destination, source)

func _hc_passage() -> void:
	# The approved corridor and stair balustrades stay visible. Only the
	# previously unsupported central ground-level stairwell is resurfaced.
	# This is a slender physically continuous 48px underpass, not a 2D bridge.
	_source_patch(Rect2(800, 414, 48, 122), Rect2(1040, 650, 48, 122))
	# Soft shadow along two retaining sidewalls frames floor continuity.
	_box(800, 414, 4, 122, Color("#1e181c", 0.70))
	_box(844, 414, 4, 122, Color("#1e181c", 0.70))
	_box(804, 414, 40, 4, Color("#12121b", 0.70))
	_line(Vector2(804,426), Vector2(844,426), Color("#c0aa86", 0.55), 1.2)
	_line(Vector2(804,531), Vector2(844,531), Color("#c0aa86", 0.24), 1.0)
	# Under-landing portal reads as a recessed, dark architectural aperture.
	# Narrow wooden piers preserve the 48px nominal feet window x800..848.
	_box(794, 387, 6, 36, WOOD)
	_box(848, 387, 6, 36, WOOD)
	_box(797, 389, 2, 31, BRASS)
	_box(849, 389, 2, 31, BRASS)
	_box(800, 385, 48, 6, Color("#1a1318", 0.89))
	_line(Vector2(800,386), Vector2(848,386), LIMESTONE, 2.0)
	_line(Vector2(800,416), Vector2(848,416), BRASS_LIGHT, 2.0)
	# Cast shadow under landing, rather than drawing a second projection.
	draw_colored_polygon(PackedVector2Array([
		Vector2(800,392),Vector2(848,392),Vector2(848,427),
		Vector2(841,440),Vector2(807,440),Vector2(800,427)
	]), Color("#101319",0.20))

func _cb_passage() -> void:
	# Bedroom wall is only 16px across (x520..536); do not obscure the
	# existing burgundy rug and parquet with an 88px greybox rectangle.
	_source_patch(Rect2(520, 352, 16, 48), Rect2(505, 354, 16, 48))
	_box(520, 352, 16, 48, Color("#493223", 0.18))
	# Correctly cut narrow jambs with a visible limestone sill; clear Y352..400.
	_box(516, 352, 4, 48, WOOD)
	_box(536, 352, 4, 48, WOOD)
	_box(519, 354, 1.5, 43, BRASS)
	_box(536, 354, 1.5, 43, BRASS)
	_box(520, 352, 16, 2, LIMESTONE_LIGHT)
	_box(520, 398, 16, 2, LIMESTONE_LIGHT)
	_line(Vector2(521,378), Vector2(535,378), BRASS_LIGHT, 1.0)

func _foreground_hc() -> void:
	# Source-identical stair railings are clipped back in FRONT of Evelyn.
	# They do not alter the painting but correctly obscure the walker.
	_source_patch(Rect2(748, 381, 52, 41), Rect2(748, 381, 52, 41))
	_source_patch(Rect2(848, 381, 60, 41), Rect2(848, 381, 60, 41))
	# Recessed arch rather than flat crossbar across the opening.
	_box(800, 380, 48, 6, Color("#392820", 0.98))
	_line(Vector2(800,381), Vector2(848,381), LIMESTONE_LIGHT, 2.0)
	_line(Vector2(800,385), Vector2(848,385), BRASS, 1.0)
	_box(800, 386, 4, 11, Color("#211b20",0.93))
	_box(844, 386, 4, 11, Color("#211b20",0.93))

func _foreground_cb() -> void:
	# Keep image-derived partition lip in front of head/shoulder as Evelyn
	# walks through: clone only wall trim, not the neighboring room floor.
	_source_patch(Rect2(516, 342, 24, 10), Rect2(516, 342, 24, 10))
	_source_patch(Rect2(516, 400, 24, 9), Rect2(516, 400, 24, 9))
	_line(Vector2(516,351), Vector2(540,351), LIMESTONE_LIGHT, 2.0)
	_line(Vector2(516,402), Vector2(540,402), BRASS, 1.5)
