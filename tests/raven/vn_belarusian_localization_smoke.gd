extends SceneTree
## Belarusian localization/ID parity in VN Studio source and playable preview.
## Only isolated language preferences are written; campaign/save state is never mutated.
const Dialogue = preload("res://data/raven/production/season1_dialogue_catalog.json")
const Content = preload("res://data/raven/rm_vs_01_content.json")
const Adapter = preload("res://scripts/raven/raven_vn_catalog_adapter.gd")
const Copy = preload("res://scripts/raven/raven_production_localization.gd")
const Preview = preload("res://scripts/raven/content_preview.gd")
const GameView = preload("res://scripts/raven/raven_vn_game_view.gd")
const Studio = preload("res://addons/vn_studio/editor/raven_story_store.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var scenes := {}
	for scene: Dictionary in Dialogue.data.scenes:
		var beat_id: String = str(scene["sceneId"])
		assert(not scenes.has(beat_id), "Duplicate scene: " + beat_id)
		scenes[beat_id] = true
		var title: String = str(scene.get("title", {}).get("be", ""))
		assert(not title.strip_edges().is_empty(), beat_id + " has no BE title")
		assert(Copy.scene_title(beat_id, "be") == title)
	assert(scenes.size() == 28)
	var known_ids := {}
	for entry: Dictionary in Dialogue.data.entries:
		var line_id: String = str(entry["id"])
		assert(not known_ids.has(line_id))
		assert(scenes.has(str(entry["sceneId"])))
		known_ids[line_id] = true
		var localized: Variant = entry.get("localized", {}).get("be")
		assert(localized is Dictionary, line_id + " BE entry absent")
		assert(not str(localized.get("text", "")).strip_edges().is_empty(), line_id + " BE line missing")
		assert(Copy.line_text(line_id, "be") == localized["text"])
	assert(known_ids.size() == 280)
	var report: Dictionary = Copy.translation_report()
	assert(report.total == 280)
	for language in ["ru", "be", "en"]:
		assert(report.missingDialogueByLocale[language] == 0, language + " is incomplete")

	# Studio reads the same checked-in source, without RU fallback on BE.
	var project: Dictionary = Studio.open_project(ProjectSettings.globalize_path("res://"))
	assert(project.get("ok", false), str(project))
	assert(project["sceneCount"] == 28 and project["lineCount"] == 280)
	var draft: Dictionary = Studio.fresh(project)
	for entry: Dictionary in project["data"]["entries"]:
		var rendered: Dictionary = Studio.localized(entry, draft, "be")
		assert(not rendered["fallback"], str(entry["id"]) + " unexpectedly used RU fallback")
		assert(rendered["translated"])
		assert(rendered["text"] == entry["localized"]["be"]["text"])

	# Old playable beats must map to identical immutable RM line IDs in all locales.
	for group: Dictionary in [Content.data.prologueScenes, Content.data.vnScenes]:
		for key in group:
			var source: Dictionary = group[key]
			var ru: Dictionary = Adapter.for_legacy(source, "ru")
			var be: Dictionary = Adapter.for_legacy(source, "be")
			var en: Dictionary = Adapter.for_legacy(source, "en")
			assert(be["beatId"] == source["beatId"] and be["lineIds"] == ru["lineIds"])
			assert(en["lineIds"] == ru["lineIds"])
			assert(be["lines"].size() == source["lines"].size())
			for i in be["lines"].size():
				var id: String = str(be["lineIds"][i])
				assert(be["lines"][i]["text"] == Copy.line_text(id, "be"))
				assert(ru["lines"][i]["text"] == source["lines"][i]["text"])
	assert(Copy.speaker_name("RM-CHAR-EVELYN", "be") == "Эвелін")
	assert(Copy.speaker_name("RM-CHAR-ROWAN", "be") == "Роўэн")

	# Real active preview: change locale on the same beat/line and retain cursor.
	var settings_path := "user://raven_belarusian_locale_smoke.cfg"
	var preview := Preview.new()
	preview.preferences = Copy.new(settings_path)
	preview.size = Vector2(390, 844)
	root.add_child(preview)
	await process_frame
	preview._open_vn("road")
	await process_frame
	assert(preview.vn_view is GameView)
	var first_id: String = str(preview.vn_player.scene["lineIds"][0])
	var first_index: int = preview.vn_player.line_index
	assert(preview.vn_view._full_text == Copy.line_text(first_id, "ru"))
	preview._switch_locale(1) # Belarusian
	await process_frame
	assert(preview.vn_player.line_index == first_index)
	assert(preview.vn_player.scene["lineIds"][0] == first_id)
	assert(preview.vn_view._full_text == Copy.line_text(first_id, "be"))
	assert(preview.vn_view.nameplate.text == "ЭВЕЛІН")
	assert(preview.vn_view.chapter.text == Copy.scene_title("RM-BEAT-00-02", "be"))
	assert(preview.vn_view.next_button.text == "Далей ›")
	assert(Copy.new(settings_path).locale == "be", "BE preference was not persisted")
	# One full screen/page tap must not lose the remaining text or skip past line two.
	for tap in range(64):
		if preview.vn_player.line_index >= 1:
			break
		preview.vn_view._next()
		await process_frame
	assert(preview.vn_player.line_index == 1, "BE pagination skipped a story line")
	var second_id: String = str(preview.vn_player.scene["lineIds"][1])
	assert(preview.vn_view._full_text == Copy.line_text(second_id, "be"))
	preview._switch_locale(2)
	await process_frame
	assert(preview.vn_player.line_index == 1)
	assert(preview.vn_player.scene["lineIds"][1] == second_id)
	assert(preview.vn_view._full_text == Copy.line_text(second_id, "en"))
	preview._switch_locale(1)
	await process_frame
	assert(preview.vn_player.line_index == 1)
	assert(preview.vn_view._full_text == Copy.line_text(second_id, "be"))
	preview.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(settings_path))
	print("Raven Belarusian VN Studio localization smoke passed")
	quit()
