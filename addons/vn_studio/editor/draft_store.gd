@tool
extends RefCounted
## VN Studio v1 legacy overlays: local editor-only, never write back to UPDS.
## Drafts can contain private text: store them ONLY in user://, not res://.

const FORMAT := "vn-studio-legacy-overlay-v1"
const LOCALES := ["ru", "en", "be"]
const FIELDS := ["speaker", "emotion", "text"]


static func draft_path(root: String, entry: Dictionary) -> String:
	var base: String = ProjectSettings.globalize_path("user://vn_studio_drafts/v1")
	var folder: String = root.simplify_path().sha256_text()
	return base.path_join(folder).path_join("%02d.json" % int(entry["index"]))


static func source_hash(root: String, entry: Dictionary) -> String:
	var path: String = root.path_join("data").path_join(str(entry.get("file", "")))
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_sha256(path)


static func fresh(root: String, entry: Dictionary) -> Dictionary:
	return {
		"format": FORMAT,
		"schemaVersion": 1,
		"sceneId": str(entry["id"]),
		"source": {
			"rootFingerprint": root.simplify_path().sha256_text(),
			"sceneFile": str(entry["file"]),
			"baseSha256": source_hash(root, entry)
		},
		"patches": {}
	}


static func patch_key(group: String, line_index: int, line_id: String) -> String:
	# JSON array is unambiguous even for variants with the same lineId.
	return JSON.stringify([group, line_index, line_id])


static func load_draft(root: String, entry: Dictionary) -> Dictionary:
	var clean: Dictionary = fresh(root, entry)
	var path: String = draft_path(root, entry)
	if not FileAccess.file_exists(path):
		return {"ok": true, "draft": clean, "found": false}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "error": "Не удаётся открыть локальный черновик."}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		return {"ok": false, "error": "Черновик повреждён; исходник не изменён."}
	var draft: Dictionary = parsed
	var error: String = validate(root, entry, draft)
	if not error.is_empty():
		return {"ok": false, "error": error}
	return {"ok": true, "draft": draft, "found": true}


static func validate(root: String, entry: Dictionary, draft: Dictionary) -> String:
	var reference: Dictionary = fresh(root, entry)
	if reference["source"]["baseSha256"].is_empty():
		return "Исходная сцена отсутствует. Черновик не применяется."
	if draft.get("format") != FORMAT or draft.get("schemaVersion") != 1 or draft.get("sceneId") != entry["id"]:
		return "Неизвестный формат или ID черновика."
	if draft.get("source") != reference["source"]:
		return "Исходник UPDS изменился или выбран другой путь. Черновик заблокирован: требуется отдельный diff/rebase."
	var patches: Variant = draft.get("patches", {})
	if not patches is Dictionary:
		return "Некорректные patches."
	var groups: Dictionary = entry["groups"]
	for key in patches:
		if not key is String:
			return "Некорректный ключ реплики."
		var decoded: Variant = JSON.parse_string(key)
		if not decoded is Array or decoded.size() != 3:
			return "Некорректный ключ реплики."
		if not decoded[0] is String or not decoded[1] is float and not decoded[1] is int or not decoded[2] is String:
			return "Некорректные параметры ключа."
		var group: String = decoded[0]
		var index: int = int(decoded[1])
		if not groups.has(group):
			return "Несуществующая ветка."
		var lines: Array = groups[group]
		if index < 0 or index >= lines.size() or str(lines[index].get("id", "")) != decoded[2]:
			return "ID реплики изменился. Черновик не применяется."
		var patch: Variant = patches[key]
		if not patch is Dictionary:
			return "Некорректные изменения реплики."
		for patch_field in patch:
			if patch_field != "localized" and patch_field != "actors":
				return "Неизвестный тип изменения."
		var translations: Variant = patch.get("localized", {})
		if not translations is Dictionary:
			return "Некорректная локализация."
		for locale in translations:
			if locale not in LOCALES or not translations[locale] is Dictionary:
				return "Неизвестный язык."
			for field in translations[locale]:
				if field not in FIELDS or not translations[locale][field] is String:
					return "Недопустимое поле перевода."
		var actors: Variant = patch.get("actors", {})
		if not actors is Dictionary:
			return "Некорректные изменения персонажей."
		var originals: Array = lines[index].get("actors", [])
		for actor_key in actors:
			if not actor_key is String or not actor_key.is_valid_int():
				return "Некорректный индекс персонажа."
			var actor_idx: int = int(actor_key)
			if actor_idx < 0 or actor_idx >= originals.size() or not actors[actor_key] is Dictionary:
				return "Неизвестный персонаж."
			var altered: Dictionary = actors[actor_key]
			if altered.get("character") != originals[actor_idx].get("character"):
				return "ID персонажа изменён."
			for field in altered:
				if field not in ["character", "pose", "x", "y"]:
					return "Неизвестное поле персонажа."
			if altered.has("pose") and (not altered["pose"] is String or altered["pose"].is_empty()):
				return "Недопустимая поза."
			for field in ["x", "y"]:
				if altered.has(field):
					if not (altered[field] is float or altered[field] is int) or float(altered[field]) < 0.0 or float(altered[field]) > 1.0:
						return "Положение персонажа вне поля."
	return ""


static func materialize(line: Dictionary, draft: Dictionary, group: String, line_index: int) -> Dictionary:
	var output: Dictionary = line.duplicate(true)
	var key: String = patch_key(group, line_index, str(line.get("id", "")))
	var patch: Dictionary = draft.get("patches", {}).get(key, {})
	var translated: Dictionary = output.get("localized", {}).duplicate(true)
	var overrides: Dictionary = patch.get("localized", {})
	for lang in overrides:
		var cell: Dictionary = translated.get(lang, {}).duplicate(true)
		cell.merge(overrides[lang], true)
		translated[lang] = cell
	output["localized"] = translated
	var actors: Array = output.get("actors", []).duplicate(true)
	for idx in range(actors.size()):
		var changed: Dictionary = patch.get("actors", {}).get(str(idx), {})
		if changed.is_empty():
			continue
		var actor: Dictionary = actors[idx]
		if changed.has("pose"):
			actor["pose"] = changed["pose"]
		for prop in ["x", "y"]:
			if changed.has(prop):
				actor["vnStudio" + prop.to_upper()] = float(changed[prop])
		actors[idx] = actor
	output["actors"] = actors
	return output


static func set_localized(draft: Dictionary, group: String, idx: int, line_id: String, language: String, field: String, value: String) -> void:
	assert(language in LOCALES and field in FIELDS)
	var key: String = patch_key(group, idx, line_id)
	var patch: Dictionary = draft["patches"].get(key, {})
	var localized: Dictionary = patch.get("localized", {})
	var cell: Dictionary = localized.get(language, {})
	cell[field] = value
	localized[language] = cell
	patch["localized"] = localized
	draft["patches"][key] = patch


static func set_actor(draft: Dictionary, group: String, idx: int, line_id: String, actor_idx: int, character: String, field: String, value: Variant) -> void:
	assert(field in ["pose", "x", "y"])
	var key: String = patch_key(group, idx, line_id)
	var patch: Dictionary = draft["patches"].get(key, {})
	var actors: Dictionary = patch.get("actors", {})
	var change: Dictionary = actors.get(str(actor_idx), {"character": character})
	assert(change["character"] == character)
	change[field] = value
	actors[str(actor_idx)] = change
	patch["actors"] = actors
	draft["patches"][key] = patch


static func save_draft(root: String, entry: Dictionary, draft: Dictionary) -> Dictionary:
	var problem: String = validate(root, entry, draft)
	if not problem.is_empty():
		return {"ok": false, "error": problem}
	var destination: String = draft_path(root, entry)
	var folder: String = destination.get_base_dir()
	var created: Error = DirAccess.make_dir_recursive_absolute(folder)
	if created != OK:
		return {"ok": false, "error": "Не удалось создать локальный каталог черновиков."}
	var temp: String = destination + ".tmp-" + str(Time.get_ticks_usec())
	var file: FileAccess = FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "error": "Не удалось записать временный черновик."}
	file.store_string(JSON.stringify(draft, "\t") + "\n")
	file.flush()
	file.close()
	var backup: String = ""
	if FileAccess.file_exists(destination):
		backup = destination + ".backup-" + str(Time.get_ticks_usec())
		if DirAccess.rename_absolute(destination, backup) != OK:
			DirAccess.remove_absolute(temp)
			return {"ok": false, "error": "Не удалось сохранить прежнюю версию черновика."}
	var moved: Error = DirAccess.rename_absolute(temp, destination)
	if moved != OK:
		if not backup.is_empty():
			DirAccess.rename_absolute(backup, destination)
		DirAccess.remove_absolute(temp)
		return {"ok": false, "error": "Ошибка записи. Ранее сохранённый черновик сохранён."}
	if not backup.is_empty():
		DirAccess.remove_absolute(backup)
	return {"ok": true, "path": destination}
