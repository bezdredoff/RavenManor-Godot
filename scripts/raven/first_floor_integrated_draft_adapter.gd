extends RefCounted
## MAP-QA-07B: read-only DRAFT_ONLY → room-owned MAP-QA-06 fixture.
## One image-pixel coordinate space; no canonical import, promotion or save.
const Routes = preload("res://addons/room_builder_routes/route_document.gd")
const Preview = preload("res://addons/room_builder_routes/route_preview_source.gd")
const Original = preload("res://scripts/raven/first_floor_hall_qa_graph.gd")
const ART := "res://a_detailed_top_down_isometric_game_map_illustratio.png"
const HALL := "RM-ROOM-HALL"
const CORRIDOR := "RM-ROOM-CORRIDOR"
const BEDROOM := "RM-ROOM-BEDROOM"
const ARCHIVE := "RM-ROOM-ARCHIVE"
const KITCHEN := "RM-ROOM-KITCHEN"
const ROOM_IDS := [HALL, CORRIDOR, BEDROOM, ARCHIVE, KITCHEN]
const STARTS := {
	HALL: "QA-HALL-SPAWN",
	CORRIDOR: "QA-CORRIDOR-WEST",
	BEDROOM: "QA-BEDROOM-RUG",
	ARCHIVE: "QA-LIBRARY-NORTH",
	KITCHEN: "QA-KITCHEN-NORTH"
}


static func load_source(kind: String = Preview.PROJECT, path: String = "") -> Dictionary:
	if not FileAccess.file_exists(ART):
		return _bad("Approved image is missing: " + ART)
	if FileAccess.get_sha256(ART) != Routes.IMAGE_SHA256:
		return _bad("Approved first-floor PNG SHA-256 does not match")
	var preview = Preview.new()
	if not preview.load_source(kind, path):
		return _bad(preview.error_text)
	if kind == Preview.BASELINE:
		var hall_anchors: Array = []
		for id in preview.waypoint_ids():
			hall_anchors.append(preview.graph.anchor(str(id)).duplicate(true))
		var hall_graph := {
			"provenance": {"approval":"DRAFT_ONLY", "productionReady":false,
				"coordinateSpace":"image-pixel", "geometryStatus":"original-hall-baseline"},
			"anchors":hall_anchors, "edges":preview.graph.active_edges()
		}
		var contract := _contract([{"id":HALL, "label":"ORIGINAL HALL QA", "graph":hall_graph}], [], [])
		return {"ok":true, "contract":contract, "visuals":_visuals([HALL]),
			"document":{}, "sourceKind":kind, "sourcePath":preview.source_path,
			"initialRoomId":HALL, "initialAnchorId":"QA-HALL-SPAWN",
			"starts":{HALL:"QA-HALL-SPAWN"}, "waypointCount":hall_anchors.size(),
			"routeCount":hall_graph.edges.size(), "unresolvedCount":0,
			"syntheticTransitions":false}
	var doc: Dictionary = preview.data.duplicate(true)
	# Preview's existing compiler produces physical ordered STEP anchors but
	# gives every anchor a Hall roomId. Repair room ownership ONLY in the
	# isolated QA contract, never in the editor source or canonical graph.
	var compiled: Dictionary = Routes.compile_qa_graph(doc)
	if not bool(compiled.get("ok", false)):
		return _bad(str(compiled.get("error", "Invalid QA compilation")))
	var ownership: Dictionary = {}
	for wp in doc["waypoints"]:
		var id := str(wp.get("id", ""))
		var room := str(wp.get("roomId", ""))
		# MAP-EDIT-01's original seven Hall points predate roomId metadata.
		if room.is_empty() and Original.PILOT_IDS.has(id):
			room = HALL
		if not ROOM_IDS.has(room) or ownership.has(id):
			return _bad("Unowned/duplicate waypoint: " + id + " (roomId required)")
		ownership[id] = room
	var route_rooms: Dictionary = {}
	for route in doc["routes"]:
		var from_id := str(route.get("from", ""))
		var to_id := str(route.get("to", ""))
		if not ownership.has(from_id) or not ownership.has(to_id):
			return _bad("Route endpoint missing: " + str(route.get("id", "")))
		var room: String = str(ownership[from_id])
		if room != str(ownership[to_id]):
			return _bad("Cross-room route forbidden without approved portal: " + str(route["id"]))
		route_rooms[str(route["id"])] = room
		var cells: Array = route.get("cells", [])
		for step in range(1, cells.size() - 1):
			var step_id := "%s-STEP-%03d" % [str(route["id"]), step]
			if ownership.has(step_id):
				return _bad("Duplicate compiled step: " + step_id)
			ownership[step_id] = room
	var room_graphs: Dictionary = {}
	for room in ROOM_IDS:
		room_graphs[room] = {"provenance":{
			"approval":"DRAFT_ONLY", "productionReady":false,
			"coordinateSpace":"image-pixel", "geometryStatus":"AI_PROVISIONAL_UNAPPROVED",
			"sourceSha256":Routes.IMAGE_SHA256},
			"anchors":[], "edges":[]}
	var compiled_data: Dictionary = compiled["data"]
	for original in compiled_data["anchors"]:
		var anchor_id := str(original["id"])
		if not ownership.has(anchor_id):
			return _bad("Unowned compiled anchor: " + anchor_id)
		var room: String = str(ownership[anchor_id])
		var owned: Dictionary = original.duplicate(true)
		owned["roomId"] = room
		if str(STARTS.get(room, "")) == anchor_id or anchor_id == "QA-HALL-RETURN-SAFE" or anchor_id == "QA-CORRIDOR-EAST" or anchor_id == "QA-BEDROOM-SOUTH":
			owned["kind"] = "safe"
		room_graphs[room]["anchors"].append(owned)
	for original_edge in compiled_data["edges"]:
		var edge: Dictionary = original_edge
		var from_id := str(edge["from"])
		var to_id := str(edge["to"])
		if not ownership.has(from_id) or not ownership.has(to_id) or ownership[from_id] != ownership[to_id]:
			return _bad("Compiled cross-room/missing edge: " + from_id + " → " + to_id)
		if not route_rooms.has(str(edge.get("routeId", ""))) or str(route_rooms[str(edge["routeId"])]) != str(ownership[from_id]):
			return _bad("Route ownership mismatch: " + str(edge.get("routeId", "")))
		room_graphs[str(ownership[from_id])]["edges"].append(edge.duplicate(true))
	var rooms: Array = []
	var available_starts: Dictionary = {}
	for room in ROOM_IDS:
		var graph: Dictionary = room_graphs[room]
		if graph["anchors"].is_empty():
			continue
		if graph["edges"].is_empty() or not ownership.has(STARTS[room]) or str(ownership[STARTS[room]]) != room:
			return _bad("No safe authored start/route in " + room)
		rooms.append({"id":room, "label":room + " · AI DRAFT", "graph":graph})
		available_starts[room] = STARTS[room]
	if not available_starts.has(HALL):
		return _bad("Hall safe start missing")
	var doors: Array = []
	var transitions: Array = []
	var mock := available_starts.has(CORRIDOR) and available_starts.has(BEDROOM) \
		and ownership.has("QA-HALL-PORTAL-APPROACH") \
		and ownership.has("QA-HALL-RETURN-SAFE") \
		and ownership.has("QA-CORRIDOR-EAST") and ownership.has("QA-BEDROOM-SOUTH")
	if mock:
		doors = [
			{"id":"QA-07B-DOOR-HC", "status":"open"},
			{"id":"QA-07B-DOOR-CB", "status":"open"},
			{"id":"QA-07B-DOOR-LOCKED", "status":"gated"}]
		transitions = [
			_transition("QA-07B-TR-HC", HALL, CORRIDOR, "QA-HALL-PORTAL-APPROACH", STARTS[CORRIDOR], "QA-07B-TR-CH", "QA-07B-DOOR-HC"),
			_transition("QA-07B-TR-CH", CORRIDOR, HALL, STARTS[CORRIDOR], "QA-HALL-RETURN-SAFE", "QA-07B-TR-HC", "QA-07B-DOOR-HC"),
			_transition("QA-07B-TR-CB", CORRIDOR, BEDROOM, "QA-CORRIDOR-EAST", STARTS[BEDROOM], "QA-07B-TR-BC", "QA-07B-DOOR-CB"),
			_transition("QA-07B-TR-BC", BEDROOM, CORRIDOR, "QA-BEDROOM-SOUTH", "QA-CORRIDOR-EAST", "QA-07B-TR-CB", "QA-07B-DOOR-CB"),
			_transition("QA-07B-TR-LOCKED", HALL, CORRIDOR, "QA-HALL-WEST", STARTS[CORRIDOR], "", "QA-07B-DOOR-LOCKED")]
	# All 11 real manifest doors remain unresolved. QA transitions use
	# authored waypoints as MOCKED approaches, not real portal footpoints.
	return {"ok":true, "contract":_contract(rooms, doors, transitions),
		"visuals":_visuals(available_starts.keys()), "document":doc,
		"sourceKind":kind, "sourcePath":preview.source_path,
		"initialRoomId":HALL, "initialAnchorId":STARTS[HALL],
		"starts":available_starts, "waypointCount":doc["waypoints"].size(),
		"routeCount":doc["routes"].size(),
		"unresolvedCount":doc.get("unresolvedLocations", []).size(),
		"syntheticTransitions":mock}


static func _contract(rooms: Array, doors: Array, transitions: Array) -> Dictionary:
	return {"schemaVersion":1, "kind":"raven-authored-room-transitions",
		"approval":"TEST_ONLY", "draftAuthority":"DRAFT_ONLY", "rooms":rooms,
		"doors":doors, "transitions":transitions}


static func _transition(id: String, source: String, dest: String, approach: String,
		entry: String, reverse: String, door: String) -> Dictionary:
	return {"id":id, "sourceRoomId":source, "destinationRoomId":dest,
		"approachAnchorId":approach, "destinationEntryAnchorId":entry,
		"reverseTransitionId":reverse, "doorId":door, "authority":"TEST_ONLY",
		"physicalPortalApproved":false}


static func _visuals(room_ids: Array) -> Dictionary:
	var specs: Dictionary = {}
	for room in room_ids:
		specs[room] = {"source":"approved-art", "texturePath":ART,
			"bounds":[0,0,1672,941], "cameraZoom":1.0, "actorHeight":62.0}
	return specs


static func _bad(reason: String) -> Dictionary:
	return {"ok":false, "error":reason}
