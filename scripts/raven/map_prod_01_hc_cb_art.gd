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

func _parquet(rect: Rect2) -> void:
	# A small source floor patch avoids accidentally sampling the dark east wall.
	for y in range(int(rect.position.y), int(rect.end.y), 16):
		var height := minf(16.0, rect.end.y - y)
		_source_patch(Rect2(rect.position.x, y, rect.size.x, height), Rect2(904, 640, rect.size.x, height))


func _hc_passage() -> void:
	# Ground-level tunnel continues below the elevated central landing.
	# The actual landing is restored in foreground, never painted as walkable floor.
	_parquet(Rect2(800, 388, 48, 148))
	_box(800, 400, 4, 136, Color("#17131c", 0.45))
	_box(844, 400, 4, 136, Color("#17131c", 0.45))
	_box(794, 477, 6, 59, WOOD)
	_box(848, 477, 6, 59, WOOD)
	_box(798, 478, 2, 57, BRASS)
	_box(848, 478, 2, 57, BRASS)
	_box(804, 480, 40, 24, Color("#15101c", 0.36))


func _cb_passage() -> void:
	# 48px ground opening y352..400, plus the painted wall's vertical rise.
	# Clearing only the feet window left Evelyn's head inside the original wall.
	_parquet(Rect2(520, 290, 16, 110))
	_box(520, 290, 16, 110, Color("#493223", 0.12))
	_box(516, 290, 4, 110, WOOD)
	_box(536, 290, 4, 110, WOOD)
	_line(Vector2(521,398), Vector2(535,398), LIMESTONE_LIGHT, 2.0)


func _foreground_hc() -> void:
	# Preserve the real raised landing over the tunnel. A walker passes behind
	# its full painted mass, with the same mask on both directions of travel.
	_source_patch(Rect2(800, 422, 48, 58), Rect2(800, 422, 48, 58))
	_source_patch(Rect2(748, 381, 52, 99), Rect2(748, 381, 52, 99))
	_source_patch(Rect2(848, 381, 60, 99), Rect2(848, 381, 60, 99))
	_box(800, 477, 48, 5, WOOD)
	_line(Vector2(800,478), Vector2(848,478), BRASS, 1.0)


func _foreground_cb() -> void:
	# Full-height near jamb occludes the body as it crosses the partition.
	# A cap across the feet window was an incorrect one-dimensional mask.
	_source_patch(Rect2(516, 280, 24, 10), Rect2(516, 280, 24, 10))
	_source_patch(Rect2(516, 400, 24, 12), Rect2(516, 400, 24, 12))
	_box(536, 290, 4, 110, WOOD)
	_line(Vector2(536,292), Vector2(536,399), LIMESTONE_LIGHT, 1.5)

