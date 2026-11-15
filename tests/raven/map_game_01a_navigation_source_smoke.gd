extends SceneTree
## MAP-GAME-01A: explicit production/QA navigation-source boundary and isolated
## hotspot movement harness. No production scene, save schema or map is changed.
const Source = preload("res://scripts/raven/manor_navigation_source.gd")
const Harness = preload("res://scripts/raven/manor_gameplay_integration_harness.gd")
const Snapshot = preload("res://scripts/raven/raven_snapshot.gd")
const Preview = preload("res://addons/room_builder_routes/route_preview_source.gd")
const PATH := "res://assets/raven/map/qa/drafts/map_qa_08_visual_candidate.v1.json"
const INVALID := "user://room_builder_routes/map_game_01a_invalid.v1.json"
const ART := "res://a_detailed_top_down_isometric_game_map_illustratio.png"
const HALL := "RM-ROOM-HALL"
const CORRIDOR := "RM-ROOM-CORRIDOR"
const DOOR := "RM-DOOR-HALL-CORRIDOR"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_request_contract()
	_test_canonical_production_fails_closed()
	_test_qa_opt_in_and_candidate()
	var approved := _approved_world_plan()
	var production := Source.resolve(_production_request(Snapshot.fresh(), approved))
	assert(production.ok, production.reason)
	assert(production.approval == "PRODUCTION_APPROVED" and production.productionReady)
	assert(not production.draftOnly and production.initialRoomId == HALL)
	assert(production.initialAnchorId == "RM-NAV-HALL-SPAWN")
	_test_safe_start_resolution(production)
	_test_missing_and_invalid_production_geometry(approved)
	_test_invalid_qa_route()
	await _test_harness_rejects_unavailable_source()
	await _test_qa_hotspot_movement_and_transition()
	await _test_production_harness_path(production)
	_cleanup()
	print("MAP-GAME-01A navigation source adapter smoke passed")
	quit()


func _test_request_contract() -> void:
	var bad_schema := Source.resolve({"schemaVersion": 2, "kind": Source.REQUEST_KIND, "mode": "production"})
	assert(bad_schema.status == "invalid_request" and bad_schema.reason == "unsupported-request-schema")
	var bad_kind := Source.resolve({"schemaVersion": 1, "kind": "other", "mode": "production"})
	assert(bad_kind.status == "invalid_request")
	var bad_mode := Source.resolve({"schemaVersion": 1, "kind": Source.REQUEST_KIND, "mode": "auto"})
	assert(bad_mode.status == "invalid_request" and bad_mode.reason == "unknown-navigation-source-mode")
	var bad_snapshot := Source.resolve({"schemaVersion": 1, "kind": Source.REQUEST_KIND, "mode": "production", "snapshot": []})
	assert(bad_snapshot.status == "invalid_request" and bad_snapshot.reason == "snapshot-must-be-dictionary")


func _test_canonical_production_fails_closed() -> void:
	var canonical := Source.resolve(_production_request(Snapshot.fresh()))
	assert(not canonical.ok and canonical.status == "unavailable_geometry")
	assert(canonical.reason == "production-geometry-unapproved")
	assert(canonical.blockers.has("unapproved-world-plan"))
	assert(canonical.blockers.has("production-geometry-unapproved"))
	assert(canonical.blockers.has("unsupported-coordinate-space"))
	assert(canonical.blockers.has("unapproved-room-art-calibration"))
	assert(not canonical.movementEnabled and not canonical.freeTapToMove)
	assert(canonical.contract.is_empty() and canonical.starts.is_empty())
	assert(canonical.hold.action == "hold" and canonical.hold.snapshotMutation == false)
	assert(canonical.hold.checkpointEvent.is_empty())
	assert(not canonical.snapshotMutation and canonical.saveAuthority == "raven_campaign_store")


func _test_qa_opt_in_and_candidate() -> void:
	var no_opt := Source.resolve(_qa_request(false))
	assert(not no_opt.ok and no_opt.status == "qa_requires_opt_in")
	assert(not no_opt.movementEnabled and no_opt.contract.is_empty())
	var qa := Source.resolve(_qa_request(true))
	assert(qa.ok, qa.reason)
	assert(qa.status == "ready" and qa.approval == "TEST_ONLY")
	assert(qa.draftOnly and not qa.productionReady)
	assert(qa.coordinateSpace == "image-pixel")
	assert(qa.movementEnabled and not qa.freeTapToMove)
	assert(qa.inputPolicy == "authored-hotspot-only")
	assert(qa.contract.rooms.size() == 5)
	assert(qa.initialRoomId == HALL and qa.initialAnchorId == "QA-HALL-SPAWN")
	assert(not qa.savedPositionApplied and not qa.spawnFallback)
	assert(not qa.snapshotMutation and qa.source.syntheticTransitions)


func _test_safe_start_resolution(production: Dictionary) -> void:
	var unknown: Dictionary = Source.resolve_snapshot_start(production, {
		"lastRoomId": "RM-ROOM-ARCHIVE", "lastSafeAnchorId": ""})
	assert(unknown.ok and unknown.roomId == HALL and unknown.anchorId == "RM-NAV-HALL-SPAWN")
	assert(unknown.fallback and unknown.reason == "unknown-saved-room")
	assert(not unknown.savedPositionApplied)
	var bogus: Dictionary = Source.resolve_snapshot_start(production, {
		"lastRoomId": HALL, "lastSafeAnchorId": "RM-NAV-BOGUS"})
	assert(bogus.ok and bogus.roomId == HALL and bogus.anchorId == "RM-NAV-HALL-SPAWN")
	assert(bogus.fallback and bogus.reason == "invalid-saved-anchor")
	var unsafe: Dictionary = Source.resolve_snapshot_start(production, {
		"lastRoomId": HALL, "lastSafeAnchorId": "RM-NAV-HALL-APPROACH"})
	assert(unsafe.fallback and unsafe.reason == "invalid-saved-anchor")
	var valid: Dictionary = Source.resolve_snapshot_start(production, {
		"lastRoomId": HALL, "lastSafeAnchorId": "RM-NAV-HALL-ENTRY"})
	assert(valid.ok and valid.anchorId == "RM-NAV-HALL-ENTRY")
	assert(not valid.fallback and valid.savedPositionApplied)
	var empty: Dictionary = Source.resolve_snapshot_start(production, {
		"lastRoomId": HALL, "lastSafeAnchorId": ""})
	assert(empty.ok and empty.anchorId == "RM-NAV-HALL-SPAWN")
	assert(not empty.fallback and not empty.savedPositionApplied)
	# The same fallback is applied while resolving production requests.
	var snapshot := Snapshot.fresh()
	snapshot.lastRoomId = HALL
	snapshot.lastSafeAnchorId = "RM-NAV-BOGUS"
	var resolved := Source.resolve(_production_request(snapshot, _approved_world_plan()))
	assert(resolved.ok and resolved.initialAnchorId == "RM-NAV-HALL-SPAWN")
	assert(resolved.spawnFallback and resolved.spawnFallbackReason == "invalid-saved-anchor")


func _test_missing_and_invalid_production_geometry(base_plan: Dictionary) -> void:
	var missing_visual := base_plan.duplicate(true)
	missing_visual.provenance.roomArtCalibration.rooms.erase(CORRIDOR)
	var no_visual := Source.resolve(_production_request(Snapshot.fresh(), missing_visual))
	assert(no_visual.status == "unavailable_geometry" and no_visual.reason == "missing-room-visuals")
	assert(no_visual.blockers.has("missing-room-visual:" + CORRIDOR))
	assert(not no_visual.movementEnabled)
	var unsupported := base_plan.duplicate(true)
	unsupported.anchors.append({
		"id": "RM-NAV-ARCHIVE-START", "roomId": "RM-ROOM-ARCHIVE",
		"position": [400, 400], "kind": "safe"})
	var unsupported_room := Source.resolve(_production_request(Snapshot.fresh(), unsupported))
	assert(unsupported_room.status == "invalid_route")
	assert(unsupported_room.blockers.has("unsupported-save-catalog-room:RM-ROOM-ARCHIVE"))
	var invalid_edge := base_plan.duplicate(true)
	for anchor in invalid_edge.anchors:
		if str(anchor.id) == "RM-NAV-CORRIDOR-ENTRY":
			anchor.kind = "transition"
	var bad_route := Source.resolve(_production_request(Snapshot.fresh(), invalid_edge))
	assert(bad_route.status == "invalid_route" and bad_route.reason == "invalid-transition-contract")
	assert(bad_route.blockers.has("missing-destination-entry-anchor:RM-NAV-CORRIDOR-ENTRY"))
	var restoration := base_plan.duplicate(true)
	restoration.edges[0]["restorationId"] = "RM-RESTORE-TEST"
	var gated := Source.resolve(_production_request(Snapshot.fresh(), restoration))
	assert(gated.status == "invalid_route")
	assert(gated.blockers.has("restoration-gated-edges-unsupported"))


func _test_invalid_qa_route() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	assert(parsed is Dictionary)
	var doc: Dictionary = parsed
	doc.routes[0]["to"] = "QA-MISSING-ENDPOINT"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://room_builder_routes"))
	var file := FileAccess.open(INVALID, FileAccess.WRITE)
	assert(file != null)
	file.store_string(JSON.stringify(doc))
	file.close()
	var rejected := Source.resolve(_qa_request(true, INVALID, Preview.USER))
	assert(not rejected.ok and rejected.status == "invalid_source")
	assert(not rejected.movementEnabled and rejected.contract.is_empty())
	assert(not rejected.reason.is_empty())


func _test_harness_rejects_unavailable_source() -> void:
	var canonical := Source.resolve(_production_request(Snapshot.fresh()))
	var harness = Harness.new()
	root.add_child(harness)
	await process_frame
	assert(not harness.configure(canonical, Snapshot.fresh()))
	assert(harness.error_text == "navigation-source-unavailable")
	assert(not harness.movement_enabled())
	var rejection: Dictionary = harness.request_screen_point(Vector2(120, 140))
	assert(not rejection.ok and rejection.error == "free-tap-to-move-disabled")
	harness.queue_free()


func _test_qa_hotspot_movement_and_transition() -> void:
	var snapshot := Snapshot.fresh()
	var snapshot_before := JSON.stringify(snapshot)
	var source := Source.resolve(_qa_request(true, PATH))
	assert(source.ok, source.reason)
	var harness = Harness.new()
	root.add_child(harness)
	await process_frame
	assert(harness.configure(source, snapshot), harness.error_text)
	assert(harness.movement_enabled())
	assert(harness.actor.position.distance_to(harness.controller.anchor_position("QA-HALL-SPAWN")) < 0.01)
	var rejected: Dictionary = harness.request_screen_point(Vector2(720, 430))
	assert(not rejected.ok and rejected.error == "free-tap-to-move-disabled")
	var start_position: Vector2 = harness.actor.position
	assert(harness.request_hotspot("QA-HS:QA-HALL-CENTRE").ok)
	var walked: Dictionary = harness.drive()
	assert(walked.status == "arrived", JSON.stringify(walked))
	assert(harness.controller.confirmed_anchor() == "QA-HALL-CENTRE")
	assert(harness.actor.position.distance_to(start_position) > 1.0)
	assert(harness.actor.position.distance_to(harness.controller.anchor_position("QA-HALL-CENTRE")) < 0.01)
	assert(harness.checkpoint_proposal("MAP-GAME-01A-NON-SAFE").is_empty())
	var before_room: Dictionary = harness.room_state()
	assert(not before_room.roomChanged and before_room.roomId == HALL)
	assert(harness.request_transition("QA-07B-TR-HC").ok)
	var approach: Dictionary = harness.drive()
	assert(approach.status == "ready", JSON.stringify(approach))
	assert(harness.controller.ready_transition() == "QA-07B-TR-HC")
	var committed: Dictionary = harness.commit_transition()
	assert(committed.ok and committed.roomId == CORRIDOR)
	assert(committed.fromRoomId == HALL and committed.checkpointProposal.anchorId == "QA-CORRIDOR-WEST")
	assert(harness.actor.position.distance_to(harness.controller.anchor_position("QA-CORRIDOR-WEST")) < 0.01)
	var changed: Dictionary = harness.room_state()
	assert(changed.roomChanged and changed.roomId == CORRIDOR)
	assert(changed.previousReportedRoomId == HALL)
	var camera: Dictionary = harness.camera_proposal()
	assert(camera.roomChanged and camera.roomId == CORRIDOR)
	assert(camera.resetOnRoomChange and camera.cameraNode == null)
	assert(camera.position.size() == 2)
	assert(harness.checkpoint_proposal("").is_empty())
	harness.acknowledge_room()
	harness.acknowledge_camera()
	assert(not harness.room_state().roomChanged)
	assert(not harness.camera_proposal().roomChanged)
	var checkpoint: Dictionary = harness.checkpoint_proposal("MAP-GAME-01A-EVT-1")
	assert(checkpoint.type == "position_checkpoint" and checkpoint.roomId == CORRIDOR)
	assert(checkpoint.anchorId == "QA-CORRIDOR-WEST")
	assert(checkpoint.eventId == "MAP-GAME-01A-EVT-1")
	assert(JSON.stringify(snapshot) == snapshot_before)
	assert(not source.snapshotMutation)
	harness.queue_free()


func _test_production_harness_path(production: Dictionary) -> void:
	var harness = Harness.new()
	root.add_child(harness)
	await process_frame
	assert(harness.configure(production, Snapshot.fresh()), harness.error_text)
	assert(harness.request_hotspot("PROD-HS-HALL-DOOR").ok)
	var walk: Dictionary = harness.drive()
	assert(walk.status == "arrived", JSON.stringify(walk))
	assert(harness.actor.position.distance_to(Vector2(50, 10)) < 0.01)
	assert(harness.request_transition("PROD-TR-RM-NAV-HALL-APPROACH>RM-NAV-CORRIDOR-ENTRY").ok)
	assert(harness.drive().status == "ready")
	var committed: Dictionary = harness.commit_transition()
	assert(committed.ok and committed.roomId == CORRIDOR)
	assert(committed.checkpointProposal.anchorId == "RM-NAV-CORRIDOR-ENTRY")
	assert(harness.room_state().roomChanged)
	assert(harness.camera_proposal().roomChanged)
	harness.queue_free()


func _production_request(snapshot: Dictionary, world_plan: Dictionary = {}) -> Dictionary:
	var request := {
		"schemaVersion": 1,
		"kind": Source.REQUEST_KIND,
		"mode": "production",
		"snapshot": snapshot,
	}
	if not world_plan.is_empty():
		request["worldPlan"] = world_plan
	return request


func _qa_request(allow: bool, path: String = PATH, kind: String = Preview.PROJECT) -> Dictionary:
	return {
		"schemaVersion": 1,
		"kind": Source.REQUEST_KIND,
		"mode": "qa",
		"snapshot": Snapshot.fresh(),
		"allowQaCandidate": allow,
		"qaSourceKind": kind,
		"qaSourcePath": path,
	}


func _approved_world_plan() -> Dictionary:
	return {
		"schemaVersion": 1,
		"provenance": {
			"approval": "PRODUCTION_APPROVED",
			"productionReady": true,
			"coordinateSpace": "world-plan",
			"geometryStatus": "fixture-approved",
			"roomArtCalibration": {
				"status": "approved",
				"assetHash": "sha256:map-game-01a-fixture",
				"version": 1,
				"rooms": {
					HALL: _visual_spec(),
					CORRIDOR: _visual_spec(),
				},
			},
		},
		"anchors": [
			{"id": "RM-NAV-HALL-SPAWN", "roomId": HALL, "position": [10, 10], "kind": "safe"},
			{"id": "RM-NAV-HALL-ENTRY", "roomId": HALL, "position": [10, 50], "kind": "safe"},
			{"id": "RM-NAV-HALL-APPROACH", "roomId": HALL, "position": [50, 10],
				"kind": "interaction", "hotspotId": "PROD-HS-HALL-DOOR"},
			{"id": "RM-NAV-CORRIDOR-ENTRY", "roomId": CORRIDOR, "position": [90, 10], "kind": "safe"},
			{"id": "RM-NAV-CORRIDOR-SPAWN", "roomId": CORRIDOR, "position": [90, 90], "kind": "safe"},
			{"id": "RM-NAV-CORRIDOR-APPROACH", "roomId": CORRIDOR, "position": [90, 50],
				"kind": "interaction", "hotspotId": "PROD-HS-CORRIDOR-DOOR"},
		],
		"edges": [
			{"from": "RM-NAV-HALL-SPAWN", "to": "RM-NAV-HALL-ENTRY"},
			{"from": "RM-NAV-HALL-SPAWN", "to": "RM-NAV-HALL-APPROACH"},
			{"from": "RM-NAV-CORRIDOR-ENTRY", "to": "RM-NAV-CORRIDOR-SPAWN"},
			{"from": "RM-NAV-CORRIDOR-ENTRY", "to": "RM-NAV-CORRIDOR-APPROACH"},
			{"from": "RM-NAV-HALL-APPROACH", "to": "RM-NAV-CORRIDOR-ENTRY", "doorId": DOOR},
			{"from": "RM-NAV-CORRIDOR-APPROACH", "to": "RM-NAV-HALL-ENTRY", "doorId": DOOR},
		],
	}


func _visual_spec() -> Dictionary:
	return {
		"texturePath": ART,
		"bounds": [0, 0, 1672, 941],
		"cameraZoom": 1.0,
		"actorHeight": 62.0,
	}


func _cleanup() -> void:
	var absolute := ProjectSettings.globalize_path(INVALID)
	if FileAccess.file_exists(INVALID):
		DirAccess.remove_absolute(absolute)
