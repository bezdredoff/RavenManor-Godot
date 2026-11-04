extends Window
## Compact Raven adapter for the UPDS VN configuration controls.
## Campaign state and audio playback remain owned by their existing systems.
signal locale_selected(locale: String)

const COPY := {
	"ru": {"settings": "Настройки", "language": "Язык", "music": "Музыка", "effects": "Эффекты", "mute": "Без звука", "haptics": "Вибрация", "motion": "Уменьшить анимацию", "preview_music": "Проверить музыку", "preview_effects": "Проверить эффекты", "haptics_available": "Вибрация доступна", "haptics_unavailable": "Устройство не поддерживает вибрацию", "close": "Готово", "save_error": "Не удалось сохранить настройки"},
	"be": {"settings": "Налады", "language": "Мова", "music": "Музыка", "effects": "Эфекты", "mute": "Без гуку", "haptics": "Вібрацыя", "motion": "Паменшыць анімацыю", "preview_music": "Праверыць музыку", "preview_effects": "Праверыць эфекты", "haptics_available": "Вібрацыя даступная", "haptics_unavailable": "Прылада не падтрымлівае вібрацыю", "close": "Гатова", "save_error": "Не ўдалося захаваць налады"},
	"en": {"settings": "Settings", "language": "Language", "music": "Music", "effects": "Effects", "mute": "Mute", "haptics": "Haptics", "motion": "Reduce motion", "preview_music": "Preview music", "preview_effects": "Preview effects", "haptics_available": "Haptics available", "haptics_unavailable": "Haptics are not supported on this device", "close": "Done", "save_error": "Could not save settings"},
}

var preferences: Variant
var audio_runtime: Variant
var language: OptionButton
var music: HSlider
var effects: HSlider
var mute: CheckButton
var haptics: CheckButton
var reduced_motion: CheckButton
var save_error: Label
var haptics_capability: Label
var _body: VBoxContainer
var _scroll: ScrollContainer
var _done: Button


func setup(source_preferences: RefCounted, runtime: Variant) -> void:
	preferences = source_preferences
	audio_runtime = runtime
	title = str(COPY.get(preferences.locale, COPY.ru).get("settings", "Settings"))
	min_size = Vector2i(260, 300)
	close_requested.connect(hide)
	_scroll = ScrollContainer.new()
	_scroll.name = "RavenSettingsScroll"
	_scroll.custom_minimum_size = Vector2(230, 240)
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_scroll)
	_body = VBoxContainer.new()
	_body.name = "RavenSettingsControls"
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", 8)
	_scroll.add_child(_body)
	_done = Button.new()
	_done.name = "RavenSettingsDone"
	_done.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_done.pressed.connect(hide)
	add_child(_done)
	language = OptionButton.new()
	language.name = "RavenSettingsLanguage"
	_body.add_child(_label_row("language", language))
	for locale in ["ru", "be", "en"]:
		language.add_item({"ru": "Русский", "be": "Беларуская", "en": "English"}[locale])
		language.set_item_metadata(language.item_count - 1, locale)
	language.item_selected.connect(_select_locale)
	music = _slider_row("music", "RavenSettingsMusic")
	music.value_changed.connect(func(value: float) -> void: _update_audio({"musicVolume": value}))
	effects = _slider_row("effects", "RavenSettingsEffects")
	effects.value_changed.connect(func(value: float) -> void: _update_audio({"effectsVolume": value}))
	mute = _toggle_row("mute", "RavenSettingsMute")
	mute.toggled.connect(func(value: bool) -> void: _update_audio({"muted": value}))
	haptics = _toggle_row("haptics", "RavenSettingsHaptics")
	haptics.toggled.connect(func(value: bool) -> void: _update_audio({"hapticsEnabled": value}))
	haptics_capability = Label.new()
	haptics_capability.name = "RavenHapticsCapability"
	haptics_capability.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.add_child(haptics_capability)
	haptics_capability.add_theme_font_size_override("font_size", 12)
	reduced_motion = _toggle_row("motion", "RavenSettingsReducedMotion")
	reduced_motion.toggled.connect(func(value: bool) -> void: _update_accessibility({"reducedMotion": value}))
	var previews := HBoxContainer.new()
	previews.add_theme_constant_override("separation", 6)
	_body.add_child(previews)
	var preview_music := Button.new()
	preview_music.name = "RavenPreviewMusic"
	preview_music.custom_minimum_size.y = 32
	preview_music.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_music.pressed.connect(Callable(audio_runtime, "preview_music"))
	previews.add_child(preview_music)
	var preview_effects := Button.new()
	preview_effects.name = "RavenPreviewEffects"
	preview_effects.custom_minimum_size.y = 32
	preview_effects.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_effects.pressed.connect(Callable(audio_runtime, "preview_effects"))
	previews.add_child(preview_effects)
	save_error = Label.new()
	save_error.name = "RavenSettingsSaveError"
	save_error.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.add_child(save_error)
	_refresh()
	preferences.locale_changed.connect(func(_locale: String) -> void: _refresh())
	preferences.audio_changed.connect(_refresh)
	preferences.accessibility_changed.connect(_refresh)
	ready.connect(func() -> void: _refresh())


func _label_row(key: String, control: Control) -> VBoxContainer:
	var row := VBoxContainer.new()
	var label := Label.new()
	label.name = "RavenSettings" + key.capitalize() + "Label"
	row.add_child(label)
	row.add_child(control)
	return row


func _slider_row(key: String, node_name: String) -> HSlider:
	var slider := HSlider.new()
	slider.name = node_name
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.custom_minimum_size = Vector2(240, 42)
	_body.add_child(_label_row(key, slider))
	return slider


func _toggle_row(key: String, node_name: String) -> CheckButton:
	var toggle := CheckButton.new()
	toggle.name = node_name
	_body.add_child(toggle)
	return toggle


func _select_locale(index: int) -> void:
	if index < 0 or index >= language.item_count:
		return
	var selected := str(language.get_item_metadata(index))
	var error: Error = preferences.set_locale(selected)
	save_error.text = "" if error == OK else _copy("save_error")
	if error == OK:
		locale_selected.emit(selected)
	_refresh()


func _update_audio(patch: Dictionary) -> void:
	var error: Error = preferences.update_audio(patch)
	save_error.text = "" if error == OK else _copy("save_error")
	_refresh()


func _update_accessibility(patch: Dictionary) -> void:
	var error: Error = preferences.update_accessibility(patch)
	save_error.text = "" if error == OK else _copy("save_error")
	_refresh()


func _copy(key: String) -> String:
	return str(COPY.get(preferences.locale, COPY.ru).get(key, key))


func _refresh() -> void:
	if not is_instance_valid(_body):
		return
	if language == null or music == null or haptics_capability == null:
		return
	title = _copy("settings")
	for index in language.item_count:
		if language.get_item_metadata(index) == preferences.locale:
			language.select(index)
	var words: Dictionary = COPY.get(preferences.locale, COPY.ru)
	(_body.find_child("RavenSettingsLanguageLabel", true, false) as Label).text = str(words.language)
	(_body.find_child("RavenSettingsMusicLabel", true, false) as Label).text = str(words.music)
	(_body.find_child("RavenSettingsEffectsLabel", true, false) as Label).text = str(words.effects)
	var audio: Dictionary = preferences.audio
	music.set_value_no_signal(float(audio.musicVolume))
	effects.set_value_no_signal(float(audio.effectsVolume))
	mute.text = str(words.mute)
	mute.set_pressed_no_signal(bool(audio.muted))
	haptics.text = str(words.haptics)
	haptics.set_pressed_no_signal(bool(audio.hapticsEnabled))
	reduced_motion.text = str(words.motion)
	reduced_motion.set_pressed_no_signal(bool(preferences.accessibility.reducedMotion))
	haptics_capability.text = str(words.haptics_available if audio_runtime.haptics_supported else words.haptics_unavailable)
	var preview_music := _body.find_child("RavenPreviewMusic", true, false) as Button
	var preview_effects := _body.find_child("RavenPreviewEffects", true, false) as Button
	if preview_music != null:
		preview_music.text = str(words.preview_music)
	if preview_effects != null:
		preview_effects.text = str(words.preview_effects)
	_done.text = str(words.close)
