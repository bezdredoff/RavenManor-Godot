extends SceneTree
const Content = preload("res://data/raven/rm_vs_01_content.json")
const Game = preload("res://scripts/raven/raven_match3_game.gd")
const Snapshot = preload("res://scripts/raven/raven_snapshot.gd")
const Ids = preload("res://scripts/raven/raven_ids.gd")

func _initialize() -> void:
	var level: Dictionary = Content.data.levels[0]
	var game = Game.new(level)
	var hint: Dictionary = game.get_hint_move()
	assert(not hint.is_empty(), "No playable test move")
	var result: Dictionary = game.attempt_swap(int(hint.first), int(hint.second))
	assert(result.get("valid", false), "Hint move must be valid")
	assert(game.move_history.size() == 1, "Valid move not recorded")
	var state := Snapshot.fresh()
	state.match3Checkpoint = {"levelId": str(level.id), "actions": game.move_history.duplicate(true)}
	var normalized: Dictionary = Snapshot.normalize(state, Ids.CATALOG.data)
	assert(normalized.match3Checkpoint.actions.size() == 1, "Checkpoint lost during normalization")
	var resumed = Game.new(level)
	assert(resumed.restore_history(normalized.match3Checkpoint.actions), "Could not replay checkpoint")
	assert(resumed.tiles == game.tiles and resumed.specials == game.specials, "Tile state diverged")
	assert(resumed.blocker_layers == game.blocker_layers and resumed.ingredients == game.ingredients, "Board objects diverged")
	assert(resumed.moves_left == game.moves_left and resumed.collected_by_tile == game.collected_by_tile, "Objectives diverged")
	state.match3Checkpoint = {"levelId": str(level.id), "actions": [{"kind": "swap", "first": -1, "second": 2}]}
	assert(Snapshot.normalize(state, Ids.CATALOG.data).match3Checkpoint.is_empty(), "Unsafe checkpoint accepted")
	print("Raven Manor Match-3 replay checkpoint smoke passed")
	quit()
