extends RefCounted

## Reusable authored-anchor graph. AStar2D solves routes; content data owns geometry and gates.
const GRAPH_DATA = preload("res://data/raven/manor_greybox_graph.json")

var _astar := AStar2D.new()
var _anchors := {}
var _point_ids := {}
var _anchor_ids := {}
var _active_edges: Array[Dictionary] = []


func rebuild(snapshot: Dictionary, graph_data: Dictionary = GRAPH_DATA.data) -> void:
	_astar.clear()
	_anchors.clear()
	_point_ids.clear()
	_anchor_ids.clear()
	_active_edges.clear()
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
