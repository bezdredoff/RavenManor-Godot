extends SceneTree
## MAP-QA-06: executable two-room regression. In-memory TEST_ONLY state only.
const Controller = preload("res://scripts/raven/manor_room_transition_controller.gd")
const ActorScene = preload("res://scenes/raven/tests/onoe_segment_actor.tscn")
const DemoScene = preload("res://scenes/raven/tests/room_transition_synthetic.tscn")
const Snapshot = preload("res://scripts/raven/raven_snapshot.gd")
const FIXTURE := "res://data/raven/qa/room_transitions_synthetic.v1.json"

var controller = Controller.new()
var actor
var contract: Dictionary
var arrivals: Array[Dictionary] = []
var ready_count := 0
var complete_count := 0
var diagnostic_count := 0
var rejection_count := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	assert(DemoScene != null and DemoScene.instantiate() != null, "F6 demo must parse")
	var loaded: Variant = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))
	assert(loaded is Dictionary)
	contract = loaded
	actor = ActorScene.instantiate()
	root.add_child(actor)
	await process_frame
	actor.move_speed = 350.0
	actor.segment_completed.connect(_on_physical_arrival)
	controller.transition_ready.connect(func(_v): ready_count += 1)
	controller.transition_completed.connect(func(_v): complete_count += 1)
	controller.transition_diagnostic.connect(func(_id, _reason): diagnostic_count += 1)
	controller.transition_rejected.connect(func(_id, _reason): rejection_count += 1)
	var saved: Dictionary = Snapshot.fresh()
	var saved_before := JSON.stringify(saved)

	# Config validation: unknown room, invalid entry, fake pixels, broken reverse.
	var invalid := contract.duplicate(true)
	invalid["transitions"][0]["destinationEntryAnchorId"] = "QA-B-NOT-AUTHORED"
	var trial = Controller.new()
	assert(not trial.configure(invalid, "QA-ROOM-A", "QA-A-ENTRY"))
	assert(trial.error_text == "missing-destination-entry-anchor")
	invalid = contract.duplicate(true)
	invalid["rooms"][1]["graph"]["anchors"][0]["position"] = [INF, 0]
	assert(not trial.configure(invalid, "QA-ROOM-A", "QA-A-ENTRY"))
	assert(trial.error_text == "invalid-anchor-position")
	invalid = contract.duplicate(true)
	invalid["transitions"][1]["reverseTransitionId"] = ""
	assert(not trial.configure(invalid, "QA-ROOM-A", "QA-A-ENTRY"))
	assert(trial.error_text == "nonreciprocal-transition")
	assert(not trial.configure(contract, "QA-ROOM-C", "QA-A-ENTRY"))
	assert(trial.error_text == "invalid-initial-room")

	_reset()
	assert(controller.room_id() == "QA-ROOM-A" and controller.confirmed_anchor() == "QA-A-ENTRY")
	var origin: Vector2 = actor.position
	assert(not controller.request_transition("QA-TR-B-A", actor).ok)
	assert(not controller.request_transition("QA-MISSING", actor).ok)
	assert(not controller.request_transition("QA-TR-A-LOCKED", actor).ok)
	assert(controller.request_transition("QA-TR-A-LOCKED", actor).error == "locked-door")
	assert(controller.request_transition("QA-TR-A-FUTURE", actor).error == "future-door")
	assert(actor.position == origin and controller.confirmed_anchor() == "QA-A-ENTRY")
	assert(controller.pending_transition().is_empty() and controller.ready_transition().is_empty())
	assert(controller.commit_transition(actor).error == "no-confirmed-transition")

	# Physically moving actor cannot arrive merely because a target was clicked.
	assert(controller.request_transition("QA-TR-A-B", actor).ok)
	assert(controller.request_transition("QA-TR-A-B", actor).status == "unchanged")
	var leg := _start_leg()
	var mid_before: Vector2 = actor.position
	assert(controller.accept_segment_arrival(int(leg.segmentToken), str(leg.toAnchorId), leg.toPosition, actor).error == "premature-arrival")
	assert(controller.accept_segment_arrival(999999, str(leg.toAnchorId), leg.toPosition, actor).error == "stale-or-unexpected-arrival")
	assert(actor.position == mid_before and controller.room_id() == "QA-ROOM-A")
	actor.advance(0.07)
	assert(actor.position != leg.toPosition and actor.position != mid_before)
	var middle: Vector2 = actor.position
	assert(controller.request_transition("QA-TR-A-B", actor).status == "unchanged")
	assert(controller.next_segment(actor).is_empty(), "No duplicate in-flight leg")
	assert(actor.position == middle, "Repeated request must not snap feet")
	_finish_leg(leg)
	assert(controller.confirmed_anchor() == "QA-A-MID")
	assert(controller.ready_transition().is_empty())
	var last_leg := _start_leg()
	assert(last_leg.fromAnchorId == "QA-A-MID" and last_leg.toAnchorId == "QA-A-DOOR")
	_finish_leg(last_leg)
	assert(controller.confirmed_anchor() == "QA-A-DOOR")
	assert(controller.ready_transition() == "QA-TR-A-B" and ready_count == 1)
	assert(controller.room_id() == "QA-ROOM-A" and actor.position == last_leg.toPosition, "No implicit room switch")
	assert(controller.accept_segment_arrival(int(last_leg.segmentToken), str(last_leg.toAnchorId), actor.position, actor).error == "stale-or-unexpected-arrival")
	var forward: Dictionary = controller.commit_transition(actor)
	assert(forward.ok and forward.transitionId == "QA-TR-A-B")
	assert(forward.roomId == "QA-ROOM-B" and forward.entryAnchorId == "QA-B-ENTRY")
	assert(forward.reverseTransitionId == "QA-TR-B-A")
	assert(forward.checkpointProposal == {"type":"position_checkpoint", "roomId":"QA-ROOM-B", "anchorId":"QA-B-ENTRY"})
	assert(actor.position == Vector2(100, 270) and controller.confirmed_anchor() == "QA-B-ENTRY")
	assert(complete_count == 1 and controller.last_entry().roomId == "QA-ROOM-B")
	assert(not controller.commit_transition(actor).ok, "Repeated commit must not double-switch")
	assert(controller.request_transition("QA-TR-A-B", actor).error == "invalid-source-room")

	# Navigate inside B before returning; return must use authored reverse entry.
	assert(controller.request_room_hotspot("QA-HS-B-SIDE", actor).ok)
	_walk_until_idle()
	assert(controller.confirmed_anchor() == "QA-B-SIDE")
	assert(controller.room_id() == "QA-ROOM-B")
	assert(controller.request_transition("QA-TR-B-A", actor).ok)
	_walk_until_ready("QA-TR-B-A")
	var reverse: Dictionary = controller.commit_transition(actor)
	assert(reverse.ok and reverse.roomId == "QA-ROOM-A")
	assert(reverse.entryAnchorId == "QA-A-ENTRY")
	assert(reverse.reverseTransitionId == "QA-TR-A-B")
	assert(actor.position == Vector2(100, 270) and controller.confirmed_anchor() == "QA-A-ENTRY")
	assert(ready_count == 2 and complete_count == 2)

	# Virtual portal only emits diagnostic AFTER actual footpoint arrival.
	_reset()
	var diagnostic_before := diagnostic_count
	assert(controller.request_transition("QA-TR-A-VIRTUAL", actor).ok)
	_walk_until_idle()
	assert(diagnostic_count == diagnostic_before + 1)
	assert(controller.room_id() == "QA-ROOM-A")
	assert(controller.ready_transition().is_empty() and controller.pending_transition().is_empty())
	assert(not controller.commit_transition(actor).ok, "No far-side spawn was authored")

	# Cancel during active physical movement: finish current leg; never teleport.
	_reset()
	assert(controller.request_transition("QA-TR-A-B", actor).ok)
	leg = _start_leg()
	actor.advance(0.06)
	var cancel_position: Vector2 = actor.position
	var cancelled: Dictionary = controller.cancel_transition()
	assert(cancelled.ok and cancelled.finishCurrentSegment)
	assert(actor.position == cancel_position)
	_finish_leg(leg)
	assert(controller.room_id() == "QA-ROOM-A")
	assert(controller.confirmed_anchor() == "QA-A-MID")
	assert(controller.ready_transition().is_empty())
	assert(controller.next_segment(actor).is_empty())
	assert(controller.cancel_transition().ok)

	# Closing an approach GATE during a segment pauses physical motion in place.
	_reset()
	assert(controller.request_transition("QA-TR-A-B", actor).ok)
	leg = _start_leg()
	_finish_leg(leg)
	leg = _start_leg() # QA-A-MID -> QA-A-DOOR, uses QA-DOOR-APPROACH
	actor.advance(0.08)
	var held_feet: Vector2 = actor.position
	assert(held_feet != leg.toPosition)
	assert(controller.set_test_door_status("QA-DOOR-APPROACH", "gated", actor))
	assert(controller.in_safe_hold() and actor.is_paused())
	assert(not controller.request_transition("QA-TR-A-B", actor).ok)
	assert(controller.accept_segment_arrival(int(leg.segmentToken), str(leg.toAnchorId), leg.toPosition, actor).error == "safe-hold-required")
	actor.advance(100.0)
	assert(actor.position == held_feet, "Closed gate cannot teleport or keep moving")
	assert(controller.room_id() == "QA-ROOM-A")
	assert(controller.confirmed_anchor() == "QA-A-MID")
	assert(not controller.resume_held_segment(actor))
	assert(controller.set_test_door_status("QA-DOOR-APPROACH", "open", actor))
	assert(controller.resume_held_segment(actor))
	_finish_leg(leg)
	assert(controller.room_id() == "QA-ROOM-A" and controller.confirmed_anchor() == "QA-A-DOOR")
	assert(controller.ready_transition().is_empty() and not controller.in_safe_hold())
	assert(controller.next_segment(actor).is_empty(), "Closed gate cancels queued handoff")

	# Late asynchronous gate closure at the exact endpoint: hard hold, no
	# accepting RouteSession rollbackAnchorId as permission to snap to an old XY.
	_reset()
	assert(controller.request_transition("QA-TR-A-B", actor).ok)
	leg = _start_leg()
	_finish_leg(leg)
	leg = _start_leg()
	actor.advance(10.0)
	assert(not actor.has_active_segment() and actor.position == leg.toPosition)
	var endpoint: Vector2 = actor.position
	assert(controller.set_test_door_status("QA-DOOR-APPROACH", "gated", actor))
	assert(controller.in_safe_hold())
	assert(controller.accept_segment_arrival(int(leg.segmentToken), str(leg.toAnchorId), endpoint, actor).error == "safe-hold-required")
	assert(controller.room_id() == "QA-ROOM-A" and actor.position == endpoint)
	assert(controller.confirmed_anchor() == "QA-A-MID", "Unconfirmed crossing is quarantined, not acknowledged")
	assert(controller.set_test_door_status("QA-DOOR-APPROACH", "open", actor))
	assert(not controller.resume_held_segment(actor), "Hard hold requires explicit QA restart, no snap")
	assert(actor.position == endpoint and controller.room_id() == "QA-ROOM-A")

	# Door gate may close after approach is physically confirmed but before commit.
	_reset()
	assert(controller.request_transition("QA-TR-A-B", actor).ok)
	_walk_until_ready("QA-TR-A-B")
	var at_door: Vector2 = actor.position
	assert(controller.set_test_door_status("QA-DOOR-A-B", "gated", actor))
	assert(controller.ready_transition().is_empty())
	assert(controller.commit_transition(actor).error == "no-confirmed-transition")
	assert(actor.position == at_door and controller.room_id() == "QA-ROOM-A")

	# No controller path reads/writes the production campaign or save adapter.
	assert(JSON.stringify(saved) == saved_before)
	assert(complete_count == 2, "Only forward and reverse produced switches")
	assert(rejection_count > 0)
	actor.queue_free()
	print("Raven MAP-QA-06 authored room transition smoke passed")
	quit()


func _reset() -> void:
	assert(not actor.has_active_segment(), "Test reset only between settled cases")
	assert(controller.configure(contract, "QA-ROOM-A", "QA-A-ENTRY"))
	actor.position = controller.anchor_position("QA-A-ENTRY") # Test fixture reset, never live transition.
	arrivals.clear()


func _start_leg() -> Dictionary:
	var leg: Dictionary = controller.next_segment(actor)
	assert(not leg.is_empty() and leg.has("toAnchorId") and leg.has("segmentToken"))
	assert(actor.start_segment(leg))
	return leg


func _finish_leg(leg: Dictionary) -> void:
	var prior := arrivals.size()
	actor.advance(10.0)
	assert(not actor.has_active_segment())
	assert(arrivals.size() == prior + 1)
	assert(arrivals.back().id == leg.toAnchorId and arrivals.back().point == leg.toPosition)
	var outcome: Dictionary = controller.accept_segment_arrival(int(leg.segmentToken), str(leg.toAnchorId), actor.position, actor)
	assert(outcome.ok or (outcome.get("diagnostic", false) and outcome.get("error", "") == "qa-virtual-no-far-spawn"), "Authored leg must be acknowledged after physical arrival or emit expected virtual QA diagnostic: %s" % str(outcome))


func _walk_until_ready(expected: String) -> void:
	for i in range(12):
		if controller.ready_transition() == expected:
			return
		var leg: Dictionary = controller.next_segment(actor)
		if leg.is_empty():
			break
		if bool(leg.get("arrived", false)):
			continue
		assert(actor.start_segment(leg))
		_finish_leg(leg)
	assert(controller.ready_transition() == expected, "Expected confirmed handoff after finite authored legs")


func _walk_until_idle() -> void:
	for i in range(12):
		var leg: Dictionary = controller.next_segment(actor)
		if leg.is_empty():
			return
		if bool(leg.get("arrived", false)):
			return
		assert(actor.start_segment(leg))
		_finish_leg(leg)
	assert(false, "Walking must terminate")


func _on_physical_arrival(anchor_id: String, point: Vector2) -> void:
	arrivals.append({"id": anchor_id, "point": point})
