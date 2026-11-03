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
const Characters = preload("res://scripts/raven/raven_vn_characters.gd")
const StageV2 = preload("res://addons/vn_studio/model/stage_v2_store.gd")
const StageFx = preload("res://addons/vn_studio/model/stage_fx_store.gd")
const StoryGraph = preload("res://addons/vn_studio/model/raven_story_graph_draft.gd")
const Author = preload("res://addons/vn_studio/model/raven_story_authoring.gd")
const StageLayout = preload("res://addons/vn_studio/model/stage_layout_tools.gd")
const Promotion = preload("res://addons/vn_studio/model/raven_story_promotion.gd")
const Package = preload("res://addons/vn_studio/model/raven_production_package.gd")
const ImageStaging = preload("res://addons/vn_studio/model/staged_image_store.gd")
const VNBackgrounds = preload("res://scripts/raven/raven_vn_backgrounds.gd")
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
		"routesSha": FileAccess.get_sha256(root.path_join(ROUTES)),
		"routesData": routes, "cuesData": cues,
		"cuesSha": FileAccess.get_sha256(root.path_join(CUES)),
		"castData": cast_info, "castSha": FileAccess.get_sha256(root.path_join(CAST)),
		"shots": shots, "routes": triggers, "cues": performance,
		"sceneCount": order.size(), "lineCount": line_ids.size()}


static func draft_path(root: String) -> String:
	return ProjectSettings.globalize_path("user://raven_story_studio/v1").path_join(root.simplify_path().sha256_text()).path_join("draft.json")


static func fresh(project: Dictionary) -> Dictionary:
	return {"format": FORMAT, "schemaVersion": 1,
		"sourceSha256": str(project.get("sha", "")),
		"sourceRootFingerprint": str(project.get("root", "")).sha256_text(),
		"routeSourceSha256": str(project.get("routesSha", "")),
		"stageSourceSha256": str(project.get("stagingSha", "")),
		"castSourceSha256": str(project.get("castSha", "")),
		"patches": {}, "stagePatches": {}, "stageV2Patches": {}, "stageFxPatches": {},
		"storyGraphPatches": {}, "authoredScenes": [], "authoredLines": [],
		"promotionSceneIdMap": {}}


## Immutable source line IDs for a scene; used for FX cross-scene validation.
static func visible_project(project: Dictionary, draft: Dictionary) -> Dictionary:
	return Author.preview_project(project, draft)


static func scene_records(project: Dictionary, draft: Dictionary) -> Array:
	return Author.scenes(project, draft)


static func entries_for(project: Dictionary, draft: Dictionary, scene_id: String) -> Array:
	return Author.lines(project, draft, scene_id)


## New authored scenes can pick their exact catalogued background as part of
## the creation wizard. All mutations are made to a cloned review-only draft.
static func add_scene(project: Dictionary, draft: Dictionary, title_ru: String,
		text_ru: String, speaker_id: String, chapter: String = "",
		background: Dictionary = {}) -> Dictionary:
	var result: Dictionary = Author.add_scene(project, draft, title_ru, text_ru, speaker_id, chapter)
	if not result.get("ok", false) or background.is_empty():
		return result
	var scene_id: String = str(result["sceneId"])
	var shot: Dictionary = {"sceneId": scene_id,
		"backgroundId": str(background.get("backgroundId", "")),
		"lighting": str(background.get("lighting", "")),
		"roomState": str(background.get("roomState", "")),
		"cast": [], "visibleCount": 0}
	var error: String = set_stage(project, result["draft"], shot)
	if not error.is_empty():
		return {"ok": false, "error": error}
	var composed: Dictionary = _with_speaker_on_stage(project, result["draft"], scene_id, speaker_id)
	if not composed.get("ok", false):
		return composed
	result["draft"] = composed["draft"]
	error = validate(project, result["draft"])
	if not error.is_empty():
		return {"ok": false, "error": error}
	return result


## Only real existing catalog plate variants, never planned or fake art.
static func background_variants(project: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry in VNBackgrounds.all_entries():
		var id: String = str(entry.get("backgroundId", ""))
		var master: Dictionary = stage_master(project, id)
		if master.is_empty():
			continue
		if entry.get("lighting") not in master.get("lightingVariants", []) or\
				entry.get("roomState") not in master.get("stateLayers", []):
			continue
		result.append({"backgroundId": id,
			"lighting": str(entry.get("lighting", "")),
			"roomState": str(entry.get("roomState", ""))})
	return result


static func add_line(project: Dictionary, draft: Dictionary, scene_id: String,
		text_ru: String, speaker_id: String) -> Dictionary:
	var result: Dictionary = Author.add_line(project, draft, scene_id, text_ru, speaker_id)
	if not result.get("ok", false):
		return result
	var composed: Dictionary = _with_speaker_on_stage(project, result["draft"], scene_id, speaker_id)
	if not composed.get("ok", false):
		return composed
	result["draft"] = composed["draft"]
	result["stageNotice"] = composed.get("stageNotice", "")
	return result


## Prefer an exact, accepted neutral portrait from the existing VN art registry.
## Never fabricate art IDs when no matching default image exists.
static func default_actor(project: Dictionary, actor_id: String) -> Dictionary:
	var spec: Dictionary = stage_options(project).get("actors", {}).get(actor_id, {})
	if spec.is_empty():
		return {}
	var entries: Array[Dictionary] = Characters.entries_for(actor_id)
	for item: Dictionary in entries:
		if item.get("status") == "accepted" and item.get("defaultForPose", false) and item.get("emotion") == "neutral" and\
				item.get("pose") in spec.get("poses", []) and item.get("emotion") in spec.get("emotions", []):
			return {"characterId": actor_id, "pose": item["pose"], "emotion": item["emotion"],
				"assetId": item["id"], "slot": "center", "x": 0.5, "y": 0.55, "micro": ""}
	for item: Dictionary in entries:
		if item.get("status") == "accepted" and item.get("defaultForPose", false) and\
				item.get("pose") in spec.get("poses", []) and item.get("emotion") in spec.get("emotions", []):
			return {"characterId": actor_id, "pose": item["pose"], "emotion": item["emotion"],
				"assetId": item["id"], "slot": "center", "x": 0.5, "y": 0.55, "micro": ""}
	return {"characterId": actor_id, "pose": str(spec.get("poses", [""])[0]),
		"emotion": str(spec.get("emotions", [""])[0]), "slot": "center", "x": 0.5,
		"y": 0.55, "micro": ""} # ART PENDING; no invented assetId


static func _with_speaker_on_stage(project: Dictionary, draft: Dictionary,
		scene_id: String, speaker_id: String) -> Dictionary:
	if speaker_id == Author.NARRATOR_ID:
		return {"ok": true, "draft": draft}
	var stage: Dictionary = effective_stage(project, draft, scene_id)
	if stage.is_empty():
		return {"ok": false, "error": "Сцена не имеет постановки."}
	var cast: Array = stage.get("cast", [])
	for actor in cast:
		if actor.get("characterId", "") == speaker_id:
			return {"ok": true, "draft": draft}
	if cast.size() >= 3:
		return {"ok": true, "draft": draft,
			"stageNotice": "В кадре уже три персонажа; текст добавлен, но четвёртый портрет не вставлен."}
	var actor: Dictionary = default_actor(project, speaker_id)
	if actor.is_empty():
		return {"ok": false, "error": "Персонаж отсутствует в реестре постановки."}
	cast.append(actor)
	stage["cast"] = cast
	stage["visibleCount"] = cast.size()
	# When a NEW speaker arrives, transition 1→2 or 2→3 portraits.
	# Does not change a pose, image or costume already chosen by the author.
	stage = StageLayout.apply_template(stage, StageLayout.PORTRAIT)
	var error: String = set_stage(project, draft, stage)
	if not error.is_empty():
		return {"ok": false, "error": "Не удалось добавить портрет: " + error}
	return {"ok": true, "draft": draft}



static func move_line(project: Dictionary, draft: Dictionary, scene_id: String,
		line_id: String, direction: int) -> Dictionary:
	var result: Dictionary = Author.move_line(project, draft, scene_id, line_id, direction)
	if result.get("ok", false):
		var error: String = validate(project, result["draft"])
		if not error.is_empty():
			return {"ok": false, "error": error}
	return result


static func move_line_to(project: Dictionary, draft: Dictionary, scene_id: String,
		line_id: String, target_line_id: String) -> Dictionary:
	var result: Dictionary = Author.move_line_to(project, draft, scene_id, line_id, target_line_id)
	if result.get("ok", false):
		var error: String = validate(project, result["draft"])
		if not error.is_empty():
			return {"ok": false, "error": error}
	return result


static func delete_line(project: Dictionary, draft: Dictionary, scene_id: String,
		line_id: String) -> Dictionary:
	var result: Dictionary = Author.delete_line(project, draft, scene_id, line_id)
	if result.get("ok", false):
		var error: String = validate(project, result["draft"])
		if not error.is_empty():
			return {"ok": false, "error": error}
	return result


static func line_ids(project: Dictionary, scene_id: String) -> Array:
	var ids: Array = []
	for entry in project.get("linesByScene", {}).get(scene_id, []):
		if entry is Dictionary:
			ids.append(str(entry.get("id", "")))
	return ids


static func load_draft(project: Dictionary) -> Dictionary:
	var path: String = draft_path(str(project["root"]))
	if not FileAccess.file_exists(path):
		return {"ok": true, "found": false, "draft": fresh(project)}
	var existing: Dictionary = _json(path)
	var validation: String = validate(project, existing)
	if not validation.is_empty():
		return {"ok": false, "error": validation}
	return {"ok": true, "found": true, "draft": existing}



## A stale local draft is NEVER auto-rebased. Give the owner a safe, explicit
## escape hatch: preserve the exact bytes in a separate no-overwrite backup
## before starting a fresh SHA-locked draft for the current source.
static func stale_draft_info(project: Dictionary) -> Dictionary:
	if not bool(project.get("ok", false)):
		return {"ok": false, "error": "Исходный Raven проект не загружен."}
	var path: String = draft_path(str(project["root"]))
	if not FileAccess.file_exists(path):
		return {"ok": false, "error": "Старого черновика нет."}
	var raw: String = FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(raw)
	if not parsed is Dictionary:
		return {"ok": false, "error": "Старый черновик повреждён. Сначала сохраните его вручную."}
	var old: Dictionary = parsed
	if old.get("format") != FORMAT or old.get("schemaVersion") != 1:
		return {"ok": false, "error": "Формат черновика неизвестен. Нужен ручной разбор."}
	if str(old.get("sourceRootFingerprint", "")) != str(project["root"]).sha256_text():
		return {"ok": false, "error": "Черновик привязан к другому проекту, восстановление запрещено."}
	var drift: bool = old.get("sourceSha256") != project.get("sha") or\
			old.get("routeSourceSha256") != project.get("routesSha") or\
			old.get("stageSourceSha256") != project.get("stagingSha") or\
			old.get("castSourceSha256") != project.get("castSha")
	if not drift:
		return {"ok": false, "error": "Исходные SHA совпадают; это не конфликт обновления сценария. Исправьте ошибку отдельно."}
	var error: String = validate(project, old)
	if error.is_empty():
		return {"ok": false, "error": "Черновик уже совместим с текущим проектом."}
	return {"ok": true, "path": path, "sha256": raw.sha256_text(),
		"reason": error,
		"changes": {"translations": change_count(old), "stage": old.get("stagePatches", {}).size(),
			"stageV2": old.get("stageV2Patches", {}).size(), "fx": old.get("stageFxPatches", {}).size(),
			"graph": old.get("storyGraphPatches", {}).size(), "scenes": old.get("authoredScenes", []).size(),
			"lines": old.get("authoredLines", []).size()}}


static func archive_and_start_fresh(project: Dictionary) -> Dictionary:
	var info: Dictionary = stale_draft_info(project)
	if not info.get("ok", false):
		return info
	# Re-read before writing so a concurrent local edit cannot be silently lost.
	var path: String = str(info["path"])
	var raw: String = FileAccess.get_file_as_string(path)
	if raw.sha256_text() != str(info["sha256"]):
		return {"ok": false, "error": "Черновик изменился после проверки. Перечитайте проект."}
	var backup: String = ProjectSettings.globalize_path("user://raven_story_studio/recovery").path_join(
		str(project["root"]).sha256_text()).path_join("draft-" + str(info["sha256"]) + ".json")
	if FileAccess.file_exists(backup):
		if FileAccess.get_file_as_string(backup) != raw:
			return {"ok": false, "error": "Резервная копия с тем же SHA отличается. Запись запрещена."}
	else:
		var archived: Dictionary = _write_new(backup, raw, false)
		if not archived.get("ok", false) or FileAccess.get_file_as_string(backup) != raw:
			return {"ok": false, "error": "Старый черновик не удалось надёжно сохранить. Исходный файл не тронут."}
	var saved: Dictionary = save_local(project, fresh(project))
	if not saved.get("ok", false):
		return {"ok": false, "error": "Копия сохранена, но новый черновик не создан: " + str(saved.get("error", "")),
			"backupPath": backup}
	return {"ok": true, "backupPath": backup, "draftPath": saved["path"],
		"notice": "Создан новый черновик. Старые правки НЕ перенесены: сравните резервную копию вручную."}


static func validate(project: Dictionary, draft: Dictionary) -> String:
	if not bool(project.get("ok", false)):
		return "Сначала откройте источник Raven."
	if draft.get("format") != FORMAT or draft.get("schemaVersion") != 1:
		return "Неподдерживаемая версия Raven draft."
	if draft.get("sourceSha256") != project.get("sha") or draft.get("sourceRootFingerprint") != str(project.get("root", "")).sha256_text():
		return "Raven-сценарий изменился после сохранения черновика. Нужен ручной diff; автоматический rebase запрещён."
	if FileAccess.get_sha256(str(project["sourcePath"])) != project["sha"]:
		return "Сценарий в репозитории изменён извне; повторно откройте редактор."
	var authored_error: String = Author.validate(project, draft)
	if not authored_error.is_empty():
		return authored_error
	var promotion_error: String = Promotion.validate_mapping(project, draft,
		draft.get("promotionSceneIdMap", {}))
	if not promotion_error.is_empty():
		return promotion_error
	# VNS5-06A: route authoring is a separate SHA-locked review-only overlay.
	var graph_patches: Variant = draft.get("storyGraphPatches", {})
	if not graph_patches is Dictionary:
		return "Story Map patches must be an object."
	if not graph_patches.is_empty():
		var graph_project: Dictionary = visible_project(project, draft)
		if draft.get("routeSourceSha256", "") != project.get("routesSha", ""):
			return "Canonical routes changed since this Story Map draft was created."
		if FileAccess.get_sha256(str(project["root"]).path_join(ROUTES)) != project["routesSha"]:
			return "Canonical route file changed on disk; Story Map draft is stale."
		for scene_id in graph_patches:
			if not graph_project["routes"].has(scene_id):
				return "Story Map references an unknown source scene."
			var validation: String = StoryGraph.validate(graph_project, graph_patches[scene_id])
			if not validation.is_empty() or str(graph_patches[scene_id].get("sceneId", "")) != str(scene_id):
				return "Story Map %s: %s" % [scene_id, validation if not validation.is_empty() else "sceneId mismatch"]
	var stage_patches: Variant = draft.get("stagePatches", {})
	if not stage_patches is Dictionary:
		return "Повреждённый список изменений постановки."
	if not stage_patches.is_empty():
		if draft.get("stageSourceSha256", "") != project.get("stagingSha", "") or draft.get("castSourceSha256", "") != project.get("castSha", ""):
			return "Исходная постановка или справочник персонажей изменились. Нужен ручной diff."
		if FileAccess.get_sha256(str(project["root"]).path_join(STAGING)) != project["stagingSha"] or FileAccess.get_sha256(str(project["root"]).path_join(CAST)) != project["castSha"]:
			return "Постановка изменилась на диске после открытия. Повторно откройте проект."
		for stage_id in stage_patches:
			if not project["shots"].has(stage_id) and not Author.is_authored_scene(draft, str(stage_id)):
				return "В черновике неизвестная сцена постановки."
			if not stage_patches[stage_id] is Dictionary or str(stage_patches[stage_id].get("sceneId", "")) != str(stage_id):
				return "sceneId постановки не совпадает с ключом черновика."
			var stage_error: String = validate_stage(project, stage_patches[stage_id], draft)
			if not stage_error.is_empty():
				return "%s: %s" % [stage_id, stage_error]
	var v2_patches: Variant = draft.get("stageV2Patches", {})
	if not v2_patches is Dictionary:
		return "Повреждённый список изменений v2-постановки."
	if not v2_patches.is_empty():
		if draft.get("stageSourceSha256", "") != project.get("stagingSha", "") or draft.get("castSourceSha256", "") != project.get("castSha", ""):
			return "V2-черновик привязан к старой постановке/касту; автоматическая миграция запрещена."
		if FileAccess.get_sha256(str(project["root"]).path_join(STAGING)) != project["stagingSha"] or FileAccess.get_sha256(str(project["root"]).path_join(CAST)) != project["castSha"]:
			return "Исходная постановка изменилась на диске; проверьте SHA вручную."
		for scene_id in v2_patches:
			if not project["shots"].has(scene_id) and not Author.is_authored_scene(draft, str(scene_id)):
				return "V2-черновик ссылается на неизвестную сцену."
			if not v2_patches[scene_id] is Dictionary or str(v2_patches[scene_id].get("sceneId", "")) != str(scene_id):
				return "sceneId V2-постановки не совпадает с ключом черновика."
			var source_stage: Dictionary = effective_stage(project, draft, str(scene_id))
			var v2_error: String = StageV2.validate(source_stage, v2_patches[scene_id])
			if not v2_error.is_empty():
				return "%s: %s" % [scene_id, v2_error]
	var fx_patches: Variant = draft.get("stageFxPatches", {})
	if not fx_patches is Dictionary:
		return "Повреждённый FX-таймлайн."
	if not fx_patches.is_empty():
		if draft.get("stageSourceSha256", "") != project.get("stagingSha", "") or draft.get("castSourceSha256", "") != project.get("castSha", ""):
			return "FX-черновик привязан к устаревшей постановке/касту."
		if FileAccess.get_sha256(str(project["root"]).path_join(STAGING)) != project["stagingSha"] or FileAccess.get_sha256(str(project["root"]).path_join(CAST)) != project["castSha"]:
			return "FX: источники постановки изменились на диске."
		for scene_id in fx_patches:
			if not project["shots"].has(scene_id):
				return "Неизвестный sceneId FX."
			var fx_stage: Dictionary = effective_stage(project, draft, str(scene_id))
			var fx_v2: Dictionary = StageV2.effective(draft, str(scene_id))
			var fx_error: String = StageFx.validate(fx_stage, fx_v2, fx_patches[scene_id], line_ids(project, str(scene_id)))
			if not fx_error.is_empty():
				return "%s: %s" % [scene_id, fx_error]
	var patches: Variant = draft.get("patches", {})
	if not patches is Dictionary:
		return "Повреждённый набор правок."
	var allowed: Dictionary = {}
	for entry in project["data"]["entries"]:
		allowed[str(entry["id"])] = true
	for entry in draft.get("authoredLines", []):
		allowed[str(entry.get("id", ""))] = true
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
	if not draft.get("storyGraphPatches", {}).is_empty() or not draft.get("authoredScenes", []).is_empty() or not draft.get("authoredLines", []).is_empty():
		return {"ok": false, "error": "New scenes, lines or Story Map edges require the no-loss story review export."}
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
	if draft.get("stagePatches", {}).has(scene_id):
		return draft["stagePatches"][scene_id].duplicate(true)
	if project.get("shots", {}).has(scene_id):
		return project["shots"][scene_id].duplicate(true)
	if Author.is_authored_scene(draft, scene_id):
		var entries: Array = VNBackgrounds.all_entries()
		if not entries.is_empty():
			var bg: Dictionary = entries[0]
			return {"sceneId": scene_id, "backgroundId": bg["backgroundId"],
				"lighting": bg["lighting"], "roomState": bg["roomState"],
				"cast": [], "visibleCount": 0}
	return {}


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


static func validate_stage(project: Dictionary, stage: Variant, draft: Dictionary = {}) -> String:
	if not stage is Dictionary:
		return "Постановка должна быть объектом."
	var id: String = str(stage.get("sceneId", ""))
	var authored: bool = Author.is_authored_scene(draft, id)
	if not project.get("shots", {}).has(id) and not authored:
		return "Неизвестная сцена."
	var original: Dictionary = project["shots"].get(id, {"sceneId": id})
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
	if authored and VNBackgrounds.entry_for(str(stage.get("backgroundId", "")), str(stage.get("lighting", "")), str(stage.get("roomState", ""))).is_empty():
		return "Точный вариант фона отсутствует в VN-каталоге."
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
			if key not in ["characterId", "slot", "pose", "emotion", "micro", "x", "y", "assetId"]:
				return "Недопустимое поле персонажа: " + str(key)
		if item.has("assetId"):
			if not item["assetId"] is String or Characters.for_actor(item, false).get("entry", {}).is_empty():
				return "Изображение не соответствует персонажу, позе и эмоции."
		for axis in ["x", "y"]:
			if item.has(axis) and (not (item[axis] is float or item[axis] is int) or not is_finite(float(item[axis])) or float(item[axis]) < 0 or float(item[axis]) > 1):
				return "Координаты должны быть нормализованы в диапазоне 0–1."
	return ""


static func set_stage(project: Dictionary, draft: Dictionary, stage: Dictionary) -> String:
	var error: String = validate_stage(project, stage, draft)
	if not error.is_empty():
		return error
	var scene_id: String = str(stage.get("sceneId", ""))
	var fx: Variant = draft.get("stageFxPatches", {}).get(scene_id, {})
	if fx is Dictionary and not fx.is_empty():
		var overlay: Dictionary = StageV2.trim_actor_z(stage, StageV2.effective(draft, scene_id))
		var fx_error: String = StageFx.validate(stage, overlay, fx, line_ids(project, scene_id))
		if not fx_error.is_empty():
			return "Нельзя удалить цель FX: " + fx_error
	draft["stageSourceSha256"] = str(project["stagingSha"])
	draft["castSourceSha256"] = str(project["castSha"])
	if not draft.has("stagePatches"):
		draft["stagePatches"] = {}
	draft["stagePatches"][scene_id] = stage.duplicate(true)
	if draft.get("stageV2Patches", {}).has(scene_id):
		draft["stageV2Patches"][scene_id] = StageV2.trim_actor_z(stage, draft["stageV2Patches"][scene_id])
	return ""


static func set_stage_v2(project: Dictionary, draft: Dictionary, overlay: Dictionary) -> String:
	var scene_id: String = str(overlay.get("sceneId", ""))
	if not project.get("shots", {}).has(scene_id) and not Author.is_authored_scene(draft, scene_id):
		return "V2-постановка ссылается на неизвестную сцену."
	var stage: Dictionary = effective_stage(project, draft, scene_id)
	var error: String = StageV2.validate(stage, overlay)
	if not error.is_empty():
		return error
	var fx: Variant = draft.get("stageFxPatches", {}).get(scene_id, {})
	if fx is Dictionary and not fx.is_empty():
		var fx_error: String = StageFx.validate(stage, overlay, fx, line_ids(project, scene_id))
		if not fx_error.is_empty():
			return "Нельзя удалить prop, использующийся в FX: " + fx_error
	draft["stageSourceSha256"] = str(project["stagingSha"])
	draft["castSourceSha256"] = str(project["castSha"])
	if not draft.has("stageV2Patches"):
		draft["stageV2Patches"] = {}
	draft["stageV2Patches"][scene_id] = overlay.duplicate(true)
	return ""


static func export_v2_candidate(project: Dictionary, draft: Dictionary) -> Dictionary:
	if not draft.get("storyGraphPatches", {}).is_empty() or not draft.get("authoredScenes", []).is_empty() or not draft.get("authoredLines", []).is_empty():
		return {"ok": false, "error": "Story additions require the no-loss story review export."}
	if not draft.get("stageFxPatches", {}).is_empty():
		return {"ok": false, "error": "FX события требуют отдельный FX review export; v2 экспорт потеряет таймлайн."}
	var error: String = validate(project, draft)
	if not error.is_empty():
		return {"ok": false, "error": error}
	var patches: Dictionary = draft.get("stageV2Patches", {})
	if patches.is_empty():
		return {"ok": false, "error": "V2-изменения постановки отсутствуют."}
	var asset_store := ImageStaging.new()
	var asset_result: Dictionary = asset_store.open_project(str(project["root"]))
	var item_by_id: Dictionary = {}
	if asset_result.get("ok", false):
		for item: Dictionary in asset_store.list_items():
			item_by_id[str(item.get("id", ""))] = item
	var pending: Array[String] = []
	var used_assets: Dictionary = {}
	for scene_id in patches:
		for prop: Dictionary in patches[scene_id].get("props", []):
			var asset_id: String = str(prop.get("assetId", ""))
			if asset_id.is_empty():
				pending.append("%s/%s: ART PENDING" % [scene_id, prop["instanceId"]])
				continue
			if not asset_result.get("ok", false) or not item_by_id.has(asset_id):
				return {"ok": false, "error": "Staged prop отсутствует или source SHA изменился: " + asset_id}
			if item_by_id[asset_id].get("category") != "prop":
				return {"ok": false, "error": "Asset не относится к prop: " + asset_id}
			used_assets[asset_id] = {"sha256": item_by_id[asset_id]["sha256"],
				"provenance": item_by_id[asset_id].get("provenance", ""),
				"license": item_by_id[asset_id].get("license", ""),
				"approval": "unreviewed_staged_asset"}
	var output: Dictionary = {"format": "raven-stage-v2-review-candidate", "schemaVersion": 1,
		"sourceSha256": project["sha"], "stageSourceSha256": project["stagingSha"],
		"castSourceSha256": project["castSha"], "stageV1Patches": draft.get("stagePatches", {}).duplicate(true),
		"stageV2Patches": patches.duplicate(true), "stagedPropReferences": used_assets,
		"artPending": pending, "runtimeApplied": false, "requiresHumanReview": true}
	var folder: String = ProjectSettings.globalize_path("user://raven_story_studio/v2/exports")
	var payload: String = JSON.stringify(output, "	") + "
"
	var path: String = folder.path_join("raven-stage-v2-" + payload.sha256_text().substr(0, 24) + ".json")
	return _write_new(path, payload, false)


## Review-only Story Map authoring — canonical map_narrative_routes remains immutable.
static func set_story_graph(project: Dictionary, draft: Dictionary, data: Dictionary) -> String:
	var error: String = StoryGraph.validate(visible_project(project, draft), data)
	if not error.is_empty():
		return error
	var scene_id: String = str(data.get("sceneId", ""))
	if not visible_project(project, draft).get("routes", {}).has(scene_id):
		return "Cannot author edges for an unknown scene."
	draft["routeSourceSha256"] = str(project.get("routesSha", ""))
	if not draft.has("storyGraphPatches"):
		draft["storyGraphPatches"] = {}
	draft["storyGraphPatches"][scene_id] = data.duplicate(true)
	return ""


## Bundles all existing draft categories, so a graph export never discards FX
## or staging silently; requires review and never writes to res://.
static func set_promotion_map(project: Dictionary, draft: Dictionary, mapping: Dictionary) -> String:
	var error: String = Promotion.validate_mapping(project, draft, mapping)
	if not error.is_empty():
		return error
	if not draft.has("promotionSceneIdMap"):
		draft["promotionSceneIdMap"] = {}
	draft["promotionSceneIdMap"] = mapping.duplicate(true)
	return ""


static func promotion_plan(project: Dictionary, draft: Dictionary) -> Dictionary:
	var error: String = validate(project, draft)
	if not error.is_empty():
		return {"ok": false, "error": error}
	return Promotion.plan(project, draft)


## Exports a review-only, fully remapped proposal with explicit unresolved
## route/shot/save blockers. Does not apply any canonical files or runtime flags.
## VNS5-06D1: Generate a blank manifest in user://. It must be explicitly
## filled by a reviewer before package assembly. Cannot activate scenes.
static func export_package_manifest_template(project: Dictionary, draft: Dictionary) -> Dictionary:
	var result: Dictionary = promotion_plan(project, draft)
	if not result.get("ok", false):
		return result
	var manifest: Dictionary = Package.template(project, draft)
	if not manifest.get("ok", false):
		return manifest
	var serialized: String = JSON.stringify(manifest["manifest"], "\t") + "\n"
	var folder: String = ProjectSettings.globalize_path("user://raven_story_studio/production_package")
	return _write_new(folder.path_join("promotion-manifest-template-" +
		serialized.sha256_text().substr(0, 20) + ".json"), serialized, false)


## Fail closed on any changed canonical source, even if draft has no existing
## stage or FX patches. Assembled output is never written to res://.
static func export_four_registry_review(project: Dictionary, draft: Dictionary,
		manifest: Variant) -> Dictionary:
	var planned: Dictionary = promotion_plan(project, draft)
	if not planned.get("ok", false):
		return planned
	for pair in [[RELATIVE, "sha"], [ROUTES, "routesSha"], [STAGING, "stagingSha"],
			[CAST, "castSha"], [CUES, "cuesSha"]]:
		if FileAccess.get_sha256(str(project["root"]).path_join(pair[0])) != project[pair[1]]:
			return {"ok": false, "error": "Canonical source changed on disk: " + str(pair[0])}
	var candidate: Dictionary = Package.assemble(project, draft, manifest)
	if not candidate.get("ok", false):
		return candidate
	var serialized: String = JSON.stringify(candidate["bundle"], "\t") + "\n"
	var folder: String = ProjectSettings.globalize_path("user://raven_story_studio/production_package")
	return _write_new(folder.path_join("raven-four-registry-review-" +
		serialized.sha256_text().substr(0, 24) + ".json"), serialized, false)


static func export_promotion_review(project: Dictionary, draft: Dictionary) -> Dictionary:
	var result: Dictionary = promotion_plan(project, draft)
	if not result.get("ok", false):
		return result
	var payload: String = JSON.stringify(result["bundle"], "\t") + "\n"
	var folder: String = ProjectSettings.globalize_path("user://raven_story_studio/promotion_review")
	var path: String = folder.path_join("raven-promotion-" + payload.sha256_text().substr(0, 24) + ".json")
	return _write_new(path, payload, false)


static func export_story_graph_candidate(project: Dictionary, draft: Dictionary) -> Dictionary:
	if not draft.get("promotionSceneIdMap", {}).is_empty():
		return {"ok": false, "error": "Promotion mappings need the complete promotion review export to prevent ID loss."}
	var error: String = validate(project, draft)
	if not error.is_empty():
		return {"ok": false, "error": error}
	if draft.get("storyGraphPatches", {}).is_empty() and draft.get("authoredScenes", []).is_empty() and draft.get("authoredLines", []).is_empty():
		return {"ok": false, "error": "No authored Story Map or new dialogue content."}
	var payload: Dictionary = {
		"format": "raven-vn-story-graph-review-v1", "schemaVersion": 1,
		"sourceSha256": project["sha"], "routeSourceSha256": project["routesSha"],
		"stageSourceSha256": project["stagingSha"], "castSourceSha256": project["castSha"],
		"storyGraphPatches": draft.get("storyGraphPatches", {}).duplicate(true),
		"authoredScenes": draft.get("authoredScenes", []).duplicate(true),
		"authoredLines": draft.get("authoredLines", []).duplicate(true),
		"dialogueCatalogReview": Author.export_preview(project, draft),
		"textPatches": draft.get("patches", {}).duplicate(true),
		"stagePatches": draft.get("stagePatches", {}).duplicate(true),
		"stageV2Patches": draft.get("stageV2Patches", {}).duplicate(true),
		"stageFxPatches": draft.get("stageFxPatches", {}).duplicate(true),
		"runtimeApplied": false, "requiresHumanReview": true
	}
	var serialized: String = JSON.stringify(payload, "\t") + "\n"
	var path: String = ProjectSettings.globalize_path("user://raven_story_studio/story_graph/exports").path_join(
		"raven-story-graph-" + serialized.sha256_text().substr(0, 24) + ".json")
	return _write_new(path, serialized, false)


static func set_stage_fx(project: Dictionary, draft: Dictionary, data: Dictionary) -> String:
	var scene_id: String = str(data.get("sceneId", ""))
	if not project.get("shots", {}).has(scene_id):
		return "FX содержит неизвестный sceneId."
	var stage: Dictionary = effective_stage(project, draft, scene_id)
	var overlay: Dictionary = StageV2.effective(draft, scene_id)
	var error: String = StageFx.validate(stage, overlay, data, line_ids(project, scene_id))
	if not error.is_empty():
		return error
	draft["stageSourceSha256"] = str(project["stagingSha"])
	draft["castSourceSha256"] = str(project["castSha"])
	if not draft.has("stageFxPatches"):
		draft["stageFxPatches"] = {}
	draft["stageFxPatches"][scene_id] = data.duplicate(true)
	return ""


static func export_fx_candidate(project: Dictionary, draft: Dictionary) -> Dictionary:
	if not draft.get("storyGraphPatches", {}).is_empty() or not draft.get("authoredScenes", []).is_empty() or not draft.get("authoredLines", []).is_empty():
		return {"ok": false, "error": "Story additions require the no-loss story review export."}
	var error: String = validate(project, draft)
	if not error.is_empty():
		return {"ok": false, "error": error}
	var fx_patches: Dictionary = draft.get("stageFxPatches", {})
	if fx_patches.is_empty():
		return {"ok": false, "error": "Нет FX событий для review."}
	var output: Dictionary = {"format": "raven-stage-fx-review-candidate", "schemaVersion": 1,
		"sourceSha256": project["sha"], "stageSourceSha256": project["stagingSha"],
		"castSourceSha256": project["castSha"],
		"stageV1Patches": draft.get("stagePatches", {}).duplicate(true),
		"stageV2Patches": draft.get("stageV2Patches", {}).duplicate(true),
		"stageFxPatches": fx_patches.duplicate(true),
		"runtimeApplied": false, "requiresHumanReview": true,
		"fxPreviewOnly": true}
	var payload: String = JSON.stringify(output, "\t") + "\n"
	var target: String = ProjectSettings.globalize_path("user://raven_story_studio/fx/exports").path_join(
		"raven-stage-fx-" + payload.sha256_text().substr(0, 24) + ".json")
	return _write_new(target, payload, false)


static func materialize_staging(project: Dictionary, draft: Dictionary) -> Dictionary:
	var data: Dictionary = project["stagingData"].duplicate(true)
	var patches: Dictionary = draft.get("stagePatches", {})
	for i in range(data.get("sceneShots", []).size()):
		var scene_id: String = str(data["sceneShots"][i]["sceneId"])
		if patches.has(scene_id):
			data["sceneShots"][i] = patches[scene_id].duplicate(true)
	return data


static func export_stage_candidate(project: Dictionary, draft: Dictionary) -> Dictionary:
	if not draft.get("storyGraphPatches", {}).is_empty() or not draft.get("authoredScenes", []).is_empty() or not draft.get("authoredLines", []).is_empty():
		return {"ok": false, "error": "Story additions require the no-loss story review export."}
	if not draft.get("stageFxPatches", {}).is_empty():
		return {"ok": false, "error": "Есть FX таймлайн. Используйте FX review export для сохранения событий."}
	if not draft.get("stageV2Patches", {}).is_empty():
		return {"ok": false, "error": "Есть stage-v2 данные. Используйте отдельный V2 review export: v1 исключит слои/props."}
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
