extends SceneTree

## GAME-LOOP-01A: real authored RM IDs + actual Onoe legs, isolated memory save.
const NavigationSource = preload("res://scripts/raven/manor_navigation_source.gd")
const Bridge = preload("res://scripts/raven/raven_hotspot_gameplay_bridge.gd")
const Snapshot = preload("res://scripts/raven/raven_snapshot.gd")
const Store = preload("res://scripts/raven/raven_campaign_store.gd")
const Reducer = preload("res://scripts/raven/raven_reducer.gd")
const Director = preload("res://scripts/raven/raven_slice_director.gd")
const Match3Session = preload("res://scripts/raven/raven_match3_session.gd")
const VN = preload("res://scripts/raven/raven_vn_player.gd")
const CatalogAdapter = preload("res://scripts/raven/raven_vn_catalog_adapter.gd")
const ReadHistory = preload("res://scripts/raven/raven_vn_read_history.gd")
const Content = preload("res://data/raven/rm_vs_01_content.json")
const Memory = preload("res://tests/support/memory_storage.gd")
const Actor = preload("res://scenes/raven/tests/onoe_segment_actor.tscn")


func _initialize() -> void:
	call_deferred("_run")


func _seed(adapter: RefCounted) -> void:
	var state: Dictionary = Snapshot.fresh()
	for beat in ["RM-BEAT-00-01", "RM-BEAT-00-02", "RM-BEAT-00-03", "RM-BEAT-01-01"]:
		var outcome: Dictionary = Reducer.apply(state, {
			"eventId": "loop01a-fixture-" + beat,
			"type": "story_beat_seen", "storyBeatId": beat})
		assert(outcome.get("ok", false))
		state = outcome.state
	assert(Store.new(adapter).save_campaign(state))


func _walk(bridge, actor) -> Dictionary:
	for unused in range(24):
		var leg: Dictionary = bridge.next_segment()
		if leg.has("presentation"):
			return leg
		assert(leg.has("toAnchorId"), "Only authored physical legs are accepted")
		assert(actor.position.distance_to(leg.fromPosition) < 0.01)
		assert(actor.start_segment(leg))
		actor.advance(30.0)
		assert(not actor.has_active_segment() and actor.position.distance_to(leg.toPosition) < 0.01)
		var outcome: Dictionary = bridge.finish_segment(str(leg.toAnchorId))
		assert(outcome.get("ok", false), str(outcome))
		if outcome.has("presentation"):
			return outcome
	return {}


func _run() -> void:
	_source_regressions()
	# Exercise the actual playable QA scene as well as the pure bridge below.
	# This catches scene parse/instantiation, in-memory injection and real
	# vertical_slice Match-3 UI handoff (not just static source checks).
	var qa_scene: PackedScene = load("res://scenes/raven/tests/game_loop_01a_qa_harness.tscn")
	assert(qa_scene != null)
	var qa = qa_scene.instantiate()
	root.add_child(qa)
	await process_frame
	assert(qa.bridge != null and qa.memory != null)
	assert(qa.bridge.state.storyBeatsSeen.has("RM-BEAT-01-01"))
	assert(qa.actor.position == qa.bridge.graph.position("RM-NAV-HALL-SPAWN"))
	qa._request("RM-HS-005")
	var qa_hops := 0
	while qa.actor.has_active_segment() and qa_hops < 16:
		qa.actor.advance(30.0)
		qa_hops += 1
	assert(qa_hops > 0 and qa_hops < 16)
	assert(is_instance_valid(qa.gameplay), "Arrival opens existing playable gameplay overlay")
	assert(qa.gameplay.step.id == "level1")
	assert(qa.gameplay.store == qa.bridge.store, "No competing campaign state")
	qa._close_gameplay()
	qa.queue_free()
	await process_frame

	var actor = Actor.instantiate()
	root.add_child(actor)
	await process_frame
	var memory = Memory.new()
	_seed(memory)
	var bridge = Bridge.new(memory, NavigationSource.historical_qa_request())
	actor.position = bridge.graph.position(bridge.session.current_anchor())
	assert(Director.next_step(bridge.state).id == "access")
	assert(bridge.request_hotspot("RM-HS-002").error == "locked-hotspot")
	assert(bridge.request_hotspot("RM-HS-004").error == "unmapped-hotspot")
	assert(bridge.request_hotspot("RM-HS-005").ok)
	assert(not bridge.state.storyFlags.has("RM-FLAG-BEDROOM-ACCESS-CLEARED"))
	var first: Dictionary = bridge.next_segment()
	assert(first.toAnchorId == "RM-NAV-HALL-CORRIDOR-NEAR")
	assert(bridge.next_segment().is_empty(), "One physical leg at a time")
	assert(actor.start_segment(first))
	actor.advance(30.0)
	assert(not actor.has_active_segment())
	assert(bridge.finish_segment(str(first.toAnchorId)).ok)
	var access: Dictionary = _walk(bridge, actor)
	assert(access.get("nextStep") == "level1" and access.get("presentation") == "match3")
	assert(bridge.state.storyFlags.has("RM-FLAG-BEDROOM-ACCESS-CLEARED"))
	assert(bridge.state.unlockedDoors.has("RM-DOOR-CORRIDOR-BEDROOM"))
	assert(bridge.state.hotspotStates.get("RM-HS-005") == "cleared")
	assert(not bridge.request_hotspot("RM-HS-005").ok, "No replay after action commit")
	assert(not bridge.request_hotspot("RM-HS-002").ok, "No restoration before work preparation")

	# Handoff to the pre-existing Match-3 session/reducer. Other game-loop
	# characterization tests prove a genuinely played board and failed-win retry.
	var level: Dictionary = {}
	for candidate in Content.data.levels:
		if candidate.id == "RM-LVL-001":
			level = candidate
	assert(not level.is_empty())
	var game = Match3Session.open(level, bridge.state, Callable())
	assert(game != null)
	var won: Dictionary = Match3Session.complete(null, bridge.state,
		"level1", "RM-LVL-001", 1, bridge.store)
	assert(won.get("ok", false))
	var second: Dictionary = Match3Session.complete(null, won.state,
		"level1", "RM-LVL-001", 2, bridge.store)
	assert(second.get("ok", false) and second.state.workPoints == 2)
	bridge.refresh()
	assert(Director.next_step(bridge.state).id == "restore1")
	assert(bridge.request_hotspot("RM-HS-002").ok)
	var restore: Dictionary = _walk(bridge, actor)
	assert(restore.get("presentation") == "vn" and restore.get("nextStep") == "bedroom")
	assert(bridge.state.completedRestorations.has("RM-REST-001"))
	assert(bridge.state.hotspotStates.get("RM-HS-002") == "restored")
	assert(bridge.state.workPoints == 0, "Exactly 2 earned and 2 spent, once")
	assert(not bridge.request_hotspot("RM-HS-002").ok)
	assert(bridge.reload() == "RM-NAV-BEDROOM-CENTER")
	assert(bridge.state.completedRestorations.size() == 1)

	# VN shell adapter retains actual RM-BEAT-01-02 in every existing locale.
	for locale in ["ru", "be", "en"]:
		var config: Dictionary = CatalogAdapter.for_legacy(Content.data.vnScenes.bedroom, locale)
		assert(config.beatId == "RM-BEAT-01-02" and not config.lines.is_empty())
		var player = VN.new()
		player.open(config)
		assert(not player.current_line().is_empty())
		assert(ReadHistory.skip_target(config, 0, []) == 0, "Unread lines cannot be skipped")

	# Cancel and scene interruption: finish current physical segment but do
	# not mark hotspot used, and reload starts at a persisted safe anchor.
	var cancelled_memory = Memory.new()
	_seed(cancelled_memory)
	var cancelled = Bridge.new(cancelled_memory, NavigationSource.historical_qa_request())
	actor.position = cancelled.graph.position(cancelled.session.current_anchor())
	assert(cancelled.request_hotspot("RM-HS-005").ok)
	var cancelled_leg: Dictionary = cancelled.next_segment()
	assert(actor.start_segment(cancelled_leg))
	assert(cancelled.interrupt_scene().finishCurrentSegment)
	actor.advance(30.0)
	assert(cancelled.finish_segment(str(cancelled_leg.toAnchorId)).status == "cancelled")
	assert(not cancelled.state.storyFlags.has("RM-FLAG-BEDROOM-ACCESS-CLEARED"))
	assert(cancelled.reload() == "RM-NAV-HALL-SPAWN")
	assert(cancelled.session.pending_hotspot().is_empty())

	# Missing authored edge blocks the request, without teleport or story write.
	var disconnected: Dictionary = load("res://data/raven/manor_greybox_graph.json").data.duplicate(true)
	var edges: Array = []
	for e in disconnected.edges:
		if str(e.get("to", "")) != "RM-NAV-HS-005":
			edges.append(e)
	disconnected.edges = edges
	var missing = Bridge.new(cancelled_memory, NavigationSource.historical_qa_request(disconnected))
	assert(missing.request_hotspot("RM-HS-005").error == "unreachable")
	assert(missing.state.revision == Store.new(cancelled_memory).load_campaign().revision)

	# Failed atomic save: retry from physical hotspot; no partial flag/door writes.
	var failure = Bridge.new(cancelled_memory, NavigationSource.historical_qa_request())
	actor.position = failure.graph.position(failure.session.current_anchor())
	assert(failure.request_hotspot("RM-HS-005").ok)
	var failed := false
	for unused in range(24):
		var leg: Dictionary = failure.next_segment()
		assert(leg.has("toAnchorId"))
		assert(actor.start_segment(leg))
		actor.advance(30.0)
		if leg.toAnchorId == "RM-NAV-HS-005":
			cancelled_memory.fail_write = true
		var outcome: Dictionary = failure.finish_segment(str(leg.toAnchorId))
		if leg.toAnchorId == "RM-NAV-HS-005":
			assert(outcome.error == "save-failed")
			failed = true
			break
		assert(outcome.ok)
	assert(failed)
	assert(not Store.new(cancelled_memory).load_campaign().storyFlags.has("RM-FLAG-BEDROOM-ACCESS-CLEARED"))
	cancelled_memory.fail_write = false
	assert(failure.request_hotspot("RM-HS-005").ok)
	assert(failure.next_segment().get("nextStep") == "level1")
	assert(Store.new(cancelled_memory).load_campaign().storyFlags.has("RM-FLAG-BEDROOM-ACCESS-CLEARED"))

	# Arrival-time availability must be rechecked against current store,
	# not the story snapshot captured when movement was requested.
	var stale_memory = Memory.new()
	_seed(stale_memory)
	var stale = Bridge.new(stale_memory, NavigationSource.historical_qa_request())
	actor.position = stale.graph.position(stale.session.current_anchor())
	assert(stale.request_hotspot("RM-HS-005").ok)
	var rejected := false
	for unused in range(24):
		var leg: Dictionary = stale.next_segment()
		assert(leg.has("toAnchorId"))
		assert(actor.start_segment(leg))
		actor.advance(30.0)
		if leg.toAnchorId == "RM-NAV-HS-005":
			var external: Dictionary = Store.new(stale_memory).load_campaign()
			for raw in Director.events_for("access"):
				var e: Dictionary = raw.duplicate(true)
				e.eventId = "loop01a-external-" + str(e.type)
				external = Reducer.apply(external, e).state
			assert(Store.new(stale_memory).save_campaign(external))
			var response: Dictionary = stale.finish_segment(str(leg.toAnchorId))
			assert(not response.ok and response.error == "no-longer-available")
			rejected = true
			break
		assert(stale.finish_segment(str(leg.toAnchorId)).ok)
	assert(rejected)
	actor.queue_free()
	print("Raven GAME-LOOP-01A hotspot-to-gameplay bridge smoke passed")
	quit()


func _source_regressions() -> void:
	var memory = Memory.new()
	_seed(memory)
	var before: Dictionary = Store.new(memory).load_campaign()
	var production := {"schemaVersion": 1, "kind": NavigationSource.REQUEST_KIND, "mode": "production", "worldPlan": NavigationSource.WORLD_PLAN.data}
	for request in [{}, {"mode": "qa"}, production,
			{"schemaVersion": 1, "kind": NavigationSource.REQUEST_KIND, "mode": "qa"},
			{"schemaVersion": 1, "kind": NavigationSource.REQUEST_KIND, "mode": "qa",
			"allowQaCandidate": true, "qaSourceKind": "invalid"}]:
		var blocked = Bridge.new(memory, request)
		assert(blocked.session == null and blocked.graph == null)
		assert(not blocked.request_hotspot("RM-HS-005").ok)
		assert(blocked.next_segment().is_empty())
		assert(not blocked.finish_segment("RM-NAV-HS-005").ok)
		assert(blocked.cancel().ok and blocked.reload().is_empty())
		assert(Store.new(memory).load_campaign() == before, "Rejected source never writes")
	assert(NavigationSource.resolve(production).status == "unavailable_geometry")
	var malformed := NavigationSource.historical_qa_request()
	malformed.qaGraph = {"anchors": [null], "edges": []}
	assert(not Bridge.new(memory, malformed).navigation.selection.ok)
	malformed.qaGraph = {"anchors": [], "edges": []}
	assert(not Bridge.new(memory, malformed).navigation.selection.ok)
	var request := NavigationSource.historical_qa_request()
	var bridge = Bridge.new(memory, request)
	assert(bridge.navigation.selection.mode == "qa" and bridge.navigation.selection.approval == "TEST_ONLY")
	var graph = bridge.graph
	var session = bridge.session
	request.mode = "production"
	assert(not bridge.navigation.select(production, before), "One selection per session")
	assert(bridge.request_hotspot("RM-HS-005").ok)
	var revision: int = bridge.state.revision
	assert(bridge.request_hotspot("RM-HS-005").status == "unchanged")
	var leg: Dictionary = bridge.next_segment()
	assert(bridge.request_hotspot("RM-HS-005").status == "unchanged")
	bridge.set_paused(true)
	assert(bridge.next_segment().is_empty())
	assert(bridge.finish_segment(str(leg.toAnchorId)).error == "paused")
	assert(bridge.request_hotspot("RM-HS-005").error == "paused")
	assert(bridge.state.revision == revision)
	bridge.set_paused(false)
	assert(bridge.finish_segment(str(leg.toAnchorId)).ok)
	var checkpoint_revision: int = bridge.state.revision
	assert(not bridge.finish_segment(str(leg.toAnchorId)).ok)
	assert(bridge.state.revision == checkpoint_revision, "Duplicate ack has no checkpoint")
	bridge.cancel()
	bridge.refresh()
	bridge.reload()
	assert(bridge.graph == graph and bridge.session == session, "Refresh/reload reuse one source session")
	assert(not bridge.state.storyFlags.has("RM-FLAG-BEDROOM-ACCESS-CLEARED"))

	# A fixture gates the access interaction itself, so both request-time and
	# final-segment checks exercise the actual graph door rule (not story gating).
	var gated: Dictionary = load("res://data/raven/manor_greybox_graph.json").data.duplicate(true)
	for edge in gated.edges:
		if str(edge.to) == "RM-NAV-HS-005":
			edge.doorId = "RM-DOOR-CORRIDOR-BEDROOM"
	var locked = Bridge.new(memory, NavigationSource.historical_qa_request(gated))
	assert(locked.request_hotspot("RM-HS-005").error == "unreachable")
	var unlocked: Dictionary = Reducer.apply(before, {"eventId": "g1-test-unlock",
		"type": "door_unlock", "doorId": "RM-DOOR-CORRIDOR-BEDROOM"}).state
	assert(Store.new(memory).save_campaign(unlocked))
	var crossing = Bridge.new(memory, NavigationSource.historical_qa_request(gated))
	assert(crossing.request_hotspot("RM-HS-005").ok)
	var blocked_arrival := false
	for unused in range(24):
		var step: Dictionary = crossing.next_segment()
		assert(step.has("toAnchorId"))
		if step.toAnchorId == "RM-NAV-HS-005":
			var closed: Dictionary = Store.new(memory).load_campaign()
			closed.unlockedDoors.erase("RM-DOOR-CORRIDOR-BEDROOM")
			assert(Store.new(memory).save_campaign(closed))
			var rejected: Dictionary = crossing.finish_segment(str(step.toAnchorId))
			assert(rejected.error == "segment-blocked")
			assert(not crossing.state.storyFlags.has("RM-FLAG-BEDROOM-ACCESS-CLEARED"))
			blocked_arrival = true
			break
		assert(crossing.finish_segment(str(step.toAnchorId)).ok)
	assert(blocked_arrival)

	# Invalid persisted positions get existing authored, reachable safe points;
	# loading never persists an invented room/anchor or modifies the snapshot.
	var stale_hotspot_memory = Memory.new()
	_seed(stale_hotspot_memory)
	var stale_hotspot = Bridge.new(stale_hotspot_memory, NavigationSource.historical_qa_request())
	assert(stale_hotspot.request_hotspot("RM-HS-005").ok)
	var changed: Dictionary = Reducer.apply(stale_hotspot.state, {"eventId": "g1-hotspot-changed",
		"type": "hotspot_state", "hotspotId": "RM-HS-005", "state": "cleared"}).state
	assert(Store.new(stale_hotspot_memory).save_campaign(changed))
	assert(stale_hotspot.next_segment().error == "no-longer-available")
	assert(Store.new(stale_hotspot_memory).load_campaign() == changed)
	var invalid_room: Dictionary = gated.duplicate(true)
	invalid_room.anchors[0].roomId = "RM-ROOM-BEDROOM"
	assert(not Bridge.new(memory, NavigationSource.historical_qa_request(invalid_room)).navigation.selection.ok)
	var navigation = NavigationSource.new()
	var invalid := before.duplicate(true)
	invalid.lastRoomId = "UNKNOWN-ROOM"
	invalid.lastSafeAnchorId = "UNKNOWN-ANCHOR"
	assert(navigation.select(NavigationSource.historical_qa_request(), invalid))
	var start: String = navigation.session.current_anchor()
	assert(navigation.graph.has_anchor(start))
	assert(navigation.graph.anchor(start).kind == "safe")
	assert(invalid.lastRoomId == "UNKNOWN-ROOM" and invalid.lastSafeAnchorId == "UNKNOWN-ANCHOR")
	invalid.lastRoomId = "RM-ROOM-HALL"
	invalid.lastSafeAnchorId = "RM-NAV-HS-005"
	assert(navigation.restore_routes(invalid) == "RM-NAV-HALL-SPAWN")
