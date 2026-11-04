extends SceneTree
## Main menu opens the real Raven Match-3 campaign without advancing story state.
const MENU := "res://scenes/raven/main_menu.tscn"
const SLICE := "res://scenes/raven/vertical_slice.tscn"
const Store = preload("res://scripts/raven/raven_campaign_store.gd")
const Preferences = preload("res://scripts/shared/upds/player_preferences.gd")
const PREFS_PATH := "user://raven_main_menu_match3_campaign_smoke.cfg"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var menu: Variant = load(MENU).instantiate()
	root.add_child(menu)
	current_scene = menu
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PREFS_PATH))
	menu.prefs = Preferences.new(PREFS_PATH)
	assert(menu.prefs.set_locale("ru") == OK)
	menu._refresh()
	var before: Dictionary = menu.store.load_campaign()
	var entry: Button = menu.find_child("Match3Levels", true, false)
	assert(entry != null and entry.text == "Уровни Match-3")
	entry.pressed.emit()
	await process_frame
	await process_frame
	var slice: Variant = current_scene
	assert(slice != null and slice.scene_file_path == SLICE, "Menu campaign entry must open the existing vertical slice scene")
	assert(slice.optional_campaign, "Campaign list should open immediately, without going through the story")
	assert(slice.return_to_main_menu_after_campaign, "Campaign return should go back to the player menu")
	assert(not has_meta("raven_open_match3_campaign_from_main_menu"), "One-shot route metadata must be consumed")
	assert(slice.state.revision == before.revision)
	assert(slice.state.storyBeatsSeen == before.storyBeatsSeen, "Opening level selection must not advance story state")
	var level_buttons: Array[Node] = slice.body.find_children("*", "Button", true, false)
	var first_level: Button
	for node in level_buttons:
		var button := node as Button
		if button != null and button.text.begins_with("ДАЛЕЕ · Уровень 01"):
			first_level = button
			break
	assert(first_level != null and not first_level.disabled, "First campaign level should be available from the menu")
	first_level.pressed.emit()
	await process_frame
	assert(slice.match_game != null and slice.match_game.level_data.id == "RM-LVL-101", "First optional level must start from this route")
	var campaign_button: Button
	for node in slice.find_children("*", "Button", true, false):
		var button := node as Button
		if button != null and button.text == "Кампания Match-3":
			campaign_button = button
			break
	assert(campaign_button != null)
	campaign_button.pressed.emit()
	await process_frame
	var return_button: Button
	for node in slice.body.find_children("*", "Button", true, false):
		var button := node as Button
		if button != null and button.text in ["В главное меню", "У галоўнае меню", "To Main Menu"]:
			return_button = button
			break
	assert(return_button != null, "Campaign launched from the menu needs a direct return to menu")
	return_button.pressed.emit()
	await process_frame
	await process_frame
	assert(current_scene != null and current_scene.scene_file_path == MENU, "Campaign exit should return to main menu")
	var after := Store.new().load_campaign()
	assert(after.revision == before.revision, "Browsing/starting campaign must not mutate the canonical save")
	assert(after.storyBeatsSeen == before.storyBeatsSeen)
	print("Raven main menu Match-3 campaign entry smoke passed")
	quit()
