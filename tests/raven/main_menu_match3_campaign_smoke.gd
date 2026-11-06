extends SceneTree
## Main menu opens the real Raven Match-3 campaign without advancing story state.
const MENU := "res://scenes/raven/main_menu.tscn"
const SLICE := "res://scenes/raven/vertical_slice.tscn"
const Store = preload("res://scripts/raven/raven_campaign_store.gd")
const Preferences = preload("res://scripts/shared/upds/player_preferences.gd")
const Campaign = preload("res://scripts/raven/raven_optional_campaign_controller.gd")
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
	# Integration proof: locale selection in the shared shell must rerender
	# the campaign status and metadata without changing progress or routing.
	var localized_states := [
		{"index": 0, "locale": "ru", "level_prefix": "ДАЛЕЕ · Уровень 01"},
		{"index": 1, "locale": "be", "level_prefix": "ДАЛЕЙ · Узровень 01"},
		{"index": 2, "locale": "en", "level_prefix": "NEXT · Level 01"},
	]
	for locale_state: Dictionary in localized_states:
		slice._switch_locale(int(locale_state.index))
		assert(slice.preferences.locale == str(locale_state.locale))
		assert(slice.status.text == Campaign.status_text(str(locale_state.locale)), "Campaign status header did not follow selected language")
		assert(slice.step.title == str(Campaign.campaign_step(str(locale_state.locale)).title), "Campaign metadata title did not follow locale")
		var locale_buttons: Array[Node] = slice.body.find_children("*", "Button", true, false)
		assert(locale_buttons.size() >= 23 and (locale_buttons[0] as Button).text.begins_with(str(locale_state.level_prefix)), "Campaign list did not re-localize alongside header")
		assert(slice.state.revision == before.revision and slice.state.storyBeatsSeen == before.storyBeatsSeen, "Changing locale must not advance campaign state")
	# Restore RU for the legacy main-menu smoke and its exact-ID assertions.
	slice._switch_locale(0)
	var level_buttons: Array[Node] = slice.body.find_children("*", "Button", true, false)
	var first_level: Button
	# Route assertion must not depend on current RU/BE/EN caption text.
	# The list is authored in campaignIndex order; the first enabled level
	# is RM-LVL-101 on a fresh campaign, verified after press below.
	for node in level_buttons:
		var button := node as Button
		if button != null and not button.disabled:
			first_level = button
			break
	assert(first_level != null, "First campaign level should be available from the menu in any locale")
	first_level.pressed.emit()
	await process_frame
	assert(slice.match_game != null and slice.match_game.level_data.id == "RM-LVL-101", "First optional level must start from this route")
	var match3_surface := slice.find_child("UPDSMatch3FullScreen", true, false) as Control
	assert(match3_surface != null and slice.match3_frame.visible, "Match-3 must use the UPDS full-screen layout")
	assert(not slice.technical_shell.visible and not slice.vn_frame.visible, "Technical footer or VN frame leaked into Match-3 view")
	assert(match3_surface.find_child("UPDSMatch3Header", true, false) != null)
	assert(match3_surface.find_child("UPDSGoalCard", true, false) != null)
	assert(match3_surface.find_child("UPDSMovesCard", true, false) != null)
	assert(match3_surface.find_child("UPDSMatch3BoardFrame", true, false) != null)
	assert(match3_surface.find_child("UPDSMatch3Bark", true, false) != null)
	var board_presenter: Variant = slice.find_child("RavenMatch3Board", true, false)
	assert(board_presenter != null and board_presenter.separate_hud, "Goal/Moves card split must retain original board presenter")
	assert(board_presenter.moves_label.text == str(slice.match_game.moves_left), "Move counter must reflect the real UPDS board game")
	assert(board_presenter.objective.get_parent().name == "UPDSGoalContent")
	assert(board_presenter.hint_button.get_parent().name == "UPDSMatch3Hint")
	assert(board_presenter.help_button.get_parent().name == "UPDSHelpSlot")
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
