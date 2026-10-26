extends SceneTree
## Manual render-parity capture. Run with --path . --script res://tests/raven/hall_render_capture.gd
## and set RAVEN_HALL_CAPTURE_DIR to a directory outside the repository.
const SCENE = preload("res://scenes/raven/season1_map_greybox.tscn")

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var output_dir := OS.get_environment("RAVEN_HALL_CAPTURE_DIR")
	if output_dir.is_empty():
		printerr("RAVEN_HALL_CAPTURE_DIR is required")
		quit(2)
		return
	var node = SCENE.instantiate()
	root.add_child(node)
	for dims in [Vector2i(390, 844), Vector2i(412, 915), Vector2i(430, 932)]:
		root.content_scale_size = dims
		await process_frame
		node._layout_hud()
		node._update_actor_screen()
		node.queue_redraw()
		await process_frame
		await process_frame
		var target := output_dir.path_join("hall_%dx%d.png" % [dims.x, dims.y])
		var result := root.get_texture().get_image().save_png(target)
		assert(result == OK, "Cannot write render capture: " + target)
		print("Captured " + target)
	quit()
