extends SceneTree
## GAME-LOOP-01 / GAME-QA-01: lock the current runtime flow before controller extraction.
## Uses injected memory storage; never touches the player's Raven save.

const Content = preload("res://data/raven/rm_vs_01_content.json")
const Director = preload("res://scripts/raven/raven_slice_director.gd")
const Snapshot = preload("res://scripts/raven/raven_snapshot.gd")
const Reducer = preload("res://scripts/raven/raven_reducer.gd")
const Store = preload("res://scripts/raven/raven_campaign_store.gd")
const MemoryStorage = preload("res://tests/support/memory_storage.gd")
const CONTRACT = preload("res://data/save_contract.json")
const SLICE = "res://scenes/raven/vertical_slice.tscn"


func _initialize() -> void:
	call_deferred("_run")


func _spawn(adapter: RefCounted) -> Control:
	var game: Control = load(SLICE).instantiate()
	game.store = Store.new(adapter)
	root.add_child(game)
	return game


func _at_first_story_level(adapter: RefCounted) -> void:
	var state: Dictionary = Snapshot.fresh()
	var serial := 0
	for beat_id in ["RM-BEAT-00-01", "RM-BEAT-00-02", "RM-BEAT-00-03", "RM-BEAT-01-01"]:
		serial += 1
		var r: Dictionary = Reducer.apply(state, {
			"eventId": "loop-baseline-beat-%d" % serial,
			"type": "story_beat_seen", "storyBeatId": beat_id,
		})
		assert(r.ok, "Expected authored prologue beat: " + beat_id)
		state = r.state
	for raw: Dictionary in Director.events_for("access"):
		serial += 1
		var event: Dictionary = raw.duplicate(true)
		event["eventId"] = "loop-baseline-access-%d" % serial
		var r: Dictionary = Reducer.apply(state, event)
		assert(r.ok, "Expected bedroom-access event")
		state = r.state
	assert(Director.next_step(state).id == "level1", "Fixture must reach first story Match-3")
	assert(Store.new(adapter).save_campaign(state), "Fixture save failed")


func _solve_first_story_board(game: Control) -> void:
	assert(game.step.kind == "match3" and game.step.level == "RM-LVL-001")
	var turns := 0
	while str(game.match_game.state) == "playing":
		turns += 1
		assert(turns <= 50, "Unexpected stuck board")
		var hint: Dictionary = game.match_game.get_hint_move()
		assert(not hint.is_empty(), "Story board lost a legal hint")
		var move: Dictionary = game.match_game.attempt_swap(int(hint.first), int(hint.second))
		assert(move.get("valid", false), "Story hint must be playable")
	assert(str(game.match_game.state) == "won", "Story board should be won before firing completion callback")


func _run() -> void:
	var adapter := MemoryStorage.new()
	_at_first_story_level(adapter)
	var game := _spawn(adapter)
	await process_frame
	assert(game.step.id == "level1" and game.state.workPoints == 0)
	assert(game.state.match3Checkpoint.is_empty())
	_solve_first_story_board(game)
	var persisted_before_failure: String = str(adapter.values.get(CONTRACT.data.ravenKey, ""))
	var before_failure: Dictionary = game.state.duplicate(true)
	# Force failure after a real board win, at the point where reward and
	# checkpoint removal must be committed together.
	adapter.fail_write = true
	game._complete_level()
	assert(game.state == before_failure, "Failed win save mutated in-memory campaign")
	assert(str(adapter.values.get(CONTRACT.data.ravenKey, "")) == persisted_before_failure,
		"Failed win save corrupted persisted campaign")
	assert(not game.state.firstClearLevels.has("RM-LVL-001"))
	adapter.fail_write = false
	# The controller must roll back the uncommitted winning move so the
	# player can retry without phantom reward or checkpoint loss.
	assert(str(game.match_game.state) == "playing", "Failed completion must restore playable board")
	_solve_first_story_board(game)
	game._complete_level()
	assert(game.step.id == "restore1", "Win should open bedroom restoration")
	assert(game.state.workPoints == 2 and game.state.firstClearLevels.has("RM-LVL-001"))
	assert(game.state.match3Checkpoint.is_empty(), "Winning checkpoint not cleared atomically")
	var won: Dictionary = Store.new(adapter).load_campaign()
	assert(won.workPoints == 2 and won.firstClearLevels.has("RM-LVL-001") and won.match3Checkpoint.is_empty(),
		"Win/reward/checkpoint not persisted in a single snapshot")
	assert(not won.completedRestorations.has("RM-REST-001"))
	game._complete_action()
	assert(game.step.id == "bedroom", "Restoration must return to VN story")
	assert(game.state.workPoints == 0 and game.state.completedRestorations.has("RM-REST-001"))
	assert(game.state.boosterInventory.hammer == 2, "Bedroom restoration must grant exactly two hammers")
	assert(not game.state.completedRestorations.has("RM-REST-002"), "Bathroom restoration must not gate bedroom")
	var after_restore: Dictionary = Store.new(adapter).load_campaign()
	assert(after_restore.workPoints == 0 and after_restore.boosterInventory.hammer == 2)
	game.queue_free()
	await process_frame
	var resumed := _spawn(adapter)
	await process_frame
	assert(resumed.step.id == "bedroom" and resumed.state.completedRestorations.has("RM-REST-001"),
		"Continue after restoration must resume VN and saved campaign")
	resumed.queue_free()
	await process_frame

	# Optional level completion is tested through the same controller handler.
	# It intentionally does not claim that a 22-level difficulty/balance QA is done.
	var bonus_adapter := MemoryStorage.new()
	var bonus := _spawn(bonus_adapter)
	await process_frame
	assert(bonus.step.kind == "vn")
	bonus._open_optional_campaign()
	bonus._start_optional_level("RM-LVL-101")
	assert(bonus.step.kind == "match3" and bonus.match_game.level_data.id == "RM-LVL-101")
	bonus._complete_level() # Completion-signal contract; board solver/balance is separate QA.
	assert(bonus.optional_campaign and bonus.step.kind == "campaign")
	assert(bonus.state.firstClearLevels.has("RM-LVL-101"))
	assert(bonus.state.workPoints == 0 and bonus.state.storyBeatsSeen.is_empty())
	assert(bonus.state.completedRestorations.is_empty(), "Optional level cannot repair a room")
	var optional_saved: Dictionary = Store.new(bonus_adapter).load_campaign()
	assert(optional_saved.workPoints == 0 and optional_saved.storyBeatsSeen.is_empty())
	assert(optional_saved.firstClearLevels == ["RM-LVL-101"])
	bonus._start_optional_level("RM-LVL-101")
	bonus._complete_level() # Replay must never duplicate progression or rewards.
	assert(bonus.state.workPoints == 0 and bonus.state.firstClearLevels == ["RM-LVL-101"])
	bonus._leave_optional_campaign()
	assert(bonus.step.kind == "vn" and bonus.state.storyBeatsSeen.is_empty(),
		"Returning from optional campaign must preserve the original VN")
	bonus.queue_free()
	print("Raven Manor game loop characterization smoke passed")
	quit()
