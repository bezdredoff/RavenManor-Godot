@tool
extends RefCounted
## Strict, read-only UPDS story-save position inspector. Nothing is imported or written.
## Validates against donor's save_contract and the selected migration plan in memory.
const FORMAT := "vn-studio-save-position-preview-v1"
const SUPPORTED_LOCALES := ["ru", "en", "be"]
const OPTIONS := ["A", "B", "C"]


static func inspect(project: Dictionary, plan: Dictionary, candidate: Variant) -> Dictionary:
	var errors: Array[String] = []
	var warnings: Array[String] = []
	if not bool(project.get("ok", false)) or not bool(plan.get("ok", false)):
		return _fail(["Откройте UPDS-godot и выполните успешный dry-run."])
	var map: Dictionary = _save_map(plan)
	if map.get("format", "") != "vn-studio-save-map-v1":
		return _fail(["В dry-run отсутствует карта сохранений."])
	var contract: Dictionary = project.get("contract", {})
	var scenes: Array = project.get("scenes", [])
	if scenes.size() != 45 or contract.get("storySceneIds", []).size() != 45:
		return _fail(["Контракт сцен изменился. Повторно откройте источник."])
	if not candidate is Dictionary:
		return _fail(["Сохранение должно быть JSON-объектом."])
	var document: Dictionary = candidate
	var story_key: String = str(contract.get("storyKey", ""))
	var max_schema: int = int(contract.get("storySchema", -1))
	if story_key.is_empty() or max_schema < 0:
		return _fail(["Нет доверенного storyKey/storySchema в контракте UPDS."])
	var save: Dictionary
	if document.has("format"):
		if document.get("format") != "upds-campaign-save" or document.get("saveKey") != story_key:
			return _fail(["Неверный формат или saveKey экспортированного UPDS-сейва."])
		if not document.get("state") is Dictionary:
			return _fail(["В экспортированном сейве отсутствует state."])
		save = document["state"]
	else:
		if document.has("saveKey") and document.get("saveKey") != story_key:
			return _fail(["Неверный saveKey."])
		save = document
	var schema: Variant = document.get("schemaVersion", 0)
	if not _integer(schema) or int(schema) < 0 or int(schema) > max_schema:
		return _fail(["Версия save schema не поддерживается текущим UPDS."])
	for name in ["scene", "line", "choice", "clues", "completed", "attempts", "readLines",
		"tutorialsCompleted", "storyChoices"]:
		if not save.has(name):
			warnings.append("Поле %s отсутствует; UPDS может использовать значение по умолчанию." % name)
	var scene: Variant = save.get("scene", 0)
	var line: Variant = save.get("line", 0)
	if not _integer(scene) or int(scene) < 0 or int(scene) >= scenes.size():
		errors.append("Индекс сцены вне контракта: %s" % str(scene))
	if not _integer(line) or int(line) < 0:
		errors.append("Неверный индекс реплики: %s" % str(line))
	var selected: Variant = save.get("choice", "A")
	if selected not in OPTIONS:
		errors.append("Выбор начальной ветки должен быть A/B/C.")
	var read_lines: Variant = save.get("readLines", [])
	var completed: Variant = save.get("completed", [])
	var story_choices: Variant = save.get("storyChoices", {})
	var clues: Variant = save.get("clues", [])
	var attempts: Variant = save.get("attempts", {})
	var tutorials: Variant = save.get("tutorialsCompleted", [])
	if not read_lines is Array or not completed is Array or not story_choices is Dictionary or not clues is Array or not attempts is Dictionary or not tutorials is Array:
		errors.append("Некорректные типы истории, прогрессии или choices.")
	if not errors.is_empty():
		return _fail(errors, warnings)
	var source_scene: Dictionary = scenes[int(scene)]["data"]
	var sid: String = str(scenes[int(scene)]["id"])
	var groups: Dictionary = map.get("linePositionsByScene", {}).get(sid, {})
	var group: String = str(selected) if int(scene) == 1 else "base"
	if not groups.has(group):
		return _fail(["Отсутствует ветка %s у сцены %s." % [group, sid]], warnings)
	var positions: Array = groups[group]
	var ending: bool = source_scene.get("ending", {}) is Dictionary and not source_scene.get("ending", {}).is_empty()
	var at_end: bool = int(line) == positions.size()
	if int(line) >= positions.size() and not (at_end and ending):
		return _fail(["Индекс реплики %d вне ветки %s; окончание допустимо только у финала." % [int(line), group]], warnings)
	var line_id: String = "<ending-boundary>" if at_end else str(positions[int(line)].get("legacyLineId", ""))
	if line_id.is_empty():
		return _fail(["Невозможно восстановить ID текущей реплики."], warnings)
	var possible_ids: Dictionary = {}
	for scene_entry in scenes:
		for group_array in scene_entry.get("groups", {}).values():
			for item in group_array:
				possible_ids[str(item.get("id", ""))] = true
	var history: Array[String] = []
	for id in read_lines:
		if not id is String or not possible_ids.has(id):
			errors.append("История содержит неизвестный lineId.")
			break
		if id not in history:
			history.append(id)
	var level_ids: Array = contract.get("levelIds", [])
	var completed_ids: Array[String] = []
	for level in completed:
		if not _integer(level) or int(level) < 0 or int(level) >= level_ids.size():
			errors.append("Завершённый Match-3 индекс вне контракта.")
			break
		var level_id: String = str(level_ids[int(level)])
		if level_id not in completed_ids:
			completed_ids.append(level_id)
	for clue in clues:
		if not clue is String or clue not in contract.get("clueIds", []):
			errors.append("Неизвестный clueId в сейве.")
			break
	for tutorial in tutorials:
		if not tutorial is String or tutorial not in contract.get("tutorialConceptIds", []):
			errors.append("Неизвестный tutorialConceptId в сейве.")
			break
	for gate in story_choices:
		if gate not in contract.get("storyChoiceGateIds", []) or story_choices[gate] not in OPTIONS:
			errors.append("Неизвестный choiceGate или значение A/B/C.")
			break
	for key in attempts:
		if not attempts[key] is int and not attempts[key] is float:
			errors.append("Некорректный счётчик попыток.")
			break
	if not errors.is_empty():
		return _fail(errors, warnings)
	var mapped: Dictionary = {
		"sceneId": sid, "sceneIndex": int(scene), "group": group,
		"lineIndex": int(line), "lineId": line_id, "atEndingBoundary": at_end,
		"choice": str(selected), "storyChoices": story_choices.duplicate(true),
		"completedLevelIds": completed_ids, "clues": clues.duplicate(true),
		"readLineIds": history, "tutorialsCompleted": tutorials.duplicate(true),
		"attempts": attempts.duplicate(true)
	}
	if int(scene) == 1 and not story_choices.is_empty():
		warnings.append("Ветка locker определяется полем choice, не storyChoices.")
	var gate: Dictionary = source_scene.get("choiceGate", {})
	if not gate.is_empty():
		mapped["choiceGateId"] = str(gate.get("id", ""))
		mapped["choiceGateResolved"] = story_choices.has(str(gate.get("id", "")))
	if not at_end and bool(positions[int(line)].get("hidden", false)):
		warnings.append("Сохранение указывает на скрытую реплику; UPDS resume() вызовет _skip_hidden().")
	if source_scene.has("nextLevelId") and not str(source_scene.get("nextLevelId", "")).is_empty():
		mapped["match3LevelId"] = str(source_scene["nextLevelId"])
	if source_scene.has("nextSceneIndices"):
		var route_key: String = str(source_scene.get("branchChoiceId", ""))
		mapped["routeChoiceId"] = route_key
		var route: String = str(story_choices.get(route_key, ""))
		var dest: Variant = source_scene["nextSceneIndices"].get(route, -1)
		if route.is_empty() or not _integer(dest) or int(dest) < 0 or int(dest) >= scenes.size():
			warnings.append("Финальный маршрут пока не выбран, переход не вычислялся.")
		else:
			mapped["candidateNextSceneId"] = str(scenes[int(dest)]["id"])
	return {"ok": true, "format": FORMAT, "mapped": mapped, "warnings": warnings,
		"status": "POSITION_PREVIEW_ONLY_NOT_IMPORTED"}


static func _save_map(plan: Dictionary) -> Dictionary:
	for file in plan.get("files", []):
		if file.get("path") == "save_migration_map.json":
			var obj: Variant = JSON.parse_string(str(file.get("json", "")))
			return obj if obj is Dictionary else {}
	return {}


static func _integer(v: Variant) -> bool:
	if v is int:
		return true
	return v is float and is_finite(v) and floorf(v) == v


static func _fail(errors: Array[String], warnings: Array[String] = []) -> Dictionary:
	return {"ok": false, "errors": errors, "warnings": warnings,
		"status": "BLOCKED_NO_WRITE"}
