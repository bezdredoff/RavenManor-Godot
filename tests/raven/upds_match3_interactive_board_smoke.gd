extends SceneTree
## Test real UPDS Match3 engine + extracted pointer model + visual presenter,
## including Raven reward isolation. No real campaign save is written.
const Drag = preload("res://scripts/match3/match3_drag_model.gd")
const Board = preload("res://scripts/match3/match3_board_presenter.gd")
const Game = preload("res://scripts/raven/raven_match3_game.gd")
const RavenTheme = preload("res://scripts/raven/raven_match3_theme.gd")
const Content = preload("res://data/raven/rm_vs_01_content.json")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var level: Dictionary = Content.data.levels[0]
	var game := Game.new(level)
	var source := Control.new()
	source.size = Vector2(390, 844)
	root.add_child(source)
	var board := Board.new()
	source.add_child(board)
	board.setup(game, RavenTheme.placeholder())
	board.reduced_motion = true
	await process_frame
	assert(board.cells.size() == 36)
	assert(board.board_area.get_node("UPDSBoardShape") != null)
	assert(board.board_area.get_node("UPDSTileMotion") != null)
	assert(board.objective.text.contains("16"))
	assert(game.state == "playing")
	assert(Drag.direction(Vector2(50, 1)) == "right")
	assert(Drag.direction(Vector2(-80, 1)) == "left")
	assert(Drag.direction(Vector2(0, -80)) == "up")
	assert(Drag.direction(Vector2(50, 50)).is_empty())
	var active := func(index: int) -> bool: return index >= 0 and index < 36
	assert(Drag.neighbour(5, "right", 6, 6, active) == -1, "UPDS row wrap forbidden")
	assert(Drag.neighbour(6, "up", 6, 6, active) == 0)
	assert(Drag.target_for_drag(7, Vector2(10, 0), 50.0, 6, 6, active) == -1)
	assert(Drag.target_for_drag(7, Vector2(20, 0), 50.0, 6, 6, active) == 8)
	assert(board.cells[7].gui_input.is_connected(board._on_cell_gui_input), "Each UPDS tile must bind gui_input")
	# Assert the real signal path starts an interaction on a tile, including
	# coordinate conversion from local tile space to canvas coordinates.
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = board.cells[7].size * 0.5
	board._on_cell_gui_input(press, 7)
	assert(board._gesture_index == 7, "Local tile press must begin a real gesture")
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = press.position
	board._on_cell_gui_input(release, 7)
	assert(board._gesture_index == -1 and board.selected_index == 7)
	board.tap_cell(7)
	assert(board.selected_index == -1)
	var before_moves := game.moves_left
	board.show_hint()
	assert(game.moves_left == before_moves, "Hint must not automatically play a move")
	assert(board.highlighted.size() == 2)
	assert(board.selected_index == -1)
	board.tap_cell(0)
	assert(board.selected_index == 0)
	board.tap_cell(0)
	assert(game.moves_left == before_moves, "Tapping same normal tile must not consume moves")
	var won := {"count": 0}
	board.level_won.connect(func(): won.count += 1)
	# Exercise the actual touch event path, not only the pure drag helper.
	var first_hint: Dictionary = game.get_hint_move()
	var start := board.cells[int(first_hint.first)].get_global_rect().get_center()
	var finish := board.cells[int(first_hint.second)].get_global_rect().get_center()
	assert(start.distance_to(finish) > 12.0, "Grid must have real touch target geometry")
	var touch_start := InputEventScreenTouch.new()
	touch_start.index = 0
	touch_start.pressed = true
	touch_start.position = start
	board._input(touch_start)
	var touch_drag := InputEventScreenDrag.new()
	touch_drag.index = 0
	touch_drag.position = finish
	board._input(touch_drag)
	var touch_end := InputEventScreenTouch.new()
	touch_end.index = 0
	touch_end.pressed = false
	touch_end.position = finish
	board._input(touch_end)
	assert(game.moves_left == before_moves - 1, "A real touch swipe must commit exactly one legal move")
	var safety := 0
	while game.state == "playing" and safety < 40:
		var hint: Dictionary = game.get_hint_move()
		assert(not hint.is_empty(), "UPDS game must remain playable")
		board.tap_cell(int(hint.first))
		board.tap_cell(int(hint.second))
		safety += 1
	assert(game.state == "won", "Raven level must remain completable through shared UI")
	assert(won.count == 1, "Completion callback must be emitted once")
	assert(board.objective.text.contains(str(game.moves_left)))
	source.queue_free()
	print("Raven Manor UPDS interactive Match-3 board smoke passed (drag, hint, frames, win, no save).")
	quit()
