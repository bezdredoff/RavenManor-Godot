extends Node2D
## GAME-LOOP-02: normal-game production map view. Only the existing G2 host
## controls Evelyn, routes, physical handoffs, story events and persistence.
## This view accepts no QA fixture, raw screen destinations or injected plan.
const Host = preload("res://scripts/raven/raven_gameplay_host.gd")
const Entry = preload("res://scripts/raven/raven_player_map_entry.gd")
const Source = preload("res://scripts/raven/manor_navigation_source.gd")
const Bridge = preload("res://scripts/raven/raven_hotspot_gameplay_bridge.gd")
const Store = preload("res://scripts/raven/raven_campaign_store.gd")
const SettingsDialog = preload("res://scripts/raven/raven_settings_dialog.gd")

const MENU := "res://scenes/raven/main_menu.tscn"
const LABELS := {
	"ru": ["Поместье", "Пауза", "Продолжить", "Отмена", "Настройки", "Меню", "Сцена",
		"Карта недоступна: ожидается утверждённая геометрия", "Маршрут отменён",
		"Нельзя взаимодействовать: ", "Холл", "Коридор", "Спальня", "Открыть"],
	"be": ["Маёнтак", "Паўза", "Працягнуць", "Скасаваць", "Налады", "Меню", "Сцэна",
		"Мапа недаступная: чакаецца зацверджаная геаметрыя", "Маршрут скасаваны",
		"Немагчыма ўзаемадзейнічаць: ", "Хол", "Калідор", "Спальня", "Адчыніць"],
	"en": ["Manor", "Pause", "Resume", "Cancel", "Settings", "Menu", "Scene",
		"Map unavailable: approved geometry required", "Route cancelled",
		"Interaction unavailable: ", "Hall", "Corridor", "Bedroom", "Open"],
}
const HOTSPOT_NAMES := {
	"RM-HS-005": {"ru": "Дверь спальни", "be": "Дзверы спальні", "en": "Bedroom access"},
	"RM-HS-002": {"ru": "Обустройство", "be": "Аднаўленне", "en": "Restore bedroom"},
}
const ROOM_NAMES := {
	"RM-ROOM-HALL": 10,
	"RM-ROOM-CORRIDOR": 11,
	"RM-ROOM-BEDROOM": 12,
}

var host
var camera: Camera2D
var background: Sprite2D
var targets: Node2D
var ui_layer: CanvasLayer
var status: Label
var heading: Label
var resume_button: Button
var pause_button: Button
var cancel_button: Button
var settings_button: Button
var menu_button: Button
var settings
var overlay: Control
var audio_runtime: Variant
var prefs: Variant
var _moving := false
var _paused := false
var _exit_requested := false
var _presentation_dismissed := false
var _ready_for_input := false
var _room_id := ""
var _zoom := 1.0


func _ready() -> void:
	# Consume the normal-menu scene-routing flag before any future Prototype
	# Lab entry; it is navigation metadata, never story or save state.
	if get_tree().has_meta("raven_normal_gameplay_from_menu"):
		get_tree().remove_meta("raven_normal_gameplay_from_menu")
	audio_runtime = get_node("/root/RavenAudio")
	prefs = audio_runtime.preferences
	audio_runtime.set_scene("vn")
	background = Sprite2D.new()
	background.centered = false
	background.z_index = -10
	add_child(background)
	host = Host.new()
	add_child(host)
	targets = Node2D.new()
	targets.z_index = 10
	add_child(targets)
	camera = Camera2D.new()
	add_child(camera)
	camera.make_current()
	get_viewport().size_changed.connect(_resize_camera)
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)
	_build_hud()
	var stored := Store.new()
	var snapshot: Dictionary = stored.load_campaign()
	if str(stored.last_load_report.get("status", "")) == "recovered-corrupt" or \
			str(stored.last_load_report.get("detail", "")) == "storage-read-failed":
		_hold("save-unreadable")
		return
	if not Entry.can_enter(snapshot):
		_hold(_copy(7))
		return
	var start: Dictionary = host.configure({
		"schemaVersion": Source.SCHEMA_VERSION,
		"kind": Source.REQUEST_KIND,
		"mode": Source.MODE_PRODUCTION,
	})
	if not bool(start.get("ok", false)):
		_hold(_copy(7) + ": " + str(start.get("error", "")))
		return
	host.save_refused.connect(_on_save_refused)
	host.room_changed.connect(func(_room: Dictionary) -> void: call_deferred("_refresh_room"))
	prefs.locale_changed.connect(func(_locale: String) -> void: _refresh_room())
	_ready_for_input = true
	if not _refresh_room():
		_hold("approved-room-visual-unavailable")
		return
	_set_status(_copy(0))
	_maybe_open_presentation()


func _build_hud() -> void:
	var surface := Control.new()
	surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(surface)
	var top := PanelContainer.new()
	top.anchor_right = 1.0
	top.offset_left = 8.0
	top.offset_top = 8.0
	top.offset_right = -8.0
	surface.add_child(top)
	var top_column := VBoxContainer.new()
	top.add_child(top_column)
	heading = Label.new()
	heading.add_theme_font_size_override("font_size", 17)
	top_column.add_child(heading)
	status = Label.new()
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.add_theme_font_size_override("font_size", 12)
	top_column.add_child(status)
	var bottom := PanelContainer.new()
	bottom.anchor_left = 0.0
	bottom.anchor_right = 1.0
	bottom.anchor_top = 1.0
	bottom.anchor_bottom = 1.0
	bottom.offset_left = 8.0
	bottom.offset_right = -8.0
	bottom.offset_top = -164.0
	bottom.offset_bottom = -8.0
	surface.add_child(bottom)
	var controls := GridContainer.new()
	controls.columns = 2
	controls.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	controls.add_theme_constant_override("h_separation", 6)
	controls.add_theme_constant_override("v_separation", 6)
	bottom.add_child(controls)
	pause_button = _hud_button(controls, _copy(1), _toggle_pause)
	cancel_button = _hud_button(controls, _copy(3), _cancel)
	settings_button = _hud_button(controls, _copy(4), _show_settings)
	menu_button = _hud_button(controls, _copy(5), _request_menu)
	resume_button = _hud_button(controls, _copy(6), _resume_presentation)
	resume_button.visible = false
	settings = SettingsDialog.new()
	settings.setup(prefs, audio_runtime)
	settings.locale_selected.connect(func(_locale: String) -> void: _refresh_room())
	settings.visibility_changed.connect(func() -> void:
		if _ready_for_input and settings.visible:
			_set_status(_copy(4)))
	ui_layer.add_child(settings)


func _hud_button(parent: Control, caption: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(0, 48)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.clip_text = true
	button.pressed.connect(action)
	parent.add_child(button)
	return button


func _copy(index: int) -> String:
	return str(LABELS.get(str(prefs.locale) if prefs != null else "ru", LABELS["ru"])[index])


func _room_name(id: String) -> String:
	return _copy(int(ROOM_NAMES.get(id, 0))) if ROOM_NAMES.has(id) else id


## Only approved source visuals define world coordinates, texture and scale.
## 'bounds' means [world_left, world_top, world_width, world_height].
func _refresh_room() -> bool:
	if not _ready_for_input or host.navigation == null:
		return false
	var room := str(host.navigation.controller.room_id())
	var visual: Dictionary = host.source.get("visuals", {}).get(room, {})
	var path := str(visual.get("texturePath", ""))
	var bounds: Variant = visual.get("bounds", [])
	if not path.begins_with("res://") or not ResourceLoader.exists(path) or \
			not bounds is Array or bounds.size() != 4 or float(bounds[2]) <= 0.0 or float(bounds[3]) <= 0.0:
		return false
	var texture := load(path) as Texture2D
	if texture == null or texture.get_size().x <= 0.0 or texture.get_size().y <= 0.0:
		return false
	background.texture = texture
	background.position = Vector2(float(bounds[0]), float(bounds[1]))
	background.scale = Vector2(float(bounds[2]), float(bounds[3])) / texture.get_size()
	_zoom = clampf(float(visual.get("cameraZoom", 1.0)), 0.1, 4.0)
	_room_id = room
	heading.text = _copy(0) + " · " + _room_name(room)
	_refresh_ui_copy()
	_rebuild_targets()
	_resize_camera()
	return true


func _refresh_ui_copy() -> void:
	pause_button.text = _copy(2) if _paused else _copy(1)
	cancel_button.text = _copy(3)
	settings_button.text = _copy(4)
	menu_button.text = _copy(5)
	resume_button.text = _copy(6)


func _resize_camera() -> void:
	if camera == null:
		return
	var viewport_width := get_viewport_rect().size.x
	camera.zoom = Vector2.ONE * _zoom * clampf(viewport_width / 390.0, 0.7, 1.1)


func _rebuild_targets() -> void:
	for child in targets.get_children():
		child.queue_free()
	if not _ready_for_input:
		return
	var room_data: Dictionary = {}
	for candidate in host.source.get("contract", {}).get("rooms", []):
		if str(candidate.get("id", "")) == _room_id:
			room_data = candidate
			break
	for anchor in room_data.get("graph", {}).get("anchors", []):
		var hotspot_id := str(anchor.get("hotspotId", ""))
		if not Bridge.HOTSPOT_STEPS.has(hotspot_id):
			continue
		var label_set: Dictionary = HOTSPOT_NAMES.get(hotspot_id, {})
		var caption := str(label_set.get(str(prefs.locale), hotspot_id))
		var allowed := Bridge.story_available(host.state, hotspot_id)
		_world_button(anchor.get("position", []),
			caption if allowed else "🔒 " + caption,
			Callable(self, "_request_story").bind(hotspot_id), allowed)
	for transition in host.source.get("contract", {}).get("transitions", []):
		if str(transition.get("sourceRoomId", "")) != _room_id:
			continue
		var approach := str(transition.get("approachAnchorId", ""))
		var door_id := str(transition.get("doorId", ""))
		var unlocked := host.state.get("unlockedDoors", []).has(door_id)
		var room_label := _room_name(str(transition.get("destinationRoomId", "")))
		var caption := "→ " + room_label if unlocked else "🔒 " + room_label
		for anchor in room_data.get("graph", {}).get("anchors", []):
			if str(anchor.get("id", "")) == approach:
				var transition_id := str(transition.get("id", ""))
				_world_button(anchor.get("position", []), caption,
					Callable(self, "_request_door").bind(transition_id), unlocked)
				break


func _world_button(coords: Variant, caption: String, action: Callable, enabled: bool) -> void:
	if not coords is Array or coords.size() != 2:
		return
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(136, 50)
	button.position = Vector2(float(coords[0]) - 68.0, float(coords[1]) - 76.0)
	button.modulate = Color.WHITE if enabled else Color(0.75, 0.72, 0.74, 0.8)
	button.pressed.connect(action)
	targets.add_child(button)


func _request_story(hotspot_id: String) -> void:
	if not _can_request():
		return
	_accept_request(host.request_story_hotspot(hotspot_id))


func _request_door(transition_id: String) -> void:
	if not _can_request():
		return
	_accept_request(host.request_transition(transition_id))


func _can_request() -> bool:
	return _ready_for_input and not _moving and not _paused and not _exit_requested \
		and not is_instance_valid(overlay) and not settings.visible


func _accept_request(result: Dictionary) -> void:
	if not bool(result.get("ok", false)):
		_set_status(_copy(9) + str(result.get("error", "rejected")))
		return
	_moving = true
	_set_status(_copy(0))


func _process(delta: float) -> void:
	if not _ready_for_input or host.navigation == null:
		return
	if is_instance_valid(host.navigation.actor):
		camera.position = host.navigation.actor.position
	if _moving and not _paused:
		var result: Dictionary = host.advance(delta)
		if not bool(result.get("ok", false)):
			_moving = false
			_set_status(_copy(9) + str(result.get("error", "movement-rejected")))
		else:
			match str(result.get("status", "")):
				"ready":
					var crossing: Dictionary = host.commit_ready_transition()
					_moving = false
					if bool(crossing.get("ok", false)):
						if not _refresh_room():
							_hold("approved-room-visual-unavailable")
					else:
						_set_status(_copy(9) + str(crossing.get("error", "handoff-rejected")))
				"action-committed":
					_moving = false
					_rebuild_targets()
					_maybe_open_presentation()
				"arrived", "idle", "cancelled":
					_moving = false
	if is_instance_valid(overlay):
		var active_step: Variant = overlay.get("step")
		if active_step is Dictionary and str(active_step.get("id", "")) in ["access", "restore1"]:
			_close_presentation(false)
	if _exit_requested and not _moving and not host.navigation.actor.has_active_segment():
		get_tree().change_scene_to_file(MENU)


func _maybe_open_presentation() -> void:
	if not _ready_for_input or _presentation_dismissed or is_instance_valid(overlay):
		return
	var activity: Dictionary = host.current_activity()
	if str(activity.get("kind", "")) not in ["vn", "match3"]:
		resume_button.visible = false
		return
	overlay = host.mount_presentation(ui_layer)
	if is_instance_valid(overlay):
		overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		overlay.connect("map_return_requested", _dismiss_presentation)
		resume_button.visible = false
	else:
		_set_status(_copy(9) + "presentation-unavailable")


func _dismiss_presentation() -> void:
	_close_presentation(true)


func _close_presentation(dismissed: bool) -> void:
	if not is_instance_valid(overlay):
		return
	var result: Dictionary = host.close_presentation()
	overlay = null
	_presentation_dismissed = dismissed
	if not bool(result.get("ok", false)):
		_hold(str(result.get("error", "presentation-save-unreadable")))
		return
	resume_button.visible = dismissed and str(host.current_activity().get("kind", "")) in ["vn", "match3"]
	_rebuild_targets()


func _resume_presentation() -> void:
	if _ready_for_input and not _moving and not _paused:
		_presentation_dismissed = false
		_maybe_open_presentation()


func _cancel() -> void:
	if not _ready_for_input:
		return
	if _paused:
		_toggle_pause()
	var answer: Dictionary = host.cancel()
	_set_status(_copy(8) if bool(answer.get("ok", false)) else str(answer.get("error", "")))
	if not bool(answer.get("finishCurrentSegment", false)):
		_moving = false


func _toggle_pause() -> void:
	if not _ready_for_input:
		return
	_paused = not _paused
	host.set_paused(_paused)
	pause_button.text = _copy(2) if _paused else _copy(1)


func _show_settings() -> void:
	if _ready_for_input and not is_instance_valid(overlay):
		# Do not allow a physical segment to progress under a settings modal.
		if _moving and not _paused:
			_toggle_pause()
		settings.popup_centered(Vector2i(mini(360, int(get_viewport_rect().size.x) - 12),
			mini(520, int(get_viewport_rect().size.y) - 12)))


func _request_menu() -> void:
	if _moving:
		_exit_requested = true
		_cancel()
	else:
		get_tree().change_scene_to_file(MENU)


func _on_save_refused(reason: String) -> void:
	_hold(reason)


func _hold(reason: String) -> void:
	_ready_for_input = false
	_moving = false
	_set_status(reason)
	if is_instance_valid(pause_button):
		pause_button.disabled = true
	if is_instance_valid(resume_button):
		resume_button.disabled = true


func _set_status(message: String) -> void:
	if is_instance_valid(status):
		status.text = message
