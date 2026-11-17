extends SceneTree
## GFX-07-01: real reusable gameplay harness, not merely an F6 animation.
## Geometry and campaign authority stay outside this visual integration.
const Harness = preload("res://scripts/raven/manor_gameplay_integration_harness.gd")
const Mover = preload("res://scripts/raven/onoe_segment_mover.gd")
const EvelynActor = preload("res://assets/raven/chibi/evelyn/g1_candidate/repair_v1/evelyn_actor.gd")
const EvelynScene = preload("res://scenes/raven/actors/evelyn_walker.tscn")
const HistoricalMultiRoom = preload("res://scenes/raven/tests/first_floor_multi_room_host.tscn")
const Fixture = preload("res://scripts/raven/first_floor_multi_room_fixture.gd")
const Source = preload("res://scripts/raven/manor_navigation_source.gd")
const Snapshot = preload("res://scripts/raven/raven_snapshot.gd")
const Preview = preload("res://addons/room_builder_routes/route_preview_source.gd")
const QA_PATH := "res://assets/raven/map/qa/drafts/map_qa_08_visual_candidate.v1.json"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var snapshot: Dictionary = Snapshot.fresh()
	var frozen: String = JSON.stringify(snapshot)
	# Unapproved canonical production geometry must fail closed; no actor spawn.
	var unavailable: Dictionary = Source.resolve({
		"schemaVersion": 1, "kind": Source.REQUEST_KIND,
		"mode": "production", "snapshot": snapshot, "worldPlan": Source.WORLD_PLAN.data})
	assert(not unavailable.ok and not unavailable.movementEnabled)
	var blocked = Harness.new()
	root.add_child(blocked)
	await process_frame
	assert(not blocked.configure(unavailable, snapshot))
	assert(blocked.error_text == "navigation-source-unavailable")
	assert(blocked.actor == null and not blocked.movement_enabled())
	blocked.queue_free()
	await process_frame

	# This QA route is TEST_ONLY but uses the SAME real gameplay harness.
	var source: Dictionary = Source.resolve({
		"schemaVersion": 1, "kind": Source.REQUEST_KIND,
		"mode": "qa", "snapshot": snapshot, "allowQaCandidate": true,
		"qaSourceKind": Preview.PROJECT, "qaSourcePath": QA_PATH})
	assert(source.ok and source.draftOnly and source.approval == "TEST_ONLY")
	var host = Harness.new()
	root.add_child(host)
	await process_frame
	assert(host.configure(source, snapshot), host.error_text)
	assert(host.actor is Mover and host.actor.get_script() == EvelynActor)
	assert(host.actor.name == "Evelyn" and host.actor.visual().name == "EvelynVisual")
	assert(not host.actor.is_processing(), "Harness must own the only advance loop")
	assert(host.actor.position == host.controller.anchor_position(source.initialAnchorId))
	for clip in ["side", "up", "down"]:
		assert(host.actor.get_sprite().sprite_frames.get_frame_count(clip) == 4)
	assert(host.actor.visual()._meta.ownerApproved)
	assert(host.actor.get_sprite().material == null)
	assert(not host.request_screen_point(Vector2(300, 400)).ok)
	assert(not host.actor.start_segment({
		"fromAnchorId": "BAD", "toAnchorId": "BAD-END",
		"fromPosition": Vector2(INF, 0), "toPosition": Vector2(100, 0)}))
	var origin: Vector2 = host.actor.position
	assert(host.request_hotspot("QA-HS:QA-HALL-CENTRE").ok)
	assert(host.advance().status == "segment_started")
	assert(host.actor.has_active_segment())
	var initial_phase: float = host.actor.visual().phase()
	# QA graph routes can contain short intermediate grid anchors; keep this
	# physical segment in-flight when testing cancellation, not at its boundary.
	host.advance(0.005)
	assert(host.actor.position.distance_to(origin) > 0.01)
	assert(host.actor.visual().phase() != initial_phase)
	var mid_leg: Vector2 = host.actor.position
	assert(not host.actor.start_segment({
		"fromAnchorId": "RESTART", "toAnchorId": "BAD",
		"fromPosition": origin, "toPosition": origin + Vector2(10, 0)}))
	assert(host.actor.position == mid_leg, "Cannot restart or teleport mid-leg")
	assert(host.actor.pause_segment())
	var held_phase: float = host.actor.visual().phase()
	host.advance(10.0)
	assert(host.actor.position == mid_leg and host.actor.visual().phase() == held_phase)
	assert(host.actor.resume_segment())
	host.actor.visual().set_reduced_motion(true)
	host.advance(0.005)
	assert(host.actor.position != mid_leg and host.actor.get_sprite().frame == 1)
	host.actor.visual().set_reduced_motion(false)
	assert(host.actor.has_active_segment(), "Cancel test needs an in-flight leg")
	var canceled: Dictionary = host.cancel_request()
	assert(canceled.ok and canceled.get("finishCurrentSegment", false), "Cancel retains current physical leg")
	var after_cancel: Vector2 = host.actor.position
	assert(host.drive().ok)
	assert(not host.actor.has_active_segment())
	assert(host.controller.ready_transition().is_empty())
	assert(host.room_state().roomId == "RM-ROOM-HALL")
	# Completing a preauthorized leg after cancellation is not an actor snap.
	assert(host.actor.position.distance_to(after_cancel) > 0.01)
	assert(host.request_hotspot("QA-HS:QA-HALL-CENTRE").ok)
	var arrived: Dictionary = host.drive()
	assert(arrived.ok and arrived.status == "arrived")
	assert(host.actor.position.distance_to(host.controller.anchor_position("QA-HALL-CENTRE")) < 0.01)
	assert(JSON.stringify(snapshot) == frozen)
	host.queue_free()
	await process_frame

	# Reinstantiate after a canceled mid-leg route, without stale actor XY.
	var fresh = Harness.new()
	root.add_child(fresh)
	await process_frame
	assert(fresh.configure(source, snapshot))
	assert(fresh.actor.position == fresh.controller.anchor_position(source.initialAnchorId))
	assert(not fresh.actor.has_active_segment())
	fresh.queue_free()
	await process_frame

	# Stable scene is a real segment-mover subclass in all four directions.
	var walker = EvelynScene.instantiate()
	root.add_child(walker)
	await process_frame
	walker.set_process(false)
	walker.set_sprite_height(62.0)
	walker.move_speed = 55.0
	assert(walker.get_script() == EvelynActor)
	for step in [Vector2(40, 0), Vector2(-40, 0), Vector2(0, -40), Vector2(0, 40)]:
		var starting: Vector2 = walker.position
		var target: Vector2 = starting + step
		assert(walker.start_segment({"fromAnchorId": "A", "toAnchorId": "B",
			"fromPosition": starting, "toPosition": target}))
		var clip := "side" if step.x != 0.0 else ("up" if step.y < 0.0 else "down")
		assert(walker.get_sprite().animation == clip)
		assert(walker.get_sprite().flip_h == (step.x < 0.0))
		walker.advance(1.0)
		assert(not walker.has_active_segment() and walker.position == target)
		assert(walker.get_sprite().frame == 1)
	assert(walker.position == Vector2.ZERO)
	walker.queue_free()
	await process_frame

	# Retain the historic Onoe QA baseline; substitute approved Evelyn in a
	# distinct QA-only Hall ↔ Corridor ↔ Bedroom host for multi-room regression.
	var fixture: Dictionary = Fixture.build()
	assert(not fixture.is_empty())
	var multi = HistoricalMultiRoom.instantiate()
	# This is a TEST_ONLY local substitution on the already proven QA host.
	# Switch the script before _ready, preserving the historical $Onoe API
	# and the baseline scene on disk (no alternate movement controller).
	var qa_actor: Node2D = multi.get_node("Onoe")
	assert(qa_actor != null and qa_actor.get_script() != EvelynActor)
	qa_actor.set_script(EvelynActor)
	assert(qa_actor.get_script() == EvelynActor)
	root.add_child(multi)
	await process_frame
	assert(multi.actor == qa_actor and multi.actor.get_script() == EvelynActor)
	assert(multi.configure_host(fixture.contract, fixture.visuals,
		fixture.initialRoomId, fixture.initialAnchorId))
	multi.actor.set_process(false)
	assert(multi.actor.visual().name == "EvelynVisual")
	assert(multi.actor.position == multi.controller.anchor_position(fixture.initialAnchorId))
	assert(multi.request_transition("QA-F7-TR-LOCKED").error == "locked-door")
	assert(multi.request_transition("QA-F7-TR-HC").ok)
	assert(_drive_to_room(multi, "QA-F7-CORRIDOR"))
	assert(multi.actor.position == multi.controller.anchor_position("QA-F7-C-ENTRY-H"))
	assert(multi.request_transition("QA-F7-TR-CB").ok)
	assert(_drive_to_room(multi, "QA-F7-BEDROOM"))
	assert(multi.actor.position == multi.controller.anchor_position("QA-F7-B-ENTRY"))
	assert(multi.request_transition("QA-F7-TR-BC").ok)
	assert(_drive_to_room(multi, "QA-F7-CORRIDOR"))
	assert(multi.request_transition("QA-F7-TR-CH").ok)
	assert(_drive_to_room(multi, "RM-ROOM-HALL"))
	assert(multi.actor.position == multi.controller.anchor_position("QA-HALL-RETURN-SAFE"))
	assert(JSON.stringify(snapshot) == frozen)
	multi.queue_free()
	await process_frame
	print("GFX-07-01 Evelyn gameplay-host integration smoke passed")
	quit()

func _drive_to_room(host, room: String) -> bool:
	for _i in range(100):
		if host.active_room_id == room:
			return true
		if not host.actor.has_active_segment():
			return false
		host.actor.advance(2.0)
	return host.active_room_id == room
