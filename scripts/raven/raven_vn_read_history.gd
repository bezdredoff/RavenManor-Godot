extends RefCounted
## UPDS StorySession._mark_read / VN screen._skip_read_lines adapter.
## Only canonical completed line IDs persist; never infer reading from beat flags.
const Dialogue = preload("res://data/raven/production/season1_dialogue_catalog.json")
const Copy = preload("res://scripts/raven/raven_production_localization.gd")

static func normalize(value: Variant) -> Array:
	var known: Dictionary = {}
	for line: Dictionary in Dialogue.data.entries:
		known[str(line.id)] = true
	var result: Array = []
	if value is Array:
		for id in value:
			if id is String and known.has(id) and not result.has(id):
				result.append(id)
	return result

static func current_id(config: Dictionary, index: int) -> String:
	var ids: Array = config.get("lineIds", [])
	return str(ids[index]) if index >= 0 and index < ids.size() else ""

static func mark_read(state: Dictionary, id: String) -> void:
	if not normalize([id]).is_empty() and not state.vnReadLines.has(id):
		state.vnReadLines.append(id)

static func at_checkpoint(config: Dictionary, index: int) -> bool:
	var id := current_id(config, index)
	if id.is_empty(): return true  # Unmapped content cannot be auto-skipped.
	for key in ["choiceGate", "match3Gate"]:
		var gate: Variant = config.get(key, {})
		if gate is Dictionary and str(gate.get("checkpointLineId", "")) == id:
			return true
	return config.get("checkpointLineIds", []).has(id)

static func skip_target(config: Dictionary, index: int, read_lines: Array) -> int:
	var ids: Array = config.get("lineIds", [])
	if ids.size() != config.get("lines", []).size() or index < 0 or index >= ids.size():
		return index
	var target := index
	while target < ids.size():
		if at_checkpoint(config, target) or not read_lines.has(str(ids[target])):
			break
		target += 1
	# Same boundary as UPDS: do not complete a scene or invoke a story gate.
	return target if target < ids.size() else index

static func localized_entries(read_lines: Array, locale: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for id in normalize(read_lines):
		for line: Dictionary in Dialogue.data.entries:
			if line.id == id:
				result.append({"speaker": Copy.speaker_name(str(line.speakerId), locale),
					"text": Copy.line_text(id, locale)})
				break
	return result
