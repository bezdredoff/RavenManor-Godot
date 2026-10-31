extends SceneTree
## Synthetic confidential-content-safe fixture: text is fictional test data.
const Drafts = preload("res://addons/vn_studio/editor/draft_store.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var root: String = ProjectSettings.globalize_path("user://vn_editor_03_synthetic")
	var data_dir: String = root.path_join("data")
	assert(DirAccess.make_dir_recursive_absolute(data_dir) == OK)
	var path: String = data_dir.path_join("test_scene.json")
	var line: Dictionary = {
		"id": "VN0001", "hidden": true,
		"actors": [{"character": "miku", "pose": "neutral", "layout": "left"}],
		"localized": {
			"ru": {"speaker": "МИКУ", "emotion": "НЕЙТРАЛЬНАЯ", "text": "До изменения"},
			"en": {"speaker": "MIKU", "emotion": "NEUTRAL", "text": "Before"},
			"be": {"speaker": "МІКУ", "emotion": "НЭЙТРАЛЬНАЯ", "text": "Да змены"}
		}
	}
	var original: Dictionary = {"sceneId": "VN_SCENE_00", "sceneIndex": 0, "lines": [line]}
	var writer: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	assert(writer != null)
	writer.store_string(JSON.stringify(original))
	writer.close()
	var before: String = FileAccess.get_file_as_string(path)
	var entry: Dictionary = {"index": 0, "id": "VN_SCENE_00", "file": "test_scene.json", "groups": {"base": [line]}}
	var fresh: Dictionary = Drafts.fresh(root, entry)
	assert(fresh["patches"].is_empty())
	assert(Drafts.validate(root, entry, fresh).is_empty())
	var undo: Dictionary = fresh.duplicate(true)
	Drafts.set_localized(fresh, "base", 0, "VN0001", "ru", "text", "После изменения")
	Drafts.set_localized(fresh, "base", 0, "VN0001", "ru", "speaker", "МИКУ (ШЁПОТОМ)")
	Drafts.set_actor(fresh, "base", 0, "VN0001", 0, "miku", "pose", "smile")
	Drafts.set_actor(fresh, "base", 0, "VN0001", 0, "miku", "x", 0.625)
	Drafts.set_actor(fresh, "base", 0, "VN0001", 0, "miku", "y", 0.175)
	var derived: Dictionary = Drafts.materialize(line, fresh, "base", 0)
	assert(derived["localized"]["ru"]["text"] == "После изменения")
	assert(derived["localized"]["en"]["text"] == "Before")
	assert(derived["actors"][0]["pose"] == "smile")
	assert(is_equal_approx(float(derived["actors"][0]["vnStudioX"]), 0.625))
	assert(derived["hidden"] == true and derived["id"] == "VN0001")
	assert(line["localized"]["ru"]["text"] == "До изменения")
	assert(Drafts.materialize(line, undo, "base", 0)["localized"]["ru"]["text"] == "До изменения")
	var saved: Dictionary = Drafts.save_draft(root, entry, fresh)
	assert(saved["ok"], str(saved.get("error", "")))
	var loaded: Dictionary = Drafts.load_draft(root, entry)
	assert(loaded["ok"] and loaded["found"])
	assert(loaded["draft"]["patches"] == fresh["patches"])
	assert(FileAccess.get_file_as_string(path) == before)
	# Repeated saves must not truncate or change the original donor file.
	assert(Drafts.save_draft(root, entry, loaded["draft"])["ok"])
	assert(FileAccess.get_file_as_string(path) == before)
	var bad: Dictionary = fresh.duplicate(true)
	var key: String = Drafts.patch_key("base", 0, "VN0001")
	bad["patches"][key]["actors"]["0"]["x"] = 1.2
	assert(not Drafts.validate(root, entry, bad).is_empty())
	assert(not Drafts.save_draft(root, entry, bad)["ok"])
	# A/B/C with identical IDs are still independent with index+group keys.
	assert(Drafts.patch_key("A", 0, "VN0010") != Drafts.patch_key("B", 0, "VN0010"))
	# A source mutation invalidates existing drafts instead of applying stale content.
	writer = FileAccess.open(path, FileAccess.WRITE)
	writer.store_string(before + "\n")
	writer.close()
	var drift: Dictionary = Drafts.load_draft(root, entry)
	assert(not drift["ok"] and "diff/rebase" in drift["error"])
	assert(FileAccess.get_file_as_string(path) == before + "\n")
	print("Raven VN Studio draft overlay round-trip smoke passed")
	quit()
