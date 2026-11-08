extends SceneTree

## MAP-QA-03: deterministic physical-leg, RouteSession, portal and scene smoke.
## No campaign store, reducer, checkpoint or real Corridor scene is instantiated.
const PILOT = preload("res://scenes/raven/tests/first_floor_hall_movement_pilot.tscn")
const ORIGINAL_GRAPH = preload("res://scripts/raven/manor_navigation_graph.gd")
const QA_ADAPTER = preload("res://scripts/raven/first_floor_hall_qa_graph.gd")
const SESSION = preload("res://scripts/raven/manor_route_session.gd")

var _portal_events: Array[Dictionary] = []


func _initialize() -> void:
	call_deferred("_run")


func _finish_current_leg(pilot) -> void:
	assert(pilot.actor.has_active_segment(), "An authorized segment must be moving")
	pilot.actor.advance(10.0)


func _run() -> void:
	var scene: PackedScene = PILOT
	assert(scene != null, "Pilot scene must load")
	var pilot = scene.instantiate()
	root.add_child(pilot)
	await process_frame
	assert(pilot.ready_for_qa, "Pilot must accept pinned DRAFT_ONLY image-pixel dataset")
	assert(pilot.art.texture != null and pilot.art.texture.get_size() == Vector2(1672, 941))
	assert(pilot.qa.data.approval == "DRAFT_ONLY")
	assert(pilot.qa.data.integrationAllowed == false)
	assert(pilot.qa.graph.anchors().size() == 7)
	assert(pilot.qa.graph.active_edges().size() == 7)
	assert(pilot.qa.waypoint_ids().size() == 7)
	assert(pilot.qa.graph.route("QA-HALL-SPAWN", "QA-HALL-PORTAL-APPROACH").size() > 1)
	assert(pilot.actor.position == Vector2(836, 746), "Root Node2D is the foot contact")
	assert(pilot.session.current_anchor() == "QA-HALL-SPAWN")
	assert(not pilot.actor.has_active_segment())
	assert(not pilot.request_waypoint("INVALID"), "Clicking outside explicit points cannot create a route")
	assert(not pilot.request_waypoint("RM-NAV-HALL-SPAWN"), "Canonical anchors cannot be picked as QA pixels")
	assert(not pilot.qa.graph.has_anchor("RM-NAV-HALL-SPAWN"))

	# An unreachable but syntactically valid hotspot must fail closed.
	var disconnected = ORIGINAL_GRAPH.new()
	disconnected.rebuild({}, {
		"anchors": [
			{"id": "QA-X", "kind": "safe", "roomId": "RM-ROOM-HALL", "position": [1, 2], "hotspotId": "QA-HS:X"},
			{"id": "QA-Y", "kind": "qa", "roomId": "RM-ROOM-HALL", "position": [4, 5], "hotspotId": "QA-HS:Y"}
		],
		"edges": []
	})
	var isolated = SESSION.new(disconnected)
	assert(isolated.start_at("QA-X"))
	assert(isolated.request_hotspot("QA-HS:Y").error == "unreachable")
	assert(isolated.next_segment().is_empty())

	# First planned route is SPAWN -> CENTRE -> WEST.
	assert(pilot.request_waypoint("QA-HALL-WEST"))
	assert(pilot.actor.segment_destination() == "QA-HALL-CENTRE")
	pilot.actor.advance(0.08)
	var mid: Vector2 = pilot.actor.position
	assert(mid != Vector2(836, 746) and mid != Vector2(835, 697))
	assert(pilot.session.current_anchor() == "QA-HALL-SPAWN", "No early arrival")
	assert(pilot.session.in_flight_anchor() == "QA-HALL-CENTRE")
	assert(pilot.session.next_segment().is_empty(), "No concurrent leg")
	assert(pilot.request_waypoint("QA-HALL-EAST"), "New target is queued after current leg")
	assert(pilot.actor.position == mid, "A queued click must never teleport")
	assert(pilot.actor.segment_destination() == "QA-HALL-CENTRE")
	assert(pilot.pause_movement())
	var held: Vector2 = pilot.actor.position
	pilot.actor.advance(50.0)
	assert(pilot.actor.position == held and pilot.session.current_anchor() == "QA-HALL-SPAWN")
	assert(pilot.actor.has_active_segment() and pilot.actor.is_paused())
	assert(pilot.resume_movement())
	_finish_current_leg(pilot)
	assert(pilot.actor.position == Vector2(835, 697))
	assert(pilot.session.current_anchor() == "QA-HALL-CENTRE", "Arrival only after physical foot contact")
	assert(pilot.actor.has_active_segment(), "Replacement leg must start from completed segment")
	assert(pilot.actor.segment_destination() == "QA-HALL-EAST", "WEST must not be visited after reroute")
	assert(pilot.actor.get_sprite().animation == "side", "Horizontal leg must use side animation")
	assert(not pilot.actor.get_sprite().flip_h)
	_finish_current_leg(pilot)
	assert(pilot.actor.position == Vector2(925, 716))
	assert(pilot.session.current_anchor() == "QA-HALL-EAST")
	assert(not pilot.actor.has_active_segment() and not pilot.actor.get_sprite().is_playing())
	assert(pilot.session.pending_hotspot().is_empty())

	# Another route across centre exercises left-facing animation.
	assert(pilot.request_waypoint("QA-HALL-WEST"))
	_finish_current_leg(pilot) # EAST -> CENTRE
	assert(pilot.actor.segment_destination() == "QA-HALL-WEST")
	assert(pilot.actor.get_sprite().animation == "side" and pilot.actor.get_sprite().flip_h)
	_finish_current_leg(pilot) # CENTRE -> WEST
	assert(pilot.session.current_anchor() == "QA-HALL-WEST")
	assert(not pilot.actor.get_sprite().is_playing())

	# Portal is always virtual: approach, diagnostic signal, no unknown spawn.
	pilot.portal_transition_requested.connect(_on_portal)
	assert(pilot.request_waypoint("QA-HALL-PORTAL-APPROACH"))
	var safety := 0
	while pilot.actor.has_active_segment() and safety < 10:
		_finish_current_leg(pilot)
		safety += 1
	assert(safety > 0 and safety < 10, "Authored portal route must terminate")
	assert(pilot.session.current_anchor() == "QA-HALL-PORTAL-APPROACH")
	assert(pilot.actor.position == Vector2(959, 746))
	assert(pilot.portal_request_count == 1 and _portal_events.size() == 1)
	assert(_portal_events[0].portal == "QA-PORTAL-HALL-CORRIDOR")
	assert(_portal_events[0].to_room == "RM-ROOM-CORRIDOR")
	assert(pilot.portal_status.contains("deferred"))
	assert(pilot.qa.data.virtualPortal.farSideSpawnPointPx == null)
	assert(not pilot.qa.data.virtualPortal.physicalDoorConfirmed)
	assert(not pilot.qa.data.virtualPortal.liveDoorGateWrites)
	assert(not pilot.actor.has_active_segment(), "Virtual portal must leave the actor on the Hall footpoint")
	assert(not pilot.actor.get_sprite().is_playing(), "Idle after approach")

	# Overlay and camera affect presentation, never authored footpoint coordinates.
	var physical_before: Vector2 = pilot.actor.position
	pilot.set_debug_overlay(true)
	assert(pilot.overlay.visible)
	pilot._zoom_by(1.2)
	pilot._pan(Vector2(30, 20))
	assert(pilot.actor.position == physical_before)
	pilot.set_debug_overlay(false)
	assert(not pilot.overlay.visible)
	var invalid_data = QA_ADAPTER.new()
	assert(invalid_data.load_pilot())
	assert(invalid_data.graph.anchors().size() == 7)

	# Canonical graph still carries all 13 independent world-plan anchors.
	var canonical = ORIGINAL_GRAPH.new()
	canonical.rebuild({})
	assert(canonical.anchors().size() == 13)
	assert(canonical.has_anchor("RM-NAV-HALL-SPAWN"))
	assert(canonical.position("RM-NAV-HALL-SPAWN") != Vector2(836, 746))
	# Static source guard against introducing campaign storage or progression calls.
	var controller_source := FileAccess.get_file_as_string("res://scripts/raven/first_floor_hall_movement_pilot.gd")
	for forbidden in ["raven_campaign_store.gd", "raven_reducer.gd", "save_campaign(", "checkpoint_event(", "door_unlock"]:
		assert(not controller_source.contains(forbidden), "QA-only controller must not touch campaign/save: " + forbidden)
	pilot.queue_free()
	print("Raven MAP-QA-03 Hall movement pilot smoke passed (scene, routes, queue, pause, portal and no-save).")
	quit()


func _on_portal(portal_id: String, destination_room: String) -> void:
	_portal_events.append({"portal": portal_id, "to_room": destination_room})
