extends RefCounted

## Versioned, Raven-only campaign state. It deliberately contains no UPDS story indexes.
const SCHEMA_VERSION := 1
const GAME_ID := "raven-manor"


static func fresh() -> Dictionary:
	return {
		"schemaVersion": SCHEMA_VERSION,
		"gameId": GAME_ID,
		"revision": 0,
		"workPoints": 0,
		"firstClearLevels": [],
		"completedRestorations": [],
		"unlockedDoors": ["RM-DOOR-HALL-CORRIDOR"],
		"hotspotStates": {},
		"recordedClues": [],
		"storyFlags": [],
		"storyBeatsSeen": [],
		"appliedEventIds": [],
		"lastRoomId": "RM-ROOM-HALL",
		"lastSafeAnchorId": "",
	}


static func normalize(value: Variant, catalog: Dictionary) -> Variant:
	if not value is Dictionary:
		return null
	if int(value.get("schemaVersion", -1)) != SCHEMA_VERSION or value.get("gameId") != GAME_ID:
		return null
	var result := fresh()
	result.revision = maxi(0, int(value.get("revision", 0)))
	result.workPoints = maxi(0, int(value.get("workPoints", 0)))
	result.firstClearLevels = _known_unique(value.get("firstClearLevels"), catalog.levels)
	result.completedRestorations = _known_unique(value.get("completedRestorations"), catalog.restorations)
	result.unlockedDoors = _known_unique(value.get("unlockedDoors"), catalog.doors)
	if not result.unlockedDoors.has("RM-DOOR-HALL-CORRIDOR"):
		result.unlockedDoors.append("RM-DOOR-HALL-CORRIDOR")
	result.recordedClues = _known_unique(value.get("recordedClues"), catalog.clues)
	result.storyFlags = _known_unique(value.get("storyFlags"), catalog.storyFlags)
	result.storyBeatsSeen = _known_unique(value.get("storyBeatsSeen"), catalog.storyBeats)
	result.appliedEventIds = _unique_strings(value.get("appliedEventIds"))
	var room_id := str(value.get("lastRoomId", "RM-ROOM-HALL"))
	result.lastRoomId = room_id if catalog.rooms.has(room_id) else "RM-ROOM-HALL"
	result.lastSafeAnchorId = str(value.get("lastSafeAnchorId", ""))
	var hotspot_states: Variant = value.get("hotspotStates")
	if hotspot_states is Dictionary:
		for hotspot_id in hotspot_states:
			if catalog.hotspots.has(hotspot_id) and hotspot_states[hotspot_id] is String:
				result.hotspotStates[hotspot_id] = hotspot_states[hotspot_id]
	return result


static func _known_unique(value: Variant, known: Variant) -> Array:
	var result := []
	if not value is Array:
		return result
	for id in value:
		if id is String and known.has(id) and not result.has(id):
			result.append(id)
	return result


static func _unique_strings(value: Variant) -> Array:
	var result := []
	if not value is Array:
		return result
	for id in value:
		if id is String and not id.is_empty() and not result.has(id):
			result.append(id)
	return result
