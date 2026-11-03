extends SceneTree
## In-memory scene lifecycle test: no player disk save or UPDS story keys are touched.
const Store = preload("res://scripts/raven/raven_campaign_store.gd")
const MemoryStorage = preload("res://tests/support/memory_storage.gd")
const Reducer = preload("res://scripts/raven/raven_reducer.gd")
const Snapshot = preload("res://scripts/raven/raven_snapshot.gd")
const Content = preload("res://data/raven/rm_vs_01_content.json")
const CONTRACT = preload("res://data/save_contract.json")

func _initialize() -> void:
	call_deferred("_run")

func _spawn(adapter: RefCounted) -> Control:
	var scene: PackedScene = load("res://scenes/raven/vertical_slice.tscn")
	var game: Control = scene.instantiate()
	game.store = Store.new(adapter)
	root.add_child(game)
	return game

func _run() -> void:
	# Godot JSON.parse_string turns integral JSON numbers into floats.
	# Roundtrip must retain a valid VN cursor and reject fractional indices.
	var cursor_fixture := Snapshot.fresh()
	cursor_fixture.vnCursor = {"beatId": "RM-BEAT-00-01", "lineIndex": 1}
	var roundtrip: Variant = JSON.parse_string(JSON.stringify(cursor_fixture))
	var normalized: Variant = Snapshot.normalize(roundtrip, preload("res://data/raven/foundation_catalog.json").data)
	assert(normalized.vnCursor.get("lineIndex", -1) == 1, "JSON roundtrip dropped valid VN cursor")
	roundtrip.vnCursor.lineIndex = 1.5
	assert(Snapshot.normalize(roundtrip, preload("res://data/raven/foundation_catalog.json").data).vnCursor.is_empty(), "Fractional VN cursor accepted")
	# Checkpoint action indices must survive the same JSON storage roundtrip.
	var checkpoint_fixture := Snapshot.fresh()
	checkpoint_fixture.match3Checkpoint = {"levelId": "RM-LVL-001", "actions": [{"kind": "swap", "first": 0, "second": 1}, {"kind": "special", "index": 4}]}
	var checkpoint_roundtrip: Dictionary = JSON.parse_string(JSON.stringify(checkpoint_fixture))
	var catalog: Dictionary = preload("res://data/raven/foundation_catalog.json").data
	var checkpoint_normalized: Dictionary = Snapshot.normalize(checkpoint_roundtrip, catalog)
	assert(checkpoint_normalized.match3Checkpoint.get("actions", []).size() == 2, "JSON roundtrip dropped Match-3 checkpoint")
	checkpoint_roundtrip.match3Checkpoint.actions[0].first = 0.5
	assert(Snapshot.normalize(checkpoint_roundtrip, catalog).match3Checkpoint.is_empty(), "Fractional Match-3 index accepted")
	var adapter := MemoryStorage.new()
	var game := _spawn(adapter)
	await process_frame
	assert(game.step.kind == "vn", "New Game must start in VN")
	var beat: String = str(game.vn_player.scene.beatId)
	game._advance_vn()
	assert(game.state.vnCursor.beatId == beat and game.state.vnCursor.lineIndex == 1, "VN advance not saved")
	var saved_before_failure: String = str(adapter.values.get(CONTRACT.data.ravenKey, ""))
	assert(not saved_before_failure.is_empty(), "First VN cursor write missing from storage")
	# Failed VN line save must not silently advance the visible line.
	adapter.fail_write = true
	game._advance_vn()
	assert(game.vn_player.line_index == 1, "VN cursor advanced despite failed save")
	assert(game.status.text == game.PAUSE_COPY[game.preferences.locale][4], "VN save failure not visible")
	adapter.fail_write = false
	assert(str(adapter.values.get(CONTRACT.data.ravenKey, "")) == saved_before_failure, "Failed VN save mutated stored snapshot")
	var stored_after_failure := Store.new(adapter).load_campaign()
	assert(stored_after_failure.get("vnCursor", {}).get("lineIndex", -1) == 1, "Persisted VN cursor missing before reload: %s" % str(stored_after_failure.get("vnCursor", {})))
	# A scene reload is the core Continue contract; avoid changing the SceneTree
	# to main_menu inside this headless smoke (the menu has separate coverage).
	game.queue_free()
	await process_frame
	# Explicitly re-open a fresh vertical slice as Continue would.
	var resumed := _spawn(adapter)
	await process_frame
	assert(resumed.step.kind == "vn" and resumed.vn_player.line_index == 1, "Continue lost VN line: %s / %s" % [str(resumed.step), str(resumed.state.vnCursor)])
	resumed.queue_free()
	await process_frame
	# Prepare an authorized campaign step via reducer events, not by faking a board snapshot.
	var state: Dictionary = Store.new(adapter).load_campaign()
	var n := 0
	for beat_id in ["RM-BEAT-00-01", "RM-BEAT-00-02", "RM-BEAT-00-03", "RM-BEAT-01-01"]:
		n += 1
		var result: Dictionary = Reducer.apply(state, {"eventId":"session-e2e-beat-%d" % n, "type":"story_beat_seen", "storyBeatId":beat_id})
		assert(result.ok, "Could not advance story")
		state = result.state
	var access := Reducer.apply(state, {"eventId":"session-e2e-access", "type":"story_flag_set", "flagId":"RM-FLAG-BEDROOM-ACCESS-CLEARED"})
	assert(access.ok)
	state = access.state
	state.vnCursor = {}
	assert(Store.new(adapter).save_campaign(state))
	var board := _spawn(adapter)
	await process_frame
	assert(board.step.kind == "match3", "Continue did not reach Match-3")
	var hint: Dictionary = board.match_game.get_hint_move()
	assert(not hint.is_empty(), "No playable Match-3 move")
	var move: Dictionary = board.match_game.attempt_swap(int(hint.first), int(hint.second))
	assert(move.get("valid", false), "Hint move invalid")
	assert(not Store.new(adapter).load_campaign().match3Checkpoint.is_empty(), "Move checkpoint not persisted")
	var tiles: Array = board.match_game.tiles.duplicate()
	var specials: Array = board.match_game.specials.duplicate()
	var remaining: int = board.match_game.moves_left
	board.queue_free()
	await process_frame
	var continued := _spawn(adapter)
	await process_frame
	assert(continued.step.kind == "match3", "Continue lost level")
	assert(continued.match_game.tiles == tiles and continued.match_game.specials == specials, "Board diverged after Continue")
	assert(continued.match_game.moves_left == remaining, "Moves diverged after Continue")
	# Failed New Game reset must preserve the current session and checkpoint.
	adapter.fail_remove = true
	var before_reset: Dictionary = continued.state.duplicate(true)
	continued._reset()
	assert(continued.state == before_reset, "Failed reset discarded active session")
	assert(continued.status.text == continued.PAUSE_COPY[continued.preferences.locale][4], "Reset failure not visible")
	adapter.fail_remove = false
	# Retry must replace the old checkpoint, not resurrect it.
	continued.match_game.reset()
	assert(Store.new(adapter).load_campaign().match3Checkpoint.is_empty(), "Retry retained checkpoint")
	continued.queue_free()
	await process_frame
	# A new game must never inherit VN or Match-3 progress.
	assert(Store.new(adapter).reset_campaign(), "New Game reset failed")
	assert(Store.new(adapter).load_campaign() == Snapshot.fresh(), "New Game revived stale state")
	# Corrupt saves recover to a fresh campaign with a backup.
	adapter.values[CONTRACT.data.ravenKey] = "{invalid"
	var recovery := Store.new(adapter)
	assert(recovery.load_campaign() == Snapshot.fresh() and recovery.last_load_report.status == "recovered-corrupt")
	# Failure must remain visible and must not navigate away.
	var failure := _spawn(adapter)
	await process_frame
	adapter.fail_write = true
	failure._save_and_exit()
	assert(failure.status.text == failure.PAUSE_COPY[failure.preferences.locale][4], "Save failure not visible")
	adapter.fail_write = false
	failure.queue_free()
	print("Raven Manor session lifecycle E2E smoke passed")
	quit()
