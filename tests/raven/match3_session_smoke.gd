extends SceneTree
## R2b characterization of Raven Match-3 session transactions without scene UI.
## MemoryStorage is isolated; no player save/preferences or UPDS story keys touched.
const Session = preload("res://scripts/raven/raven_match3_session.gd")
const Snapshot = preload("res://scripts/raven/raven_snapshot.gd")
const Content = preload("res://data/raven/rm_vs_01_content.json")
const Store = preload("res://scripts/raven/raven_campaign_store.gd")
const MemoryStorage = preload("res://tests/support/memory_storage.gd")
const Ids = preload("res://scripts/raven/raven_ids.gd")

var callback_count := 0


func _initialize() -> void:
	call_deferred("_run")


func _checkpoint_callback() -> void:
	callback_count += 1


func _run() -> void:
	var adapter := MemoryStorage.new()
	var store := Store.new(adapter)
	var state: Dictionary = Snapshot.fresh()
	assert(store.save_campaign(state))
	var level: Dictionary = Content.data.levels[0]
	var game: RefCounted = Session.open(level, state, _checkpoint_callback)
	assert(game.level_data.id == "RM-LVL-001" and game.move_history.is_empty())
	var hint: Dictionary = game.get_hint_move()
	assert(not hint.is_empty())
	var move: Dictionary = game.attempt_swap(int(hint.first), int(hint.second))
	assert(move.get("valid", false) and callback_count >= 1)
	var recorded: Dictionary = Session.checkpoint(game, state, "level1", "RM-LVL-001", store)
	assert(recorded.ok and recorded.boosterActionSaved)
	assert(recorded.state.match3Checkpoint.actions.size() == 1 and state.match3Checkpoint.is_empty(),
		"Checkpoint must not modify caller snapshot")
	state = recorded.state
	assert(Store.new(adapter).load_campaign().match3Checkpoint.actions.size() == 1)
	# Reopening a board replays only persisted actions.
	var resumed: RefCounted = Session.open(level, Store.new(adapter).load_campaign(), Callable())
	assert(resumed.tiles == game.tiles and resumed.moves_left == game.moves_left)
	var next_hint: Dictionary = game.get_hint_move()
	assert(not next_hint.is_empty())
	var next_move: Dictionary = game.attempt_swap(int(next_hint.first), int(next_hint.second))
	assert(next_move.get("valid", false))
	adapter.fail_write = true
	var before_error: Dictionary = state.duplicate(true)
	var failed: Dictionary = Session.checkpoint(game, state, "level1", "RM-LVL-001", store)
	assert(not failed.ok and failed.reason == "save")
	assert(state == before_error and Store.new(adapter).load_campaign() == before_error,
		"Failed checkpoint save must preserve the committed campaign")
	assert(game.tiles == resumed.tiles and game.move_history == resumed.move_history,
		"Failed checkpoint must roll board back to committed replay")
	adapter.fail_write = false
	# Win and checkpoint removal are one transaction.
	var win: Dictionary = Session.complete(game, state, "level1", "RM-LVL-001", 1, store)
	assert(win.ok and win.state.firstClearLevels.has("RM-LVL-001"))
	assert(win.state.workPoints == 2 and win.state.match3Checkpoint.is_empty())
	assert(Store.new(adapter).load_campaign().workPoints == 2)
	assert(state.workPoints == 0, "Session must not mutate original snapshot")
	# Bonus levels are first-clear recorded, but don't credit restoration work.
	var bonus_level: Dictionary = Content.data.levels[3]
	var bonus: RefCounted = Session.open(bonus_level, Snapshot.fresh(), Callable())
	var bonus_store := Store.new(MemoryStorage.new())
	var bonus_win: Dictionary = Session.complete(bonus, Snapshot.fresh(),
		"optional-RM-LVL-101", "RM-LVL-101", 1, bonus_store)
	assert(bonus_win.ok and bonus_win.state.firstClearLevels == ["RM-LVL-101"])
	assert(bonus_win.state.workPoints == 0 and bonus_win.state.storyBeatsSeen.is_empty())
	# Booster spends only once, in the same snapshot as its replay checkpoint.
	var booster_state := Snapshot.fresh()
	booster_state.boosterInventory.shuffle = 1
	var booster_storage := MemoryStorage.new()
	var booster_store := Store.new(booster_storage)
	assert(booster_store.save_campaign(booster_state))
	var booster_game: RefCounted = Session.open(level, booster_state, Callable())
	assert(booster_game.use_shuffle().get("valid", false))
	var boosted: Dictionary = Session.checkpoint(booster_game, booster_state, "level1", "RM-LVL-001", booster_store)
	assert(boosted.ok and boosted.state.boosterInventory.shuffle == 0 and booster_state.boosterInventory.shuffle == 1)
	assert(boosted.state.match3Checkpoint.actions.back().kind == "shuffle")
	assert(booster_store.load_campaign().boosterInventory.shuffle == 0)
	assert(Snapshot.normalize(boosted.state, Ids.CATALOG.data) != null,
		"Booster transaction must preserve save schema v1")
	print("Raven Match-3 session persistence and booster transaction smoke passed")
	quit()
