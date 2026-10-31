@tool
extends RefCounted
## Read-only descriptions of assets already declared by the selected UPDS project.
## Asset bytes remain in the local donor; no project resource is created.
const Reader = preload("res://addons/vn_studio/editor/legacy_reader.gd")

const NON_POSE := ["icon", "phone"]

static func character_ids(assets: Dictionary) -> Array[String]:
	var ids: Array[String] = []
	var characters: Dictionary = assets.get("characters", {})
	for key in characters:
		if key is String and characters[key] is Dictionary:
			ids.append(key)
	ids.sort()
	return ids


static func inspect(root: String, assets: Dictionary, character_id: String) -> Dictionary:
	var characters: Dictionary = assets.get("characters", {})
	var source: Dictionary = characters.get(character_id, {})
	if source.is_empty():
		return {"ok": false, "id": character_id, "error": "Персонаж не найден в каталоге UPDS."}
	var entries: Array[Dictionary] = []
	var names: Array = source.keys()
	names.sort()
	for name in names:
		if not name is String or not source[name] is String:
			continue
		var asset: String = source[name]
		var path: String = Reader.resource_path(root, asset)
		entries.append({
			"id": name,
			"kind": "icon" if name == "icon" else "special" if name == "phone" else "portrait",
			"exists": not path.is_empty(),
			"source": asset
		})
	return {
		"ok": true, "id": character_id, "entries": entries,
		"outfits": [], "layeredExpressions": false,
		"motionClips": [], "format": "UPDS-flat-portraits"
	}


static func pose_ids(root: String, assets: Dictionary, character_id: String, include_missing: bool = false) -> Array[String]:
	var options: Array[String] = []
	var result: Dictionary = inspect(root, assets, character_id)
	if not result.get("ok", false):
		return options
	for info in result["entries"]:
		if info["kind"] == "portrait" and (info["exists"] or include_missing):
			options.append(info["id"])
	return options


static func motion_presets() -> Array[Dictionary]:
	# UI preview only, not authored runtime cue tracks.
	return [
		{"id": "none", "name": "Без движения", "needsMotion": false},
		{"id": "soft_idle", "name": "Мягкое дыхание · тест", "needsMotion": true},
		{"id": "fade_in", "name": "Появление · тест", "needsMotion": true}
	]
