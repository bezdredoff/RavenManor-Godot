extends SceneTree

## GAME-LOOP-01A: real authored RM IDs + actual Onoe legs, isolated memory save.
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
	var actor = Actor.instantiate()
	root.add_child(actor)
	await process_frame
	var memory = Memory.new()
	_seed(memory)
	var bridge = Bridge.new(memory)
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
	var cancelled = Bridge.new(cancelled_memory)
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
	var missing = Bridge.new(cancelled_memory, disconnected)
	assert(missing.request_hotspot("RM-HS-005").error == "unreachable")
	assert(missing.state.revision == Store.new(cancelled_memory).load_campaign().revision)

	# Failed atomic save: retry from physical hotspot; no partial flag/door writes.
	var failure = Bridge.new(cancelled_memory)
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
	var stale = Bridge.new(stale_memory)
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
