extends SceneTree
## Produce actual Godot-rendered review captures after driving existing authored routes.
## Screenshots prove rendering, NOT production approval or physical phone clearance.
const Geometry = preload("res://scripts/raven/map_prod_01_geometry.gd")
const Art = preload("res://scripts/raven/map_prod_01_hc_cb_art.gd")
const Review = preload("res://scenes/raven/tests/map_prod_01_hc_cb_review.tscn")

func _initialize() -> void:
	call_deferred("_run")

func _verify_original_art() -> void:
	root.size = Vector2i(1672, 941)
	root.content_scale_size = root.size
	var base := Sprite2D.new()
	base.texture = Art.ORIGINAL
	base.centered = false
	root.add_child(base)
	await process_frame
	await RenderingServer.frame_post_draw
	var before := root.get_texture().get_image()
	var back := Art.new()
	back.z_index = 2
	root.add_child(back)
	var front := Art.new()
	front.foreground = true
	front.z_index = 12
	root.add_child(front)
	await process_frame
	await RenderingServer.frame_post_draw
	var after := root.get_texture().get_image()
	var changed := 0
	var outside := 0
	var door := 0
	for y in range(941):
		for x in range(1672):
			if before.get_pixel(x,y) != after.get_pixel(x,y):
				changed += 1
				if not Art.HC_WALL.has_point(Vector2(x,y)):
					outside += 1
				if Rect2(516,280,24,132).has_point(Vector2(x,y)):
					door += 1
	assert(changed > 0)
	assert(outside == 0, "No added floor tiles or changes outside the HC wall join: " + str(outside))
	assert(door == 0, "Original CB golden door preserved pixel-for-pixel")
	assert(after.save_png("res://build/map-prod-01/composite-v4-full.png") == OK)
	print("V4 rendered pixel comparison PASS: ", changed, " changed pixels, all inside HC wall; CB golden door and all floors identical to original render")
	base.free()
	back.free()
	front.free()
	await process_frame

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/map-prod-01"))
	await _verify_original_art()
	root.size = Vector2i(960, 720)
	root.content_scale_size = Vector2i(960, 720)
	if not Geometry.verify().get("ok", false):
		push_error("MAP-PROD-01 capture: geometry verification failed")
		quit(2)
		return
	var scene: Variant = Review.instantiate()
	root.add_child(scene)
	await process_frame
	for child in scene.get_children():
		if child is CanvasLayer:
			child.visible = false
	var output := ProjectSettings.globalize_path("res://build/map-prod-01")
	if DirAccess.make_dir_recursive_absolute(output) != OK:
		push_error("MAP-PROD-01 capture: cannot create output directory")
		quit(2)
		return
	var cases := [
		{"room":"RM-ROOM-HALL","gate":"RM-DOOR-HALL-CORRIDOR",
		 "request":"QA-09B-HC-AB","name":"HC-godot-evelyn.png","feet":Vector2(824,400)},
		{"room":"RM-ROOM-CORRIDOR","gate":"RM-DOOR-CORRIDOR-BEDROOM",
		 "request":"QA-09B-CB-AB","name":"CB-godot-evelyn.png","feet":Vector2(528,376)}
	]
	for shot in cases:
		if not scene.load_room(str(shot.room)) or not scene.set_gate(str(shot.gate), "open"):
			push_error("MAP-PROD-01 capture: unable to initialize " + str(shot.name))
			quit(2)
			return
		if not scene.request_transition(str(shot.request)).get("ok", false):
			push_error("MAP-PROD-01 capture: route refused")
			quit(2)
			return
		for tick in range(5000):
			if not scene.host.actor.has_active_segment():
				break
			scene.host.actor.advance(0.025)
		if scene.host.actor.has_active_segment() or scene.host.actor.position.distance_to(shot.feet) > 0.01:
			push_error("MAP-PROD-01 capture: feet did not reach the actual sill")
			quit(2)
			return
		scene.host.camera.position_smoothing_enabled = false
		scene.host.camera.zoom = Vector2.ONE * 2.0
		scene.host.camera.position = shot.feet
		scene.host.camera.force_update_scroll()
		for i in range(6):
			await process_frame
		await RenderingServer.frame_post_draw
		var img: Image = root.get_texture().get_image()
		if img.is_empty():
			push_error("MAP-PROD-01 capture: empty rendered viewport")
			quit(2)
			return
		var path: String = output.path_join(str(shot.name))
		if img.save_png(path) != OK:
			push_error("MAP-PROD-01 capture: failed PNG write: " + path)
			quit(2)
			return
		print("MAP-PROD-01 actual Godot capture: " + path)
	scene.queue_free()
	quit(0)
