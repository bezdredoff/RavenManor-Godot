extends RefCounted
## Architectural greybox proposal, never a production door importer.
const Routes = preload("res://addons/room_builder_routes/route_document.gd")
const Manifest := "res://assets/raven/map/first_floor_manifest.v1.json"
const PATH := "res://assets/raven/map/qa/drafts/map_qa_09b_opening_blueprint.v1.json"


static func apply_to(loaded: Dictionary) -> Dictionary:
	var doc: Dictionary = loaded.get("document", {})
	if doc.get("taskId") != "MAP-QA-09B":
		return loaded
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Manifest))
	var logical := {}
	for door in manifest.doors:
		logical[door.id] = door.roomIds
	var contacts: Array = doc.get("sharedDoorContacts", [])
	if contacts.is_empty():
		return {"ok":false, "error":"Opening blueprint requires explicit paired contacts"}
	var lookup := Routes._waypoint_lookup(doc)
	var contract: Dictionary = loaded.contract.duplicate(true)
	contract.doors = []
	contract.transitions = []
	var seen_doors := {}
	for contact in contacts:
		var door_id := str(contact.get("doorId", ""))
		var pair: Array = contact.waypointIds
		var rooms: Array = contact.roomIds
		if not logical.has(door_id) or not logical[door_id].has(rooms[0]) or not logical[door_id].has(rooms[1]):
			return {"ok":false, "error":"Opening proposal changes logical topology: " + door_id}
		var width: Variant = contact.get("openingWidthPx")
		var normal := Routes._vector(contact.get("normalPx"))
		if seen_doors.has(door_id) or not (width is int or width is float) or not is_finite(float(width)) or float(width) < 24 or float(width) > 128 or not normal.is_finite() or absf(normal.length()-1.0) > 0.001:
			return {"ok":false, "error":"Invalid opening width/normal or duplicate door"}
		seen_doors[door_id] = true
		var a := Routes._vector(lookup[pair[0]].pointPx)
		var b := Routes._vector(lookup[pair[1]].pointPx)
		if a.distance_to(b) > 0.001:
			return {"ok":false, "error":"Shared threshold sides differ; no relocation allowed: " + door_id}
		contract.doors.append({"id":door_id, "status":"gated"})
		for side in range(2):
			var id := str(contact.id) + ("-AB" if side == 0 else "-BA")
			var reverse := str(contact.id) + ("-BA" if side == 0 else "-AB")
			contract.transitions.append({"id":id, "sourceRoomId":rooms[side], "destinationRoomId":rooms[1-side],
				"approachAnchorId":pair[side], "destinationEntryAnchorId":pair[1-side],
				"reverseTransitionId":reverse, "doorId":door_id, "authority":"TEST_ONLY",
				"physicalPortalApproved":false, "geometryStatus":"AI_PROPOSED_ARCHITECTURE"})
		for room in contract.rooms:
			for anchor in room.graph.anchors:
				if pair.has(anchor.id):
					anchor.kind = "safe"
	loaded.contract = contract
	loaded.syntheticTransitions = false
	loaded.openingBlueprint = true
	return loaded
