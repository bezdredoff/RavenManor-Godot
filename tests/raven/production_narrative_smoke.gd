extends SceneTree

const Copy = preload("res://scripts/raven/raven_production_localization.gd")
const Performance = preload("res://data/raven/production/character_performance.json")
const Stage = preload("res://data/raven/production/vn_staging.json")
const Routes = preload("res://data/raven/production/map_narrative_routes.json")
const Props = preload("res://data/raven/production/story_props.json")
const Popups = preload("res://data/raven/production/hotspot_popup_copy.json")
const Dialogue = preload("res://data/raven/production/season1_dialogue_catalog.json")


func _initialize() -> void:
	var actors: Dictionary = {}
	for actor: Dictionary in Performance.data.characters:
		actors[actor.id] = actor
	assert(actors.size() == 4)
	assert(Stage.data.masters.size() <= 11)
	assert(Stage.data.sceneShots.size() == Dialogue.data.scenes.size())
	assert(Routes.data.sceneTriggers.size() == Dialogue.data.scenes.size())
	assert(Popups.data.items.size() >= 20)
	assert(Props.data.objects.size() >= 30)

	var available_scenes := {}
	var beat_line_ids := {}
	var background_ids := {}
	for master: Dictionary in Stage.data.masters:
		background_ids[master.id] = true
	for scene: Dictionary in Dialogue.data.scenes:
		assert(not available_scenes.has(scene.sceneId), "Duplicate scene ID")
		available_scenes[scene.sceneId] = true
		beat_line_ids[scene.sceneId] = 0
	for line: Dictionary in Dialogue.data.entries:
		assert(available_scenes.has(line.sceneId), "Line belongs to missing beat")
		assert(actors.has(line.speakerId) or line.speakerId == "RM-CHAR-UNKNOWN-VOICE", "Unknown speaker")
		assert(not Copy.line_text(line.id, "ru").is_empty(), "Missing source text")
		assert(not Copy.line_text(line.id, "be").is_empty(), "Missing fallback for BE")
		assert(not Copy.line_text(line.id, "en").is_empty(), "Missing fallback for EN")
		beat_line_ids[line.sceneId] += 1
	for beat_id: String in available_scenes:
		assert(beat_line_ids[beat_id] > 0, "Empty beat: " + beat_id)
	var mapped := {}
	for shot: Dictionary in Stage.data.sceneShots:
		assert(available_scenes.has(shot.sceneId))
		assert(background_ids.has(shot.backgroundId))
		assert(shot.visibleCount >= 1 and shot.visibleCount <= 3)
		assert(shot.cast.size() == shot.visibleCount)
		assert(not mapped.has(shot.sceneId), "Duplicate VN shot")
		mapped[shot.sceneId] = true
		var slots := {}
		for member: Dictionary in shot.cast:
			assert(actors.has(member.characterId), "Invalid portrait character")
			assert(not slots.has(member.slot), "Multiple actors in one slot")
			slots[member.slot] = true
			var actor: Dictionary = actors[member.characterId]
			assert(actor.poses.has(member.pose), "Undefined pose: " + str(member.pose))
			assert(actor.emotions.has(member.emotion), "Undefined emotion: " + str(member.emotion))
	var routed := {}
	for route: Dictionary in Routes.data.sceneTriggers:
		assert(available_scenes.has(route.sceneId))
		assert(not routed.has(route.sceneId), "Duplicate story route")
		routed[route.sceneId] = true
	var popup_ids := {}
	for popup: Dictionary in Popups.data.items:
		assert(not popup_ids.has(popup.id))
		popup_ids[popup.id] = true
		for lang in ["ru", "be", "en"]:
			assert(not Copy.popup_text(popup.id, lang).is_empty(), "Missing translated popup")
	assert(Copy.normalize_locale("invalid") == "ru")
	assert(Copy.speaker_name("RM-CHAR-ROWAN", "be") == "Роўэн")
	var report := Copy.translation_report()
	assert(report.total == Dialogue.data.entries.size())
	assert(report.missingDialogueByLocale.ru == 0)
	assert(report.missingDialogueByLocale.be > 0 and report.missingDialogueByLocale.en > 0, "Translations are intentionally pending; update release quality gate when ready")

	var path := "user://raven_production_localization_smoke.cfg"
	var preferences := Copy.new(path)
	assert(preferences.set_locale("be") == OK)
	assert(Copy.new(path).locale == "be")
	assert(preferences.set_locale("invalid") == ERR_INVALID_PARAMETER)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("Raven Manor production narrative contract smoke passed.")
	quit()
