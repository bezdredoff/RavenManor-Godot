@tool
extends RefCounted
## Raven Manor story source: the EXISTING season-one narrative production catalog.
## Unlike the legacy UPDS adapter, this corpus is public Raven project-owned data.
## Writes to res:// only after an explicit "Apply to project" click with SHA and backup.
const RELATIVE := "data/raven/production/season1_dialogue_catalog.json"
const STAGING := "data/raven/production/vn_staging.json"
const ROUTES := "data/raven/production/map_narrative_routes.json"
const CUES := "data/raven/production/line_performance_cues.json"
const FORMAT := "raven-vn-studio-draft-v1"
const LANGUAGES := ["ru", "be", "en"]


static func open_project(root: String) -> Dictionary:
	if not root.is_absolute_path() or not DirAccess.dir_exists_absolute(root):
		return {"ok": false, "error": "Корень проекта Raven Manor не найден."}
	var path: String = root.path_join(RELATIVE)
	var raw: Dictionary = _json(path)
	var staging: Dictionary = _json(root.path_join(STAGING))
	var routes: Dictionary = _json(root.path_join(ROUTES))
	var cues: Dictionary = _json(root.path_join(CUES))
	if raw.is_empty() or staging.is_empty() or routes.is_empty() or cues.is_empty():
		return {"ok": false, "error": "Для Raven нужны season1_dialogue_catalog, vn_staging, map_narrative_routes и line_performance_cues."}
	if not raw.get("scenes") is Array or not raw.get("entries") is Array:
		return {"ok": false, "error": "Неверный формат исходного каталога Raven."}
	var scene_ids: Dictionary = {}
	var line_ids: Dictionary = {}
	var order: Array = []
	for scene in raw["scenes"]:
		if not scene is Dictionary:
			return {"ok": false, "error": "Повреждённая запись сцены."}
		var id: String = str(scene.get("sceneId", ""))
		if id.is_empty() or scene_ids.has(id):
			return {"ok": false, "error": "Повторяющийся или пустой ID сцены."}
		scene_ids[id] = true
		order.append(id)
	var groupings: Dictionary = {}
	for id in order:
		groupings[id] = []
	for entry in raw["entries"]:
		if not entry is Dictionary:
			return {"ok": false, "error": "Повреждённая запись реплики."}
		var id: String = str(entry.get("id", ""))
		var scene_id: String = str(entry.get("sceneId", ""))
		if id.is_empty() or line_ids.has(id) or not scene_ids.has(scene_id):
			return {"ok": false, "error": "Дублирующийся lineId или сцена реплики отсутствует: " + id}
		if not entry.get("localized") is Dictionary:
			return {"ok": false, "error": "У реплики нет localized: " + id}
		if not entry["localized"].get("ru") is Dictionary or str(entry["localized"]["ru"].get("text", "")).is_empty():
			return {"ok": false, "error": "У реплики отсутствует оригинальный русский текст: " + id}
		line_ids[id] = true
		groupings[scene_id].append(entry)
	for id in order:
		if groupings[id].is_empty():
			return {"ok": false, "error": "Пустая сцена: " + id}
	var shots: Dictionary = {}
	for shot in staging.get("sceneShots", []):
		if shot is Dictionary:
			shots[str(shot.get("sceneId", ""))] = shot
	var triggers: Dictionary = {}
	for route in routes.get("sceneTriggers", []):
		if route is Dictionary:
			triggers[str(route.get("sceneId", ""))] = route
	var performance: Dictionary = {}
	for cue in cues.get("cues", []):
		if cue is Dictionary:
			performance[str(cue.get("lineId", ""))] = cue
	for id in order:
		if not shots.has(id) or not triggers.has(id):
			return {"ok": false, "error": "Нет постановки или trigger для сцены " + id}
	return {"ok": true, "root": root.simplify_path(), "sourcePath": path, "sha": FileAccess.get_sha256(path),
		"data": raw, "scenes": raw["scenes"], "linesByScene": groupings,
		"shots": shots, "routes": triggers, "cues": performance,
		"sceneCount": order.size(), "lineCount": line_ids.size()}


static func draft_path(root: String) -> String:
	return ProjectSettings.globalize_path("user://raven_story_studio/v1").path_join(root.simplify_path().sha256_text()).path_join("draft.json")


static func fresh(project: Dictionary) -> Dictionary:
	return {"format": FORMAT, "schemaVersion": 1,
		"sourceSha256": str(project.get("sha", "")),
		"sourceRootFingerprint": str(project.get("root", "")).sha256_text(),
		"patches": {}}


static func load_draft(project: Dictionary) -> Dictionary:
	var path: String = draft_path(str(project["root"]))
	if not FileAccess.file_exists(path):
		return {"ok": true, "found": false, "draft": fresh(project)}
	var existing: Dictionary = _json(path)
	var validation: String = validate(project, existing)
	if not validation.is_empty():
		return {"ok": false, "error": validation}
	return {"ok": true, "found": true, "draft": existing}


static func validate(project: Dictionary, draft: Dictionary) -> String:
	if not bool(project.get("ok", false)):
		return "Сначала откройте источник Raven."
	if draft.get("format") != FORMAT or draft.get("schemaVersion") != 1:
		return "Неподдерживаемая версия Raven draft."
	if draft.get("sourceSha256") != project.get("sha") or draft.get("sourceRootFingerprint") != str(project.get("root", "")).sha256_text():
		return "Raven-сценарий изменился после сохранения черновика. Нужен ручной diff; автоматический rebase запрещён."
	if FileAccess.get_sha256(str(project["sourcePath"])) != project["sha"]:
		return "Сценарий в репозитории изменён извне; повторно откройте редактор."
	var patches: Variant = draft.get("patches", {})
	if not patches is Dictionary:
		return "Повреждённый набор правок."
	var allowed: Dictionary = {}
	for entry in project["data"]["entries"]:
		allowed[str(entry["id"])] = true
	for id in patches:
		if not id is String or not allowed.has(id) or not patches[id] is Dictionary:
			return "Черновик содержит неизвестную реплику."
		for lang in patches[id]:
			if lang not in LANGUAGES or not patches[id][lang] is String:
				return "Недопустимая локализация черновика."
			if lang == "ru" and str(patches[id][lang]).strip_edges().is_empty():
				return "Русский текст не может быть пустым."
	return ""


static func edit(draft: Dictionary, line_id: String, language: String, text_value: String) -> void:
	assert(language in LANGUAGES)
	var changes: Dictionary = draft["patches"].get(line_id, {})
	changes[language] = text_value
	draft["patches"][line_id] = changes


static func localized(entry: Dictionary, draft: Dictionary, language: String) -> Dictionary:
	var text_value: Variant = entry.get("localized", {}).get(language)
	var raw: String = str(text_value.get("text", "")) if text_value is Dictionary else ""
	var changes: Dictionary = draft.get("patches", {}).get(str(entry.get("id", "")), {})
	var edited: bool = changes.has(language)
	if edited:
		raw = str(changes[language])
	if language != "ru" and raw.is_empty():
		var ru: Dictionary = localized(entry, draft, "ru")
		return {"text": ru["text"], "translated": false, "fallback": true, "edited": edited}
	return {"text": raw, "translated": not raw.is_empty(), "fallback": false, "edited": edited}


static func materialize(project: Dictionary, draft: Dictionary) -> Dictionary:
	var value: Dictionary = project.get("data", {}).duplicate(true)
	for entry in value.get("entries", []):
		var id: String = str(entry.get("id", ""))
		var patches: Dictionary = draft.get("patches", {}).get(id, {})
		for lang in patches:
			entry["localized"][lang] = {"text": patches[lang]}
	return value


static func change_count(draft: Dictionary) -> int:
	var count: int = 0
	for patch in draft.get("patches", {}).values():
		if patch is Dictionary:
			count += patch.size()
	return count


static func save_local(project: Dictionary, draft: Dictionary) -> Dictionary:
	var error: String = validate(project, draft)
	if not error.is_empty():
		return {"ok": false, "error": error}
	return _write_new(draft_path(str(project["root"])), JSON.stringify(draft, "\t") + "\n", true)


static func export_candidate(project: Dictionary, draft: Dictionary) -> Dictionary:
	var error: String = validate(project, draft)
	if not error.is_empty():
		return {"ok": false, "error": error}
	var folder: String = ProjectSettings.globalize_path("user://raven_story_studio/v1/exports")
	var result: Dictionary = materialize(project, draft)
	var target: String = folder.path_join("raven-season1-" + project["sha"].substr(0, 12) + "-" +
			JSON.stringify(draft["patches"]).sha256_text().substr(0, 12) + ".json")
	var saved: Dictionary = _write_new(target, JSON.stringify(result, "\t") + "\n", false)
	if saved["ok"]:
		saved["notice"] = "Локальный кандидат: не заменяет игровой сценарий. Для коммита нужен ревью и перенос в production catalog."
	return saved


static func _write_new(path: String, payload: String, overwrite: bool) -> Dictionary:
	if not overwrite and FileAccess.file_exists(path):
		return {"ok": false, "error": "Экспорт уже существует, перезапись запрещена.", "path": path}
	if DirAccess.make_dir_recursive_absolute(path.get_base_dir()) != OK:
		return {"ok": false, "error": "Не удалось создать папку."}
	var tmp: String = path + ".staging"
	if FileAccess.file_exists(tmp):
		return {"ok": false, "error": "Найден незавершённый staging. Проверьте его вручную."}
	var f: FileAccess = FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return {"ok": false, "error": "Не удалось открыть staging."}
	f.store_string(payload)
	f.flush()
	f.close()
	if FileAccess.get_file_as_string(tmp) != payload:
		return {"ok": false, "error": "Не совпала проверка записи."}
	if overwrite and FileAccess.file_exists(path):
		var backup: String = path + ".backup"
		if FileAccess.file_exists(backup):
			return {"ok": false, "error": "Существует резервная копия черновика; сначала проверьте её."}
		if DirAccess.rename_absolute(path, backup) != OK:
			return {"ok": false, "error": "Не удалось сохранить резервную копию."}
		if DirAccess.rename_absolute(tmp, path) != OK:
			DirAccess.rename_absolute(backup, path)
			return {"ok": false, "error": "Не удалось заменить черновик."}
		DirAccess.remove_absolute(backup)
	elif DirAccess.rename_absolute(tmp, path) != OK:
		return {"ok": false, "error": "Не удалось завершить запись."}
	return {"ok": true, "path": path}


static func _json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}
