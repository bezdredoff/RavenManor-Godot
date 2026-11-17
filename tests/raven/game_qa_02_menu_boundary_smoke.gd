extends SceneTree
## GAME-QA-02: exercise the ACTUAL menu callbacks, not a QA preview shortcut.
## This is a negative activation boundary until Agent B integrates production G2.
## Expected PASS here means only that we can honestly identify the still-legacy
## New Game/Continue destinations; it NEVER certifies a player-facing G2 loop.
const MENU_PATH := "res://scenes/raven/main_menu.tscn"
const LEGACY_SLICE := "res://scenes/raven/vertical_slice.tscn"
const Memory = preload("res://tests/support/memory_storage.gd")
const Store = preload("res://scripts/raven/raven_campaign_store.gd")
const Snapshot = preload("res://scripts/raven/raven_snapshot.gd")


func _initialize() -> void:
	call_deferred("_run")


func _menu_with(storage: RefCounted) -> Control:
	var menu: Control = load(MENU_PATH).instantiate()
	menu.store = Store.new(storage)
	root.add_child(menu)
	return menu


func _run() -> void:
	root.size = Vector2i(390, 844)
	assert(ProjectSettings.get_setting("application/run/main_scene") == MENU_PATH,
		"Normal game startup must use the real menu, not a QA preview")

	# Continue from a real, persisted Raven snapshot via the real Continue button.
	var saved := Memory.new()
	var state: Dictionary = Snapshot.fresh()
	state.revision = 3
	assert(Store.new(saved).save_campaign(state))
	var menu := _menu_with(saved)
	await process_frame
	assert(not menu.continue_button.disabled)
	menu.continue_button.pressed.emit()
	await process_frame
	await process_frame
	assert(current_scene != null, "Continue failed to load a scene")
	assert(current_scene.scene_file_path == LEGACY_SLICE,
		"GAME-QA-02 G2 BLOCKED: menu Continue route changed; update this test to assert the real production map and safe anchor")

	menu.queue_free()
	await process_frame

	# New Game must take the ordinary onboarding path before loading gameplay.
	var fresh := _menu_with(Memory.new())
	await process_frame
	assert(fresh.continue_button.disabled)
	var new_game: Button = fresh.find_child("NewGame", true, false)
	assert(new_game != null)
	new_game.pressed.emit()
	await process_frame
	assert(fresh._start_after_guide and fresh.onboarding_dialog.visible)
	var close_guide: Button = fresh.onboarding_dialog.find_child("RavenOnboardingClose", true, false)
	assert(close_guide != null)
	close_guide.pressed.emit()
	await process_frame
	await process_frame
	assert(current_scene != null, "New Game failed to load a scene")
	assert(current_scene.scene_file_path == LEGACY_SLICE,
		"GAME-QA-02 G2 BLOCKED: menu New Game route changed; update this test to assert the real production map, approved Evelyn and starting Hall")

	fresh.queue_free()
	await process_frame
	print("GAME-QA-02 normal menu legacy-route boundary smoke passed (production G2 activation BLOCKED)")
	quit()
