extends SceneTree
## Actual callbacks and views; a test-only adapter isolates every campaign write.
const Fixture = preload("res://tests/support/g2_production_fixture.gd")
const Menu = preload("res://tests/support/g2_menu_fixture.gd")
const Memory = preload("res://tests/support/memory_storage.gd")
const Store = preload("res://scripts/raven/raven_campaign_store.gd")
const Source = preload("res://scripts/raven/manor_navigation_source.gd")
const Contract = preload("res://data/save_contract.json")

func _initialize() -> void:
	call_deferred("_run")

func _menu(storage: RefCounted, approved: bool = false):
	if approved:
		Fixture.install_canonical()
	var menu = Menu.new()
	menu.store = Store.new(storage)
	root.add_child(menu)
	return menu

func _run() -> void:
	root.size = Vector2i(390, 844)
	assert(ProjectSettings.get_setting("application/run/main_scene") == "res://scenes/raven/main_menu.tscn")
	var memory = Memory.new()
	# Negative gate: mutate only the in-memory JSON Resource, never the shipped receipt.
	var acceptance: Dictionary = Source.ACCEPTANCE.data
	var saved_receipt: Dictionary = acceptance.duplicate(true)
	acceptance["ownerApproved"] = false
	var menu = _menu(memory)
	await process_frame
	assert(menu.continue_button.disabled)
	menu.find_child("NewGame", true, false).pressed.emit()
	assert(menu._start_after_guide and menu.onboarding_dialog.visible)
	assert(menu.launched_scene == null)
	menu.onboarding_dialog.find_child("RavenOnboardingClose", true, false).pressed.emit()
	await process_frame
	var opening = menu.launched_scene
	assert(opening != null and opening.normal_game_flow)
	for beat in ["RM-BEAT-00-01", "RM-BEAT-00-02", "RM-BEAT-00-03", "RM-BEAT-01-01"]:
		assert(opening.vn_player.scene.beatId == beat, "Opening omitted: " + beat)
		for _line in range(100):
			if opening.state.storyBeatsSeen.has(beat):
				break
			opening._advance_vn()
		assert(opening.state.storyBeatsSeen.has(beat))
	assert(opening.step.id == "access" and opening.technical_shell.visible)
	assert(opening.state.storyFlags.is_empty() and opening.state.firstClearLevels.is_empty())
	assert(not Source.resolve({"schemaVersion": 1, "kind": Source.REQUEST_KIND, "mode": "production"}).ok)
	var buttons: Array = opening.body.find_children("*", "Button", true, false)
	assert(buttons.size() == 1 and buttons[0].text in ["Вернуться в меню", "Вярнуцца ў меню", "Return to menu"], "Geometry hold needs recovery without an action bypass")
	opening.queue_free()
	menu.queue_free()
	await process_frame
	menu = _menu(memory)
	menu.continue_button.pressed.emit()
	await process_frame
	assert(menu.launched_scene.step.id == "access" and menu.launched_scene.normal_game_flow)
	menu.launched_scene.queue_free()
	menu.queue_free()
	await process_frame
	# Positive control: the same callback routes to the real player view, actor,
	# background and foreground using an isolated validated production fixture.
	acceptance.clear()
	acceptance.merge(saved_receipt, true)
	assert(Source.resolve(Fixture.request()).ok, "Production receipt must be restored")
	menu = _menu(memory)
	menu.continue_button.pressed.emit()
	await process_frame
	assert(menu.launched_path == "res://scenes/raven/manor_player_map.tscn")
	var map = menu.launched_scene
	map.set_process(false)
	assert(map._ready_for_input and map.host.room_state().roomId == "RM-ROOM-HALL", map.status.text)
	assert(map.host.room_state().anchorId == "RM-NAV-HALL-SPAWN")
	assert(map.host.navigation.actor.get_script().resource_path.ends_with("evelyn_actor.gd"))
	assert(map.background.texture != null and map._door_art != null and map._door_foreground != null)
	assert(not Store.new(memory).load_campaign().has("worldPlan"))
	map.queue_free()
	menu.queue_free()
	await process_frame
	assert(Source.resolve(Fixture.request()).ok, "Shipped receipt must remain valid after menu checks")
	var corrupt = Memory.new()
	corrupt.values[Contract.data.ravenKey] = "{bad"
	menu = _menu(corrupt)
	menu._continue_game()
	assert(menu.launched_scene == null and corrupt.values[Contract.data.ravenKey] == "{bad")
	menu.queue_free()
	memory.fail_remove = true
	menu = _menu(memory)
	menu._reset_and_start()
	assert(menu.launched_scene == null and not menu._start_after_guide)
	menu.queue_free()
	await process_frame
	print("GAME-QA-02 menu blocked-receipt fail-closed, approved real map entry and recovery smoke passed")
	quit()
