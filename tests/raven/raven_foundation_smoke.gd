extends SceneTree

const Ids = preload("res://scripts/raven/raven_ids.gd")
const Snapshot = preload("res://scripts/raven/raven_snapshot.gd")
const Reducer = preload("res://scripts/raven/raven_reducer.gd")
const Store = preload("res://scripts/raven/raven_campaign_store.gd")
const MemoryStorage = preload("res://tests/support/memory_storage.gd")
const CONTRACT = preload("res://data/save_contract.json")


func _initialize() -> void:
	var state := Snapshot.fresh()
	assert(state.workPoints == 0)
	assert(state.unlockedDoors == ["RM-DOOR-HALL-CORRIDOR"])
	assert(Ids.resolve_door("RM-DOOR-HALL-BEDROOM") == "RM-DOOR-CORRIDOR-BEDROOM")

	var premature := Reducer.apply(state, _restore("event-rest-early", "RM-REST-001"))
	assert(not premature.ok and premature.error == "level-prerequisite-missing")

	var first_win := {"eventId": "event-level-1", "type": "level_won", "levelId": "RM-LVL-001"}
	state = _accepted(state, first_win)
	assert(state.workPoints == 2 and state.firstClearLevels == ["RM-LVL-001"])
	assert(Reducer.apply(state, first_win).duplicate)
	assert(Reducer.apply(state, {"eventId": "event-level-1-callback-2", "type": "level_won", "levelId": "RM-LVL-001"}).duplicate)
	assert(state.workPoints == 2 and state.revision == 1)

	var missing_access := Reducer.apply(state, _restore("event-rest-1-early", "RM-REST-001"))
	assert(not missing_access.ok and missing_access.error == "story-flag-prerequisite-missing")
	state = _accepted(state, {"eventId": "event-access", "type": "story_flag_set", "flagId": "RM-FLAG-BEDROOM-ACCESS-CLEARED"})
	state = _accepted(state, {"eventId": "event-door", "type": "door_unlock", "doorId": "RM-DOOR-CORRIDOR-BEDROOM"})
	state = _accepted(state, _restore("event-rest-1", "RM-REST-001"))
	assert(state.workPoints == 0 and state.completedRestorations == ["RM-REST-001"])
	assert(Reducer.apply(state, _restore("event-rest-1-repeat", "RM-REST-001")).duplicate)

	state = _accepted(state, {"eventId": "event-level-2", "type": "level_won", "levelId": "RM-LVL-002"})
	var insufficient := Reducer.apply(state, _restore("event-rest-2-insufficient", "RM-REST-002"))
	assert(not insufficient.ok and insufficient.error == "level-prerequisite-missing")
	state = _accepted(state, {"eventId": "event-level-3", "type": "level_won", "levelId": "RM-LVL-003"})
	var no_specialist := Reducer.apply(state, _restore("event-rest-2-no-plumber", "RM-REST-002"))
	assert(not no_specialist.ok and no_specialist.error == "story-flag-prerequisite-missing")
	state = _accepted(state, {"eventId": "event-plumber", "type": "story_flag_set", "flagId": "service.plumber_available"})
	state = _accepted(state, _restore("event-rest-2", "RM-REST-002"))
	assert(state.workPoints == 0 and state.completedRestorations.has("RM-REST-002"))

	state = _accepted(state, {"eventId": "event-hotspot", "type": "hotspot_state", "hotspotId": "RM-HS-004", "state": "recorded"})
	state = _accepted(state, {"eventId": "event-clue", "type": "clue_recorded", "clueId": "RM-CLUE-01-CHILDHOOD-OBJECT"})
	state = _accepted(state, {"eventId": "event-beat", "type": "story_beat_seen", "storyBeatId": "RM-BEAT-01-05"})
	state = _accepted(state, {"eventId": "event-position", "type": "position_checkpoint", "roomId": "RM-ROOM-BEDROOM", "anchorId": "bedroom-entry-safe"})

	var adapter := MemoryStorage.new()
	var store := Store.new(adapter)
	assert(store.save_campaign(state))
	var loaded := Store.new(adapter).load_campaign()
	assert(loaded == state)
	assert(loaded.recordedClues == ["RM-CLUE-01-CHILDHOOD-OBJECT"])
	assert(loaded.hotspotStates["RM-HS-004"] == "recorded")
	assert(loaded.lastRoomId == "RM-ROOM-BEDROOM" and loaded.lastSafeAnchorId == "bedroom-entry-safe")

	adapter.values[CONTRACT.data.ravenKey] = "{broken"
	var recovered := Store.new(adapter)
	assert(recovered.load_campaign() == Snapshot.fresh())
	assert(recovered.last_load_report.status == "recovered-corrupt")
	assert(recovered.get_recovery_backup().raw == "{broken")
	adapter.fail_write = true
	assert(not store.save_campaign(state))

	print("Raven Manor foundation smoke passed (rewards, restoration, IDs, persistence and recovery).")
	quit()


func _accepted(state: Dictionary, event: Dictionary) -> Dictionary:
	var result := Reducer.apply(state, event)
	assert(result.ok and not result.duplicate)
	return result.state


func _restore(event_id: String, restoration_id: String) -> Dictionary:
	return {"eventId": event_id, "type": "restoration_purchase", "restorationId": restoration_id}
