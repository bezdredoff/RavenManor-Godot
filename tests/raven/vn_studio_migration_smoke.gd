extends SceneTree
const Reader = preload("res://addons/vn_studio/editor/legacy_reader.gd")
const Drafts = preload("res://addons/vn_studio/editor/draft_store.gd")
const Bundle = preload("res://addons/vn_studio/editor/conversion_bundle.gd")
const Review = preload("res://addons/vn_studio/editor/migration_review_view.gd")

func _initialize() -> void:
	call_deferred("_run")

func _save(path: String, value: Dictionary) -> void:
	assert(DirAccess.make_dir_recursive_absolute(path.get_base_dir()) == OK)
	var f: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	assert(f != null)
	f.store_string(JSON.stringify(value, "\t") + "\n")
	f.close()

func _line(id: String, hidden: bool = false) -> Dictionary:
	return {"id": id, "hidden": hidden, "actors": [{"character": "onoe", "pose": "neutral", "layout": "center"}],
		"localized": {"ru": {"speaker": "ОНОЭ", "emotion": "спокойно", "text": "Русский тест"},
		"en": {"speaker": "ONOE", "emotion": "neutral", "text": "English test"},
		"be": {"speaker": "ОНОЭ", "emotion": "спакойна", "text": "Беларускі тэст"}}}

func _run() -> void:
	var source: String = ProjectSettings.globalize_path("user://vn_studio_migration_synthetic_06")
	var ids: Array = []
	for i in range(45):
		ids.append("S_%02d" % i)
	_save(source.path_join("data/save_contract.json"), {"storyKey": "synthetic", "storySchema": 2,
		"storySceneIds": ids, "levelIds": ["M3_TEST"], "storyChoiceGateIds": ["final-strategy"]})
	_save(source.path_join("data/actor_layouts.json"), {"frames": {"onoe": {}}, "placements": {"center": {"x": 50}}})
	_save(source.path_join("data/asset_catalog.json"), {"assets": {"backgrounds": {}, "characters": {}}})
	for i in range(45):
		var s: Dictionary = {"sceneId": ids[i], "sceneIndex": i, "lines": [_line("VN_%03d" % i, i == 0)]}
		if i < 44:
			s["nextSceneIndex"] = i + 1
			s["nextSceneId"] = ids[i + 1]
		if i == 1:
			s.erase("sceneIndex")
			s.erase("lines")
			s["variants"] = {"A": [_line("VN_A"), _line("VN_COMMON")],
				"B": [_line("VN_B"), _line("VN_COMMON")],
				"C": [_line("VN_C"), _line("VN_COMMON")]}
			s["choices"] = {"A": {}, "B": {}, "C": {}}
			s["nextLevelId"] = "M3_TEST"
			s["onWinSceneIndex"] = 2
		if i == 38:
			s.erase("nextSceneIndex")
			s.erase("nextSceneId")
			s["branchChoiceId"] = "final-strategy"
			s["choiceGate"] = {"id": "final-strategy", "checkpointLineId": "VN_038", "choices": {"A": {}, "B": {}, "C": {}}}
			s["nextSceneIndices"] = {"A": 39, "B": 41, "C": 43}
		if i == 44:
			s.erase("nextSceneIndex")
			s.erase("nextSceneId")
			s["ending"] = {"endingId": "ENDING_C"}
		var filename: String = "prologue.json" if i == 0 else "locker_scene.json" if i == 1 else "sample_%02d_scene.json" % i
		_save(source.path_join("data").path_join(filename), s)
	var source_file: String = source.path_join("data/prologue.json")
	var original: String = FileAccess.get_file_as_string(source_file)
	var project: Dictionary = Reader.read_project(source)
	assert(project.get("ok", false), str(project.get("error", "")))
	var draft: Dictionary = Drafts.fresh(source, project["scenes"][0])
	Drafts.set_localized(draft, "base", 0, "VN_000", "ru", "text", "Правка черновика")
	Drafts.set_actor(draft, "base", 0, "VN_000", 0, "onoe", "x", 0.625)
	assert(Drafts.save_draft(source, project["scenes"][0], draft)["ok"])
	var plan: Dictionary = Bundle.prepare(project)
	assert(plan.get("ok", false), JSON.stringify(plan.get("errors", [])))
	assert(plan["stats"]["scenes"] == 45 and plan["stats"]["files"] == 47)
	assert(plan["stats"]["lines"] == 50 and plan["stats"]["changed"] == 1)
	var first: Dictionary = JSON.parse_string(plan["files"][0]["json"])
	assert(first["format"] == "vn-studio-scene-v1")
	assert(first["payload"]["lines"][0]["localized"]["ru"]["text"] == "Правка черновика")
	assert(first["payload"]["lines"][0]["localized"]["be"]["text"] == "Беларускі тэст")
	assert(first["legacyOriginal"]["lines"][0]["localized"]["ru"]["text"] == "Русский тест")
	assert(first["payload"]["lines"][0]["hidden"])
	var variant: Dictionary = JSON.parse_string(plan["files"][1]["json"])
	assert(variant["payload"]["variants"]["A"][1]["id"] == "VN_COMMON")
	assert(variant["payload"]["variants"]["B"][1]["id"] == "VN_COMMON")
	assert(variant["payload"]["nextLevelId"] == "M3_TEST")
	var mapping: Dictionary = JSON.parse_string(plan["files"][45]["json"])
	assert(mapping["sceneIndexToId"]["44"] == "S_44")
	assert(mapping["linePositionsByScene"]["S_01"]["C"][1]["legacyLineId"] == "VN_COMMON")
	assert(mapping["status"] == "PROPOSED_NOT_VALIDATED_WITH_EXISTING_SAVES")
	assert(Bundle.prepare(project)["bundleId"] == plan["bundleId"])
	assert(not Bundle.export_new_bundle(project, plan, false)["ok"])
	var exported: Dictionary = Bundle.export_new_bundle(project, plan, true)
	assert(exported["ok"], JSON.stringify(exported))
	assert(FileAccess.file_exists(exported["path"].path_join("scenes/00.json")))
	assert(FileAccess.file_exists(exported["path"].path_join("conversion_manifest.json")))
	assert(not Bundle.export_new_bundle(project, plan, true)["ok"])
	assert(FileAccess.get_file_as_string(source_file) == original)
	Drafts.set_localized(draft, "base", 0, "VN_000", "ru", "text", "Несогласованная версия")
	assert(Drafts.save_draft(source, project["scenes"][0], draft)["ok"])
	assert(not Bundle.export_new_bundle(project, plan, true)["ok"])
	_save(source_file, {"sceneId": "DIFFERENT", "lines": []})
	assert(not Bundle.prepare(project)["ok"])
	assert(FileAccess.file_exists(exported["path"].path_join("scenes/00.json")))
	var panel := Review.new()
	root.add_child(panel)
	panel.set_project(project)
	assert(panel._export_button.disabled)
	panel.analyze(project, {}, {})
	assert(not panel._result.get("ok", false))
	panel.queue_free()
	print("Raven VN Studio migration dry-run and immutable export smoke passed")
	quit()
