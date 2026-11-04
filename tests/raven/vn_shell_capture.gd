extends SceneTree
## Reproducible renderer capture. Run without --headless under native/Xvfb.
## Output is QA evidence under /tmp, never production artwork or player saves.
const View = preload("res://scripts/raven/raven_vn_game_view.gd")
const Copy = preload("res://scripts/raven/raven_production_localization.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.content_scale_size = Vector2i.ZERO
	for width in [320, 340, 360, 390, 430]:
		root.size = Vector2i(width, 844)
		var view := View.new()
		view.size = Vector2(width, 844)
		root.add_child(view)
		await process_frame
		for locale in ["ru", "be", "en"]:
			view.show_beat("RM-BEAT-01-01", Copy.speaker_name("RM-CHAR-LUCAS", locale), Copy.line_text("RM-BEAT-01-01-L001", locale), "1/10", Callable(), "RM-BEAT-01-01-L001", locale)
			await process_frame
			await RenderingServer.frame_post_draw
			assert(root.get_texture().get_image().save_png("/tmp/raven-vn-%d-%s.png" % [width, locale]) == OK)
		view.queue_free()
		await process_frame
	print("Raven VN native renderer captures saved to /tmp/raven-vn-*.png")
	quit()
