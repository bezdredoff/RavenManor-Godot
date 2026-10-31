@tool
extends Control
## VN-EDITOR-02: read-only, editor-only inspection of a local UPDS-godot project.
## This preview is deliberately not the production VN renderer or a converter.

const Reader = preload("res://addons/vn_studio/editor/legacy_reader.gd")

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


func _init() -> void:
	name = "VN Studio"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	size_flags_horizontal = SIZE_EXPAND_FILL
	size_flags_vertical = SIZE_EXPAND_FILL


func _ready() -> void:
	_make_ui()


func open_source(folder: String) -> bool:
	var result: Dictionary = Reader.read_project(folder)
	if not result.get("ok", false):
		_status.text = str(result.get("error", "Ошибка чтения UPDS-godot"))
		return false
	_project = result
	_current_scene = 0
	_current_line = 0
	_status.text = "Только просмотр · %d сцен · оригинал не изменяется" % _project["scenes"].size()
	_scene_filter.text = ""
	_refresh_scene_list()
	_select_scene(0)
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
	caption.text = "VN Studio · Legacy Viewer"
	caption.size_flags_horizontal = SIZE_EXPAND_FILL
	caption.add_theme_font_size_override("font_size", 17)
	toolbar.add_child(caption)
	var open_button := Button.new()
	open_button.text = "Выбрать локальную папку UPDS-godot…"
	open_button.pressed.connect(_on_choose_folder)
	toolbar.add_child(open_button)
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

	var preview_panel := VBoxContainer.new()
	preview_panel.custom_minimum_size = Vector2(380, 0)
	preview_panel.size_flags_horizontal = SIZE_EXPAND_FILL
	working.add_child(preview_panel)
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
	_stage.mouse_filter = MOUSE_FILTER_IGNORE
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

	var details_panel := VBoxContainer.new()
	details_panel.custom_minimum_size = Vector2(310, 0)
	working.add_child(details_panel)
	var line_label := Label.new()
	line_label.text = "Реплики и ветви"
	details_panel.add_child(line_label)
	_variant_picker = OptionButton.new()
	_variant_picker.item_selected.connect(_on_variant_selected)
	details_panel.add_child(_variant_picker)
	_line_list = ItemList.new()
	_line_list.size_flags_vertical = SIZE_EXPAND_FILL
	_line_list.item_selected.connect(_on_line_selected)
	details_panel.add_child(_line_list)
	_details = RichTextLabel.new()
	_details.bbcode_enabled = false
	_details.custom_minimum_size.y = 160
	_details.fit_content = false
	details_panel.add_child(_details)

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
	_current_line = 0
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
		var line: Dictionary = lines[i]
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
	var line: Dictionary = lines[_current_line]
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
		fallback.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
		_stage.add_child(fallback)

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
			continue
		var position: Dictionary = places.get(slot, {"x": 50.0})
		var calib: Dictionary = frames.get(char_id, {})
		var center_x: float = float(position.get("x", 50.0)) / 100.0
		var top_y: float = clampf(float(calib.get("top", 25.0)) / 180.0, 0.0, 0.45)
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
	details_text += "\n\nPREVIEW ONLY — никаких действий в кампании."
	_details.text = details_text
