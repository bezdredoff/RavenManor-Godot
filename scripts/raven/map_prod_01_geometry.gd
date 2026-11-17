extends RefCounted
## MAP-PROD-01: read-only candidate validation and explicit pixel/world conversion.
const SPEC_PATH := "res://assets/raven/map/production/map_prod_01_hc_cb_candidate.v1.json"
const ROUTES_PATH := "res://assets/raven/map/qa/drafts/map_qa_09b_opening_blueprint.v1.json"
const ART_PATH := "res://a_detailed_top_down_isometric_game_map_illustratio.png"
const ART_SHA256 := "5e0edf97bd719fb1df95c7e9bea2f134d90adad0bc04d1771acc82a95a4d549a"
const Routes = preload("res://addons/room_builder_routes/route_document.gd")
const OFFSET := Vector2(128, 128)

static func image_to_candidate_world(point_px: Vector2) -> Vector2:
	return point_px + OFFSET

static func candidate_world_to_image(point_world: Vector2) -> Vector2:
	return point_world - OFFSET

static func load_spec() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SPEC_PATH))
	return parsed if parsed is Dictionary else {}

static func verify() -> Dictionary:
	var spec := load_spec()
	if spec.get("schemaVersion") != 1 or spec.get("taskId") != "MAP-PROD-01":
		return {"ok":false, "error":"candidate-schema"}
	if spec.get("activationEnabled") != false or spec.get("productionReady") != false or spec.get("runtimeAuthority") != false:
		return {"ok":false, "error":"unsafe-activation"}
	if not FileAccess.file_exists(ART_PATH) or FileAccess.get_sha256(ART_PATH) != ART_SHA256:
		return {"ok":false, "error":"approved-png-changed"}
	var dims: Variant = spec["source"].get("dimensionsPx", null)
	if spec["source"].get("sha256") != ART_SHA256 or not dims is Array or dims.size() != 2:
		return {"ok":false, "error":"source-identity"}
	if int(dims[0]) != 1672 or int(dims[1]) != 941:
		return {"ok":false, "error":"source-dimensions"}
	if spec.get("paintedPerspective", {}).get("applySecondProjection") != false:
		return {"ok":false, "error":"double-projection"}
	var transform: Dictionary = spec.get("coordinateTransform", {})
	var shift: Variant = transform.get("translation", null)
	if transform.get("status") != "EXPLICIT_CANDIDATE_NEEDS_WORLDPLAN_AUTHORITY_REVIEW" or not shift is Array or shift.size() != 2:
		return {"ok":false, "error":"unreviewed-transform"}
	if absf(float(shift[0]) - OFFSET.x) > 0.001 or absf(float(shift[1]) - OFFSET.y) > 0.001:
		return {"ok":false, "error":"calibration-shift"}
	for sample in transform.get("controlPoints", []):
		var image := Vector2(float(sample["image"][0]),float(sample["image"][1]))
		var world := Vector2(float(sample["world"][0]),float(sample["world"][1]))
		if image_to_candidate_world(image).distance_to(world) > 0.001 or candidate_world_to_image(world).distance_to(image) > 0.001:
			return {"ok":false, "error":"calibration-control-point"}
	var loaded := Routes.load_draft(ROUTES_PATH)
	if not loaded.get("ok", false):
		return {"ok":false, "error":"invalid-authoring-source"}
	var doc: Dictionary = loaded["document"]
	var lookup: Dictionary = Routes._waypoint_lookup(doc)
	for door in spec.get("doors", []):
		if int(door.get("openingWidthPx", 0)) != 48:
			return {"ok":false, "error":"door-width"}
		var contact: Dictionary = {}
		for candidate in doc["sharedDoorContacts"]:
			if candidate.get("doorId") == door["id"]:
				contact = candidate
		if contact.is_empty() or contact["authority"] != "TEST_ONLY":
			return {"ok":false, "error":"door-contact-missing"}
		var threshold := Vector2(float(door["thresholdPx"][0]),float(door["thresholdPx"][1]))
		for waypoint_id in contact["waypointIds"]:
			if not lookup.has(waypoint_id) or Routes._vector(lookup[waypoint_id]["pointPx"]) != threshold:
				return {"ok":false, "error":"noncoincident-portal"}
		if float(door["clearance"]["nominalSideMarginPx"]) < 12.0:
			return {"ok":false, "error":"insufficient-foot-clearance"}
	return {"ok":true, "spec":spec, "document":doc}
