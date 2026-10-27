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
const FrameVisuals = preload("res://scripts/match3/match3_frame_visuals.gd")

var game: RefCounted
var skin: Dictionary = {}
var board_area: Control
var grid: GridContainer
var motion_layer: Control
var impact_layer: Control
var outline: Control
var feedback: Label
var objective: Label
var hint_button: Button
var help_button: Button
var help_panel: PanelContainer
var retry_button: Button
var motion_button: Button
var help_open := false
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
		var special_badge := Label.new()
		special_badge.name = "SpecialBadge"
		special_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		special_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		special_badge.add_theme_color_override("font_color", Color("fff3b8"))
		special_badge.add_theme_font_size_override("font_size", 17)
		stack.add_child(special_badge)
		special_badge.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		special_badge.offset_left = -27.0
		special_badge.offset_right = -2.0
		special_badge.offset_top = 0.0
		special_badge.offset_bottom = 23.0
		var blocker_badge := Label.new()
		blocker_badge.name = "BlockerBadge"
		blocker_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		blocker_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		blocker_badge.add_theme_color_override("font_color", Color("ffffff"))
		blocker_badge.add_theme_font_size_override("font_size", 15)
		stack.add_child(blocker_badge)
		blocker_badge.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		blocker_badge.offset_left = 2.0
		blocker_badge.offset_top = 0.0
		blocker_badge.offset_right = 23.0
		blocker_badge.offset_bottom = 23.0
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
	motion_layer.z_index = 4
	motion_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board_area.add_child(motion_layer)
	motion_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	impact_layer = Control.new()
	impact_layer.name = "UPDSClearImpacts"
	impact_layer.z_index = 5
	impact_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board_area.add_child(impact_layer)
	impact_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	feedback = Label.new()
	feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback.add_theme_color_override("font_color", Color("c0dab7"))
	add_child(feedback)
	hint_button = Button.new()
	hint_button.text = str(skin.get("hint", "Показать подсказку"))
	hint_button.custom_minimum_size.y = 44
	hint_button.pressed.connect(show_hint)
	add_child(hint_button)

	var toolbar := HBoxContainer.new()
	toolbar.add_theme_constant_override("separation", 6)
	add_child(toolbar)
	help_button = Button.new()
	help_button.text = str(skin.get("help_button", "Как играть"))
	help_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	help_button.custom_minimum_size.y = 44
	help_button.pressed.connect(toggle_help)
	toolbar.add_child(help_button)
	motion_button = Button.new()
	motion_button.text = str(skin.get("motion_on", "Анимация: вкл."))
	motion_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	motion_button.custom_minimum_size.y = 44
	motion_button.pressed.connect(toggle_motion)
	toolbar.add_child(motion_button)
	retry_button = Button.new()
	retry_button.name = "RetryButton"
	retry_button.text = str(skin.get("retry", "Попробовать снова"))
	retry_button.custom_minimum_size.y = 44
	retry_button.pressed.connect(retry_level)
	retry_button.visible = false
	add_child(retry_button)
	help_panel = PanelContainer.new()
	help_panel.name = "Match3HelpPanel"
	help_panel.visible = false
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("2b2634")
	panel_style.border_color = Color("a88b66")
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(7)
	panel_style.set_content_margin_all(12)
	help_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(help_panel)
	var help_content := VBoxContainer.new()
	help_content.add_theme_constant_override("separation", 9)
	help_panel.add_child(help_content)
	for key in ["help_title", "help_intro", "help_blockers", "help_specials", "help_goal"]:
		var paragraph := Label.new()
		paragraph.name = key
		paragraph.text = str(skin.get(key, ""))
		paragraph.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		paragraph.add_theme_color_override("font_color", Color("e9ddca"))
		paragraph.add_theme_font_size_override("font_size", 16 if key == "help_title" else 13)
		help_content.add_child(paragraph)
	var close_button := Button.new()
	close_button.text = str(skin.get("help_close", "Закрыть"))
	close_button.custom_minimum_size.y = 44
	close_button.pressed.connect(toggle_help)
	help_content.add_child(close_button)



func toggle_help() -> void:
	if input_locked:
		return
	help_open = not help_open
	help_panel.visible = help_open
	selected_index = -1
	highlighted.clear()
	_gesture_index = -1
	_gesture_kind = ""
	_paint_selection()
	_refresh_controls()


func toggle_motion() -> void:
	if input_locked:
		return
	reduced_motion = not reduced_motion
	motion_button.text = str(skin.get("motion_off" if reduced_motion else "motion_on", "Анимация"))
	feedback.text = motion_button.text


func retry_level() -> void:
	if input_locked or str(game.state) != "lost":
		return
	motion_layer.call("cancel_motions")
	_clear_impacts()
	game.reset()
	_completed = false
	selected_index = -1
	highlighted.clear()
	_gesture_index = -1
	_gesture_kind = ""
	feedback.text = str(skin.get("retry_message", "Новая попытка"))
	_paint_live()


func _refresh_controls() -> void:
	if is_instance_valid(hint_button):
		hint_button.disabled = input_locked or help_open or str(game.state) != "playing"
	if is_instance_valid(retry_button):
		retry_button.visible = str(game.state) == "lost" and not _completed
		retry_button.disabled = input_locked
	if is_instance_valid(motion_button):
		motion_button.disabled = input_locked


func _input(event: InputEvent) -> void:
	if game == null or input_locked or help_open or str(game.state) != "playing":
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
			highlighted.clear()
			highlighted.append(_gesture_index)
			if target >= 0:
				highlighted.append(target)
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
	if input_locked or help_open or str(game.state) != "playing" or not game.can_interact_with_tile(index):
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
	if input_locked or help_open or str(game.state) != "playing":
		return
	var hint: Dictionary = game.get_hint_move()
	highlighted.clear()
	if hint.is_empty():
		feedback.text = str(skin.get("no_hint", "Нет доступных ходов"))
	else:
		highlighted.append(int(hint.first))
		highlighted.append(int(hint.second))
		feedback.text = str(skin.get("hint_message", "Подсвечен возможный ход"))
	selected_index = -1
	_paint_selection()



func _clear_impacts() -> void:
	if not is_instance_valid(impact_layer):
		return
	for child in impact_layer.get_children():
		impact_layer.remove_child(child)
		child.queue_free()


func _show_clear_impacts(frame: Dictionary) -> void:
	_clear_impacts()
	var feedback_kind := str(frame.get("feedback", ""))
	var badge_map: Dictionary = skin.get("special_badges", {})
	for index in FrameVisuals.cleared_indices(frame, cells.size()):
		if not cells[index].visible:
			continue
		var special := FrameVisuals.special_at(frame, index)
		var flash := ColorRect.new()
		flash.name = "ClearImpact_%d" % index
		flash.position = cells[index].position
		flash.size = cells[index].size
		flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
		flash.color = FrameVisuals.impact_color(special, feedback_kind)
		flash.modulate.a = 0.44 if not special.is_empty() else 0.65
		impact_layer.add_child(flash)
		if not special.is_empty():
			var glyph := Label.new()
			glyph.text = str(badge_map.get(special, "✦"))
			glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
			glyph.add_theme_font_size_override("font_size", 22)
			glyph.add_theme_color_override("font_color", Color("161625"))
			flash.add_child(glyph)
			glyph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var fade := create_tween()
		fade.tween_property(flash, "modulate:a", 0.0, 0.18)
		fade.tween_callback(flash.queue_free)


func _play_result(result: Dictionary, first: int, second: int) -> void:
	input_locked = true
	highlighted.clear()
	selected_index = -1
	if not bool(result.get("valid", false)):
		var reason := str(result.get("reason", ""))
		var key := "invalid_blocked" if reason == "blocked" else "invalid_adjacent" if reason == "not-adjacent" else "invalid"
		feedback.text = str(skin.get(key, "Этот ход не даёт комбинацию"))
		_paint_selection()
		input_locked = false
		_refresh_controls()
		board_feedback.emit(feedback.text)
		return
	feedback.text = str(skin.get("matched", "Комбинация!"))
	if not reduced_motion:
		for raw in result.get("frames", []):
			var frame: Dictionary = raw
			var phase := str(frame.get("phase", ""))
			_paint_frame(frame)
			var message := FrameVisuals.phase_feedback(frame, skin)
			if not message.is_empty():
				feedback.text = message
			if phase == "swap":
				await get_tree().create_timer(0.12).timeout
			elif phase == "clear":
				_show_clear_impacts(frame)
				for idx in frame.get("cleared", []):
					var cell_index := int(idx)
					if cell_index >= 0 and cell_index < stacks.size():
						stacks[cell_index].modulate.a = 0.35
				await get_tree().create_timer(0.10).timeout
			elif phase == "settle":
				_clear_impacts()
				await get_tree().process_frame
				for raw_motion in frame.get("motions", []):
					var motion: Dictionary = raw_motion
					var index := int(motion.get("index", -1))
					if index >= 0 and index < stacks.size():
						var bounded := motion.duplicate()
						bounded["clipRect"] = FrameVisuals.clip_for_motion(
							motion, int(game.level_data.columns), int(game.level_data.rows),
							stacks[index].size, 3.0)
						motion_layer.call("animate_tile", stacks[index], bounded, 0.22)
				await get_tree().create_timer(0.23).timeout
				motion_layer.call("cancel_motions")
			elif phase == "reshuffle":
				await get_tree().create_timer(0.1).timeout
	_clear_impacts()
	_paint_live()
	if int(result.get("cascades", 0)) >= 2:
		feedback.text = "%s ×%d" % [str(skin.get("chain", "Цепочка")), int(result.cascades)]
	if bool(result.get("won", false)) and not _completed:
		_completed = true
		feedback.text = str(skin.get("won", "Подготовка завершена"))
		level_won.emit()
	elif bool(result.get("lost", false)):
		feedback.text = str(skin.get("lost", "Попробуйте ещё раз"))
		# Do not reset the board until the player explicitly requests a retry.
		# Only the Raven reducer owns first-clear rewards, never this UI.
	input_locked = false
	_refresh_controls()
	board_feedback.emit(feedback.text)


func _paint_frame(frame: Dictionary) -> void:
	_paint_board(frame.get("tiles", game.tiles), frame.get("specials", game.specials), frame.get("blockers", game.blocker_layers), frame.get("ingredients", game.ingredients))


func _paint_live() -> void:
	_paint_board(game.tiles, game.specials, game.blocker_layers, game.ingredients)
	var descriptions: Array[String] = []
	var objectives: Array = game.level_data.get("objectives", [])
	for index in objectives.size():
		var entry: Dictionary = objectives[index]
		var label := str(entry.get("label", entry.get("tile", entry.get("kind", ""))))
		var target := int(entry.get("target", 0))
		var value := int(game.objective_value(index))
		descriptions.append("%s %d/%d" % [label, mini(target, value), target])
	objective.text = "  ·  ".join(descriptions) + "  ·  %s %d" % [str(skin.get("moves", "Ходы:")), int(game.moves_left)]
	_paint_selection()
	_refresh_controls()


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
		var blocker_layers := int(blockers[i])
		var glyph := stack.get_node("Glyph") as Label
		glyph.text = symbol
		var special_badge := stack.get_node("SpecialBadge") as Label
		special_badge.text = str(skin.get("special_badges", {}).get(special, "✦"))
		special_badge.visible = not special.is_empty()
		var blocker_badge := stack.get_node("BlockerBadge") as Label
		blocker_badge.text = str(blocker_layers)
		blocker_badge.visible = blocker_layers > 0
		var description := str(skin.get("tile_names", {}).get(tile, tile))
		if not special.is_empty():
			description += " · %s" % str(skin.get("special_names", {}).get(special, special))
		if blocker_layers > 0:
			description += " · блокер: %d сл." % blocker_layers
		cell.tooltip_text = description
		cell.disabled = not game.can_interact_with_tile(i) or str(game.state) != "playing"
		var style := (cell.get_theme_stylebox("normal") as StyleBoxFlat).duplicate() as StyleBoxFlat
		style.bg_color = colors.get(tile, Color("344054"))
		if blocker_layers > 0:
			style.bg_color = style.bg_color.darkened(0.35)
			style.border_color = Color("d5aa79")
			style.set_border_width_all(2)
		cell.add_theme_stylebox_override("disabled", style)
		cell.add_theme_stylebox_override("normal", style)
		cell.add_theme_stylebox_override("hover", style)
		cell.add_theme_stylebox_override("pressed", style)


func _paint_selection() -> void:
	for i in cells.size():
		var style := (cells[i].get_theme_stylebox("normal") as StyleBoxFlat).duplicate() as StyleBoxFlat
		var chosen := i == selected_index or highlighted.has(i)
		var blocked := int(game.blocker_layers[i]) > 0
		style.border_color = Color("f5e8c8") if chosen else Color("d5aa79") if blocked else Color.TRANSPARENT
		style.set_border_width_all(3 if chosen else 2 if blocked else 0)
		cells[i].add_theme_stylebox_override("normal", style)
		cells[i].add_theme_stylebox_override("hover", style)
		cells[i].add_theme_stylebox_override("pressed", style)
