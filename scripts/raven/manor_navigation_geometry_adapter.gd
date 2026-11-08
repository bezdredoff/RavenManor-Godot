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
