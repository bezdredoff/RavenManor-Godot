extends Node2D
## MAP-PROD-01. Native Godot 2D painted patch; independent of immutable source PNG.
## Real CanvasItem artwork (not a wireframe/SVG); separate foreground pass.
@export var foreground := false

const DARK := Color("#211b20")
const SHADOW := Color("#0b1418")
const LIMESTONE := Color("#a99982")
const LIMESTONE_LIGHT := Color("#d2bea0")
const WOOD := Color("#483329")
const WOOD_LIGHT := Color("#694734")
const BRASS := Color("#b99555")
const BRASS_LIGHT := Color("#ddbc7d")

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

func _hc_passage() -> void:
	# Existing stair riser is deliberately overpainted with a continuous lower
	# floor. The passage remains only 48 image pixels wide (x800..848).
	_box(800, 376, 48, 160, LIMESTONE)
	_box(801, 396, 46, 139, WOOD)
	for y in range(405, 536, 15):
		_line(Vector2(802,y), Vector2(846,y), Color("#70513a",0.60), 1.5)
		_line(Vector2(803,y+2), Vector2(845,y+2), Color("#211c1a",0.32))
	_box(804, 385, 40, 40, SHADOW)
	draw_colored_polygon(PackedVector2Array([
		Vector2(804,389),Vector2(810,378),Vector2(838,378),
		Vector2(844,389),Vector2(844,415),Vector2(804,415)
	]), Color("#162024"))
	_box(807, 408, 34, 17, Color("#4a3227"))
	_box(802, 420, 44, 7, Color("#7e6549"))
	_box(802, 431, 44, 3, Color("#b29a7b", 0.65))
	# Wood + brass structural jambs keep the central 48px clearance.
	_box(793, 386, 7, 45, DARK)
	_box(848, 386, 7, 45, DARK)
	_box(797, 392, 3, 39, WOOD_LIGHT)
	_box(848, 392, 3, 39, WOOD_LIGHT)
	_line(Vector2(796,390), Vector2(796,418), BRASS, 1.5)
	_line(Vector2(852,390), Vector2(852,418), BRASS, 1.5)
	_box(800, 414, 48, 3, BRASS)
	_box(802, 418, 44, 2, BRASS_LIGHT)
	# Falling landing shadow conveys headroom without perspective reprojection.
	draw_colored_polygon(PackedVector2Array([
		Vector2(800,388),Vector2(848,388),Vector2(848,421),
		Vector2(838,439),Vector2(810,439),Vector2(800,421)
	]), Color("#0c1016",0.27))

func _cb_passage() -> void:
	# Actual 88x48 floor backfill repaints the partition across x520..536.
	_box(480, 352, 88, 48, WOOD)
	_box(482, 354, 84, 44, Color("#644831"))
	for y in range(357, 400, 8):
		_line(Vector2(482,y), Vector2(566,y), Color("#8c6245",0.58))
	_box(520, 352, 16, 48, Color("#947858"))
	_box(522, 354, 12, 44, Color("#67513c"))
	_box(520, 367, 16, 2, BRASS)
	_box(520, 392, 16, 2, BRASS_LIGHT)
	# Side jambs face west/east; y352..400 remains unobstructed at y376.
	_box(517, 351, 3, 49, DARK)
	_box(536, 351, 3, 49, DARK)
	_line(Vector2(519,355),Vector2(519,396),BRASS,1.5)
	_line(Vector2(537,355),Vector2(537,396),BRASS,1.5)
	_box(516, 348, 24, 4, WOOD_LIGHT)
	_box(516, 400, 24, 5, WOOD_LIGHT)
	_box(516, 350, 24, 2, BRASS)
	_box(516, 402, 24, 1, BRASS)

func _foreground_hc() -> void:
	# Opaque landing flanks and balustrade pass IN FRONT of Evelyn (z=12).
	# A clear 48px opening is maintained at x800..848.
	draw_colored_polygon(PackedVector2Array([
		Vector2(748,382),Vector2(800,382),Vector2(800,419),
		Vector2(753,419)
	]), WOOD)
	draw_colored_polygon(PackedVector2Array([
		Vector2(848,382),Vector2(907,382),Vector2(904,419),
		Vector2(848,419)
	]), WOOD)
	for x in [756, 772, 788, 858, 874, 890]:
		_box(x, 384, 4, 33, DARK)
		_box(x+1, 385, 1.5, 31, BRASS)
	_line(Vector2(748,381),Vector2(800,381),LIMESTONE_LIGHT,4)
	_line(Vector2(848,381),Vector2(908,381),LIMESTONE_LIGHT,4)
	_line(Vector2(748,413),Vector2(800,413),BRASS,2)
	_line(Vector2(848,413),Vector2(906,413),BRASS,2)
	# A narrow lintel hides head/shoulder at the depth break.
	_box(800, 379, 48, 8, WOOD)
	_box(801, 379, 46, 2, LIMESTONE_LIGHT)
	_box(807, 387, 34, 3, Color("#100f14", 0.82))

func _foreground_cb() -> void:
	# Partition wall caps, clipped above/below the 48px clear door aperture.
	_box(515, 342, 26, 10, DARK)
	_box(516, 344, 24, 5, WOOD_LIGHT)
	_box(517, 347, 22, 2, BRASS_LIGHT)
	_box(515, 400, 26, 9, DARK)
	_box(516, 400, 24, 4, WOOD_LIGHT)
	_box(517, 400, 22, 2, BRASS)
