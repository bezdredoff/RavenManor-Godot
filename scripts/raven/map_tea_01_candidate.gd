extends RefCounted
## MAP-TEA-01: read-only delta assembly for visual QA and isolated path testing.
## NEVER pass the returned in-memory DRAFT_ONLY world plan to normal gameplay.
const BasePlan = preload("res://data/raven/manor_production_candidate.v1.json")
const Delta = preload("res://assets/raven/map/qa/drafts/map_tea_01_hall_route_candidate.v1.json")
const Source = preload("res://scripts/raven/manor_navigation_source.gd")

static func inspect() -> Dictionary:
	var spec: Dictionary = Delta.data
	var raw: Dictionary = BasePlan.data
	if spec.get("kind") != "raven-hall-tea-qa-route-delta" or spec.get("approval") != "DRAFT_ONLY":
		return _error("invalid-qa-delta")
	for flag in ["productionReady", "activationEnabled", "runtimeAuthority", "ownerApproved"]:
		if bool(spec.get(flag, true)):
			return _error("unexpected-authority:" + flag)
	if FileAccess.get_sha256(str(spec.get("sourceWorldPlanPath", ""))) != str(spec.get("sourceWorldPlanSha256", "")):
		return _error("base-world-plan-hash-mismatch")
	if FileAccess.get_sha256(str(spec.get("sourceArtPath", ""))) != str(spec.get("sourceArtSha256", "")):
		return _error("original-art-hash-mismatch")
	if raw.get("anchors", []).size() != int(spec.get("baseAnchorCount", -1)) or raw.get("edges", []).size() != int(spec.get("baseEdgeCount", -1)):
		return _error("base-world-plan-count-mismatch")
	if spec.get("coordinateSpace") != "world-plan" or not _numbers_match(spec.get("sourcePixelToWorldTranslation"), [128, 128]) or spec.get("applySecondProjection") != false:
		return _error("coordinate-contract-mismatch")
	var anchor: Dictionary = spec.get("anchor", {})
	var edge: Dictionary = spec.get("edge", {})
	if str(anchor.get("id", "")) != "RM-NAV-HALL-TEA" or str(anchor.get("roomId", "")) != "RM-ROOM-HALL" or str(anchor.get("kind", "")) != "interaction" or str(anchor.get("hotspotId", "")) != "RM-HS-TEA-TABLE" or anchor.get("checkpointAllowed", true):
		return _error("wrong-interaction-anchor")
	if not _numbers_match(anchor.get("position"), [984, 784]) or str(edge.get("from", "")) != "RM-NAV-HS-001" or str(edge.get("to", "")) != "RM-NAV-HALL-TEA" or edge.get("bidirectional", false) != true or edge.has("doorId"):
		return _error("unexpected-path-delta")
	var base_ids: Dictionary = {}
	for item in raw["anchors"]:
		base_ids[str(item.get("id", ""))] = item
		if str(item.get("hotspotId", "")) == "RM-HS-TEA-TABLE":
			return _error("base-already-contains-hall-tea")
	if base_ids.has(str(anchor.id)):
		return _error("base-already-contains-tea-anchor")
	if not base_ids.has(str(edge["from"])) or str(base_ids[str(edge["from"])].get("roomId", "")) != "RM-ROOM-HALL":
		return _error("invalid-connected-hall-waypoint")
	var origin: Array = base_ids[str(edge["from"])].get("position", [])
	if not _numbers_match(origin, [952, 792]):
		return _error("changed-base-hall-route")
	var footprint: Dictionary = {}
	for zone in raw.get("physicalConstraints", {}).get("noGoPolygons", []):
		if str(zone.get("id", "")) == "QA-08B-HALL-TABLE":
			footprint = zone
			break
	if not _points_match(footprint.get("pointsPx"), [[788, 548], [880, 548], [880, 623], [788, 623]]):
		return _error("table-footprint-changed")
	var review: Dictionary = spec.get("physicalReview", {})
	if not _numbers_match(review.get("arrivalFootpointImage"), [856, 656]) or not _numbers_match(review.get("approachImage"), [824, 664]) or absf(float(review.get("minimumTableEdgeGapImagePx", -1)) - 33.0) > 0.001:
		return _error("footpoint-reference-changed")
	# Duplicate in memory, never rewrite the signed bytes or receipt.
	var trial: Dictionary = raw.duplicate(true)
	var provenance: Dictionary = trial.get("provenance", {})
	provenance["approval"] = "DRAFT_ONLY"
	provenance["productionReady"] = false
	provenance["activationEnabled"] = false
	provenance["runtimeAuthority"] = false
	provenance["ownerApproved"] = false
	trial["provenance"] = provenance
	trial["anchors"].append(anchor.duplicate(true))
	trial["edges"].append(edge.duplicate(true))
	var geometry_error: String = Source.validate_calibrated_plan(trial)
	if not geometry_error.is_empty():
		return _error("collision-validator:" + geometry_error)
	return {"ok": true, "spec": spec, "plan": trial, "baseAnchorCount": raw["anchors"].size(),
		"baseEdgeCount": raw["edges"].size(), "candidateAnchorCount": trial["anchors"].size(),
		"candidateEdgeCount": trial["edges"].size()}

static func _error(reason: String) -> Dictionary:
	return {"ok": false, "error": reason}

## Godot JSON imports may decode source numeric arrays as floats, not ints.
static func _numbers_match(value: Variant, expected: Array) -> bool:
	if not value is Array or value.size() != expected.size():
		return false
	for i in range(expected.size()):
		if not (value[i] is float or value[i] is int):
			return false
		if not is_finite(float(value[i])) or absf(float(value[i]) - float(expected[i])) > 0.001:
			return false
	return true

static func _points_match(value: Variant, expected: Array) -> bool:
	if not value is Array or value.size() != expected.size():
		return false
	for i in range(expected.size()):
		if not _numbers_match(value[i], expected[i]):
			return false
	return true
