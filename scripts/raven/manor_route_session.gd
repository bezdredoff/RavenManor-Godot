extends RefCounted

## Map-only route transaction. The scene owns the character/Tween; this object emits
## one authored segment at a time and acknowledges only completed arrivals.
## If a new target arrives mid-segment, finish the current segment before replanning.
var _graph
var _confirmed_anchor := ""
var _last_safe_anchor := ""
var _target_hotspot := ""
var _in_flight_to := ""


func _init(graph) -> void:
	_graph = graph


func restore(snapshot: Dictionary) -> String:
	_confirmed_anchor = _graph.safe_checkpoint_anchor(snapshot)
	_last_safe_anchor = _confirmed_anchor
	_target_hotspot = ""
	_in_flight_to = ""
	return _confirmed_anchor


func start_at(anchor_id: String) -> bool:
	if not _in_flight_to.is_empty() or not _graph.has_anchor(anchor_id):
		return false
	_confirmed_anchor = anchor_id
	_target_hotspot = ""
	var item: Dictionary = _graph.anchor(anchor_id)
	if str(item.get("kind", "")) == "safe":
		_last_safe_anchor = anchor_id
	return true


func current_anchor() -> String:
	return _confirmed_anchor


func pending_hotspot() -> String:
	return _target_hotspot


func in_flight_anchor() -> String:
	return _in_flight_to


func request_hotspot(hotspot_id: String) -> Dictionary:
	if _confirmed_anchor.is_empty():
		return {"ok": false, "error": "no-current-anchor"}
	var destination: String = _graph.interaction_anchor(hotspot_id)
	if destination.is_empty():
		return {"ok": false, "error": "unknown-hotspot"}
	var origin := _in_flight_to if not _in_flight_to.is_empty() else _confirmed_anchor
	if _graph.route(origin, destination).is_empty():
		return {"ok": false, "error": "unreachable"}
	if _target_hotspot == hotspot_id:
		return {"ok": true, "status": "unchanged"}
	_target_hotspot = hotspot_id
	return {"ok": true, "status": "queued" if not _in_flight_to.is_empty() else "planned"}


func next_segment() -> Dictionary:
	# Calling twice must not start a second tween or skip an anchor.
	if not _in_flight_to.is_empty() or _target_hotspot.is_empty():
		return {}
	var destination: String = _graph.interaction_anchor(_target_hotspot)
	var route_ids: Array[String] = _graph.route(_confirmed_anchor, destination)
	if route_ids.is_empty():
		_target_hotspot = ""
		return {}
	if route_ids.size() == 1:
		var reached_hotspot := _target_hotspot
		_target_hotspot = ""
		return {"arrived": true, "hotspotId": reached_hotspot}
	var next_id: String = route_ids[1]
	if not _graph.segment_available(_confirmed_anchor, next_id):
		_target_hotspot = ""
		return {}
	_in_flight_to = next_id
	return {
		"fromAnchorId": _confirmed_anchor,
		"toAnchorId": next_id,
		"fromPosition": _graph.position(_confirmed_anchor),
		"toPosition": _graph.position(next_id)
	}


func finish_segment(arrived_anchor_id: String) -> Dictionary:
	if _in_flight_to.is_empty() or arrived_anchor_id != _in_flight_to:
		return {"ok": false, "error": "unexpected-arrival"}
	# Gates may change while a scene Tween is moving. Never acknowledge
	# a crossing after its direct authored edge has become unavailable.
	# Host must stop its Tween and place feet back at rollbackAnchorId;
	# the graph itself never teleports or writes a checkpoint.
	if not _graph.segment_available(_confirmed_anchor, _in_flight_to):
		var rollback_id := _confirmed_anchor
		_in_flight_to = ""
		_target_hotspot = ""
		return {"ok": false, "error": "segment-blocked", "rollbackAnchorId": rollback_id}
	_confirmed_anchor = arrived_anchor_id
	_in_flight_to = ""
	var item: Dictionary = _graph.anchor(_confirmed_anchor)
	if str(item.get("kind", "")) == "safe":
		_last_safe_anchor = _confirmed_anchor
	if _target_hotspot.is_empty():
		return {"ok": true, "status": "cancelled"}
	var destination: String = _graph.interaction_anchor(_target_hotspot)
	if destination == _confirmed_anchor:
		var reached_hotspot := _target_hotspot
		_target_hotspot = ""
		return {"ok": true, "status": "arrived", "hotspotId": reached_hotspot}
	if _graph.route(_confirmed_anchor, destination).is_empty():
		_target_hotspot = ""
		return {"ok": true, "status": "blocked"}
	return {"ok": true, "status": "continue"}


func cancel() -> Dictionary:
	_target_hotspot = ""
	# Do not kill an in-flight tween and then jump across walls from an old anchor.
	return {"ok": true, "finishCurrentSegment": not _in_flight_to.is_empty()}


func checkpoint_event(event_id: String) -> Dictionary:
	if not _in_flight_to.is_empty():
		return {}
	return _graph.checkpoint_event(_last_safe_anchor, event_id)
