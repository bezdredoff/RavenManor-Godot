extends Control
## First playable Chapter-II VN pilot. Text is read by stable RM-* line ID.
## Art is deliberately provisional: the atlas-free sprites are NOT yet layered facial rigs.
const SceneId := "RM-BEAT-02-01"
const ScriptData = preload("res://data/raven/production/season1_dialogue_catalog.json")
const CueData = preload("res://data/raven/production/line_performance_cues.json")
const Copy = preload("res://scripts/raven/raven_production_localization.gd")
const Paging = preload("res://scripts/shared/upds/dialogue_paging.gd")
const Snapshot = preload("res://scripts/raven/raven_snapshot.gd")
const Reducer = preload("res://scripts/raven/raven_reducer.gd")
const Store = preload("res://scripts/raven/raven_campaign_store.gd")
const VNBackgrounds = preload("res://scripts/raven/raven_vn_backgrounds.gd")
const Characters = preload("res://scripts/raven/raven_vn_characters.gd")
const FxRuntime = preload("res://scripts/raven/raven_vn_fx_runtime.gd")
const BACK_TO_MAP := "res://scenes/raven/manor_greybox.tscn"

var preferences := Copy.new()
var store := Store.new()
var lines: Array = []
var line_index := 0
var dialogue_page := 0
var dialogue_pages: Array[String] = []
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
var _fx: RefCounted = FxRuntime.new()
var _fx_reduced_motion: bool = false
var _fx_skipping: bool = false
var _focus_left_alpha: float = 1.0
var _focus_right_alpha: float = 1.0


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


## No local Studio drafts are loaded. A separate human-approved bundle must
## be explicitly injected; its scene, cast and line IDs are validated.
func configure_reviewed_fx(bundle: Dictionary) -> String:
	if lines.is_empty():
		return "Hall Tea VN must be opened before runtime FX configuration."
	var ids: Array = []
	for entry in lines:
		ids.append(str(entry.get("id", "")))
	var error: String = _fx.configure(SceneId, ids, ["RM-CHAR-EVELYN", "RM-CHAR-ADA"], bundle)
	if not error.is_empty():
		_reset_fx_visuals()
	elif _fx.configured():
		_fx.enter_line(SceneId, str(lines[line_index].get("id", "")))
		_apply_fx_samples(_fx.step(0.0, _fx_skipping, _fx_reduced_motion))
	return error


func set_fx_accessibility(reduced_motion: bool, skipping: bool = false) -> void:
	_fx_reduced_motion = reduced_motion
	_fx_skipping = skipping
	if reduced_motion or skipping:
		_reset_fx_visuals()


func _process(delta: float) -> void:
	if _fx.configured():
		_apply_fx_samples(_fx.step(delta, _fx_skipping, _fx_reduced_motion))
	elif actor_left != null:
		actor_left.modulate.a = _focus_left_alpha
		actor_right.modulate.a = _focus_right_alpha


func _reset_fx_visuals() -> void:
	if background == null:
		return
	_layout()
	background.scale = Vector2.ONE
	background.modulate = Color.WHITE
	for actor in [actor_left, actor_right]:
		actor.scale = Vector2.ONE
	actor_left.modulate = Color(1, 1, 1, _focus_left_alpha)
	actor_right.modulate = Color(1, 1, 1, _focus_right_alpha)


func _apply_fx_samples(samples: Dictionary) -> void:
	_reset_fx_visuals()
	for item in [
		{"node": background, "key": "background/background"},
		{"node": actor_left, "key": "actor/RM-CHAR-EVELYN"},
		{"node": actor_right, "key": "actor/RM-CHAR-ADA"}
	]:
		var sample: Dictionary = samples.get(item["key"], {})
		if sample.is_empty():
			continue
		var target: Control = item["node"]
		target.pivot_offset = target.size * 0.5
		target.position += sample["offset"]
		target.scale *= sample["scale"]
		var tint: Color = target.modulate
		tint.a *= float(sample["alpha"])
		target.modulate = tint


func _build_ui() -> void:
	background = TextureRect.new()
	background.texture = VNBackgrounds.texture_for_scene(SceneId)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	dimmer = ColorRect.new()
	dimmer.color = Color(0.06, 0.07, 0.10, 0.12)
	dimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dimmer)

	actor_left = _sprite(Characters.texture_for_actor({"characterId": "RM-CHAR-EVELYN", "pose": "relaxed", "emotion": "neutral"}))
	actor_right = _sprite(Characters.texture_for_actor({"characterId": "RM-CHAR-ADA", "pose": "offer_tray", "emotion": "neutral"}))
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
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
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

	var heading_bg := get_node("HeadingBackground") as ColorRect
	heading_bg.position = Vector2(0, 42)
	heading_bg.size = Vector2(w, 46)
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
	_fx.enter_line(SceneId, str(line.id))
	var who := str(line.speakerId)
	for actor: Dictionary in Characters.cast_for_scene(SceneId, str(line.id)):
		var image: Texture2D = Characters.texture_for_actor(actor)
		if actor["characterId"] == "RM-CHAR-EVELYN":
			actor_left.texture = image
		elif actor["characterId"] == "RM-CHAR-ADA":
			actor_right.texture = image
	var lang := preferences.locale
	chapter.text = _scene_title(lang)
	nameplate.text = Copy.speaker_name(who, lang).to_upper()
	var full_text := Copy.line_text(str(line.id), lang)
	dialogue_pages = Paging.paginate(full_text, Callable(self, "_fits_dialogue"), lang)
	dialogue_page = mini(dialogue_page, dialogue_pages.size() - 1)
	dialogue.text = Paging.continuation(dialogue_pages[dialogue_page], dialogue_page < dialogue_pages.size() - 1)
	line_progress.text = "%d/%d · %d/%d" % [line_index + 1, lines.size(), dialogue_page + 1, dialogue_pages.size()]
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
	if _fx.configured():
		_apply_fx_samples(_fx.step(0.0, _fx_skipping, _fx_reduced_motion))


func _fits_dialogue(candidate: String) -> bool:
	var font: Font = dialogue.get_theme_font("font")
	var font_size := dialogue.get_theme_font_size("font_size")
	var measured := font.get_multiline_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, maxf(40.0, dialogue.size.x), font_size)
	return measured.y <= dialogue.size.y - 3.0


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
	# Focus alpha is kept separate from additive FX fade alpha to avoid frame drift.
	focus_tween.tween_property(self, "_focus_left_alpha", 1.0 if who == "RM-CHAR-EVELYN" else 0.65, 0.18)
	focus_tween.tween_property(self, "_focus_right_alpha", 1.0 if who == "RM-CHAR-ADA" else 0.65, 0.18)
	# A restrained focus movement is a pilot micro cue. Real facial blink and
	# mouth layers are NOT part of these single-raster generated sprites.


func _switch_locale(selected_index: int) -> void:
	if selected_index < 0 or selected_index >= Copy.SUPPORTED_LOCALES.size():
		return
	if preferences.set_locale(Copy.SUPPORTED_LOCALES[selected_index]) == OK:
		dialogue_page = 0
		_render(false)


func _next() -> void:
	if dialogue_page < dialogue_pages.size() - 1:
		dialogue_page += 1
		_render(false)
		return
	if line_index < lines.size() - 1:
		line_index += 1
		dialogue_page = 0
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
	_fx.clear()
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
