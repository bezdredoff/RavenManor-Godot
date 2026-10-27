extends RefCounted
## Pure sizing policy used by Raven Match-3 HUD and native safe-area shell.
## Explicitly avoids hard-coded minimum widths that overflow narrow phones.
const MIN_TAP := 44.0
const CELL_GAP := 3.0
const CELL_MAX := 50.0
const BASE_GUTTER := 14.0


static func content_width(viewport_width: float, left_inset: float = 0.0, right_inset: float = 0.0) -> float:
	return maxf(1.0, viewport_width - 2.0 * BASE_GUTTER - maxf(0.0, left_inset) - maxf(0.0, right_inset))


static func tile_size(available_width: float, columns: int) -> float:
	if columns <= 0:
		return 0.0
	return maxf(1.0, floorf(minf(CELL_MAX, (maxf(1.0, available_width) - CELL_GAP * float(columns - 1)) / float(columns))))


static func board_extent(cell_width: float, columns: int, rows: int) -> Vector2:
	if columns <= 0 or rows <= 0:
		return Vector2.ZERO
	return Vector2(
		cell_width * float(columns) + CELL_GAP * float(columns - 1),
		cell_width * float(rows) + CELL_GAP * float(rows - 1)
	)


static func native_safe_insets(viewport_size: Vector2, physical_screen: Vector2i, safe_rect: Rect2i) -> Vector4:
	# Real mobile pixels can be 2x/3x the Godot logical viewport. Only
	# convert a valid rect within the physical screen; skip desktop/web fallbacks.
	if viewport_size.x <= 0 or viewport_size.y <= 0 or physical_screen.x <= 0 or physical_screen.y <= 0:
		return Vector4.ZERO
	if safe_rect.size.x <= 0 or safe_rect.size.y <= 0 or safe_rect.position.x < 0 or safe_rect.position.y < 0:
		return Vector4.ZERO
	if safe_rect.end.x > physical_screen.x or safe_rect.end.y > physical_screen.y:
		return Vector4.ZERO
	var scale_x := viewport_size.x / float(physical_screen.x)
	var scale_y := viewport_size.y / float(physical_screen.y)
	return Vector4(
		float(safe_rect.position.x) * scale_x,
		float(safe_rect.position.y) * scale_y,
		float(physical_screen.x - safe_rect.end.x) * scale_x,
		float(physical_screen.y - safe_rect.end.y) * scale_y
	)


static func gutter(base: float, inset: float) -> int:
	return ceili(maxf(0.0, base) + maxf(0.0, inset))
