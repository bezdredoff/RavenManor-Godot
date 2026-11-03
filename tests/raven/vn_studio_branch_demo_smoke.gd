extends SceneTree
## User-requested end-of-draft Story Map + distinct FX QA, no runtime mutation.
const Store = preload("res://addons/vn_studio/editor/raven_story_store.gd")
const QABranch = preload("res://addons/vn_studio/model/raven_qa_branch_demo.gd")
const Graph = preload("res://addons/vn_studio/model/raven_story_graph_draft.gd")
const StageFx = preload("res://addons/vn_studio/model/stage_fx_store.gd")
const StageV2 = preload("res://addons/vn_studio/model/stage_v2_store.gd")
const View = preload("res://addons/vn_studio/editor/raven_story_view.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var root_path: String = ProjectSettings.globalize_path("res://")
	var original_files: Dictionary = {}
	for rel in [Store.RELATIVE, Store.STAGING, Store.ROUTES, Store.CAST]:
		original_files[rel] = FileAccess.get_sha256(root_path.path_join(rel))
	var project: Dictionary = Store.open_project(root_path)
	assert(project.get("ok", false))
	var original: Dictionary = Store.fresh(project)
	# Start from a pre-existing authored scene too: the fixture is appended,
	# not substituted for or mixed into the owner's earlier authored content.
	var plate: Dictionary = QABranch._plate(project)
	var prior: Dictionary = Store.add_scene(project, original,
		"QA · уже созданная сцена", "Ранее созданная реплика", QABranch.ACTORS[0], "09", plate)
	assert(prior.get("ok", false), str(prior.get("error", "")))
	var prior_draft: Dictionary = prior["draft"].duplicate(true)
	var appended: Dictionary = QABranch.build(project, prior_draft)
	assert(appended.get("ok", false), str(appended.get("error", "")))
	assert(prior_draft == prior["draft"], "Append must never mutate caller's draft")
	assert(appended["hubSceneId"] == "RM-DRAFT-BEAT-0002")
	assert(appended["draft"]["authoredScenes"].size() == 5)
	assert(appended["draft"]["authoredLines"].size() == 8)
	assert(appended["draft"]["authoredScenes"][0] == prior_draft["authoredScenes"][0])
	assert(appended["draft"]["authoredLines"][0] == prior_draft["authoredLines"][0])
	assert(appended["draft"]["stagePatches"][str(prior["sceneId"])] ==
		prior_draft["stagePatches"][str(prior["sceneId"])] )
	assert(Store.validate(project, JSON.parse_string(JSON.stringify(appended["draft"]))).is_empty())
	assert(not QABranch.build(project, appended["draft"]).get("ok", false),
		"Duplicate QA fixture must be rejected without touching other scenes")
	var user_path: String = Store.draft_path(root_path)
	var user_exists: bool = FileAccess.file_exists(user_path)
	var original_user_bytes: String = FileAccess.get_file_as_string(user_path) if user_exists else ""
	var result: Dictionary = QABranch.build(project, original)
	assert(result.get("ok", false), str(result.get("error", "")))
	var d: Dictionary = result["draft"]
	var hub: String = str(result["hubSceneId"])
	var branches: Array = result["branchSceneIds"]
	assert(project["sceneCount"] == 28 and project["lineCount"] == 280)
	assert(d["authoredScenes"].size() == 4)
	assert(d["authoredLines"].size() == 7)
	assert(branches.size() == 3)
	assert(hub == "RM-DRAFT-BEAT-0001")
	assert(Store.scene_records(project, d)[-1]["sceneId"] == branches[2], "Demo is appended to tail")
	assert(Store.validate(project, d).is_empty())
	var hub_lines: Array = Store.entries_for(project, d, hub)
	assert(hub_lines.size() == 4 and hub_lines[0]["delivery"] == "narration")
	assert(hub_lines[0]["speakerId"] == Store.Author.NARRATOR_ID)
	var stage: Dictionary = Store.effective_stage(project, d, hub)
	assert(stage.get("cast", []).size() == 3, "Evelyn, Ada, Rowan visibly staged")
	for i in range(3):
		assert(stage["cast"][i]["characterId"] == QABranch.ACTORS[i])
		assert(stage["cast"][i].has("assetId"), "Must use accepted VN portrait")
	var edges: Array = d["storyGraphPatches"][hub]["edges"]
	assert(edges.size() == 3)
	for i in range(3):
		assert(edges[i]["kind"] == "choice")
		assert(edges[i]["choiceKey"] == QABranch.KEYS[i])
		assert(edges[i]["lineId"] == result["checkpointLineId"])
		assert(edges[i]["targetId"] == branches[i])
		var back: Array = d["storyGraphPatches"][branches[i]]["edges"]
		assert(back.size() == 1 and back[0]["kind"] == "scene")
		assert(back[0]["targetId"] == hub, "Each route returns to choice hub")
		assert(Store.effective_stage(project, d, branches[i])["cast"].size() == 1)
		assert(d["stageFxPatches"][branches[i]]["cues"].size() == 1)
	var preview: Dictionary = Store.visible_project(project, d)
	var graph: Dictionary = Graph.build(preview, d)
	assert(graph["nodes"].has(hub))
	for branch in branches:
		assert(graph["nodes"].has(branch))
		assert(graph["edges"].any(func(e: Dictionary) -> bool:
			return e["from"] == branch and e["to"] == hub and e["kind"] == "draft"))
	var cues: Array = d["stageFxPatches"][hub]["cues"]
	assert(cues.size() == 3)
	assert(cues[0]["effect"] == "fade_in")
	assert(cues[1]["effect"] == "breathe")
	assert(cues[2]["effect"] == "shake")
	assert(StageFx.validate(stage, StageV2.effective(d, hub), d["stageFxPatches"][hub],
		Store.draft_line_ids(project, d, hub)).is_empty())
	assert(float(StageFx.sample(cues[0], 0)["alpha"]) < 1.0)
	assert(not QABranch.build(project, d).get("ok", false), "Demo cannot be duplicated accidentally")
	var serialized: Dictionary = JSON.parse_string(JSON.stringify(d))
	var roundtrip_error: String = Store.validate(project, serialized)
	assert(roundtrip_error.is_empty(), "Full graph+FX survives draft JSON serialization: " + roundtrip_error)
	assert(original["authoredScenes"].is_empty() and original["stageFxPatches"].is_empty())
	# Real UI preview: the user-visible action selects the hub and admits Undo.
	var view := View.new()
	root.add_child(view)
	assert(not view._blocked)
	view._on_confirm_qa_demo()
	assert(view._draft["authoredScenes"].size() == 4)
	assert(view.selected_context()["sceneId"] == hub)
	assert(view._workspace_tabs.current_tab == 3)
	assert(view._raven_graph._scene_id == hub)
	assert(view._stage_designer._fx_data["cues"].size() == 3)
	view._on_undo()
	assert(view._draft["authoredScenes"].is_empty(), "Single-click demo must be one Undo step")
	view._on_redo()
	assert(view._draft["authoredScenes"].size() == 4)
	# Undo may select the previous canonical scene; explicitly refocus the QA hub.
	view._scene_idx = project["sceneCount"]
	view._scene_switch()
	assert(view.selected_context()["sceneId"] == hub)

	# User-visible Story Map: all three orange links exist and are selectable.
	assert(view._raven_graph._edge_list.item_count == 3)
	for i in range(3):
		var from_node: StringName = StringName(view._raven_graph._name_map[hub])
		var to_node: StringName = StringName(view._raven_graph._name_map[branches[i]])
		assert(view._raven_graph._canvas.is_node_connected(from_node, 1, to_node, 1),
			"Each choice must show a draft-port wire")
	view._raven_graph._select_graph_connection({
		"from_node": StringName(view._raven_graph._name_map[hub]),
		"to_node": StringName(view._raven_graph._name_map[branches[0]]),
		"from_port": 0, "to_port": 0})
	assert(view._raven_graph._editing_edge == -1, "Canonical port must stay read-only")
	view._raven_graph._select_graph_connection({
		"from_node": StringName(view._raven_graph._name_map[hub]),
		"to_node": StringName(view._raven_graph._name_map[branches[0]]),
		"from_port": 1, "to_port": 1})
	assert(view._raven_graph._editing_edge == 0, "Draft wire selects exact choice")
	var old_label: String = str(view._draft["storyGraphPatches"][hub]["edges"][0]["label"])
	view._raven_graph._label.text = "QA · Эвелин — проверка редактирования"
	view._raven_graph._on_update()
	assert(view._draft["storyGraphPatches"][hub]["edges"][0]["label"] != old_label)
	view._on_undo()
	assert(view._draft["storyGraphPatches"][hub]["edges"][0]["label"] == old_label)
	view._on_redo()
	assert(view._draft["storyGraphPatches"][hub]["edges"][0]["label"] != old_label)
	view._on_undo() # Preserve baseline for the animation fixture.
	# Editor Animation: Play/Pause/Reset, scrub and moving a real clip persist
	# via the same signal/Undo path as mouse-driven timeline authoring.
	var stage_ui = view._stage_designer
	assert(stage_ui._fx_timeline._cues.size() == 3)
	assert(not stage_ui._fx_playing)
	stage_ui._on_fx_play()
	assert(stage_ui._fx_playing)
	stage_ui._process(0.25)
	assert(stage_ui._fx_elapsed > 0.0)
	stage_ui._on_fx_play()
	assert(not stage_ui._fx_playing)
	stage_ui._on_fx_stop()
	assert(stage_ui._fx_elapsed == 0.0)
	var old_start: int = int(view._draft["stageFxPatches"][hub]["cues"][1]["startMs"])
	stage_ui._on_timeline_move(1, 1750)
	assert(int(view._draft["stageFxPatches"][hub]["cues"][1]["startMs"]) == 1750)
	assert(Store.validate(view._project, view._draft).is_empty())
	view._on_undo()
	assert(int(view._draft["stageFxPatches"][hub]["cues"][1]["startMs"]) == old_start)
	view._on_redo()
	assert(int(view._draft["stageFxPatches"][hub]["cues"][1]["startMs"]) == 1750)
	assert(Store.validate(view._project, JSON.parse_string(JSON.stringify(view._draft))).is_empty())
	assert(FileAccess.file_exists(user_path) == user_exists,
		"Preview/Undo/FX must not implicitly save a local draft")
	if user_exists:
		assert(FileAccess.get_file_as_string(user_path) == original_user_bytes)
	view.queue_free()
	for rel in original_files:
		assert(FileAccess.get_sha256(root_path.path_join(rel)) == original_files[rel],
			"Demo must not modify a production source: " + rel)
	print("Raven VN Studio three-way branch-and-FX draft-only demo smoke passed")
	quit()
