extends RefCounted

## Candidate anchor POSITION overlay only. Never approves Hall geometry, doors,
## collisions, Y-sort or a Room Builder scene; the canonical graph stays immutable.
## Input: {schemaVersion:1, coordinateSpace:"world-plan", productionReady:false,
##         anchors:[{id:"RM-NAV-*", roomId:"RM-ROOM-*", position:[x,y]}]}.
## World-plan XY is *unprojected*. The scene applies the approved 65-degree view.


static func apply_preview(canonical: Dictionary, candidate: Dictionary) -> Dictionary:
	if int(candidate.get("schemaVersion", -1)) != 1:
		return {"ok": false, "error": "unknown-schema"}
	if str(candidate.get("coordinateSpace", "")) != "world-plan":
		return {"ok": false, "error": "unknown-coordinate-space"}
	if bool(candidate.get("productionReady", false)):
		return {"ok": false, "error": "approval-is-external"}
	var source_anchors: Variant = canonical.get("anchors", [])
	var overrides: Variant = candidate.get("anchors", null)
	if not source_anchors is Array or not overrides is Array or overrides.is_empty():
		return {"ok": false, "error": "missing-anchors"}
	var by_id := {}
	for index in range(source_anchors.size()):
		var record: Dictionary = source_anchors[index]
		var anchor_id := str(record.get("id", ""))
		if anchor_id.is_empty() or by_id.has(anchor_id):
			return {"ok": false, "error": "invalid-canonical-anchor"}
		by_id[anchor_id] = index
	var preview: Dictionary = canonical.duplicate(true)
	var seen := {}
	for record_value in overrides:
		if not record_value is Dictionary:
			return {"ok": false, "error": "invalid-anchor"}
		var record: Dictionary = record_value
		var anchor_id := str(record.get("id", ""))
		if not by_id.has(anchor_id) or seen.has(anchor_id):
			return {"ok": false, "error": "unknown-or-duplicate-anchor"}
		var current: Dictionary = preview["anchors"][int(by_id[anchor_id])]
		if str(record.get("roomId", "")) != str(current.get("roomId", "")):
			return {"ok": false, "error": "room-id-mismatch"}
		var point: Variant = record.get("position")
		if not point is Array or point.size() != 2:
			return {"ok": false, "error": "invalid-position"}
		for coordinate in point:
			if not (coordinate is int or coordinate is float) or not is_finite(float(coordinate)):
				return {"ok": false, "error": "non-finite-position"}
		current["position"] = [float(point[0]), float(point[1])]
		preview["anchors"][int(by_id[anchor_id])] = current
		seen[anchor_id] = true
	var provenance: Dictionary = canonical.get("provenance", {}).duplicate(true)
	provenance["geometryStatus"] = "candidate-preview"
	provenance["productionReady"] = false
	provenance["roomArtCalibration"] = "pending"
	preview["provenance"] = provenance
	return {"ok": true, "data": preview, "updatedAnchorCount": seen.size()}


## Validate an Agent A art manifest without importing its greybox/pixel reference values.
## A's referenceGreyboxPoint and sourcePixelFootpoint are NEVER navigation coordinates.
static func audit_art_reference(canonical: Dictionary, manifest: Dictionary, world: Dictionary) -> Dictionary:
	if manifest.get("schemaVersion") != 1 or manifest.get("contractId") != "raven.first-floor-art":
		return {"ok": false, "error": "invalid-art-manifest"}
	if manifest.get("productionReady", false) != false or manifest.get("integrationAllowed", false) != false:
		return {"ok": false, "error": "unapproved-art-promotion"}
	var systems: Variant = manifest.get("coordinateSystems")
	if not systems is Dictionary:
		return {"ok": false, "error": "missing-coordinate-systems"}
	if systems.get("worldPlan", {}).get("origin", "") != "reference_season1_world_map":
		return {"ok": false, "error": "wrong-world-origin"}
	if systems.get("greyboxGraph", {}).get("directMappingToWorldPlan", null) != false:
		return {"ok": false, "error": "unsafe-greybox-world-mapping"}
	var reference_rooms: Variant = world.get("rooms", [])
	var reference_doors: Variant = world.get("doors", [])
	var rooms: Variant = manifest.get("rooms", null)
	var doors: Variant = manifest.get("doors", null)
	var refs: Variant = manifest.get("navigationReferenceAnchors", null)
	if not rooms is Array or not doors is Array or not refs is Array:
		return {"ok": false, "error": "missing-art-reference-ids"}
	if rooms.size() != reference_rooms.size() or doors.size() != reference_doors.size() or refs.size() != canonical.get("anchors", []).size():
		return {"ok": false, "error": "incomplete-art-reference-ids"}
	var known_rooms := {}
	for room_value in reference_rooms:
		known_rooms[str(room_value.get("id", ""))] = true
	var seen_rooms := {}
	for raw_room in rooms:
		if not raw_room is Dictionary:
			return {"ok": false, "error": "invalid-art-room"}
		var id := str(raw_room.get("id", ""))
		if not known_rooms.has(id) or seen_rooms.has(id):
			return {"ok": false, "error": "art-room-id-mismatch"}
		seen_rooms[id] = true
	var known_doors := {}
	for door_value in reference_doors:
		var a: int = int(door_value.get("a", -1))
		var b: int = int(door_value.get("b", -1))
		known_doors[str(door_value.get("id", ""))] = [str(reference_rooms[a].get("id", "")), str(reference_rooms[b].get("id", "")) if b >= 0 else null]
	var seen_doors := {}
	for raw_door in doors:
		if not raw_door is Dictionary:
			return {"ok": false, "error": "invalid-art-door"}
		var id := str(raw_door.get("id", ""))
		if not known_doors.has(id) or seen_doors.has(id) or raw_door.get("roomIds", null) != known_doors[id]:
			return {"ok": false, "error": "art-door-id-or-room-pair-mismatch"}
		seen_doors[id] = true
	var known_anchors := {}
	for anchor_value in canonical.get("anchors", []):
		known_anchors[str(anchor_value.get("id", ""))] = anchor_value
	var seen := {}
	var calibrated := 0
	for raw_anchor in refs:
		if not raw_anchor is Dictionary:
			return {"ok": false, "error": "invalid-art-anchor"}
		var id := str(raw_anchor.get("id", ""))
		if not known_anchors.has(id) or seen.has(id):
			return {"ok": false, "error": "art-anchor-id-mismatch"}
		var authored: Dictionary = known_anchors[id]
		if raw_anchor.get("roomId", null) != authored.get("roomId", "") or raw_anchor.get("kind", null) != authored.get("kind", ""):
			return {"ok": false, "error": "art-anchor-room-or-kind-mismatch"}
		if raw_anchor.get("referenceSpace", "") != "independent_greybox":
			return {"ok": false, "error": "art-reference-space-mismatch"}
		var world_point: Variant = raw_anchor.get("calibratedWorldPlanPoint", null)
		if world_point != null:
			if not _valid_xy(world_point):
				return {"ok": false, "error": "invalid-calibrated-world-point"}
			calibrated += 1
		seen[id] = true
	# Audit-only: even 13 calibrated values are not imported or accepted here.
	return {"ok": true, "idCount": seen.size(), "calibratedCount": calibrated, "usableNavigationData": false}


## Exact B v2 -> C v1 DRAFT_ONLY bridge. No pixel/screen coordinates or
## implicit greybox coordinate fallback. Requires a complete 13-anchor overlay.
static func from_builder_draft(canonical: Dictionary, project_or_draft: Dictionary, world: Dictionary) -> Dictionary:
	var draft: Variant = project_or_draft.get("firstFloorDraft", project_or_draft)
	if not draft is Dictionary or draft.get("schemaVersion") != 2 or draft.get("kind") != "raven-first-floor-draft":
		return {"ok": false, "error": "invalid-builder-version"}
	if draft.get("productionReady", false) != false:
		return {"ok": false, "error": "approval-is-external"}
	var calibration: Variant = draft.get("calibration", null)
	if not calibration is Dictionary:
		return {"ok": false, "error": "missing-calibration"}
	var world_rect: Variant = calibration.get("worldRect", null)
	var world_size: Variant = world.get("worldSize", null)
	if not _valid_rect(world_rect) or not _valid_xy(world_size):
		return {"ok": false, "error": "invalid-world-frame"}
	# Freeze the provisional world frame during this integration contract revision.
	# A different approved origin/size needs a new explicit contract, not an offset.
	if world_rect != [0, 0, world_size[0], world_size[1]]:
		return {"ok": false, "error": "world-frame-mismatch"}
	var image_rect: Variant = calibration.get("imageRect", null)
	var control_points: Variant = calibration.get("controlPoints", null)
	if not _valid_rect(image_rect) or not control_points is Array or control_points.size() < 2:
		return {"ok": false, "error": "missing-image-calibration"}
	var region_values: Variant = draft.get("roomRegions", null)
	var door_values: Variant = draft.get("doorPlacements", null)
	var nav_values: Variant = draft.get("navigationAnchors", null)
	if not region_values is Array or not door_values is Array or not nav_values is Array:
		return {"ok": false, "error": "missing-builder-records"}
	var room_records: Variant = world.get("rooms", [])
	var door_records: Variant = world.get("doors", [])
	if region_values.size() != room_records.size() or door_values.size() != door_records.size():
		return {"ok": false, "error": "incomplete-world-identities"}
	var known_rooms := {}
	for ref_room in room_records:
		known_rooms[str(ref_room.get("id", ""))] = true
	var regions := {}
	for raw_region in region_values:
		if not raw_region is Dictionary:
			return {"ok": false, "error": "invalid-region"}
		var id := str(raw_region.get("id", ""))
		var rect: Variant = raw_region.get("rect", null)
		if not known_rooms.has(id) or regions.has(id) or not _valid_rect(rect):
			return {"ok": false, "error": "invalid-region-id-or-rect"}
		if not _point_in_rect([rect[0], rect[1]], world_rect) or not _point_in_rect([rect[0] + rect[2], rect[1] + rect[3]], world_rect):
			return {"ok": false, "error": "region-outside-world"}
		regions[id] = rect
	var known_doors := {}
	for ref_door in door_records:
		var a: int = int(ref_door.get("a", -1))
		var b: int = int(ref_door.get("b", -1))
		known_doors[str(ref_door.get("id", ""))] = [str(room_records[a].get("id", "")), str(room_records[b].get("id", "")) if b >= 0 else null]
	var seen_doors := {}
	for raw_door in door_values:
		if not raw_door is Dictionary:
			return {"ok": false, "error": "invalid-builder-door"}
		var id := str(raw_door.get("id", ""))
		if not known_doors.has(id) or seen_doors.has(id) or raw_door.get("rooms", null) != known_doors[id] or not _valid_xy(raw_door.get("point", null)):
			return {"ok": false, "error": "builder-door-id-or-pair-mismatch"}
		if not _point_in_rect(raw_door["point"], world_rect):
			return {"ok": false, "error": "door-outside-world"}
		seen_doors[id] = true
	var known_anchors := {}
	for raw_anchor in canonical.get("anchors", []):
		known_anchors[str(raw_anchor.get("id", ""))] = raw_anchor
	if nav_values.size() != known_anchors.size():
		return {"ok": false, "error": "incomplete-navigation-anchor-set"}
	var coordinates := []
	var seen_anchors := {}
	for raw_nav in nav_values:
		if not raw_nav is Dictionary:
			return {"ok": false, "error": "invalid-builder-anchor"}
		var id := str(raw_nav.get("id", ""))
		if not known_anchors.has(id) or seen_anchors.has(id):
			return {"ok": false, "error": "builder-anchor-id-mismatch"}
		var original: Dictionary = known_anchors[id]
		var room_id := str(raw_nav.get("roomId", ""))
		var point: Variant = raw_nav.get("point", null)
		if room_id != original.get("roomId", "") or not _valid_xy(point):
			return {"ok": false, "error": "builder-anchor-room-or-coordinates"}
		if not _point_in_rect(point, regions[room_id]) or not _point_in_rect(point, world_rect):
			return {"ok": false, "error": "builder-anchor-outside-room"}
		coordinates.append({"id": id, "roomId": room_id, "position": point.duplicate(true)})
		seen_anchors[id] = true
	var candidate := {
		"schemaVersion": 1, "coordinateSpace": "world-plan",
		"productionReady": false, "anchors": coordinates
	}
	var overlay: Dictionary = apply_preview(canonical, candidate)
	if not overlay.get("ok", false):
		return overlay
	overlay["complete"] = true
	overlay["runtimeApproved"] = false
	var provenance: Dictionary = overlay["data"]["provenance"]
	provenance["coordinateSpace"] = "world-plan"
	provenance["sourceDraftSchema"] = 2
	return overlay


static func _valid_xy(point: Variant) -> bool:
	if not point is Array or point.size() != 2:
		return false
	for coordinate in point:
		if not (coordinate is float or coordinate is int) or not is_finite(float(coordinate)):
			return false
	return true


static func _valid_rect(rect: Variant) -> bool:
	if not rect is Array or rect.size() != 4:
		return false
	for coordinate in rect:
		if not (coordinate is float or coordinate is int) or not is_finite(float(coordinate)):
			return false
	return float(rect[2]) > 0.0 and float(rect[3]) > 0.0


static func _point_in_rect(point: Array, rect: Array) -> bool:
	return float(point[0]) >= float(rect[0]) and float(point[0]) <= float(rect[0]) + float(rect[2]) and \
		float(point[1]) >= float(rect[1]) and float(point[1]) <= float(rect[1]) + float(rect[3])
