extends SceneTree
## MAP-QA-05: independent geometry contract smoke; no production map writes.
const Routes = preload("res://addons/room_builder_routes/route_document.gd")
const PreviewSource = preload("res://addons/room_builder_routes/route_preview_source.gd")
const DRAFT := "res://assets/raven/map/qa/drafts/hall_routes_draft.v1.json"
const MANIFEST := "res://assets/raven/map/first_floor_manifest.v1.json"
const CANONICAL := "res://data/raven/manor_greybox_graph.json"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var original_hall: String = FileAccess.get_file_as_string(Routes.HALL_SOURCE)
	var canonical_before: String = FileAccess.get_file_as_string(CANONICAL)
	var manifest_text: String = FileAccess.get_file_as_string(MANIFEST)
	assert(not original_hall.is_empty() and not canonical_before.is_empty())
	var hall_data: Dictionary = JSON.parse_string(original_hall)
	var manifest: Dictionary = JSON.parse_string(manifest_text)
	var loaded: Dictionary = Routes.load_draft(DRAFT)
	assert(loaded.ok, str(loaded.get("error", "")))
	var doc: Dictionary = loaded.document
	assert(Routes.validate(doc).ok, "Draft must load unmodified in MAP-EDIT-01")
	assert(doc.get("qaTaskId") == "MAP-QA-05")
	assert(doc.get("geometryReview") == "AI_PROVISIONAL_UNAPPROVED")
	assert(doc.get("approval") == "DRAFT_ONLY")
	assert(doc.get("productionReady") == false)
	assert(doc.get("canonicalNavigationAuthority") == false)
	assert(doc.get("coordinateSpace") == "image-pixel")
	assert(doc["source"]["sha256"] == hall_data["source"]["sha256"])
	assert(doc["source"]["gitBlobSha"] == hall_data["source"]["gitBlobSha"])
	assert(doc["waypoints"].size() == 22 and doc["routes"].size() == 19)
	assert(doc["roomCoverage"].size() == manifest["rooms"].size())
	assert(doc["unresolvedLocations"].size() == manifest["doors"].size() + 6)

	# Preserve all original Hall IDs, coordinates and edge direction in order.
	assert(hall_data["waypoints"].size() == 7 and hall_data["edges"].size() == 7)
	for i in range(7):
		var source_point: Dictionary = hall_data["waypoints"][i]
		var authored_point: Dictionary = doc["waypoints"][i]
		assert(authored_point["id"] == source_point["id"])
		assert(authored_point["pointPx"] == source_point["pointPx"])
		var source_edge: Dictionary = hall_data["edges"][i]
		var authored_edge: Dictionary = doc["routes"][i]
		assert(authored_edge["id"] == "QA-ROUTE-%03d" % (i + 1))
		assert(authored_edge["from"] == source_edge["from"])
		assert(authored_edge["to"] == source_edge["to"])
		assert(authored_edge["bidirectional"] == source_edge["bidirectional"])
		assert(authored_edge["provisional"] and authored_edge["cells"].is_empty())

	# Stable unique IDs and valid bounded pixel positions.
	var points_by_id: Dictionary = {}
	for waypoint in doc["waypoints"]:
		var id: String = str(waypoint["id"])
		assert(not points_by_id.has(id))
		points_by_id[id] = waypoint
		assert(Routes._inside_art(Routes._vector(waypoint["pointPx"]), doc))
		assert(not Routes._is_restricted(Routes._vector(waypoint["pointPx"]), doc))
	var route_ids: Dictionary = {}
	for route in doc["routes"]:
		var id: String = str(route["id"])
		assert(not route_ids.has(id))
		route_ids[id] = true
		assert(points_by_id.has(route["from"]) and points_by_id.has(route["to"]))
		assert(route["bidirectional"] == true, "No invented one-way restrictions")
		if not route["provisional"]:
			assert(route["calibrationStatus"] == "AI_PROVISIONAL_UNAPPROVED")
			assert(route["cells"].size() >= 2)
			var parsed: Dictionary = Routes.parse_route_text(" → ".join(PackedStringArray(route["cells"])), doc)
			assert(parsed.ok and parsed.cells == route["cells"])
			assert(route["cells"][0] == Routes.pixel_to_cell(Routes._vector(points_by_id[route["from"]]["pointPx"]), doc))
			assert(route["cells"].back() == Routes.pixel_to_cell(Routes._vector(points_by_id[route["to"]]["pointPx"]), doc))
			var positions: PackedVector2Array = Routes.route_points(route, doc)
			for step in range(1, positions.size()):
				assert(Routes._check_segment(positions[step - 1], positions[step], doc).is_empty(), "Blocked/outside authored segment: " + id)

	# Each of the five authored room islands is internally connected.
	var covered_rooms: Array[String] = ["RM-ROOM-HALL", "RM-ROOM-CORRIDOR", "RM-ROOM-BEDROOM", "RM-ROOM-ARCHIVE", "RM-ROOM-KITCHEN"]
	for room in covered_rooms:
		var member_ids: Array[String] = []
		for waypoint in doc["waypoints"]:
			if str(waypoint.get("roomId", "RM-ROOM-HALL")) == room:
				member_ids.append(str(waypoint["id"]))
		assert(member_ids.size() >= 2, "Room needs an authored route island: " + room)
		var seen: Dictionary = {}
		var queue: Array[String] = [member_ids[0]]
		while not queue.is_empty():
			var current: String = queue.pop_front()
			if seen.has(current):
				continue
			seen[current] = true
			for route in doc["routes"]:
				if str(points_by_id[route["from"]].get("roomId", "RM-ROOM-HALL")) != room:
					continue
				if str(points_by_id[route["to"]].get("roomId", "RM-ROOM-HALL")) != room:
					continue
				if route["from"] == current and not seen.has(route["to"]):
					queue.append(str(route["to"]))
				if route["bidirectional"] and route["to"] == current and not seen.has(route["from"]):
					queue.append(str(route["from"]))
		assert(seen.size() == member_ids.size(), "Disconnected authored segments in " + room)

	# No fictional door pairs: all manifest doors remain explicit unresolved.
	for door in manifest["doors"]:
		var found := false
		for item in doc["unresolvedLocations"]:
			if item.get("doorId") == door["id"] and item.get("status") == "UNRESOLVED":
				assert(item.get("sourcePixelFootpoints", null) == null)
				found = true
		assert(found, "Missing unresolved physical door: " + str(door["id"]))
	assert(doc["virtualHallPortal"]["kind"] == "VIRTUAL_QA_ONLY_NOT_PHYSICAL")
	assert(points_by_id.has(doc["virtualHallPortal"]["doorApproachId"]))
	assert(points_by_id.has(doc["virtualHallPortal"]["returnSpawnId"]))
	assert(points_by_id[doc["virtualHallPortal"]["doorApproachId"]]["type"] == "Door Approach")
	assert(points_by_id[doc["virtualHallPortal"]["returnSpawnId"]]["type"] == "Return Spawn")

	# MAP-EDIT-02 now plays persisted exported drafts. Disconnected islands
	# must remain unreachable from Hall spawn, not virtual room transitions.
	var playable = PreviewSource.new()
	assert(playable.load_source(PreviewSource.PROJECT), playable.error_text)
	assert(playable.data.get("qaTaskId") == "MAP-QA-05")
	assert(playable.graph.has_anchor("QA-CORRIDOR-CENTRE"))
	assert(playable.graph.has_anchor("QA-BEDROOM-RUG"))
	assert(playable.graph.has_anchor("QA-KITCHEN-NORTH"))
	assert(not playable.graph.route("QA-HALL-SPAWN", "QA-HALL-CIRCULATION-W").is_empty())
	for distant in ["QA-CORRIDOR-WEST", "QA-BEDROOM-RUG", "QA-LIBRARY-NORTH", "QA-KITCHEN-NORTH"]:
		assert(playable.graph.route("QA-HALL-SPAWN", distant).is_empty(), "No fictional Hall crossing to " + distant)
	assert(playable.provisional_routes.size() == 7, "Seven original uncalibrated Hall edges remain explicitly provisional")
	# Editor graph and actual disk serialization round trip without production write.
	assert(Routes.compile_qa_graph(doc).ok)
	assert(Routes.route_preview(doc, "QA-CORRIDOR-WEST", "QA-CORRIDOR-EAST").ok)
	assert(not Routes.route_preview(doc, "QA-CORRIDOR-WEST", "QA-BEDROOM-RUG").ok)
	var scratch := "user://room_builder_routes/MAP-QA-05-roundtrip.json"
	var saved: Dictionary = Routes.save_draft(scratch, doc)
	assert(saved.ok, str(saved.get("error", "")))
	var reopened: Dictionary = Routes.load_draft(scratch)
	assert(reopened.ok, str(reopened.get("error", "")))
	assert(JSON.stringify(reopened.document) == JSON.stringify(doc), "Round-trip must preserve stable IDs and unresolved records")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(scratch))
	assert(FileAccess.get_file_as_string(Routes.HALL_SOURCE) == original_hall, "Original Hall source mutated")
	assert(FileAccess.get_file_as_string(CANONICAL) == canonical_before, "Canonical game graph mutated")
	print("MAP-QA-05 first floor draft geometry smoke passed")
	quit(0)
