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
	var stage: Dictionary = Store.effective_stage(project, draft, scene_id)
	assert(not stage.is_empty() and stage["cast"].is_empty())
	stage["backgroundId"] = "BG-HALL"
	stage["lighting"] = "evening"
	stage["roomState"] = "dusty"
	var actors: Dictionary = Store.stage_options(project)["actors"]
	var actor_ids: Array = actors.keys()
	for index in range(2):
		var actor_id: String = str(actor_ids[index])
		stage["cast"].append({"characterId": actor_id, "slot": "left" if index == 0 else "right",
			"pose": actors[actor_id]["poses"][0], "emotion": actors[actor_id]["emotions"][0],
			"x": 0.15 if index == 0 else 0.65, "y": 0.35, "micro": ""})
	stage["visibleCount"] = 2
	assert(Store.set_stage(project, draft, stage).is_empty())
	assert(Store.validate(project, draft).is_empty())
	assert(Store.effective_stage(project, draft, scene_id) == stage)
	var reopened: Dictionary = JSON.parse_string(JSON.stringify(draft))
	assert(Store.validate(project, reopened).is_empty(), "Serialized draft reopens with source locks")
	assert(reopened["stagePatches"][scene_id]["cast"].size() == 2)
	assert(reopened["stagePatches"][scene_id]["cast"][0]["emotion"] == stage["cast"][0]["emotion"])
	var bad_stage: Dictionary = stage.duplicate(true)
	bad_stage["lighting"] = "night"
	assert(not Store.validate_stage(project, bad_stage, draft).is_empty(), "Uncatalogued draft plate rejected")
	bad_stage = stage.duplicate(true)
	bad_stage["cast"][1]["characterId"] = bad_stage["cast"][0]["characterId"]
	assert(not Store.validate_stage(project, bad_stage, draft).is_empty(), "Duplicate actor rejected")
	bad_stage = stage.duplicate(true)
	bad_stage["cast"][0]["x"] = 2.0
	assert(not Store.validate_stage(project, bad_stage, draft).is_empty(), "Out-of-range layout rejected")
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
	assert(exported["stagePatches"][scene_id]["backgroundId"] == "BG-HALL", "Review export retains authored background")
	assert(exported["stagePatches"][scene_id]["cast"].size() == 2, "Review export retains authored cast")
	assert(exported["stagePatches"][scene_id]["cast"][1]["pose"] == stage["cast"][1]["pose"])
	var found_en: bool = false
	for item in exported["dialogueCatalogReview"]["entries"]:
		if item["id"] == new_line["lineId"]:
			found_en = item["localized"]["en"]["text"] == "Draft translated line"
	assert(found_en, "Candidate carries edits to authored lines")
	assert(not Store.export_story_graph_candidate(project, draft).get("ok", false), "No overwrite")
	assert(DirAccess.remove_absolute(str(artifact["path"])) == OK)
	# VNS5-07F3: wizard atomically produces scene/chapter/exact background.
	var plates: Array[Dictionary] = Store.background_variants(project)
	assert(not plates.is_empty(), "Scene wizard needs at least one imported plate")
	var wizard: Dictionary = Store.add_scene(project, Store.fresh(project),
		"Комната с портретом", "Первая строка", speaker, "02", plates[0])
	assert(wizard.get("ok", false), str(wizard.get("error", "")))
	var wizard_id: String = str(wizard["sceneId"])
	var wd: Dictionary = wizard["draft"]
	assert(wd["authoredScenes"][0]["chapter"] == "02")
	assert(wd["stagePatches"][wizard_id]["backgroundId"] == plates[0]["backgroundId"])
	assert(wd["stagePatches"][wizard_id]["lighting"] == plates[0]["lighting"])
	assert(Store.validate(project, wd).is_empty())
	assert(JSON.parse_string(JSON.stringify(wd))["stagePatches"][wizard_id] ==
		wd["stagePatches"][wizard_id], "Wizard plate roundtrip must be lossless")
	assert(not Store.add_scene(project, wd, "Invalid", "RU", speaker, "XX", plates[0]).get("ok", false))
	assert(not Store.add_scene(project, wd, "Invalid", "RU", speaker, "02",
		{"backgroundId": "BG-HALL", "lighting": "invalid", "roomState": "dusty"}).get("ok", false))
	var a2: Dictionary = Store.add_line(project, wd, wizard_id, "Вторая", speaker)
	assert(a2.get("ok", false))
	wd = a2["draft"]
	var a3: Dictionary = Store.add_line(project, wd, wizard_id, "Третья", speaker)
	assert(a3.get("ok", false))
	wd = a3["draft"]
	var third_id: String = str(a3["lineId"])
	Store.edit(wd, third_id, "be", "Трэцяя")
	var ordered: Dictionary = Store.move_line(project, wd, wizard_id, third_id, -1)
	assert(ordered.get("ok", false), str(ordered.get("error", "")))
	wd = ordered["draft"]
	assert(Store.entries_for(project, wd, wizard_id)[1]["id"] == third_id)
	assert(Store.localized(Store.entries_for(project, wd, wizard_id)[1], wd, "be")["text"] == "Трэцяя")
	assert(not Store.move_line(project, wd, wizard_id, third_id, -3).get("ok", false))
	assert(not Store.move_line(project, wd, wizard_id, wizard_id + "-L001", -1).get("ok", false))
	var choice: Dictionary = Graph.fresh(wizard_id)
	choice = Graph.next_edge(choice, "choice", str(project["scenes"][0]["sceneId"]),
		"Открыть", third_id, "A")
	assert(Store.set_story_graph(project, wd, choice).is_empty())
	assert(not Store.delete_line(project, wd, wizard_id, third_id).get("ok", false),
		"Referenced draft checkpoint cannot be deleted")
	wd["storyGraphPatches"].erase(wizard_id)
	var deleted: Dictionary = Store.delete_line(project, wd, wizard_id, third_id)
	assert(deleted.get("ok", false), str(deleted.get("error", "")))
	wd = deleted["draft"]
	assert(not wd.get("patches", {}).has(third_id), "No orphan localization patches")
	assert(Store.validate(project, wd).is_empty())
	var final_delete: Dictionary = Store.delete_line(project, wd, wizard_id, wizard_id + "-L002")
	assert(final_delete.get("ok", false))
	assert(not Store.delete_line(project, final_delete["draft"], wizard_id,
		wizard_id + "-L001").get("ok", false), "Cannot empty an authored scene")
	assert(not Store.delete_line(project, wd, str(project["scenes"][0]["sceneId"]),
		str(existing_lines[0]["id"])).get("ok", false), "Canonical lines immutable")
	# Real editor UI: create a scene, select its text, add a line, undo/redo.
	var view := View.new()
	root.add_child(view)
	assert(not view._blocked)
	var baseline_scenes: int = view._scenes.item_count
	view._show_create_scene()
	assert(view._scene_chapter.item_count > 0)
	assert(view._scene_background.item_count > 0)
	var ui_plate: Dictionary = view._scene_backgrounds[view._scene_background.selected]
	view._scene_title_input.text = "Видимая новая сцена"
	view._scene_first_line_input.text = "Первый UI текст"
	view._on_create_scene()
	assert(view._scenes.item_count == baseline_scenes + 1)
	assert(view.selected_context()["sceneId"] == "RM-DRAFT-BEAT-0001")
	assert(view._draft_stage_hint.visible and view._stage_scroll.visible)
	assert(view._stage_designer._stage_data["sceneId"] == scene_id)
	assert(view._draft["stagePatches"][scene_id]["backgroundId"] == ui_plate["backgroundId"])
	assert(view._draft["authoredScenes"][0]["chapter"] == view._scene_chapter.get_item_text(view._scene_chapter.selected))
	var ui_stage: Dictionary = view._stage_designer._stage_data.duplicate(true)
	ui_stage["backgroundId"] = "BG-APARTMENT"
	ui_stage["lighting"] = "day"
	ui_stage["roomState"] = "packed_boxes"
	view._on_stage_modified(ui_stage)
	assert(view._draft["stagePatches"][scene_id]["backgroundId"] == "BG-APARTMENT")
	view._on_undo()
	assert(view._draft["stagePatches"][scene_id]["backgroundId"] == ui_plate["backgroundId"])
	view._on_redo()
	assert(view._draft["stagePatches"][scene_id]["backgroundId"] == "BG-APARTMENT")
	assert(view._lines.item_count == 1)
	view._show_create_line()
	view._new_line_input.text = "Вторая UI реплика"
	view._on_create_line()
	assert(view._lines.item_count == 2)
	assert(view.selected_context()["lineId"].ends_with("-L002"))
	assert(not view._line_delete.disabled)
	view._show_create_line()
	view._new_line_input.text = "Третья UI реплика"
	view._on_create_line()
	assert(view._lines.item_count == 3)
	var id_three: String = str(view.selected_context()["lineId"])
	view._on_line_up()
	assert(view.selected_context()["lineId"] == id_three)
	assert(view._lines.item_count == 3 and view._line_idx == 1)
	view._on_line_down()
	assert(view._line_idx == 2)
	view._delete_selected_line()
	assert(view._lines.item_count == 2)
	view._on_undo()
	assert(view._lines.item_count == 3)
	view._on_redo()
	assert(view._lines.item_count == 2)
	view._on_line(1)
	var selected_line: String = str(view.selected_context()["lineId"])
	assert(view._locale_edits["be"].text.is_empty())
	assert(view._locale_status["be"].text.contains("Не переведено"))
	view._capture_undo()
	view._locale_edits["be"].text = "Другая рэпліка"
	view._on_text_changed("be")
	view._locale_edits["en"].text = "Second line"
	view._on_text_changed("en")
	view._title_edits["be"].text = "Новая сцэна"
	view._on_title_changed("Новая сцэна", "be")
	view._on_locale(1)
	assert(view.selected_context()["lineId"] == selected_line, "Locale switch preserves line ID")
	assert(view._locale_edits["ru"].text == "Вторая UI реплика")
	assert(view._locale_edits["be"].text == "Другая рэпліка")
	assert(view._locale_edits["en"].text == "Second line")
	var long_translation: String = "Long synthetic translation. ".repeat(120)
	view._locale_edits["en"].text = long_translation
	view._on_text_changed("en")
	assert(Store.localized(view._current_entry(), view._draft, "en")["text"] == long_translation)
	view._workspace_tabs.current_tab = 2
	assert(view.selected_context()["lineId"] == selected_line, "Inspector tab preserves line ID")
	assert(Store.validate(view._project, view._draft).is_empty())
	view._on_undo()
	assert(view._locale_edits["be"].text.is_empty())
	view._on_redo()
	assert(view._lines.item_count == 2)
	view._on_scene(0)
	assert(view._stage_scroll.visible and not view._draft_stage_hint.visible)
	view.queue_free()
	for path in paths:
		assert(FileAccess.get_sha256(root_path.path_join(path)) == hashes[path], "Canonical file mutated: " + path)
	print("Raven VN Studio VNS5-06B new scene and dialogue draft authoring smoke passed")
	quit()
