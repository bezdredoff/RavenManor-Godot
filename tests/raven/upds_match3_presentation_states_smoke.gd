extends SceneTree
## CODE-02B exercises Raven skin and the actual UPDS engine/presenter, not
## an independent rule implementation. No Raven campaign store is touched.
const Game = preload("res://scripts/raven/raven_match3_game.gd")
const Board = preload("res://scripts/match3/match3_board_presenter.gd")
const RavenSkin = preload("res://scripts/raven/raven_match3_theme.gd")
const Content = preload("res://data/raven/rm_vs_01_content.json")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := Game.new(Content.data.levels[0])
	var host := Control.new()
	host.size = Vector2(390, 844)
	root.add_child(host)
	var board := Board.new()
	host.add_child(board)
	board.setup(game, RavenSkin.placeholder())
	board.reduced_motion = true
	await process_frame
	assert(not board.help_panel.visible)
	assert(not board.retry_button.visible)
	assert(not board.hint_button.disabled)
	assert(not board.help_button.text.is_empty())
	board.toggle_help()
	assert(board.help_panel.visible and board.help_open)
	assert(board.hint_button.disabled)
	board.tap_cell(0)
	assert(board.selected_index == -1, "Help must block in-progress board taps")
	board.toggle_help()
	assert(not board.help_panel.visible)
	assert(not board.hint_button.disabled)
	board.toggle_motion()
	assert(not board.reduced_motion)
	board.toggle_motion()
	assert(board.reduced_motion)
	assert(board.motion_button.text == str(RavenSkin.placeholder().get("motion_off")))

	# The UPDS game owns special IDs, blockers and ALL objective progress.
	# This is presentation-only mutation of a disposable local game fixture.
	var initial_tile := str(game.tiles[0])
	var badges := RavenSkin.SPECIAL_BADGES
	for special in badges:
		game.specials[0] = str(special)
		board._paint_live()
		var badge := board.stacks[0].get_node("SpecialBadge") as Label
		assert(badge.visible and badge.text == badges[special], "Special badge must distinguish UPDS kind: " + str(special))
		assert(board.cells[0].tooltip_text.contains(str(RavenSkin.SPECIAL_NAMES[special])))
	game.specials[0] = ""
	game.tiles[0] = initial_tile
	game.blocker_layers[1] = 2
	board._paint_live()
	var blocker_badge := board.stacks[1].get_node("BlockerBadge") as Label
	assert(blocker_badge.visible and blocker_badge.text == "2")
	assert(board.cells[1].disabled, "Solid blocker must not be usable by pointer")
	assert(board.cells[1].tooltip_text.contains("2 сл."))
	var blocked_color := board.cells[1].get_theme_stylebox("normal") as StyleBoxFlat
	assert(blocked_color.border_width_top == 2)
	board.show_hint()
	assert((board.cells[1].get_theme_stylebox("normal") as StyleBoxFlat).border_width_top == 2, "Hints must retain blocker marker")
	game.blocker_layers[1] = 0
	# Future multi-objective level definitions display values from the UPDS
	# objective_value() API rather than the first Raven collect counter only.
	game.level_data.objectives.append({"kind":"clearBlockers", "label":"Преграды", "target":2})
	board._paint_live()
	assert(board.objective.text.contains("Преграды 0/2"))
	assert(board.objective.text.contains("Нужные вещи"))
	assert(board.objective.text.contains(str(game.moves_left)))
	var won := {"count": 0}
	board.level_won.connect(func(): won.count += 1)
	var before_moves := game.moves_left
	board._commit_swap(0, 35)
	assert(game.moves_left == before_moves, "Invalid diagonal must not consume moves or restoration currency")
	assert(not board.feedback.text.is_empty())
	assert(won.count == 0)
	# Explicit loss screen keeps the last board until player retries.
	game.state = "lost"
	board._paint_live()
	assert(board.retry_button.visible)
	assert(board.hint_button.disabled)
	board.tap_cell(0)
	assert(board.selected_index == -1, "Lost screen must reject tile taps")
	board.show_hint()
	assert(game.state == "lost")
	board.retry_level()
	assert(game.state == "playing" and game.moves_left == before_moves)
	assert(not board.retry_button.visible)
	assert(not board.hint_button.disabled)
	assert(won.count == 0, "Retry must not issue Raven first-clear or story rewards")
	host.queue_free()
	print("Raven Manor UPDS Match-3 help, objectives, special/blocker and retry smoke passed.")
	quit()
