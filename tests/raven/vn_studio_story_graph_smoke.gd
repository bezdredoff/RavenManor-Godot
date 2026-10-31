extends SceneTree
## Synthetic private-free UPDS graph regression: no authoring/donor mutations.
const Model = preload("res://addons/vn_studio/editor/story_graph_model.gd")
const Viewer = preload("res://addons/vn_studio/editor/story_graph_view.gd")


func _initialize() -> void:
	call_deferred("_run")


func _has_edge(model: Dictionary, from_id: String, to_id: String, label: String = "") -> bool:
	for edge in model["edges"]:
		if edge["from"] == from_id and edge["to"] == to_id and (label.is_empty() or edge["label"] == label):
			return true
	return false


func _run() -> void:
	var ids: Array = []
	var scenes: Array = []
	for i in range(45):
		ids.append("TEST_SCENE_%02d" % i)
	for i in range(45):
		var data: Dictionary = {
			"sceneId": ids[i], "sceneIndex": i,
			"titles": {"ru": "Тест %d" % i, "en": "Test %d" % i, "be": "Тэст %d" % i},
			"lines": [{"id": "VN_%02d" % i, "hidden": false,
				"localized": {"ru": {"text": "тест"}, "en": {"text": "test"}, "be": {"text": "тэст"}}}]
		}
		if i < 44:
			data["nextSceneIndex"] = i + 1
			data["nextSceneId"] = ids[i + 1]
		else:
			data["ending"] = {"endingId": "END_C"}
		if i == 1:
			data.erase("lines")
			data.erase("sceneIndex")
			data.erase("nextSceneIndex")
			data.erase("nextSceneId")
			data["variants"] = {"A": [{"id": "VN_1A"}], "B": [{"id": "VN_1B"}], "C": [{"id": "VN_1C"}]}
			data["choices"] = {"A": {"ru": {"title": "A"}}, "B": {}, "C": {}}
			data["nextLevelId"] = "M3_00"
			data["onWinSceneIndex"] = 2
		if i == 3:
			data.erase("nextSceneIndex")
			data.erase("nextSceneId")
			data["nextLevelId"] = "M3_01"
			data["onWinSceneIndex"] = 4
			data["choiceGate"] = {"id": "meeting-tone", "checkpointLineId": "VN_03",
				"prompt": {"ru": "Как поступить?"}, "choices": {"A": {"ru": {"title": "Спросить", "effect": "+1"}}, "B": {"ru": {"title": "Ждать"}}}}
		if i == 38:
			data.erase("nextSceneIndex")
			data.erase("nextSceneId")
			data["nextSceneIndices"] = {"A": 39, "B": 41, "C": 43}
			data["branchChoiceId"] = "final-strategy"
			data["choiceGate"] = {"id": "final-strategy", "checkpointLineId": "VN_38",
				"choices": {"A": {}, "B": {}, "C": {}}, "prompt": {"en": "Final choice"}}
		if i == 40:
			data.erase("nextSceneIndex")
			data.erase("nextSceneId")
			data["ending"] = {"endingId": "END_B"}
		if i == 42:
			data.erase("nextSceneIndex")
			data.erase("nextSceneId")
			data["ending"] = {"endingId": "END_A", "fallbackEndingId": "END_B",
				"successRequirement": {"evidence": 7, "teamTrust": 2, "sourceTrust": 2}}
		scenes.append({"id": ids[i], "index": i, "file": "TEST_%02d.json" % i, "data": data})
	var project: Dictionary = {"scenes": scenes, "contract": {
		"storySceneIds": ids, "levelIds": ["M3_00", "M3_01"],
		"storyChoiceGateIds": ["meeting-tone", "final-strategy"]
	}}
	var frozen: String = JSON.stringify(project)
	var graph: Dictionary = Model.build(project)
	assert(graph["warnings"].is_empty(), JSON.stringify(graph["warnings"]))
	assert(graph["stats"]["sceneNodes"] == 45)
	assert(graph["stats"]["variants"] == 3)
	assert(graph["stats"]["choiceGates"] == 2)
	assert(graph["stats"]["match3"] == 2)
	assert(graph["stats"]["endings"] == 3)
	assert(_has_edge(graph, "scene:TEST_SCENE_01", "variant:TEST_SCENE_01:A", "A"))
	assert(_has_edge(graph, "variant:TEST_SCENE_01:C", "m3:M3_00"))
	assert(_has_edge(graph, "m3:M3_00", "scene:TEST_SCENE_02", "победа"))
	assert(_has_edge(graph, "scene:TEST_SCENE_03", "choice:TEST_SCENE_03:meeting-tone"))
	assert(_has_edge(graph, "choice:TEST_SCENE_03:meeting-tone", "m3:M3_01"))
	for item in ["A", "B", "C"]:
		var next: int = {"A": 39, "B": 41, "C": 43}[item]
		assert(_has_edge(graph, "choice:TEST_SCENE_38:final-strategy", "scene:TEST_SCENE_%02d" % next, item))
	assert(_has_edge(graph, "scene:TEST_SCENE_42", "ending:END_A"))
	assert(_has_edge(graph, "ending:END_A", "ending:END_B", "условие не выполнено"))
	var focus: Dictionary = Model.neighborhood(graph, "scene:TEST_SCENE_38", 2)
	assert(focus["nodes"].has("choice:TEST_SCENE_38:final-strategy"))
	assert(focus["nodes"].has("scene:TEST_SCENE_39"))
	assert(focus["nodes"].has("scene:TEST_SCENE_41"))
	assert(focus["nodes"].has("scene:TEST_SCENE_43"))
	assert(focus["nodes"].size() < graph["nodes"].size())
	assert(JSON.stringify(Model.build(project)) == JSON.stringify(graph))
	assert(JSON.stringify(project) == frozen)
	var widget := Viewer.new()
	root.add_child(widget)
	widget.set_project(project)
	widget.focus_scene("TEST_SCENE_38")
	assert(widget.get_child_count() >= 3)
	assert(widget._model["stats"]["sceneNodes"] == 45)
	assert(widget._visible.has("choice:TEST_SCENE_38:final-strategy"))
	widget._show_all.button_pressed = true
	assert(widget._visible.size() == graph["nodes"].size())
	widget.queue_free()
	print("Raven VN Studio story graph smoke passed")
	quit()
