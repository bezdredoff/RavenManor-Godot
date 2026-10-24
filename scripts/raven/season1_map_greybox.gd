extends Control
## RM-MAP-S1 contiguous footprint feasibility, intentionally separate from accepted RM-VS-01.
## Geometry and furniture are placeholders; never claim production art calibration.
const DATA = preload("res://data/raven/season1_world_map.json")
const Snapshot = preload("res://scripts/raven/raven_snapshot.gd")
const Store = preload("res://scripts/raven/raven_campaign_store.gd")
const VIEW_TOP := 98.0
const VIEW_BOTTOM := 740.0
const TRAVEL_SPEED := 460.0
var rooms: Array
var doors: Array
var props: Array
var world_size := Vector2(2150, 2250)
var center := Vector2(930, 620)
var zoom := 0.47
var dragging := false
var drag_distance := 0.0
var drag_origin := Vector2.ZERO
var actor_pos := Vector2(990, 640)
var movement_points: Array[Vector2] = []
var local_return: Array[Vector2] = []
var selected_prop := {}
var repaired_in_preview := {}
var repair_button: Button
var explore_all := true
var follow_actor := false
var nav := AStar2D.new()
var points: Array[Vector2] = []
var snapshot: Dictionary
var status_label: Label
var selected_label: Label
var action_button: Button
var toggle_button: Button

func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP
	rooms = DATA.data.rooms
	doors = DATA.data.doors
	props = DATA.data.props
	snapshot = Store.new().load_campaign()
	_make_ui()
	_rebuild_navigation()
	queue_redraw()

func _make_ui() -> void:
	var header := ColorRect.new()
	header.color = Color("151b22")
	header.set_anchors_and_offsets_preset(PRESET_TOP_WIDE)
	header.offset_bottom = 95
	header.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(header)
	var title := _label("RAVEN MANOR · WHOLE MAP GREYBOX", 17)
	title.position = Vector2(12, 7); title.size = Vector2(310, 24)
	add_child(title)
	var help := _label("Тяни карту · коснись предмета · колесо = масштаб", 11)
	help.position = Vector2(12, 33); help.size = Vector2(365, 24)
	add_child(help)
	toggle_button = _button("ВСЕ ПРОХОДЫ: ТЕСТ", Vector2(12, 61), Vector2(180, 32), _toggle_explore)
	_button("Центр на Эвелин", Vector2(199, 61), Vector2(174, 32), _recenter)
	var footer := ColorRect.new(); footer.color = Color("151b22")
	footer.anchor_top = 1.0; footer.anchor_bottom = 1.0
	footer.offset_top = -106; footer.offset_bottom = 0
	footer.anchor_right = 1.0; footer.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(footer)
	selected_label = _label("Выбери мебель или значок сюжетного ремонта", 12)
	selected_label.anchor_top = 1.0; selected_label.anchor_bottom = 1.0
	selected_label.position = Vector2(10, -103); selected_label.size = Vector2(365, 28)
	add_child(selected_label)
	status_label = _label("Топология S1: восемь зон, все пороги и габариты мебели", 11)
	status_label.anchor_top = 1.0; status_label.anchor_bottom = 1.0
	status_label.position = Vector2(10, -72); status_label.size = Vector2(365, 27)
	add_child(status_label)
	action_button = _button("MATCH-3", Vector2(10, 0), Vector2(116, 36), _open_preview)
	action_button.anchor_top = 1.0; action_button.anchor_bottom = 1.0; action_button.position.y = -43
	action_button.disabled = true
	repair_button = _button("До / После", Vector2(135, 0), Vector2(112, 36), _toggle_repair)
	repair_button.anchor_top = 1.0; repair_button.anchor_bottom = 1.0; repair_button.position.y = -43
	repair_button.disabled = true
	var back := _button("← Меню", Vector2(256, 0), Vector2(116, 36), func(): get_tree().change_scene_to_file("res://scenes/raven/prototype_launcher.tscn"))
	back.anchor_top = 1.0; back.anchor_bottom = 1.0; back.position.y = -43

func _label(t: String, font_size: int) -> Label:
	var l := Label.new(); l.text = t; l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", Color("efe4cf")); l.mouse_filter = MOUSE_FILTER_IGNORE
	return l

func _button(t: String, pos: Vector2, dims: Vector2, callback: Callable) -> Button:
	var b := Button.new(); b.text = t; b.position = pos; b.size = dims; b.pressed.connect(callback); add_child(b)
	return b

func _toggle_explore() -> void:
	explore_all = not explore_all
	toggle_button.text = "ВСЕ ПРОХОДЫ: ТЕСТ" if explore_all else "ПО СЮЖЕТНЫМ GATE"
	movement_points.clear()
	_rebuild_navigation()
	status_label.text = "Тест геометрии: все доступные двери" if explore_all else "Двери ограничены текущим Raven-save"
	queue_redraw()

func _recenter() -> void:
	center = actor_pos
	follow_actor = true
	queue_redraw()

func _open_preview() -> void:
	if not str(selected_prop.get("level", "")).is_empty():
		get_tree().set_meta("raven_map_preview_level", str(selected_prop.level))
		get_tree().change_scene_to_file("res://scenes/raven/content_preview.tscn")

func _toggle_repair() -> void:
	var id := str(selected_prop.get("id", ""))
	if id.is_empty(): return
	repaired_in_preview[id] = not bool(repaired_in_preview.get(id, false))
	status_label.text = "Визуальный тест: " + ("после ремонта" if repaired_in_preview[id] else "до ремонта") + " (без изменения Raven-save)"
	queue_redraw()


func _room_center(index: int) -> Vector2:
	var r: Array = rooms[index].rect
	if rooms[index].has("safeCenter"):
		return Vector2(float(rooms[index].safeCenter[0]), float(rooms[index].safeCenter[1]))
	return Vector2(float(r[0]) + float(r[2]) * 0.5, float(r[1]) + float(r[3]) * 0.5)

func _door_enabled(d: Dictionary) -> bool:
	if str(d.status) == "future": return false
	if explore_all: return true
	return str(d.status) == "open" or snapshot.get("unlockedDoors", []).has(str(d.id))

func _rebuild_navigation() -> void:
	nav.clear(); points.clear()
	for i in range(rooms.size()):
		_add_nav_point(_room_center(i))
	for d in doors:
		if not _door_enabled(d): continue
		var p := Vector2(float(d.point[0]), float(d.point[1]))
		var index := _add_nav_point(p)
		_link_chain(int(d.a), d.get("routeA", []), index)
		if int(d.b) >= 0: _link_chain(index, d.get("routeB", []), int(d.b))
	queue_redraw()

func _link_chain(from_index: int, guide: Array, to_index: int) -> void:
	var last_id := from_index
	for raw in guide:
		var v := Vector2(float(raw[0]), float(raw[1]))
		var next_id := _add_nav_point(v)
		nav.connect_points(last_id, next_id)
		last_id = next_id
	nav.connect_points(last_id, to_index)


func _add_nav_point(p: Vector2) -> int:
	var idx := points.size()
	points.append(p); nav.add_point(idx, p)
	return idx

func _nearest_room(pos: Vector2) -> int:
	for i in range(rooms.size()):
		var r: Array = rooms[i].rect
		if Rect2(float(r[0]), float(r[1]), float(r[2]), float(r[3])).has_point(pos): return i
	return 1

func _route_to(target: Vector2, room_index: int, local_steps: Array = []) -> void:
	var origin_room := _nearest_room(actor_pos)
	var path_ids := nav.get_id_path(origin_room, room_index)
	if path_ids.is_empty():
		status_label.text = "Заблокировано: проход ещё закрыт"; return
	movement_points.clear()
	for i in range(local_return.size() - 1, -1, -1):
		movement_points.append(local_return[i])
	movement_points.append(_room_center(origin_room))
	for idx in path_ids:
		var p := points[int(idx)]
		if movement_points.is_empty() or movement_points.back().distance_to(p) > 1:
			movement_points.append(p)
	local_return.clear()
	for raw in local_steps:
		var stop := Vector2(float(raw[0]), float(raw[1]))
		movement_points.append(stop)
		local_return.append(stop)
	movement_points.append(target)
	follow_actor = true
	status_label.text = "Эвелин идёт по маршруту через %d узлов" % movement_points.size()

func _process(delta: float) -> void:
	if not movement_points.is_empty():
		var target: Vector2 = movement_points.front()
		actor_pos = actor_pos.move_toward(target, TRAVEL_SPEED * delta)
		if actor_pos.distance_to(target) < 0.6: movement_points.pop_front()
		if follow_actor: center = actor_pos
		queue_redraw()

func _offset() -> Vector2:
	return Vector2(size.x * 0.5, (VIEW_TOP + minf(size.y - 107.0, VIEW_BOTTOM)) * 0.5) - center * zoom

func _from_screen(p: Vector2) -> Vector2:
	return (p - _offset()) / zoom

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			zoom = clampf(zoom * 1.12, 0.16, 1.25); queue_redraw(); accept_event()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			zoom = clampf(zoom / 1.12, 0.16, 1.25); queue_redraw(); accept_event()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed: dragging = true; drag_distance = 0; drag_origin = event.position
			else:
				if dragging and drag_distance < 12: _select_at(_from_screen(event.position))
				dragging = false
			accept_event()
	elif event is InputEventMouseMotion and dragging:
		center -= event.relative / zoom
		drag_distance += event.relative.length()
		follow_actor = false; queue_redraw(); accept_event()
	elif event is InputEventScreenTouch:
		if event.pressed: dragging = true; drag_distance = 0
		else:
			if dragging and drag_distance < 12: _select_at(_from_screen(event.position))
			dragging = false
		accept_event()
	elif event is InputEventScreenDrag:
		center -= event.relative / zoom; drag_distance += event.relative.length()
		follow_actor = false; queue_redraw(); accept_event()

func _select_at(p: Vector2) -> void:
	if not movement_points.is_empty():
		status_label.text = "Сначала заверши текущее перемещение Эвелин"
		return
	for item in props:
		var r: Array = item.rect
		var box := Rect2(float(r[0]), float(r[1]), float(r[2]), float(r[3]))
		if box.grow(24).has_point(p):
			selected_prop = item
			selected_label.text = str(item.title) + (" · " + str(item.restoration) if not str(item.restoration).is_empty() else "")
			action_button.disabled = str(item.level).is_empty()
			repair_button.disabled = str(item.restoration).is_empty()
			var dest := Vector2(box.position.x + box.size.x * 0.5, box.position.y + box.size.y + 70)
			if item.has("approach"):
				dest = Vector2(float(item.approach[0]), float(item.approach[1]))
			_route_to(dest, int(item.room), item.get("localRoute", []))
			queue_redraw(); return
	for d in doors:
		var dp := Vector2(float(d.point[0]), float(d.point[1]))
		if dp.distance_to(p) < 90:
			selected_label.text = str(d.id)
			action_button.disabled = true
			repair_button.disabled = true
			if _door_enabled(d) and int(d.b) >= 0: _route_to(_room_center(int(d.b)), int(d.b))
			else: status_label.text = "Заблокировано: закрытая зона или сюжетный gate"
			queue_redraw(); return

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("111821"))
	draw_set_transform(_offset(), 0, Vector2.ONE * zoom)
	var f := ThemeDB.fallback_font
	for room in rooms:
		var a: Array = room.rect
		var r := Rect2(float(a[0]), float(a[1]), float(a[2]), float(a[3]))
		draw_rect(r, Color(str(room.color)))
		draw_rect(r, Color("493b34"), false, 13)
		draw_string(f, r.position + Vector2(28, 43), str(room.title), HORIZONTAL_ALIGNMENT_LEFT, -1, 25, Color("1d1c20"))
	# Hall split stairs and east door keep precise owner-selected topology.
	for d in doors:
		var dp := Vector2(float(d.point[0]), float(d.point[1]))
		draw_rect(Rect2(dp - Vector2(38, 38), Vector2(76, 76)), Color("63b8a0") if _door_enabled(d) else Color("a7545e"))
	for item in props:
		var a: Array = item.rect
		var r := Rect2(float(a[0]), float(a[1]), float(a[2]), float(a[3]))
		var chosen: bool = str(item.id) == str(selected_prop.get("id", ""))
		draw_rect(r, Color("79b894") if bool(repaired_in_preview.get(str(item.id), false)) else (Color("d7b16c") if chosen else Color("65524b")))
		draw_rect(r, Color("f6d888") if chosen else Color("d0ae88"), false, 5)
		draw_string(f, r.position + Vector2(7, maxf(25, r.size.y * 0.5)), str(item.title), HORIZONTAL_ALIGNMENT_LEFT, int(r.size.x) - 12, 15, Color.WHITE)
	# Diagnostic path rendered beneath protagonist, not final art.
	if not movement_points.is_empty():
		var last := actor_pos
		for v in movement_points:
			draw_line(last, v, Color("8bd5ed"), 7)
			last = v
	draw_circle(actor_pos, 24, Color("e8b86c"))
	draw_circle(actor_pos, 14, Color("634c69"))
	draw_string(f, actor_pos + Vector2(-27, -34), "E", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)
	draw_set_transform(Vector2.ZERO)
