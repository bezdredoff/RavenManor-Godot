extends RefCounted

## GAME-LOOP-01A: isolated hotspot -> authored route -> Raven reducer boundary.
## No UI, save schema, new Match-3 session, or story gate definitions live here.
## Preview only: graph uses the historical greybox, never the unapproved 08B portal geometry.
const NavigationSource = preload("res://scripts/raven/manor_navigation_source.gd")
const Director = preload("res://scripts/raven/raven_slice_director.gd")
const Reducer = preload("res://scripts/raven/raven_reducer.gd")
const Store = preload("res://scripts/raven/raven_campaign_store.gd")

const HOTSPOT_STEPS := {"RM-HS-005": "access", "RM-HS-002": "restore1"}
const ACTION_STEPS := {"access": "level1", "restore1": "bedroom"}

var store: RefCounted
var state: Dictionary = {}
var graph
var session
var navigation = NavigationSource.new()
var _paused := false
var _requested := ""


func _init(storage_adapter: RefCounted = null, source_request: Dictionary = {}) -> void:
	store = Store.new(storage_adapter)
	state = store.load_campaign()
	navigation.select(source_request, state)
	graph = navigation.graph
	session = navigation.session


func reload() -> String:
	state = store.load_campaign()
	_requested = ""
	_paused = false
	return navigation.restore_routes(state)


func refresh() -> void:
	# When the existing VN/Match-3 UI closes, reread the one Raven store.
	# Do not reset an actor's confirmed feet on a presentation-only transition.
	state = store.load_campaign()
	navigation.refresh_routes(state)


func request_hotspot(hotspot_id: String) -> Dictionary:
	refresh()
	if session == null or _paused:
		return {"ok": false, "error": "navigation-source-unavailable" if session == null else "paused"}
	if not HOTSPOT_STEPS.has(hotspot_id):
		return {"ok": false, "error": "unmapped-hotspot"}
	if not _hotspot_available(hotspot_id):
		return {"ok": false, "error": "locked-hotspot"}
	var result: Dictionary = session.request_hotspot(hotspot_id)
	if result.get("ok", false):
		_requested = hotspot_id
	return result


func next_segment() -> Dictionary:
	if session == null or _paused:
		return {}
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
	if session == null or _paused:
		return {"ok": false, "error": "navigation-source-unavailable" if session == null else "paused"}
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
			navigation.refresh_routes(state)
	return result


func cancel() -> Dictionary:
	_requested = ""
	return session.cancel() if session != null else {"ok": true, "finishCurrentSegment": false}


func set_paused(value: bool) -> void:
	# Host pauses its existing mover too; no acknowledgement while paused.
	_paused = value


func interrupt_scene() -> Dictionary:
	# A closing scene never fabricates arrival or commits a pending action.
	# The next instance reloads from the last persisted safe anchor.
	return cancel()


func _still_available() -> bool:
	return _hotspot_available(_requested)


func _hotspot_available(hotspot_id: String) -> bool:
	return story_available(state, hotspot_id)


## Pure story-gate contract reused by G1's route session and the G2
## multi-room host. Movement/arrival must be verified by the caller first.
static func story_available(snapshot: Dictionary, hotspot_id: String) -> bool:
	return HOTSPOT_STEPS.has(hotspot_id) and \
		str(Director.next_step(snapshot).get("id", "")) == HOTSPOT_STEPS[hotspot_id] and \
		str(snapshot.get("hotspotStates", {}).get(hotspot_id, "")) not in ["cleared", "restored"]


## Prepare an atomic Raven reducer transaction, WITHOUT persisting or moving.
## Do not accept this proposal as evidence of arrival: only the gameplay host
## can authorize an observed actor at an authored interaction anchor.
static func story_arrival_proposal(snapshot: Dictionary, hotspot_id: String) -> Dictionary:
	if not story_available(snapshot, hotspot_id):
		return {"ok": false, "error": "no-longer-available"}
	var step_id: String = HOTSPOT_STEPS[hotspot_id]
	var proposed: Dictionary = snapshot.duplicate(true)
	for raw_event in Director.events_for(step_id):
		var event: Dictionary = raw_event.duplicate(true)
		event["eventId"] = "loop01a-%s-%s" % [step_id, str(event.get("type", ""))]
		var reduced: Dictionary = Reducer.apply(proposed, event)
		if not reduced.get("ok", false):
			return {"ok": false, "error": str(reduced.get("error", "reducer-rejected"))}
		proposed = reduced.state
	if str(Director.next_step(proposed).get("id", "")) != ACTION_STEPS[step_id]:
		return {"ok": false, "error": "unexpected-story-transition"}
	return {"ok": true, "state": proposed, "status": "action-committed",
		"hotspotId": hotspot_id, "nextStep": ACTION_STEPS[step_id],
		"presentation": "match3" if step_id == "access" else "vn"}


func _commit_arrival(hotspot_id: String) -> Dictionary:
	# The graph is not allowed to decide story availability or rewards.
	refresh()
	if hotspot_id != _requested or not _still_available():
		_requested = ""
		return {"ok": false, "error": "no-longer-available"}
	var destination: String = graph.interaction_anchor(hotspot_id)
	var current: String = session.current_anchor()
	if current != destination or destination.is_empty() or not session.in_flight_anchor().is_empty() \
			or str(graph.anchor(current).get("roomId", "")).is_empty() \
			or graph.route(session.checkpoint_event("arrival-probe").get("anchorId", ""), destination).is_empty():
		_requested = ""
		return {"ok": false, "error": "invalid-arrival-position"}
	var prepared: Dictionary = story_arrival_proposal(state, hotspot_id)
	if not bool(prepared.get("ok", false)):
		_requested = ""
		return prepared
	if not store.save_campaign(prepared.state):
		_requested = ""
		return {"ok": false, "error": "save-failed"}
	state = prepared.state
	navigation.refresh_routes(state)
	_requested = ""
	prepared.erase("state")
	return prepared
