extends Control
## Shared save-neutral visual-novel compositor used by active Raven gameplay.
## Scenes, lighting/state and character slots come from the same staging as VN Studio.
const Backgrounds = preload("res://scripts/raven/raven_vn_backgrounds.gd")
const Characters = preload("res://scripts/raven/raven_vn_characters.gd")
const PortraitLayout = preload("res://scripts/raven/raven_vn_portrait_layout.gd")
const FxRuntime = preload("res://scripts/raven/raven_vn_fx_runtime.gd")
const Copy = preload("res://scripts/raven/raven_production_localization.gd")
const Paging = preload("res://scripts/shared/upds/dialogue_paging.gd")

var scene_id := ""
var background: TextureRect
var missing_background: Label
var actor_layer: Control
var actors: Array[Dictionary] = []
var dialogue_panel: Panel
var chapter: Label
var header_menu: Button
var header_settings: Button
var header_history: Button
var _menu_callback: Callable
var _settings_callback: Callable
var _history_lines: Array[Dictionary] = []
var nameplate: Label
var dialogue: Label
var progress: Label
var next_button: Button
var auto_button: Button
var skip_button: Button
var _auto_timer: Timer
var _auto_mode := false
var _skip_callback: Callable
var _can_skip := false
var _at_checkpoint := false
var pilot_note: Label
var _advance_callback: Callable
var _fx: RefCounted = FxRuntime.new()
var _fx_reduced_motion: bool = false
var _fx_skipping: bool = false
var _full_text := ""
var _display_locale := "ru"
var _line_progress := ""
var _pages: Array[String] = []
var _page_index := 0
var _paging_box_size := Vector2.ZERO
var controls_panel: Panel
var _interaction_blocked := false
var _last_input_msec := -1000
var safe_insets := Vector4.ZERO
const MobileLayout = preload("res://scripts/match3/match3_mobile_layout.gd")
const ShellLayout = preload("res://scripts/shared/upds/vn_shell_layout.gd")


func _init() -> void:
	custom_minimum_size = Vector2(0, 360)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	clip_contents = true


func _ready() -> void:
	_build()
	resized.connect(_layout)
	_layout()


func _build() -> void:
	var dark := ColorRect.new()
	dark.name = "PendingArtBackground"
	dark.color = Color("25202a")
	dark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dark)

	background = TextureRect.new()
	background.name = "GameVNBackground"
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var shade := ColorRect.new()
	shade.name = "VNReadabilityShade"
	shade.color = Color(0.08, 0.07, 0.12, 0.10)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	actor_layer = Control.new()
	actor_layer.name = "VNActors"
	actor_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(actor_layer)

	missing_background = Label.new()
	missing_background.name = "PendingVNArt"
	missing_background.add_theme_color_override("font_color", Color("ecd9bb"))
	missing_background.add_theme_font_size_override("font_size", 14)
	missing_background.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	missing_background.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	missing_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(missing_background)

	var heading := ColorRect.new()
	heading.name = "VNHeadingBar"
	heading.color = Color(0.12, 0.08, 0.12, 0.77)
	heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(heading)
	chapter = _label(15, Color("f8e6bd"))
	chapter.name = "VNSceneTitle"
	chapter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chapter.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	chapter.autowrap_mode = TextServer.AUTOWRAP_OFF
	chapter.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	chapter.clip_text = true
	add_child(chapter)
	# UPDS-godot scripts/vn/vn_screen.gd: top-level VN actions stay in the
	# header, separate from the lower dialogue/nameplate shell.
	header_menu = Button.new()
	header_menu.name = "VNHeaderMenu"
	header_menu.text = "..."
	header_menu.tooltip_text = "Menu"
	header_menu.pressed.connect(func() -> void:
		if _menu_callback.is_valid(): _menu_callback.call())
	add_child(header_menu)
	header_history = Button.new()
	header_history.name = "VNHeaderHistory"
	header_history.text = "Log"
	header_history.tooltip_text = "History"
	header_history.pressed.connect(_show_history)
	add_child(header_history)
	header_settings = Button.new()
	header_settings.name = "VNHeaderSettings"
	header_settings.text = "RU"
	header_settings.tooltip_text = "Settings"
	header_settings.pressed.connect(func() -> void:
		if _settings_callback.is_valid(): _settings_callback.call())
	for action in [header_menu, header_history, header_settings]:
		action.add_theme_font_size_override("font_size", 12)
	add_child(header_settings)

	dialogue_panel = Panel.new()
	dialogue_panel.name = "VNDialoguePanel"
	var style := StyleBoxFlat.new()
	style.bg_color = Color("f3e5ceee")
	style.border_color = Color("b58a56")
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	dialogue_panel.add_theme_stylebox_override("panel", style)
	add_child(dialogue_panel)

	nameplate = _label(17, Color("eedab3"))
	nameplate.name = "VNSpeaker"
	nameplate.clip_text = true
	nameplate.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	nameplate.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nameplate.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var name_style := StyleBoxFlat.new()
	name_style.bg_color = Color("33262d")
	name_style.set_corner_radius_all(7)
	nameplate.add_theme_stylebox_override("normal", name_style)
	dialogue_panel.add_child(nameplate)

	dialogue = _label(17, Color("34252c"))
	dialogue.name = "VNDialogue"
	dialogue.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dialogue_panel.add_child(dialogue)

	progress = _label(12, Color("665044"))
	progress.name = "VNLineProgress"
	dialogue_panel.add_child(progress)
	# UPDS _build_controls: independent bottom strip, outside the text panel.
	controls_panel = Panel.new()
	controls_panel.name = "VNControls"
	var strip := StyleBoxFlat.new()
	strip.bg_color = Color("33262d")
	strip.border_color = Color("b58a56")
	strip.border_width_top = 1
	controls_panel.add_theme_stylebox_override("panel", strip)
	add_child(controls_panel)

	next_button = Button.new()
	next_button.name = "VNNext"
	next_button.text = "Далее ›"
	next_button.custom_minimum_size = Vector2(0, 44)
	next_button.pressed.connect(_advance_from_input)
	controls_panel.add_child(next_button)
	# UPDS VN footer: Auto advances pages and lines, never bypasses a choice.
	auto_button = Button.new()
	auto_button.name = "VNAuto"
	auto_button.text = "Auto"
	auto_button.tooltip_text = "Auto advance dialogue"
	auto_button.pressed.connect(_toggle_auto)
	controls_panel.add_child(auto_button)
	skip_button = Button.new()
	skip_button.name = "VNSkip"
	skip_button.text = "Skip »"
	skip_button.tooltip_text = "Skip previously read lines; stop at unread text or a choice"
	skip_button.pressed.connect(_skip_read_lines)
	controls_panel.add_child(skip_button)
	_auto_timer = Timer.new()
	_auto_timer.one_shot = true
	_auto_timer.timeout.connect(_on_auto_timeout)
	add_child(_auto_timer)
	dialogue_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	dialogue_panel.gui_input.connect(_on_dialogue_gui_input)
	set_process_unhandled_key_input(true)
	visibility_changed.connect(func() -> void:
		if not is_visible_in_tree(): _stop_auto())

	pilot_note = _label(11, Color("f7e7cb"))
	pilot_note.name = "VNArtStatus"
	pilot_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pilot_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(pilot_note)


## A reviewed bundle is injected explicitly; never read editor user:// exports.
## Cast and line IDs are bound to the same canonical scene, not user-supplied paths.
func configure_reviewed_fx(beat_id: String, line_ids: Array, bundle: Dictionary) -> String:
	var allowed_actor_ids: Array = []
	for line_id in line_ids:
		for cast: Dictionary in Characters.cast_for_scene(beat_id, str(line_id)):
			var actor_id: String = str(cast.get("characterId", ""))
			if not actor_id.is_empty() and not allowed_actor_ids.has(actor_id):
				allowed_actor_ids.append(actor_id)
	var error: String = _fx.configure(beat_id, line_ids, allowed_actor_ids, bundle)
	if not error.is_empty():
		_reset_fx_visuals()
	return error


func set_fx_accessibility(reduced_motion: bool, skipping: bool = false) -> void:
	_fx_reduced_motion = reduced_motion
	_fx_skipping = skipping
	if reduced_motion or skipping:
		_reset_fx_visuals()


func clear_reviewed_fx() -> void:
	_fx.clear()
	_reset_fx_visuals()


func _process(delta: float) -> void:
	if not _fx.configured():
		return
	_apply_fx_samples(_fx.step(delta, _fx_skipping, _fx_reduced_motion))


func _reset_fx_visuals() -> void:
	if background == null:
		return
	_layout()
	background.scale = Vector2.ONE
	background.modulate = Color.WHITE
	for actor in actors:
		var visual: Control = actor["node"]
		if is_instance_valid(visual):
			visual.scale = Vector2.ONE
			visual.modulate = Color.WHITE


func _apply_fx_samples(samples: Dictionary) -> void:
	# Always start at canonical layout to avoid transform drift or stale line alpha.
	_reset_fx_visuals()
	if background == null:
		return
	var bg: Dictionary = samples.get("background/background", {})
	if not bg.is_empty():
		_apply_fx_to(background, bg)
	for actor in actors:
		var visual: Control = actor["node"]
		var active: Dictionary = samples.get("actor/" + str(actor["characterId"]), {})
		if is_instance_valid(visual) and not active.is_empty():
			_apply_fx_to(visual, active)


func _apply_fx_to(control: Control, sample: Dictionary) -> void:
	control.pivot_offset = control.size * 0.5
	control.position += sample["offset"]
	control.scale *= sample["scale"]
	var tint: Color = control.modulate
	tint.a *= float(sample["alpha"])
	control.modulate = tint


func set_header_actions(on_menu: Callable, on_settings: Callable, history_lines: Array[Dictionary]) -> void:
	_menu_callback = on_menu
	_settings_callback = on_settings
	_history_lines = history_lines.duplicate(true)


func _show_history() -> void:
	# UPDS history is read-only. Raven supplies already-viewed canonical lines;
	# this view never advances the campaign or writes progress.
	set_interaction_blocked(true)
	var popup := AcceptDialog.new()
	popup.title = {"ru": "История", "be": "Гісторыя", "en": "History"}.get(_display_locale, "History")
	var log := RichTextLabel.new()
	log.bbcode_enabled = false
	log.custom_minimum_size = Vector2(290, 340)
	log.fit_content = false
	for entry in _history_lines:
		log.add_text(str(entry.get("speaker", "")) + ": " + str(entry.get("text", "")) + "\n\n")
	popup.add_child(log)
	add_child(popup)
	popup.popup_centered_ratio(0.85)
	popup.tree_exited.connect(func() -> void: set_interaction_blocked(false))
	popup.confirmed.connect(popup.queue_free)
	popup.canceled.connect(popup.queue_free)


func show_beat(beat_id: String, speaker: String, line_text: String, line_progress: String,
		on_next: Callable, explicit_line_id: String = "", locale: String = "ru") -> void:
	if scene_id != beat_id:
		_fx.reset_clocks()
	scene_id = beat_id
	_advance_callback = on_next
	_display_locale = Copy.normalize_locale(locale)
	_refresh_control_copy()
	_full_text = line_text
	_line_progress = line_progress
	_page_index = 0
	chapter.text = Copy.scene_title(beat_id, _display_locale)
	nameplate.text = speaker.to_upper()
	next_button.text = {"ru": "Далее ›", "be": "Далей ›", "en": "Next ›"}.get(_display_locale, "Next ›")
	var texture: Texture2D = Backgrounds.texture_for_scene(beat_id)
	background.texture = texture
	background.visible = texture != null
	missing_background.visible = texture == null
	var entry: Dictionary = Backgrounds.entry_for_scene(beat_id)
	missing_background.text = "ART PENDING · %s" % str(entry.get("id", beat_id))
	var resolved_line_id: String = explicit_line_id if not explicit_line_id.is_empty() else Characters.line_id_for_text(beat_id, line_text)
	_fill_actors(beat_id, resolved_line_id)
	_fx.enter_line(beat_id, resolved_line_id)
	pilot_note.text = ""
	_layout()
	_repaginate()
	_schedule_auto()
	if _fx.configured():
		_apply_fx_samples(_fx.step(0.0, _fx_skipping, _fx_reduced_motion))


func _fill_actors(beat_id: String, line_id: String = "") -> void:
	for child in actor_layer.get_children():
		actor_layer.remove_child(child)
		child.queue_free()
	actors.clear()
	for cast: Dictionary in Characters.cast_for_scene(beat_id, line_id):
		var character_id := str(cast.get("characterId", ""))
		var slot := str(cast.get("slot", "center"))
		var resolved: Dictionary = Characters.for_actor(cast)
		var art: Texture2D = Characters.texture_for_entry(resolved.get("entry", {}))
		var visual: Control
		if art != null:
			var sprite := TextureRect.new()
			sprite.texture = art
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			visual = sprite
		else:
			var marker := _label(12, Color("f3daba"))
			marker.text = "%s\nART PENDING" % character_id.trim_prefix("RM-CHAR-")
			marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			marker.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			visual = marker
		visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
		actor_layer.add_child(visual)
		actors.append({"node": visual, "slot": slot, "pilot": art != null,
			"characterId": character_id, "asset": resolved.get("entry", {}), "exact": resolved.get("exact", false),
			"x": cast.get("x", PortraitLayout.slot_x(slot)), "y": cast.get("y", 0.5)})


func _layout() -> void:
	if background == null:
		return
	var w := maxf(1.0, size.x)
	var h := maxf(1.0, size.y)
	(get_node("PendingArtBackground") as ColorRect).size = Vector2(w, h)
	background.size = Vector2(w, h)
	(get_node("VNReadabilityShade") as ColorRect).size = Vector2(w, h)
	actor_layer.size = Vector2(w, h)
	for item: Dictionary in actors:
		var visual := item["node"] as Control
		var slot := str(item["slot"])
		if bool(item["pilot"]):
			visual.size = PortraitLayout.actor_size(Vector2(w, h), actors.size())
			visual.position = PortraitLayout.position_for(Vector2(w, h), actors.size(), Vector2(float(item["x"]), float(item["y"])))
		else:
			visual.size = Vector2(w * 0.29, 58)
			visual.position = Vector2(w * (0.02 if slot == "left" else 0.68 if slot == "right" else 0.35), h * 0.48)
	missing_background.position = Vector2(w * 0.05, h * 0.28)
	missing_background.size = Vector2(w * 0.90, 70)
	var insets := safe_insets
	if OS.has_feature("mobile") and not OS.has_feature("web"):
		insets = MobileLayout.native_safe_insets(get_viewport().get_visible_rect().size,
			DisplayServer.screen_get_size(), DisplayServer.get_display_safe_area())
	var layout: Dictionary = ShellLayout.geometry(Vector2(w, h), insets)
	_place(get_node("VNHeadingBar"), layout.header)
	_place(header_menu, layout.menu)
	_place(header_settings, layout.settings)
	_place(header_history, layout.history)
	_place(chapter, layout.title)
	_place(dialogue_panel, layout.dialogue)
	_place(nameplate, layout.nameplate)
	_place(dialogue, layout.text)
	_place(progress, layout.progress)
	_place(controls_panel, layout.controls)
	_place(skip_button, layout.buttons[0])
	_place(auto_button, layout.buttons[1])
	_place(next_button, layout.buttons[2])
	dialogue.add_theme_font_size_override("font_size", 15 if w <= 340 else 18)
	pilot_note.hide()
	# Reflow on viewport resize, without advancing a line or replaying cues.
	if not _full_text.is_empty() and _paging_box_size != dialogue.size:
		_repaginate()


func _fits_dialogue(candidate: String) -> bool:
	var font: Font = dialogue.get_theme_font("font")
	var font_size: int = dialogue.get_theme_font_size("font_size")
	var bounds: Vector2 = font.get_multiline_string_size(candidate,
		HORIZONTAL_ALIGNMENT_LEFT, maxf(40.0, dialogue.size.x - 6), font_size)
	# UPDS _paginate_dialogue: two-line reading window, even on tall screens.
	return bounds.y <= minf(font_size * (1.34 if size.x <= 340 else 1.42) * 2.0 + 7.0,
		maxf(24.0, dialogue.size.y - 6))


func _repaginate() -> void:
	_paging_box_size = dialogue.size
	_pages = Paging.paginate(_full_text, Callable(self, "_fits_dialogue"), _display_locale)
	_page_index = mini(_page_index, maxi(0, _pages.size() - 1))
	_show_page()


func _show_page() -> void:
	if _pages.is_empty():
		if skip_button != null: skip_button.disabled = true
		dialogue.text = ""
		progress.text = _line_progress
		return
	dialogue.text = Paging.continuation(_pages[_page_index], _page_index < _pages.size() - 1)
	progress.text = "%s · %d/%d" % [_line_progress, _page_index + 1, _pages.size()]
	if skip_button != null: skip_button.disabled = not _can_skip or _at_checkpoint
	_schedule_auto()


func set_playback_context(on_skip: Callable, can_skip: bool, at_checkpoint: bool) -> void:
	_skip_callback = on_skip
	_can_skip = can_skip
	_at_checkpoint = at_checkpoint
	skip_button.disabled = not can_skip or at_checkpoint
	_schedule_auto()


func _skip_read_lines() -> void:
	if _interaction_blocked or _at_checkpoint or not _can_skip or not is_visible_in_tree():
		return
	_stop_auto()
	if _skip_callback.is_valid(): _skip_callback.call()


func _toggle_auto() -> void:
	_auto_mode = not _auto_mode
	auto_button.text = _auto_caption()
	_schedule_auto()


func _stop_auto() -> void:
	_auto_mode = false
	if _auto_timer != null: _auto_timer.stop()
	if auto_button != null: auto_button.text = _auto_caption()


func _schedule_auto() -> void:
	if _auto_timer == null: return
	_auto_timer.stop()
	if _auto_mode and is_visible_in_tree() and not _interaction_blocked and not _at_checkpoint and _advance_callback.is_valid():
		# Enough reading time for short/long pages; never fire in same frame.
		_auto_timer.start(2.5 + minf(1800.0, maxf(0.0, dialogue.text.length() - 28) * 18.0) / 1000.0)


func _on_auto_timeout() -> void:
	if _auto_mode and is_visible_in_tree() and not _interaction_blocked and not _at_checkpoint: _next()


func _next() -> void:
	if _interaction_blocked or _at_checkpoint or not is_visible_in_tree():
		return
	if _page_index < _pages.size() - 1:
		_page_index += 1
		_show_page()
	elif _advance_callback.is_valid():
		_advance_callback.call()


func _label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _place(control: Control, rect: Rect2) -> void:
	control.position = rect.position
	control.size = rect.size


func set_interaction_blocked(blocked: bool) -> void:
	_interaction_blocked = blocked
	_schedule_auto()


func _on_dialogue_gui_input(event: InputEvent) -> void:
	# Same 120ms guard as UPDS _next: emulated mouse must not double a touch.
	if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed) or (event is InputEventScreenTouch and event.pressed):
		_advance_from_input()
		get_viewport().set_input_as_handled()


func _advance_from_input() -> void:
	if Time.get_ticks_msec() - _last_input_msec < 120:
		return
	_last_input_msec = Time.get_ticks_msec()
	_next()


func _unhandled_key_input(event: InputEvent) -> void:
	if is_visible_in_tree() and not event.is_echo() and event.is_action_pressed("ui_accept"):
		_advance_from_input()
		get_viewport().set_input_as_handled()


func _auto_caption() -> String:
	var caption: String = {"ru": "Авто", "be": "Аўта", "en": "Auto"}.get(_display_locale, "Auto")
	return caption + (" +" if _auto_mode else "")


func _refresh_control_copy() -> void:
	# The existing Web font lacks the old Unicode menu/history/gear glyphs.
	# Plain text keeps actions legible without adding font or icon assets.
	header_menu.tooltip_text = {"ru": "Меню", "be": "Меню", "en": "Menu"}.get(_display_locale, "Menu")
	header_history.text = {"ru": "Ист.", "be": "Гіст.", "en": "Log"}.get(_display_locale, "Log")
	header_history.tooltip_text = {"ru": "История", "be": "Гісторыя", "en": "History"}.get(_display_locale, "History")
	header_settings.text = _display_locale.to_upper()
	header_settings.tooltip_text = {"ru": "Язык", "be": "Мова", "en": "Language"}.get(_display_locale, "Language")
	skip_button.text = {"ru": "Пропуск", "be": "Пропуск", "en": "Skip"}.get(_display_locale, "Skip")
	skip_button.tooltip_text = {"ru": "Только прочитанные реплики; остановка перед новым текстом и выбором", "be": "Толькі прачытаныя рэплікі; прыпынак перад новым тэкстам і выбарам", "en": "Previously read lines only; stop at unread text and choices"}.get(_display_locale, "")
	auto_button.text = _auto_caption()
	auto_button.tooltip_text = {"ru": "Автоматическое чтение", "be": "Аўтаматычнае чытанне", "en": "Automatic reading"}.get(_display_locale, "Auto")
