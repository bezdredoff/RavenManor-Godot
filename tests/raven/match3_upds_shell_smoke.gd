extends SceneTree
## Real native Control composition / reflow with the unchanged UPDS board game.
const Shell = preload("res://scripts/match3/match3_screen_shell.gd")
const Board = preload("res://scripts/match3/match3_board_presenter.gd")
const Game = preload("res://scripts/raven/raven_match3_game.gd")
const Theme = preload("res://scripts/raven/raven_match3_theme.gd")
const Content = preload("res://data/raven/rm_vs_01_content.json")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var host := Control.new()
	host.name = "Match3ShellTestHost"
	root.add_child(host)
	var level: Dictionary = Content.data.levels[3].duplicate(true)
	var game := Game.new(level)
	var slots := Shell.build(host, level, "en", func() -> void: pass, func() -> void: pass)
	var board := Board.new()
	board.name = "RavenMatch3Board"
	slots.board_slot.add_child(board)
	board.setup(game, Theme.placeholder())
	Shell.adopt_board(board, slots, host)
	board.set_reduced_motion(true)
	await process_frame
	assert(slots.surface.name == "UPDSMatch3FullScreen")
	assert(slots.surface.find_child("UPDSMatch3Header", true, false) != null)
	assert(slots.surface.find_child("UPDSGoalCard", true, false) != null)
	assert(slots.surface.find_child("UPDSMovesCard", true, false) != null)
	assert(slots.surface.find_child("UPDSMatch3Bark", true, false) != null)
	assert(board.objective.get_parent() == slots.goal_slot and board.separate_hud)
	assert(board.moves_label.get_parent() == slots.moves_slot)
	assert(board.moves_label.text == str(game.moves_left))
	assert(board.hint_button.get_parent() == slots.hint_slot)
	assert(board.help_button.get_parent() == slots.help_slot)
	assert(board.help_button.text == "?")
	assert(board.help_dialog != null, "UPDS Help modal must still belong to existing board presenter")
	var initial_moves: int = game.moves_left
	for width in [320.0, 340.0, 360.0, 390.0, 430.0]:
		host.size = Vector2(width, 844)
		await process_frame
		board.apply_available_width(Shell.available_board_width(width))
		var extent: Vector2 = board.board_area.size
		assert(extent.x <= Shell.available_board_width(width) + 1.0, "Board width overflows phone at %s px" % width)
		assert(game.moves_left == initial_moves, "Visual reflow must not reset or spend a move")
		assert(slots.surface.size.x == width, "Match-3 shell did not fill phone viewport")
	assert(Shell.available_board_width(320.0) == 284.0)
	assert(Shell.COPY.get("de", Shell.COPY.ru).title == Shell.COPY.ru.title)
	host.queue_free()
	print("Raven UPDS-style Match-3 full-screen layout smoke passed")
	quit()
