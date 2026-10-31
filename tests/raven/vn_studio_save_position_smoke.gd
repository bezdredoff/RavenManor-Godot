extends SceneTree
## Synthetic-only old save fixtures: no private donor state or files in public CI.
const Inspector = preload("res://addons/vn_studio/editor/save_position_inspector.gd")
const Bundle = preload("res://addons/vn_studio/editor/conversion_bundle.gd")
const View = preload("res://addons/vn_studio/editor/migration_review_view.gd")

func _initialize() -> void:
	call_deferred("_run")

func _line(id: String, hidden: bool = false) -> Dictionary:
	return {"id": id, "hidden": hidden,
		"localized": {"ru": {"text": "тест"}, "en": {"text": "test"}, "be": {"text": "тэст"}},
		"actors": []}

func _run() -> void:
	var ids: Array = []
	var scenes: Array = []
	var positions: Dictionary = {}
	var index_map: Dictionary = {}
	for i in range(45):
		var sid: String = "S_%02d" % i
		ids.append(sid)
		index_map[str(i)] = sid
		var line_id: String = "VN%04d" % i
		var data: Dictionary = {"sceneId": sid, "lines": [_line(line_id, i == 0)]}
		var groups: Dictionary = {"base": data["lines"]}
		var mapping: Dictionary = {"base": [{"lineIndex": 0, "lineId": line_id, "legacyLineId": line_id, "hidden": i == 0}]}
		if i == 1:
			data.erase("lines")
			groups = {}
			mapping = {}
			for option in ["A", "B", "C"]:
				var first: String = "VN0041" + option
				groups[option] = [_line(first), _line("VN0042" + option)]
				mapping[option] = [
					{"lineIndex": 0, "legacyLineId": first, "lineId": first, "hidden": false},
					{"lineIndex": 1, "legacyLineId": "VN0042" + option, "lineId": "VN0042" + option, "hidden": false}]
			data["variants"] = groups
		if i == 38:
			data["branchChoiceId"] = "final-strategy"
			data["nextSceneIndices"] = {"A": 39, "B": 41, "C": 43}
			data["choiceGate"] = {"id": "final-strategy", "checkpointLineId": line_id, "choices": {"A": {}, "B": {}, "C": {}}}
		if i == 44:
			data["ending"] = {"endingId": "ENDING_C"}
		positions[sid] = mapping
		scenes.append({"id": sid, "index": i, "data": data, "groups": groups, "file": sid + ".json"})
	var contract: Dictionary = {"storyKey": "synthetic-story", "storySchema": 2,
		"storySceneIds": ids, "levelIds": ["M3_00", "M3_01"],
		"clueIds": ["CUE_001", "CUE_002"],
		"storyChoiceGateIds": ["final-strategy"],
		"tutorialConceptIds": ["basic-swap"]}
	var project: Dictionary = {"ok": true, "scenes": scenes, "contract": contract}
	var map: Dictionary = {"format": "vn-studio-save-map-v1", "sceneIndexToId": index_map,
		"linePositionsByScene": positions}
	var plan: Dictionary = {"ok": true, "files": [
		{"path": "save_migration_map.json", "json": JSON.stringify(map)}]}
	var state: Dictionary = {
		"scene": 1, "line": 1, "choice": "B", "clues": ["CUE_001"],
		"completed": [0, 1], "attempts": {"M3_00": 2},
		"readLines": ["VN0000", "VN0041B"], "tutorialsCompleted": ["basic-swap"],
		"storyChoices": {"final-strategy": "C"}
	}
	var original: String = JSON.stringify(state)
	var report: Dictionary = Inspector.inspect(project, plan, state)
	assert(report.get("ok", false), JSON.stringify(report))
	assert(report["mapped"]["sceneId"] == "S_01")
	assert(report["mapped"]["lineId"] == "VN0042B")
	assert(report["mapped"]["group"] == "B")
	assert(report["mapped"]["completedLevelIds"] == ["M3_00", "M3_01"])
	assert(report["mapped"]["readLineIds"] == ["VN0000", "VN0041B"])
	assert(JSON.stringify(state) == original)
	var envelope: Dictionary = {"format": "upds-campaign-save", "saveKey": "synthetic-story",
		"schemaVersion": 2, "state": state}
	assert(Inspector.inspect(project, plan, envelope)["ok"])
	envelope["saveKey"] = "someone-else"
	assert(not Inspector.inspect(project, plan, envelope)["ok"])
	state["scene"] = 44
	state["line"] = 1
	state["choice"] = "A"
	assert(Inspector.inspect(project, plan, state)["mapped"]["atEndingBoundary"])
	state["line"] = 2
	assert(not Inspector.inspect(project, plan, state)["ok"])
	state["scene"] = 38
	state["line"] = 0
	assert(Inspector.inspect(project, plan, state)["mapped"]["candidateNextSceneId"] == "S_43")
	state["storyChoices"]["final-strategy"] = "B"
	assert(Inspector.inspect(project, plan, state)["mapped"]["candidateNextSceneId"] == "S_41")
	state["storyChoices"]["final-strategy"] = "X"
	assert(not Inspector.inspect(project, plan, state)["ok"])
	state["storyChoices"]["final-strategy"] = "B"
	state["readLines"] = ["VN9999"]
	assert(not Inspector.inspect(project, plan, state)["ok"])
	state["readLines"] = ["VN0000"]
	state["scene"] = 0
	var hidden_report: Dictionary = Inspector.inspect(project, plan, state)
	assert(hidden_report["ok"])
	assert(hidden_report["warnings"].size() > 0)
	state["completed"] = [12]
	assert(not Inspector.inspect(project, plan, state)["ok"])
	assert(not Inspector.inspect(project, {}, state)["ok"])
	var original_scene: Dictionary = {"sceneId": "S_00", "lines": [
		{"id": "VN0000", "localized": {"ru": {"speaker": "A", "emotion": "neutral", "text": "before"}},
		"actors": [{"character": "miku", "pose": "neutral"}]}]}
	var edited_scene: Dictionary = original_scene.duplicate(true)
	edited_scene["lines"][0]["localized"]["ru"]["text"] = "after"
	edited_scene["lines"][0]["actors"][0]["vnStudioX"] = 0.625
	var paths: Array[String] = Bundle._change_paths(original_scene, edited_scene)
	assert(paths.size() == 2, JSON.stringify(paths))
	for path in paths:
		assert(Bundle._allowed_change(path), path)
	edited_scene["nextSceneIndex"] = 2
	var bad: Array[String] = Bundle._change_paths(original_scene, edited_scene)
	assert("nextSceneIndex" in bad)
	assert(not Bundle._allowed_change("nextSceneIndex"))
	assert(original_scene["lines"][0]["localized"]["ru"]["text"] == "before")
	# GUI reads a selected local JSON but never copies it into the bundle or project.
	var file_path: String = ProjectSettings.globalize_path("user://vn_studio_save_inspect_synthetic.json")
	var file: FileAccess = FileAccess.open(file_path, FileAccess.WRITE)
	assert(file != null)
	file.store_string(JSON.stringify({"scene": 0, "line": 0, "choice": "A",
		"clues": [], "completed": [], "attempts": {}, "readLines": [],
		"tutorialsCompleted": [], "storyChoices": {}}))
	file.close()
	var before: String = FileAccess.get_file_as_string(file_path)
	var view := View.new()
	root.add_child(view)
	view.set_project(project)
	view._result = plan
	view._on_save_selected(file_path)
	assert(view._save_report.text.contains("S_00"))
	assert(FileAccess.get_file_as_string(file_path) == before)
	view.queue_free()
	print("Raven VN Studio old-save position inspection smoke passed")
	quit()
