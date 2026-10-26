extends RefCounted
## RM-PIPE-003: consume the actual Builder-generated PackedScene in the
## continuous Godot map. Only extracts render data, NEVER replaces navigation,
## collision footprints, room topology, campaign state, or actor positions.

const ROOM_ID := "RM-ROOM-HALL"
const CAMERA_ELEVATION := 65.0
const PROJECTION_RATIO := 0.9063077870366499

static func _rect_value(origin: Vector2, size: Vector2) -> Rect2:
	return Rect2(origin, size)

static func _near(a: Vector2, b: Vector2, tolerance: float = 0.12) -> bool:
	return a.distance_to(b) <= tolerance

static func load_render_data(scene: PackedScene, world: Dictionary) -> Dictionary:
	var result := {"ready": false, "reason": "", "items": [], "background": null,
		"world_rect": Rect2(), "door_count": 0, "footprint_count": 0,
		"pilot_count": 0, "placeholder_count": 0, "wall_runs": [],
		"opening_count": 0}
	if scene == null:
		result.reason = "Imported Hall PackedScene is missing"
		return result
	var source: Node2D = scene.instantiate() as Node2D
	if source == null:
		result.reason = "Imported Hall scene root must be Node2D"
		return result
	var rooms: Array = world.get("rooms", [])
	var index := -1
	for i in range(rooms.size()):
		if str(rooms[i].get("id", "")) == ROOM_ID:
			index = i
			break
	if index < 0:
		source.free()
		result.reason = "World map Hall ID is missing"
		return result
	var raw_bounds: Array = rooms[index].rect
	var world_rect := Rect2(float(raw_bounds[0]), float(raw_bounds[1]), float(raw_bounds[2]), float(raw_bounds[3]))
	if source.get_meta("room_id", "") != ROOM_ID \
		or source.get_meta("import_kind", "") != "ROOM_BUILDER_GAME_VISUAL_ONLY" \
		or source.get_meta("geometry_approval", "") != "DRAFT_ONLY" \
		or int(source.get_meta("game_camera_degrees", -1)) != 65 \
		or not _near(source.get_meta("world_origin", Vector2(-1, -1)), world_rect.position) \
		or not _near(source.get_meta("source_size", Vector2(-1, -1)), world_rect.size):
		source.free()
		result.reason = "Imported Hall metadata disagree with current map"
		return result
	var background: TextureRect = source.get_node_or_null("HallPilotBackground") as TextureRect
	if background == null or background.texture == null:
		source.free()
		result.reason = "Imported Hall background is missing"
		return result
	var refs: Node = source.get_node_or_null("ReferenceGeometry")
	if refs == null:
		source.free()
		result.reason = "Imported Hall lacks reference physical geometry"
		return result
	# The reference masks MUST describe the actual map, not a second set of
	# physics entities. Reject stale imports rather than silently misaligning.
	var prop_lookup := {}
	for prop in world.get("props", []):
		if int(prop.room) != index:
			continue
		var a: Array = prop.rect
		prop_lookup[str(prop.id)] = Rect2(float(a[0]), float(a[1]), float(a[2]), float(a[3]))
	var verified := {}
	for child in refs.get_children():
		var prop_id := str(child.get_meta("source_prop_id", ""))
		if not prop_lookup.has(prop_id) or verified.has(prop_id):
			source.free()
			result.reason = "Unknown or duplicate imported physics outline: " + prop_id
			return result
		var outline := Rect2(child.get_meta("world_local_top_left", Vector2(-1, -1)) + world_rect.position,
			child.get_meta("world_local_size", Vector2.ZERO))
		if not _near(outline.position, prop_lookup[prop_id].position) or \
			not _near(outline.size, prop_lookup[prop_id].size):
			source.free()
			result.reason = "Geometry mismatch for " + prop_id
			return result
		verified[prop_id] = true
	if verified.size() != prop_lookup.size():
		source.free()
		result.reason = "Not all Hall physics references were imported"
		return result
	# Check the actual Door Marker2D coordinates against the fixed world map.
	var expected_doors := {}
	for door in world.get("doors", []):
		if int(door.a) != index and int(door.b) != index:
			continue
		expected_doors[str(door.id)] = Vector2(
			float(door.point[0]), float(door.point[1]))
	var doors_verified := {}
	for child in source.get_children():
		if not (child is Marker2D):
			continue
		var anchor_id := str(child.get_meta("nav_id", ""))
		if not expected_doors.has(anchor_id):
			continue
		if doors_verified.has(anchor_id):
			source.free()
			result.reason = "Duplicate door anchor: " + anchor_id
			return result
		var expected_local: Vector2 = expected_doors[anchor_id] - world_rect.position
		var projected := Vector2(expected_local.x, expected_local.y * PROJECTION_RATIO)
		if not _near(child.position, projected, 0.16):
			source.free()
			result.reason = "Imported door anchor disagrees with world: " + anchor_id
			return result
		doors_verified[anchor_id] = true
	if doors_verified.size() != expected_doors.size():
		source.free()
		result.reason = "Imported Hall is missing door anchors"
		return result
	# Builder wall geometry remains visual-only. Read it from the generated
	# scene so the live map and standalone review use one source of truth.
	var wall_runs: Array = []
	var openings_verified := {}
	var draft_walls: Node = source.get_node_or_null("DraftWalls")
	if draft_walls != null:
		for child in draft_walls.get_children():
			if child is Line2D:
				var line := child as Line2D
				if line.points.size() != 2 or str(line.get_meta("physics_authority", "")) != "NONE_DRAFT_ONLY":
					source.free()
					result.reason = "Invalid draft wall run"
					return result
				var first := Vector2(line.points[0].x, line.points[0].y / PROJECTION_RATIO) + world_rect.position
				var last := Vector2(line.points[1].x, line.points[1].y / PROJECTION_RATIO) + world_rect.position
				wall_runs.append({"a": first, "b": last, "width": line.width,
					"style": str(line.get_meta("wall_style", "")),
					"role": str(line.get_meta("wall_role", "wall"))})
			elif child is Marker2D and child.has_meta("builder_opening_id"):
				var door_id := str(child.get_meta("door_id", ""))
				if not expected_doors.has(door_id) or openings_verified.has(door_id):
					source.free()
					result.reason = "Unknown or duplicate draft opening: " + door_id
					return result
				var local := Vector2(child.position.x, child.position.y / PROJECTION_RATIO)
				if not _near(local + world_rect.position, expected_doors[door_id], 0.2):
					source.free()
					result.reason = "Draft opening disagrees with world: " + door_id
					return result
				openings_verified[door_id] = true
	if openings_verified.size() != expected_doors.size():
		source.free()
		result.reason = "Draft Hall must represent all five canonical openings"
		return result
	var items: Array = []
	var imported_ids := {}
	var pilot_count := 0
	var placeholder_count := 0
	for child in source.get_children():
		if not child.has_meta("builder_instance_id"):
			continue
		var instance_id := str(child.get_meta("builder_instance_id"))
		if instance_id.is_empty() or imported_ids.has(instance_id):
			source.free()
			result.reason = "Invalid or duplicate imported visual instance"
			return result
		imported_ids[instance_id] = true
		var mode := str(child.get_meta("visual_mode", ""))
		if mode not in ["floor", "upright"]:
			source.free()
			result.reason = "Unsupported imported sprite projection"
			return result
		var art: TextureRect = child.get_node_or_null("Art") as TextureRect
		var visual: Texture2D = art.texture if art != null else null
		var top_left: Vector2 = child.get_meta("world_local_top_left", Vector2.ZERO)
		var dims: Vector2 = child.get_meta("world_local_size", Vector2.ZERO)
		if dims.x <= 0 or dims.y <= 0:
			source.free()
			result.reason = "Invalid imported artwork footprint"
			return result
		var rect := _rect_value(world_rect.position + top_left, dims)
		var provenance := str(child.get_meta("art_provenance", "PLACEHOLDER"))
		if visual == null:
			placeholder_count += 1
		elif provenance == "PILOT":
			pilot_count += 1
		items.append({"id": instance_id, "asset_ref_id": str(child.get_meta("asset_ref_id", "")),
			"mode": mode, "rect": rect, "texture": visual, "provenance": provenance,
			"foot_y": rect.end.y, "visual_state": str(child.get_meta("visual_state", "default"))})
	# Stable sorting by ground-contact depth. The actor splits front/back at
	# run time, so no actual actor ever comes from the imported scene.
	items.sort_custom(func(a, b):
		if is_equal_approx(float(a.foot_y), float(b.foot_y)):
			return str(a.id) < str(b.id)
		return float(a.foot_y) < float(b.foot_y))
	result.ready = true
	result.world_rect = world_rect
	result.items = items
	result.background = background.texture
	result.pilot_count = pilot_count
	result.placeholder_count = placeholder_count
	result.door_count = doors_verified.size()
	result.footprint_count = verified.size()
	result.wall_runs = wall_runs
	result.opening_count = openings_verified.size()
	source.free()
	return result
