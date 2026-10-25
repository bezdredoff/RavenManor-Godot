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
# Unretouched generator PNGs: experimental, non-spatially-locked art.
const AI_HALL_TWIN = preload("res://assets/raven/hall/generated_pilot/backgrounds/hall_twin_staircases.png")
const AI_HALL_CRIMSON = preload("res://assets/raven/hall/generated_pilot/backgrounds/hall_crimson_stairways.png")
const AI_CLOCK = preload("res://assets/raven/hall/generated_pilot/props/grandfather_clock.png")
const AI_CHAIR = preload("res://assets/raven/hall/generated_pilot/props/armchair_clean.png")
const AI_SIDE_TABLE = preload("res://assets/raven/hall/generated_pilot/props/round_side_table.png")
const AI_RUG = preload("res://assets/raven/hall/generated_pilot/props/burgundy_runner.png")
const AI_CONSOLE = preload("res://assets/raven/hall/generated_pilot/props/entry_console.png")
const AI_GALLERY = preload("res://assets/raven/hall/generated_pilot/props/ancestor_gallery_composite.png")
const CAMERA_ANGLES := [45, 55, 65]
const CELL := 25
const WALL_MARGIN := 28.0
const DOOR_RADIUS := 70.0
const FURNITURE_MARGIN := 21.0
const DEFAULT_CAMERA_ELEVATION := 65
const DEFAULT_HUB_ZOOM := 0.74
const ZOOM_PRESETS := [0.68, 0.74, 0.80]
const ACTOR_WORLD_HEIGHT := 90.0
const TRAVEL_SPEED := 375.0
const TOP_UI_HEIGHT := 86.0
const BOTTOM_UI_HEIGHT := 90.0

var rooms: Array
var doors: Array
var props: Array
var world_size := Vector2(2150, 2250)
var center := Vector2(750, 510)
var zoom := DEFAULT_HUB_ZOOM
var camera_elevation := DEFAULT_CAMERA_ELEVATION
var floor_depth_ratio := sin(deg_to_rad(float(DEFAULT_CAMERA_ELEVATION)))
var art_enabled := true
# 0: original SVG, 1: generated twin staircase, 2: generated crimson version, 3: bounds-only greybox
var art_variant := 1
var debug_art_bounds := false
var dragging := false
var drag_distance := 0.0
var actor_pos := Vector2(875, 635)
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
var zoom_preset_button: Button
var recenter_button: Button
var zoom_minus_button: Button
var zoom_plus_button: Button
var debug_toggle_button: Button
var safe_button: Button
var overview_button: Button
var back_button: Button
var title_label: Label
var angle_label: Label
var debug_panel: Panel
var show_safe_viewport := false

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
	# Full-screen world, compact translucent HUD. Technical controls are collapsed by default.
	var header := ColorRect.new()
	header.color = Color(0.065, 0.085, 0.12, 0.87)
	header.set_anchors_and_offsets_preset(PRESET_TOP_WIDE)
	header.offset_bottom = TOP_UI_HEIGHT
	header.mouse_filter = MOUSE_FILTER_IGNORE
	header.z_index = 10
	add_child(header)
	var footer := ColorRect.new()
	footer.color = Color(0.065, 0.085, 0.12, 0.89)
	footer.anchor_top = 1.0
	footer.anchor_bottom = 1.0
	footer.offset_top = -BOTTOM_UI_HEIGHT
	footer.offset_bottom = 0
	footer.anchor_right = 1.0
	footer.mouse_filter = MOUSE_FILTER_IGNORE
	footer.z_index = 10
	add_child(footer)
	title_label = _label("RAVEN MANOR · HUB", 17)
	title_label.z_index = 11
	add_child(title_label)
	angle_label = _label("65° · ART TEST", 12)
	angle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	angle_label.z_index = 11
	add_child(angle_label)
	zoom_minus_button = _button("−", Vector2.ZERO, Vector2(42, 36), _zoom_out)
	zoom_preset_button = _button("0.74×", Vector2.ZERO, Vector2(80, 36), _cycle_zoom_preset)
	zoom_plus_button = _button("+", Vector2.ZERO, Vector2(42, 36), _zoom_in)
	recenter_button = _button("К персонажу", Vector2.ZERO, Vector2(100, 36), _recenter)
	debug_toggle_button = _button("Настр.", Vector2.ZERO, Vector2(76, 36), _toggle_debug)
	selected_label = _label("Выбери предмет ремонта на карте", 12)
	selected_label.z_index = 11
	add_child(selected_label)
	status_label = _label("Оноэ — технический персонаж · масштаб хаба 0.74×", 11)
	status_label.z_index = 11
	add_child(status_label)
	action_button = _button("MATCH-3", Vector2.ZERO, Vector2(108, 35), _open_preview)
	action_button.disabled = true
	repair_button = _button("До / После", Vector2.ZERO, Vector2(108, 35), _toggle_repair)
	repair_button.disabled = true
	back_button = _button("← Меню", Vector2.ZERO, Vector2(108, 35),
		func(): get_tree().change_scene_to_file("res://scenes/raven/prototype_launcher.tscn"))
	debug_panel = Panel.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.13, 0.17, 0.96)
	style.border_color = Color("776f60")
	style.set_border_width_all(1)
	style.set_corner_radius_all(9)
	debug_panel.add_theme_stylebox_override("panel", style)
	debug_panel.mouse_filter = MOUSE_FILTER_STOP
	debug_panel.z_index = 14
	add_child(debug_panel)
	toggle_button = _button("ТЕСТ: ВСЕ ПРОХОДЫ", Vector2.ZERO, Vector2(150, 36), _toggle_explore, debug_panel)
	camera_button = _button("Камера: 65°", Vector2.ZERO, Vector2(110, 36), _cycle_camera, debug_panel)
	art_button = _button("Вид: AI1", Vector2.ZERO, Vector2(88, 36), _toggle_art, debug_panel)
	bounds_button = _button("Габариты: СКР", Vector2.ZERO, Vector2(110, 36), _toggle_bounds, debug_panel)
	safe_button = _button("Safe area: ВЫКЛ", Vector2.ZERO, Vector2(110, 36), _toggle_safe_viewport, debug_panel)
	overview_button = _button("Обзор этажа", Vector2.ZERO, Vector2(110, 36), _overview, debug_panel)
	debug_panel.visible = false
	resized.connect(_layout_hud)
	_layout_hud()


func _layout_hud() -> void:
	if not is_instance_valid(zoom_minus_button):
		return
	var margin := 8.0
	var usable_width := maxf(240.0, size.x - 2.0 * margin)
	title_label.position = Vector2(margin + 3.0, 7.0)
	title_label.size = Vector2(maxf(130.0, size.x - 158.0), 28.0)
	angle_label.position = Vector2(size.x - 150.0, 12.0)
	angle_label.size = Vector2(140.0, 24.0)
	var gap := 6.0
	var small_width := 42.0
	var remaining := usable_width - 2.0 * small_width - 4.0 * gap
	var recenter_width := clampf(remaining * 0.40, 78.0, 106.0)
	var debug_width := clampf(remaining * 0.28, 66.0, 82.0)
	var preset_width := remaining - recenter_width - debug_width
	var x := margin
	for button in [zoom_minus_button, zoom_preset_button, zoom_plus_button, recenter_button, debug_toggle_button]:
		var button_width := small_width
		if button == zoom_preset_button:
			button_width = preset_width
		elif button == recenter_button:
			button_width = recenter_width
		elif button == debug_toggle_button:
			button_width = debug_width
		button.position = Vector2(x, 43.0)
		button.size = Vector2(button_width, 36.0)
		x += button_width + gap
	var foot := size.y - BOTTOM_UI_HEIGHT
	selected_label.position = Vector2(margin + 2.0, foot + 4.0)
	selected_label.size = Vector2(usable_width - 4.0, 22.0)
	status_label.position = Vector2(margin + 2.0, foot + 27.0)
	status_label.size = Vector2(usable_width - 4.0, 19.0)
	var footer_space := usable_width - 2.0 * gap
	var match_width := floorf(footer_space * 0.34)
	var repair_width := floorf(footer_space * 0.33)
	action_button.position = Vector2(margin, size.y - 39.0)
	action_button.size = Vector2(match_width, 35.0)
	repair_button.position = Vector2(margin + match_width + gap, size.y - 39.0)
	repair_button.size = Vector2(repair_width, 35.0)
	back_button.position = Vector2(margin + match_width + repair_width + 2.0 * gap, size.y - 39.0)
	back_button.size = Vector2(footer_space - match_width - repair_width, 35.0)
	debug_panel.position = Vector2(margin, TOP_UI_HEIGHT + 5.0)
	debug_panel.size = Vector2(usable_width, 102.0)
	var panel_row_width := debug_panel.size.x - 18.0 - 2.0 * gap
	toggle_button.position = Vector2(9, 9)
	toggle_button.size = Vector2(panel_row_width * 0.50, 36)
	art_button.position = Vector2(9 + panel_row_width * 0.50 + gap, 9)
	art_button.size = Vector2(panel_row_width * 0.24, 36)
	bounds_button.position = Vector2(9 + panel_row_width * 0.74 + 2.0 * gap, 9)
	bounds_button.size = Vector2(panel_row_width * 0.26, 36)
	camera_button.position = Vector2(9, 53)
	camera_button.size = Vector2(panel_row_width * 0.33, 36)
	safe_button.position = Vector2(9 + panel_row_width * 0.33 + gap, 53)
	safe_button.size = Vector2(panel_row_width * 0.37, 36)
	overview_button.position = Vector2(9 + panel_row_width * 0.70 + 2.0 * gap, 53)
	overview_button.size = Vector2(panel_row_width * 0.30, 36)
	queue_redraw()


func _safe_viewport_rect(for_size: Vector2) -> Rect2:
	return Rect2(Vector2(8, TOP_UI_HEIGHT + 4.0),
		Vector2(maxf(1, for_size.x - 16.0),
			maxf(1, for_size.y - TOP_UI_HEIGHT - BOTTOM_UI_HEIGHT - 8.0)))


func _viewport_midpoint(for_size: Vector2) -> Vector2:
	return _safe_viewport_rect(for_size).get_center()


func _toggle_debug() -> void:
	debug_panel.visible = not debug_panel.visible
	debug_toggle_button.text = "Скрыть" if debug_panel.visible else "Настр."


func _toggle_safe_viewport() -> void:
	show_safe_viewport = not show_safe_viewport
	safe_button.text = "Safe area: ВКЛ" if show_safe_viewport else "Safe area: ВЫКЛ"
	queue_redraw()


func _overview() -> void:
	center = Vector2(1080, 1120)
	follow_actor = false
	_set_zoom(0.17)
	debug_panel.visible = false
	debug_toggle_button.text = "Настр."


func _cycle_zoom_preset() -> void:
	var closest := 0
	var closest_delta := INF
	for i in range(ZOOM_PRESETS.size()):
		var delta := absf(zoom - float(ZOOM_PRESETS[i]))
		if delta < closest_delta:
			closest = i
			closest_delta = delta
	_set_zoom(float(ZOOM_PRESETS[(closest + 1) % ZOOM_PRESETS.size()]))
	status_label.text = "Масштаб %.2f× · 65° — основной ракурс" % zoom


func _label(t: String, font_size: int) -> Label:
	var l := Label.new(); l.text = t
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", Color("efe4cf"))
	l.mouse_filter = MOUSE_FILTER_IGNORE
	return l

func _button(t: String, pos: Vector2, dims: Vector2, callback: Callable, target_parent: Control = null) -> Button:
	var button := Button.new()
	button.text = t
	button.position = pos
	button.size = dims
	button.z_index = 15
	button.pressed.connect(callback)
	if target_parent == null:
		add_child(button)
	else:
		target_parent.add_child(button)
	return button


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
	actor_sprite.z_index = 5
	add_child(actor_sprite)

func _update_actor_screen() -> void:
	if not is_instance_valid(actor_sprite):
		return
	var side := actor_sprite.animation == "side"
	var native_height := 724.0 if side else 384.0
	var scale_factor := ACTOR_WORLD_HEIGHT * zoom / native_height
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
	zoom = clampf(value, 0.15, 1.20)
	if is_instance_valid(zoom_preset_button): zoom_preset_button.text = "%.2f×" % zoom
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
	angle_label.text = "%d° · ART TEST" % camera_elevation
	status_label.text = "Угол: %d° вниз от горизонтали · глубина пола × %.3f" % [camera_elevation, floor_depth_ratio]
	_update_actor_screen()
	queue_redraw()


func _toggle_art() -> void:
	art_variant = (art_variant + 1) % 4
	art_enabled = art_variant != 3
	match art_variant:
		0:
			art_button.text = "Вид: SVG"
			status_label.text = "Проверочный SVG: геометрия и старые пропорции"
		1:
			art_button.text = "Вид: AI1"
			status_label.text = "AI-пробник 1: неточное совпадение дверей и стен"
		2:
			art_button.text = "Вид: AI2"
			status_label.text = "AI-пробник 2: ковёр уже встроен в картинку"
		3:
			art_button.text = "Вид: ПЛАН"
			status_label.text = "Габаритный greybox без текстур"
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
	var viewport_mid := _viewport_midpoint(size)
	return viewport_mid + Vector2((p.x - center.x) * zoom, (p.y - center.y) * zoom * floor_depth_ratio)

func _from_screen(p: Vector2) -> Vector2:
	var viewport_mid := _viewport_midpoint(size)
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
	if art_variant == 1 or art_variant == 2:
		match asset_id:
			"RM-ASSET-HALL-CLOCK": return AI_CLOCK
			"RM-ASSET-HALL-CONSOLE": return AI_CONSOLE
			"RM-ASSET-HALL-GALLERY": return AI_GALLERY
		return null
	match asset_id:
		"RM-ASSET-HALL-CLOCK": return HALL_CLOCK
		"RM-ASSET-HALL-SEATS": return HALL_SEATS
		"RM-ASSET-HALL-CONSOLE": return HALL_CONSOLE
		"RM-ASSET-HALL-GALLERY": return HALL_GALLERY
	return null


func _draw_ai_seating(seating_bounds: Rect2) -> void:
	# The generated source contains ONE chair: instantiate twice around a separate table.
	# This is compositional calibration only. Do not alter existing collision rectangles.
	var p := seating_bounds.position
	draw_texture_rect(AI_CHAIR, Rect2(p + Vector2(2, 12), Vector2(58, 96)), false)
	draw_texture_rect(AI_CHAIR, Rect2(p + Vector2(101, 12), Vector2(58, 96)), false)
	draw_texture_rect(AI_SIDE_TABLE, Rect2(p + Vector2(58, 53), Vector2(46, 46)), false)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("111821"))
	var viewport_mid := _viewport_midpoint(size)
	var offset := viewport_mid - Vector2(center.x * zoom, center.y * zoom * floor_depth_ratio)
	draw_set_transform(offset, 0.0, Vector2(zoom, zoom * floor_depth_ratio))
	var f := ThemeDB.fallback_font
	for room in rooms:
		var r := _room_rect(room)
		draw_rect(r, Color(str(room.color)))
		if art_enabled and str(room.id) == "RM-ROOM-HALL":
			if art_variant == 0:
				draw_texture_rect(HALL_SHELL, r, false)
				draw_texture_rect(HALL_RUG, Rect2(785, 435, 130, 396), false)
			elif art_variant == 1:
				draw_texture_rect(AI_HALL_TWIN, r, false)
				draw_texture_rect(AI_RUG, Rect2(785, 435, 130, 396), false)
			else:
				# The second illustration already contains a carpet; do not double-bake it.
				draw_texture_rect(AI_HALL_CRIMSON, r, false)
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
		if art_enabled and (art_variant == 1 or art_variant == 2) and str(item.id) == "RM-ASSET-HALL-SEATS":
			_draw_ai_seating(r)
			if restored:
				draw_rect(r, Color(0.22, 0.7, 0.49, 0.28))
		elif texture != null:
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
	if show_safe_viewport:
		var safe := _safe_viewport_rect(size)
		draw_rect(safe, Color("8dd3af"), false, 2.0)
		draw_line(safe.get_center() - Vector2(9, 0), safe.get_center() + Vector2(9, 0), Color("8dd3af"), 1.0)
		draw_line(safe.get_center() - Vector2(0, 9), safe.get_center() + Vector2(0, 9), Color("8dd3af"), 1.0)
