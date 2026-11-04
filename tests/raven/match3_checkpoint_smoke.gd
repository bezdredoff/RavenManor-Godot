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
	# Hammering a tile is free and deterministically replays through checkpoint history.
	var hammer_game = Game.new(level)
	var tile_index := 0
	while tile_index < hammer_game.tiles.size() and hammer_game.tiles[tile_index].is_empty(): tile_index += 1
	var tile_id: String = hammer_game.tiles[tile_index]
	var moves_before: int = hammer_game.moves_left
	var cleared_before: int = int(hammer_game.collected_by_tile.get(tile_id, 0))
	var hammer_result: Dictionary = hammer_game.use_hammer(tile_index)
	assert(hammer_result.valid and hammer_game.moves_left == moves_before, "Hammer must not spend a move")
	assert(int(hammer_game.collected_by_tile.get(tile_id, 0)) == cleared_before + 1, "Hammer must clear the selected tile")
	var booster_resume = Game.new(level)
	assert(booster_resume.restore_history(hammer_game.move_history), "Booster checkpoint failed to replay")
	assert(booster_resume.tiles == hammer_game.tiles and booster_resume.blocker_layers == hammer_game.blocker_layers, "Booster replay diverged")
	# One-use hammer removes exactly one layer even when a target cell has two.
	var blocker_level: Dictionary = level.duplicate(true)
	blocker_level.blockers = [{"index":0, "layers":2}]
	var blocker_game = Game.new(blocker_level)
	var blocker_moves: int = blocker_game.moves_left
	var blocker_result: Dictionary = blocker_game.use_hammer(0)
	assert(blocker_result.valid and blocker_game.blocker_layers[0] == 1 and blocker_game.moves_left == blocker_moves, "Hammer must remove one blocker layer without a move")
	var shuffle_game = Game.new(level)
	var shuffle_moves: int = shuffle_game.moves_left
	var shuffle_result: Dictionary = shuffle_game.use_shuffle()
	assert(shuffle_result.valid and shuffle_game.moves_left == shuffle_moves, "Shuffle must be free")
	var shuffle_resume = Game.new(level)
	assert(shuffle_resume.restore_history(shuffle_game.move_history), "Shuffle checkpoint failed to replay")
	assert(shuffle_resume.tiles == shuffle_game.tiles, "Shuffle replay diverged")
	assert(not shuffle_resume.restore_history([{"kind":"booster", "booster":"hammer", "index":-1}]), "Invalid booster target accepted")
	state.match3Checkpoint = {"levelId": str(level.id), "actions": [{"kind": "swap", "first": -1, "second": 2}]}
	assert(Snapshot.normalize(state, Ids.CATALOG.data).match3Checkpoint.is_empty(), "Unsafe checkpoint accepted")

	# Continue must preserve the entire seeded logical state, including subsequent RNG.
	for turn in range(5):
		if game.state != "playing":
			break
		var next_move: Dictionary = game.get_hint_move()
		if next_move.is_empty():
			break
		var a: Dictionary = game.attempt_swap(int(next_move.first), int(next_move.second))
		var b: Dictionary = resumed.attempt_swap(int(next_move.first), int(next_move.second))
		assert(a.get("valid", false) and b.get("valid", false), "Replay follow-up move rejected")
		assert(game.tiles == resumed.tiles and game.specials == resumed.specials, "RNG tiles diverged")
		assert(game.blocker_layers == resumed.blocker_layers and game.ingredients == resumed.ingredients, "RNG objects diverged")
		assert(game.moves_left == resumed.moves_left and game.collected_by_tile == resumed.collected_by_tile, "RNG objectives diverged")
		assert(game.state == resumed.state, "Terminal state diverged")
	var bad = Game.new(level)
	assert(not bad.restore_history([{"kind": "swap", "first": 255, "second": 254}]), "Out-of-board indices accepted")
	assert(bad.state == "playing" and bad.move_history.is_empty(), "Bad history did not reset")
	assert(not bad.restore_history([{"kind": "unknown"}]), "Unknown action accepted")
	assert(not bad.restore_history([{"kind": "swap", "first": "0", "second": 1}]), "String index accepted")
	assert(not bad.restore_history([{"kind": "special", "index": -1}]), "Negative index accepted")
	assert(not bad.restore_history(range(501)), "Oversized history accepted")
	bad.attempt_swap(int(hint.first), int(hint.second))
	bad.reset()
	assert(bad.move_history.is_empty(), "Retry retained move history")
	state.match3Checkpoint = {"levelId": str(level.id), "actions": []}
	assert(Snapshot.normalize(state, Ids.CATALOG.data).match3Checkpoint.is_empty(), "Empty retry checkpoint retained")
	state.match3Checkpoint = {"levelId": str(level.id), "actions": [{"kind": "swap", "first": int(hint.first), "second": int(hint.second)}]}
	state.firstClearLevels = [str(level.id)]
	assert(Snapshot.normalize(state, Ids.CATALOG.data).match3Checkpoint.is_empty(), "Won level retained checkpoint")
	print("Raven Manor Match-3 replay checkpoint smoke passed")
	quit()
