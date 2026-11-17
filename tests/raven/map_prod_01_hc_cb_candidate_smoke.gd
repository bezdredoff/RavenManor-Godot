extends SceneTree
## Independent MAP-PROD-01 review-candidate checks. Production mode stays OFF.
const Routes = preload("res://addons/room_builder_routes/route_document.gd")
const Geometry = preload("res://scripts/raven/map_prod_01_geometry.gd")
const Navigation = preload("res://scripts/raven/manor_navigation_source.gd")
const ReviewScene = preload("res://scenes/raven/tests/map_prod_01_hc_cb_review.tscn")
const RADIUS := 12.0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var original: String = FileAccess.get_sha256(Geometry.ART_PATH)
	var result: Dictionary = Geometry.verify()
	assert(result.get("ok", false), str(result.get("error", "candidate invalid")))
	var spec: Dictionary = result["spec"]
	var doc: Dictionary = result["document"]
	assert(spec["ownerDecision"] == "RM-DEC-030")
	assert(spec["doors"].size() == 2)
	assert(spec["productionReady"] == false and spec["activationEnabled"] == false)
	assert(spec["paintedPerspective"]["angleDeg"] == 65 and spec["paintedPerspective"]["applySecondProjection"] == false)
	for sample in [Vector2(824,400),Vector2(528,376),Vector2(824,760)]:
		assert(Geometry.candidate_world_to_image(Geometry.image_to_candidate_world(sample)).distance_to(sample) < 0.001)
	# A candidate cannot accidentally activate the authoritative production source.
	var prod: Dictionary = Navigation.resolve({"schemaVersion":1,"kind":"raven-navigation-source-request","mode":"production"})
	assert(prod.get("movementEnabled", false) == false)
	var review: Variant = ReviewScene.instantiate()
	root.add_child(review)
	await process_frame
	assert(review.host != null and review.host.ready_for_test)
	assert(review.host.actor.get_script().resource_path.ends_with("evelyn_actor.gd"))
	assert(review.host.get_node("HC_CB_FloorAndDoorArt").z_index == 2)
	assert(review.host.get_node("Onoe").z_index == 8)
	assert(review.host.get_node("HC_CB_TrueForeground").z_index == 12)
	assert(review.source["contract"]["transitions"].size() == 4)
	assert(review.source["contract"]["doors"].size() == 2)
	assert(review.request_transition("QA-09B-HA-AB").get("error") == "unapproved-transition")
	assert(review.request_transition("QA-09B-CK-AB").get("error") == "unapproved-transition")
	for door in spec["doors"]:
		var a: String = str(door["roomIds"][0])
		var b: String = str(door["roomIds"][1])
		var door_id: String = str(door["id"])
		var ab: String = str(door["forwardTransition"])
		var ba: String = str(door["reverseTransition"])
		assert(review.load_room(a))
		assert(review.request_transition(ab).get("error") == "locked-door")
		assert(review.set_gate(door_id, "open"))
		assert(review.request_transition(ab).get("ok", false))
		_drive(review.host, doc)
		assert(review.host.active_room_id == b)
		assert(review.host.actor.position == Routes._vector(door["thresholdPx"]))
		assert(review.set_gate(door_id, "gated"))
		assert(review.request_transition(ba).get("error") == "locked-door")
		assert(review.set_gate(door_id, "open"))
		assert(review.walk_to_waypoint(str(review.source["starts"][b])).get("ok", false))
		_drive(review.host, doc)
		assert(review.request_transition(ba).get("ok", false))
		_drive(review.host, doc)
		assert(review.host.active_room_id == a)
		assert(review.host.actor.position == Routes._vector(door["thresholdPx"]))
		assert(review.load_room(a))
		assert(review.set_gate(door_id, "open"))
		assert(review.request_transition(ab).get("ok", false))
		review.host.actor.advance(0.025)
		assert(review.set_gate(door_id, "gated"))
		_drive(review.host, doc)
		assert(review.host.active_room_id == a)
		assert(review.load_room(a))
		assert(review.set_gate(door_id, "open"))
		assert(review.request_transition(ab).get("ok", false))
		assert(review.host.cancel_request().get("ok", false))
		_drive(review.host, doc)
		assert(review.host.active_room_id == a)
	assert(FileAccess.get_sha256(Geometry.ART_PATH) == original)
	review.queue_free()
	print("MAP-PROD-01 candidate: Evelyn, 4 HC/CB directions, gates, relock, cancel, NO-GO and 65-degree art validation PASS")
	quit(0)

func _drive(host: Node, doc: Dictionary) -> void:
	for tick in range(5000):
		if not host.actor.has_active_segment():
			return
		var before: Vector2 = host.actor.position
		host.actor.advance(0.025)
		assert(before.distance_to(host.actor.position) <= 3.251, "No teleport")
		var feet: Vector2 = host.actor.position
		assert(Routes.restriction_at(feet, doc).kind == "allowed")
		for zone in doc["noGoPolygons"]:
			var points := Routes._polygon_points(zone)
			for i in range(points.size()):
				var nearest: Vector2 = Geometry2D.get_closest_point_to_segment(feet, points[i], points[(i+1)%points.size()])
				assert(feet.distance_to(nearest) >= RADIUS-0.01, "12px foot radius collides with "+str(zone["id"]))
	assert(false, "Did not finish authored route")
