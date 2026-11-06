extends SceneTree

const Preferences = preload("res://scripts/raven/raven_production_localization.gd")
const Settings = preload("res://scripts/raven/raven_settings_dialog.gd")
const AudioRuntime = preload("res://scripts/raven/raven_audio_runtime.gd")
const Slice = preload("res://scripts/raven/vertical_slice.gd")
const Store = preload("res://scripts/raven/raven_campaign_store.gd")
const MemoryStorage = preload("res://tests/support/memory_storage.gd")
const SETTINGS_PATH := "user://raven_runtime_settings_smoke.cfg"

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(390, 844)
	var absolute_path := ProjectSettings.globalize_path(SETTINGS_PATH)
	DirAccess.remove_absolute(absolute_path)
	var legacy := ConfigFile.new()
	legacy.set_value("interface", "locale", "en")
	legacy.set_value("audio", "musicVolume", 0.45)
	assert(legacy.save(SETTINGS_PATH) == OK)
	var preferences := Preferences.new(SETTINGS_PATH)
	assert(preferences.locale == "en")
	assert(is_equal_approx(float(preferences.audio.musicVolume), 0.45))
	assert(preferences.accessibility.reducedMotion == false, "Old settings file must default reduced motion safely")
	assert(preferences.update_accessibility({"reducedMotion": true}) == OK)
	assert(preferences.set_locale("be") == OK)
	assert(preferences.update_audio({"muted": true}) == OK)
	var restored := Preferences.new(SETTINGS_PATH)
	assert(restored.locale == "be" and restored.audio.muted)
	assert(restored.accessibility.reducedMotion, "Reduced motion did not survive settings reload")
	assert(restored.update_accessibility({"unknown": true}) == ERR_INVALID_PARAMETER)

	var dialog := Settings.new()
	var audio_runtime := AudioRuntime.new()
	audio_runtime.preferences = restored
	root.add_child(audio_runtime)
	dialog.setup(restored, audio_runtime)
	root.add_child(dialog)
	await process_frame
	for viewport_size in [Vector2i(320, 568), Vector2i(390, 844), Vector2i(430, 932)]:
		root.size = viewport_size
		dialog.popup_centered(Vector2i(280, 450))
		await process_frame
		assert(dialog.visible and dialog.language.get_item_metadata(dialog.language.selected) == "be")
		assert(dialog.size.x <= root.size.x and dialog.size.y <= root.size.y, "Settings dialog must fit %s" % viewport_size)
		dialog.hide()
		await process_frame
	dialog.popup_centered(Vector2i(280, 450))
	await process_frame
	dialog.reduced_motion.set_pressed_no_signal(false)
	dialog.reduced_motion.toggled.emit(false)
	assert(not restored.accessibility.reducedMotion)
	assert(Preferences.new(SETTINGS_PATH).accessibility.reducedMotion == false)
	dialog.hide()
	dialog.queue_free()
	audio_runtime.queue_free()
	await process_frame

	# Changing language in live VN settings must not advance or rewind campaign/VN.
	var slice := Slice.new()
	slice.store = Store.new(MemoryStorage.new())
	slice.preferences = Preferences.new(SETTINGS_PATH)
	root.add_child(slice)
	await process_frame
	await process_frame
	assert(slice.step.kind == "vn")
	var line_before: int = slice.vn_player.line_index
	var revision_before: int = slice.state.revision
	slice._open_settings()
	await process_frame
	assert(slice.vn_view._interaction_blocked, "Settings overlay must block VN input")
	slice.settings_dialog.language.select(2)
	slice.settings_dialog.language.item_selected.emit(2)
	assert(slice.preferences.locale == "en")
	assert(slice.vn_player.line_index == line_before, "Locale change must retain the current line")
	assert(slice.state.revision == revision_before, "Settings must not write campaign progress")
	slice.settings_dialog.reduced_motion.set_pressed_no_signal(true)
	slice.settings_dialog.reduced_motion.toggled.emit(true)
	assert(slice.vn_view._fx_reduced_motion, "Reduced motion must immediately reach VN FX")
	slice.settings_dialog.hide()
	await process_frame
	assert(not slice.vn_view._interaction_blocked, "Closing Settings must restore VN input")
	slice.step = {"kind": "match3", "level": "RM-LVL-001"}
	slice._render_match3()
	await process_frame
	await process_frame
	var board := slice.find_child("RavenMatch3Board", true, false)
	slice._open_settings()
	assert(board.input_locked, "Settings dialog must block the Match-3 board")
	# Match-3 now has its own UPDS-style full-screen frame, not the
	# diagnostic body. Rerender without manually detaching UI nodes.
	slice._render_match3() # Locale rerender rebuilds the board while the modal stays open.
	var rebuilt_board := slice.find_child("RavenMatch3Board", true, false)
	assert(rebuilt_board != null and rebuilt_board != board, "Match-3 must recreate its board in the full-screen frame")
	assert(rebuilt_board.get_parent() != null and slice.match3_frame.visible)
	assert(rebuilt_board.input_locked, "Rebuilt board must remain blocked by open Settings")
	slice.settings_dialog.hide()
	await process_frame
	await process_frame
	slice.queue_free()
	await process_frame
	DirAccess.remove_absolute(absolute_path)
	print("Raven runtime settings persistence, modal and locale smoke passed")
	quit()
