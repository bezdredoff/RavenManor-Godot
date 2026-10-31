extends SceneTree
## Synthetic fixture only: no private UPDS material is used or written to Raven.
const Reader = preload("res://addons/vn_studio/editor/legacy_reader.gd")


func _initialize() -> void:
	call_deferred("_run")


func _write_json(base: String, path: String, data: Dictionary) -> void:
	var dest: String = base.path_join(path)
	DirAccess.make_dir_recursive_absolute(dest.get_base_dir())
	var handle: FileAccess = FileAccess.open(dest, FileAccess.WRITE)
	assert(handle != null)
	handle.store_string(JSON.stringify(data))
	handle.close()


func _run() -> void:
	var folder: String = ProjectSettings.globalize_path("user://vn_studio_synthetic")
	DirAccess.make_dir_recursive_absolute(folder.path_join("data"))
	var ids: Array[String] = []
	for idx in range(45):
		ids.append("S_%02d" % idx)
	var contract: Dictionary = {"storySceneIds": ids}
	_write_json(folder, "data/save_contract.json", contract)
	_write_json(folder, "data/asset_catalog.json", {"assets": {"backgrounds": {}, "characters": {}}})
	_write_json(folder, "data/actor_layouts.json", {"frames": {}, "placements": {"center": {"x": 50}}})
	for idx in range(45):
		var scene: Dictionary = {
			"sceneId": ids[idx],
			"sceneIndex": idx,
			"titles": {"ru": "Тест", "en": "Test", "be": "Тэст"},
			"lines": [{
				"id": "L_%02d" % idx, "hidden": false, "actors": [],
				"localized": {
					"ru": {"speaker": "Test", "emotion": "idle", "text": "Реплика"},
					"en": {"speaker": "Test", "emotion": "idle", "text": "Line"},
					"be": {"speaker": "Test", "emotion": "idle", "text": "Рэпліка"}
				}
			}]
		}
		if idx == 1:
			scene.erase("lines")
			scene.erase("sceneIndex")  # UPDS locker legacy exception.
			scene["choices"] = {"A": {}, "B": {}, "C": {}}
			scene["variants"] = {
				"A": [{"id": "L_A", "actors": [], "localized": {"en": {"speaker": "A", "emotion": "", "text": "Option A"}}}],
				"B": [{"id": "L_B", "actors": [], "localized": {"en": {"speaker": "B", "emotion": "", "text": "Option B"}}}],
				"C": [{"id": "L_C", "actors": [], "localized": {"en": {"speaker": "C", "emotion": "", "text": "Option C"}}}]
			}
		var filename: String = "prologue.json" if idx == 0 else "locker_scene.json" if idx == 1 else "sample_%02d_scene.json" % idx
		_write_json(folder, "data/" + filename, scene)
	var original: String = FileAccess.get_file_as_string(folder.path_join("data/locker_scene.json"))
	var result: Dictionary = Reader.read_project(folder)
	assert(bool(result.get("ok", false)), str(result.get("error", "no error")))
	assert(result["scenes"].size() == 45)
	var second: Dictionary = result["scenes"][1]
	assert(second["index"] == 1)
	assert(second["groups"].keys().size() == 3)
	assert(str(second["groups"]["B"][0]["id"]) == "L_B")
	var displayed: Dictionary = Reader.localize_line(second["groups"]["B"][0], "en")
	assert(displayed["speaker"] == "B" and displayed["text"] == "Option B")
	assert(Reader.resource_path(folder, "res://assets/../untrusted.png") == "")
	assert(Reader.resource_path(folder, "user://private.txt") == "")
	assert(FileAccess.get_file_as_string(folder.path_join("data/locker_scene.json")) == original)
	# Duplicate/missing scenes fail closed, not replaced with blank previews.
	var failure: String = folder.path_join("data/prologue.json")
	var broken: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(failure))
	broken["sceneId"] = "OTHER_SCENE"
	_write_json(folder, "data/prologue.json", broken)
	var fail: Dictionary = Reader.read_project(folder)
	assert(not fail.get("ok", false))
	print("Raven VN Studio read-only legacy viewer smoke passed")
	quit()
