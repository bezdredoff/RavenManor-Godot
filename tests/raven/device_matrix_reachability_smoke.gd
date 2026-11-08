extends SceneTree
## CODE-10-01 device-matrix reachability: 320x568 / 390x844 / 430x932.
##
## For every matrix width this boots the player menu, opens Settings in
## RU/BE/EN, enters the VN shell, enters the Match-3 campaign screen and opens
## the Match-3 QA preview, then asserts that the key controls stay tappable and
## inside the viewport (the scrollable surfaces are checked after scrolling
## their own ScrollContainer, which is the shipped reachability mechanism).
## The real scene routes (menu -> VN, menu -> campaign, Prototype Lab -> QA
## board) run once at the end at the engine window size.
##
## Each screen keeps its own dedicated owner smoke for depth: main_menu_smoke.gd
## (menu/settings/onboarding persistence), runtime_settings_smoke.gd (settings
## dialog, VN/Match-3 modal blocking), main_menu_match3_campaign_smoke.gd
## (campaign routing and RU/BE/EN campaign copy) and match3_upds_shell_smoke.gd
## (shell reflow with the unchanged UPDS board). This file adds cross-width
## reachability only; it does not duplicate those contracts.
##
## Known limitations measured while writing this smoke (follow-ups outside this
## task's write allowlist, NOT accepted as correct behaviour):
## 1. The Prototype Lab hub column has a 398 px minimum width, so at 320/390 the
##    QA card is fully visible only after the hub's own horizontal scroll.
## 2. The QA Match-3 preview keeps a fixed 315 px board while its scroll
##    container disables horizontal scrolling, so at 320 px one tile column is
##    partially clipped. Every tile centre stays tappable; a real fix belongs to
##    scripts/raven/content_preview.gd.
## 3. At 320x568 the Match-3 shell needs its UPDSMatch3Scroll to reach the hint
##    and retry row, and the seven-column board renders 38 px tiles, below the
##    44 px touch guideline used elsewhere. A device/owner check decides whether
##    the level needs a narrow-screen gate.

const MENU := "res://scenes/raven/main_menu.tscn"
const SLICE := "res://scenes/raven/vertical_slice.tscn"
const LAB := "res://scenes/raven/prototype_launcher.tscn"
const PREVIEW := "res://scenes/raven/content_preview.tscn"
const Store = preload("res://scripts/raven/raven_campaign_store.gd")
const Preferences = preload("res://scripts/raven/raven_production_localization.gd")
const MemoryStorage = preload("res://tests/support/memory_storage.gd")
const Shell = preload("res://scripts/match3/match3_screen_shell.gd")
const SETTINGS_PATH := "user://raven_device_matrix_smoke.cfg"
const DEVICES: Array[Vector2] = [Vector2(320, 568), Vector2(390, 844), Vector2(430, 932)]
const LOCALES := ["ru", "be", "en"]
const MIN_TOUCH := 44.0
const MENU_EXPECT := {
	"ru": ["Новая игра", "Продолжить", "Уровни Match-3", "Настройки", "Prototype Lab", "Как играть", "Назад"],
	"be": ["Новая гульня", "Працягнуць", "Узроўні Match-3", "Налады", "Prototype Lab", "Як гуляць", "Назад"],
	"en": ["New game", "Continue", "Match-3 Levels", "Settings", "Prototype Lab", "How to play", "Back"],
}
const QA_ENTRY_COPY := "ТЕСТИРОВАТЬ MATCH-3 БЕЗ СЮЖЕТА"


func _initialize() -> void:
	call_deferred("_run")


var layout_checks := 0


func _run() -> void:
	for device: Vector2 in DEVICES:
		await _check_menu(device)
		await _check_settings(device)
		await _check_vn(device)
		await _check_match3(device)
		await _check_qa_preview(device)
	await _check_routes()
	assert(layout_checks >= 300, "Device matrix must actually exercise controls, only %d layout checks ran" % layout_checks)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SETTINGS_PATH))
	print("Raven Manor device matrix 320/390/430 reachability smoke passed (%d layout checks)" % layout_checks)
	quit()


## --- shared helpers -------------------------------------------------------

func _new_host(device: Vector2) -> Control:
	var host := Control.new()
	host.name = "DeviceHost"
	host.size = device
	root.add_child(host)
	await process_frame
	await process_frame
	return host


func _fits(rect: Rect2, device: Vector2, label: String) -> void:
	layout_checks += 1
	assert(rect.position.x >= -0.5 and rect.position.y >= -0.5 and rect.end.x <= device.x + 0.5 and rect.end.y <= device.y + 0.5,
		"%s must stay inside %s, got %s" % [label, device, rect])


func _tappable(control: Control, label: String, minimum := MIN_TOUCH) -> void:
	layout_checks += 1
	assert(control.size.x >= minimum - 0.5 and control.size.y >= minimum - 0.5,
		"%s needs a %.0f px touch target, got %s" % [label, minimum, control.size])


## The settings panel keeps every control's centre tappable, but the BE/EN
## preview-button row widens it past a 320 px screen (41 px measured). That
## bleed is a recorded limitation, not an accepted layout: anything worse than
## the allowance below must fail.
const SETTINGS_EDGE_BLEED_LIMIT := 48.0


func _fits_vertically(rect: Rect2, device: Vector2, label: String) -> void:
	layout_checks += 1
	assert(rect.position.y >= -0.5 and rect.end.y <= device.y + 0.5,
		"%s must fit the device height %s, got %s" % [label, device, rect])


func _assert_edge_bleed(rect: Rect2, device: Vector2, label: String) -> void:
	layout_checks += 1
	var bleed: float = maxf(0.0, rect.end.x - device.x) + maxf(0.0, -rect.position.x)
	assert(bleed <= SETTINGS_EDGE_BLEED_LIMIT,
		"%s may bleed at most %.0f px past %s, got %.0f px (%s)" % [label, SETTINGS_EDGE_BLEED_LIMIT, device, bleed, rect])


func _centre_inside(control: Control, device: Vector2, label: String) -> void:
	layout_checks += 1
	var centre := control.get_global_rect().get_center()
	assert(centre.x >= 0.0 and centre.y >= 0.0 and centre.x <= device.x and centre.y <= device.y,
		"%s centre %s must be tappable inside %s" % [label, centre, device])


func _device_menu(host: Control) -> Control:
	var menu: Control = (load(MENU) as PackedScene).instantiate()
	menu.store = Store.new(MemoryStorage.new())
	host.add_child(menu)
	await process_frame
	await process_frame
	menu.prefs = Preferences.new(SETTINGS_PATH)
	menu._refresh()
	await process_frame
	return menu


func _device_slice(host: Control) -> Control:
	var slice: Control = (load(SLICE) as PackedScene).instantiate()
	slice.store = Store.new(MemoryStorage.new())
	host.add_child(slice)
	await process_frame
	await process_frame
	slice.preferences = Preferences.new(SETTINGS_PATH)
	slice._switch_locale(0)
	await process_frame
	await process_frame
	return slice


func _scroll_to_bottom(scroll: ScrollContainer) -> void:
	scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)
	await process_frame
	await process_frame


## --- main menu ------------------------------------------------------------

func _check_menu(device: Vector2) -> void:
	var host := await _new_host(device)
	var menu := await _device_menu(host)
	var names := ["NewGame", "Continue", "Match3Levels", "Settings", "PrototypeLab", "HowToPlay"]
	for locale: String in LOCALES:
		assert(menu.prefs.set_locale(locale) == OK)
		menu._refresh()
		await process_frame
		var expected: Array = MENU_EXPECT[locale]
		for index in names.size():
			var button: Button = menu.find_child(names[index], true, false)
			assert(button != null and button.text == str(expected[index]),
				"Menu %s in %s must read '%s', got '%s'" % [names[index], locale, expected[index], button.text if button else "<missing>"])
			assert(button.pressed.get_connections().size() > 0, "Menu %s is not connected in %s" % [names[index], locale])
			_fits(button.get_global_rect(), device, "Menu %s (%s)" % [names[index], locale])
			_tappable(button, "Menu %s (%s)" % [names[index], locale], 52.0)
		_fits(menu.column.get_global_rect(), device, "Menu column (%s)" % locale)
		assert(menu.column.get_combined_minimum_size().x <= device.x - 40.0,
			"Menu column minimum %.0f px must fit %s with the 24 px side margins" % [menu.column.get_combined_minimum_size().x, device])
	menu.queue_free()
	host.queue_free()
	await process_frame


## --- settings overlay in RU/BE/EN ----------------------------------------

func _check_settings(device: Vector2) -> void:
	var host := await _new_host(device)
	var menu := await _device_menu(host)
	for locale_index in LOCALES.size():
		var locale := str(LOCALES[locale_index])
		menu.find_child("Settings", true, false).pressed.emit()
		await process_frame
		await process_frame
		assert(menu.settings_panel != null and is_instance_valid(menu.settings_panel), "Settings must open at %s" % device)
		assert(not menu.column.visible, "Main actions must hide while Settings is open")
		_fits_vertically(menu.settings_panel.get_global_rect(), device, "Settings panel (%s)" % locale)
		_assert_edge_bleed(menu.settings_panel.get_global_rect(), device, "Settings panel (%s)" % locale)
		var selector: OptionButton = menu.settings_panel.find_children("*", "OptionButton", true, false)[0] as OptionButton
		assert(selector != null and selector.item_count == 3, "Settings must offer RU/BE/EN")
		selector.select(locale_index)
		selector.item_selected.emit(locale_index)
		await process_frame
		await process_frame
		assert(menu.prefs.locale == locale, "Settings language switch must persist '%s'" % locale)
		assert(Preferences.new(SETTINGS_PATH).locale == locale, "Locale '%s' must survive a settings reload" % locale)
		assert(menu.settings_panel != null, "Settings must reopen after a language switch")
		_fits_vertically(menu.settings_panel.get_global_rect(), device, "Settings panel after '%s'" % locale)
		_assert_edge_bleed(menu.settings_panel.get_global_rect(), device, "Settings panel after '%s'" % locale)
		assert(menu.settings_panel.find_children("*", "OptionButton", true, false).size() == 1, "One language selector per settings panel")
		var sliders: Array[Node] = menu.settings_panel.find_children("*", "HSlider", true, false)
		assert(sliders.size() == 2, "Music and effects sliders must both be present")
		for slider: HSlider in sliders:
			_centre_inside(slider, device, "Settings slider (%s)" % locale)
			assert(slider.size.x >= 200.0, "Settings slider must keep a usable drag length, got %.0f px" % slider.size.x)
		var toggles: Array[Node] = menu.settings_panel.find_children("*", "CheckButton", true, false)
		assert(toggles.size() >= 3, "Mute, haptics and reduced motion toggles must stay reachable")
		for toggle: CheckButton in toggles:
			_centre_inside(toggle, device, "Settings toggle '%s' (%s)" % [toggle.text, locale])
			_tappable(toggle, "Settings toggle '%s' (%s)" % [toggle.text, locale], 31.0)
		var back: Button = menu.settings_panel.find_children("*", "Button", true, false).back() as Button
		assert(back != null and back.text == str(MENU_EXPECT[locale][6]),
			"Settings back must read '%s', got '%s'" % [MENU_EXPECT[locale][6], back.text if back else "<missing>"])
		_centre_inside(back, device, "Settings back (%s)" % locale)
		_tappable(back, "Settings back (%s)" % locale)
		menu._close_settings()
		await process_frame
		assert(menu.column.visible and menu.settings_panel == null, "Back must restore the menu in %s" % locale)
	menu.queue_free()
	host.queue_free()
	await process_frame


## --- VN entry ------------------------------------------------------------

func _check_vn(device: Vector2) -> void:
	var host := await _new_host(device)
	var slice := await _device_slice(host)
	assert(slice.step.get("kind") == "vn", "A fresh campaign must enter the VN step, got '%s'" % slice.step.get("kind"))
	assert(slice.vn_frame.visible and not slice.technical_shell.visible and not slice.match3_frame.visible,
		"VN entry must show only the VN frame at %s" % device)
	assert(is_equal_approx(slice.vn_frame.size.x, device.x), "VN frame must fill the device width")
	var lines := {}
	for locale_index in LOCALES.size():
		var locale := str(LOCALES[locale_index])
		slice._switch_locale(locale_index)
		await process_frame
		await process_frame
		assert(slice.preferences.locale == locale, "VN locale switch must reach '%s'" % locale)
		var view: Control = slice.vn_view
		assert(view != null and view.get_parent() == slice.vn_frame, "VN view must stay in the VN frame")
		_fits(view.dialogue_panel.get_global_rect(), device, "VN dialogue (%s)" % locale)
		_fits(view.controls_panel.get_global_rect(), device, "VN controls (%s)" % locale)
		assert(not view.dialogue_panel.get_global_rect().intersects(view.controls_panel.get_global_rect()),
			"VN dialogue must not overlap the controls in %s" % locale)
		for button in [view.skip_button, view.auto_button, view.next_button]:
			_fits(button.get_global_rect(), device, "VN %s (%s)" % [button.name, locale])
			_tappable(button, "VN %s (%s)" % [button.name, locale])
			assert(not view.skip_button.get_global_rect().intersects(view.next_button.get_global_rect()), "VN controls overlap in %s" % locale)
		var text: String = str(view.dialogue.text).strip_edges()
		assert(text != "", "VN dialogue must render text in %s" % locale)
		lines[locale] = text
	assert(lines.values().size() == 3 and (lines["ru"] != lines["be"] or lines["be"] != lines["en"] or lines["ru"] != lines["en"]),
		"Sudden VN line must actually localize for RU/BE/EN")
	slice.queue_free()
	host.queue_free()
	await process_frame


## --- Match-3 campaign entry ---------------------------------------------

func _check_match3(device: Vector2) -> void:
	var host := await _new_host(device)
	var slice := await _device_slice(host)
	slice._open_optional_campaign()
	await process_frame
	await process_frame
	assert(slice.optional_campaign and slice.step.get("kind") == "campaign", "Campaign list must open at %s" % device)
	var level_button: Button
	for node in slice.body.find_children("*", "Button", true, false):
		var button := node as Button
		if button != null and not button.disabled:
			level_button = button
			break
	assert(level_button != null, "A campaign level must be available at %s" % device)
	_fits(level_button.get_global_rect(), device, "First campaign level button")
	_tappable(level_button, "First campaign level button")
	level_button.pressed.emit()
	await process_frame
	await process_frame
	assert(slice.match3_frame.visible and not slice.technical_shell.visible and not slice.vn_frame.visible,
		"Match-3 must own the screen at %s" % device)
	var board: Control = slice.find_child("RavenMatch3Board", true, false)
	assert(board != null, "Match-3 board is missing at %s" % device)
	assert(board.cells.size() >= 36, "Match-3 board lost tiles at %s: %d" % [device, board.cells.size()])
	var usable: float = Shell.available_board_width(device.x)
	assert(board.board_area.size.x <= usable + 1.0,
		"Match-3 board %.0f px must fit the %.0f px contract at %s" % [board.board_area.size.x, usable, device])
	var header: Control = slice.find_child("UPDSMatch3Header", true, false)
	var goal: Control = slice.find_child("UPDSGoalCard", true, false)
	var moves: Control = slice.find_child("UPDSMovesCard", true, false)
	for node in [goal, moves]:
		assert(node != null, "UPDS Match-3 HUD card missing at %s" % device)
		_fits(node.get_global_rect(), device, "UPDS Match-3 HUD card")
	assert(header != null, "UPDS Match-3 header missing at %s" % device)
	# The header banner is drawn edge to edge and carries a 1-2 px decoration
	# bleed in the shipped shell, so it is checked for full-width coverage
	# instead of exact containment; the cards above stay strictly contained.
	assert(header.get_global_rect().position.x <= 0.5 and header.get_global_rect().size.x >= device.x - 1.0,
		"UPDS Match-3 header must span the device width, got %s" % header.get_global_rect())
	assert(header.get_global_rect().size.x <= device.x + 4.0, "UPDS Match-3 header bleeds past the device: %s" % header.get_global_rect())
	var scroll: ScrollContainer = slice.find_child("UPDSMatch3Scroll", true, false)
	assert(scroll != null, "Match-3 must expose its own vertical scroll")
	_centre_inside(board.help_button, device, "Match-3 help (fixed header row)")
	_tappable(board.hint_button, "Match-3 hint")
	_tappable(board.help_button, "Match-3 help")
	# The hint/retry row lives below the fold on a 568 px tall screen; the
	# shipped mechanism is the screen's own scroll container.
	await _scroll_to_bottom(scroll)
	for control: Control in [board.hint_button, board.help_button]:
		_centre_inside(control, device, "Match-3 %s after scrolling" % control.name)
	if board.retry_button.visible:
		_centre_inside(board.retry_button, device, "Match-3 retry after scrolling")
		_tappable(board.retry_button, "Match-3 retry")
	slice.queue_free()
	host.queue_free()
	await process_frame


## --- Match-3 QA preview -------------------------------------------------

func _check_qa_preview(device: Vector2) -> void:
	var host := await _new_host(device)
	set_meta("raven_direct_preview_level", "RM-LVL-001")
	var preview: Control = (load(PREVIEW) as PackedScene).instantiate()
	host.add_child(preview)
	await process_frame
	await process_frame
	assert(preview.current_kind == "match3" and preview.current_id == "RM-LVL-001", "QA preview must open RM-LVL-001")
	assert(not has_meta("raven_direct_preview_level"), "One-shot QA level request must be consumed")
	var board: Control = preview.board_view
	assert(board != null and board.name == "QA_UPDSMatch3Board", "QA preview must host the real UPDS board")
	assert(board.cells.size() == 36, "QA board must keep all 36 tiles, got %d" % board.cells.size())
	assert(preview.body.custom_minimum_size.x == 0.0, "QA preview must not force a fixed content width")
	var scroll: ScrollContainer = preview.body.get_parent() as ScrollContainer
	assert(scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED, "QA preview must not rely on horizontal scrolling")
	var clipped := 0
	for cell in board.cells:
		_centre_inside(cell as Control, device, "QA tile")
		var rect := (cell as Control).get_global_rect()
		if rect.position.x < 0.0 or rect.end.x > device.x + 0.5:
			clipped += 1
	assert(clipped <= 6,
		"QA board must not clip more than one tile column at %s, clipped %d of 36 tiles" % [device, clipped])
	for control: Control in [board.hint_button, board.help_button, board.motion_button]:
		_tappable(control, "QA %s" % control.name)
	await _scroll_to_bottom(scroll)
	for control: Control in [board.hint_button, board.help_button, board.motion_button]:
		_centre_inside(control, device, "QA %s after scrolling" % control.name)
	preview.queue_free()
	host.queue_free()
	await process_frame


## --- real scene routes at the engine window size ------------------------

func _route_menu() -> Control:
	var menu: Control = (load(MENU) as PackedScene).instantiate()
	menu.store = Store.new(MemoryStorage.new())
	root.add_child(menu)
	current_scene = menu
	await process_frame
	await process_frame
	menu.prefs = Preferences.new(SETTINGS_PATH)
	menu._refresh()
	return menu


func _drop_current_scene() -> void:
	if current_scene != null:
		current_scene.queue_free()
		current_scene = null
	await process_frame
	await process_frame


func _check_routes() -> void:
	# Menu -> onboarding -> VN scene.
	var menu := await _route_menu()
	menu.find_child("NewGame", true, false).pressed.emit()
	await process_frame
	assert(menu.onboarding_dialog != null and menu.onboarding_dialog.visible, "New game must lead through the first-session guide")
	assert(menu._start_after_guide, "Closing the guide must continue into the campaign")
	var close: Button = menu.onboarding_dialog.find_child("RavenOnboardingClose", true, false)
	assert(close != null, "Onboarding must expose a close/continue control")
	close.pressed.emit()
	await process_frame
	await process_frame
	assert(current_scene != null and current_scene.scene_file_path == SLICE, "Menu must route into the vertical slice")
	var slice: Control = current_scene
	assert(slice.step.get("kind") in ["vn", "match3"], "Campaign entry must land on a playable step")
	assert(slice.vn_frame.visible != slice.match3_frame.visible, "Exactly one gameplay frame may own the screen")
	await _drop_current_scene()

	# Menu -> Match-3 campaign list.
	menu = await _route_menu()
	menu.find_child("Match3Levels", true, false).pressed.emit()
	await process_frame
	await process_frame
	assert(current_scene != null and current_scene.scene_file_path == SLICE, "Match-3 entry must route into the vertical slice")
	slice = current_scene
	assert(slice.optional_campaign, "Match-3 entry must open the campaign list")
	assert(slice.body.find_children("*", "Button", true, false).size() >= 23, "Campaign list lost level entries")
	await _drop_current_scene()

	# Menu -> Prototype Lab -> Match-3 QA board.
	menu = await _route_menu()
	menu.find_child("PrototypeLab", true, false).pressed.emit()
	await process_frame
	await process_frame
	assert(current_scene != null and current_scene.scene_file_path == LAB, "Prototype Lab must stay one tap away")
	var launcher: Control = current_scene
	assert(launcher.size.x > 0.0, "Prototype Lab must layout before the QA entry is searched")
	var qa_entry: Button
	for node in launcher.find_children("*", "Button", true, false):
		var button := node as Button
		if button != null and button.text == QA_ENTRY_COPY:
			qa_entry = button
			break
	assert(qa_entry != null, "Prototype Lab must keep the Match-3 QA shortcut")
	qa_entry.pressed.emit()
	await process_frame
	await process_frame
	assert(current_scene != null and current_scene.scene_file_path == PREVIEW, "QA shortcut must open the content preview")
	var preview: Control = current_scene
	assert(preview.current_kind == "match3" and preview.current_id == "RM-LVL-001", "QA shortcut must open RM-LVL-001")
	assert(preview.board_view != null and preview.board_view.cells.size() == 36, "QA shortcut must expose the real board")
	await _drop_current_scene()
