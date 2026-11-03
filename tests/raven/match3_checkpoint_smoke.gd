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
	assert(not bad.restore_history(Array(range(501))), "Oversized history accepted")
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
