extends SceneTree
## Confirm that gameplay has a safe, player-facing exit rather than QA launcher.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: PackedScene = load("res://scenes/raven/vertical_slice.tscn")
	assert(scene != null, "Vertical slice missing")
	var game: Control = scene.instantiate()
	root.add_child(game)
	await process_frame
	assert(game.pause_dialog != null, "Missing pause confirmation")
	assert(game.pause_dialog.confirmed.get_connections().size() > 0, "Save-and-exit not connected")
	game._open_pause()
	assert(game.pause_dialog.visible, "Pause dialog did not open")
	game.pause_dialog.hide()
	assert(ResourceLoader.exists("res://scenes/raven/main_menu.tscn"), "Return target missing")
	game.queue_free()
	print("Raven Manor save-and-exit pause smoke passed")
	quit()
