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
	var scene := SCENE.instantiate()
	root.add_child(scene)
	await process_frame
	assert(scene.nav.get_id_path(1, 7).size() > 0, "hall must connect to conservatory in layout test mode")
	assert(scene.nav.get_id_path(2, 4).size() > 0, "archive must connect to bedroom in layout test mode")
	scene.explore_all = false
	scene._rebuild_navigation()
	assert(scene.nav.get_id_path(1, 7).is_empty(), "story gates must block non-unlocked conservatory")
	assert(scene.nav.get_id_path(1, 4).is_empty(), "bedroom is gated until access flag unlocks door")
	print("Raven Manor continuous season1 map smoke passed (geometry and gated connectivity).")
	quit()
