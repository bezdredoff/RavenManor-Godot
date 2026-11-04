extends SceneTree
## Actual Viewport event dispatch, in a ScrollContainer, not direct game calls.
const Board = preload("res://scripts/match3/match3_board_presenter.gd")
const Game = preload("res://scripts/raven/raven_match3_game.gd")
const RavenTheme = preload("res://scripts/raven/raven_match3_theme.gd")
const Content = preload("res://data/raven/rm_vs_01_content.json")

func _initialize() -> void:
	call_deferred("_run")

func _mouse(position: Vector2, pressed: bool) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = position
	root.push_input(motion, true)
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = position
	root.push_input(event, true)

func _touch(position: Vector2, pressed: bool, finger: int = 0) -> void:
	var event := InputEventScreenTouch.new()
	event.index = finger
	event.pressed = pressed
	event.position = position
	root.push_input(event, true)

func _run() -> void:
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(390, 844)
	var scroll := ScrollContainer.new()
	scroll.size = Vector2(390, 844)
	root.add_child(scroll)
	var board := Board.new()
	board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(board)
	var level: Dictionary = Content.data.levels[0].duplicate(true)
	level.objective.target = 999  # Isolated input fixture must survive multiple valid moves.
	var game := Game.new(level)
	board.setup(game, RavenTheme.placeholder())
	board.reduced_motion = true
	await process_frame
	await process_frame
	var hint: Dictionary = game.get_hint_move()
	var first: int = hint.first
	var second: int = hint.second
	var start: Vector2 = board.cells[first].get_global_rect().get_center()
	var finish: Vector2 = board.cells[second].get_global_rect().get_center()
	var moves: int = game.moves_left
	_mouse(start, true)
	_mouse(finish, false)
	await process_frame
	assert(game.moves_left == moves - 1, "Viewport mouse swipe did not commit one move")
	board.show_hint()
	assert(board.highlighted.size() == 2 and board.highlighted[0] != board.highlighted[1])
	assert(game.moves_left == moves - 1, "Hint spent a move")
	var before_size: Vector2 = board.size
	board.toggle_help()
	await process_frame
	assert(board.help_open and board.help_dialog.visible and not board.help_panel.visible)
	assert(board.size == before_size, "Help changed board layout")
	var blocked_moves: int = game.moves_left
	_mouse(start, true)
	_mouse(finish, false)
	await process_frame
	assert(game.moves_left == blocked_moves, "Modal failed to block board")
	# AcceptDialog cancel is the Esc/system-back contract.
	board.help_dialog.canceled.emit()
	board.help_dialog.hide()
	await process_frame
	assert(not board.help_open and not board.hint_button.disabled, "Esc left Help state locked")
	hint = game.get_hint_move()
	start = board.cells[int(hint.first)].get_global_rect().get_center()
	finish = board.cells[int(hint.second)].get_global_rect().get_center()
	_touch(start, true, 3)
	_touch(finish, false, 4)
	assert(board._gesture_index == int(hint.first), "Another finger completed gesture")
	_touch(finish, false, 3)
	await process_frame
	assert(game.moves_left == blocked_moves - 1, "Viewport touch swipe did not commit one move")
	var after_touch: int = game.moves_left
	_mouse(start, true)
	_mouse(finish, false)
	assert(game.moves_left == after_touch and board.selected_index == -1, "Emulated mouse duplicated touch")
	# Direct cell GUI events have the same pointer ownership guarantee.
	hint = game.get_hint_move()
	var gui_index: int = hint.first
	var press := InputEventScreenTouch.new()
	press.index = 2
	press.position = board.cells[gui_index].size * 0.5
	press.pressed = true
	board._on_cell_gui_input(press, gui_index)
	var release := press.duplicate()
	release.index = 9
	release.pressed = false
	board._on_cell_gui_input(release, gui_index)
	assert(board._gesture_touch == 2, "finger=%s gesture=%s playing=%s locked=%s help=%s" % [board._gesture_touch, board._gesture_index, game.state, board.input_locked, board.help_open])
	board.hide()
	_touch(finish, false, 2)
	assert(board._gesture_index == -1 and game.moves_left == after_touch, "Hidden board consumed gesture")
	board.show()
	assert(board.selected_index == -1)
	scroll.queue_free()
	print("Raven Match-3 viewport pointer and modal smoke passed")
	quit()
