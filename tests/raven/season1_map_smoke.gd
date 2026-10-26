extends SceneTree
## Geometry/topology smoke; scene remains non-production and physically reviewed separately.
const MAP = preload("res://data/raven/season1_world_map.json")
const SCENE = preload("res://scenes/raven/season1_map_greybox.tscn")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var data: Dictionary = MAP.data
	assert(data.provenance.productionReady == false)
	assert(data.rooms.size() == 8)
	assert(data.doors.size() == 11)
	assert(data.props.size() >= 15)
	var ids := {}
	for room in data.rooms:
		assert(not ids.has(str(room.id)))
		ids[str(room.id)] = true
		var shape: Array = room.rect
		assert(float(shape[2]) >= 150 and float(shape[3]) >= 150)
	for d in data.doors:
		var a: int = int(d.a); var b: int = int(d.b)
		assert(a >= 0 and a < data.rooms.size())
		assert(b < data.rooms.size())
		var door_pos := Vector2(float(d.point[0]), float(d.point[1]))
		for index in [a, b]:
			if index < 0: continue
			var bounds: Array = data.rooms[index].rect
			var r := Rect2(float(bounds[0]), float(bounds[1]), float(bounds[2]), float(bounds[3]))
			assert(r.grow(0.1).has_point(door_pos), "door must physically adjoin both room footprints")
	for prop in data.props:
		var a: Array = prop.rect
		var bounds := Rect2(float(a[0]), float(a[1]), float(a[2]), float(a[3]))
		var room: Array = data.rooms[int(prop.room)].rect
		var room_bounds := Rect2(float(room[0]), float(room[1]), float(room[2]), float(room[3]))
		assert(room_bounds.encloses(bounds), "furniture must remain within its room")
	var scene = SCENE.instantiate()
	root.add_child(scene)
	await process_frame
	var routes := [
		[Vector2(1500, 1830), 7, "conservatory"],
		[Vector2(1540, 690), 4, "bedroom"],
		[Vector2(245, 650), 2, "archive"],
		[Vector2(1610, 1450), 6, "kitchen"],
	]
	assert(scene.actor_sprite.sprite_frames.get_frame_count("down") == 4)
	assert(scene.actor_sprite.sprite_frames.get_frame_count("side") == 8)
	assert(scene.camera_elevation == 65)
	assert(absf(scene.zoom - 0.74) < 0.0001)
	assert(scene.center == Vector2(750, 510))
	assert(scene.actor_pos == Vector2(875, 635))
	assert(absf(scene.floor_depth_ratio - sin(deg_to_rad(65.0))) < 0.0001)
	assert(scene.HALL_SHELL.get_width() == 700)
	assert(scene.HALL_SHELL.get_height() == 690)
	assert(scene._pilot_texture("RM-ASSET-HALL-CLOCK") != null)
	assert(scene._pilot_texture("RM-ASSET-HALL-SEATS") == null, "AI seating uses two separate chair PNGs and a round-table PNG")
	assert(scene._pilot_texture("RM-ASSET-HALL-CONSOLE") != null)
	assert(scene._pilot_texture("RM-ASSET-HALL-GALLERY") != null)
	# Shared PWA/Godot manifest and actual two-pass sprite occlusion smoke.
	assert(scene.HALL_VISUALS.data.status == "PILOT_NOT_APPROVED")
	# Source is the committed, tested Builder import PackedScene. Door markers and
	# physical footprints must match the still-canonical world graph exactly.
	assert(scene.art_variant == 4)
	assert(scene.imported_hall.ready, str(scene.imported_hall.get("reason", "Unknown import rejection")))
	assert(scene.imported_hall.world_rect == Rect2(500, 150, 700, 690))
	assert(scene.imported_hall.door_count == 5)
	assert(scene.imported_hall.footprint_count == 6)
	assert(scene.imported_hall.items.size() == 7)
	assert(scene.imported_hall.pilot_count == 7)
	assert(scene.imported_hall.placeholder_count == 0)
	# Separate validation gate: no calibration changes to the canonical map.
	assert(scene.hall_calibration.ready, str(scene.hall_calibration.get("reason", "")))
	assert(scene.hall_calibration.doors.size() == 5)
	assert(scene.hall_calibration.stairs.size() == 2)
	assert(scene.hall_calibration.candidate_seats.size() == 3)
	assert(not scene.test_split_seating)
	assert(not scene.show_hall_calibration)
	assert(scene.calibration_button.disabled == false)
	assert(scene.seat_test_button.disabled == false)
	var original_seats := scene._hall_collision_bounds(
		scene.props.filter(func(p): return str(p.id) == "RM-ASSET-HALL-SEATS")[0])
	assert(original_seats.size() == 1)
	assert(original_seats[0] == Rect2(640, 560, 160, 125))
	var access_probe := Vector2(660, 590)
	assert(not scene._is_walkable(access_probe), "Original seat cluster must block test probe")
	scene._toggle_calibration()
	assert(scene.show_hall_calibration)
	assert(scene.calibration_button.text == "Калибр.: ВИД")
	scene._toggle_calibration()
	assert(not scene.show_hall_calibration)
	scene._toggle_seat_preview()
	assert(scene.test_split_seating)
	assert(scene.seat_test_button.text == "Кресла: 3 ТЕСТ")
	var preview_seats := scene._hall_collision_bounds(
		scene.props.filter(func(p): return str(p.id) == "RM-ASSET-HALL-SEATS")[0])
	assert(preview_seats.size() == 3)
	assert(scene._is_walkable(access_probe), "Separate tentative footprints should free empty space inside old cluster")
	assert(not scene._is_walkable(Vector2(665, 648)), "Chair test contact area remains impassable")
	# Actor/door routes and fixed saved gates must remain safe after re-build.
	assert(scene._path_between(scene.actor_pos, Vector2(1110, 525), 1).size() > 0)
	assert(scene._occludes_actor(670, 635))
	assert(not scene._occludes_actor(630, 635))
	assert(not scene._occludes_actor(635, 635))
	scene._toggle_seat_preview()
	assert(not scene.test_split_seating)
	assert(scene._hall_collision_bounds(scene.props.filter(
		func(p): return str(p.id) == "RM-ASSET-HALL-SEATS")[0]).size() == 1)
	assert(not scene._is_walkable(access_probe), "Toggling off must restore original gameplay geometry")

	var import_pass: Dictionary = scene._hall_draw_source_counts()
	assert(import_pass.imported_floor == 1)
	assert(import_pass.imported_upright == 6)
	assert(import_pass.legacy_upright == 0, "Imported mode must never double draw the old AI sprites")
	assert(import_pass.legacy_props_suppressed == 6, "Six original Hall prop shapes must not be rendered twice")
	assert(scene._imported_managed("RM-ASSET-HALL-SEATS"))
	assert(scene._imported_managed("RM-ASSET-HALL-CLOCK"))
	assert(scene._imported_managed("RM-ASSET-HALL-CONSOLE"))
	assert(scene._imported_managed("RM-ASSET-HALL-GALLERY"))
	for imported in scene.imported_hall.items:
		assert(imported.texture != null, "Pilot imported PNG must exist")
		var source_bound: Rect2 = imported.rect
		var local_rect: Rect2 = Rect2(source_bound.position - Vector2(500, 150), source_bound.size)
		assert(local_rect.position.x >= 0 and local_rect.position.y >= 0)
		assert(Rect2(Vector2.ZERO, Vector2(700, 690)).encloses(local_rect))
		assert(imported.mode in ["floor", "upright"])
	assert(scene.hall_visual_sprites.size() == 7)
	assert(scene.foreground_overlay.z_index > scene.actor_sprite.z_index)
	assert(scene._visual_managed("RM-ASSET-HALL-SEATS"))
	assert(scene._visual_managed("RM-ASSET-HALL-CLOCK"))
	assert(scene._visual_texture("armchair_clean.png") == scene.AI_CHAIR)
	assert(scene._visual_texture("grandfather_clock.png") == scene.AI_CLOCK)
	var chair_rect: Rect2 = scene._visual_rect(scene.hall_visual_sprites[2])
	assert(chair_rect.end.y > scene.actor_pos.y, "chair must cover actor standing behind its foot")
	var clock_rect: Rect2 = scene._visual_rect(scene.hall_visual_sprites[1])
	assert(clock_rect.end.y < scene.actor_pos.y, "clock must stay behind actor who stands in front")

	var before_cycle := Vector2(920, 610)
	for target_angle in [45, 55, 65]:
		scene._cycle_camera()
		assert(scene.camera_elevation == target_angle)
		assert(absf(scene.floor_depth_ratio - sin(deg_to_rad(float(target_angle)))) < 0.0001)
		var projected: Vector2 = scene._screen_from_world(before_cycle)
		assert(scene._from_screen(projected).distance_to(before_cycle) < 0.001, "hit target alignment must survive camera changes")
	# Mobile portrait hub: map occupies nearly the full phone, no clipped controls.
	for device in [Vector2(390, 844), Vector2(412, 915), Vector2(430, 932)]:
		scene.size = device
		scene._layout_hud()
		var safe: Rect2 = scene._safe_viewport_rect(device)
		assert(safe.size.y >= device.y * 0.74, "map usable height must dominate portrait display")
		assert(safe.position.y >= scene.TOP_UI_HEIGHT)
		assert(safe.end.y <= device.y - scene.BOTTOM_UI_HEIGHT + 1.0)
		for b in [scene.zoom_minus_button, scene.zoom_preset_button, scene.zoom_plus_button,
				scene.recenter_button, scene.debug_toggle_button, scene.action_button,
				scene.repair_button, scene.back_button]:
			assert(b.position.x >= 0.0)
			assert(b.position.y >= 0.0)
			assert(b.position.x + b.size.x <= device.x + 0.1, "button exceeds portrait width")
			assert(b.position.y + b.size.y <= device.y + 0.1, "button exceeds portrait height")
		var onscreen_clock: Vector2 = scene._screen_from_world(Vector2(605, 505))
		var onscreen_actor: Vector2 = scene._screen_from_world(scene.actor_pos)
		assert(safe.has_point(onscreen_clock), "clock must be visible in opening hub")
		assert(safe.has_point(onscreen_actor), "character must be visible in opening hub")
		assert(scene._from_screen(onscreen_actor).distance_to(scene.actor_pos) < 0.001)
	scene.size = Vector2(390, 844)
	scene._layout_hud()
	assert(not scene.debug_panel.visible, "technical controls collapsed by default")
	scene._toggle_debug()
	assert(scene.debug_panel.visible)
	scene._toggle_safe_viewport()
	assert(scene.show_safe_viewport)
	scene._toggle_safe_viewport()
	scene._toggle_debug()
	assert(not scene.debug_panel.visible)
	scene._cycle_zoom_preset()
	assert(absf(scene.zoom - 0.80) < 0.0001)
	scene._cycle_zoom_preset()
	assert(absf(scene.zoom - 0.68) < 0.0001)
	scene._cycle_zoom_preset()
	assert(absf(scene.zoom - 0.74) < 0.0001)
	assert(scene.zoom_preset_button.text == "0.74×")
	# The generated PNGs are tracked as original sources, not re-encoded exports.
	assert(scene.art_variant == 4)
	assert(scene.AI_HALL_TWIN.get_width() == 1254)
	assert(scene.AI_HALL_TWIN.get_height() == 1254)
	assert(scene.AI_HALL_CRIMSON.get_width() == 1254)
	assert(scene.AI_CLOCK.get_width() == 1024)
	assert(scene.AI_CLOCK.get_height() == 1536)
	assert(scene.AI_CHAIR.get_width() == 1254)
	assert(scene.AI_SIDE_TABLE.get_width() == 1254)
	assert(scene.AI_RUG.get_width() == 724)
	assert(scene.AI_RUG.get_height() == 2172)
	assert(scene.AI_CONSOLE.get_width() == 1448)
	assert(scene.AI_GALLERY.get_height() == 1536)
	assert(scene._pilot_texture("RM-ASSET-HALL-CLOCK") == scene.AI_CLOCK)
	scene._toggle_art() # AI1
	assert(scene.art_variant == 1)
	assert(scene.art_button.text == "Вид: AI1")
	assert(not scene._import_mode())
	scene._toggle_art() # AI2
	assert(scene.art_variant == 2)
	assert(scene.art_enabled)
	assert(scene.art_button.text == "Вид: AI2")
	scene._toggle_art() # Greybox
	assert(scene.art_variant == 3)
	assert(not scene.art_enabled)
	scene._toggle_art() # SVG
	assert(scene.art_variant == 0)
	assert(scene.art_enabled)
	assert(scene._pilot_texture("RM-ASSET-HALL-CLOCK") == scene.HALL_CLOCK)
	assert(scene._pilot_texture("RM-ASSET-HALL-SEATS") == scene.HALL_SEATS, "SVG comparison must keep its original seating cluster")
	scene._toggle_art() # Import
	assert(scene.art_variant == 4)
	assert(scene.art_enabled)
	assert(scene._import_mode())
	assert(scene.art_button.text == "Вид: Импорт")
	assert(scene._pilot_texture("RM-ASSET-HALL-CLOCK") == scene.AI_CLOCK)
	var screen_point: Vector2 = scene._screen_from_world(Vector2(920, 610))
	assert(scene._from_screen(screen_point).distance_to(Vector2(920, 610)) < 0.001, "projection must preserve hit targeting")
	for test in routes:
		var route: PackedVector2Array = scene._path_between(scene.actor_pos, test[0], test[1])
		assert(not route.is_empty(), "ungated route not found: " + test[2])
		for i in range(1, route.size()):
			var direction := route[i] - route[i - 1]
			assert(absf(direction.x) < 0.01 or absf(direction.y) < 0.01, "no diagonal path segment")
			assert(not scene.grid.is_point_solid(Vector2i(floori(route[i].x / scene.CELL), floori(route[i].y / scene.CELL))), "route cannot cross obstacles")
	scene.explore_all = false
	scene._rebuild_navigation()
	assert(scene._path_between(scene.actor_pos, Vector2(1500, 1830), 7).is_empty(), "conservatory should be blocked")
	assert(scene._path_between(scene.actor_pos, Vector2(1540, 690), 4).is_empty(), "bedroom should be blocked")
	print("Raven Manor continuous season1 map smoke passed (orthogonal collision-aware paths, sprite and projection).")
	quit()
