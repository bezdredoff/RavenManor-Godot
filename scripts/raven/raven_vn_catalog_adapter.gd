extends RefCounted
## Canonical line-ID and translation adapter for legacy RM-VS-01 playback.
## The reviewed VN Studio production catalog is the only source of spoken text.
## Legacy beat structure still governs progression, never this translation layer.
const Dialogue = preload("res://data/raven/production/season1_dialogue_catalog.json")
const Copy = preload("res://scripts/raven/raven_production_localization.gd")


static func for_legacy(source: Dictionary, selected_locale: String = "ru") -> Dictionary:
	var beat_id: String = str(source.get("beatId", ""))
	var original: Array = source.get("lines", [])
	var entries: Array = []
	for entry: Dictionary in Dialogue.data.entries:
		if entry.get("sceneId") == beat_id:
			entries.append(entry)
	if entries.size() != original.size() or entries.is_empty():
		push_error("VN locale: catalog line count mismatch for " + beat_id)
		return source.duplicate(true)
	# Fail closed rather than pairing a changed Russian line with the wrong ID.
	for index in original.size():
		if not original[index] is Dictionary or str(original[index].get("text", "")) != \
				str(entries[index].get("localized", {}).get("ru", {}).get("text", "")):
			push_error("VN locale: source/catalog drift for " + beat_id + " line " + str(index))
			return source.duplicate(true)
	var config: Dictionary = source.duplicate(true)
	var lines: Array = []
	var line_ids: Array = []
	var lang: String = Copy.normalize_locale(selected_locale)
	for entry: Dictionary in entries:
		line_ids.append(str(entry.get("id", "")))
		lines.append({"speaker": Copy.speaker_name(str(entry.get("speakerId", "")), lang),
			"text": Copy.line_text(str(entry.get("id", "")), lang)})
	config["lines"] = lines
	config["lineIds"] = line_ids
	config["title"] = Copy.scene_title(beat_id, lang)
	return config
