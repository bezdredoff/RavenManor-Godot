@tool
extends RefCounted
## Optional, user-confirmed QA fixture, appended after existing authored scenes.
## It creates review-only story edges and micro-FX. No production/runtime edits.
const Store = preload("res://addons/vn_studio/editor/raven_story_store.gd")
const Graph = preload("res://addons/vn_studio/model/raven_story_graph_draft.gd")
const StageFx = preload("res://addons/vn_studio/model/stage_fx_store.gd")
const Author = preload("res://addons/vn_studio/model/raven_story_authoring.gd")
const TITLE := "QA · выбор героя (черновик)"
const ACTORS := ["RM-CHAR-EVELYN", "RM-CHAR-ADA", "RM-CHAR-ROWAN"]
const NAMES := ["Эвелин", "Ада", "Роуэн"]
const KEYS := ["A", "B", "C"]
const PHASES := ["enter", "idle", "idle"]


static func _plate(project: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for item in Store.background_variants(project):
		if item.get("backgroundId") == "BG-HALL":
			if result.is_empty():
				result = item
			if item.get("lighting") == "evening" and item.get("roomState") == "dusty":
				return item
	return result


static func build(project: Dictionary, existing: Dictionary) -> Dictionary:
	var valid: String = Store.validate(project, existing)
	if not valid.is_empty():
		return {"ok": false, "error": "Сначала исправьте текущий черновик: " + valid}
	for item in existing.get("authoredScenes", []):
		if str(item.get("title", {}).get("ru", "")) == TITLE:
			return {"ok": false, "error": "QA-развилка уже добавлена в этот черновик. Отмените её через Undo для повторного теста."}
	if existing.get("authoredScenes", []).size() + 4 > Author.MAX_NEW_SCENES or\
			existing.get("authoredLines", []).size() + 7 > Author.MAX_NEW_LINES:
		return {"ok": false, "error": "Для QA-развилки недостаточно лимита черновых сцен/реплик."}
	var bg: Dictionary = _plate(project)
	if bg.is_empty():
		return {"ok": false, "error": "Утверждённый BG-HALL не найден. QA-демо не создаёт фиктивный фон."}
	var candidate: Dictionary = existing.duplicate(true)
	var hub: Dictionary = Store.add_scene(project, candidate, TITLE,
		"Выберите, кто появится в следующей сцене: Эвелин, Ада или Роуэн.",
		Author.NARRATOR_ID, "09", bg)
	if not hub.get("ok", false):
		return hub
	candidate = hub["draft"]
	var hub_id: String = str(hub["sceneId"])
	var checkpoint: String = str(hub["lineId"])
	for index in range(ACTORS.size()):
		var spoken: Dictionary = Store.add_line(project, candidate, hub_id,
			"Я здесь. Выберите мою сцену." if index == 0 else "Можно выбрать меня.",
			ACTORS[index])
		if not spoken.get("ok", false):
			return spoken
		candidate = spoken["draft"]
	var shot: Dictionary = Store.effective_stage(project, candidate, hub_id)
	if shot.get("cast", []).size() != 3:
		return {"ok": false, "error": "Не удалось разместить трёх участников QA-развилки."}
	var branch_ids: Array[String] = []
	for index in range(ACTORS.size()):
		var created: Dictionary = Store.add_scene(project, candidate,
			"QA · встреча: " + NAMES[index],
			"Это сцена персонажа " + NAMES[index] + ". Вернитесь к выбору.",
			ACTORS[index], "09", bg)
		if not created.get("ok", false):
			return created
		candidate = created["draft"]
		var id: String = str(created["sceneId"])
		branch_ids.append(id)
		var back: Dictionary = Graph.next_edge(Graph.fresh(id), "scene", hub_id, "Назад к выбору")
		var back_error: String = Store.set_story_graph(project, candidate, back)
		if not back_error.is_empty():
			return {"ok": false, "error": "Возврат: " + back_error}
		var solo: Dictionary = StageFx.new_phase_cue(StageFx.fresh(id),
			"actor", ACTORS[index], PHASES[index])
		if index == 2:
			solo["cues"][0]["effect"] = "shake"
			solo["cues"][0]["startMs"] = 2200
			solo["cues"][0]["durationMs"] = 650
			solo["cues"][0]["repeat"] = 2
			solo["cues"][0]["intensity"] = 0.12
		var fx_error: String = Store.set_stage_fx(project, candidate, solo)
		if not fx_error.is_empty():
			return {"ok": false, "error": NAMES[index] + ": " + fx_error}
	var selection: Dictionary = Graph.fresh(hub_id)
	for index in range(ACTORS.size()):
		selection = Graph.next_edge(selection, "choice", branch_ids[index],
			"Встретить: " + NAMES[index], checkpoint, KEYS[index])
	var selection_error: String = Store.set_story_graph(project, candidate, selection)
	if not selection_error.is_empty():
		return {"ok": false, "error": "Три выбора: " + selection_error}
	var hub_fx: Dictionary = StageFx.fresh(hub_id)
	for index in range(ACTORS.size()):
		hub_fx = StageFx.new_phase_cue(hub_fx, "actor", ACTORS[index], PHASES[index])
	hub_fx["cues"][2]["effect"] = "shake"
	hub_fx["cues"][2]["startMs"] = 2200
	hub_fx["cues"][2]["durationMs"] = 650
	hub_fx["cues"][2]["repeat"] = 2
	hub_fx["cues"][2]["intensity"] = 0.12
	var error: String = Store.set_stage_fx(project, candidate, hub_fx)
	if not error.is_empty():
		return {"ok": false, "error": "Таймлайн трёх персонажей: " + error}
	error = Store.validate(project, candidate)
	if not error.is_empty():
		return {"ok": false, "error": "QA-драфт не прошёл финальную валидацию: " + error}
	return {"ok": true, "draft": candidate, "hubSceneId": hub_id,
		"branchSceneIds": branch_ids, "checkpointLineId": checkpoint,
		"note": "4 черновые сцены, 3 выбора A/B/C, 3 обратные связи, 6+ FX; не игровой runtime."}
