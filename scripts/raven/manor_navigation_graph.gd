extends RefCounted

## Reusable authored-anchor graph. AStar2D solves routes; content data owns geometry and gates.
const GRAPH_DATA = preload("res://data/raven/manor_greybox_graph.json")

var _astar := AStar2D.new()
var _anchors := {}
var _point_ids := {}
var _anchor_ids := {}
var _active_edges: Array[Dictionary] = []
var _door_gate_ids := {}


func rebuild(snapshot: Dictionary, graph_data: Dictionary = GRAPH_DATA.data) -> void:
	_astar.clear()
	_anchors.clear()
	_point_ids.clear()
	_anchor_ids.clear()
	_active_edges.clear()
	_door_gate_ids.clear()
	var index := 1
	for raw_anchor in graph_data.anchors:
		var anchor: Dictionary = raw_anchor
		var anchor_id := str(anchor.id)
		var position := Vector2(float(anchor.position[0]), float(anchor.position[1]))
		_anchors[anchor_id] = anchor
		_point_ids[anchor_id] = index
		_anchor_ids[index] = anchor_id
		_astar.add_point(index, position)
		index += 1
	for raw_edge in graph_data.edges:
		var edge: Dictionary = raw_edge
		var door_id := str(edge.get("doorId", ""))
		if not door_id.is_empty():
			_door_gate_ids[door_id] = true
		if not _edge_available(edge, snapshot):
			continue
		var from_id: int = _point_ids.get(str(edge.from), 0)
		var to_id: int = _point_ids.get(str(edge.to), 0)
		if from_id == 0 or to_id == 0:
			continue
		_astar.connect_points(from_id, to_id, bool(edge.get("bidirectional", true)))
		_active_edges.append(edge)


func route(from_anchor_id: String, to_anchor_id: String) -> Array[String]:
	var result: Array[String] = []
	if not _point_ids.has(from_anchor_id) or not _point_ids.has(to_anchor_id):
		return result
	for point_id in _astar.get_id_path(_point_ids[from_anchor_id], _point_ids[to_anchor_id]):
		result.append(str(_anchor_ids[point_id]))
	return result


func route_positions(from_anchor_id: String, to_anchor_id: String) -> PackedVector2Array:
	if not _point_ids.has(from_anchor_id) or not _point_ids.has(to_anchor_id):
		return PackedVector2Array()
	return _astar.get_point_path(_point_ids[from_anchor_id], _point_ids[to_anchor_id])


func anchor(id: String) -> Dictionary:
	return _anchors.get(id, {})


func position(id: String) -> Vector2:
	if not _point_ids.has(id):
		return Vector2.INF
	return _astar.get_point_position(_point_ids[id])


func interaction_anchor(hotspot_id: String) -> String:
	for anchor_id in _anchors:
		if _anchors[anchor_id].get("hotspotId") == hotspot_id:
			return anchor_id
	return ""


func active_edges() -> Array[Dictionary]:
	return _active_edges.duplicate(true)


func anchors() -> Dictionary:
	return _anchors.duplicate(true)



## Query-only API for hotspot-driven movement. Never interprets a screen tap as a destination.
func has_anchor(anchor_id: String) -> bool:
	return _anchors.has(anchor_id)


func has_door_gate(door_id: String) -> bool:
	return _door_gate_ids.has(door_id)


func route_to_hotspot(from_anchor_id: String, hotspot_id: String) -> Array[String]:
	var target_id := interaction_anchor(hotspot_id)
	if target_id.is_empty():
		return []
	return route(from_anchor_id, target_id)


## Check the *direct* authored segment, not an alternate A* route between its endpoints.
func segment_available(from_anchor_id: String, to_anchor_id: String) -> bool:
	if not has_anchor(from_anchor_id) or not has_anchor(to_anchor_id):
		return false
	for edge in _active_edges:
		var source := str(edge.get("from", ""))
		var destination := str(edge.get("to", ""))
		if source == from_anchor_id and destination == to_anchor_id:
			return true
		if bool(edge.get("bidirectional", true)) and source == to_anchor_id and destination == from_anchor_id:
			return true
	return false


func _safe_and_reachable(anchor_id: String, fallback_id: String) -> bool:
	if not _anchors.has(anchor_id) or str(_anchors[anchor_id].get("kind", "")) != "safe":
		return false
	return not route(fallback_id, anchor_id).is_empty()


## Never trust a persisted anchor string as geometry. Fall back to a connected room-safe point.
func safe_checkpoint_anchor(snapshot: Dictionary, fallback_id: String = "RM-NAV-HALL-SPAWN") -> String:
	if not _anchors.has(fallback_id) or str(_anchors[fallback_id].get("kind", "")) != "safe":
		fallback_id = ""
		for anchor_id in _anchors:
			if str(_anchors[anchor_id].get("kind", "")) == "safe":
				fallback_id = str(anchor_id)
				break
	if fallback_id.is_empty():
		return ""
	var room_id := str(snapshot.get("lastRoomId", ""))
	var saved_id := str(snapshot.get("lastSafeAnchorId", ""))
	if _safe_and_reachable(saved_id, fallback_id) and str(_anchors[saved_id].get("roomId", "")) == room_id:
		return saved_id
	for anchor_id in _anchors:
		var candidate_id := str(anchor_id)
		if str(_anchors[candidate_id].get("roomId", "")) == room_id and _safe_and_reachable(candidate_id, fallback_id):
			return candidate_id
	return fallback_id


## Call only after reaching a safe anchor. Reducer/store remain the sole save authority.
func checkpoint_event(anchor_id: String, event_id: String) -> Dictionary:
	if event_id.is_empty() or not _anchors.has(anchor_id):
		return {}
	var item: Dictionary = _anchors[anchor_id]
	if str(item.get("kind", "")) != "safe":
		return {}
	return {
		"eventId": event_id,
		"type": "position_checkpoint",
		"roomId": str(item.get("roomId", "")),
		"anchorId": anchor_id
	}


static func _edge_available(edge: Dictionary, snapshot: Dictionary) -> bool:
	var door_id := str(edge.get("doorId", ""))
	if not door_id.is_empty() and not snapshot.get("unlockedDoors", []).has(door_id):
		return false
	var restoration_id := str(edge.get("restorationId", ""))
	if not restoration_id.is_empty() and not snapshot.get("completedRestorations", []).has(restoration_id):
		return false
	return true


static func production_geometry_is_valid(graph_data: Dictionary = GRAPH_DATA.data) -> bool:
	var provenance: Dictionary = graph_data.get("provenance", {})
	if not bool(provenance.get("productionReady", false)):
		return true
	var calibration: Variant = provenance.get("roomArtCalibration")
	return calibration is Dictionary and calibration.get("status") == "approved" and not str(calibration.get("assetHash", "")).is_empty() and int(calibration.get("version", 0)) > 0
