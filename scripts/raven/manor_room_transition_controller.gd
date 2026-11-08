extends RefCounted
## MAP-QA-06: authored room handoff. This object owns no production save or scene.
## The host owns Onoe, calls next_segment/start_segment, and commits only after
## a physically confirmed approach. Current room graphs use ManorNavigationGraph.
const Graph = preload("res://scripts/raven/manor_navigation_graph.gd")
const RouteSession = preload("res://scripts/raven/manor_route_session.gd")
const FOOT_TOLERANCE := 0.25

signal transition_ready(result: Dictionary)
signal transition_completed(result: Dictionary)
signal transition_rejected(transition_id: String, reason: String)
signal transition_diagnostic(transition_id: String, reason: String)

var error_text := ""
var _approval := ""
var _room_data: Dictionary = {}
var _graphs: Dictionary = {}
var _descriptors: Dictionary = {}
var _doors: Dictionary = {}
var _unlocked_doors: Array = []
var _room_id := ""
var _graph
var _session
var _pending_id := ""
var _ready_id := ""
var _next_token := 0
var _active_token := 0
var _active_to := ""
var _safe_hold := false
var _hard_hold := false
var _hold_reason := ""
var _last_entry: Dictionary = {}


func configure(contract: Dictionary, initial_room_id: String, initial_anchor_id: String, gate_snapshot: Dictionary = {}) -> bool:
	error_text = ""
	if int(contract.get("schemaVersion", -1)) != 1 or contract.get("kind") != "raven-authored-room-transitions":
		return _invalid("invalid-transition-schema")
	if str(contract.get("approval", "")) not in ["TEST_ONLY", "PRODUCTION_APPROVED"]:
		return _invalid("unapproved-transition-data")
	var room_data: Dictionary = {}
	var doors: Dictionary = {}
	var descriptors: Dictionary = {}
	var unlocked: Array = []
	for raw_door in contract.get("doors", []):
		if not raw_door is Dictionary:
			return _invalid("invalid-door")
		var id := str(raw_door.get("id", ""))
		var status := str(raw_door.get("status", ""))
		if id.is_empty() or doors.has(id) or status not in ["open", "gated", "future"]:
			return _invalid("invalid-door")
		doors[id] = status
	if gate_snapshot.has("unlockedDoors"):
		var supplied: Variant = gate_snapshot.get("unlockedDoors")
		if not supplied is Array:
			return _invalid("invalid-door-snapshot")
		for id in supplied:
			if id is String and doors.has(id) and not unlocked.has(id):
				unlocked.append(id)
	else:
		for id in doors:
			if doors[id] == "open":
				unlocked.append(id)
	for raw_room in contract.get("rooms", []):
		if not raw_room is Dictionary:
			return _invalid("invalid-room")
		var id := str(raw_room.get("id", ""))
		if id.is_empty() or room_data.has(id):
			return _invalid("invalid-room")
		var raw_graph: Variant = raw_room.get("graph", null)
		if not raw_graph is Dictionary:
			return _invalid("missing-room-graph")
		var known: Dictionary = {}
		var hotspots: Dictionary = {}
		var anchors: Variant = raw_graph.get("anchors", [])
		var edges: Variant = raw_graph.get("edges", [])
		if not anchors is Array or anchors.is_empty() or not edges is Array:
			return _invalid("invalid-room-graph")
		for anchor in anchors:
			if not anchor is Dictionary:
				return _invalid("invalid-anchor")
			var anchor_id := str(anchor.get("id", ""))
			var coords: Variant = anchor.get("position", [])
			if anchor_id.is_empty() or known.has(anchor_id) or str(anchor.get("roomId", "")) != id:
				return _invalid("invalid-anchor")
			if not _valid_position(coords):
				return _invalid("invalid-anchor-position")
			known[anchor_id] = anchor
			var hotspot := str(anchor.get("hotspotId", ""))
			if not hotspot.is_empty():
				if hotspots.has(hotspot):
					return _invalid("duplicate-room-hotspot")
				hotspots[hotspot] = true
		for edge in edges:
			if not edge is Dictionary:
				return _invalid("invalid-room-edge")
			if not known.has(str(edge.get("from", ""))) or not known.has(str(edge.get("to", ""))):
				return _invalid("invalid-room-edge")
			var edge_door := str(edge.get("doorId", ""))
			if not edge_door.is_empty() and not doors.has(edge_door):
				return _invalid("unknown-room-edge-door")
		room_data[id] = raw_graph.duplicate(true)
	if not room_data.has(initial_room_id):
		return _invalid("invalid-initial-room")
	for raw in contract.get("transitions", []):
		if not raw is Dictionary:
			return _invalid("invalid-transition")
		var id := str(raw.get("id", ""))
		if id.is_empty() or descriptors.has(id):
			return _invalid("duplicate-transition")
		var source := str(raw.get("sourceRoomId", ""))
		var destination := str(raw.get("destinationRoomId", ""))
		var approach := str(raw.get("approachAnchorId", ""))
		var entry := str(raw.get("destinationEntryAnchorId", ""))
		var door := str(raw.get("doorId", ""))
		var authority := str(raw.get("authority", ""))
		var reverse := str(raw.get("reverseTransitionId", ""))
		if not room_data.has(source) or not room_data.has(destination) or source == destination:
			return _invalid("invalid-transition-rooms")
		if not raw.has("reverseTransitionId") or not raw.has("doorId"):
			return _invalid("incomplete-transition-descriptor")
		if authority not in ["TEST_ONLY", "QA_VIRTUAL", "PRODUCTION_APPROVED"]:
			return _invalid("invalid-transition-authority")
		if authority == "PRODUCTION_APPROVED" and contract.approval != "PRODUCTION_APPROVED":
			return _invalid("unapproved-production-transition")
		if not door.is_empty() and not doors.has(door):
			return _invalid("unknown-transition-door")
		var approach_data := _find_anchor(room_data[source], approach)
		if approach_data.is_empty() or str(approach_data.get("hotspotId", "")).is_empty():
			return _invalid("missing-approach-anchor")
		if authority == "QA_VIRTUAL":
			if not entry.is_empty() or not reverse.is_empty():
				return _invalid("virtual-spawn-must-be-absent")
		else:
			var entry_data := _find_anchor(room_data[destination], entry)
			if entry_data.is_empty() or str(entry_data.get("kind", "")) != "safe":
				return _invalid("missing-destination-entry-anchor")
		descriptors[id] = raw.duplicate(true)
	for id in descriptors:
		var item: Dictionary = descriptors[id]
		var reverse_id := str(item.get("reverseTransitionId", ""))
		if reverse_id.is_empty():
			continue
		if not descriptors.has(reverse_id):
			return _invalid("unknown-reverse-transition")
		var back: Dictionary = descriptors[reverse_id]
		if str(back.get("reverseTransitionId", "")) != id:
			return _invalid("nonreciprocal-transition")
		if back.get("sourceRoomId") != item.get("destinationRoomId") or back.get("destinationRoomId") != item.get("sourceRoomId"):
			return _invalid("invalid-reverse-rooms")
		if back.get("doorId") != item.get("doorId"):
			return _invalid("reverse-door-mismatch")
	var fresh_graphs: Dictionary = {}
	for id in room_data:
		var graph = Graph.new()
		graph.rebuild({"unlockedDoors": unlocked, "completedRestorations": []}, room_data[id])
		fresh_graphs[id] = graph
	if not fresh_graphs[initial_room_id].has_anchor(initial_anchor_id):
		return _invalid("invalid-initial-anchor")
	if str(fresh_graphs[initial_room_id].anchor(initial_anchor_id).get("kind", "")) != "safe":
		return _invalid("initial-anchor-not-safe")
	var start_session = RouteSession.new(fresh_graphs[initial_room_id])
	if not start_session.start_at(initial_anchor_id):
		return _invalid("initial-route-session-failed")
	_approval = str(contract.approval)
	_room_data = room_data
	_graphs = fresh_graphs
	_descriptors = descriptors
	_doors = doors
	_unlocked_doors = unlocked
	_room_id = initial_room_id
	_graph = _graphs[_room_id]
	_session = start_session
	_pending_id = ""
	_ready_id = ""
	_active_token = 0
	_active_to = ""
	_safe_hold = false
	_hard_hold = false
	_hold_reason = ""
	_last_entry = {}
	return true


func room_id() -> String:
	return _room_id


func confirmed_anchor() -> String:
	return _session.current_anchor() if _session != null else ""


func pending_transition() -> String:
	return _pending_id


func ready_transition() -> String:
	return _ready_id


func in_safe_hold() -> bool:
	return _safe_hold


func hold_reason() -> String:
	return _hold_reason


func last_entry() -> Dictionary:
	return _last_entry.duplicate(true)


func anchor_position(anchor_id: String) -> Vector2:
	return _graph.position(anchor_id) if _graph != null else Vector2.INF


func room_graph(room_id: String):
	return _graphs.get(room_id, null)


func door_status(door_id: String) -> String:
	return str(_doors.get(door_id, ""))


func request_room_hotspot(hotspot_id: String, actor) -> Dictionary:
	if _session == null or _safe_hold or not _pending_id.is_empty() or not _ready_id.is_empty():
		return _reject("", "transition-or-safe-hold-active")
	var checked := _verify_actor(actor)
	if not checked.is_empty():
		return _reject("", checked)
	return _session.request_hotspot(hotspot_id)


func request_transition(transition_id: String, actor) -> Dictionary:
	if not _descriptors.has(transition_id):
		return _reject(transition_id, "unknown-transition")
	var descriptor: Dictionary = _descriptors[transition_id]
	if str(descriptor.sourceRoomId) != _room_id:
		return _reject(transition_id, "invalid-source-room")
	if _safe_hold:
		return _reject(transition_id, "safe-hold-required")
	if not _ready_id.is_empty():
		return {"ok": true, "status": "unchanged"} if _ready_id == transition_id else _reject(transition_id, "handoff-already-ready")
	if _pending_id == transition_id:
		return {"ok": true, "status": "unchanged"}
	var door_error := _door_failure(descriptor)
	if not door_error.is_empty():
		return _reject(transition_id, door_error)
	var checked := _verify_actor(actor)
	if not checked.is_empty():
		return _reject(transition_id, checked)
	var approach := str(descriptor.approachAnchorId)
	if not _graph.has_anchor(approach):
		return _reject(transition_id, "missing-approach-anchor")
	var hotspot := str(_graph.anchor(approach).get("hotspotId", ""))
	if hotspot.is_empty():
		return _reject(transition_id, "missing-approach-hotspot")
	var result: Dictionary = _session.request_hotspot(hotspot)
	if not bool(result.get("ok", false)):
		return _reject(transition_id, "approach-" + str(result.get("error", "unreachable")))
	_pending_id = transition_id
	return {"ok": true, "status": str(result.get("status", "planned")), "transitionId": transition_id}


func next_segment(actor) -> Dictionary:
	if _session == null or _safe_hold or _active_token != 0 or not is_instance_valid(actor) or actor.has_active_segment():
		return {}
	var at_rest := actor.position.distance_to(_graph.position(_session.current_anchor())) <= FOOT_TOLERANCE
	if not at_rest:
		_reject(_pending_id, "physical-position-not-at-anchor")
		return {}
	var result: Dictionary = _session.next_segment()
	if result.is_empty():
		return {}
	if bool(result.get("arrived", false)):
		var reached: String = str(result.get("hotspotId", ""))
		_stage_arrival(reached, actor)
		return {"arrived": true, "hotspotId": reached}
	_next_token += 1
	_active_token = _next_token
	_active_to = str(result.get("toAnchorId", ""))
	result["segmentToken"] = _active_token
	return result


func report_dispatch_failure(token: int) -> void:
	if token == _active_token and token != 0:
		_safe_hold = true
		_hard_hold = true
		_hold_reason = "visual-executor-rejected-segment"
		_session.cancel()
		_pending_id = ""
		_ready_id = ""
		_reject("", _hold_reason)


func accept_segment_arrival(token: int, arrived_anchor_id: String, physical_feet: Vector2, actor) -> Dictionary:
	if token == 0 or token != _active_token or arrived_anchor_id != _active_to:
		return _reject(_pending_id, "stale-or-unexpected-arrival")
	if _safe_hold:
		return _reject(_pending_id, "safe-hold-required")
	if not is_instance_valid(actor) or actor.has_active_segment():
		return _reject(_pending_id, "premature-arrival")
	if not physical_feet.is_finite() or physical_feet.distance_to(actor.position) > FOOT_TOLERANCE:
		return _reject(_pending_id, "physical-footpoint-mismatch")
	if physical_feet.distance_to(_graph.position(arrived_anchor_id)) > FOOT_TOLERANCE:
		return _reject(_pending_id, "arrival-not-at-authorized-anchor")
	if not _graph.segment_available(_session.current_anchor(), arrived_anchor_id):
		_safe_hold = true
		_hard_hold = true
		_hold_reason = "segment-gate-closed-at-arrival"
		_session.cancel()
		_pending_id = ""
		_ready_id = ""
		return _reject("", _hold_reason)
	var outcome: Dictionary = _session.finish_segment(arrived_anchor_id)
	if not bool(outcome.get("ok", false)):
		_safe_hold = true
		_hard_hold = true
		_hold_reason = "route-session-rejected-arrival"
		return _reject(_pending_id, _hold_reason)
	_active_token = 0
	_active_to = ""
	if outcome.get("status") == "arrived":
		var staged: Dictionary = _stage_arrival(str(outcome.get("hotspotId", "")), actor)
		if not bool(staged.get("ok", false)):
			return staged
	return {"ok": true, "status": str(outcome.get("status", "")), "anchorId": arrived_anchor_id}


func commit_transition(actor) -> Dictionary:
	if _ready_id.is_empty():
		return _reject("", "no-confirmed-transition")
	var id := _ready_id
	var item: Dictionary = _descriptors[id]
	if _safe_hold or _active_token != 0 or not is_instance_valid(actor) or actor.has_active_segment():
		return _reject(id, "motion-not-settled")
	if _session.current_anchor() != str(item.approachAnchorId) or actor.position.distance_to(_graph.position(str(item.approachAnchorId))) > FOOT_TOLERANCE:
		return _reject(id, "approach-not-physically-confirmed")
	var door_error := _door_failure(item)
	if not door_error.is_empty():
		_ready_id = ""
		_pending_id = ""
		return _reject(id, door_error)
	if str(item.get("authority", "")) == "QA_VIRTUAL":
		_ready_id = ""
		_pending_id = ""
		return _diagnostic(id, "qa-virtual-no-far-spawn")
	var destination := str(item.destinationRoomId)
	var entry := str(item.destinationEntryAnchorId)
	if not _graphs.has(destination) or not _graphs[destination].has_anchor(entry):
		return _reject(id, "missing-destination-entry-anchor")
	var target_graph = _graphs[destination]
	if str(target_graph.anchor(entry).get("kind", "")) != "safe":
		return _reject(id, "entry-anchor-not-approved-safe")
	var new_session = RouteSession.new(target_graph)
	if not new_session.start_at(entry):
		return _reject(id, "destination-session-rejected-entry")
	var from_room := _room_id
	var entry_position: Vector2 = target_graph.position(entry)
	if not entry_position.is_finite():
		return _reject(id, "invalid-entry-position")
	# Intentional inter-room relocation ONLY after confirmed physical approach.
	# The production host can replace room visuals at this exact handoff boundary.
	_room_id = destination
	_graph = target_graph
	_session = new_session
	_pending_id = ""
	_ready_id = ""
	actor.position = entry_position
	actor.show_idle()
	var result := {
		"ok": true, "transitionId": id, "fromRoomId": from_room,
		"roomId": destination, "entryAnchorId": entry,
		"entryPosition": entry_position,
		"reverseTransitionId": str(item.reverseTransitionId),
		"checkpointProposal": {"type": "position_checkpoint", "roomId": destination, "anchorId": entry}
	}
	_last_entry = result.duplicate(true)
	transition_completed.emit(result.duplicate(true))
	return result


func cancel_transition() -> Dictionary:
	if _session == null or _safe_hold:
		return {"ok": false, "error": "safe-hold-or-unconfigured"}
	var id := _pending_id if not _pending_id.is_empty() else _ready_id
	_pending_id = ""
	_ready_id = ""
	var outcome: Dictionary = _session.cancel()
	return {"ok": true, "transitionId": id, "finishCurrentSegment": bool(outcome.get("finishCurrentSegment", false))}


## TEST_ONLY gate adapter. A production host must rebuild gates from the
## authoritative snapshot; never call this as a production door unlock.
func set_test_door_status(door_id: String, status: String, actor) -> bool:
	if _approval != "TEST_ONLY" or not _doors.has(door_id) or status not in ["open", "gated", "future"]:
		return false
	_doors[door_id] = status
	_unlocked_doors.erase(door_id)
	if status == "open":
		_unlocked_doors.append(door_id)
	for room in _graphs:
		_graphs[room].rebuild({"unlockedDoors": _unlocked_doors, "completedRestorations": []}, _room_data[room])
	if _active_token != 0 and not _graph.segment_available(_session.current_anchor(), _active_to):
		_safe_hold = true
		_hard_hold = not is_instance_valid(actor) or not actor.has_active_segment()
		_hold_reason = "gate-closed-mid-segment"
		if not _hard_hold:
			actor.pause_segment()
		_session.cancel()
		_pending_id = ""
		_ready_id = ""
		_reject("", _hold_reason)
	elif not _ready_id.is_empty():
		var waiting: Dictionary = _descriptors[_ready_id]
		var reason := _door_failure(waiting)
		if not reason.is_empty():
			var old := _ready_id
			_ready_id = ""
			_pending_id = ""
			_reject(old, reason)
	elif not _pending_id.is_empty() and not _door_failure(_descriptors[_pending_id]).is_empty():
		var old := _pending_id
		cancel_transition()
		_reject(old, "door-closed-before-arrival")
	return true


func resume_held_segment(actor) -> bool:
	if not _safe_hold or _hard_hold or not is_instance_valid(actor):
		return false
	if not actor.has_active_segment() or not actor.is_paused():
		return false
	if not _graph.segment_available(_session.current_anchor(), _active_to):
		return false
	_safe_hold = false
	_hold_reason = ""
	return actor.resume_segment()


func _stage_arrival(hotspot_id: String, actor) -> Dictionary:
	if _pending_id.is_empty():
		return {"ok": true, "status": "room-hotspot-arrived"}
	var id := _pending_id
	var item: Dictionary = _descriptors[id]
	var approach := str(item.approachAnchorId)
	if hotspot_id != str(_graph.anchor(approach).get("hotspotId", "")) or _session.current_anchor() != approach:
		return _reject(id, "arrival-hotspot-mismatch")
	if not is_instance_valid(actor) or actor.has_active_segment() or actor.position.distance_to(_graph.position(approach)) > FOOT_TOLERANCE:
		return _reject(id, "approach-not-physically-confirmed")
	var door_error := _door_failure(item)
	if not door_error.is_empty():
		_pending_id = ""
		return _reject(id, door_error)
	if str(item.authority) == "QA_VIRTUAL":
		_pending_id = ""
		return _diagnostic(id, "qa-virtual-no-far-spawn")
	_pending_id = ""
	_ready_id = id
	var result := {"ok": true, "status": "ready", "transitionId": id,
		"fromRoomId": _room_id, "destinationRoomId": str(item.destinationRoomId)}
	transition_ready.emit(result.duplicate(true))
	return result


func _verify_actor(actor) -> String:
	if _session == null or not is_instance_valid(actor):
		return "actor-or-session-unavailable"
	if actor.has_active_segment():
		if _active_token == 0 or actor.segment_destination() != _active_to or _session.in_flight_anchor() != _active_to:
			return "untracked-actor-motion"
	elif _active_token == 0 and actor.position.distance_to(_graph.position(_session.current_anchor())) > FOOT_TOLERANCE:
		return "physical-position-not-at-anchor"
	return ""


func _door_failure(item: Dictionary) -> String:
	var door := str(item.get("doorId", ""))
	if door.is_empty():
		return ""
	if not _doors.has(door):
		return "unknown-door"
	if _doors[door] == "future":
		return "future-door"
	if not _unlocked_doors.has(door):
		return "locked-door"
	return ""


func _find_anchor(graph_data: Dictionary, id: String) -> Dictionary:
	for anchor in graph_data.get("anchors", []):
		if anchor is Dictionary and str(anchor.get("id", "")) == id:
			return anchor
	return {}


func _valid_position(value: Variant) -> bool:
	if not value is Array or value.size() != 2:
		return false
	if not (value[0] is int or value[0] is float) or not (value[1] is int or value[1] is float):
		return false
	return Vector2(float(value[0]), float(value[1])).is_finite()


func _invalid(reason: String) -> bool:
	error_text = reason
	return false


func _reject(id: String, reason: String) -> Dictionary:
	transition_rejected.emit(id, reason)
	return {"ok": false, "error": reason, "transitionId": id}


func _diagnostic(id: String, reason: String) -> Dictionary:
	transition_diagnostic.emit(id, reason)
	return {"ok": false, "diagnostic": true, "error": reason, "transitionId": id}
