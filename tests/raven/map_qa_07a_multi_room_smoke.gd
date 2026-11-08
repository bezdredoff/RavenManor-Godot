extends SceneTree
## MAP-QA-07A deterministic Godot headless smoke. No campaign save or real
## Corridor/Bedroom art. Run separately until integration owner wires check.sh.
const Fixture = preload("res://scripts/raven/first_floor_multi_room_fixture.gd")
const HostScene = preload("res://scenes/raven/tests/first_floor_multi_room_host.tscn")
const DemoScene = preload("res://scenes/raven/tests/first_floor_multi_room_qa.tscn")
const HallScene = preload("res://scenes/raven/tests/first_floor_hall_movement_pilot.tscn")
const WholeScene = preload("res://scenes/raven/season1_map_greybox.tscn")
const Snapshot = preload("res://scripts/raven/raven_snapshot.gd")

var host
var visited: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	assert(HallScene != null and WholeScene != null and DemoScene != null)
	var fixture: Dictionary = Fixture.build()
	assert(not fixture.is_empty(), "Hall draft must validate before assembling QA-only rooms")
	var contract: Dictionary = fixture["contract"]
	assert(contract["approval"] == "TEST_ONLY")
	assert(contract["rooms"].size() == 3)
	assert(contract["rooms"][0]["graph"]["provenance"]["productionReady"] == false)
	assert(contract["rooms"][1]["graph"]["provenance"]["geometryStatus"] == "synthetic-test-only")
	assert(contract["rooms"][2]["graph"]["provenance"]["geometryStatus"] == "synthetic-test-only")
	var original_fixture := JSON.stringify(fixture)
	var saved_before := JSON.stringify(Snapshot.fresh())
	var reject_host = HostScene.instantiate()
	root.add_child(reject_host)
	await process_frame
	var broken_visuals: Dictionary = fixture["visuals"].duplicate(true)
	broken_visuals.erase("QA-F7-BEDROOM")
	assert(not reject_host.configure_host(contract, broken_visuals, "RM-ROOM-HALL", "QA-HALL-SPAWN"))
	assert(reject_host.active_room_id.is_empty() and not reject_host.ready_for_test)
	var broken_contract: Dictionary = contract.duplicate(true)
	broken_contract["transitions"][0]["destinationEntryAnchorId"] = "QA-NOT-A-REAL-ENTRY"
	assert(not reject_host.configure_host(broken_contract, fixture["visuals"], "RM-ROOM-HALL", "QA-HALL-SPAWN"))
	assert(reject_host.active_room_id.is_empty())
	reject_host.queue_free()

	host = HostScene.instantiate()
	root.add_child(host)
	await process_frame
	assert(host.configure_host(contract, fixture["visuals"], "RM-ROOM-HALL", "QA-HALL-SPAWN"))
	host.room_changed.connect(func(event): visited.append(str(event.get("roomId", ""))))
	assert(host.active_room_id == "RM-ROOM-HALL")
	assert(host.controller.confirmed_anchor() == "QA-HALL-SPAWN")
	assert(host.actor.position == host.controller.anchor_position("QA-HALL-SPAWN"))
	assert(host.camera.limit_left == 0 and host.camera.limit_right == 1672)
	assert(host.camera.limit_bottom == 941 and host.camera.position_smoothing_enabled)
	assert(host.route_overlay.visible == false)
	host.toggle_routes()
	assert(host.route_overlay.visible)
	host.toggle_routes()
	assert(not host.route_overlay.visible)
	var snapshot_before := host.state_proposal()
	assert(snapshot_before["roomId"] == "RM-ROOM-HALL")
	assert(snapshot_before["transitionComplete"] == false)

	# Locked and nonexistent transitions must not move Onoe or change rooms.
	var feet: Vector2 = host.actor.position
	assert(host.request_transition("QA-F7-TR-LOCKED").get("error") == "locked-door")
	assert(host.request_transition("QA-F7-TR-MISSING").get("error") == "unknown-transition")
	assert(host.actor.position == feet and host.active_room_id == "RM-ROOM-HALL")
	assert(host.controller.pending_transition().is_empty())

	# A new editor graph can replace inactive data without touching the Hall.
	var replacement: Dictionary = contract["rooms"][2]["graph"].duplicate(true)
	replacement["anchors"][3]["position"] = [540,175]
	assert(host.replace_room_graph("QA-F7-BEDROOM", replacement))
	assert(host.actor.position == feet)
	assert(not host.replace_room_graph("QA-UNKNOWN", replacement))
	assert(host.actor.position == feet)

	# A → B → C. No room change on request, only after Onoe reaches approach.
	var result: Dictionary = host.request_transition("QA-F7-TR-HC")
	assert(result.get("ok") and host.active_room_id == "RM-ROOM-HALL")
	assert(host.request_transition("QA-F7-TR-HC").get("status") == "unchanged")
	assert(host.actor.has_active_segment())
	var in_motion: Vector2 = host.actor.position
	assert(not host.replace_room_graph("QA-F7-BEDROOM", replacement))
	assert(host.actor.position == in_motion)
	assert(host.pause_movement())
	host.actor.advance(60.0)
	assert(host.actor.position == in_motion and host.actor.is_paused())
	assert(host.resume_movement())
	_drive_room("QA-F7-CORRIDOR")
	assert(host.controller.confirmed_anchor() == "QA-F7-C-ENTRY-H")
	assert(host.actor.position == Vector2(135, 280))
	assert(host.camera.limit_right == 900 and host.camera.limit_bottom == 550)
	assert(host.state_proposal()["returnSpawnAnchorId"] == "QA-F7-C-ENTRY-H")
	assert(host.state_proposal()["transitionComplete"])
	assert(not host.controller.commit_transition(host.actor).get("ok"), "Duplicate commit cannot teleport")

	# Mid-route cancellation never moves to the next room.
	assert(host.request_transition("QA-F7-TR-CB").get("ok"))
	var before_cancel: Vector2 = host.actor.position
	assert(host.actor.has_active_segment())
	assert(host.cancel_request().get("finishCurrentSegment"))
	assert(host.active_room_id == "QA-F7-CORRIDOR")
	assert(host.actor.position == before_cancel)
	_drive_idle()
	assert(host.active_room_id == "QA-F7-CORRIDOR")
	assert(host.controller.ready_transition().is_empty())

	# Walk to a non-door hotspot, then take the valid Corridor → Bedroom door.
	assert(host.request_hotspot("QA-HS-F7-C-SIDE").get("ok"))
	_drive_idle()
	assert(host.controller.confirmed_anchor() == "QA-F7-C-SIDE")
	assert(host.request_transition("QA-F7-TR-CB").get("ok"))
	_drive_room("QA-F7-BEDROOM")
	assert(host.controller.confirmed_anchor() == "QA-F7-B-ENTRY")
	assert(host.actor.position == Vector2(135, 280))
	assert(host.camera.limit_right == 780 and host.camera.limit_bottom == 520)
	assert(host.current_graph().position("QA-F7-B-SIDE") == Vector2(540, 175))
	assert(host.state_proposal()["lastSafeAnchorId"] == "QA-F7-B-ENTRY")

	# Return C → B → A, with dedicated far-side safe entries.
	assert(host.request_transition("QA-F7-TR-BC").get("ok"))
	_drive_room("QA-F7-CORRIDOR")
	assert(host.actor.position == Vector2(685,280))
	assert(host.controller.confirmed_anchor() == "QA-F7-C-ENTRY-B")
	assert(host.request_transition("QA-F7-TR-CH").get("ok"))
	_drive_room("RM-ROOM-HALL")
	assert(host.controller.confirmed_anchor() == "QA-HALL-RETURN-SAFE")
	assert(host.actor.position == host.controller.anchor_position("QA-HALL-RETURN-SAFE"))
	assert(host.state_proposal()["returnSpawnAnchorId"] == "QA-HALL-RETURN-SAFE")
	assert(visited == ["QA-F7-CORRIDOR", "QA-F7-BEDROOM", "QA-F7-CORRIDOR", "RM-ROOM-HALL"])

	# Closing a real QA gate while approach is underway cancels the handoff,
	# but allows the already authorized segment to finish without a teleport.
	assert(host.request_transition("QA-F7-TR-HC").get("ok"))
	host.actor.advance(0.1)
	var mid_gate: Vector2 = host.actor.position
	assert(host.test_gate("QA-F7-DOOR-HC", "gated"))
	assert(host.active_room_id == "RM-ROOM-HALL" and host.actor.position == mid_gate)
	_drive_idle()
	assert(host.controller.ready_transition().is_empty())
	assert(host.active_room_id == "RM-ROOM-HALL")
	assert(host.request_transition("QA-F7-TR-HC").get("error") == "locked-door")
	assert(host.test_gate("QA-F7-DOOR-HC", "open"))
	assert(host.request_transition("QA-F7-TR-HC").get("ok"))
	_drive_room("QA-F7-CORRIDOR")

	# TEST_ONLY state is a read-only proposal, never pushed to campaign snapshot.
	assert(JSON.stringify(Snapshot.fresh()) == saved_before)
	assert(JSON.stringify(fixture) == original_fixture, "Host cannot mutate fixture graph/visual records")
	assert(host.state_proposal()["roomId"] == "QA-F7-CORRIDOR")
	var proposal := host.state_proposal()
	proposal["roomId"] = "FAKE"
	assert(host.state_proposal()["roomId"] == "QA-F7-CORRIDOR")
	host.queue_free()

	# F6 demonstration actually boots and connects its Host/actor/buttons.
	var demo = DemoScene.instantiate()
	root.add_child(demo)
	await process_frame
	assert(demo.host.ready_for_test)
	assert(demo.host.active_room_id == "RM-ROOM-HALL")
	assert(demo.transition("QA-F7-TR-HC").get("ok"))
	_drive_demo_room(demo, "QA-F7-CORRIDOR")
	assert(demo.transition("QA-F7-TR-CB").get("ok"))
	_drive_demo_room(demo, "QA-F7-BEDROOM")
	demo.queue_free()
	print("Raven MAP-QA-07A multi-room playable foundation smoke passed")
	quit()


func _drive_room(target: String) -> void:
	for i in range(28):
		if host.active_room_id == target:
			return
		assert(host.actor.has_active_segment(), "No transition without authored physical approach")
		host.actor.advance(60.0)
	assert(host.active_room_id == target, "Expected room " + target)


func _drive_idle() -> void:
	for i in range(28):
		if not host.actor.has_active_segment():
			return
		host.actor.advance(60.0)
	assert(not host.actor.has_active_segment())


func _drive_demo_room(demo, target: String) -> void:
	for i in range(28):
		if demo.host.active_room_id == target:
			return
		assert(demo.host.actor.has_active_segment())
		demo.host.actor.advance(60.0)
	assert(demo.host.active_room_id == target)
