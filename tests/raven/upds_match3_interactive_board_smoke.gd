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
	assert(board.get_node("UPDSBoardArea/UPDSBoardShape") != null)
	assert(board.get_node("UPDSBoardArea/UPDSTileMotion") != null)
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
