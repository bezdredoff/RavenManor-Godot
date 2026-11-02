extends SceneTree
## VNS5-06A: graph draft authoring, immutable canonical triggers, no-loss review.
const Store = preload("res://addons/vn_studio/editor/raven_story_store.gd")
const Graph = preload("res://addons/vn_studio/model/raven_story_graph_draft.gd")
const View = preload("res://addons/vn_studio/editor/raven_story_graph_view.gd")

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var root_path: String = ProjectSettings.globalize_path("res://")
	var paths: Array = [Store.RELATIVE, Store.ROUTES, Store.STAGING, Store.CAST]
	var original: Dictionary = {}
	for path in paths:
		original[path] = FileAccess.get_sha256(root_path.path_join(path))
	var project: Dictionary = Store.open_project(root_path)
	assert(project.get("ok", false), str(project.get("error", "")))
	assert(project["sceneCount"] == 28)
	var source: String = str(project["scenes"][0]["sceneId"])
	var second: String = str(project["scenes"][1]["sceneId"])
	var third: String = str(project["scenes"][2]["sceneId"])
	var checkpoint: String = str(Store.line_ids(project, source)[0])
	var levels: Array = Graph.level_ids(project)
	assert(not levels.is_empty(), "Canonical first_clear refs must provide valid Match-3 targets")
	var draft: Dictionary = Store.fresh(project)
	var original_graph: Dictionary = Graph.build(project, draft)
	assert(original_graph["nodes"].size() >= 28)
	assert(original_graph["edges"].size() >= 28)
	assert(Graph.neighborhood(original_graph, source)["nodes"].has(source))
	var data: Dictionary = Graph.fresh(source)
	assert(Graph.validate(project, data).is_empty())
	data = Graph.next_edge(data, "scene", second, "Дальше")
	assert(Graph.validate(project, data).is_empty())
	var second_unconditional: Dictionary = Graph.next_edge(data, "scene", third, "Нельзя два раза")
	assert(not Graph.validate(project, second_unconditional).is_empty())
	var wrong: Dictionary = data.duplicate(true)
	wrong["edges"][0]["targetId"] = "RM-BEAT-UNKNOWN"
	assert(not Graph.validate(project, wrong).is_empty())
	wrong = data.duplicate(true)
	wrong["edges"][0]["kind"] = "script"
	assert(not Graph.validate(project, wrong).is_empty())
	wrong = data.duplicate(true)
	wrong["edges"][0]["path"] = "res://outside.gd"
	assert(not Graph.validate(project, wrong).is_empty())
	wrong = data.duplicate(true)
	wrong["edges"][0]["label"] = " "
	assert(not Graph.validate(project, wrong).is_empty())
	data = Graph.next_edge(data, "choice", third, "Пойти к воротам", checkpoint, "A")
	data = Graph.next_edge(data, "choice", second, "Остаться дома", checkpoint, "B")
	assert(Graph.validate(project, data).is_empty())
	var duplicate_choice: Dictionary = Graph.next_edge(data, "choice", second, "Повтор", checkpoint, "A")
	assert(not Graph.validate(project, duplicate_choice).is_empty())
	wrong = data.duplicate(true)
	wrong["edges"][1]["lineId"] = str(Store.line_ids(project, second)[0])
	assert(not Graph.validate(project, wrong).is_empty(), "Wrong-scene checkpoint cannot be promoted")
	wrong = data.duplicate(true)
	wrong["edges"][1]["choiceKey"] = "D"
	assert(not Graph.validate(project, wrong).is_empty())
	var m3: Dictionary = Graph.fresh(source)
	m3 = Graph.next_edge(m3, "match3", str(levels[0]), "После победы")
	assert(Graph.validate(project, m3).is_empty())
	m3["edges"][0]["targetId"] = "RM-LVL-FAKE"
	assert(not Graph.validate(project, m3).is_empty())
	assert(Store.set_story_graph(project, draft, data).is_empty())
	assert(Store.validate(project, draft).is_empty())
	var story: Dictionary = Graph.build(project, draft)
	assert(story["edges"].size() == original_graph["edges"].size() + 3)
	assert(not Store.export_candidate(project, draft).get("ok", false), "Old JSON candidate must never drop Graph")
	assert(not Store.export_stage_candidate(project, draft).get("ok", false))
	assert(not Store.export_v2_candidate(project, draft).get("ok", false))
	assert(not Store.export_fx_candidate(project, draft).get("ok", false))
	var artifact: Dictionary = Store.export_story_graph_candidate(project, draft)
	assert(artifact.get("ok", false), str(artifact.get("error", "")))
	var target_path: String = str(artifact["path"])
	var exported: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(target_path))
	assert(not exported["runtimeApplied"] and exported["requiresHumanReview"])
	assert(exported["storyGraphPatches"][source]["edges"].size() == 3)
	assert(exported["routeSourceSha256"] == project["routesSha"])
	assert(not Store.export_story_graph_candidate(project, draft).get("ok", false), "No overwrite")
	assert(DirAccess.remove_absolute(target_path) == OK)
	var obsolete: Dictionary = draft.duplicate(true)
	obsolete["routeSourceSha256"] = "stale"
	assert(not Store.validate(project, obsolete).is_empty())
	obsolete = draft.duplicate(true)
	obsolete["storyGraphPatches"][source]["sceneId"] = second
	assert(not Store.validate(project, obsolete).is_empty())
	var widget := View.new()
	root.add_child(widget)
	widget.set_context(project, draft, source)
	assert(widget._edge_list.item_count == 3)
	assert(widget._name_map.has(source))
	widget._kind.select(1)
	widget._on_kind(1)
	widget._label.text = "Третья ветка"
	widget._choice.select(2)
	widget._checkpoint.select(0)
	widget._target.select(0)
	widget._on_add()
	assert(widget._overlay["edges"].size() == 4)
	widget._edge_list.select(3)
	widget._on_remove()
	assert(widget._overlay["edges"].size() == 3)
	# VNS5-07C1: selecting a graph node requests a scene focus in the Director.
	var requested: Array[String] = []
	widget.scene_focus_requested.connect(func(id: String): requested.append(id))
	widget._on_node_selected(third)
	assert(requested == [third])
	assert(widget._node_to_id.get(str(widget._name_map[source]), "") == source)
	# Connect from the active scene to a different scene, preserving a review-only edge.
	widget._kind.select(1) # choice
	widget._on_kind(1)
	widget._choice.select(2) # C (A and B already exist)
	widget._checkpoint.select(0)
	widget._label.clear() # drag gives a safe visible label
	var previous_size: int = widget._overlay["edges"].size()
	widget._on_connection_request(StringName(widget._name_map[source]), 0,
		StringName(widget._name_map[third]), 0)
	assert(widget._overlay["edges"].size() == previous_size + 1)
	var added: Dictionary = widget._overlay["edges"][-1]
	assert(added["kind"] == "choice" and added["targetId"] == third)
	assert(added["choiceKey"] == "C" and added["lineId"] == checkpoint)
	assert(added["label"] != "")
	var added_id: String = str(added["id"])
	# Selecting the review-only edge must populate an editor; update keeps its ID.
	widget._edge_list.select(previous_size)
	widget._on_edge_selected(previous_size)
	assert(widget._update.disabled == false)
	assert(widget._label.text == added["label"])
	widget._label.text = "Исправленная подпись"
	widget._on_update()
	assert(widget._overlay["edges"][-1]["id"] == added_id)
	assert(widget._overlay["edges"][-1]["label"] == "Исправленная подпись")
	# Invalid source and duplicate choice fail without silently changing any draft.
	previous_size = widget._overlay["edges"].size()
	widget._on_connection_request(StringName(widget._name_map[third]), 0,
		StringName(widget._name_map[source]), 0)
	assert(widget._overlay["edges"].size() == previous_size)
	widget._kind.select(1)
	widget._on_kind(1)
	widget._choice.select(2)
	widget._checkpoint.select(0)
	widget._on_connection_request(StringName(widget._name_map[source]), 0,
		StringName(widget._name_map[third]), 0)
	assert(widget._overlay["edges"].size() == previous_size)
	# Canonical connections cannot be deleted via graphical dragging.
	widget._reject_disconnection(StringName(widget._name_map[source]), 0,
		StringName(widget._name_map[third]), 0)
	assert(widget._overlay["edges"].size() == previous_size)
	widget._edge_list.select(previous_size - 1)
	widget._on_remove()
	assert(widget._overlay["edges"].size() == previous_size - 1)
	widget.queue_free()
	for path in paths:
		assert(FileAccess.get_sha256(root_path.path_join(path)) == original[path],
			"Story Map draft altered canonical source: " + path)
	print("Raven VN Studio VNS5-06A Story Map draft and immutable routes smoke passed")
	quit()
