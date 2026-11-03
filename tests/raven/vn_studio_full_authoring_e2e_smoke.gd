extends SceneTree
## VNS5-09: actual local save/reopen/review export of a full 3-language
## authored Raven scene + optional A/B/C Story Map / 3 actor FX fixture.
## Every source registry is copied to an isolated user:// directory first.
## Do not use the owner's real res://-bound VN Studio draft path.
const Store = preload("res://addons/vn_studio/editor/raven_story_store.gd")
const QABranch = preload("res://addons/vn_studio/model/raven_qa_branch_demo.gd")
const Author = preload("res://addons/vn_studio/model/raven_story_authoring.gd")
const SOURCE_FILES = [Store.RELATIVE, Store.STAGING, Store.ROUTES, Store.CUES, Store.CAST]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var live_root: String = ProjectSettings.globalize_path("res://")
	var suffix: String = str(Time.get_ticks_usec())
	var fixture_root: String = ProjectSettings.globalize_path("user://vns5_09_e2e_fixture_" + suffix)
	var hashes: Dictionary = {}
	for relative in SOURCE_FILES:
		var rel: String = str(relative)
		var source_path: String = live_root.path_join(rel)
		var fixture_path: String = fixture_root.path_join(rel)
		hashes[rel] = FileAccess.get_sha256(source_path)
		assert(not str(hashes[rel]).is_empty(), "Missing canonical source " + rel)
		assert(DirAccess.make_dir_recursive_absolute(fixture_path.get_base_dir()) == OK)
		var f: FileAccess = FileAccess.open(fixture_path, FileAccess.WRITE)
		assert(f != null)
		f.store_string(FileAccess.get_file_as_string(source_path))
		f.close()
		assert(FileAccess.get_sha256(fixture_path) == hashes[rel])
	var project: Dictionary = Store.open_project(fixture_root)
	assert(project.get("ok", false), str(project.get("error", "")))
	assert(project["sceneCount"] == 28 and project["lineCount"] == 280)
	var local_path: String = Store.draft_path(fixture_root)
	assert(not FileAccess.file_exists(local_path), "E2E test must never overwrite a local draft")

	# The same accepted images and background used by the real VN Studio.
	var plate: Dictionary = QABranch._plate(project)
	assert(not plate.is_empty() and plate["backgroundId"] == "BG-HALL")
	var fresh: Dictionary = Store.fresh(project)
	var created: Dictionary = Store.add_scene(project, fresh,
		"QA · разговор в холле " + suffix, "Кого пригласить в следующую сцену?",
		"RM-CHAR-EVELYN", "09", plate)
	assert(created.get("ok", false), str(created.get("error", "")))
	var scene_id: String = str(created["sceneId"])
	var draft: Dictionary = created["draft"]
	var speakers: Array[String] = ["RM-CHAR-ADA", "RM-CHAR-ROWAN", Author.NARRATOR_ID]
	var texts: Array[String] = [
		"Я могу помочь, мисс Эвелин.",
		"Сад ещё не готов принимать гостей.",
		"В коридоре стихли шаги."
	]
	for index in range(speakers.size()):
		var added: Dictionary = Store.add_line(project, draft, scene_id, texts[index], speakers[index])
		assert(added.get("ok", false), str(added.get("error", "")))
		draft = added["draft"]
	var shot: Dictionary = Store.effective_stage(project, draft, scene_id)
	assert(shot["backgroundId"] == plate["backgroundId"])
	assert(shot["lighting"] == plate["lighting"] and shot["roomState"] == plate["roomState"])
	assert(shot["cast"].size() == 3, "Narrator must not create a fourth portrait")
	for index in range(3):
		assert(shot["cast"][index]["characterId"] == ["RM-CHAR-EVELYN", "RM-CHAR-ADA", "RM-CHAR-ROWAN"][index])
		assert(shot["cast"][index].has("assetId"), "Only real approved actor art")
	assert(draft["authoredLines"][-1]["delivery"] == "narration")

	# Reuse, don't duplicate, the already-merged four-scene A/B/C return demo.
	var before_fixture: Dictionary = draft.duplicate(true)
	var fixture: Dictionary = QABranch.build(project, draft)
	assert(fixture.get("ok", false), str(fixture.get("error", "")))
	assert(draft == before_fixture, "Fixture builder must not mutate original authored work")
	draft = fixture["draft"]
	var hub: String = str(fixture["hubSceneId"])
	var branches: Array = fixture["branchSceneIds"]
	assert(draft["authoredScenes"].size() == 5)
	assert(draft["authoredLines"].size() == 11)
	assert(branches.size() == 3)
	for index in range(branches.size()):
		var link: Dictionary = draft["storyGraphPatches"][hub]["edges"][index]
		assert(link["kind"] == "choice" and link["choiceKey"] == QABranch.KEYS[index])
		assert(link["targetId"] == branches[index])
		assert(draft["storyGraphPatches"][branches[index]]["edges"][0]["targetId"] == hub)
	assert(draft["stageFxPatches"][hub]["cues"].size() == 3)
	assert(not Store.visible_project(project, draft)["routes"][hub]["gate"]["approvedRuntime"])

	# Text and scene-title translations are real authored draft edits, not
	# fabricated production catalog translations or fallback assertions.
	for item in draft["authoredScenes"]:
		item["title"]["en"] = "QA scene " + str(item["sceneId"])
		item["title"]["be"] = "Тэставая сцэна " + str(item["sceneId"])
	for line in draft["authoredLines"]:
		var line_id: String = str(line["id"])
		Store.edit(draft, line_id, "en", "Test English dialogue: " + line_id)
		Store.edit(draft, line_id, "be", "Тэставы беларускі дыялог: " + line_id)
	var original_ids: Array = Store.entries_for(project, draft, scene_id).map(
		func(line: Dictionary) -> String: return str(line["id"]))
	var moved: Dictionary = Store.move_line_to(project, draft, scene_id,
		str(original_ids[2]), str(original_ids[1]))
	assert(moved.get("ok", false), str(moved.get("error", "")))
	draft = moved["draft"]
	assert(str(Store.entries_for(project, draft, scene_id)[1]["id"]) == str(original_ids[2]),
		"Stable actor line ID must survive authored drag/reorder")
	assert(str(Store.entries_for(project, draft, scene_id)[2]["id"]) == str(original_ids[1]))
	for line in draft["authoredLines"]:
		for lang in ["ru", "be", "en"]:
			var translated: Dictionary = Store.localized(line, draft, lang)
			assert(not str(translated["text"]).is_empty())
			assert(not translated["fallback"], "All current release authored locales are explicit")
	assert(Store.validate(project, draft).is_empty())

	# Persist to actual disk, reload the source/project, then load the exact
	# locally saved draft. This is stronger than a JSON in-memory roundtrip.
	var saved: Dictionary = Store.save_local(project, draft)
	assert(saved.get("ok", false), str(saved.get("error", "")))
	assert(str(saved["path"]) == local_path)
	var bytes_before: String = FileAccess.get_file_as_string(local_path)
	assert(not bytes_before.is_empty())
	var reopened_project: Dictionary = Store.open_project(fixture_root)
	assert(reopened_project.get("ok", false))
	var reopened: Dictionary = Store.load_draft(reopened_project)
	assert(reopened.get("ok", false) and reopened.get("found", false))
	var loaded: Dictionary = reopened["draft"]
	assert(Store.validate(reopened_project, loaded).is_empty())
	assert(loaded["authoredScenes"].size() == 5 and loaded["authoredLines"].size() == 11)
	assert(loaded["storyGraphPatches"][hub]["edges"].size() == 3)
	assert(loaded["stageFxPatches"][hub]["cues"].size() == 3)
	assert(loaded["stagePatches"][scene_id]["cast"].size() == 3)
	assert(loaded["authoredLines"][-1]["id"] == draft["authoredLines"][-1]["id"])
	assert(str(Store.entries_for(reopened_project, loaded, scene_id)[1]["id"]) == str(original_ids[2]))
	for line in loaded["authoredLines"]:
		for lang in ["ru", "be", "en"]:
			var t: Dictionary = Store.localized(line, loaded, lang)
			assert(not t["fallback"] and not str(t["text"]).is_empty())
	for id in [hub] + branches:
		assert(loaded["stagePatches"].has(id) and loaded["stageFxPatches"].has(id))

	# The complete review candidate must retain translations, graph, stage
	# and FX; no changes can appear in the canonical game's source files.
	var review: Dictionary = Store.export_story_graph_candidate(reopened_project, loaded)
	assert(review.get("ok", false), str(review.get("error", "")))
	var exported: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(str(review["path"])))
	assert(not exported["runtimeApplied"] and exported["requiresHumanReview"])
	assert(exported["authoredScenes"].size() == 5 and exported["authoredLines"].size() == 11)
	assert(exported["stagePatches"][scene_id]["cast"].size() == 3)
	assert(exported["storyGraphPatches"][hub]["edges"].size() == 3)
	assert(exported["stageFxPatches"][hub]["cues"].size() == 3)
	var review_entries: Array = exported["dialogueCatalogReview"]["entries"]
	for id in original_ids:
		var hits: Array = review_entries.filter(func(entry: Dictionary) -> bool:
			return str(entry.get("id", "")) == str(id))
		assert(hits.size() == 1)
		assert(hits[0]["localized"]["en"]["text"] == "Test English dialogue: " + str(id))
		assert(hits[0]["localized"]["be"]["text"] == "Тэставы беларускі дыялог: " + str(id))
	assert(not Store.export_story_graph_candidate(reopened_project, loaded).get("ok", false),
		"Review export must be no-overwrite")
	var tampered: Dictionary = loaded.duplicate(true)
	tampered["sourceSha256"] = "stale-source"
	assert(not Store.save_local(reopened_project, tampered).get("ok", false))
	assert(FileAccess.get_file_as_string(local_path) == bytes_before,
		"Rejected stale writes must preserve the previous draft byte for byte")
	for relative in SOURCE_FILES:
		var rel: String = str(relative)
		assert(FileAccess.get_sha256(live_root.path_join(rel)) == hashes[rel],
			"Canonical registry mutated: " + rel)

	# Remove only files created by this synthetic test; never the user's
	# res:// project, actual Raven draft or other user:// directories.
	assert(DirAccess.remove_absolute(str(review["path"])) == OK)
	assert(DirAccess.remove_absolute(local_path) == OK)
	for relative in SOURCE_FILES:
		assert(DirAccess.remove_absolute(fixture_root.path_join(str(relative))) == OK)
	for rel_dir in ["data/raven/production", "data/raven", "data", ""]:
		assert(DirAccess.remove_absolute(fixture_root.path_join(rel_dir)) == OK)
	print("Raven VN Studio VNS5-09 full authoring round-trip smoke passed")
	quit()
