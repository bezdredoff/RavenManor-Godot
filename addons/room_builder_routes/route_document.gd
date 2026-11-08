@tool
extends RefCounted
## MAP-EDIT-01: authoring-only route document. Image pixels are never world-plan.
## Pure, deterministic transformations; no campaign/save/door runtime dependencies.
const Graph = preload("res://scripts/raven/manor_navigation_graph.gd")
const HALL_SOURCE := "res://assets/raven/map/qa/first_floor_hall_pilot.v1.json"
const IMAGE_PATH := "a_detailed_top_down_isometric_game_map_illustratio.png"
const IMAGE_SHA256 := "5e0edf97bd719fb1df95c7e9bea2f134d90adad0bc04d1771acc82a95a4d549a"
const IMAGE_BLOB_SHA := "b50bc36cffd3d3aca7e81a0cea28bb3d0c0e9563"
const DEFAULT_SAVE := "user://room_builder_routes/hall_routes_draft.v1.json"
const PROJECT_DRAFT_DIR := "res://assets/raven/map/qa/drafts/"
const TYPES := ["Spawn", "Waypoint", "Interaction", "Door Approach", "Return Spawn"]

static func import_hall(path: String = HALL_SOURCE) -> Dictionary:
	var raw_text := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(raw_text)
	if not parsed is Dictionary:
		return _bad("Hall QA import: source JSON is missing or invalid")
	var source: Dictionary = parsed
	var info: Dictionary = source.get("source", {})
	var pixels: Array = info.get("dimensionsPx", [])
	if source.get("kind") != "raven-first-floor-hall-qa-pilot" or source.get("approval") != "DRAFT_ONLY":
		return _bad("Hall QA import: expected immutable DRAFT_ONLY pilot")
	if info.get("path") != IMAGE_PATH or info.get("sha256") != IMAGE_SHA256 or info.get("gitBlobSha") != IMAGE_BLOB_SHA:
		return _bad("Hall QA import: approved art identity does not match")
	if pixels.size() != 2 or int(pixels[0]) != 1672 or int(pixels[1]) != 941:
		return _bad("Hall QA import: unexpected original image dimensions")
	if source.get("waypoints", []).size() != 7 or source.get("edges", []).size() != 7:
		return _bad("Hall QA import: expected seven waypoints and seven edges")
	var waypoints: Array = []
	for original in source["waypoints"]:
		waypoints.append({
			"id": str(original.get("id", "")),
			"label": str(original.get("id", "")),
			"type": _import_kind(str(original.get("kind", ""))),
			"pointPx": original.get("pointPx", []).duplicate(true),
			"provisional": true
		})
	var routes: Array = []
	var number := 1
	for edge in source["edges"]:
		routes.append({
			"id": "QA-ROUTE-%03d" % number,
			"from": str(edge.get("from", "")),
			"to": str(edge.get("to", "")),
			"bidirectional": bool(edge.get("bidirectional", true)),
			"cells": [],
			"provisional": true
		})
		number += 1
	var draft := {
		"schemaVersion": 1,
		"kind": "raven-grid-route-draft",
		"approval": "DRAFT_ONLY",
		"productionReady": false,
		"canonicalNavigationAuthority": false,
		"coordinateSpace": "image-pixel",
		"source": info.duplicate(true),
		"sourceQaPath": HALL_SOURCE,
		"grid": {"cellWidth": 32, "cellHeight": 32, "origin": [0, 0], "visible": true, "showCoordinates": false},
		"waypoints": waypoints,
		"routes": routes,
		"blockedCells": [],
		"walkablePolygons": source.get("walkablePolygons", []).duplicate(true),
		"noGoPolygons": source.get("noGoPolygons", []).duplicate(true),
		"nextWaypointSerial": 1,
		"nextRouteSerial": 8
	}
	var check := validate(draft)
	if not check.ok:
		return _bad("Hall QA import: " + str(check.error))
	return {"ok": true, "document": draft}


static func _import_kind(source_kind: String) -> String:
	match source_kind:
		"spawn": return "Spawn"
		"interaction": return "Interaction"
		"portal_approach": return "Door Approach"
		"return_spawn": return "Return Spawn"
		_: return "Waypoint"


static func column_label(col: int) -> String:
	if col < 0:
		return ""
	var result := ""
	var index := col + 1
	while index > 0:
		index -= 1
		result = char(65 + (index % 26)) + result
		index = int(index / 26)
	return result


static func cell_name(col: int, row: int) -> String:
	if col < 0 or row < 0:
		return ""
	return column_label(col) + str(row + 1)


static func parse_cell(name: String) -> Dictionary:
	var value := name.strip_edges().to_upper()
	var i := 0
	while i < value.length():
		var code := value.unicode_at(i)
		if code < 65 or code > 90:
			break
		i += 1
	if i == 0 or i == value.length():
		return _bad("Invalid cell '" + name + "': use A1, H7 or AA12")
	var suffix := value.substr(i)
	if not suffix.is_valid_int() or suffix.begins_with("0"):
		return _bad("Invalid row in '" + name + "'; row numbering begins at 1")
	var row := int(suffix) - 1
	if row < 0 or row > 99999:
		return _bad("Row outside permitted range in '" + name + "'")
	var column := 0
	for j in range(i):
		column = column * 26 + value.unicode_at(j) - 64
		if column > 99999:
			return _bad("Column outside permitted range in '" + name + "'")
	return {"ok": true, "col": column - 1, "row": row, "cell": cell_name(column - 1, row)}


static func _grid(doc: Dictionary) -> Dictionary:
	return doc.get("grid", {})


static func _image_size(doc: Dictionary) -> Vector2:
	var pixels: Array = doc.get("source", {}).get("dimensionsPx", [0, 0])
	if pixels.size() != 2:
		return Vector2.ZERO
	return Vector2(float(pixels[0]), float(pixels[1]))


static func pixel_to_cell(point: Vector2, doc: Dictionary) -> String:
	var size := _image_size(doc)
	if point.x < 0.0 or point.y < 0.0 or point.x >= size.x or point.y >= size.y:
		return ""
	var grid := _grid(doc)
	var step_x := float(grid.get("cellWidth", 0))
	var step_y := float(grid.get("cellHeight", 0))
	var offset: Array = grid.get("origin", [])
	if step_x <= 0.0 or step_y <= 0.0 or offset.size() != 2:
		return ""
	var col := floori((point.x - float(offset[0])) / step_x)
	var row := floori((point.y - float(offset[1])) / step_y)
	return cell_name(col, row)


static func cell_to_pixel(cell: String, doc: Dictionary) -> Vector2:
	var decoded := parse_cell(cell)
	if not decoded.ok:
		return Vector2.INF
	var grid := _grid(doc)
	var offset: Array = grid.get("origin", [])
	if offset.size() != 2:
		return Vector2.INF
	var center := Vector2(
		float(offset[0]) + (int(decoded.col) + 0.5) * float(grid.get("cellWidth", 0)),
		float(offset[1]) + (int(decoded.row) + 0.5) * float(grid.get("cellHeight", 0))
	)
	var size := _image_size(doc)
	return center if center.x >= 0.0 and center.y >= 0.0 and center.x < size.x and center.y < size.y else Vector2.INF


static func pixel_pair(point: Vector2) -> Array:
	return [snappedf(point.x, 0.001), snappedf(point.y, 0.001)]


static func _vector(pair: Variant) -> Vector2:
	if not pair is Array or pair.size() != 2:
		return Vector2.INF
	if not (pair[0] is int or pair[0] is float) or not (pair[1] is int or pair[1] is float):
		return Vector2.INF
	return Vector2(float(pair[0]), float(pair[1]))


static func _polygon_points(data: Dictionary) -> PackedVector2Array:
	var result := PackedVector2Array()
	for raw in data.get("pointsPx", []):
		result.append(_vector(raw))
	return result


static func _inside_art(point: Vector2, doc: Dictionary) -> bool:
	var size := _image_size(doc)
	return point.is_finite() and point.x >= 0.0 and point.y >= 0.0 and point.x < size.x and point.y < size.y


static func _is_restricted(point: Vector2, doc: Dictionary) -> bool:
	if not _inside_art(point, doc):
		return true
	for region in doc.get("noGoPolygons", []):
		if Geometry2D.is_point_in_polygon(point, _polygon_points(region)):
			return true
	var walkable: Array = doc.get("walkablePolygons", [])
	if not walkable.is_empty():
		var inside := false
		for region in walkable:
			if Geometry2D.is_point_in_polygon(point, _polygon_points(region)):
				inside = true
				break
		if not inside:
			return true
	return doc.get("blockedCells", []).has(pixel_to_cell(point, doc))


static func _crosses_polygon(a: Vector2, b: Vector2, region: Dictionary) -> bool:
	var polygon := _polygon_points(region)
	for i in range(polygon.size()):
		if Geometry2D.segment_intersects_segment(a, b, polygon[i], polygon[(i + 1) % polygon.size()]) != null:
			return true
	return false


static func _check_segment(a: Vector2, b: Vector2, doc: Dictionary) -> String:
	if not _inside_art(a, doc) or not _inside_art(b, doc):
		return "Route exits the approved source-image bounds"
	for region in doc.get("noGoPolygons", []):
		if _crosses_polygon(a, b, region):
			return "Route crosses no-go polygon " + str(region.get("id", "unknown"))
	var count := maxi(1, ceili(a.distance_to(b) / 2.0))
	for i in range(count + 1):
		var sample := a.lerp(b, float(i) / count)
		if _is_restricted(sample, doc):
			return "Route crosses blocked cell, no-go polygon or outside walkable area near " + str(sample.round())
	return ""


static func parse_route_text(text: String, doc: Dictionary) -> Dictionary:
	var clean := text.replace("->", "→")
	var cells: Array = []
	for part in clean.split("→", false):
		var parsed := parse_cell(part)
		if not parsed.ok:
			return _bad(str(parsed.error))
		var name: String = parsed.cell
		if not cell_to_pixel(name, doc).is_finite():
			return _bad("Cell " + name + " lies outside the source image")
		if not cells.is_empty():
			var previous := parse_cell(str(cells.back()))
			var delta := absi(int(previous.col) - int(parsed.col)) + absi(int(previous.row) - int(parsed.row))
			if delta != 1:
				return _bad("Invalid step " + str(cells.back()) + " → " + name + ": move exactly one orthogonal cell")
		cells.append(name)
	if cells.size() < 2:
		return _bad("A cell route needs at least two adjacent cells, e.g. G7 → H7")
	return {"ok": true, "cells": cells}


static func route_points(route: Dictionary, doc: Dictionary) -> PackedVector2Array:
	var by_id := _waypoint_lookup(doc)
	var a: Dictionary = by_id.get(str(route.get("from", "")), {})
	var b: Dictionary = by_id.get(str(route.get("to", "")), {})
	if a.is_empty() or b.is_empty():
		return PackedVector2Array()
	var points := PackedVector2Array([_vector(a["pointPx"])])
	for i in range(1, route.get("cells", []).size() - 1):
		points.append(cell_to_pixel(str(route["cells"][i]), doc))
	points.append(_vector(b["pointPx"]))
	return points


static func _waypoint_lookup(doc: Dictionary) -> Dictionary:
	var result := {}
	for point in doc.get("waypoints", []):
		result[str(point.get("id", ""))] = point
	return result


static func _check_route(route: Dictionary, doc: Dictionary) -> String:
	var by_id := _waypoint_lookup(doc)
	var a := str(route.get("from", ""))
	var b := str(route.get("to", ""))
	if not by_id.has(a) or not by_id.has(b) or a == b:
		return "Route " + str(route.get("id", "")) + ": unknown or identical endpoint IDs"
	if not route.get("bidirectional") is bool:
		return "Route " + str(route.get("id", "")) + ": direction must be boolean"
	var cells: Variant = route.get("cells", null)
	if not cells is Array:
		return "Route cells must be an array"
	if bool(route.get("provisional", false)):
		if not cells.is_empty():
			return "Provisional imported straight route cannot claim authored cells"
	else:
		if cells.size() < 2:
			return "Authored route needs an ordered sequence of cells"
		var parsed := parse_route_text(" → ".join(cells), doc)
		if not parsed.ok:
			return str(parsed.error)
		var first := pixel_to_cell(_vector(by_id[a]["pointPx"]), doc)
		var last := pixel_to_cell(_vector(by_id[b]["pointPx"]), doc)
		if cells[0] != first or cells.back() != last:
			return "Route endpoints must match waypoint cells " + first + " and " + last
	var positions := route_points(route, doc)
	if positions.size() < 2:
		return "Route has no real positions"
	for i in range(1, positions.size()):
		var error := _check_segment(positions[i - 1], positions[i], doc)
		if not error.is_empty():
			return "%s, segment %d: %s" % [str(route.get("id", "")), i, error]
	return ""


static func validate(doc: Dictionary) -> Dictionary:
	if int(doc.get("schemaVersion", -1)) != 1 or doc.get("kind") != "raven-grid-route-draft":
		return _bad("Unsupported route draft schemaVersion/kind; required v1")
	if doc.get("approval") != "DRAFT_ONLY" or doc.get("productionReady") != false:
		return _bad("Navigation authoring cannot promote geometry to production")
	if doc.get("canonicalNavigationAuthority") != false or doc.get("coordinateSpace") != "image-pixel":
		return _bad("Canonical world-plan navigation authority is forbidden")
	var source: Dictionary = doc.get("source", {})
	if source.get("path") != IMAGE_PATH or source.get("sha256") != IMAGE_SHA256 or source.get("gitBlobSha") != IMAGE_BLOB_SHA:
		return _bad("Source-image identity differs from approved Hall PNG")
	if _image_size(doc) != Vector2(1672, 941):
		return _bad("Source image must remain 1672 × 941 pixels")
	var grid: Dictionary = _grid(doc)
	if not grid.get("cellWidth") is int and not grid.get("cellWidth") is float:
		return _bad("Grid cellWidth must be numeric")
	if not grid.get("cellHeight") is int and not grid.get("cellHeight") is float:
		return _bad("Grid cellHeight must be numeric")
	for field in ["cellWidth", "cellHeight"]:
		var value := float(grid.get(field, 0))
		if value < 4.0 or value > 512.0 or not is_finite(value):
			return _bad("Grid " + field + " must be 4..512 image pixels")
	var offset := _vector(grid.get("origin", []))
	if not offset.is_finite() or absf(offset.x) > 4096 or absf(offset.y) > 4096:
		return _bad("Grid origin must contain two finite pixel offsets")
	if not doc.get("waypoints", null) is Array or not doc.get("routes", null) is Array:
		return _bad("Draft must contain waypoint and route arrays")
	if doc["waypoints"].size() > 500 or doc["routes"].size() > 1000:
		return _bad("Draft is too large")
	for key in ["blockedCells", "walkablePolygons", "noGoPolygons"]:
		if not doc.get(key, null) is Array:
			return _bad("Missing array " + key)
	var occupied := {}
	for cell in doc["blockedCells"]:
		var p := parse_cell(str(cell))
		if not p.ok or not cell_to_pixel(str(cell), doc).is_finite() or occupied.has(str(cell)):
			return _bad("Invalid, duplicate or out-of-image blocked cell: " + str(cell))
		occupied[str(cell)] = true
	for group in ["walkablePolygons", "noGoPolygons"]:
		for region in doc[group]:
			if not region is Dictionary or region.get("pointsPx", []).size() < 3:
				return _bad("Invalid polygon in " + group)
			for point in region["pointsPx"]:
				if not _inside_art(_vector(point), doc):
					return _bad("Polygon source pixel is outside art")
	var ids := {}
	for wp in doc["waypoints"]:
		if not wp is Dictionary:
			return _bad("Invalid waypoint")
		var id := str(wp.get("id", ""))
		if not id.begins_with("QA-") or id.length() > 100 or ids.has(id):
			return _bad("Invalid or duplicate stable QA waypoint ID: " + id)
		ids[id] = true
		if not wp.get("label") is String or str(wp["label"]).strip_edges().is_empty():
			return _bad("Waypoint " + id + " needs a display label")
		if not TYPES.has(wp.get("type")):
			return _bad("Waypoint " + id + " has an unknown type")
		var point := _vector(wp.get("pointPx", []))
		if not _inside_art(point, doc) or _is_restricted(point, doc):
			return _bad("Waypoint " + id + " lies outside walkable area or within an obstacle")
	var route_ids := {}
	for route in doc["routes"]:
		if not route is Dictionary:
			return _bad("Invalid authored route")
		var id := str(route.get("id", ""))
		if not id.begins_with("QA-ROUTE-") or route_ids.has(id):
			return _bad("Invalid or duplicate stable route ID: " + id)
		route_ids[id] = true
		var error := _check_route(route, doc)
		if not error.is_empty():
			return _bad(error)
	return {"ok": true}


static func _finish_edit(doc: Dictionary) -> Dictionary:
	var checked := validate(doc)
	return {"ok": true, "document": doc} if checked.ok else checked


static func move_waypoint(original: Dictionary, id: String, pixel: Vector2) -> Dictionary:
	var doc: Dictionary = original.duplicate(true)
	for wp in doc["waypoints"]:
		if wp["id"] == id:
			wp["pointPx"] = pixel_pair(pixel)
			return _finish_edit(doc)
	return _bad("Unknown waypoint ID " + id)


static func set_waypoint_info(original: Dictionary, id: String, label: String, kind: String) -> Dictionary:
	var doc: Dictionary = original.duplicate(true)
	for wp in doc["waypoints"]:
		if wp["id"] == id:
			wp["label"] = label.strip_edges()
			wp["type"] = kind
			return _finish_edit(doc)
	return _bad("Unknown waypoint ID " + id)


static func add_waypoint(original: Dictionary, pixel: Vector2, label: String = "New waypoint") -> Dictionary:
	var doc: Dictionary = original.duplicate(true)
	var serial := int(doc.get("nextWaypointSerial", 1))
	var known := _waypoint_lookup(doc)
	var id := "QA-USER-%03d" % serial
	while known.has(id):
		serial += 1
		id = "QA-USER-%03d" % serial
	doc["nextWaypointSerial"] = serial + 1
	doc["waypoints"].append({"id": id, "label": label, "type": "Waypoint", "pointPx": pixel_pair(pixel), "provisional": false})
	var result := _finish_edit(doc)
	if result.ok:
		result["id"] = id
	return result


static func delete_waypoint(original: Dictionary, id: String) -> Dictionary:
	for route in original.get("routes", []):
		if route.get("from") == id or route.get("to") == id:
			return _bad("Waypoint " + id + " is referenced by route " + str(route.get("id")) + "; delete the route first")
	var doc: Dictionary = original.duplicate(true)
	for i in range(doc["waypoints"].size()):
		if doc["waypoints"][i].get("id") == id:
			doc["waypoints"].remove_at(i)
			return _finish_edit(doc)
	return _bad("Unknown waypoint " + id)


static func add_route(original: Dictionary, from_id: String, to_id: String) -> Dictionary:
	var doc: Dictionary = original.duplicate(true)
	var serial := int(doc.get("nextRouteSerial", 1))
	var id := "QA-ROUTE-%03d" % serial
	var occupied := {}
	for route in doc["routes"]:
		occupied[route["id"]] = true
	while occupied.has(id):
		serial += 1
		id = "QA-ROUTE-%03d" % serial
	doc["nextRouteSerial"] = serial + 1
	# A new edge is also provisional until the user explicitly authors cells.
	doc["routes"].append({"id": id, "from": from_id, "to": to_id, "bidirectional": true, "cells": [], "provisional": true})
	var result := _finish_edit(doc)
	if result.ok:
		result["id"] = id
	return result


static func delete_route(original: Dictionary, id: String) -> Dictionary:
	var doc: Dictionary = original.duplicate(true)
	for i in range(doc["routes"].size()):
		if doc["routes"][i].get("id") == id:
			doc["routes"].remove_at(i)
			return _finish_edit(doc)
	return _bad("Unknown route ID " + id)


static func set_route_cells(original: Dictionary, id: String, route_text: String) -> Dictionary:
	var parsed := parse_route_text(route_text, original)
	if not parsed.ok:
		return parsed
	var doc: Dictionary = original.duplicate(true)
	for route in doc["routes"]:
		if route.get("id") == id:
			route["cells"] = parsed.cells
			route["provisional"] = false
			return _finish_edit(doc)
	return _bad("Unknown route ID " + id)


static func set_route_direction(original: Dictionary, id: String, bidirectional: bool) -> Dictionary:
	var doc: Dictionary = original.duplicate(true)
	for route in doc["routes"]:
		if route.get("id") == id:
			route["bidirectional"] = bidirectional
			return _finish_edit(doc)
	return _bad("Unknown route ID " + id)


static func change_grid(original: Dictionary, width: int, height: int, origin: Vector2, visible: bool, coords: bool) -> Dictionary:
	var doc: Dictionary = original.duplicate(true)
	doc["grid"] = {"cellWidth": width, "cellHeight": height, "origin": pixel_pair(origin), "visible": visible, "showCoordinates": coords}
	return _finish_edit(doc)


static func set_blocked(original: Dictionary, cell: String, blocked: bool) -> Dictionary:
	var name := parse_cell(cell)
	if not name.ok or not cell_to_pixel(str(name.get("cell", "")), original).is_finite():
		return _bad("Obstacle cell is outside the image: " + cell)
	var doc: Dictionary = original.duplicate(true)
	var cells: Array = doc["blockedCells"]
	if blocked and not cells.has(name.cell):
		cells.append(name.cell)
		cells.sort()
	elif not blocked:
		cells.erase(name.cell)
	return _finish_edit(doc)


static func compile_qa_graph(doc: Dictionary) -> Dictionary:
	var valid := validate(doc)
	if not valid.ok:
		return valid
	var anchors: Array = []
	var edges: Array = []
	for wp in doc["waypoints"]:
		var hotspot := "QA-PORTAL-HALL-CORRIDOR" if wp["id"] == "QA-HALL-PORTAL-APPROACH" else "QA-HS:" + str(wp["id"])
		anchors.append({"id": wp["id"], "position": wp["pointPx"].duplicate(), "roomId": "RM-ROOM-HALL", "kind": "safe" if wp["type"] in ["Spawn", "Return Spawn"] else "qa", "hotspotId": hotspot})
	for route in doc["routes"]:
		var previous: String = route["from"]
		var cells: Array = route["cells"]
		# One intermediate QA anchor per authored cell guarantees corners survive.
		for i in range(1, cells.size() - 1):
			var anchor_id := "%s-STEP-%03d" % [str(route["id"]), i]
			anchors.append({"id": anchor_id, "position": pixel_pair(cell_to_pixel(str(cells[i]), doc)), "roomId": "RM-ROOM-HALL", "kind": "qa"})
			edges.append({"from": previous, "to": anchor_id, "bidirectional": route["bidirectional"]})
			previous = anchor_id
		edges.append({"from": previous, "to": route["to"], "bidirectional": route["bidirectional"]})
	var graph_data := {"anchors": anchors, "edges": edges, "provenance": {"approval": "DRAFT_ONLY", "productionReady": false, "coordinateSpace": "image-pixel"}}
	var graph = Graph.new()
	graph.rebuild({}, graph_data)
	return {"ok": true, "data": graph_data, "graph": graph}


static func route_preview(doc: Dictionary, from_id: String, to_id: String) -> Dictionary:
	var compiled := compile_qa_graph(doc)
	if not compiled.ok:
		return compiled
	var path: Array[String] = compiled.graph.route(from_id, to_id)
	if path.is_empty():
		return _bad("Unreachable: no directed authored route between selected waypoints")
	var points := PackedVector2Array()
	var length := 0.0
	for id in path:
		var pixel: Vector2 = compiled.graph.position(id)
		if not points.is_empty():
			length += points[-1].distance_to(pixel)
		points.append(pixel)
	return {"ok": true, "anchorIds": path, "points": points, "lengthPx": length}


static func save_draft(path: String, doc: Dictionary) -> Dictionary:
	if not path.ends_with(".json"):
		return _bad("Draft path must end with .json")
	if not path.begins_with("user://room_builder_routes/") and not path.begins_with(PROJECT_DRAFT_DIR):
		return _bad("Save only inside user://room_builder_routes/ or res://assets/raven/map/qa/drafts/")
	var checked := validate(doc)
	if not checked.ok:
		return checked
	var abs_dir := ProjectSettings.globalize_path(path.get_base_dir())
	var error := DirAccess.make_dir_recursive_absolute(abs_dir)
	if error != OK:
		return _bad("Cannot create draft directory: error " + str(error))
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return _bad("Cannot open draft for writing: error " + str(FileAccess.get_open_error()))
	file.store_string(JSON.stringify(doc, "\t") + "\n")
	file.flush()
	file.close()
	return {"ok": true, "path": path}


static func load_draft(path: String) -> Dictionary:
	if not path.begins_with("user://room_builder_routes/") and not path.begins_with(PROJECT_DRAFT_DIR):
		return _bad("Load only from separate QA draft directories")
	var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not value is Dictionary:
		return _bad("Missing or malformed draft file: " + path)
	var checked := validate(value)
	if not checked.ok:
		return checked
	return {"ok": true, "document": value}


static func _bad(message: String) -> Dictionary:
	return {"ok": false, "error": message}
