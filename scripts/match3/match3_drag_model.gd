extends RefCounted
## Extracted from UPDS-godot scripts/match3/match3_screen.gd
## original blob 76b42df35d4857f242d3f6bc06b9f989d43ad0a3:
## _update_tile_drag, _end_tile_drag and _drag_neighbour.
## Pure coordinate model; the host chooses touch/mouse event lifecycle and
## asks its actual UPDS game which cells are active.
const COMMIT_THRESHOLD := 0.24
const PREVIEW_THRESHOLD := 0.035
const AXIS_RATIO := 1.08


static func direction(delta: Vector2) -> String:
	var horizontal := absf(delta.x)
	var vertical := absf(delta.y)
	if horizontal >= vertical * AXIS_RATIO and horizontal > 0.0:
		return "left" if delta.x < 0.0 else "right"
	if vertical >= horizontal * AXIS_RATIO and vertical > 0.0:
		return "up" if delta.y < 0.0 else "down"
	return ""


static func neighbour(index: int, direction_key: String, columns: int, rows: int, active: Callable) -> int:
	if direction_key.is_empty() or columns < 1 or rows < 1:
		return -1
	var row := int(index / columns)
	var column := index % columns
	if index < 0 or row >= rows:
		return -1
	if direction_key == "left":
		column -= 1
	elif direction_key == "right":
		column += 1
	elif direction_key == "up":
		row -= 1
	elif direction_key == "down":
		row += 1
	else:
		return -1
	if row < 0 or row >= rows or column < 0 or column >= columns:
		return -1
	var target := row * columns + column
	return target if bool(active.call(target)) else -1


static func target_for_drag(index: int, delta: Vector2, cell_size: float, columns: int, rows: int, active: Callable) -> int:
	if maxf(absf(delta.x), absf(delta.y)) < maxf(1.0, cell_size) * COMMIT_THRESHOLD:
		return -1
	return neighbour(index, direction(delta), columns, rows, active)


static func preview_target(index: int, delta: Vector2, cell_size: float, columns: int, rows: int, active: Callable) -> int:
	if maxf(absf(delta.x), absf(delta.y)) < maxf(1.0, cell_size) * PREVIEW_THRESHOLD:
		return -1
	return neighbour(index, direction(delta), columns, rows, active)
