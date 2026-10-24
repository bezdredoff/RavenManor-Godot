extends Control

const FOUNDATION_SCENE := "res://scenes/raven/foundation_lab.tscn"
const NAVIGATION_SCENE := "res://scenes/raven/manor_greybox.tscn"
const VERTICAL_SLICE_SCENE := "res://scenes/raven/vertical_slice.tscn"
const CONTENT_PREVIEW_SCENE := "res://scenes/raven/content_preview.tscn"


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new(); background.color = Color("10131b"); background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(background)
	var margin := MarginContainer.new(); margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 18); margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 24); margin.add_theme_constant_override("margin_bottom", 24); add_child(margin)
	var scroll := ScrollContainer.new(); margin.add_child(scroll)
	var column := VBoxContainer.new(); column.custom_minimum_size = Vector2(354, 0); column.add_theme_constant_override("separation", 14); scroll.add_child(column)
	column.add_child(_title("RAVEN MANOR", 30, Color("eadbbf")))
	column.add_child(_title("Prototype Lab · RM-HUB-001", 17, Color("a9c8be")))
	column.add_child(_paragraph("Единая интерактивная сборка для изолированной и совместной проверки прототипов. Данные обоих режимов используют одно Raven-сохранение."))
	column.add_child(_card(
		"4 · Content Preview",
		"Запустить отдельно любой RM-LVL-001..003 или VN beat RM-BEAT-01-01..05 без изменения общего сохранения.",
		"ВЫБРАТЬ УРОВЕНЬ ИЛИ VN",
		_open.bind(CONTENT_PREVIEW_SCENE)
	))
	column.add_child(_card(
		"1 · Foundation sandbox",
		"Награды 2/2/2, валюта, доступ в спальню, две реставрации, специалист, save/reload и защита от повторной выдачи.",
		"ОТКРЫТЬ СОСТОЯНИЕ",
		_open.bind(FOUNDATION_SCENE)
	))
	column.add_child(_card(
		"2 · Navigation greybox",
		"Hall → Corridor → Bedroom, authored AStar2D graph, hotspots, дверь, foreground и камера. Связано с тем же сохранением.",
		"ОТКРЫТЬ КАРТУ",
		_open.bind(NAVIGATION_SCENE)
	))
	column.add_child(_card(
		"3 · RM-VS-01 vertical slice",
		"Сквозной маршрут: дверь, VN-сцены, три настоящих Match-3 уровня, две реставрации, улика, ночной эпизод и resume из Raven-save.",
		"ЗАПУСТИТЬ ВЕРТИКАЛЬНЫЙ СРЕЗ",
		_open.bind(VERTICAL_SLICE_SCENE)
	))
	column.add_child(_card(
		"Совместная проверка",
		"Vertical slice, Foundation sandbox и карта читают одно сохранение. Начните сквозной flow, затем отдельно проверьте состояние и навигацию.",
		"НАЧАТЬ ОБЩИЙ FLOW",
		_open.bind(VERTICAL_SLICE_SCENE)
	))
	column.add_child(_paragraph("Все режимы запускаются отдельно или вместе из одной web/desktop сборки."))


func _open(path: String) -> void:
	get_tree().change_scene_to_file(path)


func _card(heading: String, description: String, button_text: String, action: Callable) -> PanelContainer:
	var panel := PanelContainer.new(); panel.add_theme_stylebox_override("panel", _panel(Color("202631"), Color("566c67"), 2, 12))
	var box := VBoxContainer.new(); box.add_theme_constant_override("separation", 10); panel.add_child(box)
	var title := _title(heading, 19, Color("f0dfbd")); box.add_child(title)
	box.add_child(_paragraph(description))
	var button := Button.new(); button.text = button_text; button.custom_minimum_size = Vector2(0, 48); button.pressed.connect(action); box.add_child(button)
	return panel


func _title(text: String, size: int, color: Color) -> Label:
	var label := Label.new(); label.text = text; label.add_theme_font_size_override("font_size", size); label.add_theme_color_override("font_color", color); return label


func _paragraph(text: String) -> Label:
	var label := _title(text, 14, Color("d8d0c1")); label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; label.custom_minimum_size = Vector2(0, 54); return label


func _panel(background: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new(); style.bg_color = background; style.border_color = border; style.set_border_width_all(width); style.set_corner_radius_all(radius); style.content_margin_left = 14; style.content_margin_right = 14; style.content_margin_top = 14; style.content_margin_bottom = 14; return style
