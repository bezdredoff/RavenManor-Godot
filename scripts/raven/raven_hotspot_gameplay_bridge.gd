extends RefCounted

## GAME-LOOP-01A: isolated hotspot -> authored route -> Raven reducer boundary.
## No UI, save schema, new Match-3 session, or story gate definitions live here.
## Preview only: graph uses the historical greybox, never the unapproved 08B portal geometry.
const Graph = preload("res://scripts/raven/manor_navigation_graph.gd")
const RouteSession = preload("res://scripts/raven/manor_route_session.gd")
const Director = preload("res://scripts/raven/raven_slice_director.gd")
const Reducer = preload("res://scripts/raven/raven_reducer.gd")
const Store = preload("res://scripts/raven/raven_campaign_store.gd")

const HOTSPOT_STEPS := {"RM-HS-005": "access", "RM-HS-002": "restore1"}
const ACTION_STEPS := {"access": "level1", "restore1": "bedroom"}

var store: RefCounted
var state: Dictionary = {}
var graph
var session
var _source: Dictionary = {}
var _requested := ""


func _init(storage_adapter: RefCounted = null, graph_override: Dictionary = {}) -> void:
	store = Store.new(storage_adapter)
	_source = graph_override.duplicate(true) if not graph_override.is_empty() else Graph.GRAPH_DATA.data
	graph = Graph.new()
	reload()


func reload() -> String:
	state = store.load_campaign()
	graph.rebuild(state, _source)
	session = RouteSession.new(graph)
	_requested = ""
	return session.restore(state)


func refresh() -> void:
	# When the existing VN/Match-3 UI closes, reread the one Raven store.
	# Do not reset an actor's confirmed feet on a presentation-only transition.
	state = store.load_campaign()
	graph.rebuild(state, _source)


func request_hotspot(hotspot_id: String) -> Dictionary:
	refresh()
	if not HOTSPOT_STEPS.has(hotspot_id):
		return {"ok": false, "error": "unmapped-hotspot"}
	if str(Director.next_step(state).get("id", "")) != HOTSPOT_STEPS[hotspot_id]:
		return {"ok": false, "error": "locked-hotspot"}
	var result: Dictionary = session.request_hotspot(hotspot_id)
	if result.get("ok", false):
		_requested = hotspot_id
	return result


func next_segment() -> Dictionary:
	refresh()
	if not _requested.is_empty() and not _still_available():
		cancel()
		return {"ok": false, "error": "no-longer-available"}
	var leg: Dictionary = session.next_segment()
	if leg.get("arrived", false):
		return _commit_arrival(str(leg.get("hotspotId", "")))
	return leg


func finish_segment(anchor_id: String) -> Dictionary:
	# This must be called by the visual host only after Onoe confirms contact.
	# Rebuild before acknowledgement, so a gate closed mid-leg blocks crossing.
	refresh()
	var result: Dictionary = session.finish_segment(anchor_id)
	if not result.get("ok", false):
		_requested = ""
		return result
	if result.get("status") == "arrived":
		return _commit_arrival(str(result.get("hotspotId", "")))
	if str(graph.anchor(session.current_anchor()).get("kind", "")) == "safe":
		var checkpoint: Dictionary = session.checkpoint_event("loop01a-position-%s-%d" % [
			session.current_anchor(), int(state.get("revision", 0))])
		if not checkpoint.is_empty():
			var applied: Dictionary = Reducer.apply(state, checkpoint)
			if not applied.get("ok", false) or not store.save_campaign(applied.state):
				cancel()
				return {"ok": false, "error": "checkpoint-save-failed"}
			state = applied.state
			graph.rebuild(state, _source)
	return result


func cancel() -> Dictionary:
	_requested = ""
	return session.cancel()


func interrupt_scene() -> Dictionary:
	# A closing scene never fabricates arrival or commits a pending action.
	# The next instance reloads from the last persisted safe anchor.
	return cancel()


func _still_available() -> bool:
	return HOTSPOT_STEPS.has(_requested) and \
		str(Director.next_step(state).get("id", "")) == HOTSPOT_STEPS[_requested]


func _commit_arrival(hotspot_id: String) -> Dictionary:
	# The graph is not allowed to decide story availability or rewards.
	refresh()
	if hotspot_id != _requested or not _still_available():
		_requested = ""
		return {"ok": false, "error": "no-longer-available"}
	var step_id: String = HOTSPOT_STEPS[hotspot_id]
	var proposed: Dictionary = state.duplicate(true)
	for raw_event in Director.events_for(step_id):
		var event: Dictionary = raw_event.duplicate(true)
		event["eventId"] = "loop01a-%s-%s" % [step_id, str(event.get("type", ""))]
		var reduced: Dictionary = Reducer.apply(proposed, event)
		if not reduced.get("ok", false):
			_requested = ""
			return {"ok": false, "error": str(reduced.get("error", "reducer-rejected"))}
		proposed = reduced.state
	if str(Director.next_step(proposed).get("id", "")) != ACTION_STEPS[step_id]:
		_requested = ""
		return {"ok": false, "error": "unexpected-story-transition"}
	if not store.save_campaign(proposed):
		_requested = ""
		return {"ok": false, "error": "save-failed"}
	state = proposed
	graph.rebuild(state, _source)
	_requested = ""
	return {"ok": true, "status": "action-committed", "hotspotId": hotspot_id,
		"nextStep": ACTION_STEPS[step_id],
		"presentation": "match3" if step_id == "access" else "vn"}
