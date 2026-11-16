extends SceneTree
## CODE-05-02 (G1): isolated physical door & route calibration regression.
## Read-only assertions over the DRAFT_ONLY calibration record. It does NOT
## instantiate a scene, move Onoe, promote production geometry, or mutate any
## canonical file (PNG, manifest, greybox graph, world map, 09B blueprint).
const Routes = preload("res://addons/room_builder_routes/route_document.gd")
const CAL := "res://assets/raven/map/qa/drafts/map_qa_09c_g1_door_calibration.v1.json"
const BLUEPRINT := "res://assets/raven/map/qa/drafts/map_qa_09b_opening_blueprint.v1.json"
const MANIFEST := "res://assets/raven/map/first_floor_manifest.v1.json"
const GRAPH := "res://data/raven/manor_greybox_graph.json"
const WORLD := "res://data/raven/season1_world_map.json"
const ART := "res://a_detailed_top_down_isometric_game_map_illustratio.png"
const EXPECTED_DOORS := ["RM-DOOR-HALL-CORRIDOR", "RM-DOOR-CORRIDOR-BEDROOM"]
const FOOT_RADIUS := 12.0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var art_hash := FileAccess.get_sha256(ART)
	var manifest_before := FileAccess.get_file_as_string(MANIFEST)
	var graph_before := FileAccess.get_file_as_string(GRAPH)
	var world_before := FileAccess.get_file_as_string(WORLD)
	var blueprint_before := FileAccess.get_file_as_string(BLUEPRINT)

	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(CAL))
	assert(raw is Dictionary, "calibration JSON must parse to a dictionary")
	var data: Dictionary = raw

	# Contract identity and approval boundaries.
	assert(data["kind"] == "raven-map-g1-door-calibration")
	assert(data["approval"] == "DRAFT_ONLY")
	assert(data["productionReady"] == false)
	assert(data["runtimeAuthority"] == false)
	assert(data["canonicalNavigationAuthority"] == false)
	assert(data["coordinateSpace"] == "image-pixel")

	# Immutable approved source image must be referenced exactly.
	var src: Dictionary = data["sourceImage"]
	assert(str(src["path"]) == Routes.IMAGE_PATH)
	assert(str(src["sha256"]) == Routes.IMAGE_SHA256)
	assert(str(src["gitBlobSha"]) == Routes.IMAGE_BLOB_SHA)
	var dims: Array = src["sizePx"]
	assert(dims.size() == 2 and int(dims[0]) == 1672 and int(dims[1]) == 941)
	assert(bool(src["immutable"]))

	# Authoritative logical identity and lock state from the world map + manifest.
	var world: Dictionary = JSON.parse_string(world_before)
	var manifest: Dictionary = JSON.parse_string(manifest_before)
	var world_doors := {}
	for door in world["doors"]:
		world_doors[str(door["id"])] = door
	var manifest_doors := {}
	for door in manifest["doors"]:
		manifest_doors[str(door["id"])] = door
	var canonical_anchors := {}
	var canonical: Dictionary = JSON.parse_string(graph_before)
	for anchor in canonical["anchors"]:
		canonical_anchors[str(anchor["id"])] = anchor

	var doors: Array = data["doors"]
	assert(doors.size() == 2, "G1 calibration must cover exactly HC and CB")
	var seen := {}
	for raw_door in doors:
		assert(raw_door is Dictionary)
		var door: Dictionary = raw_door
		var id := str(door["doorId"])
		assert(EXPECTED_DOORS.has(id) and not seen.has(id))
		seen[id] = true

		# Logical door identity and lock state preserved.
		assert(world_doors.has(id), "unknown world-map door: " + id)
		assert(manifest_doors.has(id), "unknown manifest door: " + id)
		var world_door: Dictionary = world_doors[id]
		var room_ids: Array = door["roomIds"]
		assert(room_ids.size() == 2)
		var a: int = int(world_door["a"])
		var b: int = int(world_door["b"])
		var w_rooms: Array = [str(world["rooms"][a]["id"]), str(world["rooms"][b]["id"])]
		assert(room_ids[0] == w_rooms[0] and room_ids[1] == w_rooms[1],
			"room pair mismatch for " + id)
		assert(str(door["logicalReferenceState"]) == str(world_door["status"]),
			"lock state changed for " + id)
		assert(manifest_doors[id]["roomIds"] == room_ids,
			"manifest roomIds mismatch for " + id)

		# Canonical RM-NAV-* transition anchors must still exist, room-owning unchanged.
		var near_id := str(door["canonicalNearAnchorId"])
		var far_id := str(door["canonicalFarAnchorId"])
		assert(canonical_anchors.has(near_id) and canonical_anchors.has(far_id))
		assert(str(canonical_anchors[near_id]["roomId"]) == room_ids[0])
		assert(str(canonical_anchors[far_id]["roomId"]) == room_ids[1])
		assert(str(canonical_anchors[near_id]["kind"]) == "transition")
		assert(str(canonical_anchors[far_id]["kind"]) == "transition")

		# The record must be explicit that no real opening is painted.
		assert(bool(door["requiresArchitecturalChange"]))

		# Threshold geometry sanity.
		var threshold := _vec(door["thresholdPx"])
		var normal := _vec(door["normalPx"])
		var width := float(door["openingWidthPx"])
		assert(width >= 24.0 and width <= 128.0)
		assert(absf(normal.length() - 1.0) <= 0.001, "normal must be a unit vector")

		# Near/far feet: inside image, distinct, on opposite sides of the threshold.
		var near := _vec(door["nearFootPx"])
		var far := _vec(door["farFootPx"])
		assert(_in_bounds(near, 1672, 941) and _in_bounds(far, 1672, 941))
		assert(near.distance_to(far) >= 8.0, "near/far feet must be physically separated")
		assert((far - threshold).dot(normal) > 0.0, "far foot must sit along the crossing normal")
		assert((near - threshold).dot(normal) < 0.0, "near foot must sit opposite the crossing normal")

		# Near/far sides match the declared rooms.
		assert(str(door["nearSideRoomId"]) == room_ids[0])
		assert(str(door["farSideRoomId"]) == room_ids[1])

		# Clearance: both feet >= 12px from every 09B NO-GO polygon edge.
		var blueprint: Dictionary = JSON.parse_string(blueprint_before)
		var min_clearance := INF
		for zone in blueprint.get("noGoPolygons", []):
			var poly := _poly(zone)
			for pt in [near, far]:
				min_clearance = minf(min_clearance, _min_dist(pt, poly))
		assert(min_clearance >= FOOT_RADIUS,
			"feet proxy collides with a NO-GO polygon: " + id)
		assert(float(door["minClearancePx"]) >= FOOT_RADIUS)

		# Elevation/foreground are explicitly not implemented.
		assert(str(door["elevationStatus"]) == "PROPOSED_FLAT_QA_ONLY")
		assert(str(door["foregroundStatus"]) == "NOT_IMPLEMENTED")
		assert(door["artChanges"] is Array and not door["artChanges"].is_empty())

	assert(seen.size() == 2)

	# The record must never mark itself production-approved.
	assert(data["productionReady"] == false and data["runtimeAuthority"] == false)

	# Nothing canonical was modified by reading this calibration.
	assert(FileAccess.get_sha256(ART) == art_hash)
	assert(FileAccess.get_file_as_string(MANIFEST) == manifest_before)
	assert(FileAccess.get_file_as_string(GRAPH) == graph_before)
	assert(FileAccess.get_file_as_string(WORLD) == world_before)
	assert(FileAccess.get_file_as_string(BLUEPRINT) == blueprint_before)

	print("MAP-QA-09C G1 door/route calibration and fail-closed geometry contract passed")
	quit(0)


func _vec(v: Variant) -> Vector2:
	assert(v is Array and v.size() == 2)
	return Vector2(float(v[0]), float(v[1]))


func _in_bounds(p: Vector2, w: float, h: float) -> bool:
	return p.x >= 0.0 and p.x <= w and p.y >= 0.0 and p.y <= h


func _poly(zone: Dictionary) -> Array[Vector2]:
	var pts: Array[Vector2] = []
	for pt in zone["pointsPx"]:
		pts.append(_vec(pt))
	return pts


func _min_dist(p: Vector2, poly: Array[Vector2]) -> float:
	var best := INF
	for i in poly.size():
		var a: Vector2 = poly[i]
		var b: Vector2 = poly[(i + 1) % poly.size()]
		var closest: Vector2 = Geometry2D.get_closest_point_to_segment(p, a, b)
		best = minf(best, p.distance_to(closest))
	return best
