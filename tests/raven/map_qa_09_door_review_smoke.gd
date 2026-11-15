extends SceneTree
const Review = preload("res://scripts/raven/first_floor_door_review.gd")
const Preview = preload("res://addons/room_builder_routes/route_preview_source.gd")
const Scene = preload("res://scenes/raven/tests/first_floor_integrated_qa.tscn")
const ART := "res://a_detailed_top_down_isometric_game_map_illustratio.png"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var source_hash := FileAccess.get_sha256(ART)
	var routes_before := FileAccess.get_file_as_string(Review.CANDIDATE)
	var manifest_before := FileAccess.get_file_as_string(Review.MANIFEST)
	var loaded := Review.load_review()
	assert(loaded.get("ok", false), str(loaded.get("error", "")))
	var doc: Dictionary = loaded.document
	assert(doc.doors.size() == 11)
	assert(doc.ownerReview.mapQa08b == "OWNER_CONFIRMED")
	for door in doc.doors:
		assert(door.status == "UNRESOLVED" and not door.traversalEnabled)
		assert(Review.crossing_request(doc, str(door.id)).get("error") == "physical-threshold-unresolved")
	# Evidence cannot be promoted to movement authority by editing a JSON flag.
	var bad: Dictionary = doc.duplicate(true)
	bad.doors[0].physicalPortalApproved = true
	assert(not Review.validate(bad).get("ok", false))
	assert(not Review.crossing_request(bad, str(bad.doors[0].id)).get("ok", false))
	bad = doc.duplicate(true)
	bad.doors[0].nearSideFootpointPx = [833, 801]
	assert(not Review.validate(bad).get("ok", false))
	bad = doc.duplicate(true)
	bad.doors[1].roomSideStops[0].roomId = "RM-ROOM-BEDROOM"
	assert(not Review.validate(bad).get("ok", false))
	bad = doc.duplicate(true)
	bad.doors[0].reviewRectPx = [0, 0, 2000, 2000]
	assert(not Review.validate(bad).get("ok", false))
	bad = doc.duplicate(true)
	bad.doors[1].id = bad.doors[0].id
	assert(not Review.validate(bad).get("ok", false))
	bad = doc.duplicate(true)
	bad.routeDraftSha256 = "stale-draft"
	assert(not Review.validate(bad).get("ok", false))
	assert(Review.validate(JSON.parse_string(JSON.stringify(doc))).get("ok", false))
	var qa = Scene.instantiate()
	root.add_child(qa)
	await process_frame
	# Door inspector never silently changes the selected source.
	qa.open_door_review()
	var panel = qa._door_review_panel
	await process_frame
	assert(panel.visible and panel._image.size.y >= 220)
	assert(panel.document.doors.size() == 11)
	assert(not panel.preview_side(0))
	assert(qa._source_kind == Preview.PROJECT and qa._source_path != Review.CANDIDATE)
	assert(qa.load_source(Preview.PROJECT, Review.CANDIDATE))
	for i in doc.doors.size():
		panel.select_door(i)
		assert(panel._image.texture is AtlasTexture)
		assert(panel._details.text.contains("UNRESOLVED"))
		var door: Dictionary = doc.doors[i]
		for side in door.roomSideStops.size():
			assert(panel.preview_side(side))
			var stop: Dictionary = door.roomSideStops[side]
			assert(qa.host.active_room_id == stop.roomId)
			assert(qa._room_ids[qa._room_picker.selected] == stop.roomId)
			for tick in range(2000):
				if not qa.host.actor.has_active_segment():
					break
				qa.host.actor.advance(0.025)
			assert(not qa.host.actor.has_active_segment())
			assert(qa.host.controller.confirmed_anchor() == stop.waypointId)
			assert(qa.host.active_room_id == stop.roomId, "Room approach must never hand off across a real door")
			await process_frame
	# A second room reset cannot interrupt an in-flight segment.
	panel.select_door(1)
	assert(panel.preview_side(0))
	assert(qa.host.actor.has_active_segment())
	var feet: Vector2 = qa.host.actor.position
	assert(not panel.preview_side(1))
	assert(qa.host.actor.position == feet)
	assert(qa.host.active_room_id == "RM-ROOM-HALL")
	qa.queue_free()
	assert(FileAccess.get_sha256(ART) == source_hash)
	assert(FileAccess.get_file_as_string(Review.CANDIDATE) == routes_before)
	assert(FileAccess.get_file_as_string(Review.MANIFEST) == manifest_before)
	print("MAP-QA-09 physical door evidence and fail-closed room approaches passed")
	quit()
