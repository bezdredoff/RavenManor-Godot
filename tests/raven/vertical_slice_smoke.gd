extends SceneTree

const Content = preload("res://data/raven/rm_vs_01_content.json")
const Narrative = preload("res://data/raven/season1_narrative.json")
const Snapshot = preload("res://scripts/raven/raven_snapshot.gd")
const Reducer = preload("res://scripts/raven/raven_reducer.gd")
const Director = preload("res://scripts/raven/raven_slice_director.gd")
const Match3 = preload("res://scripts/raven/raven_match3_game.gd")
const VN = preload("res://scripts/raven/raven_vn_player.gd")
const Store = preload("res://scripts/raven/raven_campaign_store.gd")
const MemoryStorage = preload("res://tests/support/memory_storage.gd")


func _initialize() -> void:
	var content: Dictionary = Content.data
	var narrative: Dictionary = Narrative.data
	assert(content.sliceId == "RM-VS-01")
	assert(content.narrativeRevision == "2026-10-26-chat-sync")
	assert(narrative.canonRevision == content.narrativeRevision)
	assert(narrative.premise.inheritanceReturn)
	assert(narrative.premise.lastHeir)
	assert(not narrative.gameplaySemantics.freeTapToMove)
	assert(not narrative.gameplaySemantics.roomArtMayMutateStoryState)
	assert(narrative.premise.memoryRule.cause.begins_with("long-term mystery"))
	for character: Dictionary in narrative.characters:
		if character.id in ["RM-CHAR-ADA", "RM-CHAR-LUCAS", "RM-CHAR-ROWAN"]:
			assert(not character.earlyReveal, character.id + " supernatural nature must not be explicitly revealed in RM-VS-01")

	var vn := VN.new()
	vn.open(content.vnScenes.arrival)
	assert(vn.current_speaker() == "Эвелин")
	assert(not vn.current_line().is_empty())
	vn.advance()
	assert(vn.current_speaker() == "Лукас", "RM-BEAT-01-01 must support per-line speakers")

	for level: Dictionary in content.levels:
		assert(not str(level.get("fiction", "")).is_empty(), level.id + " must explain its in-world preparation work")
		var game := Match3.new(level)
		assert(game.tiles.size() == int(level.rows) * int(level.columns))
		assert(game.get_hint_move().size() == 2, level.id + " must start playable")
		var hint: Dictionary = game.get_hint_move()
		var result := game.attempt_swap(hint.first, hint.second)
		assert(result.valid, level.id + " must execute a real legal swap")
		while game.state == "playing":
			hint = game.get_hint_move()
			assert(not hint.is_empty(), level.id + " must remain playable")
			result = game.attempt_swap(hint.first, hint.second)
		assert(game.state == "won", level.id + " must be completable within its authored move limit")

	var state := Snapshot.fresh()
	var serial := 0
	for expected in ["arrival","access","level1","restore1","bedroom","level2","trace","level3","restore2","clue","night","complete"]:
		var step: Dictionary = Director.next_step(state)
		assert(step.id == expected, "Unexpected slice step: " + str(step.id))
		var events: Array = Director.events_for(expected)
		if step.kind == "vn": events = [{"type":"story_beat_seen","storyBeatId":content.vnScenes[step.scene].beatId}]
		elif step.kind == "match3": events = [{"type":"level_won","levelId":step.level}]
		for raw: Dictionary in events:
			serial += 1
			var event := raw.duplicate(true); event.eventId = "slice-smoke-%d" % serial
			var reduced := Reducer.apply(state, event)
			assert(reduced.ok, "Rejected %s: %s" % [event.type, reduced.get("error", "")])
			state = reduced.state
	assert(Director.next_step(state).id == "done")
	assert(state.workPoints == 0 and state.completedRestorations.size() == 2)
	assert(state.recordedClues == ["RM-CLUE-01-CHILDHOOD-OBJECT"])
	assert(state.hotspotStates.get("RM-HS-004") == "recorded")
	var adapter := MemoryStorage.new(); var store := Store.new(adapter)
	assert(store.save_campaign(state))
	var resumed := Store.new(adapter).load_campaign()
	assert(Director.next_step(resumed).id == "done", "Completed vertical slice must resume after reload")
	print("Raven Manor RM-VS-01 smoke passed (narrative sync, multi-speaker VN, real Match-3, full route and resume).")
	quit()
