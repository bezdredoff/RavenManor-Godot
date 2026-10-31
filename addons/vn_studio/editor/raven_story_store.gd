@tool
extends RefCounted
## Raven Manor story source: the EXISTING season-one narrative production catalog.
## Unlike the legacy UPDS adapter, this corpus is public Raven project-owned data.
## Writes to res:// only after an explicit "Apply to project" click with SHA and backup.
const RELATIVE := "data/raven/production/season1_dialogue_catalog.json"
const STAGING := "data/raven/production/vn_staging.json"
const ROUTES := "data/raven/production/map_narrative_routes.json"
const CUES := "data/raven/production/line_performance_cues.json"
const CAST := "data/raven/production/character_performance.json"
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
	var cast_info: Dictionary = _json(root.path_join(CAST))
	if raw.is_empty() or staging.is_empty() or routes.is_empty() or cues.is_empty() or cast_info.is_empty():
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
		"stagingData": staging, "stagingSha": FileAccess.get_sha256(root.path_join(STAGING)),
		"castData": cast_info, "castSha": FileAccess.get_sha256(root.path_join(CAST)),
		"shots": shots, "routes": triggers, "cues": performance,
		"sceneCount": order.size(), "lineCount": line_ids.size()}


static func draft_path(root: String) -> String:
	return ProjectSettings.globalize_path("user://raven_story_studio/v1").path_join(root.simplify_path().sha256_text()).path_join("draft.json")


static func fresh(project: Dictionary) -> Dictionary:
	return {"format": FORMAT, "schemaVersion": 1,
		"sourceSha256": str(project.get("sha", "")),
		"sourceRootFingerprint": str(project.get("root", "")).sha256_text(),
		"stageSourceSha256": str(project.get("stagingSha", "")),
		"castSourceSha256": str(project.get("castSha", "")),
		"patches": {}, "stagePatches": {}}


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
	var stage_patches: Variant = draft.get("stagePatches", {})
	if not stage_patches is Dictionary:
		return "Повреждённый список изменений постановки."
	if not stage_patches.is_empty():
		if draft.get("stageSourceSha256", "") != project.get("stagingSha", "") or draft.get("castSourceSha256", "") != project.get("castSha", ""):
			return "Исходная постановка или справочник персонажей изменились. Нужен ручной diff."
		if FileAccess.get_sha256(str(project["root"]).path_join(STAGING)) != project["stagingSha"] or FileAccess.get_sha256(str(project["root"]).path_join(CAST)) != project["castSha"]:
			return "Постановка изменилась на диске после открытия. Повторно откройте проект."
		for stage_id in stage_patches:
			if not project["shots"].has(stage_id):
				return "В черновике неизвестная сцена постановки."
			var stage_error: String = validate_stage(project, stage_patches[stage_id])
			if not stage_error.is_empty():
				return "%s: %s" % [stage_id, stage_error]
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


## Returns only the selected authored production-stage shot, never modifies res://.
static func effective_stage(project: Dictionary, draft: Dictionary, scene_id: String) -> Dictionary:
	return draft.get("stagePatches", {}).get(scene_id, project.get("shots", {}).get(scene_id, {})).duplicate(true)


static func stage_options(project: Dictionary) -> Dictionary:
	var backgrounds: Array[String] = []
	for master in project.get("stagingData", {}).get("masters", []):
		backgrounds.append(str(master.get("id", "")))
	var actors: Dictionary = {}
	for actor in project.get("castData", {}).get("characters", []):
		actors[str(actor.get("id", ""))] = actor
	return {"backgrounds": backgrounds, "actors": actors}


static func stage_master(project: Dictionary, bg_id: String) -> Dictionary:
	for master in project.get("stagingData", {}).get("masters", []):
		if str(master.get("id", "")) == bg_id:
			return master
	return {}


static func validate_stage(project: Dictionary, stage: Variant) -> String:
	if not stage is Dictionary:
		return "Постановка должна быть объектом."
	var id: String = str(stage.get("sceneId", ""))
	if not project.get("shots", {}).has(id):
		return "Неизвестная сцена."
	var original: Dictionary = project["shots"][id]
	var approved: Dictionary = original.duplicate(true)
	approved["backgroundId"] = stage.get("backgroundId")
	approved["lighting"] = stage.get("lighting")
	approved["roomState"] = stage.get("roomState")
	approved["cast"] = stage.get("cast")
	approved["visibleCount"] = stage.get("visibleCount")
	if stage != approved:
		return "Изменены поля вне backgroundId/lighting/roomState/cast/visibleCount."
	var opts: Dictionary = stage_options(project)
	if stage.get("backgroundId") not in opts["backgrounds"]:
		return "Фон отсутствует в каталоге постановки."
	var master: Dictionary = stage_master(project, str(stage.get("backgroundId", "")))
	if stage.get("lighting") not in master.get("lightingVariants", []):
		return "Освещение не разрешено для выбранного фона."
	if stage.get("roomState") not in master.get("stateLayers", []):
		return "Состояние комнаты не разрешено для выбранного фона."
	var cast_list: Variant = stage.get("cast", [])
	if not cast_list is Array or cast_list.size() > 3 or int(stage.get("visibleCount", -1)) != cast_list.size():
		return "В кадре можно разместить не более трёх персонажей."
	var used: Dictionary = {}
	for item in cast_list:
		if not item is Dictionary:
			return "Некорректный персонаж."
		var actor_id: String = str(item.get("characterId", ""))
		if not opts["actors"].has(actor_id) or used.has(actor_id):
			return "Неизвестный или повторяющийся персонаж."
		used[actor_id] = true
		var spec: Dictionary = opts["actors"][actor_id]
		if item.get("pose") not in spec.get("poses", []):
			return "Поза не разрешена для персонажа."
		if item.get("emotion") not in spec.get("emotions", []):
			return "Эмоция не разрешена для персонажа."
		if item.get("slot") not in ["left", "center", "right"]:
			return "Неизвестный слот постановки."
		for key in item.keys():
			if key not in ["characterId", "slot", "pose", "emotion", "micro", "x", "y"]:
				return "Недопустимое поле персонажа: " + str(key)
		for axis in ["x", "y"]:
			if item.has(axis) and (not (item[axis] is float or item[axis] is int) or not is_finite(float(item[axis])) or float(item[axis]) < 0 or float(item[axis]) > 1):
				return "Координаты должны быть нормализованы в диапазоне 0–1."
	return ""


static func set_stage(project: Dictionary, draft: Dictionary, stage: Dictionary) -> String:
	var error: String = validate_stage(project, stage)
	if not error.is_empty():
		return error
	draft["stageSourceSha256"] = str(project["stagingSha"])
	draft["castSourceSha256"] = str(project["castSha"])
	if not draft.has("stagePatches"):
		draft["stagePatches"] = {}
	draft["stagePatches"][str(stage["sceneId"])] = stage.duplicate(true)
	return ""


static func materialize_staging(project: Dictionary, draft: Dictionary) -> Dictionary:
	var data: Dictionary = project["stagingData"].duplicate(true)
	var patches: Dictionary = draft.get("stagePatches", {})
	for i in range(data.get("sceneShots", []).size()):
		var scene_id: String = str(data["sceneShots"][i]["sceneId"])
		if patches.has(scene_id):
			data["sceneShots"][i] = patches[scene_id].duplicate(true)
	return data


static func export_stage_candidate(project: Dictionary, draft: Dictionary) -> Dictionary:
	var error: String = validate(project, draft)
	if not error.is_empty():
		return {"ok": false, "error": error}
	if draft.get("stagePatches", {}).is_empty():
		return {"ok": false, "error": "Нет изменений постановки."}
	var data: Dictionary = materialize_staging(project, draft)
	var folder: String = ProjectSettings.globalize_path("user://raven_story_studio/v1/exports")
	var target: String = folder.path_join("raven-staging-" + str(project["stagingSha"]).substr(0, 12) + "-" +
			JSON.stringify(draft["stagePatches"]).sha256_text().substr(0, 12) + ".json")
	return _write_new(target, JSON.stringify(data, "\t") + "\n", false)

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
