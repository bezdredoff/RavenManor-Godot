extends SceneTree
## VNS5-06D1: candidate assembly with real background/actor/cue registries.
## Canonical catalogue, routes, shots, cues, cast and runtime remain immutable.
const Store = preload("res://addons/vn_studio/editor/raven_story_store.gd")
const Graph = preload("res://addons/vn_studio/model/raven_story_graph_draft.gd")
const Package = preload("res://addons/vn_studio/model/raven_production_package.gd")
const View = preload("res://addons/vn_studio/editor/raven_story_view.gd")


func _initialize() -> void:
	call_deferred("_run")


func _filled_manifest(project: Dictionary, draft: Dictionary, scene_id: String, speaker: String) -> Dictionary:
	var raw: Dictionary = Package.template(project, draft)
	assert(raw.get("ok", false), str(raw.get("error", "")))
	var data: Dictionary = raw["manifest"]
	data["reviewRef"] = "RM-OWNER-REVIEW-EXAMPLE"
	var first: Dictionary = project["stagingData"]["sceneShots"][0]
	var canonical: Dictionary = {
		"backgroundId": first["backgroundId"], "lighting": first["lighting"],
		"roomState": first["roomState"], "cast": first["cast"].duplicate(true)}
	data["sceneShots"][scene_id] = canonical
	data["routeProposals"][scene_id] = {"kind": "scene_complete",
		"ref": str(project["scenes"][0]["sceneId"]),
		"interactionTarget": "review-new-room-anchor"}
	var actor: Dictionary = {}
	for a in project["castData"]["characters"]:
		if a.get("id") == speaker:
			actor = a
			break
	assert(not actor.is_empty())
	for line_id in data["lineCues"]:
		data["lineCues"][line_id] = {
			"poseId": actor["poses"][0], "emotionId": actor["emotions"][0],
			"portraitVisible": false, "microOnEnter": null}
	return data


func _run() -> void:
	var root_path: String = ProjectSettings.globalize_path("res://")
	var sources: Array = [Store.RELATIVE, Store.ROUTES, Store.STAGING, Store.CUES, Store.CAST]
	var sha: Dictionary = {}
	for path in sources:
		sha[path] = FileAccess.get_sha256(root_path.path_join(path))
	var project: Dictionary = Store.open_project(root_path)
	assert(project.get("ok", false), str(project.get("error", "")))
	assert(project["sceneCount"] == 28 and project["lineCount"] == 280)
	assert(project["cuesSha"] == sha[Store.CUES])
	var draft: Dictionary = Store.fresh(project)
	var speaker: String = str(Store.Author.actor_ids(project)[0])
	var result: Dictionary = Store.add_scene(project, draft, "Новая библиотека", "Письмо", speaker)
	assert(result.get("ok", false))
	draft = result["draft"]
	var original: String = str(result["sceneId"])
	var new_line: String = str(result["lineId"])
	var scene: String = "RM-BEAT-07-01"
	var id_mapping: Dictionary = {}
	id_mapping[original] = scene
	assert(Store.set_promotion_map(project, draft, id_mapping).is_empty())
	assert(Store.validate(project, draft).is_empty())
	var manifest: Dictionary = _filled_manifest(project, draft, scene, speaker)
	assert(manifest["sourceSha256"] == project["sha"])
	assert(manifest["cueSourceSha256"] == project["cuesSha"])
	var checked: Dictionary = Package.assemble(project, draft, manifest)
	assert(checked.get("ok", false), str(checked.get("error", "")))
	var package: Dictionary = checked["bundle"]
	assert(package["format"] == Package.PACKAGE)
	assert(package["reviewRef"] == "RM-OWNER-REVIEW-EXAMPLE")
	assert(not package["runtimeApplied"] and not package["readyForRuntime"])
	assert(package["requiresFollowUpPromotion"] and package["requiresHumanReview"])
	assert(package["releaseBlockers"].size() >= 3)
	assert(package["files"]["season1_dialogue_catalog.json"]["scenes"].size() == 29)
	assert(package["files"]["season1_dialogue_catalog.json"]["entries"].size() == 281)
	assert(package["files"]["vn_staging.json"]["sceneShots"].size() == 29)
	assert(package["files"]["map_narrative_routes.json"]["sceneTriggers"].size() == 29)
	assert(package["files"]["line_performance_cues.json"]["cues"].size() == project["cuesData"]["cues"].size() + 1)
	assert(package["files"]["map_narrative_routes.json"]["sceneTriggers"][-1]["gate"]["approvedRuntime"] == false)
	assert(package["files"]["map_narrative_routes.json"]["sceneTriggers"][-1]["gate"]["kind"] == "draft_unapproved")
	assert(package["lineIdMap"][new_line] == scene + "-L001")
	assert(package["files"]["line_performance_cues.json"]["cues"][-1]["manualReview"])
	var bad: Dictionary = manifest.duplicate(true)
	bad["reviewRef"] = ""
	assert(not Package.assemble(project, draft, bad).get("ok", false))
	bad = manifest.duplicate(true)
	bad["savePolicy"] = "enable_runtime_now"
	assert(not Package.assemble(project, draft, bad).get("ok", false))
	bad = manifest.duplicate(true)
	bad["cueSourceSha256"] = "stale"
	assert(not Package.assemble(project, draft, bad).get("ok", false))
	bad = manifest.duplicate(true)
	bad["newArbitraryScript"] = "res://evil"
	assert(not Package.assemble(project, draft, bad).get("ok", false))
	bad = manifest.duplicate(true)
	bad["sceneShots"][scene]["backgroundId"] = "BG-FAKE"
	assert(not Package.assemble(project, draft, bad).get("ok", false))
	bad = manifest.duplicate(true)
	bad["sceneShots"][scene]["cast"][0]["characterId"] = "RM-CHAR-NOT-EXISTS"
	assert(not Package.assemble(project, draft, bad).get("ok", false))
	bad = manifest.duplicate(true)
	bad["sceneShots"][scene]["cast"][0]["pose"] = "unknown"
	assert(not Package.assemble(project, draft, bad).get("ok", false))
	bad = manifest.duplicate(true)
	bad["routeProposals"][scene]["ref"] = scene
	assert(not Package.assemble(project, draft, bad).get("ok", false), "Self gate dependency rejected")
	bad = manifest.duplicate(true)
	bad["routeProposals"][scene]["kind"] = "auto_new_game"
	assert(not Package.assemble(project, draft, bad).get("ok", false))
	bad = manifest.duplicate(true)
	bad["lineCues"][scene + "-L001"]["poseId"] = "corrupted"
	assert(not Package.assemble(project, draft, bad).get("ok", false))
	bad = manifest.duplicate(true)
	bad["lineCues"].erase(scene + "-L001")
	assert(not Package.assemble(project, draft, bad).get("ok", false), "No lost line cues")
	var edge: Dictionary = Graph.next_edge(Graph.fresh(original), "scene", str(project["scenes"][0]["sceneId"]), "Ветка")
	assert(Store.set_story_graph(project, draft, edge).is_empty())
	assert(not Package.assemble(project, draft, manifest).get("ok", false), "No release of unimplemented branching")
	draft["storyGraphPatches"] = {}
	var artifact: Dictionary = Store.export_four_registry_review(project, draft, manifest)
	assert(artifact.get("ok", false), str(artifact.get("error", "")))
	var exported: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(str(artifact["path"])))
	assert(exported["files"]["season1_dialogue_catalog.json"]["scenes"].size() == 29)
	assert(exported["cueSourceSha256"] == project["cuesSha"])
	assert(not Store.export_four_registry_review(project, draft, manifest).get("ok", false), "No overwrite")
	assert(DirAccess.remove_absolute(str(artifact["path"])) == OK)
	var first_template: Dictionary = Store.export_package_manifest_template(project, draft)
	assert(first_template.get("ok", false), str(first_template.get("error", "")))
	assert(not Store.export_package_manifest_template(project, draft).get("ok", false), "Template immutable")
	assert(DirAccess.remove_absolute(str(first_template["path"])) == OK)
	# End-user UI can load a filled JSON manifest and expose safe bundle export.
	var ui := View.new()
	root.add_child(ui)
	assert(not ui._blocked)
	assert(ui._promotion_view._file_picker != null)
	ui._show_create_scene()
	ui._scene_title_input.text = "UI title"
	ui._scene_first_line_input.text = "UI line"
	ui._on_create_scene()
	ui._on_promotion_mapping_modified(id_mapping)
	var ui_manifest: Dictionary = _filled_manifest(ui._project, ui._draft, scene, speaker)
	var tmp: String = ProjectSettings.globalize_path("user://raven_story_studio/production_package_test.json")
	var out: FileAccess = FileAccess.open(tmp, FileAccess.WRITE)
	assert(out != null)
	out.store_string(JSON.stringify(ui_manifest))
	out.close()
	ui._promotion_view._load_manifest(tmp)
	assert(not ui._promotion_view._package_button.disabled)
	assert(DirAccess.remove_absolute(tmp) == OK)
	ui.queue_free()
	for path in sources:
		assert(FileAccess.get_sha256(root_path.path_join(path)) == sha[path],
			"VNS5-06D1 touched a canonical source: " + path)
	print("Raven VN Studio VNS5-06D1 four-registry no-apply package smoke passed")
	quit()
