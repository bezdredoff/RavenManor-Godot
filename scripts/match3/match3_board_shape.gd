extends Control

var rows := 0
var columns := 0
var holes: PackedInt32Array = PackedInt32Array()
var draw_fill := false
var fill_color := Color("#24335466")


func configure(next_rows: int, next_columns: int, next_holes: Array, fill_enabled: bool) -> void:
	rows = next_rows
	columns = next_columns
	holes.clear()
	for hole: Variant in next_holes:
		holes.append(int(hole))
	draw_fill = fill_enabled
	queue_redraw()


func _draw() -> void:
	if rows <= 0 or columns <= 0 or holes.is_empty() or size.x <= 6.0 or size.y <= 6.0:
		return
	var gap := 1.0
	var cell_width := (size.x - float(columns - 1) * gap) / float(columns)
	var cell_height := (size.y - float(rows - 1) * gap) / float(rows)
	var origin := Vector2.ZERO
	if draw_fill:
		for row in rows:
			var column := 0
			while column < columns:
				while column < columns and _is_hole(row * columns + column):
					column += 1
				var start := column
				while column < columns and not _is_hole(row * columns + column):
					column += 1
				if column > start:
					var width := float(column - start) * cell_width + float(column - start - 1) * gap
					var position := origin + Vector2(float(start) * (cell_width + gap), float(row) * (cell_height + gap))
					# Match the translucent backing used by regular board cells. An
					# opaque shape fill makes irregular boards look like a blue card.
					draw_rect(Rect2(position, Vector2(width, cell_height)), fill_color, true)
		return
	var line_width := minf(cell_width, cell_height) * 0.065
	var outline_color := Color("#f3e4bc")
	for row in rows:
		for column in columns:
			var index := row * columns + column
			if _is_hole(index):
				continue
			var left := origin.x + float(column) * (cell_width + gap)
			var top := origin.y + float(row) * (cell_height + gap)
			var right := left + cell_width
			var bottom := top + cell_height
			if row == 0 or _is_hole(index - columns):
				draw_line(Vector2(left, top), Vector2(right, top), outline_color, line_width, true)
			if column == columns - 1 or _is_hole(index + 1):
				draw_line(Vector2(right, top), Vector2(right, bottom), outline_color, line_width, true)
			if row == rows - 1 or _is_hole(index + columns):
				draw_line(Vector2(right, bottom), Vector2(left, bottom), outline_color, line_width, true)
			if column == 0 or _is_hole(index - 1):
				draw_line(Vector2(left, bottom), Vector2(left, top), outline_color, line_width, true)


func _is_hole(index: int) -> bool:
	return holes.has(index)
