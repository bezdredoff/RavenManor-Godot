extends RefCounted
## MAP-QA-09 evidence only. Never compiles a crossing or unlocks a door.
const Routes = preload("res://addons/room_builder_routes/route_document.gd")
const PATH := "res://assets/raven/map/qa/drafts/map_qa_09_door_review.v1.json"
const MANIFEST := "res://assets/raven/map/first_floor_manifest.v1.json"
const CANDIDATE := "res://assets/raven/map/qa/drafts/map_qa_08_visual_candidate.v1.json"


static func load_review(path: String = PATH) -> Dictionary:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not raw is Dictionary:
		return _bad("Door review JSON is missing or invalid")
	var checked := validate(raw)
	if not checked.ok:
		return checked
	if FileAccess.get_sha256("res://" + Routes.IMAGE_PATH) != Routes.IMAGE_SHA256:
		return _bad("Approved PNG identity mismatch")
	return {"ok":true, "document":raw}


static func validate(doc: Dictionary) -> Dictionary:
	if doc.get("schemaVersion") != 1 or doc.get("kind") != "raven-first-floor-door-review":
		return _bad("Unsupported door review schema")
	if doc.get("approval") != "DRAFT_ONLY" or doc.get("productionReady") != false or doc.get("runtimeAuthority") != false:
		return _bad("Door review cannot grant production or movement authority")
	if doc.get("coordinateSpace") != "image-pixel":
		return _bad("Door review requires original image pixels")
	var source: Variant = doc.get("source")
	if not source is Dictionary or source.get("sha256") != Routes.IMAGE_SHA256 or source.get("gitBlobSha") != Routes.IMAGE_BLOB_SHA or source.get("path") != Routes.IMAGE_PATH or Routes._vector(source.get("dimensionsPx")) != Vector2(1672, 941):
		return _bad("Door review source identity mismatch")
	# Normalize checkout line endings; byte-identical art is verified separately.
	var route_hash := FileAccess.get_file_as_string(CANDIDATE).replace("\r\n", "\n").sha256_text()
	if doc.get("routeDraftPath") != CANDIDATE or doc.get("routeDraftSha256") != route_hash:
		return _bad("Door review stops refer to a different route draft; recalibrate explicitly")
	var draft := Routes.load_draft(CANDIDATE)
	if not draft.get("ok", false):
		return _bad("Referenced 08B route document is invalid")
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	var references: Dictionary = {}
	for door in manifest.doors:
		references[door.id] = door
	var doors: Variant = doc.get("doors")
	if not doors is Array or doors.size() != references.size():
		return _bad("Door review must cover all 11 manifest doors")
	var seen: Dictionary = {}
	var points := Routes._waypoint_lookup(draft.document)
	for door in doors:
		if not door is Dictionary:
			return _bad("Door record must be an object")
		var id := str(door.get("id", ""))
		if not references.has(id) or seen.has(id):
			return _bad("Unknown or duplicate physical door: " + id)
		seen[id] = true
		if door.get("roomIds") != references[id].roomIds or door.get("referenceState") != references[id].referenceState:
			return _bad("Logical topology/story gate changed in " + id)
		if door.get("status") != "UNRESOLVED" or door.get("physicalPortalApproved") != false or door.get("traversalEnabled") != false:
			return _bad("Unverified physical door cannot be enabled: " + id)
		for field in ["nearSideFootpointPx", "farSideFootpointPx", "openingWidthPx"]:
			if not door.has(field) or door[field] != null:
				return _bad("Unresolved threshold cannot claim physical contacts: " + id)
		var point: Variant = door.get("thresholdCandidatePx")
		if point != null and not Routes._inside_art(Routes._vector(point), draft.document):
			return _bad("Door landmark outside original image: " + id)
		var box: Variant = door.get("reviewRectPx")
		if not box is Array or box.size() != 4:
			return _bad("Invalid review crop: " + id)
		for number in box:
			if not (number is int or number is float) or not is_finite(float(number)):
				return _bad("Non-finite review crop: " + id)
		if box[0] < 0 or box[1] < 0 or box[2] <= 0 or box[3] <= 0 or box[0] + box[2] > 1672 or box[1] + box[3] > 941:
			return _bad("Review crop outside original image: " + id)
		if not door.get("roomSideStops") is Array or str(door.get("evidence", "")).is_empty():
			return _bad("Missing review evidence/stops: " + id)
		for stop in door.roomSideStops:
			if not stop is Dictionary:
				return _bad("Invalid room stop: " + id)
			var wp := str(stop.get("waypointId", ""))
			var room := str(stop.get("roomId", ""))
			if not door.roomIds.has(room) or not points.has(wp) or Routes.waypoint_room(points[wp]) != room:
				return _bad("Door stop is missing or belongs to another room: " + id)
	return {"ok":true}


static func crossing_request(doc: Dictionary, door_id: String) -> Dictionary:
	# Even crafted/invalid documents cannot create a runtime transition here.
	var checked := validate(doc)
	if not checked.ok:
		return checked
	for door in doc.doors:
		if door.id == door_id:
			return {"ok":false, "error":"physical-threshold-unresolved", "doorId":door_id}
	return _bad("unknown-door")


static func _bad(reason: String) -> Dictionary:
	return {"ok":false, "error":reason}
