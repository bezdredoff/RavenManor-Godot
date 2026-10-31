extends SceneTree
## Raven Manor two-source authoring safety. Only synthetic user:// sources are modified.
const Store = preload("res://addons/vn_studio/editor/raven_story_store.gd")
const View = preload("res://addons/vn_studio/editor/raven_story_view.gd")


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
	_write(source.path_join(Store.STAGING), {"sceneShots": [
		{"sceneId": scene_a, "backgroundId": "BG-HALL", "cast": [{"characterId": "RM-CHAR-EVELYN", "slot": "left"}]},
		{"sceneId": scene_b, "backgroundId": "BG-KITCHEN", "cast": []}]})
	_write(source.path_join(Store.ROUTES), {"sceneTriggers": [
		{"sceneId": scene_a, "gate": {"kind": "auto_new_game", "ref": "none"}},
		{"sceneId": scene_b, "gate": {"kind": "scene_complete", "ref": scene_a}}]})
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
	assert(Store.validate(project, draft).is_empty())
	assert(Store.localized(payload["entries"][0], draft, "en")["translated"])
	assert(Store.localized(payload["entries"][0], draft, "en")["text"] == "Good evening")
	assert(FileAccess.get_file_as_string(original_path) == original)
	var saved: Dictionary = Store.save_local(project, draft)
	assert(saved.get("ok", false), JSON.stringify(saved))
	var read: Dictionary = Store.load_draft(project)
	assert(read["ok"] and read["found"])
	assert(read["draft"]["patches"] == draft["patches"])
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
