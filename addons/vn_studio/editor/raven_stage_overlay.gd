@tool
extends Control
## Editor-only overlay. 390x844 logical reference from project.godot; never exported to game saves.
var reference_size: Vector2 = Vector2(390, 844)
var show_safe: bool = false
var focal: Vector2 = Vector2(0.5, 0.5)
var show_grid: bool = false
var show_vn: bool = false
var speaker: String = ""
var dialogue: String = ""
var line_id: String = ""

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_preview(next_speaker: String, next_dialogue: String, next_id: String) -> void:
	speaker = next_speaker
	dialogue = next_dialogue
	line_id = next_id
	queue_redraw()

func _draw() -> void:
	if size.x < 1 or size.y < 1:
		return
	var font: Font = ThemeDB.fallback_font
	if show_grid:
		var grid_color := Color(0.92, 0.90, 0.75, 0.29)
		for x in range(0, int(reference_size.x) + 1, 65):
			var px: float = size.x * float(x) / reference_size.x
			draw_line(Vector2(px, 0), Vector2(px, size.y), grid_color, 1.0)
			draw_string(font, Vector2(px + 3, 14), str(x), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)
		for y in range(0, int(reference_size.y) + 1, 65):
			var py: float = size.y * float(y) / reference_size.y
			draw_line(Vector2(0, py), Vector2(size.x, py), grid_color, 1.0)
			draw_string(font, Vector2(3, py + 12), str(y), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)
		draw_string(font, Vector2(7, size.y - 7), "%d x %d logical px" % [int(reference_size.x), int(reference_size.y)], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)
	if show_safe:
		var margin: Vector2 = size * Vector2(0.05, 0.05)
		draw_rect(Rect2(margin, size - margin * 2.0), Color(0.5, 0.91, 0.74, 0.68), false, 2.0)
		draw_string(font, margin + Vector2(5, 14), "SAFE · editor guide", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.83, 1.0, 0.84))
	# Persisted v2 focal is a guide, never a camera instruction to runtime.
	var f: Vector2 = size * focal
	draw_line(f - Vector2(9, 0), f + Vector2(9, 0), Color(0.98, 0.71, 0.33), 2)
	draw_line(f - Vector2(0, 9), f + Vector2(0, 9), Color(0.98, 0.71, 0.33), 2)
	if show_vn:
		var h: float = size.y * 0.28
		var top: float = size.y - h
		draw_rect(Rect2(0, top, size.x, h), Color(0.11, 0.075, 0.16, 0.87))
		draw_rect(Rect2(0, top, size.x, 2), Color(0.76, 0.65, 0.50, 0.94))
		draw_string(font, Vector2(12, top + 23), speaker if not speaker.is_empty() else "Narrator",
			HORIZONTAL_ALIGNMENT_LEFT, size.x - 24, 16, Color(1, 0.89, 0.75))
		draw_multiline_string(font, Vector2(12, top + 51), dialogue, HORIZONTAL_ALIGNMENT_LEFT,
			maxf(size.x - 24, 40), 14, 4, Color.WHITE)
		draw_string(font, Vector2(12, size.y - 11), line_id, HORIZONTAL_ALIGNMENT_LEFT,
			maxf(size.x - 24, 40), 10, Color(0.8, 0.77, 0.72))
