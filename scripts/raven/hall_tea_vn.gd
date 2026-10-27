extends Control
## First playable Chapter-II VN pilot. Text is read by stable RM-* line ID.
## Art is deliberately provisional: the atlas-free sprites are NOT yet layered facial rigs.
const SceneId := "RM-BEAT-02-01"
const ScriptData = preload("res://data/raven/production/season1_dialogue_catalog.json")
const CueData = preload("res://data/raven/production/line_performance_cues.json")
const Copy = preload("res://scripts/raven/raven_production_localization.gd")
const Snapshot = preload("res://scripts/raven/raven_snapshot.gd")
const Reducer = preload("res://scripts/raven/raven_reducer.gd")
const Store = preload("res://scripts/raven/raven_campaign_store.gd")
const BG = preload("res://assets/raven/vn_pilot/hall_morning.webp")
const EVELYN = preload("res://assets/raven/vn_pilot/evelyn_relaxed.webp")
const ADA = preload("res://assets/raven/vn_pilot/ada_offer_tea.webp")
const BACK_TO_MAP := "res://scenes/raven/manor_greybox.tscn"

var preferences := Copy.new()
var store := Store.new()
var lines: Array = []
var line_index := 0
var background: TextureRect
var dimmer: ColorRect
var actor_left: TextureRect
var actor_right: TextureRect
var dialogue_panel: Panel
var chapter: Label
var nameplate: Label
var dialogue: Label
var line_progress: Label
var next_button: Button
var back_button: Button
var locale_selector: OptionButton
var note: Label
var focus_tween: Tween


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	clip_contents = true
	for entry: Dictionary in ScriptData.data.entries:
		if entry.sceneId == SceneId:
			lines.append(entry)
	if lines.is_empty():
		push_error("Hall VN pilot cannot find " + SceneId)
		return
	_build_ui()
	resized.connect(_layout)
	_layout()
	_render(true)


func _build_ui() -> void:
	background = TextureRect.new()
	background.texture = BG
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	dimmer = ColorRect.new()
	dimmer.color = Color(0.06, 0.07, 0.10, 0.12)
	dimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dimmer)

	actor_left = _sprite(EVELYN)
	actor_right = _sprite(ADA)
	add_child(actor_left)
	add_child(actor_right)

	var heading_background := ColorRect.new()
	heading_background.name = "HeadingBackground"
	heading_background.color = Color(0.11, 0.08, 0.11, 0.78)
	heading_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(heading_background)

	chapter = _label(17, Color("f8e6bd"))
	chapter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chapter.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(chapter)

	back_button = _button("←")
	back_button.pressed.connect(_back_to_map)
	add_child(back_button)

	locale_selector = OptionButton.new()
	locale_selector.add_item("RU")
	locale_selector.add_item("BE")
	locale_selector.add_item("EN")
	locale_selector.item_selected.connect(_switch_locale)
	locale_selector.tooltip_text = "Language / Мова / Язык"
	add_child(locale_selector)

	dialogue_panel = Panel.new()
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("f3e5ceee")
	panel_style.border_color = Color("b58a56")
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(12)
	dialogue_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(dialogue_panel)

	nameplate = _label(19, Color("eedab3"))
	nameplate.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var plate := StyleBoxFlat.new()
	plate.bg_color = Color("33262d")
	plate.border_color = Color("b58a56")
	plate.set_border_width_all(1)
	plate.set_corner_radius_all(7)
	nameplate.add_theme_stylebox_override("normal", plate)
	dialogue_panel.add_child(nameplate)

	dialogue = _label(19, Color("34252c"))
	dialogue.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dialogue_panel.add_child(dialogue)

	line_progress = _label(12, Color("665044"))
	dialogue_panel.add_child(line_progress)

	next_button = _button("Далее ›")
	next_button.pressed.connect(_next)
	dialogue_panel.add_child(next_button)

	note = _label(11, Color("f6e5c8"))
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(note)


func _sprite(texture: Texture2D) -> TextureRect:
	var sprite := TextureRect.new()
	sprite.texture = texture
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sprite.modulate = Color.WHITE
	return sprite


func _layout() -> void:
	if background == null:
		return
	var w := size.x
	var h := size.y
	background.position = Vector2.ZERO
	background.size = size
	dimmer.position = Vector2.ZERO
	dimmer.size = size
	# Allow characters to overlap the decorative lower text area, without
	# depending on image-baked dialogue or hardcoded 390px screen dimensions.
	var character_width := w * 0.77
	var character_height := h * 0.73
	actor_left.position = Vector2(-w * 0.20, h * 0.125)
	actor_left.size = Vector2(character_width, character_height)
	actor_right.position = Vector2(w * 0.41, h * 0.135)
	actor_right.size = Vector2(character_width, character_height)

	get_node("HeadingBackground").position = Vector2(0, 42)
	get_node("HeadingBackground").size = Vector2(w, 46)
	chapter.position = Vector2(58, 44)
	chapter.size = Vector2(maxf(1, w - 117), 40)
	back_button.position = Vector2(8, 4)
	back_button.size = Vector2(48, 36)
	locale_selector.position = Vector2(maxf(0, w - 106), 4)
	locale_selector.size = Vector2(98, 36)

	var margin := maxf(10, w * 0.035)
	var box_h := maxf(208, minf(h * 0.335, 310))
	dialogue_panel.position = Vector2(margin, h - box_h - 36)
	dialogue_panel.size = Vector2(w - margin * 2, box_h)
	nameplate.position = Vector2(18, -24)
	nameplate.size = Vector2(minf(155, w * 0.37), 40)
	dialogue.position = Vector2(19, 34)
	dialogue.size = Vector2(dialogue_panel.size.x - 38, box_h - 113)
	line_progress.position = Vector2(20, box_h - 39)
	line_progress.size = Vector2(110, 22)
	next_button.position = Vector2(dialogue_panel.size.x - 126, box_h - 49)
	next_button.size = Vector2(110, 38)
	note.position = Vector2(12, h - 27)
	note.size = Vector2(w - 24, 22)


func _render(animate: bool = false) -> void:
	if lines.is_empty():
		return
	var line: Dictionary = lines[line_index]
	var who := str(line.speakerId)
	var lang := preferences.locale
	chapter.text = _scene_title(lang)
	nameplate.text = Copy.speaker_name(who, lang).to_upper()
	dialogue.text = Copy.line_text(str(line.id), lang)
	line_progress.text = "%d / %d" % [line_index + 1, lines.size()]
	next_button.text = {"ru": "Далее ›", "be": "Далей ›", "en": "Next ›"}.get(lang, "Next ›")
	var state: Dictionary = store.load_campaign()
	if state.storyBeatsSeen.has(SceneId):
		note.text = {"ru": "Повторный просмотр", "be": "Паўторны прагляд", "en": "Replay"}.get(lang)
	elif state.storyBeatsSeen.has("RM-BEAT-01-05"):
		note.text = {"ru": "Глава II · Сюжетная сцена", "be": "Раздзел II · Сюжэтная сцэна", "en": "Chapter II · Story scene"}.get(lang)
	else:
		note.text = {"ru": "Демо: прогресс сохранения не меняется", "be": "Дэма: прагрэс не змяняецца", "en": "Preview: no campaign progression"}.get(lang)
	for index in range(3):
		locale_selector.set_item_text(index, ["RU", "BE", "EN"][index])
	locale_selector.select(Copy.SUPPORTED_LOCALES.find(lang))
	if animate:
		_focus_speaker(who)


func _scene_title(lang: String) -> String:
	for scene: Dictionary in ScriptData.data.scenes:
		if scene.sceneId == SceneId:
			var title: String = str(scene.title.get(lang, scene.title.ru))
			return title if not title.is_empty() else str(scene.title.ru)
	return SceneId


func _focus_speaker(who: String) -> void:
	if focus_tween and focus_tween.is_valid():
		focus_tween.kill()
	focus_tween = create_tween()
	focus_tween.set_parallel(true)
	focus_tween.tween_property(actor_left, "modulate", Color(1, 1, 1, 1.0 if who == "RM-CHAR-EVELYN" else 0.65), 0.18)
	focus_tween.tween_property(actor_right, "modulate", Color(1, 1, 1, 1.0 if who == "RM-CHAR-ADA" else 0.65), 0.18)
	# A restrained focus movement is a pilot micro cue. Real facial blink and
	# mouth layers are NOT part of these single-raster generated sprites.


func _switch_locale(selected_index: int) -> void:
	if selected_index < 0 or selected_index >= Copy.SUPPORTED_LOCALES.size():
		return
	if preferences.set_locale(Copy.SUPPORTED_LOCALES[selected_index]) == OK:
		_render(false)


func _next() -> void:
	if line_index < lines.size() - 1:
		line_index += 1
		_render(true)
		return
	_commit_completed_beat()
	_back_to_map()


func _commit_completed_beat() -> void:
	var state: Dictionary = store.load_campaign()
	if not state.storyBeatsSeen.has("RM-BEAT-01-05"):
		return # The launcher permits art/language preview without altering progression.
	if state.storyBeatsSeen.has(SceneId):
		return
	var applied := Reducer.apply(state, {
		"eventId": "chapter-ii-tea-pilot-complete",
		"type": "story_beat_seen",
		"storyBeatId": SceneId
	})
	if applied.ok:
		store.save_campaign(applied.state)
	else:
		push_error("Hall VN story beat rejected: " + str(applied.get("error", "")))


func _back_to_map() -> void:
	get_tree().change_scene_to_file(BACK_TO_MAP)


func _label(font_size: int, color: Color) -> Label:
	var result := Label.new()
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", color)
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return result


func _button(value: String) -> Button:
	var result := Button.new()
	result.text = value
	result.custom_minimum_size = Vector2(45, 36)
	return result
