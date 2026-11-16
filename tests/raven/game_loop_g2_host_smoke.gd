extends SceneTree
## Standalone GAME-LOOP-01 G2 contract test. Run explicitly while QA runner
## registration belongs to Agent E:
## godot --headless --path . --script res://tests/raven/game_loop_g2_host_smoke.gd
const Host = preload("res://scripts/raven/raven_gameplay_host.gd")
const Source = preload("res://scripts/raven/manor_navigation_source.gd")
const Snapshot = preload("res://scripts/raven/raven_snapshot.gd")
const Reducer = preload("res://scripts/raven/raven_reducer.gd")
const Store = preload("res://scripts/raven/raven_campaign_store.gd")
const Director = preload("res://scripts/raven/raven_slice_director.gd")
const Memory = preload("res://tests/support/memory_storage.gd")
const Match3Session = preload("res://scripts/raven/raven_match3_session.gd")
const Content = preload("res://data/raven/rm_vs_01_content.json")
const Catalog = preload("res://scripts/raven/raven_vn_catalog_adapter.gd")
const ReadHistory = preload("res://scripts/raven/raven_vn_read_history.gd")
const Contract = preload("res://data/save_contract.json")

const QA_PATH := "res://assets/raven/map/qa/drafts/map_qa_08_visual_candidate.v1.json"
const HALL := "RM-ROOM-HALL"
const CORRIDOR := "RM-ROOM-CORRIDOR"
const BEDROOM := "RM-ROOM-BEDROOM"
const CB_DOOR := "RM-DOOR-CORRIDOR-BEDROOM"


func _initialize() -> void:
	call_deferred("_run")


func _qa_request() -> Dictionary:
	return {
		"schemaVersion": 1, "kind": Source.REQUEST_KIND, "mode": "qa",
		"allowQaCandidate": true, "qaSourceKind": "project", "qaSourcePath": QA_PATH,
		"qaStoryHotspots": {
			"RM-HS-005": "QA-HS:QA-CORRIDOR-EAST",
			"RM-HS-002": "QA-HS:QA-BEDROOM-RUG",
		},
		"qaTransitionDoors": {
			"QA-07B-TR-HC": "RM-DOOR-HALL-CORRIDOR",
			"QA-07B-TR-CH": "RM-DOOR-HALL-CORRIDOR",
			"QA-07B-TR-CB": CB_DOOR,
			"QA-07B-TR-BC": CB_DOOR,
			"QA-07B-TR-LOCKED": CB_DOOR,
		},
	}


func _production_request() -> Dictionary:
	return {"schemaVersion": 1, "kind": Source.REQUEST_KIND, "mode": "production"}


func _seed(adapter: RefCounted) -> void:
	var snapshot := Snapshot.fresh()
	for beat in ["RM-BEAT-00-01", "RM-BEAT-00-02", "RM-BEAT-00-03", "RM-BEAT-01-01"]:
		var event := {"eventId": "g2-seed-" + beat, "type": "story_beat_seen", "storyBeatId": beat}
		var updated: Dictionary = Reducer.apply(snapshot, event)
		assert(updated.get("ok", false), str(updated))
		snapshot = updated.state
	assert(Store.new(adapter).save_campaign(snapshot))


func _host(adapter: RefCounted):
	return Host.new(adapter, true)


func _run() -> void:
	# Production is still fail-closed, even with a real campaign snapshot.
	var real := Memory.new()
	_seed(real)
	var before: Dictionary = Store.new(real).load_campaign()
	var denied = _host(real)
	root.add_child(denied)
	await process_frame
	assert(not denied.configure(_production_request()).ok)
	assert(denied.navigation == null)
	assert(not denied.request_story_hotspot("RM-HS-005").ok)
	assert(Store.new(real).load_campaign() == before, "No false progress from blocked geometry")
	var forged := _production_request()
	forged.worldPlan = {"provenance": {"approval": "PRODUCTION_APPROVED", "productionReady": true}}
	assert(denied.configure(forged).error == "injected-production-plan-forbidden")
	denied.queue_free()
	await process_frame

	# A QA source without explicit opt-in or isolated storage is never enabled.
	var no_isolation = Host.new()
	root.add_child(no_isolation)
	await process_frame
	assert(no_isolation.configure(_qa_request()).error == "qa-requires-isolated-storage")
	no_isolation.queue_free()
	var no_opt = _qa_request()
	no_opt.allowQaCandidate = false
	var opt = _host(real)
	root.add_child(opt)
	await process_frame
	assert(not opt.configure(no_opt).ok)
	assert(opt.navigation == null)
	opt.queue_free()
	await process_frame

	# An explicit isolated fixture exercises the real multi-room transition
	# controller and inherited actor, with no alternative nav/session.
	var storage = Memory.new()
	_seed(storage)
	var host = _host(storage)
	root.add_child(host)
	await process_frame
	var opened: Dictionary = host.configure(_qa_request())
	assert(opened.get("ok", false), str(opened))
	assert(opened.draftOnly and opened.approval == "TEST_ONLY")
	assert(host.room_state().roomId == HALL)
	assert(host.navigation.request_screen_point(Vector2(500, 500)).error == "free-tap-to-move-disabled")
	assert(host.request_story_hotspot("RM-HS-005").error == "hotspot-not-in-current-room")
	assert(host.request_transition("QA-07B-TR-CB").error == "wrong-transition-room")
	var revision := int(host.state.revision)
	assert(host.request_transition("QA-07B-TR-HC").ok)
	assert(not host.state.storyFlags.has("RM-FLAG-BEDROOM-ACCESS-CLEARED"))
	assert(host.drive().status == "ready")
	assert(int(host.state.revision) >= revision)
	assert(host.navigation.controller.ready_transition() == "QA-07B-TR-HC")
	assert(host.commit_ready_transition().ok)
	assert(host.room_state().roomId == CORRIDOR)
	var checkpointed: Dictionary = Store.new(storage).load_campaign()
	assert(checkpointed.lastRoomId == CORRIDOR and checkpointed.lastSafeAnchorId == "QA-CORRIDOR-WEST")

	# Continue rebuilds controller + actor at the saved safe Corridor entry.
	var restored = _host(storage)
	root.add_child(restored)
	await process_frame
	var resume: Dictionary = restored.configure(_qa_request())
	assert(resume.ok and resume.roomId == CORRIDOR and resume.anchorId == "QA-CORRIDOR-WEST")
	assert(restored.navigation.actor.position.distance_to(restored.navigation.controller.anchor_position(resume.anchorId)) < 0.01)
	assert(restored.request_transition("QA-07B-TR-CB").error == "locked-door")
	assert(restored.request_transition("QA-07B-TR-LOCKED").error == "wrong-transition-room")

	# A blocked/cancelled story request never awards rewards, flags or doors.
	var cancelled_memory = Memory.new()
	_seed(cancelled_memory)
	var cancelled = _host(cancelled_memory)
	root.add_child(cancelled)
	await process_frame
	assert(cancelled.configure(_qa_request()).ok)
	assert(cancelled.request_transition("QA-07B-TR-HC").ok)
	assert(cancelled.cancel().ok)
	assert(cancelled.drive().status == "idle")
	assert(Store.new(cancelled_memory).load_campaign().lastRoomId == HALL)
	assert(Store.new(cancelled_memory).load_campaign().storyFlags.is_empty())

	# A story gate revoked during a real in-flight leg does not commit
	# extra events; the already-started leg finishes and stops safely.
	var revoked_storage = Memory.new()
	_seed(revoked_storage)
	var revoked = _host(revoked_storage)
	root.add_child(revoked)
	await process_frame
	assert(revoked.configure(_qa_request()).ok)
	assert(revoked.request_transition("QA-07B-TR-HC").ok)
	assert(revoked.drive().status == "ready")
	assert(revoked.commit_ready_transition().ok)
	assert(revoked.request_story_hotspot("RM-HS-005").ok)
	assert(revoked.advance(0.05).status == "segment_started")
	var external: Dictionary = Store.new(revoked_storage).load_campaign()
	for raw in Director.events_for("access"):
		var event: Dictionary = raw.duplicate(true)
		event.eventId = "g2-revoked-" + str(raw.get("type", ""))
		var update: Dictionary = Reducer.apply(external, event)
		assert(update.ok)
		external = update.state
	assert(Store.new(revoked_storage).save_campaign(external))
	var stopped: Dictionary = revoked.advance(0.05)
	assert(stopped.ok and stopped.status == "cancel-finishing-current-leg")
	assert(revoked.drive().status == "idle")
	var after_revocation: Dictionary = Store.new(revoked_storage).load_campaign()
	assert(after_revocation.storyFlags == external.storyFlags)
	assert(after_revocation.hotspotStates == external.hotspotStates)
	assert(after_revocation.unlockedDoors == external.unlockedDoors)
	assert(after_revocation.firstClearLevels.is_empty())

	# Door relock during an in-flight CB approach also cancels without a
	# physical portal commit or forged Bedroom checkpoint.
	assert(revoked.request_transition("QA-07B-TR-CB").ok)
	assert(revoked.advance(0.05).status == "segment_started")
	var closed: Dictionary = Store.new(revoked_storage).load_campaign()
	closed.unlockedDoors.erase(CB_DOOR)
	assert(Store.new(revoked_storage).save_campaign(closed))
	var door_stopped: Dictionary = revoked.advance(0.05)
	assert(door_stopped.ok and door_stopped.status == "cancel-finishing-current-leg")
	assert(revoked.drive().status == "idle")
	assert(revoked.room_state().roomId == CORRIDOR)
	assert(Store.new(revoked_storage).load_campaign().lastRoomId == CORRIDOR)

	# Physical traversal and arrival precede the atomic story action.
	assert(restored.request_story_hotspot("RM-HS-005").ok)
	assert(not restored.state.storyFlags.has("RM-FLAG-BEDROOM-ACCESS-CLEARED"))
	var first: Dictionary = restored.advance(0.05)
	assert(first.get("ok", false))
	assert(not Store.new(storage).load_campaign().unlockedDoors.has(CB_DOOR))
	assert(restored.request_story_hotspot("RM-HS-005").error == "action-already-pending")
	var access: Dictionary = restored.drive()
	assert(access.ok and access.status == "action-committed", str(access))
	assert(access.nextStep == "level1" and access.presentation == "match3")
	var after_access: Dictionary = Store.new(storage).load_campaign()
	assert(after_access.unlockedDoors.has(CB_DOOR))
	assert(after_access.storyFlags.has("RM-FLAG-BEDROOM-ACCESS-CLEARED"))
	assert(after_access.hotspotStates.get("RM-HS-005") == "cleared")
	assert(after_access.firstClearLevels.is_empty(), "Arrival must not grant Match-3 rewards")
	assert(restored.request_transition("QA-07B-TR-CB").error == "action-already-pending")
	assert(restored.close_presentation().ok)

	# The existing Match-3 session writes its first clear through the same
	# reducer/store; repeating completion must not duplicate work points.
	var level: Dictionary = {}
	for candidate in Content.data.levels:
		if str(candidate.get("id", "")) == "RM-LVL-001":
			level = candidate
	assert(not level.is_empty())
	var session = Match3Session.open(level, restored.state, Callable())
	assert(session != null)
	var won: Dictionary = Match3Session.complete(null, restored.state,
		"level1", "RM-LVL-001", 1, restored.store)
	assert(won.get("ok", false), str(won))
	var again: Dictionary = Match3Session.complete(null, won.state,
		"level1", "RM-LVL-001", 2, restored.store)
	assert(again.get("ok", false) and again.state.workPoints == 2)
	assert(restored.close_presentation().ok)
	assert(Director.next_step(restored.state).id == "restore1")
	assert(restored.request_transition("QA-07B-TR-CB").ok)
	assert(restored.drive().status == "ready")
	assert(restored.commit_ready_transition().ok)
	assert(restored.room_state().roomId == BEDROOM)
	assert(Store.new(storage).load_campaign().lastRoomId == BEDROOM)
	assert(restored.request_story_hotspot("RM-HS-002").ok)
	var bedroom: Dictionary = restored.drive()
	assert(bedroom.ok and bedroom.presentation == "vn" and bedroom.nextStep == "bedroom")
	assert(Store.new(storage).load_campaign().completedRestorations.has("RM-REST-001"))
	assert(Store.new(storage).load_campaign().workPoints == 0)
	assert(restored.close_presentation().ok)
	assert(restored.request_transition("QA-07B-TR-BC").ok)
	assert(restored.drive().status == "ready")
	assert(restored.commit_ready_transition().ok)
	assert(restored.room_state().roomId == CORRIDOR)
	assert(restored.request_transition("QA-07B-TR-CH").ok)
	assert(restored.drive().status == "ready")
	assert(restored.commit_ready_transition().ok)
	assert(restored.room_state().roomId == HALL)
	assert(Store.new(storage).load_campaign().lastRoomId == HALL)

	var reloaded: Dictionary = restored.reload_session()
	assert(reloaded.ok and reloaded.roomId == HALL)
	assert(restored.state.unlockedDoors.has(CB_DOOR))
	assert(restored.state.completedRestorations.size() == 1)
	assert(restored.state.workPoints == 0)
	assert(restored.current_activity().id == "bedroom", "Continue must retain VN scene activity")

	# Write failure at a confirmed portal entry must never save a false room;
	# the caller may recover by Continue from the last committed safe anchor.
	var broken_storage = Memory.new()
	_seed(broken_storage)
	var broken = _host(broken_storage)
	root.add_child(broken)
	await process_frame
	assert(broken.configure(_qa_request()).ok)
	assert(broken.request_transition("QA-07B-TR-HC").ok)
	assert(broken.drive().status == "ready")
	broken_storage.fail_write = true
	var failure: Dictionary = broken.commit_ready_transition()
	assert(not failure.ok and failure.safeHold)
	assert(Store.new(broken_storage).load_campaign().lastRoomId == HALL)
	broken_storage.fail_write = false
	assert(broken.reload_session().ok)
	assert(broken.room_state().roomId == HALL)

	# Corrupt saves are preserved for recovery and may NOT be replaced by a
	# silently fresh state through G2's Configure.
	var corrupt_memory = Memory.new()
	corrupt_memory.values[Contract.data.ravenKey] = "{corrupt"
	var corrupt = _host(corrupt_memory)
	root.add_child(corrupt)
	await process_frame
	assert(corrupt.configure(_qa_request()).error.begins_with("save-unreadable:"))
	assert(corrupt.navigation == null)
	assert(corrupt_memory.values[Contract.data.ravenKey] == "{corrupt")
	assert(Store.new(corrupt_memory).get_recovery_backup().raw == "{corrupt")

	# Existing RU/BE/EN VN catalog and read-only Skip semantics are unchanged.
	for locale in ["ru", "be", "en"]:
		var config: Dictionary = Catalog.for_legacy(Content.data.vnScenes.bedroom, locale)
		assert(config.beatId == "RM-BEAT-01-02" and not config.lines.is_empty())
		assert(ReadHistory.skip_target(config, 0, []) == 0)

	print("GAME-LOOP-01 G2 isolated host/Continue/door/story/recovery smoke passed")
	quit()
