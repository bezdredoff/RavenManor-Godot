extends RefCounted

## Versioned, Raven-only campaign state. It deliberately contains no UPDS story indexes.
const SCHEMA_VERSION := 1
const GAME_ID := "raven-manor"
const ReadHistory = preload("res://scripts/raven/raven_vn_read_history.gd")
const BoosterInventory = preload("res://scripts/raven/raven_booster_inventory.gd")


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
		"vnCursor": {},
		"vnReadLines": [],
		"match3Checkpoint": {},
		"boosterInventory": BoosterInventory.fresh(),
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
	result.vnReadLines = ReadHistory.normalize(value.get("vnReadLines", []))
	result.appliedEventIds = _unique_strings(value.get("appliedEventIds"))
	result.boosterInventory = BoosterInventory.normalize(value.get("boosterInventory", {}))
	var room_id := str(value.get("lastRoomId", "RM-ROOM-HALL"))
	result.lastRoomId = room_id if catalog.rooms.has(room_id) else "RM-ROOM-HALL"
	result.lastSafeAnchorId = str(value.get("lastSafeAnchorId", ""))
	var cursor: Variant = value.get("vnCursor", {})
	if cursor is Dictionary:
		var beat_id := str(cursor.get("beatId", ""))
		var line_index: Variant = cursor.get("lineIndex", -1)
		# JSON.parse_string returns numeric values as floats; accept only exact
		# non-negative integral values, never fractional or string indices.
		var valid_index: bool = (line_index is int or line_index is float) and is_finite(float(line_index)) and float(line_index) == floor(float(line_index)) and float(line_index) >= 0.0 and float(line_index) < 10000.0
		if catalog.storyBeats.has(beat_id) and valid_index and not result.storyBeatsSeen.has(beat_id):
			result.vnCursor = {"beatId": beat_id, "lineIndex": int(line_index)}
	var checkpoint: Variant = value.get("match3Checkpoint", {})
	if checkpoint is Dictionary:
		var level_id := str(checkpoint.get("levelId", ""))
		var actions: Variant = checkpoint.get("actions", [])
		if catalog.levels.has(level_id) and not result.firstClearLevels.has(level_id) and actions is Array and actions.size() <= 500:
			var safe_actions := []
			var valid := true
			for action in actions:
				if not action is Dictionary:
					valid = false
					break
				var kind := str(action.get("kind", ""))
				if kind == "swap" and _valid_board_index(action.get("first")) and _valid_board_index(action.get("second")):
					safe_actions.append({"kind": "swap", "first": int(action.first), "second": int(action.second)})
				elif kind == "special" and _valid_board_index(action.get("index")):
					safe_actions.append({"kind": "special", "index": int(action.index)})
				elif kind == "booster" and BoosterInventory.KINDS.has(str(action.get("booster", ""))) and _valid_board_index(action.get("index")):
					safe_actions.append({"kind": "booster", "booster": str(action.booster), "index": int(action.index)})
				elif kind == "shuffle":
					safe_actions.append({"kind": "shuffle"})
				else:
					valid = false
					break
			if valid and not safe_actions.is_empty():
				result.match3Checkpoint = {"levelId": level_id, "actions": safe_actions}
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


static func _valid_board_index(value: Variant) -> bool:
	# JSON.parse_string decodes integer-valued JSON numbers as floats.
	# Reject fractional, nonnumeric, NaN, infinite and out-of-bounds indices.
	if not (value is int or value is float):
		return false
	var number: float = float(value)
	return is_finite(number) and number == floor(number) and number >= 0.0 and number < 256.0
