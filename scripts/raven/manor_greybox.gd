extends Control

## RM-HUB-001 engineering greybox. Geometry is temporary; graph, state and door IDs are production-facing.
const Graph = preload("res://scripts/raven/manor_navigation_graph.gd")
const Snapshot = preload("res://scripts/raven/raven_snapshot.gd")
const Reducer = preload("res://scripts/raven/raven_reducer.gd")
const Store = preload("res://scripts/raven/raven_campaign_store.gd")
const WORLD_SIZE := Vector2(800, 1600)
const MAP_SIZE := Vector2(370, 664)
const SCALE := 0.52

var graph := Graph.new()
var store := Store.new()
var snapshot := Snapshot.fresh()
var world: Control
var actor: Control
var actor_visual: Node2D
var feedback: Label
var door_panel: ColorRect
var route_lines: Node2D
var current_anchor := "RM-NAV-HALL-SPAWN"
var movement: Tween
var capture_path := ""
var capture_unlocked := false
var capture_locked := false


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("capture="):
			capture_path = argument.trim_prefix("capture=")
		elif argument == "unlock=true":
			capture_unlocked = true
		elif argument == "locked=true":
			capture_locked = true
	snapshot = Snapshot.fresh() if capture_locked else store.load_campaign()
	if capture_unlocked and not snapshot.unlockedDoors.has("RM-DOOR-CORRIDOR-BEDROOM"):
		snapshot = Reducer.apply(snapshot, {"eventId": "greybox-capture-unlock", "type": "door_unlock", "doorId": "RM-DOOR-CORRIDOR-BEDROOM"}).state
	graph.rebuild(snapshot)
	_build_ui()
	_refresh_debug_graph()
	_update_door()
	_center_camera()
	if not capture_path.is_empty():
		_capture_later()


func _process(_delta: float) -> void:
	if is_instance_valid(actor):
		actor.z_index = roundi(actor.position.y)
		_center_camera()


func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var backdrop := ColorRect.new()
	backdrop.color = Color("11131b")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	var title := _label("RAVEN MANOR · RM-HUB-001", 18, Color("eadbbf"))
	title.position = Vector2(14, 12); title.size = Vector2(360, 28); add_child(title)
	var frame := Panel.new()
	frame.position = Vector2(10, 48); frame.size = MAP_SIZE; frame.clip_contents = true
	frame.add_theme_stylebox_override("panel", _panel(Color("090d14"), Color("68756f"), 2, 12))
	add_child(frame)
	world = Control.new(); world.size = WORLD_SIZE; world.scale = Vector2.ONE * SCALE; world.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(world)
	_add_room(Rect2(70, 70, 660, 390), "RM-ROOM-HALL", Color("293241"))
	_add_room(Rect2(250, 500, 300, 580), "RM-ROOM-CORRIDOR", Color("3a3440"))
	_add_room(Rect2(70, 1120, 660, 410), "RM-ROOM-BEDROOM", Color("303c3b"))
	var wall_top := ColorRect.new(); wall_top.position = Vector2(70, 1040); wall_top.size = Vector2(280, 90); wall_top.color = Color("171a22"); wall_top.z_index = 1200; world.add_child(wall_top)
	var wall_bottom := ColorRect.new(); wall_bottom.position = Vector2(450, 1040); wall_bottom.size = Vector2(280, 90); wall_bottom.color = Color("171a22"); wall_bottom.z_index = 1200; world.add_child(wall_bottom)
	door_panel = ColorRect.new(); door_panel.position = Vector2(350, 1040); door_panel.size = Vector2(100, 90); door_panel.z_index = 1150; world.add_child(door_panel)
	var lintel := ColorRect.new(); lintel.position = Vector2(340, 1038); lintel.size = Vector2(120, 30); lintel.color = Color("0b0d12"); lintel.z_index = 2000; world.add_child(lintel)
	route_lines = Node2D.new(); route_lines.z_index = 50; world.add_child(route_lines)
	for hotspot_id in ["RM-HS-001", "RM-HS-002", "RM-HS-003", "RM-HS-004", "RM-HS-005"]:
		_add_hotspot(hotspot_id)
	actor = _make_actor(); actor.position = graph.position(current_anchor); world.add_child(actor)
	feedback = _label("Выберите hotspot. Синие линии — доступные связи.", 12, Color("d8d0c1"))
	feedback.position = Vector2(15, 720); feedback.size = Vector2(360, 50); feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; add_child(feedback)
	var unlock := Button.new(); unlock.text = "Открыть спальню (debug)"; unlock.position = Vector2(78, 778); unlock.size = Vector2(234, 42)
	unlock.pressed.connect(_unlock_bedroom); add_child(unlock)


func _add_room(rect: Rect2, room_id: String, color: Color) -> void:
	var room := ColorRect.new(); room.position = rect.position; room.size = rect.size; room.color = color; room.mouse_filter = Control.MOUSE_FILTER_IGNORE; world.add_child(room)
	var label := _label(room_id, 20, Color("e9dfc8")); label.position = rect.position + Vector2(18, 14); label.size = Vector2(rect.size.x - 36, 30); world.add_child(label)


func _add_hotspot(hotspot_id: String) -> void:
	var anchor_id := graph.interaction_anchor(hotspot_id)
	var button := Button.new(); button.text = hotspot_id.trim_prefix("RM-"); button.position = graph.position(anchor_id) - Vector2(62, 24); button.size = Vector2(124, 48)
	button.tooltip_text = "%s → %s" % [hotspot_id, anchor_id]; button.z_index = 1600; button.pressed.connect(_move_to_hotspot.bind(hotspot_id)); world.add_child(button)


func _make_actor() -> Control:
	var holder := Control.new(); holder.size = Vector2(80, 118); holder.pivot_offset = Vector2(40, 100); holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	actor_visual = Node2D.new(); actor_visual.position = Vector2(0, -25); holder.add_child(actor_visual)
	var shadow := Polygon2D.new(); shadow.polygon = PackedVector2Array([Vector2(-26, 34), Vector2(26, 34), Vector2(20, 44), Vector2(-20, 44)]); shadow.color = Color(0.02, 0.03, 0.04, 0.55); actor_visual.add_child(shadow)
	var body := Polygon2D.new(); body.polygon = PackedVector2Array([Vector2(-17, -8), Vector2(17, -8), Vector2(24, 35), Vector2(-24, 35)]); body.color = Color("6f5b79"); actor_visual.add_child(body)
	var head := Polygon2D.new(); head.polygon = PackedVector2Array([Vector2(-15, -35), Vector2(15, -35), Vector2(18, -8), Vector2(-18, -8)]); head.color = Color("d9c0af"); actor_visual.add_child(head)
	var direction := Polygon2D.new(); direction.name = "Direction"; direction.polygon = PackedVector2Array([Vector2(-5, -24), Vector2(7, -20), Vector2(-5, -16)]); direction.color = Color("eadbbf"); actor_visual.add_child(direction)
	var label := _label("TECHNICAL ACTOR", 11, Color("fff0c9")); label.position = Vector2(-72, 20); label.size = Vector2(144, 18); label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; holder.add_child(label)
	return holder


func _move_to_hotspot(hotspot_id: String) -> void:
	var target_anchor := graph.interaction_anchor(hotspot_id)
	var route := graph.route(current_anchor, target_anchor)
	if route.is_empty():
		feedback.text = "%s недоступен: дверь или маршрут заблокированы." % hotspot_id
		return
	if movement and movement.is_valid():
		movement.kill()
	movement = create_tween()
	var previous := actor.position
	for index in range(1, route.size()):
		var anchor_id := route[index]
		var target := graph.position(anchor_id)
		movement.tween_callback(_start_animation.bind(target - previous))
		movement.tween_property(actor, "position", target, maxf(0.12, previous.distance_to(target) / 300.0)).set_trans(Tween.TRANS_LINEAR)
		movement.tween_callback(_anchor_reached.bind(anchor_id))
		previous = target
	movement.tween_callback(_interaction_reached.bind(hotspot_id))


func _anchor_reached(anchor_id: String) -> void:
	current_anchor = anchor_id


func _interaction_reached(hotspot_id: String) -> void:
	actor_visual.rotation = 0.0; actor_visual.scale = Vector2.ONE
	feedback.text = "Достигнут %s через %s." % [hotspot_id, current_anchor]


func _start_animation(delta: Vector2) -> void:
	if absf(delta.x) > absf(delta.y):
		actor_visual.scale = Vector2(-1, 1) if delta.x < 0 else Vector2.ONE
	else:
		actor_visual.scale = Vector2.ONE
	actor_visual.rotation = -0.05 if delta.x < 0 else 0.05


func _unlock_bedroom() -> void:
	if not snapshot.unlockedDoors.has("RM-DOOR-CORRIDOR-BEDROOM"):
		var result := Reducer.apply(snapshot, {"eventId": "greybox-bedroom-access", "type": "door_unlock", "doorId": "RM-DOOR-CORRIDOR-BEDROOM"})
		if result.ok:
			snapshot = result.state; store.save_campaign(snapshot)
	graph.rebuild(snapshot); _refresh_debug_graph(); _update_door()
	feedback.text = "RM-DOOR-CORRIDOR-BEDROOM открыт и сохранён."


func _refresh_debug_graph() -> void:
	for child in route_lines.get_children(): child.queue_free()
	for edge in graph.active_edges():
		var line := Line2D.new(); line.width = 5; line.default_color = Color(0.28, 0.72, 0.90, 0.72)
		line.add_point(graph.position(edge.from)); line.add_point(graph.position(edge.to)); route_lines.add_child(line)
	for anchor_id in graph.anchors():
		var marker := Polygon2D.new(); marker.polygon = PackedVector2Array([Vector2(-7, -7), Vector2(7, -7), Vector2(7, 7), Vector2(-7, 7)])
		marker.position = graph.position(anchor_id); marker.color = Color("f0c86a"); route_lines.add_child(marker)


func _update_door() -> void:
	var unlocked: bool = snapshot.unlockedDoors.has("RM-DOOR-CORRIDOR-BEDROOM")
	door_panel.color = Color(0.12, 0.24, 0.20, 0.28) if unlocked else Color("572d35")
	door_panel.visible = not unlocked


func _center_camera() -> void:
	if not is_instance_valid(world) or not is_instance_valid(actor): return
	var desired := MAP_SIZE * 0.5 - actor.position * SCALE
	var scaled := WORLD_SIZE * SCALE
	world.position.x = clampf(desired.x, minf(0, MAP_SIZE.x - scaled.x), 0)
	world.position.y = clampf(desired.y, minf(0, MAP_SIZE.y - scaled.y), 0)


func _capture_later() -> void:
	if not capture_path.is_absolute_path() or not capture_path.to_lower().ends_with(".png"):
		push_error("capture must be an absolute PNG path"); return
	await get_tree().process_frame; await get_tree().process_frame; await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	if image == null or image.save_png(capture_path) != OK:
		push_error("greybox capture failed"); get_tree().quit(1); return
	print("RAVEN_GREYBOX_CAPTURE " + capture_path); get_tree().quit()


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new(); label.text = text; label.add_theme_font_size_override("font_size", font_size); label.add_theme_color_override("font_color", color); label.mouse_filter = Control.MOUSE_FILTER_IGNORE; return label


func _panel(background: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new(); style.bg_color = background; style.border_color = border; style.set_border_width_all(width); style.set_corner_radius_all(radius); return style
