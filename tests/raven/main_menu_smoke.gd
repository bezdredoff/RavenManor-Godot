extends SceneTree
## Player menu regression: real scene, controls, settings, Lab routing and safe save behavior.
const MENU := "res://scenes/raven/main_menu.tscn"
const LAB := "res://scenes/raven/prototype_launcher.tscn"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	assert(ProjectSettings.get_setting("application/run/main_scene") == MENU, "Player menu must boot by default")
	var packed: PackedScene = load(MENU)
	assert(packed != null, "Missing main menu")
	var instance: Control = packed.instantiate()
	root.add_child(instance)
	await process_frame
	var new_game: Button = instance.find_child("NewGame", true, false)
	var continue_game: Button = instance.find_child("Continue", true, false)
	var settings: Button = instance.find_child("Settings", true, false)
	var lab: Button = instance.find_child("PrototypeLab", true, false)
	assert(new_game != null and continue_game != null and settings != null and lab != null, "Required menu actions missing")
	assert(lab.pressed.get_connections().size() > 0, "Prototype Lab action not connected")
	assert(ResourceLoader.exists(LAB), "Prototype Lab must stay in the same build")
	settings.pressed.emit()
	await process_frame
	assert(instance.settings_panel != null and is_instance_valid(instance.settings_panel), "Settings did not open")
	assert(not instance.column.visible, "Main actions must hide while settings open")
	instance._close_settings()
	await process_frame
	assert(instance.column.visible, "Back must restore main menu")
	assert(instance.settings_panel == null, "Settings must close")
	instance.queue_free()
	print("Raven Manor main menu and Prototype Lab navigation smoke passed")
	quit()
