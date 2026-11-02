extends SceneTree
## VNS5-06B: draft-only new scenes, lines, translated text and Story Map compatibility.
const Store = preload("res://addons/vn_studio/editor/raven_story_store.gd")
const Author = preload("res://addons/vn_studio/model/raven_story_authoring.gd")
const Graph = preload("res://addons/vn_studio/model/raven_story_graph_draft.gd")
const View = preload("res://addons/vn_studio/editor/raven_story_view.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var root_path: String = ProjectSettings.globalize_path("res://")
	var paths: Array = [Store.RELATIVE, Store.ROUTES, Store.STAGING, Store.CAST]
	var hashes: Dictionary = {}
	for path in paths:
		hashes[path] = FileAccess.get_sha256(root_path.path_join(path))
	var project: Dictionary = Store.open_project(root_path)
	assert(project.get("ok", false), str(project.get("error", "")))
	assert(project["sceneCount"] == 28 and project["lineCount"] == 280)
	var original: Dictionary = Store.fresh(project)
	assert(original.get("authoredScenes", []).is_empty())
	assert(Store.validate(project, original).is_empty())
	var speaker: String = str(Author.actor_ids(project)[0])
	var new_scene: Dictionary = Store.add_scene(project, original, "Новый эпизод", "Первая фраза", speaker)
	assert(new_scene.get("ok", false), str(new_scene.get("error", "")))
	var draft: Dictionary = new_scene["draft"]
	var scene_id: String = str(new_scene["sceneId"])
	assert(scene_id == "RM-DRAFT-BEAT-0001")
	assert(new_scene["lineId"] == scene_id + "-L001")
	assert(Store.scene_records(project, draft).size() == 29)
	assert(Store.entries_for(project, draft, scene_id).size() == 1)
	assert(Author.is_authored_scene(draft, scene_id))
	assert(Store.validate(project, draft).is_empty())
	assert(project["sceneCount"] == 28 and project["lineCount"] == 280, "Canonical project was mutated")
	var second: Dictionary = Store.add_scene(project, draft, "Следующий", "Вторая сцена", speaker)
	assert(second.get("ok", false))
	draft = second["draft"]
	assert(second["sceneId"] == "RM-DRAFT-BEAT-0002")
	var new_line: Dictionary = Store.add_line(project, draft, scene_id, "Новая реплика", speaker)
	assert(new_line.get("ok", false))
	draft = new_line["draft"]
	assert(new_line["lineId"] == scene_id + "-L002")
	var original_scene: String = str(project["scenes"][0]["sceneId"])
	var existing_lines: Array = Store.entries_for(project, original, original_scene)
	new_line = Store.add_line(project, draft, original_scene, "Дописанная реплика", speaker)
	assert(new_line.get("ok", false))
	draft = new_line["draft"]
	assert(new_line["lineId"] == original_scene + "-L%03d" % (existing_lines.size() + 1))
	Store.edit(draft, str(new_line["lineId"]), "en", "Draft translated line")
	Store.edit(draft, scene_id + "-L001", "ru", "Исправлено в редакторе")
	assert(Store.validate(project, draft).is_empty())
	var authored: Dictionary = Store.visible_project(project, draft)
	assert(authored["scenes"].size() == 30)
	assert(authored["routes"][scene_id]["gate"]["approvedRuntime"] == false)
	assert(authored["routes"][scene_id]["gate"]["kind"] == "draft_unapproved")
	assert(Graph.scene_ids(authored).has(scene_id))
	var edge: Dictionary = Graph.fresh(original_scene)
	edge = Graph.next_edge(edge, "choice", scene_id, "Пойти дальше", str(new_line["lineId"]), "A")
	assert(Store.set_story_graph(project, draft, edge).is_empty(), "New line checkpoints and scenes support review graph")
	assert(Store.validate(project, draft).is_empty())
	var invalid: Dictionary = draft.duplicate(true)
	invalid["authoredScenes"][0]["status"] = "already_runtime"
	assert(not Store.validate(project, invalid).is_empty(), "Draft scene cannot pretend to be runtime")
	invalid = draft.duplicate(true)
	invalid["authoredScenes"][0]["sceneId"] = original_scene
	assert(not Store.validate(project, invalid).is_empty(), "Cannot shadow canonical scene ID")
	invalid = draft.duplicate(true)
	invalid["authoredScenes"][1]["sceneId"] = scene_id
	assert(not Store.validate(project, invalid).is_empty(), "Duplicate new scene IDs rejected")
	invalid = draft.duplicate(true)
	invalid["authoredLines"][0]["id"] = str(new_scene["lineId"]).replace("-L001", "-LZZZ")
	assert(not Store.validate(project, invalid).is_empty())
	invalid = draft.duplicate(true)
	invalid["authoredLines"][0]["localized"]["ru"]["text"] = " "
	assert(not Store.validate(project, invalid).is_empty())
	invalid = draft.duplicate(true)
	invalid["authoredLines"][0]["speakerId"] = "RM-CHAR-UNKNOWN"
	assert(not Store.validate(project, invalid).is_empty())
	invalid = draft.duplicate(true)
	invalid["authoredLines"][0]["path"] = "user://injection.gd"
	assert(not Store.validate(project, invalid).is_empty())
	invalid = draft.duplicate(true)
	invalid["authoredScenes"].clear()
	assert(not Store.validate(project, invalid).is_empty(), "Cannot orphan authored lines")
	invalid = draft.duplicate(true)
	invalid["sourceSha256"] = "bad-sha"
	assert(not Store.validate(project, invalid).is_empty(), "Reject source SHA drift")
	invalid = draft.duplicate(true)
	invalid["routeSourceSha256"] = "bad-sha"
	assert(not Store.validate(project, invalid).is_empty(), "Reject route SHA drift")
	assert(not Store.add_scene(project, draft, "", "line", speaker).get("ok", false))
	assert(not Store.add_scene(project, draft, "title", "", speaker).get("ok", false))
	assert(not Store.add_line(project, draft, scene_id, "abc", "RM-CHAR-UNKNOWN").get("ok", false))
	assert(not Store.export_candidate(project, draft).get("ok", false), "Legacy export cannot drop additions")
	assert(not Store.export_fx_candidate(project, draft).get("ok", false))
	assert(not Store.export_stage_candidate(project, draft).get("ok", false))
	var artifact: Dictionary = Store.export_story_graph_candidate(project, draft)
	assert(artifact.get("ok", false), str(artifact.get("error", "")))
	var exported: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(str(artifact["path"])))
	assert(not exported["runtimeApplied"] and exported["requiresHumanReview"])
	assert(exported["authoredScenes"].size() == 2)
	assert(exported["authoredLines"].size() == 4)
	assert(exported["dialogueCatalogReview"]["scenes"].size() == 30)
	assert(exported["dialogueCatalogReview"]["status"] == "DRAFT_REVIEW_NOT_RUNTIME")
	assert(exported["storyGraphPatches"][original_scene]["edges"][0]["targetId"] == scene_id)
	var found_en: bool = false
	for item in exported["dialogueCatalogReview"]["entries"]:
		if item["id"] == new_line["lineId"]:
			found_en = item["localized"]["en"]["text"] == "Draft translated line"
	assert(found_en, "Candidate carries edits to authored lines")
	assert(not Store.export_story_graph_candidate(project, draft).get("ok", false), "No overwrite")
	assert(DirAccess.remove_absolute(str(artifact["path"])) == OK)
	# Real editor UI: create a scene, select its text, add a line, undo/redo.
	var view := View.new()
	root.add_child(view)
	assert(not view._blocked)
	var baseline_scenes: int = view._scenes.item_count
	view._show_create_scene()
	view._scene_title_input.text = "Видимая новая сцена"
	view._scene_first_line_input.text = "Первый UI текст"
	view._on_create_scene()
	assert(view._scenes.item_count == baseline_scenes + 1)
	assert(view.selected_context()["sceneId"] == "RM-DRAFT-BEAT-0001")
	assert(view._draft_stage_hint.visible and not view._stage_scroll.visible)
	assert(view._lines.item_count == 1)
	view._show_create_line()
	view._new_line_input.text = "Вторая UI реплика"
	view._on_create_line()
	assert(view._lines.item_count == 2)
	assert(view.selected_context()["lineId"].ends_with("-L002"))
	view._on_undo()
	assert(view._lines.item_count == 1)
	view._on_redo()
	assert(view._lines.item_count == 2)
	view._on_scene(0)
	assert(view._stage_scroll.visible and not view._draft_stage_hint.visible)
	view.queue_free()
	for path in paths:
		assert(FileAccess.get_sha256(root_path.path_join(path)) == hashes[path], "Canonical file mutated: " + path)
	print("Raven VN Studio VNS5-06B new scene and dialogue draft authoring smoke passed")
	quit()
