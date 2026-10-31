@tool
extends Control
## Editor-only overlay. 390x844 logical reference from project.godot; never exported to game saves.
const REFERENCE := Vector2(390, 844)
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
		for x in range(0, 391, 65):
			var px: float = size.x * float(x) / REFERENCE.x
			draw_line(Vector2(px, 0), Vector2(px, size.y), grid_color, 1.0)
			draw_string(font, Vector2(px + 3, 14), str(x), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)
		for y in range(0, 845, 100):
			var py: float = size.y * float(y) / REFERENCE.y
			draw_line(Vector2(0, py), Vector2(size.x, py), grid_color, 1.0)
			draw_string(font, Vector2(3, py + 12), str(y), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)
		draw_string(font, Vector2(7, size.y - 7), "390 x 844 logical px", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)
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
