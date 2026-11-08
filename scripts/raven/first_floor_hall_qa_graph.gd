extends RefCounted

## MAP-QA-03: read-only image-pixel adapter for the canonical authored navigation
## machinery. Never changes the 13 RM-NAV anchors or promotes DRAFT_ONLY geometry.
const NavigationGraph = preload("res://scripts/raven/manor_navigation_graph.gd")
const DATA_PATH := "res://assets/raven/map/qa/first_floor_hall_pilot.v1.json"
const ART_PATH := "res://a_detailed_top_down_isometric_game_map_illustratio.png"
const ART_SHA256 := "5e0edf97bd719fb1df95c7e9bea2f134d90adad0bc04d1771acc82a95a4d549a"
const ART_SIZE := Vector2i(1672, 941)
const PILOT_IDS := [
	"QA-HALL-SPAWN", "QA-HALL-CENTRE", "QA-HALL-WEST",
	"QA-HALL-EAST", "QA-HALL-TABLE-APPROACH",
	"QA-HALL-PORTAL-APPROACH", "QA-HALL-RETURN-SAFE"
]
const PORTAL_ID := "QA-PORTAL-HALL-CORRIDOR"

var graph = NavigationGraph.new()
var data: Dictionary = {}
var error_text := ""


func load_pilot() -> bool:
	error_text = ""
	data = {}
	if not FileAccess.file_exists(DATA_PATH):
		return _reject("Missing QA dataset")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	if not parsed is Dictionary:
		return _reject("Invalid QA JSON")
	var candidate: Dictionary = parsed
	if int(candidate.get("schemaVersion", -1)) != 1 or candidate.get("kind") != "raven-first-floor-hall-qa-pilot":
		return _reject("Unknown QA schema")
	if candidate.get("approval") != "DRAFT_ONLY" or candidate.get("productionReady") != false:
		return _reject("QA geometry must remain draft-only")
	if candidate.get("integrationAllowed") != false or candidate.get("canonicalNavigationAuthority") != false:
		return _reject("Production navigation authority is forbidden")
	var coordinate: Dictionary = candidate.get("coordinateSpaces", {})
	if coordinate.get("pilot") != "image-pixel" or coordinate.get("pixelToWorldPlan", true) != null:
		return _reject("QA coordinates are not image pixels")
	if coordinate.get("apply65DegreeProjectionToBaseImage") != false:
		return _reject("The approved illustration is already perspectival")
	var art: Dictionary = candidate.get("source", {})
	if art.get("path") != ART_PATH.trim_prefix("res://") or art.get("dimensionsPx") != [1672, 941]:
		return _reject("Source image path/dimensions changed")
	if art.get("sha256") != ART_SHA256 or art.get("gitBlobSha") != "b50bc36cffd3d3aca7e81a0cea28bb3d0c0e9563":
		return _reject("Approved source image identity changed")
	# Original PNG bytes can be absent from exported .pck while the imported
	# texture exists. Enforce byte identity whenever raw bytes are available.
	if FileAccess.file_exists(ART_PATH) and FileAccess.get_sha256(ART_PATH) != ART_SHA256:
		return _reject("Source PNG bytes no longer match approved image")
	var portal: Dictionary = candidate.get("virtualPortal", {})
	if portal.get("id") != PORTAL_ID or portal.get("status") != "QA_VIRTUAL_NOT_VISIBLE_PHYSICAL_DOOR":
		return _reject("QA portal status changed")
	if portal.get("physicalDoorConfirmed") != false or portal.get("farSideSpawnPointPx", true) != null:
		return _reject("Cannot fabricate a physical Corridor connection")
	if portal.get("liveDoorGateWrites") != false or portal.get("activateOnArrivalOnly") != true:
		return _reject("Unsafe QA portal activation contract")
	if portal.get("approachPointId") != "QA-HALL-PORTAL-APPROACH":
		return _reject("Portal approach anchor changed")
	if candidate.get("actor", {}).get("initialPointId") != "QA-HALL-SPAWN":
		return _reject("Unexpected QA spawn")
	var points: Array = candidate.get("waypoints", [])
	var edges: Array = candidate.get("edges", [])
	if points.size() != PILOT_IDS.size() or edges.size() != 7:
		return _reject("Expected exactly seven QA anchors and seven QA edges")
	if candidate.get("walkablePolygons", []).size() != 1 or candidate.get("noGoPolygons", []).size() != 5:
		return _reject("QA debug polygons changed")
	var seen: Dictionary = {}
	var built_anchors: Array = []
	for raw in points:
		if not raw is Dictionary:
			return _reject("Invalid QA waypoint")
		var id := str(raw.get("id", ""))
		var xy: Variant = raw.get("pointPx", [])
		if not PILOT_IDS.has(id) or seen.has(id) or not _pixel_pair_valid(xy):
			return _reject("Unknown, duplicate or out-of-bounds waypoint")
		seen[id] = true
		built_anchors.append({
			"id": id,
			"roomId": "RM-ROOM-HALL",
			"kind": "safe" if id == "QA-HALL-SPAWN" or id == "QA-HALL-RETURN-SAFE" else "qa",
			"position": xy,
			"hotspotId": hotspot_for_waypoint(id)
		})
	var built_edges: Array = []
	var seen_edges: Dictionary = {}
	for raw in edges:
		if not raw is Dictionary:
			return _reject("Invalid QA edge")
		var a := str(raw.get("from", ""))
		var b := str(raw.get("to", ""))
		var key := a + "|" + b
		if not seen.has(a) or not seen.has(b) or a == b or seen_edges.has(key):
			return _reject("Missing, duplicate or invalid edge endpoint")
		if raw.get("bidirectional") != true or raw.has("doorId") or raw.has("restorationId"):
			return _reject("QA edges must be bidirectional and ungated")
		seen_edges[key] = true
		built_edges.append({"from": a, "to": b, "bidirectional": true})
	for polygon in candidate["walkablePolygons"] + candidate["noGoPolygons"]:
		if not polygon is Dictionary or polygon.get("pointsPx", []).size() < 3:
			return _reject("Invalid QA polygon")
		for point in polygon["pointsPx"]:
			if not _pixel_pair_valid(point):
				return _reject("Out-of-bounds QA polygon")
	graph = NavigationGraph.new()
	graph.rebuild({}, {"anchors": built_anchors, "edges": built_edges})
	for id in PILOT_IDS:
		if not seen.has(id) or graph.route("QA-HALL-SPAWN", id).is_empty():
			return _reject("Missing or unreachable QA anchor")
	data = candidate
	return true


func hotspot_for_waypoint(id: String) -> String:
	if not PILOT_IDS.has(id):
		return ""
	return PORTAL_ID if id == "QA-HALL-PORTAL-APPROACH" else "QA-HS:" + id


func waypoint_position(id: String) -> Vector2:
	return graph.position(id)


func waypoint_ids() -> Array:
	return PILOT_IDS.duplicate()


func is_portal_hotspot(id: String) -> bool:
	return id == PORTAL_ID


func _pixel_pair_valid(pair: Variant) -> bool:
	if not pair is Array or pair.size() != 2:
		return false
	if not (pair[0] is int or pair[0] is float) or not (pair[1] is int or pair[1] is float):
		return false
	var position := Vector2(float(pair[0]), float(pair[1]))
	return position.is_finite() and position.x >= 0.0 and position.y >= 0.0 and position.x < ART_SIZE.x and position.y < ART_SIZE.y


func _reject(reason: String) -> bool:
	error_text = reason
	data = {}
	return false
