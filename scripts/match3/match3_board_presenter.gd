extends VBoxContainer
## Shared Match-3 board presenter extracted from the UPDS Match3Screen contract.
## Donor: bezdredoff/UPDS-godot scripts/match3/match3_screen.gd
## blob: 76b42df35d4857f242d3f6bc06b9f989d43ad0a3
## Reuses UPDS game frames, board-shape and motion layer unchanged.
## Holds only transient UI; Raven reducer remains the sole campaign authority.
signal level_won
signal board_feedback(message: String)

const Drag = preload("res://scripts/match3/match3_drag_model.gd")
const Shape = preload("res://scripts/match3/match3_board_shape.gd")
const MotionScene = preload("res://scenes/match3_tile_motion_layer.tscn")

var game: RefCounted
var skin: Dictionary = {}
var board_area: Control
var grid: GridContainer
var motion_layer: Control
var outline: Control
var feedback: Label
var objective: Label
var hint_button: Button
var cells: Array[Button] = []
var stacks: Array[Control] = []
var selected_index := -1
var highlighted: Array[int] = []
var input_locked := false
var reduced_motion := false
var _gesture_index := -1
var _gesture_start := Vector2.ZERO
var _gesture_kind := ""
var _gesture_touch := -1
var _last_touch_ms := -10000
var _cell_size := 48.0
var _completed := false


func setup(next_game: RefCounted, theme: Dictionary) -> void:
	game = next_game
	skin = theme.duplicate(true)
	add_theme_constant_override("separation", 8)
	_build()
	_paint_live()


func _build() -> void:
	objective = Label.new()
	objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective.add_theme_color_override("font_color", Color("f0dfbd"))
	add_child(objective)
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(center)
	var cols := int(game.level_data.columns)
	var rows := int(game.level_data.rows)
	_cell_size = minf(50.0, maxf(34.0, (350.0 - float(cols - 1) * 3.0) / float(cols)))
	var extent := Vector2(float(cols) * (_cell_size + 3.0) - 3.0, float(rows) * (_cell_size + 3.0) - 3.0)
	board_area = Control.new()
	board_area.name = "UPDSBoardArea"
	board_area.custom_minimum_size = extent
	board_area.size = extent
	board_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(board_area)

	grid = GridContainer.new()
	grid.name = "BoardGrid"
	grid.columns = cols
	grid.add_theme_constant_override("h_separation", 3)
	grid.add_theme_constant_override("v_separation", 3)
	grid.size = extent
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board_area.add_child(grid)
	for index in cols * rows:
		var cell := Button.new()
		cell.name = "Cell_%d" % index
		cell.focus_mode = Control.FOCUS_NONE
		cell.custom_minimum_size = Vector2(_cell_size, _cell_size)
		cell.mouse_filter = Control.MOUSE_FILTER_STOP
		var style := StyleBoxFlat.new()
		style.bg_color = Color("263044")
		style.set_corner_radius_all(7)
		cell.add_theme_stylebox_override("normal", style)
		cell.add_theme_stylebox_override("hover", style)
		cell.add_theme_stylebox_override("pressed", style)
		grid.add_child(cell)
		var stack := Control.new()
		stack.name = "TileStack"
		stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.add_child(stack)
		stack.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var label := Label.new()
		label.name = "Glyph"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 21)
		label.add_theme_color_override("font_color", Color("15151d"))
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stack.add_child(label)
		label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		cells.append(cell)
		stacks.append(stack)

	outline = Shape.new()
	outline.name = "UPDSBoardShape"
	outline.size = extent
	outline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	outline.z_index = 2
	board_area.add_child(outline)
	outline.configure(rows, cols, game.level_data.get("boardHoles", []), false)
	motion_layer = MotionScene.instantiate() as Control
	motion_layer.name = "UPDSTileMotion"
	motion_layer.size = extent
	motion_layer.z_index = 4
	motion_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board_area.add_child(motion_layer)
	feedback = Label.new()
	feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback.add_theme_color_override("font_color", Color("c0dab7"))
	add_child(feedback)
	hint_button = Button.new()
	hint_button.text = str(skin.get("hint", "Показать подсказку"))
	hint_button.custom_minimum_size.y = 44
	hint_button.pressed.connect(show_hint)
	add_child(hint_button)


func _input(event: InputEvent) -> void:
	if game == null or input_locked or str(game.state) != "playing":
		return
	var position := Vector2.ZERO
	var kind := ""
	var is_press := false
	var is_release := false
	var is_move := false
	var touch_index := -1
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		kind = "mouse"
		position = event.position
		is_press = event.pressed
		is_release = not event.pressed
	elif event is InputEventMouseMotion:
		kind = "mouse"
		position = event.position
		is_move = true
	elif event is InputEventScreenTouch:
		kind = "touch"
		position = event.position
		touch_index = event.index
		is_press = event.pressed
		is_release = not event.pressed
	elif event is InputEventScreenDrag:
		kind = "touch"
		position = event.position
		touch_index = event.index
		is_move = true
	else:
		return
	# On mobile Godot can synthesize mouse events after touch events. Never
	# interpret both streams as two independent tile selections.
	if kind == "touch":
		_last_touch_ms = Time.get_ticks_msec()
	elif Time.get_ticks_msec() - _last_touch_ms < 650:
		return
	if is_press:
		if _gesture_index >= 0 or _gesture_kind == "touch" and kind == "mouse":
			return
		var index := _index_at(position)
		if index < 0 or not game.can_interact_with_tile(index):
			return
		_gesture_index = index
		_gesture_start = position
		_gesture_kind = kind
		_gesture_touch = touch_index
		get_viewport().set_input_as_handled()
	elif _gesture_index >= 0 and kind == _gesture_kind and (kind != "touch" or touch_index == _gesture_touch):
		if is_move:
			var target := Drag.preview_target(_gesture_index, position - _gesture_start, _cell_size, int(game.level_data.columns), int(game.level_data.rows), Callable(game, "_is_active"))
			highlighted = [_gesture_index, target] if target >= 0 else [_gesture_index]
			_paint_selection()
		elif is_release:
			var start := _gesture_index
			var target := Drag.target_for_drag(start, position - _gesture_start, _cell_size, int(game.level_data.columns), int(game.level_data.rows), Callable(game, "_is_active"))
			_gesture_index = -1
			_gesture_kind = ""
			_gesture_touch = -1
			highlighted.clear()
			if target >= 0:
				selected_index = -1
				_commit_swap(start, target)
			else:
				tap_cell(start)
			get_viewport().set_input_as_handled()


func _index_at(position: Vector2) -> int:
	for i in cells.size():
		if cells[i].visible and cells[i].get_global_rect().has_point(position):
			return i
	return -1


func tap_cell(index: int) -> void:
	if input_locked or not game.can_interact_with_tile(index):
		return
	if selected_index < 0:
		selected_index = index
		_paint_selection()
		return
	var first := selected_index
	selected_index = -1
	if first == index:
		if not str(game.specials[index]).is_empty():
			_play_result(game.attempt_special_activation(index), index, index)
		else:
			_paint_selection()
		return
	if Drag.neighbour(first, "left", int(game.level_data.columns), int(game.level_data.rows), Callable(game, "_is_active")) == index or Drag.neighbour(first, "right", int(game.level_data.columns), int(game.level_data.rows), Callable(game, "_is_active")) == index or Drag.neighbour(first, "up", int(game.level_data.columns), int(game.level_data.rows), Callable(game, "_is_active")) == index or Drag.neighbour(first, "down", int(game.level_data.columns), int(game.level_data.rows), Callable(game, "_is_active")) == index:
		_commit_swap(first, index)
	else:
		selected_index = index
		_paint_selection()


func _commit_swap(first: int, second: int) -> void:
	if input_locked:
		return
	_play_result(game.attempt_swap(first, second), first, second)


func show_hint() -> void:
	if input_locked:
		return
	var hint: Dictionary = game.get_hint_move()
	highlighted.clear()
	if hint.is_empty():
		feedback.text = str(skin.get("no_hint", "Нет доступных ходов"))
	else:
		highlighted = [int(hint.first), int(hint.second)]
		feedback.text = str(skin.get("hint_message", "Подсвечен возможный ход"))
	selected_index = -1
	_paint_selection()


func _play_result(result: Dictionary, first: int, second: int) -> void:
	input_locked = true
	highlighted.clear()
	selected_index = -1
	if not bool(result.get("valid", false)):
		feedback.text = str(skin.get("invalid", "Этот ход не даёт комбинацию"))
		_paint_selection()
		input_locked = false
		board_feedback.emit(feedback.text)
		return
	feedback.text = str(skin.get("matched", "Комбинация!"))
	if not reduced_motion:
		for raw in result.get("frames", []):
			var frame: Dictionary = raw
			var phase := str(frame.get("phase", ""))
			_paint_frame(frame)
			if phase == "swap":
				await get_tree().create_timer(0.12).timeout
			elif phase == "clear":
				for idx in frame.get("cleared", []):
					var cell_index := int(idx)
					if cell_index >= 0 and cell_index < stacks.size():
						stacks[cell_index].modulate.a = 0.35
				await get_tree().create_timer(0.10).timeout
			elif phase == "settle":
				await get_tree().process_frame
				for raw_motion in frame.get("motions", []):
					var motion: Dictionary = raw_motion
					var index := int(motion.get("index", -1))
					if index >= 0 and index < stacks.size():
						motion_layer.call("animate_tile", stacks[index], motion, 0.22)
				await get_tree().create_timer(0.23).timeout
				motion_layer.call("cancel_motions")
			elif phase == "reshuffle":
				await get_tree().create_timer(0.1).timeout
	_paint_live()
	if int(result.get("cascades", 0)) >= 2:
		feedback.text = "%s ×%d" % [str(skin.get("chain", "Цепочка")), int(result.cascades)]
	if bool(result.get("won", false)) and not _completed:
		_completed = true
		feedback.text = str(skin.get("won", "Подготовка завершена"))
		level_won.emit()
	elif bool(result.get("lost", false)):
		feedback.text = str(skin.get("lost", "Попробуйте ещё раз"))
		game.reset()
		_paint_live()
	input_locked = false
	board_feedback.emit(feedback.text)


func _paint_frame(frame: Dictionary) -> void:
	_paint_board(frame.get("tiles", game.tiles), frame.get("specials", game.specials), frame.get("blockers", game.blocker_layers), frame.get("ingredients", game.ingredients))


func _paint_live() -> void:
	_paint_board(game.tiles, game.specials, game.blocker_layers, game.ingredients)
	var value := int(game.collected)
	var target := 0
	var label := ""
	if not game.level_data.get("objectives", []).is_empty():
		var first: Dictionary = game.level_data.objectives[0]
		target = int(first.get("target", 0))
		label = str(first.get("label", first.get("tile", "")))
	objective.text = "%s %d/%d  ·  %s %d" % [label, value, target, str(skin.get("moves", "Ходы:")), int(game.moves_left)]
	_paint_selection()


func _paint_board(tiles: Array, specials: Array, blockers: Array, ingredients: Array) -> void:
	var holes: Array = game.level_data.get("boardHoles", [])
	var colors: Dictionary = skin.get("colors", {})
	var marks: Dictionary = skin.get("marks", {})
	for i in cells.size():
		var cell := cells[i]
		var stack := stacks[i]
		stack.modulate = Color.WHITE
		stack.visible = true
		if holes.has(i):
			cell.hide()
			continue
		cell.show()
		var tile := str(tiles[i])
		var symbol := str(marks.get(tile, "·"))
		if not str(ingredients[i]).is_empty():
			symbol = "◇"
		var special := str(specials[i])
		if not special.is_empty():
			symbol += "✦"
		if int(blockers[i]) > 0:
			symbol += "▣"
		var glyph := stack.get_node("Glyph") as Label
		glyph.text = symbol
		var style := (cell.get_theme_stylebox("normal") as StyleBoxFlat).duplicate() as StyleBoxFlat
		style.bg_color = colors.get(tile, Color("344054"))
		if int(blockers[i]) > 0:
			style.bg_color = style.bg_color.darkened(0.35)
		cell.add_theme_stylebox_override("normal", style)
		cell.add_theme_stylebox_override("hover", style)
		cell.add_theme_stylebox_override("pressed", style)


func _paint_selection() -> void:
	for i in cells.size():
		var style := (cells[i].get_theme_stylebox("normal") as StyleBoxFlat).duplicate() as StyleBoxFlat
		var chosen := i == selected_index or highlighted.has(i)
		style.border_color = Color("f5e8c8") if chosen else Color.TRANSPARENT
		style.set_border_width_all(3 if chosen else 0)
		cells[i].add_theme_stylebox_override("normal", style)
		cells[i].add_theme_stylebox_override("hover", style)
		cells[i].add_theme_stylebox_override("pressed", style)
