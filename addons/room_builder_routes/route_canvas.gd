@tool
extends Control
## Native Room Builder Navigation / Routes canvas, image-pixel coordinates only.
const Routes = preload("res://addons/room_builder_routes/route_document.gd")
signal waypoint_chosen(id: String)
signal waypoint_dropped(id: String, point: Vector2)
signal route_chosen(id: String)
signal image_pixel_chosen(point: Vector2)
signal cell_chosen(cell: String)
signal obstacle_paint(cell: String, blocked: bool)
signal freehand_started()
signal freehand_changed(stroke: PackedVector2Array)
signal freehand_finished(stroke: PackedVector2Array)
signal freehand_cancelled()
signal zone_chosen(group: String, id: String)
signal zone_vertex_chosen(index: int)
signal zone_drag_changed(points: PackedVector2Array)
signal zone_drag_finished(points: PackedVector2Array)
signal zone_insert_requested(edge_index: int, point: Vector2)
signal zone_cancelled()

var document: Dictionary = {}
var image: Texture2D
var mode := "Waypoints"
var active_room := "RM-ROOM-HALL"
var show_constraints := true
var selected_zone := ""
var selected_zone_group := ""
var selected_zone_vertex := -1
var zone_creating := false
var zone_inserting := false
var zone_edit_preview := PackedVector2Array()
var zone_edit_valid := true
var _zone_dragging := false
var _zone_drag_vertex := -1
var _zone_drag_base := PackedVector2Array()
var _zone_drag_start := Vector2.INF
var _zone_drag_moved := false
var zone_corner := Vector2.INF
var selected_waypoint := ""
var selected_route := ""
var selected_cell := ""
var preview_points := PackedVector2Array()
var zoom := 0.75
var image_origin := Vector2(28, 28)
var _drag_point := ""
var _drag_preview := Vector2.ZERO
var _drag_origin := Vector2.ZERO
var _did_drag := false
var _pan_active := false
var _last_mouse := Vector2.ZERO
var _painting := false
var _paint_value := true
var _painted: Dictionary = {}
var freehand_raw := PackedVector2Array()
var freehand_grid := PackedVector2Array()
var freehand_invalid := Vector2.INF
var freehand_cursor := Vector2.INF
var _freehand_active := false


func _ready() -> void:
	clip_contents = true
	mouse_filter = MOUSE_FILTER_STOP
	focus_mode = FOCUS_ALL
	resized.connect(queue_redraw)


func set_document(value: Dictionary) -> void:
	document = value
	queue_redraw()


func set_image(texture: Texture2D) -> void:
	image = texture
	queue_redraw()


func set_mode(value: String) -> void:
	cancel_freehand()
	mode = value
	_drag_point = ""
	_painting = false
	_zone_dragging = false
	zone_inserting = false
	queue_redraw()


func cancel_freehand() -> void:
	_freehand_active = false
	freehand_raw = PackedVector2Array()
	freehand_grid = PackedVector2Array()
	freehand_invalid = Vector2.INF
	freehand_cursor = Vector2.INF
	queue_redraw()


func set_freehand_preview(raw: PackedVector2Array, proposed: PackedVector2Array,
		invalid_at: Vector2 = Vector2.INF) -> void:
	freehand_raw = raw.duplicate()
	freehand_grid = proposed.duplicate()
	freehand_invalid = invalid_at
	queue_redraw()


func set_active_room(room_id: String) -> void:
	active_room = room_id
	queue_redraw()


func set_show_constraints(enabled: bool) -> void:
	show_constraints = enabled
	queue_redraw()


func set_selected_zone(id: String, group: String = "") -> void:
	if id != selected_zone or group != selected_zone_group:
		zone_edit_preview = PackedVector2Array()
		selected_zone_vertex = -1
		zone_inserting = false
	selected_zone = id
	selected_zone_group = group
	_zone_dragging = false
	queue_redraw()


func set_zone_drawing(active: bool) -> void:
	zone_creating = active
	if active:
		zone_inserting = false
		_zone_dragging = false
	queue_redraw()


func start_zone_insert() -> void:
	zone_inserting = true
	_zone_dragging = false
	queue_redraw()


func clear_zone_edit_preview() -> void:
	zone_edit_preview = PackedVector2Array()
	zone_edit_valid = true
	zone_inserting = false
	_zone_dragging = false
	queue_redraw()


func set_zone_edit_preview(points: PackedVector2Array, valid: bool) -> void:
	zone_edit_preview = points.duplicate()
	zone_edit_valid = valid
	queue_redraw()


func selected_zone_points() -> PackedVector2Array:
	for group in ["noGoPolygons", "walkablePolygons"]:
		if not selected_zone_group.is_empty() and group != selected_zone_group:
			continue
		for region in document.get(group, []):
			if str(region.get("id", "")) == selected_zone:
				return Routes._polygon_points(region)
	return PackedVector2Array()


func set_zone_corner(point: Vector2) -> void:
	zone_corner = point
	queue_redraw()


func show_preview(points: PackedVector2Array) -> void:
	preview_points = points
	queue_redraw()


func fit_image() -> void:
	if image == null:
		return
	zoom = clampf(minf((size.x - 44.0) / image.get_width(), (size.y - 44.0) / image.get_height()), 0.1, 4.0)
	image_origin = (size - image.get_size() * zoom) * 0.5
	queue_redraw()


func image_to_screen(point: Vector2) -> Vector2:
	return image_origin + point * zoom


func screen_to_image(point: Vector2) -> Vector2:
	return (point - image_origin) / zoom


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#151922"))
	if document.is_empty() or image == null:
		return
	draw_texture_rect(image, Rect2(image_origin, image.get_size() * zoom), false)
	if show_constraints or mode == "Zones":
		# Cell-centre preview of rejected space; polygon outlines below remain
		# exact image-pixel geometry. This explains blank-looking forbidden floor.
		_draw_outside_walkable_cells()
		for polygon in document.get("walkablePolygons", []):
			_draw_region(polygon, Color(0.12, 0.88, 0.32, 0.11), Color("#62ff90"))
		for polygon in document.get("noGoPolygons", []):
			_draw_region(polygon, Color(0.94, 0.08, 0.11, 0.40), Color("#ff676e"))
	_draw_grid()
	var g: Dictionary = document["grid"]
	if show_constraints or mode == "Zones":
		for cell in document.get("blockedCells", []):
			var centre := Routes.cell_to_pixel(str(cell), document)
			if not centre.is_finite():
				continue
			var w := float(g["cellWidth"]) * zoom
			var h := float(g["cellHeight"]) * zoom
			draw_rect(Rect2(image_to_screen(centre) - Vector2(w, h) * 0.5, Vector2(w, h)), Color(0.98, 0.40, 0.10, 0.68))
	if zone_corner.is_finite():
		draw_circle(image_to_screen(zone_corner), 8.0, Color("#f5ff00"))
		_draw_label(image_to_screen(zone_corner) + Vector2(10, -10), "1st corner", Color.WHITE)
	# Draw the selected route LAST with a high-contrast outline so it can
	# be found even on top of the detailed first-floor artwork.
	for selected_pass in [false, true]:
		for route in document.get("routes", []):
			var chosen: bool = str(route["id"]) == selected_route
			if chosen != selected_pass:
				continue
			var points: PackedVector2Array = Routes.route_points(route, document)
			if points.size() < 2:
				continue
			var source_room: String = Routes.room_for_id(document, str(route["from"]))
			var in_room: bool = source_room == active_room
			var color := Color("#ffe04e") if chosen else (Color("#e6a85c") if route["provisional"] else Color("#62d9f5"))
			if not in_room:
				color.a = 0.15
			var width := 5.0 if chosen else (2.5 if in_room else 1.5)
			for i in range(1, points.size()):
				if chosen:
					draw_line(image_to_screen(points[i - 1]), image_to_screen(points[i]), Color(0.07, 0.06, 0.12, 0.95), 9.0, true)
				if route["provisional"] and not chosen:
					_dashed(points[i - 1], points[i], color, width)
				else:
					draw_line(image_to_screen(points[i - 1]), image_to_screen(points[i]), color, width, true)
			if not bool(route["bidirectional"]):
				_draw_arrow(points[points.size() - 2], points[points.size() - 1], color)
			if chosen:
				draw_circle(image_to_screen(points[0]), 9.0, Color("#5bffb5"))
				draw_circle(image_to_screen(points[points.size() - 1]), 9.0, Color("#ff9a6a"))
	# Freehand is ONLY a proposal: blue mouse pixels, green authored cells,
	# red rejected segment/location. Waypoints remain visible over all layers.
	if mode == "Freehand":
		for i in range(1, freehand_raw.size()):
			draw_line(image_to_screen(freehand_raw[i - 1]), image_to_screen(freehand_raw[i]),
				Color("#39d5ff"), 2.0, true)
		for i in range(1, freehand_grid.size()):
			draw_line(image_to_screen(freehand_grid[i - 1]), image_to_screen(freehand_grid[i]),
				Color("#d5ff61"), 5.0, true)
		if freehand_invalid.is_finite():
			var rejected := image_to_screen(freehand_invalid)
			# Locate the actual offending source-stroke segment, not always
			# the last drag segment (which may be in another corridor).
			var nearest := INF
			var from_pixel := Vector2.INF
			var to_pixel := Vector2.INF
			for i in range(1, freehand_raw.size()):
				var closest: Vector2 = Geometry2D.get_closest_point_to_segment(
					freehand_invalid, freehand_raw[i - 1], freehand_raw[i])
				var distance: float = closest.distance_to(freehand_invalid)
				if distance < nearest:
					nearest = distance
					from_pixel = freehand_raw[i - 1]
					to_pixel = freehand_raw[i]
			if from_pixel.is_finite() and to_pixel.is_finite():
				draw_line(image_to_screen(from_pixel), image_to_screen(to_pixel), Color("#ff4141"), 4.0, true)
			draw_circle(rejected, 11.0, Color("#ff4141"))
			draw_arc(rejected, 14.0, 0, TAU, 24, Color.WHITE, 2.0)
		if freehand_cursor.is_finite():
			var cursor := image_to_screen(freehand_cursor)
			draw_line(cursor + Vector2(-8, 0), cursor + Vector2(8, 0), Color("#e9fbff"), 1.5)
			draw_line(cursor + Vector2(0, -8), cursor + Vector2(0, 8), Color("#e9fbff"), 1.5)
	if preview_points.size() > 1:
		for i in range(1, preview_points.size()):
			draw_line(image_to_screen(preview_points[i - 1]), image_to_screen(preview_points[i]), Color("#bfff5b"), 5.0, true)
	for wp in document.get("waypoints", []):
		var id := str(wp["id"])
		var pixel := _drag_preview if id == _drag_point else Routes._vector(wp["pointPx"])
		var centre := image_to_screen(pixel)
		var selected := id == selected_waypoint
		var in_room := Routes.waypoint_room(wp) == active_room
		var tint := Color("#ffe78a") if selected else (Color("#f1f1f6") if in_room else Color(0.65, 0.68, 0.76, 0.3))
		draw_circle(centre, 9.0 if selected else 6.0, tint)
		draw_arc(centre, 10.0 if selected else 7.0, 0.0, TAU, 24, Color("#2a2736"), 1.5)
		if in_room or selected:
			_draw_label(centre + Vector2(10, -12), str(wp["label"]), Color("#fff4d8"))
	if not selected_cell.is_empty():
		var centre := Routes.cell_to_pixel(selected_cell, document)
		if centre.is_finite():
			var w := float(g["cellWidth"]) * zoom
			var h := float(g["cellHeight"]) * zoom
			draw_rect(Rect2(image_to_screen(centre) - Vector2(w, h) * 0.5, Vector2(w, h)), Color("#fff89a"), false, 2.5)


func _draw_region(region: Dictionary, color: Color, border_color: Color) -> void:
	var raw: PackedVector2Array = Routes._polygon_points(region)
	var highlighted: bool = str(region.get("id", "")) == selected_zone
	if highlighted and not zone_edit_preview.is_empty():
		raw = zone_edit_preview
	var points := PackedVector2Array()
	for p in raw:
		points.append(image_to_screen(p))
	if points.size() < 3:
		return
	draw_colored_polygon(points, color)
	var outline := points.duplicate()
	outline.append(points[0])
	var outline_color := border_color
	if highlighted:
		outline_color = Color("#ffe66b") if zone_edit_valid else Color("#ff334d")
	draw_polyline(outline, outline_color, 4.0 if highlighted else 2.0, true)
	if highlighted and mode == "Zones":
		for i in range(points.size()):
			var fill := Color("#ffffff")
			if i == selected_zone_vertex:
				fill = Color("#ffc04d")
			if not zone_edit_valid:
				fill = Color("#ff4f5f")
			draw_circle(points[i], 7.0, Color("#171e29"))
			draw_circle(points[i], 5.0, fill)
	# Small labels are deliberate: exact IDs are available in the zone inspector.
	var centroid := Vector2.ZERO
	for point in points:
		centroid += point
	centroid /= float(points.size())
	if highlighted or zoom >= 0.65:
		_draw_label(centroid, str(region.get("id", "zone")), Color("#fffef5"))


func _draw_outside_walkable_cells() -> void:
	if document.get("walkablePolygons", []).is_empty():
		return
	var g: Dictionary = document["grid"]
	var w := float(g["cellWidth"])
	var h := float(g["cellHeight"])
	var origin := Routes._vector(g["origin"])
	var first_col := maxi(0, floori(-origin.x / w))
	var first_row := maxi(0, floori(-origin.y / h))
	var last_col := mini(2000, ceili((image.get_width() - origin.x) / w))
	var last_row := mini(2000, ceili((image.get_height() - origin.y) / h))
	for row in range(first_row, last_row):
		for col in range(first_col, last_col):
			var cell_start := origin + Vector2(col * w, row * h)
			var centre := cell_start + Vector2(w, h) * 0.5
			if not Routes._inside_art(centre, document):
				continue
			var diagnosis: Dictionary = Routes.restriction_at(centre, document)
			if diagnosis.get("kind") == "outside-walkable":
				draw_rect(Rect2(image_to_screen(cell_start), Vector2(w, h) * zoom),
					Color(0.08, 0.10, 0.18, 0.48))


func _draw_grid() -> void:
	var grid: Dictionary = document["grid"]
	if not bool(grid.get("visible", true)):
		return
	var w := float(grid["cellWidth"])
	var h := float(grid["cellHeight"])
	var o := Routes._vector(grid["origin"])
	var art_size := image.get_size()
	var start_col := maxi(0, ceili((0.0 - o.x) / w))
	var end_col := mini(1000, ceili((art_size.x - o.x) / w))
	var start_row := maxi(0, ceili((0.0 - o.y) / h))
	var end_row := mini(1000, ceili((art_size.y - o.y) / h))
	for col in range(start_col, end_col + 1):
		var x := o.x + col * w
		if x < 0 or x > art_size.x:
			continue
		draw_line(image_to_screen(Vector2(x, 0)), image_to_screen(Vector2(x, art_size.y)), Color(0.72, 0.87, 0.98, 0.27), 1.0)
		if col < end_col:
			_draw_label(image_to_screen(Vector2(x + 3, 4)), Routes.column_label(col), Color("#edf7ff"))
	for row in range(start_row, end_row + 1):
		var y := o.y + row * h
		if y < 0 or y > art_size.y:
			continue
		draw_line(image_to_screen(Vector2(0, y)), image_to_screen(Vector2(art_size.x, y)), Color(0.72, 0.87, 0.98, 0.27), 1.0)
		if row < end_row:
			_draw_label(image_to_screen(Vector2(3, y + 3)), str(row + 1), Color("#edf7ff"))
	if not bool(grid.get("showCoordinates", false)) or zoom < 0.5:
		return
	for row in range(start_row, end_row):
		for col in range(start_col, end_col):
			var cell := Routes.cell_name(col, row)
			var centre := Routes.cell_to_pixel(cell, document)
			if centre.is_finite():
				_draw_label(image_to_screen(centre) - Vector2(13, -4), cell, Color(0.94, 0.96, 0.99, 0.8))


func _draw_label(at: Vector2, value: String, tint: Color) -> void:
	draw_string(get_theme_default_font(), at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, tint, TextServer.JUSTIFICATION_NONE, TextServer.DIRECTION_AUTO, TextServer.ORIENTATION_HORIZONTAL)


func _draw_arrow(start: Vector2, end: Vector2, color: Color) -> void:
	var direction := (image_to_screen(end) - image_to_screen(start)).normalized()
	var point := image_to_screen(end) - direction * 15.0
	draw_line(point - direction * 10.0 + direction.rotated(PI / 2.0) * 5.0, point, color, 2.0)
	draw_line(point - direction * 10.0 - direction.rotated(PI / 2.0) * 5.0, point, color, 2.0)


func _dashed(start: Vector2, end: Vector2, color: Color, width: float) -> void:
	var a := image_to_screen(start)
	var b := image_to_screen(end)
	var distance := a.distance_to(b)
	var steps := maxi(1, ceili(distance / 10.0))
	for i in range(steps):
		if i % 2 == 0:
			draw_line(a.lerp(b, float(i) / steps), a.lerp(b, float(i + 1) / steps), color, width, true)


func _pick_waypoint(pixel: Vector2) -> String:
	var best := ""
	var max_distance := 14.0 / zoom
	for wp in document.get("waypoints", []):
		if Routes.waypoint_room(wp) != active_room:
			continue
		var distance := pixel.distance_to(Routes._vector(wp["pointPx"]))
		if distance < max_distance:
			max_distance = distance
			best = str(wp["id"])
	return best


# This hit-test is the stable selection boundary for a future freehand tool:
# authoring still commits through RouteDocument.set_route_cells, never pixels.
func pick_route(pixel: Vector2) -> String:
	var best := ""
	var distance_limit := 11.0 / zoom
	for route in document.get("routes", []):
		if Routes.room_for_id(document, str(route["from"])) != active_room:
			continue
		var points: PackedVector2Array = Routes.route_points(route, document)
		for i in range(1, points.size()):
			var projected: Vector2 = Geometry2D.get_closest_point_to_segment(pixel, points[i - 1], points[i])
			var distance: float = pixel.distance_to(projected)
			if distance < distance_limit:
				distance_limit = distance
				best = str(route["id"])
	return best


# Native polygon hit-testing includes ALL source-provided QA regions. Select
# by polygon edge or interior, preferring NO-GO over the surrounding WALKABLE.
# Clicked points are always source-image pixels, regardless of zoom/pan.
func pick_zone(pixel: Vector2) -> Dictionary:
	var nearest: Dictionary = {}
	var best := 11.0 / zoom
	for group in ["noGoPolygons", "walkablePolygons"]:
		for region in document.get(group, []):
			var points: PackedVector2Array = Routes._polygon_points(region)
			for i in range(points.size()):
				var edge: Vector2 = Geometry2D.get_closest_point_to_segment(
					pixel, points[i], points[(i + 1) % points.size()])
				var distance: float = pixel.distance_to(edge)
				if distance < best:
					best = distance
					nearest = {"group": group, "id": str(region.get("id", ""))}
	if not nearest.is_empty():
		return nearest
	for group in ["noGoPolygons", "walkablePolygons"]:
		for region in document.get(group, []):
			if Geometry2D.is_point_in_polygon(pixel, Routes._polygon_points(region)):
				return {"group": group, "id": str(region.get("id", ""))}
	return {}


func _zone_vertex_at(pixel: Vector2, points: PackedVector2Array) -> int:
	for i in range(points.size()):
		if pixel.distance_to(points[i]) <= 12.0 / zoom:
			return i
	return -1


func _zone_edge_at(pixel: Vector2, points: PackedVector2Array) -> int:
	var index := -1
	var best := 13.0 / zoom
	for i in range(points.size()):
		var closest := Geometry2D.get_closest_point_to_segment(
			pixel, points[i], points[(i + 1) % points.size()])
		var distance := pixel.distance_to(closest)
		if distance < best:
			index = i
			best = distance
	return index


func _zone_mouse_press(pixel: Vector2) -> void:
	var points: PackedVector2Array = selected_zone_points()
	if zone_inserting:
		var edge_index := _zone_edge_at(pixel, points)
		if edge_index >= 0:
			zone_insert_requested.emit(edge_index, pixel)
		zone_inserting = false
		queue_redraw()
		return
	var handle := _zone_vertex_at(pixel, points)
	# When polygons overlap, select the region under the cursor rather than
	# accidentally moving the previously selected large WALKABLE floor.
	var hit: Dictionary = pick_zone(pixel)
	if handle < 0 and not hit.is_empty() and (
			str(hit["id"]) != selected_zone or str(hit["group"]) != selected_zone_group):
		zone_chosen.emit(str(hit["group"]), str(hit["id"]))
		return
	if handle >= 0:
		selected_zone_vertex = handle
		zone_vertex_chosen.emit(handle)
		_zone_drag_vertex = handle
	elif points.size() >= 3 and Geometry2D.is_point_in_polygon(pixel, points):
		_zone_drag_vertex = -1
	else:
		if not hit.is_empty():
			zone_chosen.emit(str(hit["group"]), str(hit["id"]))
		else:
			zone_chosen.emit("", "")
		return
	_zone_dragging = true
	_zone_drag_moved = false
	_zone_drag_start = pixel
	_zone_drag_base = points
	grab_focus()


func _zone_drag_motion(pixel: Vector2) -> void:
	if not _zone_dragging:
		return
	var delta: Vector2 = pixel - _zone_drag_start
	if delta.length() < 0.5 and not _zone_drag_moved:
		return
	_zone_drag_moved = true
	var points: PackedVector2Array = _zone_drag_base.duplicate()
	if _zone_drag_vertex >= 0:
		points[_zone_drag_vertex] += delta
	else:
		for i in range(points.size()):
			points[i] += delta
	zone_edit_preview = points
	zone_drag_changed.emit(points)
	queue_redraw()


func _zone_mouse_release(pixel: Vector2) -> void:
	if not _zone_dragging:
		return
	_zone_drag_motion(pixel)
	_zone_dragging = false
	if _zone_drag_moved:
		zone_drag_finished.emit(zone_edit_preview.duplicate())


func _gui_input(event: InputEvent) -> void:
	if document.is_empty() or image == null:
		return
	if mode == "Zones" and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_zone_dragging = false
		zone_inserting = false
		clear_zone_edit_preview()
		zone_cancelled.emit()
		accept_event()
		return
	if mode == "Freehand" and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		cancel_freehand()
		freehand_cancelled.emit()
		accept_event()
		return
	if event is InputEventMouseButton:
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN] and event.pressed:
			var factor := 1.15 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.15
			var image_before := screen_to_image(event.position)
			zoom = clampf(zoom * factor, 0.15, 4.0)
			image_origin = event.position - image_before * zoom
			queue_redraw()
			accept_event()
			return
		if event.button_index in [MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE] or (mode == "Pan" and event.button_index == MOUSE_BUTTON_LEFT):
			_pan_active = event.pressed
			_last_mouse = event.position
			accept_event()
			return
		if event.button_index == MOUSE_BUTTON_LEFT:
			if mode == "Zones" and not zone_creating:
				if event.pressed:
					_zone_mouse_press(screen_to_image(event.position))
				else:
					_zone_mouse_release(screen_to_image(event.position))
				accept_event()
				return
			if mode == "Freehand":
				if event.pressed:
					_freehand_active = true
					grab_focus()
					freehand_raw = PackedVector2Array([screen_to_image(event.position)])
					freehand_grid = PackedVector2Array()
					freehand_invalid = Vector2.INF
					freehand_started.emit()
					freehand_changed.emit(freehand_raw)
				elif _freehand_active:
					_freehand_active = false
					var ending: Vector2 = screen_to_image(event.position)
					if freehand_raw.size() == 1 or ending.distance_to(freehand_raw[freehand_raw.size() - 1]) >= 0.5:
						freehand_raw.append(ending)
					freehand_finished.emit(freehand_raw.duplicate())
				queue_redraw()
				accept_event()
				return
			if event.pressed:
				var pixel := screen_to_image(event.position)
				if not Routes._inside_art(pixel, document):
					return
				var cell := Routes.pixel_to_cell(pixel, document)
				selected_cell = cell
				cell_chosen.emit(cell)
				var hit := _pick_waypoint(pixel)
				if mode != "Add" or hit.is_empty():
					image_pixel_chosen.emit(pixel)
				if mode == "Add":
					if not hit.is_empty():
						waypoint_chosen.emit(hit)
				elif mode == "Obstacles":
					_painting = true
					_painted.clear()
					_paint_value = not document["blockedCells"].has(cell)
					_paint(cell)
				elif mode in ["Waypoints", "Connect", "Routes"]:
					if not hit.is_empty():
						waypoint_chosen.emit(hit)
					elif mode == "Routes":
						var route_id := pick_route(pixel)
						if not route_id.is_empty():
							route_chosen.emit(route_id)
					if mode == "Waypoints" and not hit.is_empty():
						_drag_point = hit
						_did_drag = false
						for waypoint in document.get("waypoints", []):
							if waypoint["id"] == hit:
								_drag_origin = Routes._vector(waypoint["pointPx"])
								break
						_drag_preview = _drag_origin
				queue_redraw()
			else:
				if not _drag_point.is_empty():
					if _did_drag:
						waypoint_dropped.emit(_drag_point, _drag_preview)
					_drag_point = ""
				_painting = false
				_painted.clear()
				queue_redraw()
			accept_event()
	elif event is InputEventMouseMotion:
		if mode == "Zones" and _zone_dragging:
			_zone_drag_motion(screen_to_image(event.position))
			accept_event()
			return
		if mode == "Freehand":
			freehand_cursor = screen_to_image(event.position)
			if _freehand_active and freehand_raw.size() < 20000:
				var pixel: Vector2 = freehand_cursor
				if pixel.distance_to(freehand_raw[freehand_raw.size() - 1]) >= 0.5:
					freehand_raw.append(pixel)
					freehand_changed.emit(freehand_raw.duplicate())
			queue_redraw()
		if _pan_active:
			image_origin += event.position - _last_mouse
			_last_mouse = event.position
			queue_redraw()
		elif not _drag_point.is_empty() and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			var pixel := screen_to_image(event.position)
			if Routes._inside_art(pixel, document):
				if pixel.distance_to(_drag_origin) > 3.0:
					_did_drag = true
				if _did_drag:
					_drag_preview = pixel
					queue_redraw()
		elif _painting and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			var cell := Routes.pixel_to_cell(screen_to_image(event.position), document)
			_paint(cell)
	elif event is InputEventMouseButton and not event.pressed:
		_pan_active = false


func _paint(cell: String) -> void:
	if cell.is_empty() or _painted.has(cell):
		return
	_painted[cell] = true
	obstacle_paint.emit(cell, _paint_value)
	queue_redraw()
