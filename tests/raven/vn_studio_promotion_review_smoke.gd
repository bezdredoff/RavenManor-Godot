extends SceneTree
## VNS5-06C: remap + complete no-apply candidate, reject collision, SHA
## drift and staged runtime without ever editing canonical production files.
const Store = preload("res://addons/vn_studio/editor/raven_story_store.gd")
const Promotion = preload("res://addons/vn_studio/model/raven_story_promotion.gd")
const Graph = preload("res://addons/vn_studio/model/raven_story_graph_draft.gd")
const View = preload("res://addons/vn_studio/editor/raven_story_view.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var root_dir: String = ProjectSettings.globalize_path("res://")
	var canonical: Array = [Store.RELATIVE, Store.ROUTES, Store.STAGING, Store.CAST]
	var before: Dictionary = {}
	for p in canonical:
		before[p] = FileAccess.get_sha256(root_dir.path_join(p))
	var project: Dictionary = Store.open_project(root_dir)
	assert(project.get("ok", false))
	assert(project["sceneCount"] == 28 and project["lineCount"] == 280)
	var draft: Dictionary = Store.fresh(project)
	var empty: Dictionary = Store.promotion_plan(project, draft)
	assert(not empty.get("ok", false))
	var speaker: String = str(Store.Author.actor_ids(project)[0])
	var addition: Dictionary = Store.add_scene(project, draft, "Новый черновик", "Пример реплики", speaker)
	assert(addition.get("ok", false), str(addition.get("error", "")))
	draft = addition["draft"]
	var new_scene: String = str(addition["sceneId"])
	var new_line: String = str(addition["lineId"])
	assert(not Store.promotion_plan(project, draft).get("ok", false), "Unmapped scene cannot export")
	var source: String = str(project["scenes"][0]["sceneId"])
	var original_line: String = str(project["data"]["entries"][0]["id"])
	addition = Store.add_line(project, draft, source, "Новая реплика в канонической сцене", speaker)
	assert(addition.get("ok", false))
	draft = addition["draft"]
	var appended_line: String = str(addition["lineId"])
	Store.edit(draft, new_line, "en", "New story line")
	Store.edit(draft, original_line, "ru", "Уточнённый текст")
	var source_graph: Dictionary = Graph.fresh(source)
	source_graph = Graph.next_edge(source_graph, "choice", new_scene, "Пойти по новому пути", appended_line, "A")
	assert(Store.set_story_graph(project, draft, source_graph).is_empty())
	var draft_graph: Dictionary = Graph.fresh(new_scene)
	draft_graph = Graph.next_edge(draft_graph, "scene", source, "Назад")
	assert(Store.set_story_graph(project, draft, draft_graph).is_empty())
	var mappings: Dictionary = {new_scene: "RM-BEAT-07-01"}
	assert(Store.set_promotion_map(project, draft, mappings).is_empty())
	assert(Store.validate(project, draft).is_empty())
	var plan: Dictionary = Store.promotion_plan(project, draft)
	assert(plan.get("ok", false), str(plan.get("error", "")))
	var bundle: Dictionary = plan["bundle"]
	assert(bundle["format"] == Promotion.FORMAT)
	assert(not bundle["runtimeApplied"] and not bundle["readyForRuntime"])
	assert(bundle["requiresHumanReview"] and bundle["requiresFollowUpPromotion"])
	assert(bundle["sourceSha256"] == project["sha"])
	assert(bundle["routeSourceSha256"] == project["routesSha"])
	assert(bundle["idMap"][new_scene] == "RM-BEAT-07-01")
	assert(bundle["lineIdMap"][new_line] == "RM-BEAT-07-01-L001")
	assert(bundle["lineIdMap"][appended_line] == appended_line)
	assert(bundle["reviewCatalog"]["status"] == Promotion.REVIEW_STATUS)
	assert(bundle["reviewCatalog"]["scenes"].size() == 29)
	assert(bundle["reviewCatalog"]["entries"].size() == 282)
	assert(bundle["reviewGraphPatches"]["RM-BEAT-07-01"]["edges"][0]["targetId"] == source)
	assert(bundle["reviewGraphPatches"][source]["edges"][0]["targetId"] == "RM-BEAT-07-01")
	assert(bundle["reviewGraphPatches"][source]["edges"][0]["lineId"] == appended_line)
	assert(plan["blockers"].size() >= 4, "No runtime without staging, gate and save migration")
	var produced: Dictionary = {}
	for scene in bundle["reviewCatalog"]["scenes"]:
		produced[scene["sceneId"]] = true
	assert(produced.has("RM-BEAT-07-01") and not produced.has(new_scene))
	var found_new: bool = false
	var found_existing_patch: bool = false
	for entry in bundle["reviewCatalog"]["entries"]:
		if entry["id"] == "RM-BEAT-07-01-L001":
			found_new = entry["localized"]["en"]["text"] == "New story line"
		if entry["id"] == original_line:
			found_existing_patch = entry["localized"]["ru"]["text"] == "Уточнённый текст"
	assert(found_new and found_existing_patch)
	assert(bundle["retainedDraft"]["textPatches"][new_line]["en"] == "New story line")
	assert(bundle["retainedDraft"]["authoredScenes"].size() == 1)
	assert(bundle["retainedDraft"]["authoredLines"].size() == 2)
	assert(bundle["retainedDraft"]["promotionSceneIdMap"][new_scene] == "RM-BEAT-07-01")
	assert(bundle["diffSummary"]["newScenes"] == 1)
	assert(bundle["diffSummary"]["newLines"] == 2)
	assert(bundle["diffSummary"]["changedTextCells"] == 2)
	assert(not Store.export_story_graph_candidate(project, draft).get("ok", false),
		"Older export cannot lose explicit promotion mapping")
	var wrong: Dictionary = draft.duplicate(true)
	assert(not Store.set_promotion_map(project, wrong, {new_scene: source}).is_empty(),
		"Reject collisions with existing production IDs")
	assert(not Store.set_promotion_map(project, wrong, {new_scene: "RM-BEAT-NOT-VALID"}).is_empty())
	assert(not Store.set_promotion_map(project, wrong, {"RM-DRAFT-BEAT-9999": "RM-BEAT-07-01"}).is_empty())
	wrong = draft.duplicate(true)
	wrong["sourceSha256"] = "external-drift"
	assert(not Store.promotion_plan(project, wrong).get("ok", false))
	wrong = draft.duplicate(true)
	wrong["routeSourceSha256"] = "external-drift"
	assert(not Store.promotion_plan(project, wrong).get("ok", false))
	var second: Dictionary = Store.add_scene(project, draft, "Второй черновик", "Текст", speaker)
	assert(second.get("ok", false))
	wrong = second["draft"]
	assert(not Store.set_promotion_map(project, wrong, {
		new_scene: "RM-BEAT-07-01",
		str(second["sceneId"]): "RM-BEAT-07-01"
	}).is_empty(), "Reject two draft IDs mapped to the same production scene")
	var result: Dictionary = Store.export_promotion_review(project, draft)
	assert(result.get("ok", false), str(result.get("error", "")))
	var filepath: String = str(result["path"])
	assert(filepath.begins_with(ProjectSettings.globalize_path("user://")))
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(filepath))
	assert(saved["format"] == Promotion.FORMAT)
	assert(saved["reviewCatalog"]["status"] == Promotion.REVIEW_STATUS)
	assert(saved["promotionBlockers"].size() >= 4)
	assert(not Store.export_promotion_review(project, draft).get("ok", false), "No-overwrite exports")
	assert(DirAccess.remove_absolute(filepath) == OK)
	# Dedicated native editor mapping/review interaction, Undo/Redo and no apply.
	var editor := View.new()
	root.add_child(editor)
	assert(not editor._blocked)
	assert(editor._workspace_tabs.get_tab_count() == 6)
	editor._show_create_scene()
	editor._scene_title_input.text = "UI новая сцена"
	editor._scene_first_line_input.text = "UI реплика"
	editor._on_create_scene()
	assert(editor._promotion_view._inputs.has(new_scene))
	assert(editor._promotion_view._export_button.disabled, "No mapping means no export")
	editor._on_promotion_mapping_modified({new_scene: "RM-BEAT-07-01"})
	assert(editor._draft["promotionSceneIdMap"][new_scene] == "RM-BEAT-07-01")
	assert(not editor._promotion_view._export_button.disabled)
	editor._on_undo()
	assert(editor._draft.get("promotionSceneIdMap", {}).is_empty())
	editor._on_redo()
	assert(editor._draft["promotionSceneIdMap"][new_scene] == "RM-BEAT-07-01")
	editor.queue_free()
	for p in canonical:
		assert(FileAccess.get_sha256(root_dir.path_join(p)) == before[p], "Production file was mutated: " + p)
	print("Raven VN Studio VNS5-06C promotion remap and no-apply review smoke passed")
	quit()
