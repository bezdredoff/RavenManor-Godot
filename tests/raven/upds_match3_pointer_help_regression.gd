extends SceneTree
## Regression of reported failures: real tile gui_input, two visible hint
## markers and overlay help. Existing _input-only unit smoke was insufficient.
const Board = preload("res://scripts/match3/match3_board_presenter.gd")
const Game = preload("res://scripts/raven/raven_match3_game.gd")
const RavenSkin = preload("res://scripts/raven/raven_match3_theme.gd")
const Content = preload("res://data/raven/rm_vs_01_content.json")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var host := Control.new()
	host.size = Vector2(390, 844)
	root.add_child(host)
	var game := Game.new(Content.data.levels[0])
	var board := Board.new()
	host.add_child(board)
	board.setup(game, RavenSkin.placeholder())
	board.reduced_motion = true
	await process_frame

	board.show_hint()
	assert(board.highlighted.size() == 2)
	assert(board.highlighted[0] != board.highlighted[1])
	assert(board.hint_layer.get_child_count() == 2, "Both hint tiles must visibly highlight above UPDS shape")
	for index in board.highlighted:
		assert(board.hint_layer.get_node_or_null("Hint_%d" % index) != null)

	var hint: Dictionary = game.get_hint_move()
	var from := int(hint.first)
	var to := int(hint.second)
	var first_rect := board.cells[from].get_global_rect()
	var second_rect := board.cells[to].get_global_rect()
	var down := InputEventScreenTouch.new()
	down.index = 0
	down.pressed = true
	down.position = first_rect.size * 0.5
	board.cells[from].gui_input.emit(down)
	assert(board._gesture_index == from, "Tile gui_input must start drag")
	var move := InputEventScreenDrag.new()
	move.index = 0
	move.position = second_rect.get_center() - first_rect.position
	board.cells[from].gui_input.emit(move)
	assert(board.highlighted.size() == 2, "Drag preview must show source and target")
	var up := InputEventScreenTouch.new()
	up.index = 0
	up.pressed = false
	up.position = move.position
	var moves_before := game.moves_left
	board.cells[from].gui_input.emit(up)
	assert(game.moves_left == moves_before - 1, "Tile GUI touch drag must perform exactly one UPDS move")
	assert(board._gesture_index == -1)
	assert(board.hint_layer.get_child_count() == 0)

	var body_height := board.size.y
	board.toggle_help()
	assert(board.help_panel.visible and board.help_backdrop.visible)
	assert(board.help_panel.get_parent() is CanvasLayer, "Help must be an overlay, not an expanding spoiler")
	assert(not board.help_panel in board.get_children())
	board.toggle_help()
	assert(not board.help_panel.visible and not board.help_backdrop.visible)
	assert(board.size.y <= body_height + 1.0, "Opening help cannot push the Match-3 board down")
	host.queue_free()
	print("Raven Manor CODE-02 pointer, hint and help-overlay parity smoke passed.")
	quit()
