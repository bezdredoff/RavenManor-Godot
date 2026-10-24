extends RefCounted

## Pure Raven state transitions. UI, Match-3 and VN send commands; only this reducer mutates snapshots.
const Ids = preload("res://scripts/raven/raven_ids.gd")


static func apply(state: Dictionary, event: Dictionary, catalog: Dictionary = Ids.CATALOG.data) -> Dictionary:
	var event_id := str(event.get("eventId", ""))
	if event_id.is_empty():
		return _error("event-id-required")
	if state.get("appliedEventIds", []).has(event_id):
		return {"ok": true, "duplicate": true, "state": state}
	var next := state.duplicate(true)
	var outcome: Dictionary
	match str(event.get("type", "")):
		"level_won":
			outcome = _level_won(next, event, catalog)
		"restoration_purchase":
			outcome = _restoration_purchase(next, event, catalog)
		"door_unlock":
			outcome = _append_known(next, "unlockedDoors", str(event.get("doorId", "")), catalog.doors, "unknown-door")
		"hotspot_state":
			outcome = _hotspot_state(next, event, catalog)
		"clue_recorded":
			outcome = _append_known(next, "recordedClues", str(event.get("clueId", "")), catalog.clues, "unknown-clue")
		"story_flag_set":
			outcome = _append_known(next, "storyFlags", str(event.get("flagId", "")), catalog.storyFlags, "unknown-story-flag")
		"story_beat_seen":
			outcome = _append_known(next, "storyBeatsSeen", str(event.get("storyBeatId", "")), catalog.storyBeats, "unknown-story-beat")
		"position_checkpoint":
			outcome = _position_checkpoint(next, event, catalog)
		_:
			return _error("unknown-event-type")
	if not outcome.get("ok", false):
		return outcome
	if outcome.get("duplicate", false):
		return {"ok": true, "duplicate": true, "state": state}
	next.appliedEventIds.append(event_id)
	next.revision += 1
	return {"ok": true, "duplicate": false, "state": next}


static func _level_won(state: Dictionary, event: Dictionary, catalog: Dictionary) -> Dictionary:
	var level_id := str(event.get("levelId", ""))
	if not catalog.levels.has(level_id):
		return _error("unknown-level")
	if state.firstClearLevels.has(level_id):
		return {"ok": true, "duplicate": true}
	state.firstClearLevels.append(level_id)
	state.workPoints += int(catalog.levels[level_id].reward)
	return {"ok": true}


static func _restoration_purchase(state: Dictionary, event: Dictionary, catalog: Dictionary) -> Dictionary:
	var restoration_id := str(event.get("restorationId", ""))
	if not catalog.restorations.has(restoration_id):
		return _error("unknown-restoration")
	if state.completedRestorations.has(restoration_id):
		return {"ok": true, "duplicate": true}
	var item: Dictionary = catalog.restorations[restoration_id]
	for level_id in item.get("requiresLevels", []):
		if not state.firstClearLevels.has(level_id):
			return _error("level-prerequisite-missing")
	for required_id in item.get("requiresRestorations", []):
		if not state.completedRestorations.has(required_id):
			return _error("restoration-prerequisite-missing")
	for flag_id in item.get("requiresFlags", []):
		if not state.storyFlags.has(flag_id):
			return _error("story-flag-prerequisite-missing")
	var cost := int(item.get("cost", 0))
	if state.workPoints < cost:
		return _error("insufficient-work-points")
	state.workPoints -= cost
	state.completedRestorations.append(restoration_id)
	return {"ok": true}


static func _append_known(state: Dictionary, field: String, id: String, known: Variant, error_code: String) -> Dictionary:
	if not known.has(id):
		return _error(error_code)
	if state[field].has(id):
		return {"ok": true, "duplicate": true}
	state[field].append(id)
	return {"ok": true}


static func _hotspot_state(state: Dictionary, event: Dictionary, catalog: Dictionary) -> Dictionary:
	var hotspot_id := str(event.get("hotspotId", ""))
	var value := str(event.get("state", ""))
	if not catalog.hotspots.has(hotspot_id):
		return _error("unknown-hotspot")
	if value.is_empty():
		return _error("hotspot-state-required")
	if state.hotspotStates.get(hotspot_id) == value:
		return {"ok": true, "duplicate": true}
	state.hotspotStates[hotspot_id] = value
	return {"ok": true}


static func _position_checkpoint(state: Dictionary, event: Dictionary, catalog: Dictionary) -> Dictionary:
	var room_id := str(event.get("roomId", ""))
	if not catalog.rooms.has(room_id):
		return _error("unknown-room")
	state.lastRoomId = room_id
	state.lastSafeAnchorId = str(event.get("anchorId", ""))
	return {"ok": true}


static func _error(code: String) -> Dictionary:
	return {"ok": false, "error": code}
