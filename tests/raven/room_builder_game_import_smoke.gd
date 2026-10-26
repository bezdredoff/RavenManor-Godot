extends SceneTree

## Isolated Room Builder → Godot scene smoke; does not open gameplay or write saves.
func _initialize() -> void:
	call_deferred("_check")

func _check() -> void:
	var path := "res://scenes/raven/generated/RM_ROOM_HALL_GamePreview.tscn"
	var packed: PackedScene = load(path) as PackedScene
	assert(packed != null, "Imported .tscn was not generated or cannot be parsed")
	var root: Node2D = packed.instantiate()
	assert(root.get_meta("geometry_approval", "") == "DRAFT_ONLY")
	assert(root.get_meta("room_id", "") == "RM-ROOM-HALL")
	assert(root.get_meta("ignore_test_characters", false))
	assert(root.has_node("ReviewCamera"))
	assert(root.has_node("HallPilotBackground"))
	assert(root.has_node("ReferenceGeometry"))
	assert(not root.get_node("ReferenceGeometry").visible)
	assert(root.get_node("ReferenceGeometry").get_child_count() == 6)
	assert(root.get_node("ReferenceGeometry").get_meta("status") == "MAP_GEOMETRY_GUIDES_ONLY")
	assert(root.get_node("ReviewCamera").zoom == Vector2(0.74, 0.74))
	var found_clock := false
	var pilot_count := 0
	for child in root.get_children():
		if not child is Node2D or not child.has_meta("asset_ref_id"): continue
		assert(child.has_meta("world_local_top_left"))
		assert(child.has_meta("visual_mode"))
		if child.get_meta("asset_ref_id") == "RM-ASSET-HALL-002": found_clock = true
		if child.get_meta("art_provenance") == "PILOT": pilot_count += 1
	assert(found_clock)
	assert(pilot_count == 7, "All seven authored pilot art objects must survive import")
	root.free()
	print("Room Builder 65-degree Godot visual import smoke passed")
	quit(0)
