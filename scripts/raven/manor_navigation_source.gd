extends RefCounted
## MAP-GAME-01A: explicit, versioned navigation-source boundary.
##
## Production and QA geometry never share an implicit mode. This adapter only
## selects and validates authored data. It never writes a snapshot, never owns
## a save, never invents door connectivity and never turns a screen point into
## a movement destination. `raven_campaign_store.gd` + reducer remain the sole
## save authority; the harness returns proposals only.
const RouteSession = preload("res://scripts/raven/manor_route_session.gd")
const Graph = preload("res://scripts/raven/manor_navigation_graph.gd")
const Controller = preload("res://scripts/raven/manor_room_transition_controller.gd")
const QaAdapter = preload("res://scripts/raven/first_floor_integrated_draft_adapter.gd")
const Preview = preload("res://addons/room_builder_routes/route_preview_source.gd")
const RavenIds = preload("res://scripts/raven/raven_ids.gd")
const WORLD_PLAN = preload("res://data/raven/manor_greybox_graph.json")
const PRODUCTION_CANDIDATE = preload("res://data/raven/manor_production_candidate.v1.json")
const ACCEPTANCE = preload("res://data/raven/manor_production_acceptance.v1.json")
# Separate integration switch: editing candidate approval flags cannot select it.
const PRODUCTION_ACTIVATION_ENABLED := false

const SCHEMA_VERSION := 1
const REQUEST_KIND := "raven-navigation-source-request"
const RESULT_KIND := "raven-navigation-source"
const MODE_PRODUCTION := "production"
const MODE_QA := "qa"
const PRODUCTION_APPROVAL := "PRODUCTION_APPROVED"


## Explicit request:
## {
##   "schemaVersion": 1, "kind": "raven-navigation-source-request",
##   "mode": "production" | "qa", "snapshot": {...},
##   "allowQaCandidate": false, "qaSourceKind": "project", "qaSourcePath": "",
##   "worldPlan": optional approved world-plan dictionary (fixtures/validation)
## }
static func resolve(request: Dictionary) -> Dictionary:
	var invalid := _invalid_request(request)
	if not invalid.is_empty():
		return invalid
	if str(request.mode) == MODE_QA:
		return _resolve_qa(request)
	return _resolve_production(request)


## Production: canonical world plan or an approved replacement. The shipped
## greybox has no production approval, so this must fail closed with a hold.
static func _resolve_production(request: Dictionary) -> Dictionary:
	var mode := MODE_PRODUCTION
	var snapshot := _snapshot(request)
	var selected: Dictionary = WORLD_PLAN.data
	if not request.has("worldPlan") and PRODUCTION_ACTIVATION_ENABLED:
		if not _acceptance_receipt_matches():
			return _unavailable(mode, "production-acceptance-receipt-missing", ["owner-rendered-geometry-review-required"])
		selected = PRODUCTION_CANDIDATE.data
	var graph_data: Variant = request.get("worldPlan", selected)
	if not graph_data is Dictionary:
		return _invalid_request_result(mode, "world-plan-must-be-dictionary")
	var plan: Dictionary = graph_data
	var provenance: Variant = plan.get("provenance", {})
	if not provenance is Dictionary:
		provenance = {}
	var blockers: Array = []
	if str(provenance.get("approval", "")) != PRODUCTION_APPROVAL:
		blockers.append("unapproved-world-plan")
	if not bool(provenance.get("productionReady", false)):
		blockers.append("production-geometry-unapproved")
	if str(provenance.get("coordinateSpace", "")) != "world-plan":
		blockers.append("unsupported-coordinate-space")
	var calibration: Variant = provenance.get("roomArtCalibration")
	if not _calibration_approved(calibration):
		blockers.append("unapproved-room-art-calibration")
	if not blockers.is_empty():
		return _unavailable(mode, "production-geometry-unapproved", blockers)
	var built := _production_contract(plan, snapshot, provenance, calibration)
	if not bool(built.get("ok", false)):
		var blocked := _base(mode)
		blocked.status = str(built.get("status", "invalid_route"))
		blocked.reason = str(built.get("error", "invalid-production-contract"))
		blocked.blockers = built.get("blockers", []).duplicate()
		return blocked
	var contract: Dictionary = built.contract
	var starts: Dictionary = built.starts
	var first_room := str(contract.rooms[0].id)
	var start: Dictionary = resolve_snapshot_start({"contract": contract, "starts": starts, "initialRoomId": first_room}, snapshot)
	if not bool(start.get("ok", false)):
		return _invalid_route(mode, "invalid-saved-position:" + str(start.get("error", "")))
	var result := _base(mode)
	result.ok = true
	result.status = "ready"
	result.approval = PRODUCTION_APPROVAL
	result.draftOnly = false
	result.productionReady = true
	result.movementEnabled = true
	result.coordinateSpace = "world-plan"
	result.contract = contract
	result.visuals = built.visuals
	result.starts = starts
	result.initialRoomId = str(start.roomId)
	result.initialAnchorId = str(start.anchorId)
	result.spawnFallback = bool(start.fallback)
	result.spawnFallbackReason = str(start.reason)
	result.savedPositionApplied = bool(start.savedPositionApplied)
	result.source = {
		"kind": "canonical-world-plan",
		"coordinateSpace": "world-plan",
		"approval": PRODUCTION_APPROVAL,
		"provenance": provenance.duplicate(true),
		"anchorCount": plan.get("anchors", []).size(),
		"edgeCount": plan.get("edges", []).size(),
	}
	return result


## QA: explicit opt-in, DRAFT_ONLY, image-pixel, TEST_ONLY handoffs. The saved
## production room/anchor is intentionally not applied to candidate geometry.
static func _resolve_qa(request: Dictionary) -> Dictionary:
	var mode := MODE_QA
	if request.get("allowQaCandidate", false) != true:
		var blocked := _base(mode)
		blocked.status = "qa_requires_opt_in"
		blocked.reason = "qa-candidate-requires-explicit-allowQaCandidate"
		return blocked
	if request.get("qaSourceKind", "") == "historical-greybox":
		return _resolve_historical_qa(request)
	var source_kind := str(request.get("qaSourceKind", Preview.PROJECT))
	var source_path := str(request.get("qaSourcePath", ""))
	var loaded: Dictionary = QaAdapter.load_source(source_kind, source_path)
	if not bool(loaded.get("ok", false)):
		var invalid_source := _base(mode)
		invalid_source.status = "invalid_source"
		invalid_source.reason = str(loaded.get("error", "invalid-qa-navigation-source"))
		return invalid_source
	var contract: Dictionary = loaded.contract
	var trial = Controller.new()
	if not trial.configure(contract, str(loaded.initialRoomId), str(loaded.initialAnchorId), {}):
		return _invalid_route(mode, "qa-transition-contract:" + trial.error_text)
	var result := _base(mode)
	result.ok = true
	result.status = "ready"
	result.approval = "TEST_ONLY"
	result.draftOnly = true
	result.productionReady = false
	result.movementEnabled = true
	result.coordinateSpace = "image-pixel"
	result.contract = contract
	result.visuals = loaded.visuals
	result.starts = loaded.starts
	result.initialRoomId = str(loaded.initialRoomId)
	result.initialAnchorId = str(loaded.initialAnchorId)
	result.savedPositionApplied = false
	result.source = {
		"kind": "qa-route-document",
		"sourceKind": source_kind,
		"path": str(loaded.get("sourcePath", source_path)),
		"coordinateSpace": "image-pixel",
		"approval": "DRAFT_ONLY",
		"waypointCount": int(loaded.get("waypointCount", 0)),
		"routeCount": int(loaded.get("routeCount", 0)),
		"unresolvedCount": int(loaded.get("unresolvedCount", 0)),
		"syntheticTransitions": bool(loaded.get("syntheticTransitions", false)),
	}
	return result


## Resolve a raw persisted room/anchor against validated authored geometry.
## Unknown room -> first authored room safe anchor. Invalid/unsafe/unreachable
## anchor -> that room's safe anchor. An empty anchor is a normal room start.
## Callers must persist the returned proposal only through the campaign store.
static func resolve_snapshot_start(source: Dictionary, snapshot: Dictionary = {}) -> Dictionary:
	var contract: Variant = source.get("contract", {})
	var starts: Variant = source.get("starts", {})
	if not contract is Dictionary or not starts is Dictionary or starts.is_empty():
		return {"ok": false, "error": "missing-validated-starts"}
	var rooms: Dictionary = {}
	for room in contract.get("rooms", []):
		if room is Dictionary:
			rooms[str(room.get("id", ""))] = room
	var fallback_room := str(source.get("initialRoomId", ""))
	if not starts.has(fallback_room):
		fallback_room = str(starts.keys()[0])
	var requested := str(snapshot.get("lastRoomId", ""))
	if requested.is_empty():
		requested = fallback_room
	if not starts.has(requested):
		return _start_result(fallback_room, str(starts[fallback_room]), true, "unknown-saved-room", false)
	var room_start := str(starts[requested])
	var saved := str(snapshot.get("lastSafeAnchorId", ""))
	if saved.is_empty():
		return _start_result(requested, room_start, false, "", false)
	if not rooms.has(requested):
		return _start_result(fallback_room, str(starts[fallback_room]), true, "missing-saved-room-graph", false)
	var graph = Graph.new()
	graph.rebuild(_gate_snapshot_stub(contract, snapshot), rooms[requested].get("graph", {}))
	if not graph.has_anchor(saved) or str(graph.anchor(saved).get("kind", "")) != "safe" \
			or str(graph.anchor(saved).get("roomId", "")) != requested or not graph.anchor(saved).get("checkpointAllowed", true):
		return _start_result(requested, room_start, true, "invalid-saved-anchor", false)
	if graph.safe_checkpoint_anchor({"lastRoomId": requested, "lastSafeAnchorId": saved}, room_start) != saved:
		return _start_result(requested, room_start, true, "unreachable-saved-anchor", false)
	return _start_result(requested, saved, false, "", true)


static func _production_contract(plan: Dictionary, snapshot: Dictionary, provenance: Dictionary, calibration: Dictionary) -> Dictionary:
	if int(provenance.get("calibrationVersion", 0)) == 2:
		var physical_error := validate_calibrated_plan(plan)
		if not physical_error.is_empty():
			return _contract_error(physical_error)
	var rooms: Dictionary = {}
	var room_order: Array = []
	var anchors_by_id: Dictionary = {}
	var blockers: Array = []
	for raw in plan.get("anchors", []):
		if not raw is Dictionary:
			return _contract_error("invalid-anchor")
		var anchor: Dictionary = raw
		var id := str(anchor.get("id", ""))
		var room := str(anchor.get("roomId", ""))
		if id.is_empty() or anchors_by_id.has(id):
			return _contract_error("duplicate-or-empty-anchor-id")
		if room.is_empty():
			return _contract_error("anchor-without-room:" + id)
		if not RavenIds.is_known("rooms", room):
			return _contract_blocked("unsupported-room:" + room, ["unsupported-save-catalog-room:" + room])
		if not _valid_position(anchor.get("position", null)):
			return _contract_error("invalid-anchor-position:" + id)
		anchors_by_id[id] = anchor
		if not rooms.has(room):
			rooms[room] = {"id": room, "label": room, "graph": {"anchors": [], "edges": []}}
			room_order.append(room)
		rooms[room].graph.anchors.append(anchor.duplicate(true))
	var room_edges: Dictionary = {}
	var cross_edges: Array = []
	for raw in plan.get("edges", []):
		if not raw is Dictionary:
			return _contract_error("invalid-edge")
		var edge: Dictionary = raw
		var from_id := str(edge.get("from", ""))
		var to_id := str(edge.get("to", ""))
		if not anchors_by_id.has(from_id) or not anchors_by_id.has(to_id):
			return _contract_error("edge-endpoint-missing:" + from_id + ">" + to_id)
		if not str(edge.get("restorationId", "")).is_empty():
			return _contract_blocked("restoration-gated-edge-unsupported", ["restoration-gated-edges-unsupported"])
		var from_room := str(anchors_by_id[from_id].roomId)
		var to_room := str(anchors_by_id[to_id].roomId)
		if from_room == to_room:
			if not room_edges.has(from_room):
				room_edges[from_room] = []
			room_edges[from_room].append(edge.duplicate(true))
		else:
			if str(edge.get("doorId", "")).is_empty():
				return _contract_blocked("cross-room-edge-without-door", ["cross-room-edge-without-door:" + from_id + ">" + to_id])
			if not RavenIds.is_known("doors", str(edge.doorId)):
				return _contract_blocked("unknown-door:" + str(edge.doorId), ["unknown-door:" + str(edge.doorId)])
			cross_edges.append(edge.duplicate(true))
	var starts: Dictionary = {}
	for room in room_order:
		rooms[room].graph.edges = room_edges.get(room, []).duplicate(true)
		var start := _first_safe(rooms[room].graph.anchors)
		if start.is_empty():
			return _contract_blocked("missing-safe-anchor:" + str(room), ["missing-safe-anchor:" + str(room)])
		starts[room] = start
	var visuals := _production_visuals(room_order, calibration)
	if not bool(visuals.get("ok", false)):
		return {"ok": false, "status": "unavailable_geometry", "error": "missing-room-visuals",
			"blockers": visuals.get("blockers", [])}
	var built_transitions := _production_transitions(cross_edges, anchors_by_id)
	if not bool(built_transitions.get("ok", false)):
		return built_transitions
	for transition in built_transitions.transitions:
		var entry: Dictionary = anchors_by_id[transition.destinationEntryAnchorId]
		if entry.get("checkpointAllowed", true) == false:
			transition["destinationSafeAnchorId"] = starts[transition.destinationRoomId]
	var room_list: Array = []
	for room in room_order:
		room_list.append(rooms[room])
	var door_ids := {}
	for edge in cross_edges:
		door_ids[str(edge.doorId)] = true
	var doors: Array = []
	for door_id in door_ids:
		doors.append({"id": door_id, "status": "open"})
	var contract := {
		"schemaVersion": 1,
		"kind": "raven-authored-room-transitions",
		"approval": PRODUCTION_APPROVAL,
		"draftAuthority": "NONE",
		"rooms": room_list,
		"doors": doors,
		"transitions": built_transitions.transitions,
	}
	var first_room := str(room_order[0])
	var trial = Controller.new()
	if not trial.configure(contract, first_room, str(starts[first_room]), _gate_snapshot_stub(contract, snapshot)):
		return _contract_error("transition-contract:" + trial.error_text)
	return {"ok": true, "contract": contract, "visuals": visuals.visuals, "starts": starts}


static func _production_transitions(cross_edges: Array, anchors_by_id: Dictionary) -> Dictionary:
	var ids: Dictionary = {}
	var seen: Dictionary = {}
	var blockers: Array = []
	for edge in cross_edges:
		var from_id := str(edge.from)
		var to_id := str(edge.to)
		var key := from_id + ">" + to_id
		if seen.has(key):
			return _contract_blocked("duplicate-transition-edge:" + key, ["duplicate-transition-edge:" + key])
		seen[key] = true
		ids[key] = "PROD-TR-" + key
		if str(anchors_by_id[from_id].get("hotspotId", "")).is_empty():
			blockers.append("missing-approach-hotspot:" + from_id)
		if str(anchors_by_id[to_id].get("kind", "")) != "safe":
			blockers.append("missing-destination-entry-anchor:" + to_id)
	if not blockers.is_empty():
		return _contract_blocked("invalid-transition-contract", blockers)
	var transitions: Array = []
	for edge in cross_edges:
		var from_id := str(edge.from)
		var to_id := str(edge.to)
		var reverse_id := ""
		var reverse_key := to_id + ">" + from_id
		if ids.has(reverse_key):
			reverse_id = str(ids[reverse_key])
		transitions.append({
			"id": str(ids[from_id + ">" + to_id]),
			"sourceRoomId": str(anchors_by_id[from_id].roomId),
			"destinationRoomId": str(anchors_by_id[to_id].roomId),
			"approachAnchorId": from_id,
			"destinationEntryAnchorId": to_id,
			"reverseTransitionId": reverse_id,
			"doorId": str(edge.get("doorId", "")),
			"authority": PRODUCTION_APPROVAL,
			"physicalPortalApproved": true,
		})
	return {"ok": true, "transitions": transitions}


static func _production_visuals(room_order: Array, calibration: Dictionary) -> Dictionary:
	var entries: Variant = calibration.get("rooms", {})
	if not entries is Dictionary:
		return {"ok": false, "blockers": ["missing-room-art-calibration"]}
	var visuals: Dictionary = {}
	var blockers: Array = []
	for room in room_order:
		var entry: Variant = entries.get(room)
		if not _visual_entry_valid(entry):
			blockers.append("missing-room-visual:" + str(room))
			continue
		visuals[room] = {
			"source": "production-approved",
			"texturePath": str(entry.texturePath),
			"bounds": entry.bounds.duplicate(),
			"cameraZoom": float(entry.cameraZoom),
			"actorHeight": float(entry.get("actorHeight", 62.0)),
			"artLayer": str(entry.get("artLayer", "")),
			"artOrigin": entry.get("artOrigin", [0, 0]).duplicate(),
		}
	if not blockers.is_empty():
		return {"ok": false, "blockers": blockers}
	return {"ok": true, "visuals": visuals}


static func _visual_entry_valid(value: Variant) -> bool:
	if not value is Dictionary:
		return false
	if str(value.get("texturePath", "")).is_empty():
		return false
	var bounds: Variant = value.get("bounds")
	if not bounds is Array or bounds.size() != 4:
		return false
	for number in bounds:
		if not (number is int or number is float) or not is_finite(float(number)):
			return false
	var zoom: Variant = value.get("cameraZoom")
	return (zoom is int or zoom is float) and is_finite(float(zoom)) and float(zoom) > 0.0


static func _calibration_approved(value: Variant) -> bool:
	if not value is Dictionary:
		return false
	return value.get("status") == "approved" and not str(value.get("assetHash", "")).is_empty() \
		and int(value.get("version", 0)) > 0


static func _first_safe(anchors: Array) -> String:
	for anchor in anchors:
		if anchor is Dictionary and str(anchor.get("kind", "")) == "safe" and anchor.get("checkpointAllowed", true):
			return str(anchor.get("id", ""))
	return ""


## Geometry validation is independent of approval metadata. The inactive
## candidate and isolated tests use this same check before any source activation.
static func validate_calibrated_plan(plan: Dictionary) -> String:
	var calibration: Dictionary = plan.get("provenance", {}).get("roomArtCalibration", {})
	var transform: Dictionary = calibration.get("transform", {})
	if not _numbers_match(transform.get("translation"), [128, 128]) or float(transform.get("uniformScale", 0)) != 1.0:
		return "invalid-physical-transform"
	if FileAccess.get_sha256("res://a_detailed_top_down_isometric_game_map_illustratio.png") != calibration.get("assetHash", ""):
		return "physical-source-hash-mismatch"
	var controls: Array = transform.get("controlPoints", [])
	if controls.size() != 4:
		return "missing-calibration-control-points"
	for control in controls:
		if not _valid_position(control.get("image")) or not _valid_position(control.get("world")):
			return "invalid-control-point"
		if _point(control.world).distance_to(_point(control.image) + Vector2(128, 128)) > 0.001:
			return "control-point-residual"
	var scale: Dictionary = calibration.get("scale", {})
	if float(scale.get("sourcePixelsPerMetre", 0)) != 40.0 or scale.get("applySecondProjection", true):
		return "invalid-physical-scale"
	var constraints: Dictionary = plan.get("physicalConstraints", {})
	if float(constraints.get("footRadiusWorld", 0)) != 12.0 or float(constraints.get("portalWidthWorld", 0)) != 48.0:
		return "invalid-physical-clearance"
	var no_go: Array = constraints.get("noGoPolygons", [])
	var walkable: Array = constraints.get("walkablePolygons", [])
	if no_go.is_empty() or walkable.is_empty():
		return "missing-physical-constraints"
	var lookup: Dictionary = {}
	for anchor in plan.get("anchors", []):
		if not _valid_position(anchor.get("position")) or lookup.has(anchor.get("id")):
			return "invalid-calibrated-anchor"
		lookup[anchor.id] = anchor
	for pair in constraints.get("portalPairs", []):
		if pair.size() != 2 or not lookup.has(pair[0]) or not lookup.has(pair[1]):
			return "missing-portal-pair"
		if _point(lookup[pair[0]].position).distance_to(_point(lookup[pair[1]].position)) > 0.001:
			return "portal-handoff-jump"
		if lookup[pair[0]].get("checkpointAllowed", true) or lookup[pair[1]].get("checkpointAllowed", true):
			return "portal-checkpoint-forbidden"
	if constraints.get("portalPairs", []).size() != 2:
		return "missing-hc-cb-portals"
	for room in calibration.get("rooms", {}):
		var visual: Dictionary = calibration.rooms[room]
		if not _numbers_match(visual.get("bounds"), [128, 128, 1672, 941]) or not _numbers_match(visual.get("artOrigin"), [128, 128]):
			return "art-world-alignment"
	for edge in plan.get("edges", []):
		if not lookup.has(edge.get("from")) or not lookup.has(edge.get("to")):
			return "invalid-calibrated-edge"
		var a: Dictionary = lookup[edge.from]
		var b: Dictionary = lookup[edge.to]
		var start := _point(a.position) - Vector2(128, 128)
		var end := _point(b.position) - Vector2(128, 128)
		if a.roomId != b.roomId and start.distance_to(end) > 0.001:
			return "portal-handoff-jump"
		for step in range(ceili(start.distance_to(end)) + 1):
			var feet := start.lerp(end, float(step) / maxf(1.0, ceilf(start.distance_to(end))))
			var allowed := false
			for zone in walkable:
				if str(zone.get("roomId", "")) == str(a.roomId) and Geometry2D.is_point_in_polygon(feet, _polygon(zone)):
					allowed = true
			if not allowed:
				return "route-outside-walkable:" + str(edge.from)
			for zone in no_go:
				var polygon := _polygon(zone)
				if Geometry2D.is_point_in_polygon(feet, polygon):
					return "route-inside-no-go:" + str(zone.get("id", ""))
				for i in range(polygon.size()):
					if feet.distance_to(Geometry2D.get_closest_point_to_segment(feet, polygon[i], polygon[(i + 1) % polygon.size()])) < 11.99:
						return "route-foot-clearance:" + str(zone.get("id", ""))
	return ""


static func _point(value: Array) -> Vector2:
	return Vector2(float(value[0]), float(value[1]))


static func _polygon(zone: Dictionary) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point in zone.get("pointsPx", []):
		result.append(_point(point))
	return result


static func _gate_snapshot_stub(contract: Dictionary, snapshot: Dictionary) -> Dictionary:
	if snapshot.has("unlockedDoors"):
		return {"unlockedDoors": snapshot.get("unlockedDoors", []).duplicate()}
	var open: Array = []
	for door in contract.get("doors", []):
		if door is Dictionary and str(door.get("status", "")) == "open":
			open.append(str(door.get("id", "")))
	return {"unlockedDoors": open}


static func _start_result(room: String, anchor: String, fallback: bool, reason: String, applied: bool) -> Dictionary:
	return {
		"ok": not room.is_empty() and not anchor.is_empty(),
		"roomId": room,
		"anchorId": anchor,
		"fallback": fallback,
		"reason": reason,
		"savedPositionApplied": applied,
	}


static func _snapshot(request: Dictionary) -> Dictionary:
	var value: Variant = request.get("snapshot", {})
	return value if value is Dictionary else {}


static func _invalid_request(request: Dictionary) -> Dictionary:
	if int(request.get("schemaVersion", -1)) != SCHEMA_VERSION:
		return _invalid_request_result("", "unsupported-request-schema")
	if str(request.get("kind", "")) != REQUEST_KIND:
		return _invalid_request_result("", "invalid-request-kind")
	var mode := str(request.get("mode", ""))
	if mode != MODE_PRODUCTION and mode != MODE_QA:
		return _invalid_request_result("", "unknown-navigation-source-mode")
	if request.has("snapshot") and not request.snapshot is Dictionary:
		return _invalid_request_result(mode, "snapshot-must-be-dictionary")
	if mode == MODE_PRODUCTION and request.has("worldPlan") and not request.worldPlan is Dictionary:
		return _invalid_request_result(mode, "world-plan-must-be-dictionary")
	return {}


static func _base(mode: String) -> Dictionary:
	return {
		"schemaVersion": SCHEMA_VERSION,
		"kind": RESULT_KIND,
		"mode": mode,
		"ok": false,
		"status": "",
		"reason": "",
		"blockers": [],
		"approval": "",
		"draftOnly": true,
		"productionReady": false,
		"movementEnabled": false,
		"freeTapToMove": false,
		"inputPolicy": "authored-hotspot-only",
		"snapshotMutation": false,
		"saveAuthority": "raven_campaign_store",
		"coordinateSpace": "",
		"contract": {},
		"visuals": {},
		"starts": {},
		"initialRoomId": "",
		"initialAnchorId": "",
		"spawnFallback": false,
		"spawnFallbackReason": "",
		"savedPositionApplied": false,
		"hold": {"action": "hold", "snapshotMutation": false, "checkpointEvent": {}},
		"source": {},
	}


static func _unavailable(mode: String, reason: String, blockers: Array) -> Dictionary:
	var result := _base(mode)
	result.status = "unavailable_geometry"
	result.reason = reason
	result.blockers = blockers.duplicate()
	return result


static func _invalid_route(mode: String, reason: String) -> Dictionary:
	var result := _base(mode)
	result.status = "invalid_route"
	result.reason = reason
	return result


static func _invalid_request_result(mode: String, reason: String) -> Dictionary:
	var result := _base(mode)
	result.status = "invalid_request"
	result.reason = reason
	return result


static func _contract_error(reason: String) -> Dictionary:
	return {"ok": false, "status": "invalid_route", "error": reason, "blockers": []}


static func _contract_blocked(reason: String, blockers: Array) -> Dictionary:
	return {"ok": false, "status": "invalid_route", "error": reason, "blockers": blockers}


static func _valid_position(value: Variant) -> bool:
	if not value is Array or value.size() != 2:
		return false
	if not (value[0] is int or value[0] is float) or not (value[1] is int or value[1] is float):
		return false
	return Vector2(float(value[0]), float(value[1])).is_finite()


## Explicit compatibility source for GAME-LOOP-01A. Never falls through from
## production or draft-map failure. Overrides are QA fixtures, not approval.
static func historical_qa_request(graph_override: Dictionary = {}) -> Dictionary:
	var request := {"schemaVersion": SCHEMA_VERSION, "kind": REQUEST_KIND,
		"mode": MODE_QA, "allowQaCandidate": true, "qaSourceKind": "historical-greybox"}
	if not graph_override.is_empty():
		request.qaGraph = graph_override.duplicate(true)
	return request


static func _resolve_historical_qa(request: Dictionary) -> Dictionary:
	var data: Variant = request.get("qaGraph", WORLD_PLAN.data)
	if not data is Dictionary or not data.get("anchors") is Array or not data.get("edges") is Array:
		return _invalid_route(MODE_QA, "invalid-qa-graph")
	var canonical := {}
	for anchor in WORLD_PLAN.data.anchors:
		canonical[str(anchor.id)] = anchor
	var known := {}
	var hotspots := {}
	for anchor in data.anchors:
		if not anchor is Dictionary or not _valid_position(anchor.get("position")):
			return _invalid_route(MODE_QA, "invalid-qa-anchor")
		var id := str(anchor.get("id", ""))
		var hotspot := str(anchor.get("hotspotId", ""))
		if id.is_empty() or known.has(id) or not RavenIds.is_known("rooms", str(anchor.get("roomId", ""))):
			return _invalid_route(MODE_QA, "invalid-qa-anchor-id-or-room")
		if not hotspot.is_empty() and (hotspots.has(hotspot) or not RavenIds.is_known("hotspots", hotspot)):
			return _invalid_route(MODE_QA, "invalid-qa-hotspot")
		if not canonical.has(id) or anchor.get("roomId") != canonical[id].roomId \
				or anchor.get("kind") != canonical[id].kind \
				or hotspot != str(canonical[id].get("hotspotId", "")):
			return _invalid_route(MODE_QA, "historical-anchor-identity-mismatch")
		known[id] = anchor
		if not hotspot.is_empty():
			hotspots[hotspot] = true
	for edge in data.edges:
		if not edge is Dictionary or not known.has(str(edge.get("from", ""))) or not known.has(str(edge.get("to", ""))):
			return _invalid_route(MODE_QA, "invalid-qa-edge")
		var door := str(edge.get("doorId", ""))
		if not door.is_empty() and not RavenIds.is_known("doors", door):
			return _invalid_route(MODE_QA, "unknown-qa-door")
	var graph = Graph.new()
	graph.rebuild(_snapshot(request), data)
	var start: String = graph.safe_checkpoint_anchor(_snapshot(request))
	if start.is_empty():
		return _invalid_route(MODE_QA, "missing-safe-qa-start")
	var result := _base(MODE_QA)
	result.merge({"ok": true, "status": "ready", "approval": "TEST_ONLY",
		"movementEnabled": true, "coordinateSpace": "independent-greybox",
		"initialRoomId": str(graph.anchor(start).roomId), "initialAnchorId": start,
		"routeGraph": data.duplicate(true),
		"source": {"kind": "historical-greybox", "approval": "TEST_ONLY"}}, true)
	return result


## A selected source owns the route objects. Reload resets this same session;
## refresh only rebuilds its graph gates, never selects another source.
## Multi-room candidate contracts continue to use the existing transition
## controller/harness. Their gameplay handoff is deliberately held until G2.
var selection: Dictionary = {}
var graph
var session
var _route_data: Dictionary = {}
var _selected := false


func select(request: Dictionary, snapshot: Dictionary) -> bool:
	if _selected:
		return false
	_selected = true
	var input := request.duplicate(true)
	input.snapshot = snapshot.duplicate(true)
	selection = resolve(input)
	if not selection.get("ok", false):
		return false
	if not selection.has("routeGraph"):
		selection = _invalid_route(str(selection.mode), "gameplay-transition-handoff-requires-G2")
		return false
	_route_data = selection.routeGraph.duplicate(true)
	graph = Graph.new()
	graph.rebuild(snapshot, _route_data)
	session = RouteSession.new(graph)
	session.restore(snapshot)
	return true


func refresh_routes(snapshot: Dictionary) -> void:
	if graph != null:
		graph.rebuild(snapshot, _route_data)


func restore_routes(snapshot: Dictionary) -> String:
	refresh_routes(snapshot)
	return session.restore(snapshot) if session != null else ""


static func _numbers_match(value: Variant, expected: Array) -> bool:
	if not value is Array or value.size() != expected.size():
		return false
	for i in range(expected.size()):
		if not (value[i] is int or value[i] is float) or not is_finite(float(value[i])) or absf(float(value[i]) - float(expected[i])) > 0.001:
			return false
	return true


static func _acceptance_receipt_matches() -> bool:
	var receipt: Dictionary = ACCEPTANCE.data
	return receipt.get("ownerApproved", false) == true \
		and not str(receipt.get("ownerDecisionId", "")).is_empty() \
		and not str(receipt.get("renderEvidence", "")).is_empty() \
		and receipt.get("worldPlanSha256", "") == FileAccess.get_sha256("res://data/raven/manor_production_candidate.v1.json") \
		and receipt.get("doorLayerSha256", "") == FileAccess.get_sha256("res://scripts/raven/map_prod_01_hc_cb_art.gd")
