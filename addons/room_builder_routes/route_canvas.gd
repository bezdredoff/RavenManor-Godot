@tool
extends Control
## Native Room Builder Navigation / Routes canvas, image-pixel coordinates only.
const Routes = preload("res://addons/room_builder_routes/route_document.gd")
signal waypoint_chosen(id: String)
signal waypoint_dropped(id: String, point: Vector2)
signal image_pixel_chosen(point: Vector2)
signal cell_chosen(cell: String)
signal obstacle_paint(cell: String, blocked: bool)

var document: Dictionary = {}
var image: Texture2D
var mode := "Waypoints"
var selected_waypoint := ""
var selected_route := ""
var selected_cell := ""
var preview_points := PackedVector2Array()
var zoom := 0.75
var image_origin := Vector2(28, 28)
var _drag_point := ""
var _drag_preview := Vector2.ZERO
var _pan_active := false
var _last_mouse := Vector2.ZERO
var _painting := false
var _paint_value := true
var _painted: Dictionary = {}


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
	mode = value
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
	for polygon in document.get("walkablePolygons", []):
		_draw_region(polygon, Color(0.15, 0.90, 0.40, 0.13))
	for polygon in document.get("noGoPolygons", []):
		_draw_region(polygon, Color(0.95, 0.17, 0.20, 0.26))
	_draw_grid()
	var g: Dictionary = document["grid"]
	for cell in document.get("blockedCells", []):
		var centre := Routes.cell_to_pixel(str(cell), document)
		if not centre.is_finite():
			continue
		var w := float(g["cellWidth"]) * zoom
		var h := float(g["cellHeight"]) * zoom
		draw_rect(Rect2(image_to_screen(centre) - Vector2(w, h) * 0.5, Vector2(w, h)), Color(0.98, 0.28, 0.10, 0.55))
	for route in document.get("routes", []):
		var points := Routes.route_points(route, document)
		if points.size() < 2:
			continue
		var selected: bool = route["id"] == selected_route
		var color := Color("#fff18a") if selected else (Color("#e8a85a") if route["provisional"] else Color("#62d9f5"))
		var stroke := 3.5 if selected else 2.0
		for i in range(1, points.size()):
			# Provisional edges are visually distinct: no invented cell-by-cell detail.
			if route["provisional"]:
				_dashed(points[i - 1], points[i], color, stroke)
			else:
				draw_line(image_to_screen(points[i - 1]), image_to_screen(points[i]), color, stroke, true)
		if not bool(route["bidirectional"]):
			_draw_arrow(points[points.size() - 2], points[points.size() - 1], color)
	if preview_points.size() > 1:
		for i in range(1, preview_points.size()):
			draw_line(image_to_screen(preview_points[i - 1]), image_to_screen(preview_points[i]), Color("#bfff5b"), 5.0, true)
	for wp in document.get("waypoints", []):
		var id := str(wp["id"])
		var pixel := _drag_preview if id == _drag_point else Routes._vector(wp["pointPx"])
		var centre := image_to_screen(pixel)
		var selected := id == selected_waypoint
		draw_circle(centre, 9.0 if selected else 6.0, Color("#ffe78a") if selected else Color("#f1f1f6"))
		draw_arc(centre, 10.0 if selected else 7.0, 0.0, TAU, 24, Color("#2a2736"), 1.5)
		_draw_label(centre + Vector2(10, -12), str(wp["label"]), Color("#fff4d8"))
	if not selected_cell.is_empty():
		var centre := Routes.cell_to_pixel(selected_cell, document)
		if centre.is_finite():
			var w := float(g["cellWidth"]) * zoom
			var h := float(g["cellHeight"]) * zoom
			draw_rect(Rect2(image_to_screen(centre) - Vector2(w, h) * 0.5, Vector2(w, h)), Color("#fff89a"), false, 2.5)


func _draw_region(region: Dictionary, color: Color) -> void:
	var points := PackedVector2Array()
	for pair in region.get("pointsPx", []):
		points.append(image_to_screen(Routes._vector(pair)))
	if points.size() >= 3:
		draw_colored_polygon(points, color)


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
		var distance := pixel.distance_to(Routes._vector(wp["pointPx"]))
		if distance < max_distance:
			max_distance = distance
			best = str(wp["id"])
	return best


func _gui_input(event: InputEvent) -> void:
	if document.is_empty() or image == null:
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
			if event.pressed:
				var pixel := screen_to_image(event.position)
				if not Routes._inside_art(pixel, document):
					return
				var cell := Routes.pixel_to_cell(pixel, document)
				selected_cell = cell
				cell_chosen.emit(cell)
				image_pixel_chosen.emit(pixel)
				if mode == "Obstacles":
					_painting = true
					_painted.clear()
					_paint_value = not document["blockedCells"].has(cell)
					_paint(cell)
				elif mode in ["Waypoints", "Routes"]:
					var hit := _pick_waypoint(pixel)
					waypoint_chosen.emit(hit)
					if mode == "Waypoints" and not hit.is_empty():
						_drag_point = hit
						_drag_preview = pixel
				queue_redraw()
			else:
				if not _drag_point.is_empty():
					waypoint_dropped.emit(_drag_point, _drag_preview)
					_drag_point = ""
				_painting = false
				_painted.clear()
				queue_redraw()
			accept_event()
	elif event is InputEventMouseMotion:
		if _pan_active:
			image_origin += event.position - _last_mouse
			_last_mouse = event.position
			queue_redraw()
		elif not _drag_point.is_empty() and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			var pixel := screen_to_image(event.position)
			if Routes._inside_art(pixel, document):
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
