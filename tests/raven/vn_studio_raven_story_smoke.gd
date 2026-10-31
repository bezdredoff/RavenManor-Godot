extends SceneTree
## Raven Manor two-source authoring safety. Only synthetic user:// sources are modified.
const Store = preload("res://addons/vn_studio/editor/raven_story_store.gd")
const View = preload("res://addons/vn_studio/editor/raven_story_view.gd")
const StageDesigner = preload("res://addons/vn_studio/editor/raven_stage_designer.gd")


func _initialize() -> void:
	call_deferred("_run")


func _write(path: String, value: Dictionary) -> void:
	assert(DirAccess.make_dir_recursive_absolute(path.get_base_dir()) == OK)
	var f: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	assert(f != null)
	f.store_string(JSON.stringify(value, "\t") + "\n")
	f.close()


func _run() -> void:
	# Real public Raven production corpus is available in the repository and must validate.
	var live: Dictionary = Store.open_project(ProjectSettings.globalize_path("res://"))
	assert(live.get("ok", false), JSON.stringify(live))
	assert(live["sceneCount"] == 28)
	assert(live["lineCount"] == 280)
	assert(live["scenes"][0]["sceneId"] == "RM-BEAT-00-01")
	assert(live["scenes"][0]["status"] == "already_runtime")
	assert(live["linesByScene"]["RM-BEAT-00-01"].size() == 4)
	var first: Dictionary = live["linesByScene"]["RM-BEAT-00-01"][0]
	assert(Store.localized(first, Store.fresh(live), "en")["fallback"])
	assert(Store.localized(first, Store.fresh(live), "ru")["text"] != "")
	# UI can open public Raven without selecting any UPDS donor.
	var view := View.new()
	root.add_child(view)
	assert(not view._blocked)
	assert(view._project["sceneCount"] == 28)
	assert(view._scenes.item_count == 28)
	assert(view._lines.item_count == 4)
	assert(view._stage_designer._stage_data["sceneId"] == "RM-BEAT-00-01")
	assert(view._stage_designer._cards.size() == 1)
	assert(view._stage_designer._background.item_count >= 10)
	view.queue_free()
	# Synthetic miniature corpus: validates state without writing public production content.
	var source: String = ProjectSettings.globalize_path("user://vn_raven_source_synthetic_01")
	var scene_a: String = "RM-TEST-A"
	var scene_b: String = "RM-TEST-B"
	var payload: Dictionary = {"schemaVersion": 1, "status": "PRODUCTION_DRAFT_NOT_RUNTIME",
		"locales": ["ru", "be", "en"], "fallbackLocale": "ru",
		"scenes": [
			{"sceneId": scene_a, "title": {"ru": "Вход", "be": null, "en": null}, "status": "already_runtime"},
			{"sceneId": scene_b, "title": {"ru": "Чай", "be": null, "en": null}, "status": "proposed_future_runtime"}],
		"entries": [
			{"id": "RM-TEST-A-L001", "sceneId": scene_a, "speakerId": "RM-CHAR-EVELYN",
				"delivery": "speech", "source": "screenplay",
				"localized": {"ru": {"text": "Привет"}, "be": null, "en": null}},
			{"id": "RM-TEST-A-L002", "sceneId": scene_a, "speakerId": "RM-CHAR-ADA",
				"delivery": "speech", "source": "screenplay",
				"localized": {"ru": {"text": "Чай?"}, "be": null, "en": {"text": "Tea?"}}},
			{"id": "RM-TEST-B-L001", "sceneId": scene_b, "speakerId": "RM-CHAR-EVELYN",
				"delivery": "speech", "source": "screenplay",
				"localized": {"ru": {"text": "Спасибо"}, "be": null, "en": null}}],
		"notices": [{"kind": "non_spoken_stage_direction", "sceneId": scene_a, "textRu": "Тест"}]}
	var original_path: String = source.path_join(Store.RELATIVE)
	_write(original_path, payload)
	_write(source.path_join(Store.STAGING), {"masters": [{"id": "BG-HALL"}, {"id": "BG-KITCHEN"}], "sceneShots": [
		{"sceneId": scene_a, "backgroundId": "BG-HALL", "lighting": "day", "roomState": "dusty", "visibleCount": 1, "layout": "portrait_first", "note": "", "cast": [{"characterId": "RM-CHAR-EVELYN", "slot": "left", "pose": "relaxed", "emotion": "neutral", "micro": ""}]},
		{"sceneId": scene_b, "backgroundId": "BG-KITCHEN", "lighting": "day", "roomState": "unrestored", "visibleCount": 0, "layout": "portrait_first", "note": "", "cast": []}]})
	_write(source.path_join(Store.ROUTES), {"sceneTriggers": [
		{"sceneId": scene_a, "gate": {"kind": "auto_new_game", "ref": "none"}},
		{"sceneId": scene_b, "gate": {"kind": "scene_complete", "ref": scene_a}}]})
	_write(source.path_join(Store.CAST), {"characters": [
		{"id": "RM-CHAR-EVELYN", "poses": ["relaxed", "investigate"], "emotions": ["neutral", "curious"]},
		{"id": "RM-CHAR-ADA", "poses": ["composed", "offer_tray"], "emotions": ["neutral", "dry_amused"]}]})
	_write(source.path_join(Store.CUES), {"cues": [
		{"lineId": "RM-TEST-A-L001", "poseId": "relaxed", "emotionId": "neutral"}]})
	var original: String = FileAccess.get_file_as_string(original_path)
	var project: Dictionary = Store.open_project(source)
	assert(project.get("ok", false), JSON.stringify(project))
	assert(project["lineCount"] == 3 and project["sceneCount"] == 2)
	var draft: Dictionary = Store.fresh(project)
	assert(Store.localized(payload["entries"][0], draft, "be")["fallback"])
	assert(not Store.localized(payload["entries"][0], draft, "en")["translated"])
	Store.edit(draft, "RM-TEST-A-L001", "ru", "Добрый вечер")
	Store.edit(draft, "RM-TEST-A-L001", "en", "Good evening")
	assert(Store.change_count(draft) == 2)
	var original_stage_path: String = source.path_join(Store.STAGING)
	var original_stage_json: String = FileAccess.get_file_as_string(original_stage_path)
	var scene_stage: Dictionary = Store.effective_stage(project, draft, scene_a)
	assert(scene_stage["cast"].size() == 1)
	scene_stage["backgroundId"] = "BG-KITCHEN"
	scene_stage["cast"][0]["pose"] = "investigate"
	scene_stage["cast"][0]["emotion"] = "curious"
	scene_stage["cast"][0]["x"] = 0.348
	scene_stage["cast"][0]["y"] = 0.725
	assert(Store.set_stage(project, draft, scene_stage).is_empty())
	assert(Store.validate(project, draft).is_empty())
	assert(Store.effective_stage(project, draft, scene_a)["cast"][0]["x"] == 0.348)
	var materialized_stage: Dictionary = Store.materialize_staging(project, draft)
	assert(materialized_stage["sceneShots"][0]["backgroundId"] == "BG-KITCHEN")
	assert(materialized_stage["sceneShots"][0]["cast"][0]["pose"] == "investigate")
	assert(materialized_stage["sceneShots"][1]["cast"].is_empty())
	assert(FileAccess.get_file_as_string(original_stage_path) == original_stage_json)
	var invalid_stage: Dictionary = scene_stage.duplicate(true)
	invalid_stage["cast"][0]["pose"] = "illegal_pose"
	assert(not Store.validate_stage(project, invalid_stage).is_empty())
	invalid_stage = scene_stage.duplicate(true)
	invalid_stage["cast"][0]["x"] = 2.5
	assert(not Store.validate_stage(project, invalid_stage).is_empty())
	invalid_stage = scene_stage.duplicate(true)
	invalid_stage["gate"] = {"kind": "wrong"}
	assert(not Store.validate_stage(project, invalid_stage).is_empty())
	var visual := StageDesigner.new()
	root.add_child(visual)
	visual.set_scene(project, draft, scene_a)
	assert(visual._cards.size() == 1)
	assert(visual._background.item_count == 2)
	assert(visual._pose.item_count == 2)
	visual._on_add()
	assert(visual._stage_data["cast"].size() == 2)
	assert(visual._stage_data["cast"][1]["characterId"] == "RM-CHAR-ADA")
	visual._on_remove()
	assert(visual._stage_data["cast"].size() == 1)
	visual.queue_free()
	assert(Store.validate(project, draft).is_empty())
	assert(Store.localized(payload["entries"][0], draft, "en")["translated"])
	assert(Store.localized(payload["entries"][0], draft, "en")["text"] == "Good evening")
	assert(FileAccess.get_file_as_string(original_path) == original)
	var saved: Dictionary = Store.save_local(project, draft)
	assert(saved.get("ok", false), JSON.stringify(saved))
	var read: Dictionary = Store.load_draft(project)
	assert(read["ok"] and read["found"])
	assert(read["draft"]["patches"] == draft["patches"])
	assert(read["draft"]["stagePatches"] == draft["stagePatches"])
	var applied: Dictionary = Store.materialize(project, draft)
	assert(applied["entries"][0]["localized"]["ru"]["text"] == "Добрый вечер")
	assert(applied["entries"][0]["localized"]["en"]["text"] == "Good evening")
	assert(applied["entries"][1]["localized"]["en"]["text"] == "Tea?")
	assert(applied["entries"][2]["localized"]["be"] == null)
	assert(applied["entries"][0]["speakerId"] == "RM-CHAR-EVELYN")
	assert(applied["entries"][0]["id"] == "RM-TEST-A-L001")
	assert(applied["scenes"] == payload["scenes"] and applied["notices"] == payload["notices"])
	assert(FileAccess.get_file_as_string(original_path) == original)
	var exported: Dictionary = Store.export_candidate(project, draft)
	assert(exported["ok"], JSON.stringify(exported))
	var path: String = str(exported["path"])
	assert(path.find("user://") < 0)
	assert(path.begins_with(ProjectSettings.globalize_path("user://")))
	assert(FileAccess.file_exists(path))
	assert(JSON.parse_string(FileAccess.get_file_as_string(path))["entries"][0]["localized"]["ru"]["text"] == "Добрый вечер")
	assert(not Store.export_candidate(project, draft)["ok"]) # No overwrite.
	assert(FileAccess.get_file_as_string(original_path) == original)
	assert(DirAccess.remove_absolute(path) == OK) # Keep smoke repeatable.
	var stage_export: Dictionary = Store.export_stage_candidate(project, draft)
	assert(stage_export.get("ok", false), JSON.stringify(stage_export))
	var stage_file: String = str(stage_export["path"])
	assert(FileAccess.file_exists(stage_file))
	assert(JSON.parse_string(FileAccess.get_file_as_string(stage_file))["sceneShots"][0]["cast"][0]["y"] == 0.725)
	assert(not Store.export_stage_candidate(project, draft)["ok"])
	assert(DirAccess.remove_absolute(stage_file) == OK)
	assert(FileAccess.get_file_as_string(original_stage_path) == original_stage_json)
	# Unsupported locale and deleted authoring IDs never silently pass.
	var bad: Dictionary = draft.duplicate(true)
	bad["patches"]["RM-TEST-A-L001"]["fr"] = "Bonjour"
	assert(not Store.validate(project, bad).is_empty())
	var missing: Dictionary = draft.duplicate(true)
	missing["patches"]["unknown-line"] = {"ru": "abc"}
	assert(not Store.validate(project, missing).is_empty())
	var empty_ru: Dictionary = draft.duplicate(true)
	empty_ru["patches"]["RM-TEST-A-L001"]["ru"] = "   "
	assert(not Store.validate(project, empty_ru).is_empty())
	_write(original_path, {"scenes": [], "entries": []})
	assert(not Store.validate(project, draft).is_empty())
	assert(not Store.save_local(project, draft)["ok"])
	assert(not Store.export_candidate(project, draft)["ok"])
	print("Raven VN Studio local story authoring and safe export smoke passed")
	quit()
