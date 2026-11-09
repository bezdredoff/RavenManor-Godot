@tool
extends RefCounted
## MAP-EDIT-04: deterministic freehand stroke -> existing authored v1 cells.
## Read-only proposal. All mutations/authority remain in RouteDocument.
const Routes = preload("res://addons/room_builder_routes/route_document.gd")
const MAX_SAMPLES := 20000
const MAX_CELLS := 4000


static func convert(doc: Dictionary, room_id: String, from_id: String, to_id: String,
		raw: PackedVector2Array, tolerance: float = 4.0, route_id: String = "") -> Dictionary:
	var cells: Array = []
	if not Routes.ROOM_IDS.has(room_id):
		return _fail(doc, raw, cells, "Choose an editing room", Vector2.INF)
	var lookup: Dictionary = Routes._waypoint_lookup(doc)
	if from_id == to_id or not lookup.has(from_id) or not lookup.has(to_id):
		return _fail(doc, raw, cells, "Choose two different existing waypoints", Vector2.INF)
	if Routes.room_for_id(doc, from_id) != room_id or Routes.room_for_id(doc, to_id) != room_id:
		return _fail(doc, raw, cells, "Both route endpoints must belong to " + room_id, Vector2.INF)
	if not route_id.is_empty():
		var existing := false
		for route in doc.get("routes", []):
			if str(route["id"]) == route_id:
				existing = true
				if str(route["from"]) != from_id or str(route["to"]) != to_id:
					return _fail(doc, raw, cells, "Redraw cannot change the route endpoints", Vector2.INF)
				break
		if not existing:
			return _fail(doc, raw, cells, "Selected route no longer exists", Vector2.INF)
	if raw.size() < 2 or raw.size() > MAX_SAMPLES:
		return _fail(doc, raw, cells, "Hold the left mouse button and draw a stroke (2–20000 samples)", Vector2.INF)
	if not is_finite(tolerance) or tolerance < 0.0 or tolerance > 48.0:
		return _fail(doc, raw, cells, "Simplification must be 0–48 image pixels", Vector2.INF)
	var start: Vector2 = Routes._vector(lookup[from_id]["pointPx"])
	var finish: Vector2 = Routes._vector(lookup[to_id]["pointPx"])
	var width := float(doc["grid"]["cellWidth"])
	var height := float(doc["grid"]["cellHeight"])
	var snap_distance := maxf(width, height) * 1.75
	if not raw[0].is_finite() or raw[0].distance_to(start) > snap_distance:
		return _fail(doc, raw, cells, "Begin the stroke near FROM waypoint " + from_id, raw[0])
	if not raw[raw.size() - 1].is_finite() or raw[raw.size() - 1].distance_to(finish) > snap_distance:
		return _fail(doc, raw, cells, "Finish the stroke near TO waypoint " + to_id, raw[raw.size() - 1])
	for point in raw:
		if not point.is_finite() or not Routes._inside_art(point, doc):
			return _fail(doc, raw, cells, "Stroke leaves the approved image", point)
		var restriction: Dictionary = Routes.restriction_at(point, doc)
		if restriction["kind"] != "allowed":
			return _fail(doc, raw, cells, "Stroke at " + str(point.round()) + ": " + str(restriction["reason"]), point)
		var room_error := _room_error(doc, room_id, point)
		if not room_error.is_empty():
			return _fail(doc, raw, cells, "Stroke at " + str(point.round()) + ": " + room_error, point)
	# Anchor endpoint snapping is explicit. Retain turns from the actual pixel
	# stroke; a configurable small distance filter removes mouse jitter without
	# performing global smoothing or rerouting through unrelated corridors.
	var filtered := PackedVector2Array([start])
	for i in range(1, raw.size() - 1):
		if raw[i].distance_to(filtered[filtered.size() - 1]) >= maxf(0.5, tolerance):
			filtered.append(raw[i])
	filtered.append(finish)
	for i in range(1, filtered.size()):
		var segment_error: String = Routes._check_segment(filtered[i - 1], filtered[i], doc)
		if not segment_error.is_empty():
			var blocked_at: Vector2 = _first_bad_pixel(doc, room_id, filtered[i - 1], filtered[i])
			return _fail(doc, raw, cells, "Drawn stroke crosses an obstacle near " +
				str(blocked_at.round()) + ": " + segment_error, blocked_at)
		# Exact 2px sampling (same granularity as RouteDocument geometry).
		# Ownership is distinct from global walkability: traversing the next
		# room is not allowed merely because its floor is also green.
		var count := maxi(1, ceili(filtered[i - 1].distance_to(filtered[i]) / 2.0))
		for j in range(count + 1):
			var sample: Vector2 = filtered[i - 1].lerp(filtered[i], float(j) / count)
			var room_error := _room_error(doc, room_id, sample)
			if not room_error.is_empty():
				return _fail(doc, raw, cells, "Stroke crosses room boundary at " + str(sample.round()) + ": " + room_error, sample)
	for point in filtered:
		var cell := Routes.pixel_to_cell(point, doc)
		if cell.is_empty():
			return _fail(doc, raw, cells, "Sample cannot be snapped inside the image", point)
		if cells.is_empty():
			cells.append(cell)
		else:
			_append_orthogonal(cells, cell)
		if cells.size() > MAX_CELLS:
			return _fail(doc, raw, cells, "Stroke contains too many grid steps; draw a shorter route", point)
	if cells.size() < 2:
		return _fail(doc, raw, cells, "FROM and TO must occupy different grid cells", finish)
	# Do not silently erase backtracking or invent a short-cut. Revisited cells
	# indicate an ambiguous stroke: ask the owner to redraw the exact corridor.
	var seen := {}
	for cell in cells:
		if seen.has(cell):
			return _fail(doc, raw, cells, "Stroke doubles back through cell " + cell + ". Redraw without loops.", Routes.cell_to_pixel(cell, doc))
		seen[cell] = true
	var centers := _centers(doc, cells)
	for i in range(centers.size()):
		var point: Vector2 = centers[i]
		if not point.is_finite():
			return _fail(doc, raw, cells, "Cell " + str(cells[i]) + " is outside the image", point)
		var restriction: Dictionary = Routes.restriction_at(point, doc)
		if restriction["kind"] != "allowed":
			return _fail(doc, raw, cells, "Cell " + str(cells[i]) + " at " + str(point.round()) + ": " + str(restriction["reason"]), point)
		var room_error := _room_error(doc, room_id, point)
		if not room_error.is_empty():
			return _fail(doc, raw, cells, "Cell " + str(cells[i]) + " at " + str(point.round()) + ": " + room_error, point)
		if i > 0:
			var error: String = Routes._check_segment(centers[i - 1], point, doc)
			if not error.is_empty():
				var blocked_at: Vector2 = _first_bad_pixel(doc, room_id, centers[i - 1], point)
				return _fail(doc, raw, cells, "Invalid grid step " + str(cells[i - 1]) + " → " + str(cells[i]) + ": " + error, blocked_at)
			var samples := maxi(1, ceili(centers[i - 1].distance_to(point) / 2.0))
			for j in range(samples + 1):
				var between: Vector2 = centers[i - 1].lerp(point, float(j) / samples)
				var boundary_error := _room_error(doc, room_id, between)
				if not boundary_error.is_empty():
					return _fail(doc, raw, cells, "Grid step " + str(cells[i - 1]) + " → " + str(cells[i]) + " crosses room ownership: " + boundary_error, between)
	# Use the authoritative route validator for endpoint alignment, direction,
	# room ownership, per-segment walkability and compiled runtime geometry.
	var candidate: Dictionary = doc
	var id := route_id
	if id.is_empty():
		var created: Dictionary = Routes.add_route(candidate, from_id, to_id)
		if not created.get("ok", false):
			return _fail(doc, raw, cells, str(created.get("error", "Cannot create route")), finish)
		candidate = created["document"]
		id = str(created["id"])
	var checked: Dictionary = Routes.set_route_cells(candidate, id, " → ".join(PackedStringArray(cells)))
	if not checked.get("ok", false):
		return _fail(doc, raw, cells, "Authoritative route validation: " + str(checked.get("error", "invalid path")), finish)
	return {"ok": true, "cells": cells, "points": centers, "raw": raw.duplicate(),
		"invalidAt": Vector2.INF, "error": "", "routeId": id,
		"document": checked["document"]}


# The v1 QA polygon list already carries roomId on the five imported
# walkable regions. Optional user-authored zones are tagged by the editor.
# Untagged polygons cannot silently grant cross-room authoring permission.
static func _first_bad_pixel(doc: Dictionary, room_id: String, a: Vector2, b: Vector2) -> Vector2:
	var count := maxi(1, ceili(a.distance_to(b) / 2.0))
	for i in range(count + 1):
		var sample: Vector2 = a.lerp(b, float(i) / count)
		if Routes.restriction_at(sample, doc)["kind"] != "allowed" or not _room_error(doc, room_id, sample).is_empty():
			return sample
	for zone in doc.get("noGoPolygons", []):
		var polygon: PackedVector2Array = Routes._polygon_points(zone)
		for i in range(polygon.size()):
			var crossing: Variant = Geometry2D.segment_intersects_segment(a, b,
				polygon[i], polygon[(i + 1) % polygon.size()])
			if crossing != null:
				return crossing
	return a.lerp(b, 0.5)


static func _room_error(doc: Dictionary, room_id: String, point: Vector2) -> String:
	var own := false
	var other := ""
	var unknown := false
	for polygon in doc.get("walkablePolygons", []):
		if Geometry2D.is_point_in_polygon(point, Routes._polygon_points(polygon)):
			var owner := str(polygon.get("roomId", ""))
			if owner == room_id:
				own = true
			elif owner.is_empty():
				unknown = true
			else:
				other = owner
	if not other.is_empty():
		return "Entered " + other + " walkable region; edit one room at a time"
	if not own:
		if unknown:
			return "Walkable zone has no room ownership. Redraw that draft zone from the selected room."
		return "Outside the selected room's owned WALKABLE area"
	return ""


static func _append_orthogonal(cells: Array, destination: String) -> void:
	var source: Dictionary = Routes.parse_cell(str(cells.back()))
	var target: Dictionary = Routes.parse_cell(destination)
	if not source.ok or not target.ok:
		return
	var x := int(source.col)
	var y := int(source.row)
	var dx := int(target.col) - x
	var dy := int(target.row) - y
	var nx := absi(dx)
	var ny := absi(dy)
	var moved_x := 0
	var moved_y := 0
	var sx := signi(dx)
	var sy := signi(dy)
	while moved_x < nx or moved_y < ny:
		# Compare next grid-boundary crossings. Ties always use X first;
		# deterministic even for sparse, diagonal input.
		if moved_x < nx and (moved_y >= ny or
				float(2 * moved_x + 1) * float(maxi(ny, 1)) <=
				float(2 * moved_y + 1) * float(maxi(nx, 1))):
			x += sx
			moved_x += 1
		else:
			y += sy
			moved_y += 1
		cells.append(Routes.cell_name(x, y))


static func _centers(doc: Dictionary, cells: Array) -> PackedVector2Array:
	var result := PackedVector2Array()
	for cell in cells:
		result.append(Routes.cell_to_pixel(str(cell), doc))
	return result


static func _fail(doc: Dictionary, raw: PackedVector2Array, cells: Array,
		reason: String, point: Vector2) -> Dictionary:
	return {"ok": false, "error": reason, "raw": raw.duplicate(),
		"cells": cells.duplicate(), "points": _centers(doc, cells),
		"invalidAt": point, "routeId": ""}
