extends Control

const FOUNDATION_SCENE := "res://scenes/raven/foundation_lab.tscn"
const NAVIGATION_SCENE := "res://scenes/raven/manor_greybox.tscn"
const WHOLE_MAP_SCENE := "res://scenes/raven/season1_map_greybox.tscn"
const VERTICAL_SLICE_SCENE := "res://scenes/raven/vertical_slice.tscn"
const CONTENT_PREVIEW_SCENE := "res://scenes/raven/content_preview.tscn"
const HALL_TEA_PILOT := "res://scenes/raven/hall_tea_vn.tscn"
const HALL_TEA_WATERCOLOR := "res://scenes/raven/hall_tea_watercolor.tscn"
const BUILDER_GAME_PREVIEW_SCENE := "res://scenes/raven/generated/RM_ROOM_HALL_GamePreview.tscn"


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
		"0 · MATCH-3 QA · АКТУАЛЬНЫЙ ЭКРАН",
		"Открыть RM-LVL-001 сразу, без вступления и прогулки по карте. Это тот же UPDS Match-3 интерфейс, что в RM-VS-01: свайпы, цели, блокеры, спецфишки, подсказки и справка. Режим QA не меняет Raven-save.",
		"ТЕСТИРОВАТЬ MATCH-3 БЕЗ СЮЖЕТА",
		_open_match3_qa
	))
	column.add_child(_card(
		"5 · Whole Manor Map · S1 GREYBOX",
		"Все восемь зон, единая прокручиваемая схема, 11 дверей, габариты ключевой мебели, переходы между помещениями, выбор ремонтных объектов. Тестовая геометрия — НЕ готовая планировка.",
		"ПРОВЕРИТЬ ОБЩУЮ КАРТУ",
		_open.bind(WHOLE_MAP_SCENE)
	))

	if ResourceLoader.exists(BUILDER_GAME_PREVIEW_SCENE):
		column.add_child(_card(
			"6 · Room Builder → Godot · DRAFT",
			"Отдельная импортированная сцена холла: PNG, игровые 65° и расстановка мебели. Это тестовая композиция без сюжетной навигации, коллизий и сохранений.",
			"ПРОВЕРИТЬ ИМПОРТИРОВАННУЮ КОМНАТУ",
			_open.bind(BUILDER_GAME_PREVIEW_SCENE)
		))
	else:
		column.add_child(_paragraph("6 · Room Builder: импортируй экспортированный JSON через import_room_builder_game.py, чтобы создать отдельную проверяемую сцену в Godot."))
	column.add_child(_card(
		"7 · VN Art Pilot · Эвелин и Ада",
		"Живые слои: фон холла, отдельные прозрачные персонажи, 12 канонических реплик 2.1 и RU/BE/EN. Здесь можно открыть демо без влияния на сохранение. В сюжетной карте разговор доступен только после первого акта.",
		"ОТКРЫТЬ VN АРТ-ПРОТОТИП",
		_open.bind(HALL_TEA_PILOT)
	))
	column.add_child(_card(
		"7b · VN Art Pilot · WATERCOLOR",
		"Точная копия сцены Эвелин и Ады с процедурным акварельным шейдером на персонажах и фоне. Сохранение не изменяется.",
		"ОТКРЫТЬ АКВАРЕЛЬНУЮ ВЕРСИЮ",
		_open.bind(HALL_TEA_WATERCOLOR)
	))
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
		"Сюжетный маршрут: письмо → дорога → ворота → возвращение → освобождение двери спальни → первый Match-3. Для быстрого теста Match-3 используй карточку 0 выше. Режим сохраняет прогресс Raven.",
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


func _open_match3_qa() -> void:
	get_tree().set_meta("raven_direct_preview_level", "RM-LVL-001")
	get_tree().change_scene_to_file(CONTENT_PREVIEW_SCENE)


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
