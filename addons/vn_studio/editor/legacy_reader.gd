@tool
extends RefCounted
## An intentionally read-only reader for an authorized local UPDS-godot checkout.
## It never writes into the donor, user://, or the Raven project.

const REQUIRED_LOCALES := ["ru", "en", "be"]


static func read_project(folder: String) -> Dictionary:
	var root_path: String = folder.simplify_path()
	if not root_path.is_absolute_path() or not DirAccess.dir_exists_absolute(root_path):
		return {"ok": false, "error": "Выберите существующую абсолютную папку UPDS-godot."}
	var contract: Dictionary = _read_json(root_path.path_join("data/save_contract.json"))
	var layouts: Dictionary = _read_json(root_path.path_join("data/actor_layouts.json"))
	var catalog: Dictionary = _read_json(root_path.path_join("data/asset_catalog.json"))
	if contract.is_empty() or layouts.is_empty() or catalog.is_empty():
		return {"ok": false, "error": "Нужен корень UPDS-godot с data/save_contract.json, actor_layouts.json и asset_catalog.json."}
	var identifiers: Array = contract.get("storySceneIds", [])
	if identifiers.is_empty() or identifiers.size() != 45:
		return {"ok": false, "error": "Неизвестный контракт сцен: ожидаются 45 sceneId из UPDS-godot. Файлы не изменены."}
	var path_by_id: Dictionary = {}
	var data_directory: String = root_path.path_join("data")
	var filenames: PackedStringArray = DirAccess.get_files_at(data_directory)
	for filename in filenames:
		if not filename.ends_with("_scene.json") and filename != "prologue.json":
			continue
		var full_path: String = data_directory.path_join(filename)
		var candidate: Dictionary = _read_json(full_path)
		var key: String = str(candidate.get("sceneId", ""))
		if key.is_empty() or path_by_id.has(key):
			return {"ok": false, "error": "Повреждённый или повторяющийся sceneId: " + filename}
		path_by_id[key] = filename
	if path_by_id.size() != identifiers.size():
		return {"ok": false, "error": "Количество файлов VN отличается от контракта; импорт остановлен, исходники не изменены."}
	var scene_list: Array[Dictionary] = []
	for scene_id in identifiers:
		var id: String = str(scene_id)
		if not path_by_id.has(id):
			return {"ok": false, "error": "Нет сцены " + id + " из save_contract.json."}
		var scene: Dictionary = _read_json(data_directory.path_join(str(path_by_id[id])))
		if scene.is_empty():
			return {"ok": false, "error": "Ошибка чтения сцены " + id}
		var groups: Dictionary = line_groups(scene)
		if groups.is_empty():
			return {"ok": false, "error": "У сцены нет доступных строк: " + id}
		var index: int = scene_list.size()
		if scene.has("sceneIndex") and int(scene["sceneIndex"]) != index:
			return {"ok": false, "error": "sceneIndex расходится с save_contract: " + id}
		scene_list.append({
			"id": id,
			"index": index,
			"file": str(path_by_id[id]),
			"data": scene,
			"groups": groups
		})
	return {
		"ok": true,
		"root": root_path,
		"scenes": scene_list,
		"catalog": catalog.get("assets", {}),
		"layouts": layouts,
		"contract": contract
	}


static func line_groups(scene: Dictionary) -> Dictionary:
	var groups: Dictionary = {}
	if scene.get("lines") is Array:
		groups["base"] = scene["lines"]
	if scene.get("variants") is Dictionary:
		var variants: Dictionary = scene["variants"]
		for name in variants:
			if name is String and variants[name] is Array:
				groups[name] = variants[name]
	return groups


static func localize_line(line: Dictionary, language: String) -> Dictionary:
	var languages: Dictionary = line.get("localized", {})
	var selected: Dictionary = languages.get(language, {})
	return {
		"id": str(line.get("id", "")),
		"hidden": bool(line.get("hidden", false)),
		"speaker": str(selected.get("speaker", "—")),
		"emotion": str(selected.get("emotion", "")),
		"text": str(selected.get("text", "⚠ отсутствует перевод")),
		"actors": line.get("actors", []),
		"background": str(line.get("background", ""))
	}


static func resource_path(root: String, asset: String) -> String:
	# No arbitrary code, file or URL loading: assets must be inside selected donor/assets.
	if not asset.begins_with("res://assets/") or asset.contains("..") or asset.contains("\\"):
		return ""
	var suffix: String = asset.trim_prefix("res://")
	var full_path: String = root.path_join(suffix).simplify_path()
	var base_path: String = root.path_join("assets").simplify_path()
	if not full_path.begins_with(base_path + "/"):
		return ""
	return full_path if FileAccess.file_exists(full_path) else ""


static func image_for(root: String, catalog: Dictionary, category: String, asset_id: String, pose: String = "") -> Texture2D:
	var raw_path: String = ""
	if category == "backgrounds":
		raw_path = str(catalog.get("backgrounds", {}).get(asset_id, ""))
	elif category == "characters":
		var character: Dictionary = catalog.get("characters", {}).get(asset_id, {})
		raw_path = str(character.get(pose, character.get("neutral", "")))
	var location: String = resource_path(root, raw_path)
	if location.is_empty():
		return null
	var image: Image = Image.new()
	if image.load(location) != OK:
		return null
	return ImageTexture.create_from_image(image)


static func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var source: String = FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(source)
	return parsed if parsed is Dictionary else {}
