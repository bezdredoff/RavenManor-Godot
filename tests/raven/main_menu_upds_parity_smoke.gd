extends SceneTree
## GAME-UI-01: main-menu failure-mode parity with the UPDS donor menu.
##
## UPDS scripts/ui/main_menu.gd keeps a persistent save-status line, locks
## Continue on an unreadable/corrupt save and still asks for confirmation
## before a New Game overwrites a save it could not read. This smoke pins the
## same observable behaviour on the real Raven menu scene, in RU/BE/EN, and
## keeps the canonical RavenCampaignStore as the only save authority.
const MENU := "res://scenes/raven/main_menu.tscn"
const Store = preload("res://scripts/raven/raven_campaign_store.gd")
const Preferences = preload("res://scripts/raven/raven_production_localization.gd")
const MemoryStorage = preload("res://tests/support/memory_storage.gd")
const CONTRACT = preload("res://data/save_contract.json")
const PREFS_PATH := "user://raven_main_menu_upds_parity_smoke.cfg"
const RU_READ_FAILED := "Не удалось прочитать сохранение. Сохранённые данные не изменены."
const BE_READ_FAILED := "Не ўдалося прачытаць захаванне. Захаваныя даныя не змененыя."
const RU_RECOVERED := "Сохранение повреждено. При возможности сохранена резервная копия."
const EN_RECOVERED := "The save could not be loaded. A recovery copy was kept when storage allowed it."
const RU_RESET_FAILED := "Не удалось сбросить прогресс игры"
const DISABLED_ALPHA := 0.38


class ReadFailStorage:
	extends RefCounted
	var last_error: Error = OK

	func get_item(_key: String) -> Variant:
		last_error = ERR_FILE_CANT_READ
		return null

	func set_item(_key: String, _value: String) -> bool:
		last_error = ERR_FILE_CANT_WRITE
		return false

	func remove_item(_key: String) -> bool:
		last_error = ERR_FILE_CANT_WRITE
		return false


func _initialize() -> void:
	call_deferred("_run")


func _menu_with(storage: RefCounted) -> Control:
	var menu: Control = load(MENU).instantiate()
	menu.store = Store.new(storage)
	root.add_child(menu)
	return menu


func _isolated_prefs(menu: Control, locale: String) -> void:
	menu.prefs = Preferences.new(PREFS_PATH)
	assert(menu.prefs.set_locale(locale) == OK)
	menu._refresh()


func _run() -> void:
	root.size = Vector2i(390, 844)
	var absolute_prefs := ProjectSettings.globalize_path(PREFS_PATH)
	DirAccess.remove_absolute(absolute_prefs)

	# 1) Fresh save: donor keeps the status line hidden and only dims Continue.
	var fresh_storage := MemoryStorage.new()
	var fresh_menu := _menu_with(fresh_storage)
	await process_frame
	_isolated_prefs(fresh_menu, "ru")
	assert(fresh_menu.save_status != null and is_instance_valid(fresh_menu.save_status), "Menu must expose a SaveStatus line")
	assert(fresh_menu.find_child("SaveStatus", true, false) == fresh_menu.save_status, "SaveStatus must be reachable by donor node name")
	assert(not fresh_menu.save_status.visible and fresh_menu.save_status.text == "", "A fresh save must not show an error line")
	assert(fresh_menu.continue_button.disabled, "Continue must be locked without a save")
	assert(is_equal_approx(fresh_menu.continue_button.modulate.a, DISABLED_ALPHA), "Disabled Continue must use the donor alpha, not full opacity")
	assert(fresh_menu.continue_button.get_theme_stylebox("disabled") == fresh_menu.continue_button.get_theme_stylebox("normal"), "Disabled action must keep its normal surface")
	assert(not fresh_menu._has_progress() and not fresh_menu._save_is_unknown(), "Fresh save is neither progress nor unknown")
	assert(fresh_storage.values.is_empty(), "Reading a fresh save must not write anything")

	# 2) Settings must return focus to its own action, like the donor menu.
	fresh_menu.find_child("Settings", true, false).pressed.emit()
	await process_frame
	assert(fresh_menu.settings_panel != null, "Settings did not open")
	fresh_menu._close_settings()
	await process_frame
	assert(fresh_menu.column.visible, "Main actions must be visible again")
	assert(root.gui_get_focus_owner() == fresh_menu.find_child("Settings", true, false), "Closing Settings must restore focus to the Settings action")

	# 3) Corrupt save: recovery line, Continue locked, no silent overwrite.
	var corrupt_storage := MemoryStorage.new()
	corrupt_storage.values[CONTRACT.data.ravenKey] = "{this-is-not-json"
	var corrupt_menu := _menu_with(corrupt_storage)
	await process_frame
	_isolated_prefs(corrupt_menu, "ru")
	assert(corrupt_menu.save_report.status == "recovered-corrupt", "Corrupt save must be reported, not swallowed")
	assert(corrupt_menu.save_status.visible and corrupt_menu.save_status.text == RU_RECOVERED, "RU recovery copy missing")
	assert(corrupt_menu.continue_button.disabled, "Corrupt save must not enable Continue")
	assert(corrupt_storage.values.has(CONTRACT.data.ravenRecoveryKey), "Recovery copy must be kept by the store")
	assert(corrupt_menu.store.get_recovery_backup() != null, "Recovery copy must stay readable")
	assert(corrupt_menu.store.load_campaign().revision == 0, "Corrupt save must still resolve to a fresh snapshot")
	corrupt_menu._new_game()
	await process_frame
	assert(corrupt_menu.confirm.visible, "New Game over an unreadable save must ask for confirmation")
	assert(not corrupt_menu._start_after_guide, "New Game must not start before confirmation")

	# 4) Locale switch re-renders the same status text, without touching the save.
	corrupt_menu.prefs.set_locale("en")
	corrupt_menu._refresh()
	assert(corrupt_menu.save_status.text == EN_RECOVERED, "Save status must follow the selected locale")
	assert(corrupt_menu.confirm.dialog_text == "Starting a new game will erase your progress. Continue?", "Confirmation copy must follow the locale")
	corrupt_menu.prefs.set_locale("be")
	corrupt_menu._refresh()
	assert(corrupt_menu.save_status.text == "Захаванне пашкоджанае. Пры магчымасці захаваная рэзервовая копія.", "BE recovery copy missing")

	# Only one menu (and one modal) may be alive at a time in a window.
	corrupt_menu.queue_free()
	await process_frame

	# 5) Unreadable storage: read-failure line, Continue locked, explicit confirm.
	var failing_menu := _menu_with(ReadFailStorage.new())
	await process_frame
	_isolated_prefs(failing_menu, "ru")
	assert(failing_menu.save_report.detail == "storage-read-failed", "Read failure must be surfaced")
	assert(failing_menu.save_status.visible and failing_menu.save_status.text == RU_READ_FAILED, "RU read-failure copy missing")
	assert(failing_menu.continue_button.disabled, "Read failure must not enable Continue")
	failing_menu._new_game()
	await process_frame
	assert(failing_menu.confirm.visible, "Unreadable save must still be confirmed before reset")
	assert(not failing_menu._start_after_guide)
	failing_menu.confirm.hide()
	# A failed reset must be reported in the selected language, never in raw English.
	failing_menu.confirm.confirmed.emit()
	await process_frame
	assert(failing_menu.message.text == RU_RESET_FAILED, "Failed reset must use localized copy")
	assert(not failing_menu._start_after_guide, "Failed reset must not start the game")
	failing_menu.prefs.set_locale("be")
	failing_menu._refresh()
	assert(failing_menu.save_status.text == BE_READ_FAILED, "BE read-failure copy missing")
	assert(failing_menu._tr(23) == "Не ўдалося скінуць прагрэс гульні", "Reset error must be localized in BE")

	# 6) A readable catalog-backed save still lights Continue (no regression).
	var saved_storage := MemoryStorage.new()
	var seeded_store := Store.new(saved_storage)
	var seeded := seeded_store.load_campaign()
	seeded.revision = 3
	assert(seeded_store.save_campaign(seeded), "Seeded save must be written through the canonical store")
	var saved_menu := _menu_with(saved_storage)
	await process_frame
	_isolated_prefs(saved_menu, "ru")
	assert(saved_menu.save_report.status == "loaded", "A valid save must be reported as loaded")
	assert(not saved_menu.save_status.visible, "A valid save must not show an error line")
	assert(not saved_menu.continue_button.disabled, "Continue must unlock for a valid save")
	assert(is_equal_approx(saved_menu.continue_button.modulate.a, 1.0), "Enabled Continue must not be dimmed")
	assert(saved_storage.values.size() == 1, "Rendering the menu must not write extra save keys")

	for menu: Control in [fresh_menu, failing_menu, saved_menu]:
		menu.queue_free()
	await process_frame
	DirAccess.remove_absolute(absolute_prefs)
	print("Raven main menu UPDS failure-mode parity smoke passed")
	quit()
