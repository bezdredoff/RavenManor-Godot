extends SceneTree
const ReadHistory = preload("res://scripts/raven/raven_vn_read_history.gd")
const Snapshot = preload("res://scripts/raven/raven_snapshot.gd")
const Catalog = preload("res://data/raven/foundation_catalog.json")
const Slice = preload("res://scripts/raven/vertical_slice.gd")
const Store = preload("res://scripts/raven/raven_campaign_store.gd")
const Memory = preload("res://tests/support/memory_storage.gd")
const Contract = preload("res://data/save_contract.json")

func _initialize() -> void:
	call_deferred("_run")

func _spawn(memory: RefCounted) -> Control:
	var slice := Slice.new()
	slice.store = Store.new(memory)
	root.add_child(slice)
	return slice

func _run() -> void:
	var old := Snapshot.fresh()
	old.erase("vnReadLines")
	old.storyBeatsSeen = ["RM-BEAT-00-02"]
	assert(Snapshot.normalize(old, Catalog.data).vnReadLines.is_empty(), "Old beat flags fabricated read IDs")
	old.vnReadLines = ["RM-BEAT-00-01-L001", "RM-BEAT-00-01-L001", "draft-line", 42]
	assert(Snapshot.normalize(JSON.parse_string(JSON.stringify(old)), Catalog.data).vnReadLines == ["RM-BEAT-00-01-L001"])
	var memory := Memory.new()
	var slice := _spawn(memory)
	await process_frame
	assert(slice.vn_view.skip_button.disabled, "First-read Skip enabled")
	var config: Dictionary = slice.vn_player.scene.duplicate(true)
	assert(config.lineIds.size() >= 3)
	var ids: Array = config.lineIds
	assert(ReadHistory.skip_target(config, 0, []) == 0)
	assert(ReadHistory.skip_target(config, 0, [ids[0], ids[1]]) == 2)
	assert(ReadHistory.skip_target(config, 0, ids) == 0, "Skip must not finish scene")
	config.choiceGate = {"checkpointLineId": ids[1]}
	assert(ReadHistory.skip_target(config, 0, ids) == 1, "Skip crossed choice checkpoint")
	assert(ReadHistory.skip_target(config, 1, ids) == 1)
	config.erase("choiceGate")
	config.match3Gate = {"checkpointLineId": ids[1]}
	assert(ReadHistory.skip_target(config, 0, ids) == 1, "Skip crossed Match-3 checkpoint")
	config.erase("match3Gate")
	# A completed line is saved atomically with the next cursor, not when shown.
	slice._advance_vn()
	assert(slice.state.vnReadLines == [ids[0]])
	assert(Store.new(memory).load_campaign().vnReadLines == [ids[0]])
	memory.fail_write = true
	var prior: String = memory.values[Contract.data.ravenKey]
	slice._advance_vn()
	assert(slice.vn_player.line_index == 1 and slice.state.vnReadLines == [ids[0]])
	assert(memory.values[Contract.data.ravenKey] == prior, "Failed write marked unread line")
	memory.fail_write = false
	slice.queue_free()
	await process_frame
	# Isolated reread fixture: cursor at first line, known completed lines 1–2.
	var saved := Store.new(memory).load_campaign()
	saved.vnReadLines = [ids[0], ids[1]]
	saved.vnCursor.lineIndex = 0
	assert(Store.new(memory).save_campaign(saved))
	var resumed := _spawn(memory)
	await process_frame
	assert(not resumed.vn_view.skip_button.disabled)
	var points: int = resumed.state.workPoints
	var revision: int = resumed.state.revision
	var beats: Array = resumed.state.storyBeatsSeen.duplicate()
	memory.fail_write = true
	resumed._skip_read_vn()
	assert(resumed.vn_player.line_index == 0 and resumed.state.vnCursor.lineIndex == 0, "Failed Skip moved cursor")
	memory.fail_write = false
	# Close error dialog as the user would before continuing.
	for child in resumed.get_children():
		if child is AcceptDialog and child != resumed.pause_dialog: child.queue_free()
	await process_frame
	resumed.vn_view._skip_read_lines()
	assert(resumed.vn_player.line_index == 2 and resumed.vn_view.skip_button.disabled)
	assert(resumed.state.vnReadLines == [ids[0], ids[1]], "Skip marked unread text")
	assert(resumed.state.workPoints == points and resumed.state.revision == revision and resumed.state.storyBeatsSeen == beats, "Skip mutated story or wallet")
	assert(Store.new(memory).load_campaign().vnCursor.lineIndex == 2)
	assert(resumed.vn_view._history_lines.size() == 2, "Persisted read history missing")
	resumed.vn_view.set_playback_context(resumed._skip_read_vn, true, true)
	resumed.vn_view._toggle_auto()
	resumed.vn_view._on_auto_timeout()
	resumed.vn_view._next()
	assert(resumed.vn_view._auto_timer.is_stopped() and resumed.vn_player.line_index == 2, "Auto/Next crossed checkpoint")
	resumed.queue_free()
	await process_frame
	var continued := _spawn(memory)
	await process_frame
	assert(continued.vn_player.line_index == 2 and continued.state.vnReadLines.size() == 2)
	assert(continued.store.reset_campaign())
	assert(continued.store.load_campaign().vnReadLines.is_empty(), "New Game retained read history")
	continued.queue_free()
	print("Raven VN persisted read-only Skip smoke passed")
	quit()
