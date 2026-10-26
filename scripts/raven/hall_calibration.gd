extends RefCounted
## Source-parity and safety gate for NONCANONICAL calibration-only geometry.
## Never writes the world graph, canonical prop JSON, save, or authoring manifest.

static func _rect(parts: Array) -> Rect2:
	return Rect2(float(parts[0]), float(parts[1]), float(parts[2]), float(parts[3]))

static func inspect(calibration: Dictionary, world: Dictionary, art: Dictionary) -> Dictionary:
	var rejected := {"ready": false, "reason": "", "candidate_seats": [],
		"doors": [], "stairs": [], "original_seats": Rect2()}
	if int(calibration.get("schemaVersion", 0)) != 1 or \
			str(calibration.get("status", "")) != "CALIBRATION_ONLY_UNAPPROVED":
		rejected.reason = "Invalid calibration schema or approval flag"
		return rejected
	var gates: Dictionary = calibration.get("gates", {})
	for key in ["replaceCanonicalCollider", "applyToCampaign", "approvedBackground", "acceptedPixelMargins"]:
		if bool(gates.get(key, true)):
			rejected.reason = "Calibration falsely claims approval: " + key
			return rejected
	var rooms: Array = world.get("rooms", [])
	var hall_index := -1
	for i in range(rooms.size()):
		if str(rooms[i].get("id", "")) == "RM-ROOM-HALL": hall_index = i
	if hall_index < 0 or str(calibration.get("roomId", "")) != "RM-ROOM-HALL":
		rejected.reason = "Hall room missing"
		return rejected
	var bounds := _rect(rooms[hall_index].rect)
	if _rect(calibration.get("roomWorldRect", [0, 0, 0, 0])) != bounds or \
			_rect(art.get("roomWorldRect", [0, 0, 0, 0])) != bounds:
		rejected.reason = "Hall source bounds changed"
		return rejected
	var props := {}
	for prop in world.get("props", []):
		if int(prop.room) == hall_index: props[str(prop.id)] = _rect(prop.rect)
	if not props.has("RM-ASSET-HALL-SEATS"):
		rejected.reason = "Missing canonical seat footprint"
		return rejected
	var original: Rect2 = props["RM-ASSET-HALL-SEATS"]
	if _rect(calibration.get("originalSeatCollider", [0, 0, 0, 0])) != original:
		rejected.reason = "Canonical seat cluster changed"
		return rejected
	var source_doors := {}
	for entry in world.get("doors", []):
		if int(entry.a) == hall_index or int(entry.b) == hall_index:
			source_doors[str(entry.id)] = entry
	var door_entries: Array = calibration.get("doors", [])
	if door_entries.size() != source_doors.size(): 
		rejected.reason = "Door count does not match world"
		return rejected
	var confirmed_doors := {}
	var door_result: Array = []
	for candidate in door_entries:
		var key := str(candidate.get("id", ""))
		if not source_doors.has(key) or confirmed_doors.has(key):
			rejected.reason = "Missing or duplicate calibration doorway: " + key
			return rejected
		var live: Dictionary = source_doors[key]
		var p := Vector2(float(candidate.point[0]), float(candidate.point[1]))
		if p.distance_to(Vector2(float(live.point[0]), float(live.point[1]))) > 0.001 or \
				str(candidate.status) != str(live.status):
			rejected.reason = "Door/status location changed: " + key
			return rejected
		confirmed_doors[key] = true
		door_result.append({"id": key, "point": p, "status": str(candidate.status),
			"kind": str(candidate.kind)})
	var expected_stairs := props.keys().filter(func(k): return str(k).contains("STAIRS"))
	var stair_entries: Array = calibration.get("stairs", [])
	if stair_entries.size() != expected_stairs.size():
		rejected.reason = "Staircase count changed"
		return rejected
	var stairs: Array = []
	for stair in stair_entries:
		var key := str(stair.get("id", ""))
		if not props.has(key) or not expected_stairs.has(key) or \
				_rect(stair.rect) != props[key] or int(stair.treads) < 2:
			rejected.reason = "Staircase source footprint changed: " + key
			return rejected
		stairs.append({"id": key, "rect": props[key], "treads": int(stair.treads)})
	var source_sprite_ids := {}
	for sprite in art.get("sprites", []):
		source_sprite_ids[str(sprite.assetRefId)] = sprite
	var new_seats: Array = []
	var seen := {}
	for proposal in calibration.get("candidateSeatFootprints", []):
		var ref := str(proposal.get("assetRefId", ""))
		if not source_sprite_ids.has(ref) or seen.has(ref) or \
				str(proposal.get("status", "")) != "UNAPPROVED":
			rejected.reason = "Unknown or approved-looking furniture footprint: " + ref
			return rejected
		if ref not in ["RM-ASSET-HALL-017", "RM-ASSET-HALL-018", "RM-ASSET-HALL-019"]:
			rejected.reason = "Unexpected furniture footprint: " + ref
			return rejected
		var box := _rect(proposal.rect)
		var sprite := _rect(source_sprite_ids[ref].rect)
		if box.size.x <= 0.0 or box.size.y <= 0.0 or \
				not original.encloses(box) or not sprite.encloses(box):
			rejected.reason = "Seat proposal leaves original physical bounds or cutout"
			return rejected
		seen[ref] = true
		new_seats.append({"ref": ref, "rect": box})
	if seen.size() != 3:
		rejected.reason = "Need exactly three separate provisional seat contact bounds"
		return rejected
	# The only approved behavior is existing collider; smaller candidate boxes
	# can be enabled temporarily in test UI and always reset on new scene load.
	return {"ready": true, "reason": "", "candidate_seats": new_seats,
		"doors": door_result, "stairs": stairs, "original_seats": original}
