extends RefCounted
## MAP-EDIT-02: read-only, QA-only bridge from a saved editor draft to
## the existing ManorNavigationGraph/ManorRouteSession/OnoeSegmentMover.
## Never promotes geometry, updates checkpoints or writes production files.
const Routes = preload("res://addons/room_builder_routes/route_document.gd")
const Original = preload("res://scripts/raven/first_floor_hall_qa_graph.gd")
const PORTAL_ID := "QA-PORTAL-HALL-CORRIDOR"
const SPAWN_ID := "QA-HALL-SPAWN"
const USER := "user"
const PROJECT := "project"
const BASELINE := "original"

var graph
var data: Dictionary = {}
var error_text := ""
var source_kind := ""
var source_path := ""
var provisional_routes: Array[String] = []
var _waypoint_ids: Array[String] = []


func load_source(kind: String, override_path: String = "") -> bool:
	# Fail closed and discard stale graph on every request. The host only
	# applies a successful adapter to a newly instantiated preview scene.
	graph = null
	data.clear()
	_waypoint_ids.clear()
	provisional_routes.clear()
	error_text = ""
	source_kind = kind
	source_path = ""
	if kind == BASELINE:
		if not override_path.is_empty():
			return _reject("Original Hall cannot use a draft path override")
		var original = Original.new()
		if not original.load_pilot():
			return _reject("Original Hall QA: " + original.error_text)
		graph = original.graph
		data = original.data
		_waypoint_ids.assign(original.waypoint_ids())
		source_path = Original.DATA_PATH
		return true
	if kind != USER and kind != PROJECT:
		return _reject("Unknown preview source: " + kind)
	var path := override_path
	if path.is_empty():
		path = Routes.DEFAULT_SAVE if kind == USER else Routes.PROJECT_DRAFT_DIR + "hall_routes_draft.v1.json"
	if not _path_matches_source(kind, path):
		return _reject("Draft path is outside the selected QA source directory")
	var loaded := Routes.load_draft(path)
	if not loaded.get("ok", false):
		return _reject(str(loaded.get("error", "Draft loading failed")))
	if FileAccess.file_exists("res://" + Routes.IMAGE_PATH):
		if FileAccess.get_sha256("res://" + Routes.IMAGE_PATH) != Routes.IMAGE_SHA256:
			return _reject("Approved Hall PNG file hash mismatch")
	var doc: Dictionary = loaded.document
	var compiled := Routes.compile_qa_graph(doc)
	if not compiled.get("ok", false):
		return _reject(str(compiled.get("error", "Graph compilation failed")))
	var candidate = compiled.graph
	if not candidate.has_anchor(SPAWN_ID):
		return _reject("Draft has no explicit QA-HALL-SPAWN anchor")
	var reachable := false
	for waypoint in doc["waypoints"]:
		var id := str(waypoint["id"])
		if id != SPAWN_ID and not candidate.route(SPAWN_ID, id).is_empty():
			reachable = true
			break
	if not reachable:
		return _reject("Draft has no reachable destination from Hall spawn")
	for waypoint in doc["waypoints"]:
		_waypoint_ids.append(str(waypoint["id"]))
	for route in doc["routes"]:
		if bool(route["provisional"]):
			provisional_routes.append(str(route["id"]))
	graph = candidate
	data = doc
	source_path = path
	return true


func waypoint_ids() -> Array:
	return _waypoint_ids.duplicate()


func waypoint_position(id: String) -> Vector2:
	# Intermediate QA-ROUTE-*-STEP-* anchors also appear in completed legs.
	return graph.position(id) if graph != null else Vector2.INF


func hotspot_for_waypoint(id: String) -> String:
	if not _waypoint_ids.has(id):
		return ""
	return PORTAL_ID if id == "QA-HALL-PORTAL-APPROACH" else "QA-HS:" + id


func is_portal_hotspot(id: String) -> bool:
	return id == PORTAL_ID


func _path_matches_source(kind: String, path: String) -> bool:
	if not path.ends_with(".json") or path.contains("..") or path.contains("\\"):
		return false
	return (kind == USER and path.begins_with("user://room_builder_routes/")) or (kind == PROJECT and path.begins_with(Routes.PROJECT_DRAFT_DIR))


func _reject(reason: String) -> bool:
	error_text = reason
	return false
