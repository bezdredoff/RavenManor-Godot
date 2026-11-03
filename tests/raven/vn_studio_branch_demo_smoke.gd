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
	assert(Store.validate(project, serialized).is_empty(), "Full graph+FX survives draft JSON serialization")
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
	view.queue_free()
	for rel in original_files:
		assert(FileAccess.get_sha256(root_path.path_join(rel)) == original_files[rel],
			"Demo must not modify a production source: " + rel)
	print("Raven VN Studio three-way branch-and-FX draft-only demo smoke passed")
	quit()
