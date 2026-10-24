extends Control

const Snapshot = preload("res://scripts/raven/raven_snapshot.gd")
const Reducer = preload("res://scripts/raven/raven_reducer.gd")
const Store = preload("res://scripts/raven/raven_campaign_store.gd")

var store := Store.new()
var state := Snapshot.fresh()
var summary: Label
var feedback: Label
var event_serial := 0


func _ready() -> void:
	state = store.load_campaign()
	_build_ui(); _refresh("Состояние загружено: " + store.last_load_report.detail)


func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new(); background.color = Color("11151d"); background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(background)
	var margin := MarginContainer.new(); margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]: margin.add_theme_constant_override(side, 16)
	add_child(margin)
	var scroll := ScrollContainer.new(); margin.add_child(scroll)
	var column := VBoxContainer.new(); column.custom_minimum_size = Vector2(358, 0); column.add_theme_constant_override("separation", 8); scroll.add_child(column)
	var heading := _label("FOUNDATION SANDBOX", 22, Color("eadbbf")); column.add_child(heading)
	summary = _label("", 14, Color("cfe5da")); summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; summary.custom_minimum_size = Vector2(0, 150); column.add_child(summary)
	feedback = _label("", 13, Color("e8c98d")); feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; feedback.custom_minimum_size = Vector2(0, 44); column.add_child(feedback)
	_add_action(column, "1. Победа RM-LVL-001 (+2 один раз)", _event.bind("level_won", {"levelId": "RM-LVL-001"}))
	_add_action(column, "2. Разрешить вход и открыть спальню", _bedroom_access)
	_add_action(column, "3. RM-REST-001: подготовить спальню (-2)", _event.bind("restoration_purchase", {"restorationId": "RM-REST-001"}))
	_add_action(column, "4. Победа RM-LVL-002 (+2)", _event.bind("level_won", {"levelId": "RM-LVL-002"}))
	_add_action(column, "5. Победа RM-LVL-003 (+2)", _event.bind("level_won", {"levelId": "RM-LVL-003"}))
	_add_action(column, "6. Вызвать специалиста", _event.bind("story_flag_set", {"flagId": "service.plumber_available"}))
	_add_action(column, "7. RM-REST-002: ванная (-4)", _event.bind("restoration_purchase", {"restorationId": "RM-REST-002"}))
	_add_action(column, "СОХРАНИТЬ", _save)
	_add_action(column, "ПЕРЕЗАГРУЗИТЬ ИЗ SAVE", _reload)
	_add_action(column, "ПРОДОЛЖИТЬ НА КАРТЕ", func(): _save(); get_tree().change_scene_to_file("res://scenes/raven/manor_greybox.tscn"))
	_add_action(column, "СБРОСИТЬ RAVEN SAVE", _reset)
	_add_action(column, "← К СПИСКУ ПРОТОТИПОВ", func(): get_tree().change_scene_to_file("res://scenes/raven/prototype_launcher.tscn"))


func _add_action(parent: VBoxContainer, text: String, action: Callable) -> void:
	var button := Button.new(); button.text = text; button.custom_minimum_size = Vector2(0, 44); button.pressed.connect(action); parent.add_child(button)


func _event(type: String, payload: Dictionary) -> void:
	event_serial += 1
	var command := payload.duplicate(true); command.type = type; command.eventId = "lab-%d-%d" % [Time.get_ticks_msec(), event_serial]
	var result := Reducer.apply(state, command)
	if result.ok:
		state = result.state; _save(); _refresh("Применено: %s%s" % [type, " (duplicate)" if result.duplicate else ""])
	else:
		_refresh("Отклонено: " + str(result.error))


func _bedroom_access() -> void:
	_event("story_flag_set", {"flagId": "RM-FLAG-BEDROOM-ACCESS-CLEARED"})
	_event("door_unlock", {"doorId": "RM-DOOR-CORRIDOR-BEDROOM"})


func _save() -> void:
	_refresh("Сохранено." if store.save_campaign(state) else "Ошибка сохранения.")


func _reload() -> void:
	state = store.load_campaign(); _refresh("Перезагружено: " + store.last_load_report.detail)


func _reset() -> void:
	store.reset_campaign(); state = Snapshot.fresh(); _refresh("Raven save сброшен.")


func _refresh(message: String) -> void:
	if not is_instance_valid(summary): return
	summary.text = "Очки: %d   Revision: %d\nУровни: %s\nРеставрации: %s\nДвери: %s\nФлаги: %s" % [
		state.workPoints, state.revision, str(state.firstClearLevels), str(state.completedRestorations), str(state.unlockedDoors), str(state.storyFlags)
	]
	feedback.text = message


func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new(); label.text = text; label.add_theme_font_size_override("font_size", size); label.add_theme_color_override("font_color", color); return label
