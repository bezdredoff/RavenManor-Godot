extends SceneTree
## Player menu regression: real scene, controls, settings, Lab routing and safe save behavior.
const MENU := "res://scenes/raven/main_menu.tscn"
const LAB := "res://scenes/raven/prototype_launcher.tscn"
const Preferences = preload("res://scripts/raven/raven_production_localization.gd")
const Store = preload("res://scripts/raven/raven_campaign_store.gd")
const MemoryStorage = preload("res://tests/support/memory_storage.gd")
const SETTINGS_PATH := "user://raven_main_menu_settings_smoke.cfg"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	assert(ProjectSettings.get_setting("application/run/main_scene") == MENU, "Player menu must boot by default")
	var packed: PackedScene = load(MENU)
	assert(packed != null, "Missing main menu")
	var instance: Control = packed.instantiate()
	instance.store = Store.new(MemoryStorage.new())
	root.add_child(instance)
	await process_frame
	assert(instance.audio_runtime == root.get_node("/root/RavenAudio"), "Menu must use the persistent audio autoload")
	assert(instance.prefs == instance.audio_runtime.preferences, "Menus and audio must share one preference instance")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SETTINGS_PATH))
	instance.prefs = Preferences.new(SETTINGS_PATH)
	instance._refresh()
	var new_game: Button = instance.find_child("NewGame", true, false)
	var continue_game: Button = instance.find_child("Continue", true, false)
	var settings: Button = instance.find_child("Settings", true, false)
	var match3_levels: Button = instance.find_child("Match3Levels", true, false)
	var lab: Button = instance.find_child("PrototypeLab", true, false)
	var how_to_play: Button = instance.find_child("HowToPlay", true, false)
	assert(new_game != null and continue_game != null and match3_levels != null and settings != null and lab != null and how_to_play != null, "Required menu actions missing")
	assert(match3_levels.text == "Уровни Match-3", "Match-3 campaign entry must be visible and localized")
	assert(match3_levels.pressed.get_connections().size() > 0, "Match-3 campaign action not connected")
	assert(lab.pressed.get_connections().size() > 0, "Prototype Lab action not connected")
	assert(ResourceLoader.exists(LAB), "Prototype Lab must stay in the same build")
	settings.pressed.emit()
	await process_frame
	assert(instance.settings_panel != null and is_instance_valid(instance.settings_panel), "Settings did not open")
	assert(not instance.column.visible, "Main actions must hide while settings open")
	var reduced_motion: CheckButton = instance.find_child("ReducedMotion", true, false)
	assert(reduced_motion != null, "Main-menu settings must expose persistent reduced motion")
	reduced_motion.set_pressed_no_signal(true)
	reduced_motion.toggled.emit(true)
	assert(Preferences.new(SETTINGS_PATH).accessibility.reducedMotion, "Main-menu accessibility setting must persist")
	instance._close_settings()
	await process_frame
	assert(instance.column.visible, "Back must restore main menu")
	assert(instance.settings_panel == null, "Settings must close")
	how_to_play.pressed.emit()
	await process_frame
	assert(instance.onboarding_dialog.visible, "Replayable guide did not open from the main menu")
	assert(instance.onboarding_dialog.find_child("RavenOnboardingTopic0", true, false) != null)
	instance.onboarding_dialog.find_child("RavenOnboardingClose", true, false).pressed.emit()
	assert(not instance.onboarding_dialog.visible)
	new_game.pressed.emit()
	await process_frame
	assert(instance.onboarding_dialog.visible and instance._start_after_guide, "Fresh game must show onboarding before play")
	instance.onboarding_dialog.find_child("RavenOnboardingClose", true, false).pressed.emit()
	assert(not instance._start_after_guide, "Closing first-session guide should continue into the game")
	assert(instance.audio_runtime._scene == "vn")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SETTINGS_PATH))
	print("Raven Manor main menu and Prototype Lab navigation smoke passed")
	quit()
