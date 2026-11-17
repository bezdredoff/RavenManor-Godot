extends Node2D
## GAME-LOOP-01 G2: one gameplay/save orchestration boundary over the existing
## map transition harness, Raven reducer/store and VN/Match-3 vertical slice.
## No authored geometry, new mover, second save or free tap-to-move.
##
## A QA session REQUIRES an injected isolated storage adapter. Its room/anchor
## checkpoints are never written to production user:// storage. The canonical
## navigation source stays fail-closed until real HC/CB approval.

const Source = preload("res://scripts/raven/manor_navigation_source.gd")
const MapHarness = preload("res://scripts/raven/manor_gameplay_integration_harness.gd")
const Bridge = preload("res://scripts/raven/raven_hotspot_gameplay_bridge.gd")
const Store = preload("res://scripts/raven/raven_campaign_store.gd")
const Director = preload("res://scripts/raven/raven_slice_director.gd")
const Reducer = preload("res://scripts/raven/raven_reducer.gd")
const Ids = preload("res://scripts/raven/raven_ids.gd")
const Slice = preload("res://scenes/raven/vertical_slice.tscn")

signal room_changed(room: Dictionary)
signal story_action_ready(result: Dictionary)
signal save_refused(reason: String)

const FOOT_TOLERANCE := 0.25

var store: RefCounted
var state: Dictionary = {}
var source: Dictionary = {}
var navigation
var last_error := ""

var _isolated_qa_storage := false
var _request: Dictionary = {}
var _story_bindings: Dictionary = {}
var _transition_doors: Dictionary = {}
var _pending_story := ""
var _pending_map_hotspot := ""
var _pending_transition := ""
var _presentation_step := ""
var _presentation: Control
var _paused := false
var _held := false


func _init(storage_adapter: RefCounted = null, isolated_qa_storage: bool = false) -> void:
	store = Store.new(storage_adapter)
	_isolated_qa_storage = isolated_qa_storage and storage_adapter != null


## The host does NOT accept externally supplied source results. Always resolve
## the canonical source; arbitrary "PRODUCTION_APPROVED" fixture dictionaries
## may only be used in isolated Source/MapHarness unit tests, never here.
func configure(request: Dictionary) -> Dictionary:
	if navigation != null:
		return _error("already-configured")
	if str(request.get("mode", "")) == Source.MODE_PRODUCTION and request.has("worldPlan"):
		return _error("injected-production-plan-forbidden")
	if str(request.get("mode", "")) == Source.MODE_QA and not _isolated_qa_storage:
		return _error("qa-requires-isolated-storage")
	var loaded: Dictionary = _load_state()
	if not loaded.get("ok", false):
		return loaded
	var resolved: Dictionary = Source.resolve(request.merged({"snapshot": state.duplicate(true)}, true))
	if not bool(resolved.get("ok", false)) or not bool(resolved.get("movementEnabled", false)):
		return _error(str(resolved.get("status", "unavailable_navigation")) + ":" + str(resolved.get("reason", "")))
	if str(request.get("mode", "")) == Source.MODE_PRODUCTION and (resolved.get("draftOnly", true) or
			str(resolved.get("approval", "")) != Source.PRODUCTION_APPROVAL):
		return _error("production-approval-missing")
	if str(request.get("mode", "")) == Source.MODE_QA and (not resolved.get("draftOnly", false) or
			str(resolved.get("approval", "")) != "TEST_ONLY"):
		return _error("qa-source-not-test-only")
	var binding_error := _validate_bindings(request, resolved)
	if not binding_error.is_empty():
		return _error(binding_error)
	if str(request.get("mode", "")) == Source.MODE_QA:
		# A fresh QA resolution intentionally ignores *production* saves. Only
		# this explicitly isolated adapter may restore its own TEST_ONLY anchors.
		var safe: Dictionary = Source.resolve_snapshot_start(resolved, state)
		if not bool(safe.get("ok", false)):
			return _error("qa-safe-start-unavailable")
		resolved.initialRoomId = str(safe.roomId)
		resolved.initialAnchorId = str(safe.anchorId)
		resolved.savedPositionApplied = bool(safe.savedPositionApplied)
	_request = request.duplicate(true)
	source = resolved
	navigation = MapHarness.new()
	add_child(navigation)
	if not navigation.configure(source, state):
		var reason := str(navigation.error_text)
		navigation.queue_free()
		navigation = null
		source = {}
		return _error("map-harness:" + reason)
	_story_bindings = request.get("qaStoryHotspots", {}).duplicate(true) if source.draftOnly else {}
	_transition_doors = request.get("qaTransitionDoors", {}).duplicate(true) if source.draftOnly else {}
	_pending_story = ""
	_pending_map_hotspot = ""
	_pending_transition = ""
	_presentation_step = ""
	_paused = false
	_held = false
	last_error = ""
	return {"ok": true, "status": "ready", "approval": source.approval,
		"draftOnly": source.draftOnly, "roomId": navigation.controller.room_id(),
		"anchorId": navigation.controller.confirmed_anchor(), "activity": current_activity()}


func _validate_bindings(request: Dictionary, resolved: Dictionary) -> String:
	if request.get("qaStoryHotspots", {}) is not Dictionary or request.get("qaTransitionDoors", {}) is not Dictionary:
		return "invalid-qa-bindings"
	if not bool(resolved.get("draftOnly", true)):
		if not request.get("qaStoryHotspots", {}).is_empty() or not request.get("qaTransitionDoors", {}).is_empty():
			return "qa-bindings-forbidden-in-production"
		return ""
	var hotspots: Dictionary = {}
	var transitions: Dictionary = {}
	for room in resolved.contract.get("rooms", []):
		for anchor in room.get("graph", {}).get("anchors", []):
			var id := str(anchor.get("hotspotId", ""))
			if not id.is_empty():
				hotspots[id] = true
	for descriptor in resolved.contract.get("transitions", []):
		transitions[str(descriptor.get("id", ""))] = true
	for id in request.get("qaStoryHotspots", {}):
		var map_id := str(request.qaStoryHotspots[id])
		if not Bridge.HOTSPOT_STEPS.has(id) or not hotspots.has(map_id):
			return "unknown-story-hotspot-binding:" + str(id)
	for id in request.get("qaTransitionDoors", {}):
		var door_id := str(request.qaTransitionDoors[id])
		if not transitions.has(id) or not Ids.is_known("doors", door_id):
			return "unknown-transition-door-binding:" + str(id)
	return ""


func current_activity() -> Dictionary:
	return Director.next_step(state) if not state.is_empty() else {}


func room_state() -> Dictionary:
	return navigation.room_state() if navigation != null else {}


func request_story_hotspot(hotspot_id: String) -> Dictionary:
	if not _can_accept_input():
		return _error("host-not-ready")
	if not _pending_story.is_empty() or not _pending_transition.is_empty() or not _presentation_step.is_empty():
		return _error("action-already-pending")
	var loaded := _load_state()
	if not loaded.get("ok", false):
		return loaded
	if not Bridge.story_available(state, hotspot_id):
		return _error("locked-hotspot")
	var map_id := str(_story_bindings.get(hotspot_id, hotspot_id))
	var graph = navigation.controller.room_graph(navigation.controller.room_id())
	if graph == null or graph.interaction_anchor(map_id).is_empty():
		return _error("hotspot-not-in-current-room")
	var outcome: Dictionary = navigation.request_hotspot(map_id)
	if bool(outcome.get("ok", false)):
		_pending_story = hotspot_id
		_pending_map_hotspot = map_id
	return outcome


func request_transition(transition_id: String) -> Dictionary:
	if not _can_accept_input():
		return _error("host-not-ready")
	if not _pending_story.is_empty() or not _pending_transition.is_empty() or not _presentation_step.is_empty():
		return _error("action-already-pending")
	var loaded := _load_state()
	if not loaded.get("ok", false):
		return loaded
	var door_error := _door_gate_error(transition_id)
	if not door_error.is_empty():
		return _error(door_error)
	var result: Dictionary = navigation.request_transition(transition_id)
	if bool(result.get("ok", false)):
		_pending_transition = transition_id
	return result


## Called during gameplay ticks; no other code may acknowledge a segment.
## The underlying harness retains the inherited actor API and footpoint checks.
func advance(delta: float = 0.05) -> Dictionary:
	if not _can_accept_input():
		return _error("host-not-ready")
	var loaded := _load_state()
	if not loaded.get("ok", false):
		return loaded
	if not _pending_story.is_empty() and not Bridge.story_available(state, _pending_story):
		var stop_story: Dictionary = cancel()
		if bool(stop_story.get("finishCurrentSegment", false)):
			return {"ok": true, "status": "cancel-finishing-current-leg",
				"reason": "no-longer-available"}
		return _error("no-longer-available")
	if not _pending_transition.is_empty() and not _door_gate_error(_pending_transition).is_empty():
		var stop_transition: Dictionary = cancel()
		if bool(stop_transition.get("finishCurrentSegment", false)):
			return {"ok": true, "status": "cancel-finishing-current-leg",
				"reason": "door-gate-changed"}
		return _error("door-gate-changed")
	var result: Dictionary = navigation.advance(delta)
	if not result.get("ok", false):
		_pending_story = ""
		_pending_map_hotspot = ""
		_pending_transition = ""
		return result
	var status := str(result.get("status", ""))
	if status == "arrived" and not _pending_story.is_empty():
		return _commit_story_arrival(str(result.get("hotspotId", _pending_map_hotspot)))
	if status == "continue" or status == "cancelled" or status == "arrived":
		var checkpoint := checkpoint_safe_anchor()
		if not checkpoint.get("ok", false):
			return checkpoint
	return result


func drive(max_steps: int = 4000, delta: float = 0.05) -> Dictionary:
	var result: Dictionary = {}
	for _i in range(max_steps):
		result = advance(delta)
		if not result.get("ok", false):
			return result
		if str(result.get("status", "")) in ["idle", "arrived", "ready", "action-committed"]:
			return result
	return _error("movement-did-not-settle")


func commit_ready_transition() -> Dictionary:
	if not _can_accept_input() or _pending_transition.is_empty():
		return _error("no-pending-transition")
	var loaded := _load_state()
	if not loaded.get("ok", false):
		return loaded
	var gate_error := _door_gate_error(_pending_transition)
	if not gate_error.is_empty():
		cancel()
		return _error(gate_error)
	if navigation.controller.ready_transition() != _pending_transition:
		return _error("transition-not-physically-ready")
	var result: Dictionary = navigation.commit_transition()
	if not result.get("ok", false):
		return result
	_pending_transition = ""
	# The entry is a validated safe anchor; do NOT save the approach portal.
	var checkpoint := checkpoint_safe_anchor()
	if not checkpoint.get("ok", false):
		return checkpoint
	room_changed.emit(navigation.room_state())
	return result


func checkpoint_safe_anchor() -> Dictionary:
	if navigation == null or navigation.actor.has_active_segment() or not navigation.controller.ready_transition().is_empty():
		return _error("unsafe-checkpoint-state")
	var room := navigation.controller.room_id()
	var anchor := navigation.controller.confirmed_anchor()
	var graph = navigation.controller.room_graph(room)
	if graph == null or not graph.has_anchor(anchor) or str(graph.anchor(anchor).get("kind", "")) != "safe":
		return {"ok": true, "status": "non-safe-anchor-skipped"}
	if navigation.actor.position.distance_to(graph.position(anchor)) > FOOT_TOLERANCE:
		return _error("checkpoint-physical-footpoint-mismatch")
	if state.get("lastRoomId") == room and state.get("lastSafeAnchorId") == anchor:
		return {"ok": true, "status": "already-checkpointed"}
	var event := {"eventId": "game-loop-g2-position-%d-%s-%s" % [int(state.get("revision", 0)), room, anchor],
		"type": "position_checkpoint", "roomId": room, "anchorId": anchor}
	var result: Dictionary = Reducer.apply(state, event)
	if not result.get("ok", false):
		return _error("checkpoint-reducer-rejected")
	if not store.save_campaign(result.state):
		return _save_failure("checkpoint-write-failed")
	state = result.state
	return {"ok": true, "status": "checkpointed", "roomId": room, "anchorId": anchor}


func _commit_story_arrival(map_hotspot: String) -> Dictionary:
	var story_id := _pending_story
	var expected := _pending_map_hotspot
	_pending_story = ""
	_pending_map_hotspot = ""
	if expected != map_hotspot or story_id.is_empty() or navigation.actor.has_active_segment():
		return _error("unexpected-story-arrival")
	var room := navigation.controller.room_id()
	var anchor := navigation.controller.confirmed_anchor()
	var graph = navigation.controller.room_graph(room)
	if graph == null or graph.interaction_anchor(map_hotspot) != anchor or \
			navigation.actor.position.distance_to(graph.position(anchor)) > FOOT_TOLERANCE:
		return _error("story-arrival-footpoint-mismatch")
	var loaded := _load_state()
	if not loaded.get("ok", false):
		return loaded
	var proposal: Dictionary = Bridge.story_arrival_proposal(state, story_id)
	if not proposal.get("ok", false):
		return proposal
	if not store.save_campaign(proposal.state):
		return _save_failure("story-write-failed")
	state = proposal.state
	_presentation_step = str(proposal.nextStep)
	proposal.erase("state")
	story_action_ready.emit(proposal.duplicate(true))
	return proposal


func _door_gate_error(transition_id: String) -> String:
	var item: Dictionary = {}
	for descriptor in source.get("contract", {}).get("transitions", []):
		if str(descriptor.get("id", "")) == transition_id:
			item = descriptor
			break
	if item.is_empty():
		return "unknown-transition"
	if str(item.get("sourceRoomId", "")) != navigation.controller.room_id():
		return "wrong-transition-room"
	if str(item.get("authority", "")) == "QA_VIRTUAL":
		return "virtual-portal-not-playable"
	var door_id := str(_transition_doors.get(transition_id, item.get("doorId", "")))
	if door_id.is_empty():
		return "transition-missing-door"
	# All production doors are catalogued RM IDs. QA virtual fixture doors
	# require an explicit stable RM gate mapping, never an implicit unlock.
	if source.draftOnly and not _transition_doors.has(transition_id):
		return "qa-door-binding-required"
	if not state.get("unlockedDoors", []).has(door_id):
		return "locked-door"
	return ""


## Present the existing vertical slice (VN & UPDS Match-3), with exactly the
## same Raven store. The map host owns no copy of its cursor or board state.
func mount_presentation(parent: Node) -> Control:
	if not _can_accept_input() or is_instance_valid(_presentation):
		return null
	var activity := current_activity()
	if str(activity.get("kind", "")) not in ["vn", "match3"]:
		return null
	if not _presentation_step.is_empty() and str(activity.get("id", "")) != _presentation_step:
		return null
	_presentation = Slice.instantiate()
	_presentation.store = store
	parent.add_child(_presentation)
	return _presentation


func close_presentation() -> Dictionary:
	if is_instance_valid(_presentation):
		_presentation.queue_free()
	_presentation = null
	var loaded := _load_state()
	if not loaded.get("ok", false):
		return loaded
	# If Match-3 or VN was dismissed early the activity remains pending, and
	# opening the same existing UI again resumes its saved cursor/board.
	_presentation_step = ""
	return {"ok": true, "status": "presentation-closed", "activity": current_activity()}


func cancel() -> Dictionary:
	_pending_story = ""
	_pending_map_hotspot = ""
	_pending_transition = ""
	return navigation.cancel_request() if navigation != null else {"ok": true, "finishCurrentSegment": false}


func set_paused(value: bool) -> void:
	_paused = value
	if navigation == null or not is_instance_valid(navigation.actor):
		return
	if navigation.actor.has_active_segment():
		if value:
			navigation.actor.pause_segment()
		else:
			navigation.actor.resume_segment()


## Continue always rebuilds the room graph and physical actor from persisted
## safe ground. No in-flight/portal anchor can become a confirmed save point.
func reload_session() -> Dictionary:
	if navigation != null and navigation.actor.has_active_segment():
		return _error("reload-refused-in-flight")
	if is_instance_valid(_presentation):
		return _error("close-presentation-first")
	if _request.is_empty():
		return _error("not-configured")
	if navigation != null:
		navigation.queue_free()
		navigation = null
	var request := _request.duplicate(true)
	_pending_story = ""
	_pending_map_hotspot = ""
	_pending_transition = ""
	_presentation_step = ""
	_held = false
	_paused = false
	return configure(request)


func _load_state() -> Dictionary:
	var loaded: Dictionary = store.load_campaign()
	var report: Dictionary = store.last_load_report
	if str(report.get("detail", "")) == "storage-read-failed" or str(report.get("status", "")) == "recovered-corrupt":
		return _save_failure("save-unreadable:" + str(report.get("detail", "")))
	state = loaded
	return {"ok": true}


func _can_accept_input() -> bool:
	return navigation != null and not _held and not _paused and not is_instance_valid(_presentation)


func _save_failure(reason: String) -> Dictionary:
	_held = true
	last_error = reason
	save_refused.emit(reason)
	return {"ok": false, "error": reason, "safeHold": true}


func _error(reason: String) -> Dictionary:
	last_error = reason
	return {"ok": false, "error": reason}
