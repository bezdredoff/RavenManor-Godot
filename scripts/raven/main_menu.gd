extends Control
## GAME-UI-01: player-facing entry point. Prototype Lab stays one tap away.
const Store = preload("res://scripts/raven/raven_campaign_store.gd")
const Preferences = preload("res://scripts/shared/upds/player_preferences.gd")
const SLICE := "res://scenes/raven/vertical_slice.tscn"
const LAB := "res://scenes/raven/prototype_launcher.tscn"
const COPY := {
	"ru": ["Новая игра", "Продолжить", "Настройки", "Prototype Lab", "Новая игра удалит текущий прогресс. Продолжить?", "Начать", "Отмена", "Язык", "Музыка", "Эффекты", "Без звука", "Вибрация", "Назад", "Не удалось сохранить настройки", "Нет сохранённой игры"],
	"be": ["Новая гульня", "Працягнуць", "Налады", "Prototype Lab", "Новая гульня выдаліць бягучы прагрэс. Працягнуць?", "Пачаць", "Скасаваць", "Мова", "Музыка", "Эфекты", "Без гуку", "Вібрацыя", "Назад", "Не ўдалося захаваць налады", "Няма захаванай гульні"],
	"en": ["New game", "Continue", "Settings", "Prototype Lab", "Starting a new game will erase your progress. Continue?", "Start", "Cancel", "Language", "Music", "Effects", "Mute", "Haptics", "Back", "Could not save settings", "No saved game"]
}
const BACKDROP := "res://assets/raven/vn_backgrounds/road/dusk_mist.webp"
var store := Store.new()
var prefs := Preferences.new()
var column: VBoxContainer
var message: Label
var continue_button: Button
var settings_panel: Control
var confirm: ConfirmationDialog

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var backdrop := TextureRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.texture = load(BACKDROP)
	add_child(backdrop)
	var shade := ColorRect.new()
	shade.color = Color("#180f22c9")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	add_child(margin)
	var center := CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(center)
	column = VBoxContainer.new()
	column.custom_minimum_size = Vector2(270, 0)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 14)
	center.add_child(column)
	var heading := Label.new()
	heading.text = "RAVEN MANOR"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 34)
	heading.add_theme_color_override("font_color", Color("#f0d9a8"))
	column.add_child(heading)
	var rule := HSeparator.new()
	column.add_child(rule)
	_add_action(0, _new_game)
	continue_button = _add_action(1, _continue_game)
	_add_action(2, _show_settings)
	_add_action(3, func(): get_tree().change_scene_to_file(LAB))
	message = Label.new()
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.add_theme_color_override("font_color", Color("#e5c59b"))
	column.add_child(message)
	confirm = ConfirmationDialog.new()
	add_child(confirm)
	confirm.confirmed.connect(_reset_and_start)
	prefs.locale_changed.connect(func(_locale): _refresh())
	_refresh()

func _tr(index: int) -> String:
	return COPY.get(prefs.locale, COPY["ru"])[index]

func _add_action(index: int, callback: Callable) -> Button:
	var button := Button.new()
	button.name = ["NewGame", "Continue", "Settings", "PrototypeLab"][index]
	button.custom_minimum_size.y = 52
	button.add_theme_font_size_override("font_size", 18)
	button.pressed.connect(callback)
	column.add_child(button)
	return button

func _has_progress() -> bool:
	var snapshot: Dictionary = store.load_campaign()
	return int(snapshot.get("revision", 0)) > 0 or not snapshot.get("firstClearLevels", []).is_empty() or not snapshot.get("storyBeatsSeen", []).is_empty() or not snapshot.get("completedRestorations", []).is_empty() or not snapshot.get("appliedEventIds", []).is_empty()

func _refresh() -> void:
	for index in range(4):
		column.get_child(index + 2).text = _tr(index)
	continue_button.disabled = not _has_progress()
	confirm.dialog_text = _tr(4)
	confirm.ok_button_text = _tr(5)
	confirm.cancel_button_text = _tr(6)

func _new_game() -> void:
	if _has_progress():
		confirm.popup_centered()
	else:
		_start()

func _reset_and_start() -> void:
	if not store.reset_campaign():
		message.text = "Could not reset game progress"
		return
	_start()

func _start() -> void:
	get_tree().change_scene_to_file(SLICE)

func _continue_game() -> void:
	if not _has_progress():
		message.text = _tr(14)
		return
	_start()

func _show_settings() -> void:
	column.visible = false
	settings_panel = VBoxContainer.new()
	settings_panel.add_theme_constant_override("separation", 14)
	column.get_parent().add_child(settings_panel)
	_settings_heading(_tr(2))
	var language := OptionButton.new()
	for item in [["Русский", "ru"], ["Беларуская", "be"], ["English", "en"]]:
		language.add_item(item[0])
		language.set_item_metadata(language.item_count - 1, item[1])
		if prefs.locale == item[1]:
			language.select(language.item_count - 1)
	language.item_selected.connect(func(i: int):
		var error := prefs.set_locale(str(language.get_item_metadata(i)))
		if error != OK:
			message.text = _tr(13)
		_close_settings()
		_show_settings()
	)
	_settings_heading(_tr(7))
	settings_panel.add_child(language)
	var audio: Dictionary = prefs.audio
	for field in ["musicVolume", "effectsVolume"]:
		_settings_heading(_tr(8 if field == "musicVolume" else 9))
		var slider := HSlider.new()
		slider.min_value = 0
		slider.max_value = 1
		slider.step = 0.05
		slider.value = float(audio[field])
		slider.custom_minimum_size = Vector2(260, 42)
		slider.value_changed.connect(func(value: float): _update_audio({field: value}))
		settings_panel.add_child(slider)
	for field in ["muted", "hapticsEnabled"]:
		var toggle := CheckButton.new()
		toggle.text = _tr(10 if field == "muted" else 11)
		toggle.button_pressed = bool(audio[field])
		toggle.toggled.connect(func(value: bool): _update_audio({field: value}))
		settings_panel.add_child(toggle)
	var back := Button.new()
	back.text = _tr(12)
	back.custom_minimum_size.y = 52
	back.pressed.connect(_close_settings)
	settings_panel.add_child(back)

func _settings_heading(value: String) -> void:
	var heading := Label.new()
	heading.text = value
	heading.add_theme_color_override("font_color", Color("#f0d9a8"))
	settings_panel.add_child(heading)

func _update_audio(patch: Dictionary) -> void:
	if prefs.update_audio(patch) != OK:
		message.text = _tr(13)

func _close_settings() -> void:
	if is_instance_valid(settings_panel):
		settings_panel.queue_free()
		settings_panel = null
	column.visible = true
	_refresh()
