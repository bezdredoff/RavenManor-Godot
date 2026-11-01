@tool
extends RefCounted
## Read-only adapter over the actual Raven production catalogs. No inferred art.

const STAGING := "data/raven/production/vn_staging.json"
const BACKGROUNDS := "data/raven/production/vn_background_catalog.json"
const CHARACTERS := "data/raven/production/character_performance.json"


static func open_project(root: String) -> Dictionary:
	var staging: Dictionary = _read(root.path_join(STAGING))
	var backgrounds: Dictionary = _read(root.path_join(BACKGROUNDS))
	var characters: Dictionary = _read(root.path_join(CHARACTERS))
	if staging.is_empty() or backgrounds.is_empty() or characters.is_empty():
		return {"ok": false, "error": "Каталоги VN staging/background/character отсутствуют или повреждены."}
	return build(staging, backgrounds, characters, root)


static func build(staging: Dictionary, backgrounds: Dictionary, characters: Dictionary, root: String) -> Dictionary:
	var masters: Array = staging.get("masters", [])
	var variants: Array = backgrounds.get("entries", [])
	var cast: Array = characters.get("characters", [])
	if masters.size() != int(staging.get("masterCount", -1)) or variants.size() != int(backgrounds.get("variantCount", -1)):
		return {"ok": false, "error": "Счётчик мастеров или вариантов не совпадает с каталогом."}
	var master_ids: Dictionary = {}
	for master in masters:
		if not master is Dictionary or str(master.get("id", "")).is_empty() or master_ids.has(str(master["id"])):
			return {"ok": false, "error": "Пустой или повторный master ID."}
		master_ids[str(master["id"])] = master
	var seen: Dictionary = {}
	var records: Array[Dictionary] = []
	var issues: Array[String] = []
	for variant in variants:
		if not variant is Dictionary:
			return {"ok": false, "error": "Повреждённая запись фонового варианта."}
		var id: String = str(variant.get("id", ""))
		var group: String = str(variant.get("backgroundId", ""))
		var expected_id: String = "%s:%s:%s" % [group, str(variant.get("lighting", "")), str(variant.get("roomState", ""))]
		if id.is_empty() or seen.has(id) or id != expected_id or not master_ids.has(group):
			return {"ok": false, "error": "Повторный, неверный или неизвестный variant ID: " + id}
		seen[id] = true
		var width: int = int(variant.get("width", 0))
		var height: int = int(variant.get("height", 0))
		if width <= 0 or height <= 0:
			return {"ok": false, "error": "Неверный размер варианта: " + id}
		var path: String = str(variant.get("path", ""))
		var integrity: String = "ok"
		if not path.begins_with("res://assets/raven/vn_backgrounds/") or path.contains(".."):
			integrity = "invalid_path"
		else:
			var local_path: String = root.path_join(path.trim_prefix("res://"))
			if not FileAccess.file_exists(local_path):
				integrity = "missing_file"
			elif FileAccess.get_sha256(local_path) != str(variant.get("sha256", "")):
				integrity = "sha_mismatch"
		if integrity != "ok":
			issues.append("%s: %s" % [id, integrity])
		records.append({"id": id, "assetId": group, "groupId": group, "category": "background",
			"displayName": id, "path": path, "status": str(variant.get("status", "candidate")),
			"orientation": "portrait" if height > width else "landscape" if width > height else "square",
			"width": width, "height": height, "sha256": str(variant.get("sha256", "")),
			"integrity": integrity, "lighting": str(variant.get("lighting", "")),
			"roomState": str(variant.get("roomState", "")), "sourceType": str(variant.get("sourceType", "")),
			"rights": "not_recorded"})
	for person in cast:
		if not person is Dictionary:
			return {"ok": false, "error": "Повреждённая запись персонажа."}
		var id: String = str(person.get("id", ""))
		if id.is_empty() or seen.has(id):
			return {"ok": false, "error": "Повторный или пустой character ID: " + id}
		seen[id] = true
		records.append({"id": id, "assetId": id, "groupId": id, "category": "character",
			"displayName": id, "path": "", "status": "planned_metadata", "orientation": "unregistered",
			"integrity": "art_unregistered", "rights": "not_recorded", "poses": person.get("poses", []),
			"emotions": person.get("emotions", [])})
	return {"ok": true, "records": records, "masterIds": master_ids.keys(), "issues": issues,
		"backgroundCount": variants.size(), "characterCount": cast.size(), "propCount": 0}


static func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}
