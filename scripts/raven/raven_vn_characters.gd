@tool
extends RefCounted
## Shared, approved VN art registry. Does not own story, save or map state.
const Catalog = preload("res://data/raven/production/vn_character_catalog.json")
const Staging = preload("res://data/raven/production/vn_staging.json")
const Cues = preload("res://data/raven/production/line_performance_cues.json")
const Dialogue = preload("res://data/raven/production/season1_dialogue_catalog.json")
static var _textures: Dictionary = {}


static func all_entries() -> Array:
	return Catalog.data.get("entries", [])


static func entries_for(character_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item: Dictionary in all_entries():
		if item.get("characterId") == character_id:
			result.append(item)
	return result


static func entry_for_id(asset_id: String) -> Dictionary:
	for item: Dictionary in all_entries():
		if item.get("id") == asset_id:
			return item
	return {}


static func resolve(character_id: String, pose: String, emotion: String, asset_id: String = "", prop_id: String = "", allow_fallback: bool = true) -> Dictionary:
	if not asset_id.is_empty():
		var explicit: Dictionary = entry_for_id(asset_id)
		if explicit.get("characterId") != character_id or explicit.get("pose") != pose or explicit.get("emotion") != emotion:
			return {"entry": {}, "exact": false, "reason": "invalid_asset"}
		return {"entry": explicit, "exact": true, "reason": "selected"}
	var candidates: Array[Dictionary] = entries_for(character_id)
	var pose_neutral: Dictionary = {}
	for item: Dictionary in candidates:
		if item.get("pose") != pose:
			continue
		var matches_prop: bool = not prop_id.is_empty() and prop_id in item.get("propIds", [])
		if not matches_prop and (not prop_id.is_empty() or not item.get("defaultForPose", false)):
			continue
		if item.get("emotion") == emotion:
			return {"entry": item, "exact": true, "reason": "exact"}
		if item.get("emotion") == "neutral" and pose_neutral.is_empty():
			pose_neutral = item
	if not allow_fallback:
		return {"entry": {}, "exact": false, "reason": "not_generated"}
	if not pose_neutral.is_empty():
		return {"entry": pose_neutral, "exact": false, "reason": "neutral_expression"}
	# A cue may name a scene-level object owned by another actor. Never borrow
	# that actor's image or silently put its prop into this character's hands.
	if not prop_id.is_empty():
		var without_prop: Dictionary = resolve(character_id, pose, emotion)
		without_prop["exact"] = false
		without_prop["reason"] = "prop_not_available"
		return without_prop
	for item: Dictionary in candidates:
		if item.get("pose") == pose and item.get("emotion") == "neutral" and item.get("defaultForPose", false):
			return {"entry": item, "exact": false, "reason": "neutral_expression"}
	return {"entry": {}, "exact": false, "reason": "not_generated"}


static func texture_for_entry(item: Dictionary) -> Texture2D:
	var path: String = str(item.get("path", ""))
	if not path.begins_with("res://assets/raven/characters/") or not ResourceLoader.exists(path):
		return null
	if not _textures.has(path):
		if _textures.size() >= 8:
			_textures.erase(_textures.keys()[0])
		_textures[path] = load(path) as Texture2D
	return _textures[path] as Texture2D


static func for_actor(actor: Dictionary, allow_fallback: bool = true) -> Dictionary:
	return resolve(str(actor.get("characterId", "")), str(actor.get("pose", "")), str(actor.get("emotion", "neutral")), str(actor.get("assetId", "")), str(actor.get("propId", "")), allow_fallback)


static func texture_for_actor(actor: Dictionary) -> Texture2D:
	return texture_for_entry(for_actor(actor).get("entry", {}))


static func line_id_for_text(scene_id: String, text: String) -> String:
	# Current RM-VS-01 lines do not all carry canonical line IDs. Match the
	# unchanged original text, never invent an ID from an array position.
	var found: String = ""
	for item: Dictionary in Dialogue.data.get("entries", []):
		if item.get("sceneId") == scene_id and item.get("localized", {}).get("ru", {}).get("text") == text:
			if not found.is_empty():
				return ""
			found = str(item.get("id", ""))
	return found


static func cast_for_scene(scene_id: String, line_id: String = "") -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for shot: Dictionary in Staging.data.get("sceneShots", []):
		if shot.get("sceneId") == scene_id:
			for original: Dictionary in shot.get("cast", []):
				var actor: Dictionary = original.duplicate(true)
				for cue: Dictionary in Cues.data.get("cues", []):
					if not line_id.is_empty() and cue.get("lineId") == line_id and cue.get("speakerId") == actor.get("characterId"):
						actor.erase("assetId")
						actor["pose"] = cue.get("poseId", actor.get("pose"))
						actor["emotion"] = cue.get("emotionId", actor.get("emotion"))
						if cue.get("propOverlayId") is String:
							actor["propId"] = cue["propOverlayId"]
				result.append(actor)
			break
	return result
