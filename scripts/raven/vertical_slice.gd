extends Control

const Content = preload("res://data/raven/rm_vs_01_content.json")
const Snapshot = preload("res://scripts/raven/raven_snapshot.gd")
const Reducer = preload("res://scripts/raven/raven_reducer.gd")
const Store = preload("res://scripts/raven/raven_campaign_store.gd")
const Director = preload("res://scripts/raven/raven_slice_director.gd")
const Match3 = preload("res://scripts/raven/raven_match3_game.gd")
const Match3Board = preload("res://scripts/match3/match3_board_presenter.gd")
const Match3Theme = preload("res://scripts/raven/raven_match3_theme.gd")
const MobileLayout = preload("res://scripts/match3/match3_mobile_layout.gd")
const ReadHistory = preload("res://scripts/raven/raven_vn_read_history.gd")
const VN = preload("res://scripts/raven/raven_vn_player.gd")
const VNGameView = preload("res://scripts/raven/raven_vn_game_view.gd")
const RuntimeDispatch = preload("res://scripts/raven/raven_vn_runtime_dispatch.gd")
const Copy = preload("res://scripts/raven/raven_production_localization.gd")
const MenuCopy = preload("res://scripts/raven/raven_menu_copy.gd")
const CatalogAdapter = preload("res://scripts/raven/raven_vn_catalog_adapter.gd")
const SettingsDialog = preload("res://scripts/raven/raven_settings_dialog.gd")

var preferences := Copy.new()
var locale_selector: OptionButton
var store := Store.new()
var state := Snapshot.fresh()
var step: Dictionary = {}
var match_game: RefCounted
var vn_player: RefCounted
var vn_view: Control
var selected := -1
var event_serial := 0
var content: Dictionary
var technical_shell: MarginContainer
var vn_frame: Control
var body: VBoxContainer
var status: Label
var pause_dialog: ConfirmationDialog
var settings_dialog: AcceptDialog
const PAUSE_COPY := {
	"ru": ["Пауза", "Сохранить прогресс и выйти в главное меню?", "Сохранить и выйти", "Продолжить", "Не удалось сохранить прогресс. Выход отменён."],
	"be": ["Паўза", "Захаваць прагрэс і выйсці ў галоўнае меню?", "Захаваць і выйсці", "Працягнуць", "Не ўдалося захаваць прагрэс. Выхад скасаваны."],
	"en": ["Pause", "Save progress and return to the main menu?", "Save and exit", "Resume", "Could not save progress. Exit cancelled."]
}


func _ready() -> void:
	content = Content.data
	state = store.load_campaign()
	_build_shell()
	_render()


func _build_shell() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new(); bg.color = Color("0d1118"); bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(bg)
	var margin := MarginContainer.new(); margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	technical_shell = margin
	var insets := Vector4.ZERO
	if OS.has_feature("mobile") and not OS.has_feature("web"):
		insets = MobileLayout.native_safe_insets(
			get_viewport().get_visible_rect().size, DisplayServer.screen_get_size(),
			DisplayServer.get_display_safe_area())
	margin.add_theme_constant_override("margin_left", MobileLayout.gutter(MobileLayout.BASE_GUTTER, insets.x))
	margin.add_theme_constant_override("margin_top", MobileLayout.gutter(MobileLayout.BASE_GUTTER, insets.y))
	margin.add_theme_constant_override("margin_right", MobileLayout.gutter(MobileLayout.BASE_GUTTER, insets.z))
	margin.add_theme_constant_override("margin_bottom", MobileLayout.gutter(MobileLayout.BASE_GUTTER, insets.w))
	add_child(margin)
	var root := VBoxContainer.new(); root.add_theme_constant_override("separation", 10); margin.add_child(root)
	var title := _label("RAVEN MANOR · RM-VS-01", 18, Color("eadbbf")); title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; root.add_child(title)
	status = _label("", 12, Color("9fc8bc")); status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; root.add_child(status)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 10)
	scroll.add_child(body)
	# A two-column footer fits narrow phones without a forced scroll width.
	var footer := GridContainer.new()
	footer.columns = 2
	footer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_theme_constant_override("h_separation", 6)
	footer.add_theme_constant_override("v_separation", 6)
	root.add_child(footer)
	_add_button(footer, "☰ Меню", _open_pause)
	_add_button(footer, MenuCopy.text("settings", preferences.locale), _open_settings)
	_add_button(footer, "Save", _save)
	_add_button(footer, "Reload", _reload)
	_add_button(footer, "Reset", _reset)
	locale_selector = OptionButton.new()
	locale_selector.name = "RavenSliceLocale"
	locale_selector.tooltip_text = "Language / Мова / Язык"
	for code: String in Copy.SUPPORTED_LOCALES:
		locale_selector.add_item({"ru": "Русский", "be": "Беларуская", "en": "English"}[code])
	locale_selector.select(Copy.SUPPORTED_LOCALES.find(preferences.locale))
	locale_selector.item_selected.connect(_switch_locale)
	footer.add_child(locale_selector)
	vn_frame = Control.new()
	vn_frame.name = "GameVNFrame"
	add_child(vn_frame)
	resized.connect(_layout_vn_frame)
	_layout_vn_frame()
	pause_dialog = ConfirmationDialog.new()
	_refresh_pause_copy()
	pause_dialog.confirmed.connect(_save_and_exit)
	pause_dialog.visibility_changed.connect(func() -> void:
		if is_instance_valid(vn_view): vn_view.set_interaction_blocked(pause_dialog.visible))
	locale_selector.get_popup().visibility_changed.connect(func() -> void:
		if is_instance_valid(vn_view): vn_view.set_interaction_blocked(locale_selector.get_popup().visible))
	add_child(pause_dialog)
	settings_dialog = SettingsDialog.new()
	settings_dialog.name = "RavenRuntimeSettings"
	settings_dialog.setup(preferences)
	settings_dialog.locale_selected.connect(_on_settings_locale_selected)
	settings_dialog.visibility_changed.connect(_on_settings_visibility_changed)
	add_child(settings_dialog)
	preferences.accessibility_changed.connect(_apply_accessibility_settings)


func _render() -> void:
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	step = Director.next_step(state)
	if step.get("kind") == "done":
		var approved: Dictionary = RuntimeDispatch.next_scene(state, preferences.locale)
		if not approved.is_empty():
			step = {"id": "production-" + str(approved["beatId"]), "kind": "vn_production",
				"scene": approved["beatId"], "title": approved["title"], "config": approved}
	var is_vn: bool = step.get("kind") in ["vn", "vn_production"]
	technical_shell.visible = not is_vn
	vn_frame.visible = is_vn
	if not is_vn and is_instance_valid(vn_view):
		vn_view.queue_free()
		vn_view = null
	status.add_theme_color_override("font_color", Color("9fc8bc"))
	status.text = "Прогресс %d/%d · очки %d · save rev.%d" % [_step_index(step.id), Director.STEPS.size() - 1, state.workPoints, state.revision]
	var display_title: String = str(step.title)
	if step.get("kind") == "vn":
		var source: Dictionary = content.get("prologueScenes", {}).get(str(step.scene), content.vnScenes.get(str(step.scene), {}))
		display_title = Copy.scene_title(str(source.get("beatId", "")), preferences.locale)
	body.add_child(_label(display_title, 20, Color("f0dfbd")))
	match str(step.kind):
		"map","restore","clue":
			body.add_child(_paragraph(str(step.body)))
			_add_button(body, "ВЫПОЛНИТЬ", _complete_action)
		"vn", "vn_production": _render_vn()
		"match3": _render_match3()
		"done":
			body.add_child(_paragraph(str(step.body)))
			body.add_child(_paragraph("Уровни: %s\nРеставрации: %s\nУлики: %s" % [state.firstClearLevels, state.completedRestorations, state.recordedClues]))
			_add_button(body, "ОТКРЫТЬ КАРТУ", func(): get_tree().change_scene_to_file("res://scenes/raven/manor_greybox.tscn"))


func _render_vn() -> void:
	var scene_id := str(step.scene)
	var config: Dictionary = step["config"] if step.get("kind") == "vn_production" else \
		CatalogAdapter.for_legacy(content.get("prologueScenes", {}).get(scene_id, content.vnScenes.get(scene_id, {})), preferences.locale)
	if vn_player == null or vn_player.scene.get("beatId", "") != config.beatId:
		vn_player = VN.new()
		vn_player.open(config)
		var cursor: Dictionary = state.get("vnCursor", {})
		if str(cursor.get("beatId", "")) == str(config.beatId):
			vn_player.line_index = mini(int(cursor.get("lineIndex", 0)), maxi(0, config.get("lines", []).size() - 1))
	else:
		# Language changes replace copy only, never rewind line or campaign cursor.
		vn_player.scene = config
	if not is_instance_valid(vn_view):
		vn_view = VNGameView.new()
		vn_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		vn_frame.add_child(vn_view)
	var read_lines: Array[Dictionary] = ReadHistory.localized_entries(state.vnReadLines, preferences.locale)
	vn_view.set_header_actions(_open_pause, _open_settings, read_lines)
	vn_view.set_playback_context(_skip_read_vn,
		ReadHistory.skip_target(config, vn_player.line_index, state.vnReadLines) > vn_player.line_index,
		ReadHistory.at_checkpoint(config, vn_player.line_index))
	var line_ids: Array = config.get("lineIds", [])
	var line_id: String = str(line_ids[vn_player.line_index]) if vn_player.line_index < line_ids.size() else ""
	vn_view.show_beat(str(config.beatId), vn_player.current_speaker(), vn_player.current_line(), vn_player.progress_text(), _advance_vn, line_id, preferences.locale)
	_apply_accessibility_settings()


func _layout_vn_frame() -> void:
	# UPDS PhoneFrame max 430×932, centred on desktop; use existing Raven stretch.
	var frame_size := Vector2(minf(size.x, 430.0), minf(size.y, 932.0))
	vn_frame.position = (size - frame_size) * 0.5
	vn_frame.size = frame_size


func _open_vn_settings() -> void:
	_open_settings()


func _open_settings() -> void:
	settings_dialog.popup_centered_ratio(0.9)


func _on_settings_locale_selected(locale: String) -> void:
	var index := Copy.SUPPORTED_LOCALES.find(locale)
	if index >= 0:
		locale_selector.select(index)
		_switch_locale(index)


func _on_settings_visibility_changed() -> void:
	var blocked := settings_dialog.visible
	if is_instance_valid(vn_view):
		vn_view.set_interaction_blocked(blocked)
	var board := find_child("RavenMatch3Board", true, false)
	if board != null and board.has_method("set_interaction_blocked"):
		board.set_interaction_blocked(blocked)


func _apply_accessibility_settings() -> void:
	var reduced_motion := bool(preferences.accessibility.reducedMotion)
	if is_instance_valid(vn_view):
		vn_view.set_fx_accessibility(reduced_motion)
	var board := find_child("RavenMatch3Board", true, false)
	if board != null and board.has_method("set_reduced_motion"):
		board.set_reduced_motion(reduced_motion)


func _render_match3() -> void:
	var level := _level(str(step.level))
	if match_game == null or match_game.level_data.id != level.id:
		match_game = Match3.new(level)
		var checkpoint: Dictionary = state.get("match3Checkpoint", {})
		if str(checkpoint.get("levelId", "")) == str(level.id):
			if not match_game.restore_history(checkpoint.get("actions", [])):
				push_warning("Invalid Match-3 checkpoint; starting level afresh")
		match_game.checkpoint_changed.connect(_checkpoint_match3)
	body.add_child(_paragraph(str(level.get("fiction", "Подготовить работу в комнате."))))
	var board_view := Match3Board.new()
	board_view.name = "RavenMatch3Board"
	body.add_child(board_view)
	board_view.setup(match_game, Match3Theme.placeholder())
	board_view.set_interaction_blocked(is_instance_valid(settings_dialog) and settings_dialog.visible)
	board_view.set_reduced_motion(bool(preferences.accessibility.reducedMotion))
	board_view.level_won.connect(_complete_level)


func _checkpoint_match3() -> void:
	if match_game == null or str(match_game.state) == "won":
		return
	var updated := state.duplicate(true)
	updated.match3Checkpoint = {"levelId": str(step.level), "actions": match_game.move_history.duplicate(true)}
	if store.save_campaign(updated):
		state = updated
	else:
		_show_save_error()

func _complete_level() -> void:
	# Persist the reward and checkpoint removal as one canonical snapshot.
	event_serial += 1
	var event := {"eventId": "vs-%s-%d-%d" % [step.id, state.revision, event_serial],
		"type": "level_won", "levelId": str(step.level)}
	var result: Dictionary = Reducer.apply(state, event)
	if not result.get("ok", false):
		push_error("Match-3 completion rejected")
		return
	var updated: Dictionary = result.state
	updated.match3Checkpoint = {}
	if not store.save_campaign(updated):
		_show_save_error()
		return
	state = updated
	match_game = null
	_render()


func _complete_action() -> void:
	if _apply_events(Director.events_for(str(step.id))):
		_render()


func _advance_vn() -> void:
	if vn_player == null or ReadHistory.at_checkpoint(vn_player.scene, vn_player.line_index):
		return
	var read_id := ReadHistory.current_id(vn_player.scene, vn_player.line_index)
	if vn_player.advance():
		if step.get("kind") == "vn_production":
			var unique_id := "production-%s-%d" % [str(vn_player.scene.beatId), state.revision]
			var event: Dictionary = RuntimeDispatch.completion_event(vn_player.scene, true, unique_id)
			if event.is_empty():
				push_error("Production VN completion rejected")
				vn_player.line_index = maxi(0, vn_player.scene.get("lines", []).size() - 1)
				return
			var reduced: Dictionary = Reducer.apply(state, event)
			if not reduced.get("ok", false):
				push_error("Production VN completion rejected")
				vn_player.line_index = maxi(0, vn_player.scene.get("lines", []).size() - 1)
				return
			var completed: Dictionary = reduced["state"]
			completed.vnCursor = {}
			ReadHistory.mark_read(completed, read_id)
			if not store.save_campaign(completed):
				_show_save_error()
				vn_player.line_index = maxi(0, vn_player.scene.get("lines", []).size() - 1)
				return
			state = completed
		else:
			if not _apply_events([{"type":"story_beat_seen","storyBeatId":str(vn_player.scene.beatId)}], true, read_id):
				vn_player.line_index = maxi(0, vn_player.scene.get("lines", []).size() - 1)
				return
		vn_player = null
	else:
		var updated := state.duplicate(true)
		ReadHistory.mark_read(updated, read_id)
		updated.vnCursor = {"beatId": str(vn_player.scene.beatId), "lineIndex": vn_player.line_index}
		if store.save_campaign(updated):
			state = updated
		else:
			vn_player.line_index = maxi(0, vn_player.line_index - 1)
			_render()
			_show_save_error()
			return
	_render()


func _skip_read_vn() -> void:
	if vn_player == null: return
	var target := ReadHistory.skip_target(vn_player.scene, vn_player.line_index, state.vnReadLines)
	if target <= vn_player.line_index: return
	var updated := state.duplicate(true)
	updated.vnCursor = {"beatId": str(vn_player.scene.beatId), "lineIndex": target}
	if not store.save_campaign(updated):
		_show_save_error()
		return
	state = updated
	vn_player.line_index = target
	_render()


func _apply_events(events: Array, clear_vn_cursor: bool = false, read_id: String = "") -> bool:
	var updated := state.duplicate(true)
	for raw: Dictionary in events:
		event_serial += 1
		var event := raw.duplicate(true)
		event.eventId = "vs-%s-%d-%d" % [step.id, updated.revision, event_serial]
		var result: Dictionary = Reducer.apply(updated, event)
		if not result.get("ok", false):
			push_error("RM-VS-01 event rejected: " + str(result.get("error", "")))
			return false
		updated = result.state
	if clear_vn_cursor:
		updated.vnCursor = {}
		ReadHistory.mark_read(updated, read_id)
	if not store.save_campaign(updated):
		_show_save_error()
		return false
	state = updated
	return true

func _level(id: String) -> Dictionary:
	for item: Dictionary in content.levels:
		if item.id == id: return item
	return {}


func _step_index(current: String) -> int:
	for index in Director.STEPS.size():
		if Director.STEPS[index].id == current: return index
	return 0


func _switch_locale(index: int) -> void:
	if index < 0 or index >= Copy.SUPPORTED_LOCALES.size():
		return
	if preferences.set_locale(Copy.SUPPORTED_LOCALES[index]) == OK:
		_refresh_pause_copy()
		_render()


func _refresh_pause_copy() -> void:
	var copy: Array = PAUSE_COPY.get(preferences.locale, PAUSE_COPY["ru"])
	pause_dialog.title = copy[0]
	pause_dialog.dialog_text = copy[1]
	pause_dialog.ok_button_text = copy[2]
	pause_dialog.cancel_button_text = copy[3]

func _open_pause() -> void:
	_refresh_pause_copy()
	pause_dialog.popup_centered()

func _save_and_exit() -> void:
	if not store.save_campaign(state):
		_show_save_error()
		return
	get_tree().change_scene_to_file("res://scenes/raven/main_menu.tscn")

func _show_save_error() -> void:
	var message := str(PAUSE_COPY.get(preferences.locale, PAUSE_COPY["ru"])[4])
	push_error(message)
	status.text = message
	if is_instance_valid(vn_view):
		vn_view.set_interaction_blocked(true)
		var error := AcceptDialog.new()
		error.dialog_text = message
		add_child(error)
		error.tree_exited.connect(func() -> void:
			if is_instance_valid(vn_view): vn_view.set_interaction_blocked(false))
		error.confirmed.connect(error.queue_free)
		error.canceled.connect(error.queue_free)
		error.popup_centered()
	status.add_theme_color_override("font_color", Color("ffb8b8"))

func _save() -> void:
	if store.save_campaign(state):
		_render()
	else:
		_show_save_error()
func _reload() -> void: state = store.load_campaign(); match_game = null; vn_player = null; _render()
func _reset() -> void:
	if not store.reset_campaign():
		_show_save_error()
		return
	state = Snapshot.fresh()
	match_game = null
	vn_player = null
	_render()


func _add_button(parent: Container, text: String, action: Callable) -> void:
	var button := Button.new(); button.text = text; button.custom_minimum_size = Vector2(0, MobileLayout.MIN_TAP); button.size_flags_horizontal = Control.SIZE_EXPAND_FILL; button.pressed.connect(action); parent.add_child(button)


func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new(); label.text = text; label.add_theme_font_size_override("font_size", size); label.add_theme_color_override("font_color", color); return label


func _paragraph(text: String) -> Label:
	var label := _label(text, 14, Color("d4ccbe")); label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; label.custom_minimum_size = Vector2(0, 54); return label
