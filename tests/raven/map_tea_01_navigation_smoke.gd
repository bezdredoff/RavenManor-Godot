extends SceneTree
## MAP-TEA-01 isolated authored-route, collision and actual Evelyn travel smoke.
const Candidate = preload("res://scripts/raven/map_tea_01_candidate.gd")
const Source = preload("res://scripts/raven/manor_navigation_source.gd")
const Graph = preload("res://scripts/raven/manor_navigation_graph.gd")
const Session = preload("res://scripts/raven/manor_route_session.gd")
const Review = preload("res://scenes/raven/tests/map_tea_01_hall_review.tscn")
const HALL := "RM-ROOM-HALL"
const TEA := "RM-HS-TEA-TABLE"
const ARRIVAL := "RM-NAV-HALL-TEA"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var base_sha: String = FileAccess.get_sha256("res://data/raven/manor_production_candidate.v1.json")
	var art_sha: String = FileAccess.get_sha256("res://a_detailed_top_down_isometric_game_map_illustratio.png")
	var receipt_sha: String = FileAccess.get_sha256("res://data/raven/manor_production_acceptance.v1.json")
	var result: Dictionary = Candidate.inspect()
	assert(result.get("ok", false), str(result.get("error", "candidate invalid")))
	assert(result.baseAnchorCount == 119 and result.baseEdgeCount == 120)
	assert(result.candidateAnchorCount == 120 and result.candidateEdgeCount == 121)
	var candidate: Dictionary = result.plan
	assert(candidate.provenance.approval == "DRAFT_ONLY" and not candidate.provenance.productionReady)
	assert(not candidate.provenance.runtimeAuthority and not candidate.provenance.activationEnabled)
	assert(Source.validate_calibrated_plan(candidate).is_empty(), "The native production collision validator must accept the inactive delta")
	var rejected: Dictionary = Source.resolve({"schemaVersion": 1, "kind": Source.REQUEST_KIND,
		"mode": "production", "worldPlan": candidate})
	assert(not rejected.get("ok", false), "DRAFT_ONLY assembly must fail closed in production")
	var original: Dictionary = Source.resolve({"schemaVersion": 1, "kind": Source.REQUEST_KIND, "mode": "production"})
	assert(original.get("ok", false), "Current G2 production plan must remain active")
	assert(original.contract.rooms.size() == 3)
	var graph = Graph.new()
	graph.rebuild({}, candidate)
	assert(graph.interaction_anchor(TEA) == ARRIVAL)
	assert(graph.anchor(ARRIVAL).get("checkpointAllowed", true) == false)
	assert(graph.anchor(ARRIVAL).kind == "interaction")
	for start in ["RM-NAV-HALL-SPAWN", "RM-NAV-HALL-CORRIDOR-NEAR",
			"RM-NAV-HS-001", "RM-NAV-09B-03-STEP-026"]:
		_test_authored_route(graph, start)
	# Original G2 topology remains reachable when both approved doors are unlocked.
	var unlocked = Graph.new()
	unlocked.rebuild({"unlockedDoors": ["RM-DOOR-HALL-CORRIDOR", "RM-DOOR-CORRIDOR-BEDROOM"]}, candidate)
	for pair in [["RM-NAV-HALL-SPAWN", "RM-NAV-CORRIDOR-CENTER"],
			["RM-NAV-CORRIDOR-CENTER", "RM-NAV-BEDROOM-CENTER"],
			["RM-NAV-BEDROOM-CENTER", "RM-NAV-CORRIDOR-CENTER"],
			["RM-NAV-CORRIDOR-CENTER", "RM-NAV-HALL-SPAWN"]]:
		assert(not unlocked.route(str(pair[0]), str(pair[1])).is_empty(), "G2 bidirectional route regressed")
	var restoring = Session.new(graph)
	assert(restoring.restore({"lastRoomId": HALL, "lastSafeAnchorId": "RM-NAV-HALL-SPAWN"}) == "RM-NAV-HALL-SPAWN")
	assert(restoring.request_hotspot(TEA).get("ok", false), "Safe Hall reload must plan tea route")
	# A forged saved interaction/arrival anchor is not a valid persisted safe checkpoint.
	var forged = Session.new(graph)
	assert(forged.restore({"lastRoomId": HALL, "lastSafeAnchorId": ARRIVAL}) != ARRIVAL)
	var review = Review.instantiate()
	root.add_child(review)
	await process_frame
	assert(review.ready_for_review, "Review scene did not initialize")
	assert(review.actor.get_script().resource_path.ends_with("evelyn_actor.gd"), "Use the accepted Evelyn segment mover")
	review.actor.set_process(false)
	assert(review.walk_to_tea().get("ok", false))
	assert(review.actor.has_active_segment())
	review.actor.advance(0.025)
	var held: Vector2 = review.actor.position
	assert(review.pause_route(), "Pause must hold the current segment")
	review.actor.advance(0.25)
	assert(review.actor.position.distance_to(held) < 0.001, "Paused actor moved")
	assert(review.pause_route(), "Resume must use same segment")
	assert(review.cancel_route().get("ok", false))
	for tick in range(100):
		review.actor.advance(0.025)
		if not review.actor.has_active_segment():
			break
	assert(not review.actor.has_active_segment(), "Cancel must finish only the current segment")
	assert(not review.arrival_acknowledged, "Cancel must not acknowledge Hall Tea")
	assert(review.reset_to("RM-NAV-HALL-CORRIDOR-NEAR"))
	assert(review.walk_to_tea().get("ok", false))
	for tick in range(5000):
		var before: Vector2 = review.actor.position
		review.actor.advance(0.025)
		assert(before.distance_to(review.actor.position) <= 3.251, "Physical frame teleported")
		if review.arrival_acknowledged:
			break
	assert(review.arrival_acknowledged, "Real Evelyn did not arrive from HC return")
	assert(review.actor.position.distance_to(graph.position(ARRIVAL)) < 0.01)
	assert(not review.actor.has_active_segment())
	assert(FileAccess.get_sha256("res://data/raven/manor_production_candidate.v1.json") == base_sha)
	assert(FileAccess.get_sha256("res://a_detailed_top_down_isometric_game_map_illustratio.png") == art_sha)
	assert(FileAccess.get_sha256("res://data/raven/manor_production_acceptance.v1.json") == receipt_sha)
	review.queue_free()
	print("MAP-TEA-01 TEST_ONLY smoke PASS: pinned source, 120/121, Hall starts, HC/CB, safe reload, pause/cancel/resume, Evelyn physical arrival, no runtime promotion")
	quit(0)

func _test_authored_route(graph, start: String) -> void:
	var session = Session.new(graph)
	assert(session.start_at(start))
	assert(session.request_hotspot(TEA).get("ok", false))
	var reached := false
	for step in range(180):
		var leg: Dictionary = session.next_segment()
		if leg.get("arrived", false):
			reached = true
			break
		assert(not leg.is_empty(), "A* must return an authored leg")
		assert(graph.segment_available(str(leg.fromAnchorId), str(leg.toAnchorId)))
		assert(str(graph.anchor(str(leg.toAnchorId)).get("roomId", "")) == HALL)
		if str(leg.toAnchorId) == ARRIVAL:
			_assert_new_segment_clearance(leg, graph)
		var ack: Dictionary = session.finish_segment(str(leg.toAnchorId))
		assert(ack.get("ok", false), "Must acknowledge only real segment ends")
		if str(ack.get("status", "")) == "arrived":
			assert(ack.get("hotspotId") == TEA)
			reached = true
			break
	assert(reached and session.current_anchor() == ARRIVAL, "Hall Tea path unreachable from " + start)

func _assert_new_segment_clearance(leg: Dictionary, graph) -> void:
	assert(leg.fromAnchorId == "RM-NAV-HS-001")
	assert(graph.position(str(leg.fromAnchorId)) == Vector2(952, 792))
	assert(graph.position(str(leg.toAnchorId)) == Vector2(984, 784))
	# Native Source.validate_calibrated_plan checks EVERY route sample at 12px
	# clearance; independently spot-check the new branch's full continuous path.
	for i in range(65):
		var feet: Vector2 = leg.fromPosition.lerp(leg.toPosition, float(i) / 64.0) - Vector2(128, 128)
		assert(feet.y >= 656 and feet.y <= 664, "No stair/table interception")
		assert(feet.x >= 824 and feet.x <= 856)
		assert(feet.distance_to(Vector2(856, 623)) >= 33.0 - 0.01)
