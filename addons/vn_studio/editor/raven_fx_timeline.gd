@tool
extends Control
## VNS5-07F5: editor-only 20-second visual cue lanes and scrub.
## All coordinates are screen pixels; only validated startMs is saved.
signal cue_selected(index: int)
signal time_scrubbed(time_ms: int)
signal cue_moved(index: int, start_ms: int)

const StageFx = preload("res://addons/vn_studio/model/stage_fx_store.gd")
const LEFT := 104.0
const RIGHT := 14.0
const TOP := 34.0
const LANE_HEIGHT := 48.0
const BAR_HEIGHT := 22.0
const SNAP_MS := 50
const COLORS := {
	"enter": Color(0.30, 0.68, 0.92),
	"idle": Color(0.44, 0.79, 0.55),
	"exit": Color(0.96, 0.59, 0.32)
}

var _cues: Array = []
var _selected: int = -1
var _time_ms: int = 0
var _line_id: String = ""
var _press_index: int = -1
var _press_x: float = 0.0
var _start_before_drag: int = 0
var _dragged: bool = false


func _ready() -> void:
	custom_minimum_size = Vector2(340, 202)
	size_flags_horizontal = SIZE_EXPAND_FILL
	mouse_filter = MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	tooltip_text = "Клик: выбрать FX; перетащить: сдвинуть начало; ←/→: шаг 50 мс; клик по шкале: scrub"
	queue_redraw()


func set_timeline(cues: Array, selected_index: int, time_ms: int, line_id: String) -> void:
	_cues = cues.duplicate(true)
	_selected = selected_index
	_time_ms = clampi(time_ms, 0, StageFx.MAX_MS)
	_line_id = line_id
	queue_redraw()


func _plot_width() -> float:
	return maxf(1.0, size.x - LEFT - RIGHT)


func _x_for_time(time_ms: int) -> float:
	return LEFT + clampf(float(time_ms) / float(StageFx.MAX_MS), 0.0, 1.0) * _plot_width()


func _time_for_x(x: float) -> int:
	return clampi(roundi((x - LEFT) / _plot_width() * float(StageFx.MAX_MS) / SNAP_MS) * SNAP_MS,
		0, StageFx.MAX_MS)


func _lane_for(cue: Dictionary) -> int:
	return maxi(0, StageFx.PHASES.find(StageFx.phase_of(cue)))


func _bar_rect(cue: Dictionary) -> Rect2:
	var start: int = int(cue.get("startMs", 0))
	var end: int = StageFx.MAX_MS if cue.get("loop", false) else start + int(cue.get("durationMs", 1400)) * int(cue.get("repeat", 1))
	var lane: int = _lane_for(cue)
	return Rect2(Vector2(_x_for_time(start), TOP + lane * LANE_HEIGHT + 8.0),
		Vector2(maxf(3.0, _x_for_time(end) - _x_for_time(start)), BAR_HEIGHT))


func _hit_cue(where: Vector2) -> int:
	# Last rendered cue takes precedence on overlapping bars; the linked list
	# still allows selecting any exact ID in overlapping lanes.
	for index in range(_cues.size() - 1, -1, -1):
		var cue: Dictionary = _cues[index]
		if StageFx.visible_for_line(cue, _line_id) and _bar_rect(cue).has_point(where):
			return index
	return -1


func _gui_input(event: InputEvent) -> void:
	# Timeline is focusable, so allow precise cue adjustments without mouse
	# dragging. Share the same bounds and StageDesigner commit/Undo signal.
	if event is InputEventKey:
		var key: InputEventKey = event
		if not key.pressed or key.echo or key.ctrl_pressed or key.alt_pressed or key.meta_pressed:
			return
		if key.keycode != KEY_LEFT and key.keycode != KEY_RIGHT:
			return
		if _selected < 0 or _selected >= _cues.size():
			return
		var cue: Dictionary = _cues[_selected]
		var start: int = int(cue.get("startMs", 0))
		var length: int = int(cue.get("durationMs", 1400)) * int(cue.get("repeat", 1))
		var maximum: int = mini(15000, StageFx.MAX_MS - length)
		var step: int = SNAP_MS if key.keycode == KEY_RIGHT else -SNAP_MS
		var next_start: int = clampi(start + step, 0, maxi(0, maximum))
		if next_start != start:
			cue_moved.emit(_selected, next_start)
		accept_event()
		return
	if event is InputEventMouseButton:
		var mouse: InputEventMouseButton = event
		if mouse.button_index != MOUSE_BUTTON_LEFT:
			return
		if mouse.pressed:
			_press_index = _hit_cue(mouse.position)
			_press_x = mouse.position.x
			_dragged = false
			if _press_index >= 0:
				_start_before_drag = int(_cues[_press_index].get("startMs", 0))
				cue_selected.emit(_press_index)
			elif mouse.position.x >= LEFT:
				time_scrubbed.emit(_time_for_x(mouse.position.x))
			accept_event()
		else:
			if _press_index >= 0 and _dragged:
				var shift: int = _time_for_x(mouse.position.x) - _time_for_x(_press_x)
				var cue: Dictionary = _cues[_press_index]
				var length: int = int(cue.get("durationMs", 1400)) * int(cue.get("repeat", 1))
				var maximum: int = mini(15000, StageFx.MAX_MS - length)
				cue_moved.emit(_press_index, clampi(_start_before_drag + shift, 0, maxi(0, maximum)))
			_press_index = -1
			_dragged = false
			accept_event()
	elif event is InputEventMouseMotion and _press_index >= 0:
		var motion: InputEventMouseMotion = event
		if absf(motion.position.x - _press_x) >= 4.0:
			_dragged = true
		accept_event()


func _draw() -> void:
	var font: Font = get_theme_default_font()
	var plot: float = _plot_width()
	var line_colors: Array[Color] = [
		Color(0.30, 0.68, 0.92, 0.16),
		Color(0.44, 0.79, 0.55, 0.16),
		Color(0.96, 0.59, 0.32, 0.16)
	]
	for lane in range(3):
		var y: float = TOP + lane * LANE_HEIGHT
		draw_rect(Rect2(LEFT, y, plot, LANE_HEIGHT - 3.0), line_colors[lane], true)
		draw_string(font, Vector2(5, y + 29), ["Вход", "Ожидание", "Выход"][lane],
			HORIZONTAL_ALIGNMENT_LEFT, 95, 13, Color(0.8, 0.83, 0.88))
	for seconds in range(0, 21, 5):
		var x: float = _x_for_time(seconds * 1000)
		draw_line(Vector2(x, TOP - 5), Vector2(x, TOP + 3 * LANE_HEIGHT - 4),
			Color(0.55, 0.60, 0.68, 0.3), 1)
		draw_string(font, Vector2(x + 2, 18), "%ds" % seconds,
			HORIZONTAL_ALIGNMENT_LEFT, 38, 12, Color(0.72, 0.74, 0.78))
	for index in range(_cues.size()):
		var cue: Dictionary = _cues[index]
		var rect: Rect2 = _bar_rect(cue)
		var active: bool = StageFx.visible_for_line(cue, _line_id)
		var color: Color = COLORS.get(StageFx.phase_of(cue), COLORS["idle"])
		if not active:
			color.a = 0.26
		draw_rect(rect, color, true)
		if index == _selected:
			draw_rect(rect.grow(2.0), Color.WHITE, false, 2.0)
		var text: String = str(cue.get("id", "")) + " · " + str(cue.get("effect", "")) + (" ∞" if cue.get("loop", false) else "")
		if rect.size.x >= 65:
			draw_string(font, rect.position + Vector2(4, 15), text,
				HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 6, 12, Color(0.09, 0.11, 0.14))
	var play_x: float = _x_for_time(_time_ms)
	draw_line(Vector2(play_x, TOP - 6), Vector2(play_x, TOP + 3 * LANE_HEIGHT - 2),
		Color(0.98, 0.97, 0.60), 2)
	draw_string(font, Vector2(LEFT, TOP + 3 * LANE_HEIGHT + 18),
		"Оранжевый / синий / зелёный — дорожки FX; серый — другая реплика. Только editor preview.",
		HORIZONTAL_ALIGNMENT_LEFT, size.x - LEFT, 12, Color(0.69, 0.72, 0.77))
