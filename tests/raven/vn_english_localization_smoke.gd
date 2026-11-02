extends SceneTree
## Canonical English content and active game/Studio ID parity.
## Uses an isolated preference file and does not change campaign saves.
const Dialogue = preload("res://data/raven/production/season1_dialogue_catalog.json")
const Content = preload("res://data/raven/rm_vs_01_content.json")
const Adapter = preload("res://scripts/raven/raven_vn_catalog_adapter.gd")
const Copy = preload("res://scripts/raven/raven_production_localization.gd")
const Preview = preload("res://scripts/raven/content_preview.gd")
const GameView = preload("res://scripts/raven/raven_vn_game_view.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var translated_titles := 0
	var title_ids := {}
	for scene: Dictionary in Dialogue.data.scenes:
		var beat_id: String = str(scene["sceneId"])
		assert(not title_ids.has(beat_id))
		title_ids[beat_id] = true
		assert(not str(scene.get("title", {}).get("en", "")).strip_edges().is_empty(), beat_id)
		assert(Copy.scene_title(beat_id, "en") == scene["title"]["en"])
		translated_titles += 1
	assert(translated_titles == 28)
	var line_ids := {}
	for entry: Dictionary in Dialogue.data.entries:
		var id: String = str(entry["id"])
		assert(not line_ids.has(id))
		line_ids[id] = true
		assert(title_ids.has(str(entry["sceneId"])))
		assert(not str(entry["localized"].get("en", {}).get("text", "")).strip_edges().is_empty(), id)
		assert(Copy.line_text(id, "en") == entry["localized"]["en"]["text"])
	assert(line_ids.size() == 280)
	assert(Copy.translation_report().missingDialogueByLocale.en == 0)
	for group: Dictionary in [Content.data.prologueScenes, Content.data.vnScenes]:
		for key in group:
			var source: Dictionary = group[key]
			var ru: Dictionary = Adapter.for_legacy(source, "ru")
			var en: Dictionary = Adapter.for_legacy(source, "en")
			assert(ru.get("lineIds", []).size() == source.get("lines", []).size(), "RU mapping failure: " + str(key))
			assert(en.get("lineIds", []) == ru.get("lineIds", []), "Changed line IDs: " + str(key))
			assert(en.get("beatId") == ru.get("beatId"))
			for i in en.get("lines", []).size():
				var line_id: String = str(en["lineIds"][i])
				assert(en["lines"][i]["text"] == Copy.line_text(line_id, "en"))
				assert(ru["lines"][i]["text"] == source["lines"][i]["text"])
	assert(Copy.speaker_name("RM-CHAR-ADA", "en") == "Ada")

	var settings_path := "user://raven_english_locale_smoke.cfg"
	var preview := Preview.new()
	preview.preferences = Copy.new(settings_path)
	preview.size = Vector2(390, 844)
	root.add_child(preview)
	await process_frame
	preview._open_vn("road")
	await process_frame
	assert(preview.vn_view is GameView)
	var original_id: String = str(preview.vn_player.scene["lineIds"][0])
	var original_index: int = preview.vn_player.line_index
	assert(preview.vn_view._full_text == Copy.line_text(original_id, "ru"))
	preview._switch_locale(2) # English
	await process_frame
	assert(preview.vn_player.line_index == original_index)
	assert(preview.vn_player.scene["lineIds"][0] == original_id)
	assert(preview.vn_view._full_text == Copy.line_text(original_id, "en"))
	assert(preview.vn_view.nameplate.text == "EVELYN")
	assert(preview.vn_view.next_button.text == "Next ›")
	assert(preview.vn_view.chapter.text == Copy.scene_title("RM-BEAT-00-02", "en"))
	assert(Copy.new(settings_path).locale == "en", "Locale must persist independently of campaign")
	preview._switch_locale(0)
	await process_frame
	assert(preview.vn_player.line_index == original_index)
	assert(preview.vn_view._full_text == Copy.line_text(original_id, "ru"))
	preview.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(settings_path))
	print("Raven English VN Studio localization smoke passed")
	quit()
