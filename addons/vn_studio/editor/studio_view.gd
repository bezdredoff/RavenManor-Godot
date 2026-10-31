@tool
extends Control
## VN-EDITOR-03: local non-destructive authoring overlays over read-only UPDS.

const Reader = preload("res://addons/vn_studio/editor/legacy_reader.gd")
const Drafts = preload("res://addons/vn_studio/editor/draft_store.gd")
const Library = preload("res://addons/vn_studio/editor/character_library.gd")
const StoryGraphView = preload("res://addons/vn_studio/editor/story_graph_view.gd")

var _project: Dictionary = {}
var _current_scene: int = 0
var _current_line: int = 0
var _variant: String = "base"
var _language: String = "ru"

var _choose_folder: EditorFileDialog
var _status: Label
var _scene_list: ItemList
var _scene_filter: LineEdit
var _variant_picker: OptionButton
var _locale_picker: OptionButton
var _line_list: ItemList
var _stage: Control
var _speaker: Label
var _dialogue: Label
var _details: RichTextLabel
var _heading: Label
var _line_indexes: Array[int] = []
var _scene_indexes: Array[int] = []
var _drafts: Dictionary = {}
var _dirty: Dictionary = {}
var _blocked: Dictionary = {}
var _undo_history: Dictionary = {}
var _redo_history: Dictionary = {}
var _suppress_edit_signals: bool = false
var _dragging_actor: int = -1
var _drag_offset: Vector2 = Vector2.ZERO
var _selected_actor: int = 0
var _actor_nodes: Array[Dictionary] = []
var _save_button: Button
var _undo_button: Button
var _redo_button: Button
var _text_edit: TextEdit
var _speaker_edit: LineEdit
var _emotion_edit: LineEdit
var _actor_picker: OptionButton
var _pose_picker: OptionButton

var _library_ids: Array[String] = []
var _catalog_selected: String = ""
var _catalog_pose: String = ""
var _catalog_list: ItemList
var _catalog_gallery: GridContainer
var _catalog_preview: TextureRect
var _catalog_description: Label
var _catalog_apply: Button
var _catalog_motion: OptionButton
var _catalog_reduced_motion: CheckBox
var _catalog_tween: Tween
var _story_graph_view: Control
var _stage_tabs: TabContainer


func _init() -> void:
	name = "VN Studio"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	size_flags_horizontal = SIZE_EXPAND_FILL
	size_flags_vertical = SIZE_EXPAND_FILL


func _ready() -> void:
	_make_ui()


func open_source(folder: String) -> bool:
	if not _dirty.is_empty():
		_status.text = "Есть несохранённые правки. Сохраните черновики перед сменой источника."
		return false
	var result: Dictionary = Reader.read_project(folder)
	if not result.get("ok", false):
		_status.text = str(result.get("error", "Ошибка чтения UPDS-godot"))
		return false
	_project = result
	_drafts.clear()
	_blocked.clear()
	_undo_history.clear()
	_redo_history.clear()
	_current_scene = 0
	_current_line = 0
	_status.text = "Только просмотр · %d сцен · оригинал не изменяется" % _project["scenes"].size()
	_scene_filter.text = ""
	_refresh_scene_list()
	_story_graph_view.set_project(_project)
	_story_graph_view.set_locale(_language)
	_select_scene(0)
	_refresh_library()
	return true


func _make_ui() -> void:
	var outer := VBoxContainer.new()
	outer.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	outer.size_flags_horizontal = SIZE_EXPAND_FILL
	outer.size_flags_vertical = SIZE_EXPAND_FILL
	add_child(outer)

	var toolbar := HBoxContainer.new()
	outer.add_child(toolbar)
	var caption := Label.new()
	caption.text = "VN Studio · Draft Authoring"
	caption.size_flags_horizontal = SIZE_EXPAND_FILL
	caption.add_theme_font_size_override("font_size", 17)
	toolbar.add_child(caption)
	var open_button := Button.new()
	open_button.text = "Выбрать локальную папку UPDS-godot…"
	open_button.pressed.connect(_on_choose_folder)
	toolbar.add_child(open_button)
	_save_button = Button.new()
	_save_button.text = "Сохранить черновик"
	_save_button.pressed.connect(_on_save_draft)
	_save_button.disabled = true
	toolbar.add_child(_save_button)
	_undo_button = Button.new()
	_undo_button.text = "↶ Undo"
	_undo_button.pressed.connect(_on_undo)
	toolbar.add_child(_undo_button)
	_redo_button = Button.new()
	_redo_button.text = "↷ Redo"
	_redo_button.pressed.connect(_on_redo)
	toolbar.add_child(_redo_button)
	var next_button := Button.new()
	next_button.text = "Следующая реплика ▶"
	next_button.pressed.connect(_on_next_line)
	toolbar.add_child(next_button)
	_locale_picker = OptionButton.new()
	for locale in ["RU", "EN", "BE"]:
		_locale_picker.add_item(locale)
	_locale_picker.item_selected.connect(_on_locale_changed)
	toolbar.add_child(_locale_picker)
	_status = Label.new()
	_status.text = "Выберите локальный исходный проект UPDS-godot. Файлы не изменяются."
	outer.add_child(_status)

	var horizontal := HSplitContainer.new()
	horizontal.size_flags_vertical = SIZE_EXPAND_FILL
	horizontal.size_flags_horizontal = SIZE_EXPAND_FILL
	outer.add_child(horizontal)

	var scenes_panel := VBoxContainer.new()
	scenes_panel.custom_minimum_size = Vector2(230, 0)
	horizontal.add_child(scenes_panel)
	var scenes_label := Label.new()
	scenes_label.text = "Сцены (save_contract order)"
	scenes_panel.add_child(scenes_label)
	_scene_filter = LineEdit.new()
	_scene_filter.placeholder_text = "Поиск ID или названия…"
	_scene_filter.text_changed.connect(_on_filter_changed)
	scenes_panel.add_child(_scene_filter)
	_scene_list = ItemList.new()
	_scene_list.size_flags_vertical = SIZE_EXPAND_FILL
	_scene_list.item_selected.connect(_on_scene_selected)
	scenes_panel.add_child(_scene_list)

	var working := HSplitContainer.new()
	working.size_flags_horizontal = SIZE_EXPAND_FILL
	horizontal.add_child(working)

	_stage_tabs = TabContainer.new()
	_stage_tabs.custom_minimum_size = Vector2(380, 0)
	_stage_tabs.size_flags_horizontal = SIZE_EXPAND_FILL
	_stage_tabs.size_flags_vertical = SIZE_EXPAND_FILL
	working.add_child(_stage_tabs)
	var preview_panel := VBoxContainer.new()
	preview_panel.name = "Постановка"
	preview_panel.custom_minimum_size = Vector2(380, 0)
	preview_panel.size_flags_horizontal = SIZE_EXPAND_FILL
	preview_panel.size_flags_vertical = SIZE_EXPAND_FILL
	_stage_tabs.add_child(preview_panel)
	_heading = Label.new()
	_heading.text = "Постановка · предварительный просмотр"
	preview_panel.add_child(_heading)
	var stage_aspect := AspectRatioContainer.new()
	stage_aspect.ratio = 390.0 / 620.0
	stage_aspect.stretch_mode = AspectRatioContainer.STRETCH_FIT
	stage_aspect.size_flags_horizontal = SIZE_EXPAND_FILL
	stage_aspect.size_flags_vertical = SIZE_EXPAND_FILL
	preview_panel.add_child(stage_aspect)
	_stage = Control.new()
	_stage.custom_minimum_size = Vector2(250, 400)
	_stage.clip_contents = true
	_stage.mouse_filter = MOUSE_FILTER_STOP
	_stage.gui_input.connect(_on_stage_input)
	stage_aspect.add_child(_stage)
	var text_box := PanelContainer.new()
	preview_panel.add_child(text_box)
	var text_column := VBoxContainer.new()
	text_box.add_child(text_column)
	_speaker = Label.new()
	_speaker.text = "Говорящий · эмоция"
	text_column.add_child(_speaker)
	_dialogue = Label.new()
	_dialogue.text = "Выберите сцену и реплику."
	_dialogue.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dialogue.custom_minimum_size.y = 70
	text_column.add_child(_dialogue)
	var edit_title := Label.new()
	edit_title.text = "Черновик (текущий язык) · без изменений исходника"
	text_column.add_child(edit_title)
	_speaker_edit = LineEdit.new()
	_speaker_edit.placeholder_text = "Говорящий"
	_speaker_edit.focus_entered.connect(_capture_undo)
	_speaker_edit.text_changed.connect(_on_speaker_changed)
	text_column.add_child(_speaker_edit)
	_emotion_edit = LineEdit.new()
	_emotion_edit.placeholder_text = "Эмоция"
	_emotion_edit.focus_entered.connect(_capture_undo)
	_emotion_edit.text_changed.connect(_on_emotion_changed)
	text_column.add_child(_emotion_edit)
	_text_edit = TextEdit.new()
	_text_edit.custom_minimum_size.y = 92
	_text_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_text_edit.focus_entered.connect(_capture_undo)
	_text_edit.text_changed.connect(_on_text_changed)
	text_column.add_child(_text_edit)
	var actor_row := HBoxContainer.new()
	text_column.add_child(actor_row)
	_actor_picker = OptionButton.new()
	_actor_picker.custom_minimum_size.x = 150
	_actor_picker.item_selected.connect(_on_actor_selected)
	actor_row.add_child(_actor_picker)
	_pose_picker = OptionButton.new()
	_pose_picker.custom_minimum_size.x = 150
	_pose_picker.item_selected.connect(_on_pose_selected)
	actor_row.add_child(_pose_picker)

	_story_graph_view = StoryGraphView.new()
	_story_graph_view.name = "Граф сюжета"
	_story_graph_view.open_scene_requested.connect(_on_graph_scene_requested)
	_stage_tabs.add_child(_story_graph_view)

	var details_panel := VBoxContainer.new()
	details_panel.custom_minimum_size = Vector2(310, 0)
	working.add_child(details_panel)
	var tabs := TabContainer.new()
	tabs.size_flags_vertical = SIZE_EXPAND_FILL
	details_panel.add_child(tabs)
	var dialogue_tab := VBoxContainer.new()
	dialogue_tab.name = "Реплики"
	tabs.add_child(dialogue_tab)
	var line_label := Label.new()
	line_label.text = "Реплики и ветви"
	dialogue_tab.add_child(line_label)
	_variant_picker = OptionButton.new()
	_variant_picker.item_selected.connect(_on_variant_selected)
	dialogue_tab.add_child(_variant_picker)
	_line_list = ItemList.new()
	_line_list.size_flags_vertical = SIZE_EXPAND_FILL
	_line_list.item_selected.connect(_on_line_selected)
	dialogue_tab.add_child(_line_list)
	_details = RichTextLabel.new()
	_details.bbcode_enabled = false
	_details.custom_minimum_size.y = 160
	_details.fit_content = false
	dialogue_tab.add_child(_details)

	var characters_tab := VBoxContainer.new()
	characters_tab.name = "Персонажи"
	tabs.add_child(characters_tab)
	var library_caption := Label.new()
	library_caption.text = "Каталог выбранного UPDS (не импортируется в Raven)"
	characters_tab.add_child(library_caption)
	_catalog_list = ItemList.new()
	_catalog_list.custom_minimum_size.y = 125
	_catalog_list.item_selected.connect(_on_library_character)
	characters_tab.add_child(_catalog_list)
	_catalog_preview = TextureRect.new()
	_catalog_preview.custom_minimum_size.y = 140
	_catalog_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_catalog_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_catalog_preview.size_flags_horizontal = SIZE_EXPAND_FILL
	characters_tab.add_child(_catalog_preview)
	_catalog_description = Label.new()
	_catalog_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_catalog_description.text = "Откройте UPDS-godot для просмотра ассетов."
	characters_tab.add_child(_catalog_description)
	_catalog_apply = Button.new()
	_catalog_apply.text = "Применить изображение к актёру текущей реплики"
	_catalog_apply.disabled = true
	_catalog_apply.pressed.connect(_on_apply_library_pose)
	characters_tab.add_child(_catalog_apply)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 140
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	characters_tab.add_child(scroll)
	_catalog_gallery = GridContainer.new()
	_catalog_gallery.columns = 2
	_catalog_gallery.size_flags_horizontal = SIZE_EXPAND_FILL
	scroll.add_child(_catalog_gallery)
	var animation_caption := Label.new()
	animation_caption.text = "Микродвижения (только предпросмотр, без экспорта)"
	characters_tab.add_child(animation_caption)
	_catalog_motion = OptionButton.new()
	for preset in Library.motion_presets():
		_catalog_motion.add_item(str(preset["name"]))
	_catalog_motion.item_selected.connect(_on_motion_choice)
	characters_tab.add_child(_catalog_motion)
	_catalog_reduced_motion = CheckBox.new()
	_catalog_reduced_motion.text = "Reduced motion · выключить анимации"
	_catalog_reduced_motion.button_pressed = true
	_catalog_reduced_motion.toggled.connect(_on_reduced_motion_changed)
	characters_tab.add_child(_catalog_reduced_motion)

	_choose_folder = EditorFileDialog.new()
	_choose_folder.access = EditorFileDialog.ACCESS_FILESYSTEM
	_choose_folder.file_mode = EditorFileDialog.FILE_MODE_OPEN_DIR
	_choose_folder.title = "Выберите корневую папку отдельного UPDS-godot"
	_choose_folder.dir_selected.connect(_on_folder_chosen)
	add_child(_choose_folder)


func _on_choose_folder() -> void:
	_choose_folder.popup_centered_ratio(0.7)


func _on_folder_chosen(path: String) -> void:
	open_source(path)


func _on_filter_changed(_value: String) -> void:
	_refresh_scene_list()


func _refresh_scene_list() -> void:
	_scene_list.clear()
	_scene_indexes.clear()
	if _project.is_empty():
		return
	var fragment: String = _scene_filter.text.strip_edges().to_lower()
	var all_scenes: Array = _project.get("scenes", [])
	for idx in range(all_scenes.size()):
		var entry: Dictionary = all_scenes[idx]
		var scene: Dictionary = entry.get("data", {})
		var titles: Dictionary = scene.get("titles", {})
		var heading: String = str(titles.get(_language, entry.get("id", "")))
		var display: String = "%02d · %s" % [idx, heading]
		if not fragment.is_empty() and not (str(entry.get("id", "")).to_lower().contains(fragment) or heading.to_lower().contains(fragment)):
			continue
		_scene_list.add_item(display)
		_scene_indexes.append(idx)
		if idx == _current_scene:
			_scene_list.select(_scene_indexes.size() - 1)


func _on_scene_selected(index: int) -> void:
	if index >= 0 and index < _scene_indexes.size():
		_select_scene(_scene_indexes[index])


func _select_scene(index: int) -> void:
	if _project.is_empty():
		return
	var all_scenes: Array = _project.get("scenes", [])
	if index < 0 or index >= all_scenes.size():
		return
	_current_scene = index
	_story_graph_view.focus_scene(str(all_scenes[index].get("id", "")))
	_current_line = 0
	_selected_actor = 0
	_ensure_draft(index)
	var entry: Dictionary = all_scenes[index]
	var groups: Dictionary = entry.get("groups", {})
	_variant_picker.clear()
	var names: Array = groups.keys()
	names.sort()
	for value in names:
		_variant_picker.add_item(str(value))
	_variant = str(names[0]) if not names.is_empty() else "base"
	_variant_picker.select(0)
	_refresh_lines()


func _on_variant_selected(index: int) -> void:
	_variant = _variant_picker.get_item_text(index)
	_current_line = 0
	_refresh_lines()


func _on_locale_changed(index: int) -> void:
	_language = ["ru", "en", "be"][index]
	_story_graph_view.set_locale(_language)
	_refresh_scene_list()
	_refresh_lines()


func _current_entry() -> Dictionary:
	if _project.is_empty():
		return {}
	var scenes: Array = _project.get("scenes", [])
	return scenes[_current_scene] if _current_scene >= 0 and _current_scene < scenes.size() else {}


func _current_lines() -> Array:
	var entry: Dictionary = _current_entry()
	var groups: Dictionary = entry.get("groups", {})
	return groups.get(_variant, [])


func _refresh_lines() -> void:
	_line_list.clear()
	_line_indexes.clear()
	var lines: Array = _current_lines()
	for i in range(lines.size()):
		var line: Dictionary = _effective_line(i)
		var localized: Dictionary = Reader.localize_line(line, _language)
		var prefix: String = "◆" if localized["hidden"] else "●"
		var display: String = "%s %s · %s" % [prefix, localized["id"], localized["speaker"]]
		_line_list.add_item(display)
		_line_indexes.append(i)
	if not lines.is_empty():
		_current_line = clampi(_current_line, 0, lines.size() - 1)
		_line_list.select(_current_line)
	_render_line()


func _on_line_selected(index: int) -> void:
	if index >= 0 and index < _line_indexes.size():
		_current_line = _line_indexes[index]
		_render_line()


func _on_next_line() -> void:
	var lines: Array = _current_lines()
	if lines.is_empty():
		return
	_current_line = mini(_current_line + 1, lines.size() - 1)
	_line_list.select(_current_line)
	_render_line()


func _render_line() -> void:
	for child in _stage.get_children():
		_stage.remove_child(child)
		child.queue_free()
	var entry: Dictionary = _current_entry()
	if entry.is_empty():
		return
	var scene: Dictionary = entry.get("data", {})
	var lines: Array = _current_lines()
	if lines.is_empty():
		_dialogue.text = "Нет реплик в выбранной ветке."
		return
	var line: Dictionary = _effective_line(_current_line)
	var localized: Dictionary = Reader.localize_line(line, _language)
	var titles: Dictionary = scene.get("titles", {})
	_heading.text = "%02d · %s · %s" % [_current_scene, str(titles.get(_language, entry.get("id", ""))), _variant]
	var bg_id: String = str(line.get("background", scene.get("background", "")))
	var root_path: String = str(_project.get("root", ""))
	var catalog: Dictionary = _project.get("catalog", {})
	var bg: Texture2D = Reader.image_for(root_path, catalog, "backgrounds", bg_id)
	if bg != null:
		var background := TextureRect.new()
		background.texture = bg
		background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		background.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
		background.mouse_filter = MOUSE_FILTER_IGNORE
		_stage.add_child(background)
	else:
		var fallback := ColorRect.new()
		fallback.color = Color(0.15, 0.15, 0.2)
		fallback.mouse_filter = MOUSE_FILTER_IGNORE
		fallback.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
		_stage.add_child(fallback)

	_actor_nodes.clear()
	var actor_list: Array = line.get("actors", [])
	var layouts: Dictionary = _project.get("layouts", {})
	var frames: Dictionary = layouts.get("frames", {})
	var places: Dictionary = layouts.get("placements", {})
	var actor_descriptions: Array[String] = []
	for actor_value in actor_list:
		if not actor_value is Dictionary:
			continue
		var actor: Dictionary = actor_value
		var char_id: String = str(actor.get("character", ""))
		var pose: String = str(actor.get("pose", "neutral"))
		var slot: String = str(actor.get("layout", "center"))
		actor_descriptions.append("%s · %s · %s" % [char_id, pose, slot])
		var texture: Texture2D = Reader.image_for(root_path, catalog, "characters", char_id, pose)
		if texture == null:
			var placeholder := ColorRect.new()
			placeholder.color = Color(0.45, 0.34, 0.47, 0.67)
			var cx: float = float(actor.get("vnStudioX", 0.5))
			placeholder.anchor_left = clampf(cx - 0.12, 0.0, 0.76)
			placeholder.anchor_right = placeholder.anchor_left + 0.24
			placeholder.anchor_top = float(actor.get("vnStudioY", 0.22))
			placeholder.anchor_bottom = 0.95
			placeholder.mouse_filter = MOUSE_FILTER_IGNORE
			_stage.add_child(placeholder)
			_actor_nodes.append({"index": actor_list.find(actor_value), "node": placeholder})
			continue
		var position: Dictionary = places.get(slot, {"x": 50.0})
		var calib: Dictionary = frames.get(char_id, {})
		var center_x: float = float(actor.get("vnStudioX", float(position.get("x", 50.0)) / 100.0))
		var top_y: float = float(actor.get("vnStudioY", clampf(float(calib.get("top", 25.0)) / 180.0, 0.0, 0.45)))
		var portrait := TextureRect.new()
		portrait.texture = texture
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.anchor_left = clampf(center_x - 0.22, 0.0, 0.65)
		portrait.anchor_right = clampf(center_x + 0.22, 0.35, 1.0)
		portrait.anchor_top = top_y
		portrait.anchor_bottom = 0.96
		portrait.mouse_filter = MOUSE_FILTER_IGNORE
		_stage.add_child(portrait)
		_actor_nodes.append({"index": actor_list.find(actor_value), "node": portrait})

	_populate_editors(line)
	_speaker.text = str(localized["speaker"]) + " · " + str(localized["emotion"])
	_dialogue.text = "[РЕЖИССУРА — скрыто от игрока] " + str(localized["text"]) if localized["hidden"] else str(localized["text"])
	var details_text: String = "sceneId: " + str(entry.get("id", ""))
	details_text += "\nlineId: " + str(localized["id"])
	details_text += "\nfile: " + str(entry.get("file", ""))
	details_text += "\nфон: " + bg_id
	details_text += "\nперсонажи: " + (", ".join(actor_descriptions) if not actor_descriptions.is_empty() else "за кадром")
	if scene.has("choiceGate"):
		var gate: Dictionary = scene["choiceGate"]
		details_text += "\n\nВыбор: " + str(gate.get("id", ""))
		details_text += "\nКонтрольная реплика: " + str(gate.get("checkpointLineId", ""))
		var opts: Dictionary = gate.get("choices", {})
		details_text += "\nВарианты: " + ", ".join(opts.keys())
	if scene.has("choices"):
		details_text += "\nВетки A/B/C: " + ", ".join(scene.get("choices", {}).keys())
	if scene.has("nextSceneIndices"):
		details_text += "\nПереходы: " + JSON.stringify(scene["nextSceneIndices"])
	if scene.has("nextLevelId"):
		details_text += "\nMatch-3: " + str(scene["nextLevelId"])
	if scene.has("ending"):
		details_text += "\nФинал: " + str(scene["ending"].get("endingId", ""))
	details_text += "\n\nDRAFT ONLY — никаких действий в кампании или UPDS."
	_details.text = details_text
	_update_catalog_action()


func _ensure_draft(scene_index: int) -> void:
	if _drafts.has(scene_index) or _blocked.has(scene_index) or _project.is_empty():
		return
	var entry: Dictionary = _project["scenes"][scene_index]
	var result: Dictionary = Drafts.load_draft(str(_project["root"]), entry)
	if not result.get("ok", false):
		_blocked[scene_index] = str(result.get("error", "Черновик заблокирован."))
	else:
		_drafts[scene_index] = result["draft"]
	_update_status()


func _editable() -> bool:
	return not _project.is_empty() and not _blocked.has(_current_scene) and _drafts.has(_current_scene)


func _effective_line(index: int) -> Dictionary:
	var source: Array = _current_lines()
	if index < 0 or index >= source.size():
		return {}
	var original: Dictionary = source[index]
	if not _editable():
		return original
	return Drafts.materialize(original, _drafts[_current_scene], _variant, index)


func _active_line_id() -> String:
	var lines: Array = _current_lines()
	return str(lines[_current_line].get("id", "")) if _current_line >= 0 and _current_line < lines.size() else ""


func _capture_undo() -> void:
	if not _editable():
		return
	var stack: Array = _undo_history.get(_current_scene, [])
	stack.append(_drafts[_current_scene].duplicate(true))
	if stack.size() > 50:
		stack.pop_front()
	_undo_history[_current_scene] = stack
	_redo_history[_current_scene] = []
	_update_status()


func _record_edit() -> void:
	_dirty[_current_scene] = true
	_update_status()


func _on_speaker_changed(value: String) -> void:
	_update_localized("speaker", value)


func _on_emotion_changed(value: String) -> void:
	_update_localized("emotion", value)


func _on_text_changed() -> void:
	_update_localized("text", _text_edit.text)


func _update_localized(field: String, value: String) -> void:
	if _suppress_edit_signals or not _editable() or _current_lines().is_empty():
		return
	Drafts.set_localized(_drafts[_current_scene], _variant, _current_line, _active_line_id(), _language, field, value)
	_record_edit()
	var locale: Dictionary = Reader.localize_line(_effective_line(_current_line), _language)
	_speaker.text = str(locale["speaker"]) + " · " + str(locale["emotion"])
	_dialogue.text = ("[РЕЖИССУРА] " if locale["hidden"] else "") + str(locale["text"])
	_update_selected_line_label()


func _update_selected_line_label() -> void:
	if _line_list.item_count <= _current_line or _current_line < 0:
		return
	var loc: Dictionary = Reader.localize_line(_effective_line(_current_line), _language)
	_line_list.set_item_text(_current_line, "%s %s · %s" % ["◆" if loc["hidden"] else "●", loc["id"], loc["speaker"]])


func _populate_editors(line: Dictionary) -> void:
	_suppress_edit_signals = true
	var translated: Dictionary = Reader.localize_line(line, _language)
	_speaker_edit.text = str(translated["speaker"])
	_emotion_edit.text = str(translated["emotion"])
	_text_edit.text = str(translated["text"])
	_speaker_edit.editable = _editable()
	_emotion_edit.editable = _editable()
	_text_edit.editable = _editable()
	_actor_picker.clear()
	var actors: Array = line.get("actors", [])
	for actor in actors:
		_actor_picker.add_item(str(actor.get("character", "")))
	_actor_picker.disabled = actors.is_empty() or not _editable()
	if not actors.is_empty():
		_selected_actor = clampi(_selected_actor, 0, actors.size() - 1)
		_actor_picker.select(_selected_actor)
	_update_pose_options(actors)
	_suppress_edit_signals = false
	_update_status()


func _update_pose_options(actors: Array) -> void:
	_pose_picker.clear()
	_pose_picker.disabled = true
	if actors.is_empty():
		return
	var actor: Dictionary = actors[_selected_actor]
	var character: String = str(actor.get("character", ""))
	var catalog: Dictionary = _project.get("catalog", {}).get("characters", {}).get(character, {})
	var names: Array = []
	for id in Library.pose_ids(str(_project.get("root", "")), _project.get("catalog", {}), character):
		names.append(id)
	# Retain a legacy pose if its source asset is missing; do not silently replace it.
	names.sort()
	var current_pose: String = str(actor.get("pose", "neutral"))
	if current_pose not in names:
		names.append(current_pose)
	var current_idx: int = 0
	for pose in names:
		_pose_picker.add_item(str(pose))
		if pose == current_pose:
			current_idx = _pose_picker.item_count - 1
	if _pose_picker.item_count > 0:
		_pose_picker.select(current_idx)
	_pose_picker.disabled = not _editable()


func _on_actor_selected(index: int) -> void:
	_selected_actor = index
	_update_catalog_action()
	_update_pose_options(_effective_line(_current_line).get("actors", []))


func _on_pose_selected(index: int) -> void:
	if not _editable() or _current_lines().is_empty():
		return
	var line: Dictionary = _effective_line(_current_line)
	var actors: Array = line.get("actors", [])
	if _selected_actor < 0 or _selected_actor >= actors.size():
		return
	_capture_undo()
	Drafts.set_actor(_drafts[_current_scene], _variant, _current_line, _active_line_id(), _selected_actor, str(actors[_selected_actor]["character"]), "pose", _pose_picker.get_item_text(index))
	_record_edit()
	_render_line()


func _on_stage_input(event: InputEvent) -> void:
	if not _editable() or _current_lines().is_empty():
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_dragging_actor = -1
			for i in range(_actor_nodes.size() - 1, -1, -1):
				var item: Dictionary = _actor_nodes[i]
				var node: Control = item["node"]
				if node.get_rect().has_point(event.position):
					_dragging_actor = int(item["index"])
					_selected_actor = _dragging_actor
					_drag_offset = node.position + Vector2(node.size.x * 0.5, 0.0) - event.position
					_capture_undo()
					break
		else:
			_dragging_actor = -1
	elif event is InputEventMouseMotion and _dragging_actor >= 0:
		if _stage.size.x <= 0.0 or _stage.size.y <= 0.0:
			return
		var line: Dictionary = _effective_line(_current_line)
		var actors: Array = line.get("actors", [])
		if _dragging_actor >= actors.size():
			return
		var char_id: String = str(actors[_dragging_actor].get("character", ""))
		var pos: Vector2 = event.position + _drag_offset
		var center_x: float = clampf(pos.x / _stage.size.x, 0.22, 0.78)
		var top_y: float = clampf(pos.y / _stage.size.y, 0.02, 0.54)
		Drafts.set_actor(_drafts[_current_scene], _variant, _current_line, _active_line_id(), _dragging_actor, char_id, "x", snappedf(center_x, 0.005))
		Drafts.set_actor(_drafts[_current_scene], _variant, _current_line, _active_line_id(), _dragging_actor, char_id, "y", snappedf(top_y, 0.005))
		_record_edit()
		_render_line()


func _on_undo() -> void:
	if not _editable():
		return
	var stack: Array = _undo_history.get(_current_scene, [])
	if stack.is_empty():
		return
	var redo: Array = _redo_history.get(_current_scene, [])
	redo.append(_drafts[_current_scene].duplicate(true))
	_redo_history[_current_scene] = redo
	_drafts[_current_scene] = stack.pop_back()
	_undo_history[_current_scene] = stack
	_record_edit()
	_refresh_lines()


func _on_redo() -> void:
	if not _editable():
		return
	var stack: Array = _redo_history.get(_current_scene, [])
	if stack.is_empty():
		return
	var undo: Array = _undo_history.get(_current_scene, [])
	undo.append(_drafts[_current_scene].duplicate(true))
	_undo_history[_current_scene] = undo
	_drafts[_current_scene] = stack.pop_back()
	_redo_history[_current_scene] = stack
	_record_edit()
	_refresh_lines()


func _on_save_draft() -> void:
	if not _editable():
		return
	var entry: Dictionary = _current_entry()
	var result: Dictionary = Drafts.save_draft(str(_project["root"]), entry, _drafts[_current_scene])
	if not result.get("ok", false):
		_status.text = str(result.get("error", "Сохранение черновика не удалось."))
		return
	_dirty.erase(_current_scene)
	_update_status()


func _update_status() -> void:
	if _status == null or _project.is_empty():
		return
	if _blocked.has(_current_scene):
		_status.text = "⚠ " + str(_blocked[_current_scene])
	else:
		_status.text = "DRAFT ONLY · %d сцен · %d несохранённых черновиков · оригинал UPDS не изменяется" % [_project["scenes"].size(), _dirty.size()]
	if _save_button != null:
		_save_button.disabled = not _editable() or not _dirty.has(_current_scene)
	if _undo_button != null:
		_undo_button.disabled = not _editable() or _undo_history.get(_current_scene, []).is_empty()
	if _redo_button != null:
		_redo_button.disabled = not _editable() or _redo_history.get(_current_scene, []).is_empty()


func _refresh_library() -> void:
	_library_ids.clear()
	_catalog_list.clear()
	_catalog_selected = ""
	_catalog_pose = ""
	_catalog_preview.texture = null
	_catalog_apply.disabled = true
	if _project.is_empty():
		return
	var catalog: Dictionary = _project.get("catalog", {})
	var root: String = str(_project.get("root", ""))
	_library_ids = Library.character_ids(catalog)
	for char_id in _library_ids:
		_catalog_list.add_item(char_id)
		var portrait_icon: Texture2D = Reader.image_for(root, catalog, "characters", char_id, "icon")
		if portrait_icon != null:
			_catalog_list.set_item_icon(_catalog_list.item_count - 1, portrait_icon)
	if not _library_ids.is_empty():
		_catalog_list.select(0)
		_select_library_character(_library_ids[0])


func _on_library_character(index: int) -> void:
	if index >= 0 and index < _library_ids.size():
		_select_library_character(_library_ids[index])


func _select_library_character(character_id: String) -> void:
	_catalog_selected = character_id
	_catalog_pose = ""
	for child in _catalog_gallery.get_children():
		_catalog_gallery.remove_child(child)
		child.queue_free()
	_catalog_preview.texture = null
	var root: String = str(_project.get("root", ""))
	var assets: Dictionary = _project.get("catalog", {})
	var info: Dictionary = Library.inspect(root, assets, character_id)
	if not info.get("ok", false):
		_catalog_description.text = str(info.get("error", "Ошибка каталога"))
		_update_catalog_action()
		return
	var entries: Array = info["entries"]
	var valid_poses: int = 0
	var unavailable: int = 0
	for entry in entries:
		if entry["kind"] != "portrait":
			continue
		var pose_id: String = str(entry["id"])
		var available: bool = bool(entry["exists"])
		if available:
			valid_poses += 1
		else:
			unavailable += 1
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(138, 132)
		_catalog_gallery.add_child(panel)
		var column := VBoxContainer.new()
		panel.add_child(column)
		var thumbnail := TextureRect.new()
		thumbnail.custom_minimum_size = Vector2(120, 92)
		thumbnail.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		thumbnail.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		thumbnail.texture = Reader.image_for(root, assets, "characters", character_id, pose_id) if available else null
		column.add_child(thumbnail)
		var select_button := Button.new()
		select_button.text = pose_id if available else "⚠ " + pose_id + " · нет файла"
		select_button.disabled = not available
		select_button.pressed.connect(_on_library_pose.bind(pose_id))
		column.add_child(select_button)
	_catalog_description.text = "%s · %d изображений · %d недоступно. Костюмы: нет метаданных. Слои лица: нет. Анимации: нет исходных клипов." % [character_id, valid_poses, unavailable]
	if valid_poses > 0:
		for entry in entries:
			if entry["kind"] == "portrait" and entry["exists"]:
				_on_library_pose(str(entry["id"]))
				break
	else:
		_update_catalog_action()


func _on_library_pose(pose_id: String) -> void:
	_catalog_pose = pose_id
	var root: String = str(_project.get("root", ""))
	var catalog: Dictionary = _project.get("catalog", {})
	_catalog_preview.texture = Reader.image_for(root, catalog, "characters", _catalog_selected, pose_id)
	_update_catalog_action()
	_apply_catalog_motion()


func _update_catalog_action() -> void:
	if _catalog_apply == null:
		return
	_catalog_apply.disabled = true
	if not _editable() or _catalog_pose.is_empty():
		return
	var actors: Array = _effective_line(_current_line).get("actors", [])
	if _selected_actor >= 0 and _selected_actor < actors.size():
		var actor: Dictionary = actors[_selected_actor]
		_catalog_apply.disabled = str(actor.get("character", "")) != _catalog_selected or _catalog_preview.texture == null


func _on_apply_library_pose() -> void:
	if _catalog_apply.disabled or not _editable():
		return
	var actors: Array = _effective_line(_current_line).get("actors", [])
	if _selected_actor < 0 or _selected_actor >= actors.size():
		return
	_capture_undo()
	Drafts.set_actor(_drafts[_current_scene], _variant, _current_line, _active_line_id(), _selected_actor, _catalog_selected, "pose", _catalog_pose)
	_record_edit()
	_render_line()


func _on_motion_choice(_index: int) -> void:
	_apply_catalog_motion()


func _on_reduced_motion_changed(_enabled: bool) -> void:
	_apply_catalog_motion()


func _apply_catalog_motion() -> void:
	# Non-destructive library test animation; never serialized into UPDS drafts.
	if _catalog_tween != null and _catalog_tween.is_valid():
		_catalog_tween.kill()
	_catalog_tween = null
	_catalog_preview.scale = Vector2.ONE
	_catalog_preview.modulate.a = 1.0
	if _catalog_preview.texture == null or _catalog_reduced_motion.button_pressed:
		return
	var preset: int = _catalog_motion.selected
	if preset == 1:
		_catalog_preview.pivot_offset = _catalog_preview.size * 0.5
		_catalog_tween = create_tween().set_loops()
		_catalog_tween.tween_property(_catalog_preview, "scale", Vector2(1.02, 1.02), 0.9).set_trans(Tween.TRANS_SINE)
		_catalog_tween.tween_property(_catalog_preview, "scale", Vector2.ONE, 0.9).set_trans(Tween.TRANS_SINE)
	elif preset == 2:
		_catalog_preview.modulate.a = 0.0
		_catalog_tween = create_tween()
		_catalog_tween.tween_property(_catalog_preview, "modulate:a", 1.0, 0.45).set_trans(Tween.TRANS_SINE)

func _on_graph_scene_requested(index: int) -> void:
	if _project.is_empty():
		return
	_scene_filter.text = ""
	_refresh_scene_list()
	_select_scene(index)
	for i in range(_scene_indexes.size()):
		if _scene_indexes[i] == index:
			_scene_list.select(i)
			break
	_stage_tabs.current_tab = 0
