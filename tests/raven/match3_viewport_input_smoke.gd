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
	board.set_reduced_motion(false)
	assert(not board.reduced_motion)
	board.set_reduced_motion(true)
	assert(board.reduced_motion)
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
	assert(board.help_dialog.size.x <= root.size.x, "Help exceeds phone viewport")
	assert((board.help_dialog.get_node("Match3HelpText") as RichTextLabel).scroll_active)
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
	board.set_interaction_blocked(true)
	_mouse(start, true)
	_mouse(finish, false)
	await process_frame
	assert(game.moves_left == blocked_moves and board.hint_button.disabled, "External settings modal failed to block board")
	board.set_interaction_blocked(false)
	assert(not board.hint_button.disabled, "Closing external modal did not restore controls")
	hint = game.get_hint_move()
	start = board.cells[int(hint.first)].get_global_rect().get_center()
	finish = board.cells[int(hint.second)].get_global_rect().get_center()
	var cancelled_moves: int = game.moves_left
	_touch(start, true, 6)
	var cancelled_release := InputEventScreenTouch.new()
	cancelled_release.index = 6
	cancelled_release.pressed = false
	cancelled_release.canceled = true
	cancelled_release.position = finish
	root.push_input(cancelled_release, true)
	await process_frame
	assert(game.moves_left == cancelled_moves, "Cancelled touch drag committed a move")
	assert(board._gesture_index == -1 and board.highlighted.is_empty(), "Cancelled touch drag retained gesture state")
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
	await process_frame
	# A tab/app switch can drop the owning touch release without a canceled event.
	# Simulate Window.focus_exited, then deliver the old release via the viewport.
	hint = game.get_hint_move()
	assert(not hint.is_empty())
	start = board.cells[int(hint.first)].get_global_rect().get_center()
	finish = board.cells[int(hint.second)].get_global_rect().get_center()
	var focus_moves: int = game.moves_left
	_touch(start, true, 11)
	assert(board._gesture_index == int(hint.first) and board._gesture_touch == 11)
	board.get_window().focus_exited.emit()
	assert(board._gesture_index == -1 and board._gesture_kind.is_empty() and board._gesture_touch == -1)
	assert(board.highlighted.is_empty(), "Focus loss retained drag preview")
	_touch(finish, false, 11)
	await process_frame
	assert(game.moves_left == focus_moves, "Stale release after focus loss committed a move")
	# The next, fresh gesture must still work without any reload/reset.
	_touch(start, true, 11)
	_touch(finish, false, 11)
	await process_frame
	assert(game.moves_left == focus_moves - 1, "Fresh swipe after focus loss failed")
	# Simulate a mobile application pause while a second finger owns a swipe.
	hint = game.get_hint_move()
	assert(not hint.is_empty())
	start = board.cells[int(hint.first)].get_global_rect().get_center()
	finish = board.cells[int(hint.second)].get_global_rect().get_center()
	var pause_moves: int = game.moves_left
	_touch(start, true, 12)
	assert(board._gesture_touch == 12)
	board.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	assert(board._gesture_index == -1 and board._gesture_touch == -1, "Pause retained pointer ownership")
	_touch(finish, false, 12)
	await process_frame
	assert(game.moves_left == pause_moves, "Release after app pause committed a move")
	# Direct tile GUI regression: Web compatibility mouse press may precede
	# the true touch press. The finger must supersede it, and delayed mouse
	# release must not end the swipe or count as an extra move.
	hint = game.get_hint_move()
	assert(not hint.is_empty(), "Direct GUI pointer fixture has no hint")
	var gui_first: int = int(hint.first)
	var gui_second: int = int(hint.second)
	var gui_local_start: Vector2 = board.cells[gui_first].size * 0.5
	var gui_delta: Vector2 = board.cells[gui_second].get_global_rect().get_center() - board.cells[gui_first].get_global_rect().get_center()
	var gui_moves: int = game.moves_left
	# Previous injected touch activity is very recent; reset the suppression
	# timestamp ONLY for this synthetic independent mouse-first sequence.
	board._last_touch_ms = -10000
	var compat_press := InputEventMouseButton.new()
	compat_press.button_index = MOUSE_BUTTON_LEFT
	compat_press.pressed = true
	compat_press.position = gui_local_start
	board._on_cell_gui_input(compat_press, gui_first)
	assert(board._gesture_kind == "mouse" and board._gesture_index == gui_first)
	var owning_touch := InputEventScreenTouch.new()
	owning_touch.index = 17
	owning_touch.pressed = true
	owning_touch.position = gui_local_start
	board._on_cell_gui_input(owning_touch, gui_first)
	assert(board._gesture_kind == "touch" and board._gesture_touch == 17 and board._gesture_index == gui_first, "Real touch failed to replace compatibility mouse in cell GUI path")
	var compat_release := compat_press.duplicate() as InputEventMouseButton
	compat_release.pressed = false
	compat_release.position = gui_local_start + gui_delta
	board._on_cell_gui_input(compat_release, gui_first)
	assert(board._gesture_kind == "touch" and game.moves_left == gui_moves, "Compatibility mouse release stole touch swipe")
	var other_finger_release := owning_touch.duplicate() as InputEventScreenTouch
	other_finger_release.index = 18
	other_finger_release.pressed = false
	other_finger_release.position = gui_local_start + gui_delta
	board._on_cell_gui_input(other_finger_release, gui_first)
	assert(board._gesture_touch == 17 and game.moves_left == gui_moves, "Other finger completed direct GUI gesture")
	var touch_release := owning_touch.duplicate() as InputEventScreenTouch
	touch_release.pressed = false
	touch_release.position = gui_local_start + gui_delta
	board._on_cell_gui_input(touch_release, gui_first)
	await process_frame
	assert(game.moves_left == gui_moves - 1 and board._gesture_index == -1, "Direct GUI touch did not make exactly one legal move")
	# A synthetic mouse click after the real touch must not start a new move.
	board._on_cell_gui_input(compat_press, gui_first)
	board._on_cell_gui_input(compat_release, gui_first)
	assert(game.moves_left == gui_moves - 1 and board._gesture_index == -1, "Trailing compatibility mouse started a phantom gesture")
	# Desktop direct GUI mouse input still has its own valid path.
	hint = game.get_hint_move()
	assert(not hint.is_empty())
	gui_first = int(hint.first)
	gui_second = int(hint.second)
	gui_local_start = board.cells[gui_first].size * 0.5
	gui_delta = board.cells[gui_second].get_global_rect().get_center() - board.cells[gui_first].get_global_rect().get_center()
	board._last_touch_ms = -10000
	compat_press.position = gui_local_start
	compat_release.position = gui_local_start + gui_delta
	var mouse_before: int = game.moves_left
	board._on_cell_gui_input(compat_press, gui_first)
	assert(board._gesture_kind == "mouse")
	board._on_cell_gui_input(compat_release, gui_first)
	await process_frame
	assert(game.moves_left == mouse_before - 1 and board._gesture_index == -1, "Direct GUI mouse stopped working after touch ownership fix")
	scroll.queue_free()
	print("Raven Match-3 viewport pointer and modal smoke passed")
	quit()
