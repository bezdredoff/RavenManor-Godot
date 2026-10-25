extends Control
## RM-MAP-S1 continuous-map feasibility. Uniform shallow projected floor, NOT canonical room art.
## Onoe assets are owner-created test placeholders, not Evelyn.
const DATA = preload("res://data/raven/season1_world_map.json")
const Store = preload("res://scripts/raven/raven_campaign_store.gd")
const ONOE_WALK = preload("res://assets/prototypes/onoe/onoe_walk_sheet_v1.png")
const ONOE_SIDE = preload("res://assets/prototypes/onoe/onoe_side_walk_v2.png")
const HALL_SHELL = preload("res://assets/prototypes/map_calibration/hall_shell.svg")
const HALL_RUG = preload("res://assets/prototypes/map_calibration/hall_rug.svg")
const HALL_CLOCK = preload("res://assets/prototypes/map_calibration/grandfather_clock.svg")
const HALL_SEATS = preload("res://assets/prototypes/map_calibration/seating_cluster.svg")
const HALL_CONSOLE = preload("res://assets/prototypes/map_calibration/console.svg")
const HALL_GALLERY = preload("res://assets/prototypes/map_calibration/ancestor_gallery.svg")
const CAMERA_ANGLES := [45, 55, 65]
const CELL := 25
const WALL_MARGIN := 28.0
const DOOR_RADIUS := 70.0
const FURNITURE_MARGIN := 21.0
const DEFAULT_CAMERA_ELEVATION := 55
const TRAVEL_SPEED := 375.0
const TOP_UI_HEIGHT := 137.0
const BOTTOM_UI_HEIGHT := 110.0

var rooms: Array
var doors: Array
var props: Array
var world_size := Vector2(2150, 2250)
var center := Vector2(930, 620)
var zoom := 0.47
var camera_elevation := DEFAULT_CAMERA_ELEVATION
var floor_depth_ratio := sin(deg_to_rad(float(DEFAULT_CAMERA_ELEVATION)))
var art_enabled := true
var debug_art_bounds := false
var dragging := false
var drag_distance := 0.0
var actor_pos := Vector2(990, 640)
var movement_points: Array[Vector2] = []
var selected_prop: Dictionary = {}
var repaired_in_preview := {}
var explore_all := true
var follow_actor := false
var grid := AStarGrid2D.new()
var actor_sprite: AnimatedSprite2D
var snapshot: Dictionary
var status_label: Label
var selected_label: Label
var action_button: Button
var repair_button: Button
var toggle_button: Button
var camera_button: Button
var art_button: Button
var bounds_button: Button

func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP
	rooms = DATA.data.rooms
	doors = DATA.data.doors
	props = DATA.data.props
	snapshot = Store.new().load_campaign()
	_make_ui()
	_make_onoe()
	_rebuild_navigation()
	_update_actor_screen()
	queue_redraw()

func _make_ui() -> void:
	var header := ColorRect.new()
	header.color = Color("151b22")
	header.set_anchors_and_offsets_preset(PRESET_TOP_WIDE)
	header.offset_bottom = TOP_UI_HEIGHT
	header.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(header)
	var title := _label("RAVEN MANOR · S1 MAP + ONOE", 17)
	title.position = Vector2(12, 7); title.size = Vector2(365, 24); add_child(title)
	var help := _label("Свайп — карта · предмет — маршрут · −/+ — масштаб", 11)
	help.position = Vector2(12, 33); help.size = Vector2(365, 24); add_child(help)
	toggle_button = _button("ТЕСТ: ВСЕ ПРОХОДЫ", Vector2(8, 64), Vector2(165, 32), _toggle_explore)
	_button("К персонажу", Vector2(181, 64), Vector2(92, 32), _recenter)
	_button("−", Vector2(283, 64), Vector2(41, 32), _zoom_out)
	_button("+", Vector2(330, 64), Vector2(41, 32), _zoom_in)
	camera_button = _button("Камера: 55°", Vector2(8, 101), Vector2(122, 31), _cycle_camera)
	art_button = _button("Арт: ВКЛ", Vector2(135, 101), Vector2(111, 31), _toggle_art)
	bounds_button = _button("Габариты: СКР", Vector2(250, 101), Vector2(121, 31), _toggle_bounds)
	var footer := ColorRect.new()
	footer.color = Color("151b22")
	footer.anchor_top = 1.0; footer.anchor_bottom = 1.0
	footer.offset_top = -BOTTOM_UI_HEIGHT; footer.offset_bottom = 0
	footer.anchor_right = 1.0; footer.mouse_filter = MOUSE_FILTER_IGNORE; add_child(footer)
	selected_label = _label("Выбери крупную мебель или ремонтный объект", 12)
	selected_label.anchor_top = 1.0; selected_label.anchor_bottom = 1.0
	selected_label.position = Vector2(10, -106); selected_label.size = Vector2(365, 28); add_child(selected_label)
	status_label = _label("Оноэ — технический placeholder; путь только по свободному полу", 11)
	status_label.anchor_top = 1.0; status_label.anchor_bottom = 1.0
	status_label.position = Vector2(10, -75); status_label.size = Vector2(365, 29); add_child(status_label)
	action_button = _button("MATCH-3", Vector2(10, 0), Vector2(116, 36), _open_preview)
	action_button.anchor_top = 1.0; action_button.anchor_bottom = 1.0
	action_button.position.y = -43; action_button.disabled = true
	repair_button = _button("До / После", Vector2(135, 0), Vector2(112, 36), _toggle_repair)
	repair_button.anchor_top = 1.0; repair_button.anchor_bottom = 1.0
	repair_button.position.y = -43; repair_button.disabled = true
	var back := _button("← Меню", Vector2(256, 0), Vector2(116, 36),
		func(): get_tree().change_scene_to_file("res://scenes/raven/prototype_launcher.tscn"))
	back.anchor_top = 1.0; back.anchor_bottom = 1.0; back.position.y = -43

func _label(t: String, font_size: int) -> Label:
	var l := Label.new(); l.text = t
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", Color("efe4cf"))
	l.mouse_filter = MOUSE_FILTER_IGNORE
	return l

func _button(t: String, pos: Vector2, dims: Vector2, callback: Callable) -> Button:
	var b := Button.new()
	b.text = t; b.position = pos; b.size = dims
	b.pressed.connect(callback); add_child(b)
	return b

func _make_onoe() -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for clip in [["down", 0], ["up", 3]]:
		frames.add_animation(clip[0])
		frames.set_animation_speed(clip[0], 7)
		frames.set_animation_loop(clip[0], true)
		for column in 4:
			var atlas := AtlasTexture.new()
			atlas.atlas = ONOE_WALK
			atlas.region = Rect2(column * 256, int(clip[1]) * 384, 256, 384)
			frames.add_frame(clip[0], atlas)
	frames.add_animation("side")
	frames.set_animation_speed("side", 10)
	frames.set_animation_loop("side", true)
	for column in 8:
		var side_atlas := AtlasTexture.new()
		side_atlas.atlas = ONOE_SIDE
		side_atlas.region = Rect2(column * 272, 0, 272, 724)
		frames.add_frame("side", side_atlas)
	actor_sprite = AnimatedSprite2D.new()
	actor_sprite.sprite_frames = frames
	actor_sprite.animation = "down"
	actor_sprite.stop()
	actor_sprite.frame = 0
	actor_sprite.z_index = 20
	add_child(actor_sprite)

func _update_actor_screen() -> void:
	if not is_instance_valid(actor_sprite):
		return
	var side := actor_sprite.animation == "side"
	var native_height := 724.0 if side else 384.0
	var scale_factor := (0.15 if side else 0.28) * zoom
	actor_sprite.scale = Vector2.ONE * scale_factor
	actor_sprite.position = _screen_from_world(actor_pos) - Vector2(0, native_height * scale_factor * 0.5)
	var screen_y := actor_sprite.position.y
	actor_sprite.visible = screen_y > TOP_UI_HEIGHT - 48.0 and screen_y < size.y - BOTTOM_UI_HEIGHT + 25.0

func _set_actor_motion(delta: Vector2) -> void:
	if delta.length_squared() < 0.01:
		return
	var clip := "side" if absf(delta.x) > absf(delta.y) else ("down" if delta.y >= 0 else "up")
	if actor_sprite.animation != clip:
		actor_sprite.animation = clip
	actor_sprite.flip_h = clip == "side" and delta.x < 0
	if not actor_sprite.is_playing():
		actor_sprite.play()

func _zoom_in() -> void:
	_set_zoom(zoom * 1.17)

func _zoom_out() -> void:
	_set_zoom(zoom / 1.17)

func _set_zoom(value: float) -> void:
	zoom = clampf(value, 0.20, 0.90)
	queue_redraw()
	_update_actor_screen()

func _toggle_explore() -> void:
	explore_all = not explore_all
	toggle_button.text = "ТЕСТ: ВСЕ ПРОХОДЫ" if explore_all else "СЮЖЕТНЫЕ GATE"
	movement_points.clear()
	if is_instance_valid(actor_sprite):
		actor_sprite.stop(); actor_sprite.frame = 0
	_rebuild_navigation()
	status_label.text = "Проверка геометрии: сюжетные двери открыты" if explore_all else "Двери ограничены сохранённым прогрессом"
	queue_redraw()

func _cycle_camera() -> void:
	var current_index := CAMERA_ANGLES.find(camera_elevation)
	camera_elevation = CAMERA_ANGLES[(current_index + 1) % CAMERA_ANGLES.size()]
	floor_depth_ratio = sin(deg_to_rad(float(camera_elevation)))
	camera_button.text = "Камера: %d°" % camera_elevation
	status_label.text = "Угол: %d° вниз от горизонтали · глубина пола × %.3f" % [camera_elevation, floor_depth_ratio]
	_update_actor_screen()
	queue_redraw()


func _toggle_art() -> void:
	art_enabled = not art_enabled
	art_button.text = "Арт: ВКЛ" if art_enabled else "Арт: ВЫКЛ"
	queue_redraw()


func _toggle_bounds() -> void:
	debug_art_bounds = not debug_art_bounds
	bounds_button.text = "Габариты: ВИД" if debug_art_bounds else "Габариты: СКР"
	queue_redraw()


func _recenter() -> void:
	center = actor_pos
	follow_actor = true
	queue_redraw()
	_update_actor_screen()

func _open_preview() -> void:
	if not str(selected_prop.get("level", "")).is_empty():
		get_tree().set_meta("raven_map_preview_level", str(selected_prop.level))
		get_tree().change_scene_to_file("res://scenes/raven/content_preview.tscn")

func _toggle_repair() -> void:
	var id := str(selected_prop.get("id", ""))
	if id.is_empty(): return
	repaired_in_preview[id] = not bool(repaired_in_preview.get(id, false))
	status_label.text = "Визуальный тест: " + ("после ремонта" if repaired_in_preview[id] else "до ремонта") + " (Raven-save не меняется)"
	queue_redraw()

func _room_rect(room: Dictionary) -> Rect2:
	var a: Array = room.rect
	return Rect2(float(a[0]), float(a[1]), float(a[2]), float(a[3]))

func _prop_rect(prop: Dictionary) -> Rect2:
	var a: Array = prop.rect
	return Rect2(float(a[0]), float(a[1]), float(a[2]), float(a[3]))

func _room_at(p: Vector2) -> int:
	for i in range(rooms.size()):
		if _room_rect(rooms[i]).has_point(p): return i
	return -1

func _door_enabled(d: Dictionary) -> bool:
	if str(d.status) == "future": return false
	if explore_all: return true
	return str(d.status) == "open" or snapshot.get("unlockedDoors", []).has(str(d.id))

func _near_valid_door(p: Vector2, room_index: int) -> bool:
	for d in doors:
		if not _door_enabled(d):
			continue
		if int(d.a) != room_index and int(d.b) != room_index:
			continue
		var dp := Vector2(float(d.point[0]), float(d.point[1]))
		if dp.distance_to(p) <= DOOR_RADIUS:
			return true
	return false

func _is_walkable(p: Vector2) -> bool:
	var index := _room_at(p)
	if index == -1:
		return false
	var r := _room_rect(rooms[index])
	var on_wall := p.x < r.position.x + WALL_MARGIN or p.x > r.end.x - WALL_MARGIN
	on_wall = on_wall or p.y < r.position.y + WALL_MARGIN or p.y > r.end.y - WALL_MARGIN
	if on_wall and not _near_valid_door(p, index):
		return false
	for prop in props:
		if int(prop.room) == index and _prop_rect(prop).grow(FURNITURE_MARGIN).has_point(p):
			return false
	return true

func _rebuild_navigation() -> void:
	grid.region = Rect2i(Vector2i.ZERO, Vector2i(ceili(DATA.data.worldSize[0] / CELL), ceili(DATA.data.worldSize[1] / CELL)))
	grid.cell_size = Vector2(CELL, CELL)
	grid.offset = Vector2(CELL * 0.5, CELL * 0.5)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	grid.update()
	for y in range(grid.region.size.y):
		for x in range(grid.region.size.x):
			var cell := Vector2i(x, y)
			if not _is_walkable(grid.get_point_position(cell)):
				grid.set_point_solid(cell)
	queue_redraw()

func _nearest_open_cell(pos: Vector2, room_index: int) -> Vector2i:
	var source := Vector2i(floori(pos.x / CELL), floori(pos.y / CELL))
	var candidate := Vector2i(-1, -1)
	var best_distance := INF
	for radius in range(0, 13):
		for dy in range(-radius, radius + 1):
			for dx in range(-radius, radius + 1):
				if radius > 0 and maxi(absi(dx), absi(dy)) != radius:
					continue
				var cell := source + Vector2i(dx, dy)
				if cell.x < 0 or cell.y < 0 or cell.x >= grid.region.size.x or cell.y >= grid.region.size.y:
					continue
				if grid.is_point_solid(cell):
					continue
				var point := grid.get_point_position(cell)
				if _room_at(point) != room_index:
					continue
				var dist := pos.distance_squared_to(point)
				if dist < best_distance:
					best_distance = dist
					candidate = cell
		if candidate.x >= 0:
			return candidate
	return candidate

func _path_between(start: Vector2, destination: Vector2, dest_room: int) -> PackedVector2Array:
	var from_room := _room_at(start)
	if from_room < 0 or dest_room < 0 or dest_room >= rooms.size():
		return PackedVector2Array()
	var a := _nearest_open_cell(start, from_room)
	var b := _nearest_open_cell(destination, dest_room)
	if a.x < 0 or b.x < 0:
		return PackedVector2Array()
	return grid.get_point_path(a, b)

func _route_to(destination: Vector2, room_index: int) -> bool:
	var path := _path_between(actor_pos, destination, room_index)
	if path.is_empty():
		status_label.text = "Путь недоступен: стена, мебель или закрытая дверь"
		return false
	movement_points.clear()
	for point in path:
		# Grid is orthogonal; removing only points from a collinear run preserves obstacle clearance.
		if movement_points.size() >= 2:
			var last := movement_points[movement_points.size() - 1]
			var previous := movement_points[movement_points.size() - 2]
			var previous_dir := last - previous
			var next_dir := point - last
			if absf(previous_dir.cross(next_dir)) < 0.1 and previous_dir.dot(next_dir) > 0:
				movement_points.pop_back()
		movement_points.append(point)
	follow_actor = true
	status_label.text = "Ортогональный маршрут · %d поворотов" % maxi(0, movement_points.size() - 1)
	queue_redraw()
	return true

func _process(delta: float) -> void:
	if not movement_points.is_empty():
		var next: Vector2 = movement_points.front()
		_set_actor_motion(next - actor_pos)
		actor_pos = actor_pos.move_toward(next, TRAVEL_SPEED * delta)
		if actor_pos.distance_to(next) < 0.8:
			movement_points.pop_front()
		if movement_points.is_empty():
			actor_sprite.stop()
			actor_sprite.frame = 0
		if follow_actor: center = actor_pos
		queue_redraw()
	_update_actor_screen()

func _screen_from_world(p: Vector2) -> Vector2:
	var viewport_mid := Vector2(size.x * 0.5, (TOP_UI_HEIGHT + size.y - BOTTOM_UI_HEIGHT) * 0.5)
	return viewport_mid + Vector2((p.x - center.x) * zoom, (p.y - center.y) * zoom * floor_depth_ratio)

func _from_screen(p: Vector2) -> Vector2:
	var viewport_mid := Vector2(size.x * 0.5, (TOP_UI_HEIGHT + size.y - BOTTOM_UI_HEIGHT) * 0.5)
	return center + Vector2((p.x - viewport_mid.x) / zoom, (p.y - viewport_mid.y) / (zoom * floor_depth_ratio))

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_zoom_in(); accept_event()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_zoom_out(); accept_event()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				dragging = true; drag_distance = 0.0
			else:
				if dragging and drag_distance < 12.0:
					_select_at(_from_screen(event.position))
				dragging = false
			accept_event()
	elif event is InputEventMouseMotion and dragging:
		center -= Vector2(event.relative.x / zoom, event.relative.y / (zoom * floor_depth_ratio))
		drag_distance += event.relative.length()
		follow_actor = false; queue_redraw(); accept_event()
	elif event is InputEventScreenTouch:
		if event.pressed:
			dragging = true; drag_distance = 0.0
		else:
			if dragging and drag_distance < 12.0:
				_select_at(_from_screen(event.position))
			dragging = false
		accept_event()
	elif event is InputEventScreenDrag:
		center -= Vector2(event.relative.x / zoom, event.relative.y / (zoom * floor_depth_ratio))
		drag_distance += event.relative.length()
		follow_actor = false; queue_redraw(); accept_event()

func _select_at(p: Vector2) -> void:
	for item in props:
		var box := _prop_rect(item)
		if box.grow(18).has_point(p):
			selected_prop = item
			selected_label.text = str(item.title) + (" · " + str(item.restoration) if not str(item.restoration).is_empty() else "")
			action_button.disabled = str(item.level).is_empty()
			repair_button.disabled = str(item.restoration).is_empty()
			var dest := box.position + Vector2(box.size.x * 0.5, box.size.y + 70.0)
			if item.has("approach"):
				dest = Vector2(float(item.approach[0]), float(item.approach[1]))
			if not _route_to(dest, int(item.room)):
				action_button.disabled = true
				repair_button.disabled = true
			return
	for d in doors:
		var dp := Vector2(float(d.point[0]), float(d.point[1]))
		if dp.distance_to(p) < 82:
			selected_prop = {}
			selected_label.text = str(d.id)
			action_button.disabled = true
			repair_button.disabled = true
			if _door_enabled(d) and int(d.b) >= 0:
				_route_to(_room_rect(rooms[int(d.b)]).get_center(), int(d.b))
			else:
				status_label.text = "Закрытая зона или сюжетный gate"
			queue_redraw()
			return

func _pilot_texture(asset_id: String) -> Texture2D:
	match asset_id:
		"RM-ASSET-HALL-CLOCK": return HALL_CLOCK
		"RM-ASSET-HALL-SEATS": return HALL_SEATS
		"RM-ASSET-HALL-CONSOLE": return HALL_CONSOLE
		"RM-ASSET-HALL-GALLERY": return HALL_GALLERY
	return null


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("111821"))
	var viewport_mid := Vector2(size.x * 0.5, (TOP_UI_HEIGHT + size.y - BOTTOM_UI_HEIGHT) * 0.5)
	var offset := viewport_mid - Vector2(center.x * zoom, center.y * zoom * floor_depth_ratio)
	draw_set_transform(offset, 0.0, Vector2(zoom, zoom * floor_depth_ratio))
	var f := ThemeDB.fallback_font
	for room in rooms:
		var r := _room_rect(room)
		draw_rect(r, Color(str(room.color)))
		if art_enabled and str(room.id) == "RM-ROOM-HALL":
			draw_texture_rect(HALL_SHELL, r, false)
			draw_texture_rect(HALL_RUG, Rect2(785, 435, 130, 396), false)
		else:
			var upper_wall := PackedVector2Array([
				r.position + Vector2(0, 0),
				r.position + Vector2(0, -54),
				r.position + Vector2(r.size.x, -54),
				r.position + Vector2(r.size.x, 0)])
			draw_colored_polygon(upper_wall, Color("67584c"))
		draw_rect(r, Color("493b34"), false, 12.0)
		if not art_enabled or str(room.id) != "RM-ROOM-HALL":
			draw_string(f, r.position + Vector2(25, 38), str(room.title),
				HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("262026"))
	for d in doors:
		var dp := Vector2(float(d.point[0]), float(d.point[1]))
		var hall_entrance := int(d.a) == 1 or int(d.b) == 1
		if art_enabled and hall_entrance:
			draw_circle(dp, 13, Color("63b8a0") if _door_enabled(d) else Color("a7545e"))
		else:
			draw_rect(Rect2(dp - Vector2(35, 35), Vector2(70, 70)),
				Color("63b8a0") if _door_enabled(d) else Color("a7545e"))
	for item in props:
		var r := _prop_rect(item)
		var chosen := str(item.id) == str(selected_prop.get("id", ""))
		var restored := bool(repaired_in_preview.get(str(item.id), false))
		var texture := _pilot_texture(str(item.id)) if art_enabled else null
		var embedded_in_shell := art_enabled and str(item.id) in ["RM-ASSET-HALL-STAIRS-L", "RM-ASSET-HALL-STAIRS-R"]
		if texture != null:
			draw_texture_rect(texture, r, false)
			if restored:
				draw_rect(r, Color(0.22, 0.7, 0.49, 0.28))
		elif not embedded_in_shell:
			var fill := Color("79b894") if restored else (Color("d7b16c") if chosen else Color("65524b"))
			draw_rect(r, fill)
			if not art_enabled or int(item.room) != 1:
				draw_string(f, r.position + Vector2(6, maxf(25, r.size.y * 0.5)), str(item.title),
					HORIZONTAL_ALIGNMENT_LEFT, int(r.size.x) - 12, 15, Color.WHITE)
		if debug_art_bounds or chosen:
			draw_rect(r, Color("f6d888") if chosen else Color("cf9e86"), false, 3.0)
	if not movement_points.is_empty():
		var last := actor_pos
		for waypoint in movement_points:
			draw_line(last, waypoint, Color("78cbea"), 5.0)
			last = waypoint
	draw_circle(actor_pos, 16, Color(0.2, 0.15, 0.22, 0.48))
	draw_set_transform(Vector2.ZERO)
