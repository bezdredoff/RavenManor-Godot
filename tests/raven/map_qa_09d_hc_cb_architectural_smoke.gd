extends SceneTree
## CODE-05-02 / 09D: isolated read-only architectural metadata + real 09B draft travel.
## This is NOT a production importer, painted-mask validation or owner approval.
const Routes = preload("res://addons/room_builder_routes/route_document.gd")
const Adapter = preload("res://scripts/raven/first_floor_integrated_draft_adapter.gd")
const Blueprint = preload("res://scripts/raven/first_floor_opening_blueprint.gd")
const Preview = preload("res://addons/room_builder_routes/route_preview_source.gd")
const QA = preload("res://scenes/raven/tests/first_floor_integrated_qa.tscn")
const REVIEW := "res://assets/raven/map/qa/drafts/map_qa_09d_hc_cb_architectural_review.v1.json"
const G1 := "res://assets/raven/map/qa/drafts/map_qa_09c_g1_door_calibration.v1.json"
const BROKEN := "user://room_builder_routes/09d_missing_hc_route.json"
const RADIUS := 12.0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var original_art := FileAccess.get_sha256("res://a_detailed_top_down_isometric_game_map_illustratio.png")
	var before_blueprint := FileAccess.get_file_as_string(Blueprint.PATH)
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(REVIEW))
	var g1raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(G1))
	assert(raw is Dictionary and g1raw is Dictionary)
	var review: Dictionary = raw
	var g1: Dictionary = g1raw
	assert(review["approval"] == "DRAFT_ONLY" and not review["productionReady"])
	assert(not review["runtimeAuthority"] and not review["visualApproval"])
	assert(not review["promotionGate"]["agentBMayEnableProduction"])
	assert(review["source"]["sha256"] == original_art)
	assert(review["projection"]["paintedInSourceImage"] and review["projection"]["doNotApplySecondProjection"])
	assert(review["doors"].size() == 2)
	var doc_result := Routes.load_draft(Blueprint.PATH)
	assert(doc_result.get("ok", false), str(doc_result.get("error", "bad blueprint")))
	var doc: Dictionary = doc_result["document"]
	assert(doc["approval"] == "DRAFT_ONLY" and not doc["productionReady"])
	assert(doc["sharedDoorContacts"].size() == 4)
	var qa = QA.instantiate()
	root.add_child(qa)
	await process_frame
	assert(qa.load_source(Preview.PROJECT, Blueprint.PATH))
	for spec in review["doors"]:
		var door_id := str(spec["doorId"])
		var ref: Dictionary = {}
		for entry in g1["doors"]:
			if str(entry["doorId"]) == door_id:
				ref = entry
		assert(not ref.is_empty() and not spec["physicalOpeningApproved"])
		assert(spec["thresholdPx"] == ref["thresholdPx"])
		assert(spec["nearFootPx"] == ref["nearFootPx"])
		assert(spec["farFootPx"] == ref["farFootPx"])
		assert(spec["openingWidthPx"] == ref["openingWidthPx"])
		assert(spec["roomIds"] == ref["roomIds"])
		assert(spec["collision"]["footRadiusPx"] == RADIUS)
		assert(spec["foregroundMasks"].size() >= 2)
		for mask in spec["foregroundMasks"]:
			assert(int(mask["zIndex"]) > 10 and bool(mask["conditional"]))
		var contact: Dictionary = {}
		for item in doc["sharedDoorContacts"]:
			if str(item["doorId"]) == door_id:
				contact = item
		assert(not contact.is_empty() and not contact["physicalPortalApproved"])
		assert(contact["authority"] == "TEST_ONLY")
		assert(str(contact["id"]) == str(spec["testOnlyContactId"]))
		var pair: Array = contact["waypointIds"]
		var lookup: Dictionary = Routes._waypoint_lookup(doc)
		var contact_px: Vector2 = Routes._vector(lookup[pair[0]]["pointPx"])
		assert(contact_px == Routes._vector(lookup[pair[1]]["pointPx"]))
		assert(contact_px == Routes._vector(spec["thresholdPx"]))
		var a := str(spec["roomIds"][0])
		var b := str(spec["roomIds"][1])
		var ab := str(contact["id"]) + "-AB"
		var ba := str(contact["id"]) + "-BA"
		assert(qa.restart_island(a))
		assert(qa.transition(ab).get("error") == "locked-door")
		assert(qa.host.test_gate(door_id, "open"))
		assert(qa.transition(ab).get("ok", false))
		_drive(qa.host, doc)
		assert(qa.host.active_room_id == b and qa.host.actor.position == contact_px)
		assert(qa.walk_waypoint(qa._loaded["starts"][b]).get("ok", false))
		_drive(qa.host, doc)
		assert(qa.transition(ba).get("ok", false))
		_drive(qa.host, doc)
		assert(qa.host.active_room_id == a and qa.host.actor.position == contact_px)
		# After arriving at the near-side sill, a closed gate rejects another AB.
		assert(qa.host.test_gate(door_id, "gated"))
		assert(qa.transition(ab).get("error") == "locked-door")
		# Cancel an approach before the handoff; finish the current segment only.
		assert(qa.restart_island(a))
		assert(qa.host.test_gate(door_id, "open"))
		assert(qa.transition(ab).get("ok", false))
		var cancellation := qa.host.cancel_request()
		assert(cancellation.get("ok", false))
		_drive(qa.host, doc)
		assert(qa.host.active_room_id == a)
		assert(qa.host.test_gate(door_id, "gated"))
		await process_frame
	# Missing HC approach route must fail closed rather than create a new crossing.
	var missing: Dictionary = doc.duplicate(true)
	var removed := false
	for i in range(missing["routes"].size() - 1, -1, -1):
		if str(missing["routes"][i]["id"]) == "QA-ROUTE-09B-03":
			missing["routes"].remove_at(i)
			removed = true
	assert(removed)
	var persisted := Routes.save_draft(BROKEN, missing)
	assert(persisted.get("ok", false))
	var result := Adapter.load_source(Preview.USER, BROKEN)
	if result.get("ok", false):
		var isolated = QA.instantiate()
		root.add_child(isolated)
		await process_frame
		assert(isolated.load_source(Preview.USER, BROKEN))
		assert(isolated.restart_island("RM-ROOM-HALL"))
		assert(isolated.host.test_gate("RM-DOOR-HALL-CORRIDOR", "open"))
		var start_feet: Vector2 = isolated.host.actor.position
		assert(not isolated.transition("QA-09B-HC-AB").get("ok", false))
		assert(isolated.host.actor.position == start_feet)
		assert(isolated.host.active_room_id == "RM-ROOM-HALL")
		isolated.queue_free()
	qa.queue_free()
	assert(FileAccess.get_sha256("res://a_detailed_top_down_isometric_game_map_illustratio.png") == original_art)
	assert(FileAccess.get_file_as_string(Blueprint.PATH) == before_blueprint)
	print("CODE-05-02/09D architectural review, paired technical travel, gates and fail-closed routes passed")
	quit(0)

func _drive(host: Node, doc: Dictionary) -> void:
	for tick in range(5000):
		if not host.actor.has_active_segment():
			return
		var previous: Vector2 = host.actor.position
		host.actor.advance(0.025)
		assert(previous.distance_to(host.actor.position) <= 3.251, "Unexpected physical displacement")
		assert(Routes.restriction_at(host.actor.position, doc).kind == "allowed")
		for zone in doc["noGoPolygons"]:
			var poly := Routes._polygon_points(zone)
			for i in range(poly.size()):
				var nearest: Vector2 = Geometry2D.get_closest_point_to_segment(host.actor.position, poly[i], poly[(i + 1) % poly.size()])
				assert(host.actor.position.distance_to(nearest) >= 11.99, "12px foot proxy collides with " + str(zone["id"]))
	assert(false, "Draft movement failed to settle")
