extends SceneTree
## Headful Godot screenshots of actual accepted Hall painting + live Evelyn.
## Output is build-only review evidence. Capture is NOT device or owner approval.
const Candidate = preload("res://scripts/raven/map_tea_01_candidate.gd")
const Review = preload("res://scenes/raven/tests/map_tea_01_hall_review.tscn")
const OUTPUT := "res://build/map-tea-01"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if not Candidate.inspect().get("ok", false):
		push_error("MAP-TEA-01 screenshot: pinned QA geometry invalid")
		quit(2)
		return
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT)) != OK:
		push_error("MAP-TEA-01 screenshot output path unavailable")
		quit(2)
		return
	root.size = Vector2i(960, 720)
	root.content_scale_size = root.size
	var review = Review.instantiate()
	root.add_child(review)
	await process_frame
	if not review.ready_for_review:
		push_error("MAP-TEA-01 review scene unavailable")
		quit(2)
		return
	review.actor.set_process(false)
	review.camera.position_smoothing_enabled = false
	review.camera.position = Vector2(970, 782)
	review.camera.zoom = Vector2.ONE * 1.45
	review.camera.force_update_scroll()
	review.overlay_enabled = false
	review.queue_redraw()
	await _capture("01-before-approved-hall-960x720.png")
	if not review.walk_to_tea().get("ok", false):
		push_error("MAP-TEA-01 capture: table target refused")
		quit(2)
		return
	for i in range(5000):
		review.actor.advance(0.025)
		if review.arrival_acknowledged:
			break
	if not review.arrival_acknowledged or review.actor.position.distance_to(Vector2(984, 784)) > 0.01:
		push_error("MAP-TEA-01 capture: walker failed to arrive at approved graph branch")
		quit(2)
		return
	review.overlay_enabled = true
	review.queue_redraw()
	await _capture("02-after-route-nogo-960x720.png")
	review.overlay_enabled = false
	review.queue_redraw()
	await _capture("03-after-evelyn-clean-960x720.png")
	root.size = Vector2i(390, 844)
	root.content_scale_size = root.size
	review.camera.position = Vector2(966, 775)
	review.camera.zoom = Vector2.ONE * 1.08
	review.camera.force_update_scroll()
	review.ui_layer.visible = false
	review.overlay_enabled = true
	review.queue_redraw()
	await _capture("04-mobile-390x844-route-nogo.png")
	review.overlay_enabled = false
	review.queue_redraw()
	await _capture("05-mobile-390x844-clean.png")
	review.queue_free()
	print("MAP-TEA-01 Godot rendered five review captures; device QA and owner approval NOT_RUN")
	quit(0)

func _capture(filename: String) -> void:
	for i in range(5):
		await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	if image.is_empty() or image.get_width() != root.size.x or image.get_height() != root.size.y:
		push_error("MAP-TEA-01 render size mismatch: " + filename)
		assert(false)
	var path: String = ProjectSettings.globalize_path(OUTPUT.path_join(filename))
	assert(image.save_png(path) == OK, "Failed writing Godot capture: " + path)
	print("MAP-TEA-01 Godot screenshot: " + path)
