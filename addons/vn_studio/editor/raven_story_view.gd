@tool
extends VBoxContainer
## Project-owned Raven scenario editor. Not a replacement for the actual game runtime.
const Store = preload("res://addons/vn_studio/editor/raven_story_store.gd")
const StageDesigner = preload("res://addons/vn_studio/editor/raven_stage_designer.gd")
const LOCALES := ["ru", "be", "en"]

var _project: Dictionary = {}
var _draft: Dictionary = {}
var _blocked: bool = true
var _dirty: bool = false
var _scene_idx: int = 0
var _line_idx: int = 0
var _language: String = "ru"
var _suppress: bool = false
var _undo: Array[Dictionary] = []
var _redo: Array[Dictionary] = []
var _scenes: ItemList
var _lines: ItemList
var _locale: OptionButton
var _text_edit: TextEdit
var _heading: Label
var _line_info: Label
var _preview: RichTextLabel
var _status: Label
var _diff: Label
var _path: LineEdit
var _save: Button
var _export: Button
var _export_stage: Button
var _stage_designer: Control
var _undo_button: Button
var _redo_button: Button


func _ready() -> void:
	size_flags_horizontal = SIZE_EXPAND_FILL
	size_flags_vertical = SIZE_EXPAND_FILL
	_build()
	open_raven()


func _build() -> void:
	var heading := Label.new()
	heading.text = "Raven Manor · собственный сценарий (28 сцен / 280 реплик)"
	heading.add_theme_font_size_override("font_size", 17)
	add_child(heading)
	var toolbar := HBoxContainer.new()
	add_child(toolbar)
	var reload := Button.new()
	reload.text = "Перечитать проект"
	reload.pressed.connect(open_raven)
	toolbar.add_child(reload)
	_save = Button.new()
	_save.text = "Сохранить Raven-черновик"
	_save.pressed.connect(_save_local)
	toolbar.add_child(_save)
	_export = Button.new()
	_export.text = "Экспортировать JSON-кандидат"
	_export.pressed.connect(_export_candidate)
	toolbar.add_child(_export)
	_export_stage = Button.new()
	_export_stage.text = "Экспорт постановки JSON"
	_export_stage.pressed.connect(_export_stage_candidate)
	toolbar.add_child(_export_stage)
	_undo_button = Button.new()
	_undo_button.text = "↶"
	_undo_button.tooltip_text = "Отменить правки последнего фокуса"
	_undo_button.pressed.connect(_on_undo)
	toolbar.add_child(_undo_button)
	_redo_button = Button.new()
	_redo_button.text = "↷"
	_redo_button.pressed.connect(_on_redo)
	toolbar.add_child(_redo_button)
	_locale = OptionButton.new()
	for name in ["RU", "BE", "EN"]:
		_locale.add_item(name)
	_locale.item_selected.connect(_on_locale)
	toolbar.add_child(_locale)
	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_status)
	var panel := HSplitContainer.new()
	panel.size_flags_vertical = SIZE_EXPAND_FILL
	panel.size_flags_horizontal = SIZE_EXPAND_FILL
	add_child(panel)
	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 150
	panel.add_child(left)
	_scenes = ItemList.new()
	_scenes.size_flags_vertical = SIZE_EXPAND_FILL
	_scenes.item_selected.connect(_on_scene)
	left.add_child(_scenes)
	var middle := VBoxContainer.new()
	middle.custom_minimum_size.x = 195
	middle.size_flags_horizontal = SIZE_EXPAND_FILL
	panel.add_child(middle)
	_heading = Label.new()
	_heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	middle.add_child(_heading)
	_lines = ItemList.new()
	_lines.size_flags_vertical = SIZE_EXPAND_FILL
	_lines.item_selected.connect(_on_line)
	middle.add_child(_lines)
	var editor := VBoxContainer.new()
	editor.custom_minimum_size.x = 230
	editor.size_flags_horizontal = SIZE_EXPAND_FILL
	panel.add_child(editor)
	_line_info = Label.new()
	_line_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	editor.add_child(_line_info)
	var workspace := TabContainer.new()
	workspace.size_flags_vertical = SIZE_EXPAND_FILL
	workspace.size_flags_horizontal = SIZE_EXPAND_FILL
	editor.add_child(workspace)
	var text_column := VBoxContainer.new()
	text_column.name = "Диалог"
	text_column.size_flags_vertical = SIZE_EXPAND_FILL
	workspace.add_child(text_column)
	_text_edit = TextEdit.new()
	_text_edit.custom_minimum_size.y = 160
	_text_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_text_edit.size_flags_vertical = SIZE_EXPAND_FILL
	_text_edit.focus_entered.connect(_capture_undo)
	_text_edit.text_changed.connect(_on_text_changed)
	text_column.add_child(_text_edit)
	_diff = Label.new()
	_diff.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_column.add_child(_diff)
	var visual_column := VBoxContainer.new()
	visual_column.name = "Постановка"
	visual_column.size_flags_vertical = SIZE_EXPAND_FILL
	workspace.add_child(visual_column)
	_stage_designer = StageDesigner.new()
	_stage_designer.stage_modified.connect(_on_stage_modified)
	visual_column.add_child(_stage_designer)
	var visual_label := Label.new()
	visual_label.text = "Пилотные изображения при наличии; остальное — placeholder. Не игровой runtime."
	visual_column.add_child(visual_label)
	_preview = RichTextLabel.new()
	_preview.custom_minimum_size.y = 140
	_preview.size_flags_vertical = SIZE_EXPAND_FILL
	_preview.bbcode_enabled = false
	visual_column.add_child(_preview)
	_path = LineEdit.new()
	_path.editable = false
	_path.placeholder_text = "Путь локального черновика / JSON-кандидата"
	add_child(_path)


func open_raven() -> void:
	if _dirty:
		_status.text = "Есть несохранённые изменения. Сначала сохраните Raven-черновик; перечитывание заблокировано."
		return
	var root: String = ProjectSettings.globalize_path("res://")
	var candidate: Dictionary = Store.open_project(root)
	if not candidate.get("ok", false):
		_blocked = true
		_status.text = str(candidate.get("error", "Не удалось открыть Raven Manor"))
		_refresh_buttons()
		return
	var loaded: Dictionary = Store.load_draft(candidate)
	_project = candidate
	if not loaded.get("ok", false):
		_blocked = true
		_draft = Store.fresh(candidate)
		_status.text = "Черновик заблокирован: " + str(loaded.get("error", "конфликт"))
	else:
		_blocked = false
		_draft = loaded["draft"]
		_status.text = "Raven: %d сцен / %d реплик. %s" % [
			candidate["sceneCount"], candidate["lineCount"],
			"Локальный черновик восстановлен." if loaded["found"] else "Исходный production draft."]
	_undo.clear()
	_redo.clear()
	_scenes.clear()
	for s in _project["scenes"]:
		_scenes.add_item("%s · %s" % [
			str(s.get("sceneId", "")), str(s.get("title", {}).get("ru", ""))])
	_scene_idx = 0
	_scene_switch()
	_refresh_buttons()


func _scene_switch() -> void:
	if _project.is_empty():
		return
	_scene_idx = clampi(_scene_idx, 0, _project["scenes"].size() - 1)
	_scenes.select(_scene_idx)
	var scene: Dictionary = _project["scenes"][_scene_idx]
	var id: String = str(scene["sceneId"])
	var title: Dictionary = scene.get("title", {})
	_heading.text = "%s · %s\nСтатус: %s" % [id,
		str(title.get(_language, title.get("ru", ""))) if title.get(_language) != null else str(title.get("ru", "")),
		str(scene.get("status", ""))]
	_lines.clear()
	var entries: Array = _project["linesByScene"][id]
	for e in entries:
		var loc: Dictionary = Store.localized(e, _draft, _language)
		_lines.add_item("%s · %s" % [
			str(e["id"]).get_slice("-L", 1),
			str(loc["text"]).replace("\n", " ").left(36)])
	_line_idx = 0
	_line_render()
	_stage_designer.set_scene(_project, _draft, id)
	_refresh_preview()


func _current_entry() -> Dictionary:
	if _project.is_empty():
		return {}
	var id: String = str(_project["scenes"][_scene_idx]["sceneId"])
	var lines: Array = _project["linesByScene"][id]
	return lines[_line_idx] if _line_idx >= 0 and _line_idx < lines.size() else {}


func _line_render() -> void:
	var e: Dictionary = _current_entry()
	if e.is_empty():
		return
	_line_idx = clampi(_line_idx, 0, _project["linesByScene"][str(e["sceneId"])].size() - 1)
	_lines.select(_line_idx)
	var text_value: Dictionary = Store.localized(e, _draft, _language)
	_suppress = true
	_text_edit.text = str(text_value["text"])
	_text_edit.editable = not _blocked
	_suppress = false
	_line_info.text = "%s\nГоворящий: %s · тип: %s\n%s" % [
		str(e["id"]), str(e.get("speakerId", "")),
		str(e.get("delivery", "speech")),
		"⚠ Перевод пока отсутствует — показан RU fallback." if text_value["fallback"] else "Перевод есть / оригинал."]
	var cue: Dictionary = _project["cues"].get(str(e["id"]), {})
	if not cue.is_empty():
		_line_info.text += "\nПоза: %s · эмоция: %s · микро: %s" % [
			str(cue.get("poseId", "")), str(cue.get("emotionId", "")), str(cue.get("microOnEnter", "—"))]
	_update_diff()


func _refresh_preview() -> void:
	var scene: Dictionary = _project["scenes"][_scene_idx]
	var id: String = str(scene["sceneId"])
	var shot: Dictionary = _project["shots"][id]
	var trigger: Dictionary = _project["routes"][id]
	var output: String = "Фон: %s · свет: %s · состояние: %s\n" % [
		str(shot.get("backgroundId", "—")), str(shot.get("lighting", "—")),
		str(shot.get("roomState", "—"))]
	for actor in shot.get("cast", []):
		output += "• %s · %s · %s / %s\n" % [
			str(actor.get("slot", "center")), str(actor.get("characterId", "")),
			str(actor.get("pose", "")), str(actor.get("emotion", ""))]
	var gate: Dictionary = trigger.get("gate", {})
	output += "\nЗапуск: %s · %s\n" % [str(gate.get("kind", "")), str(gate.get("ref", ""))]
	output += "В игре сейчас: %s\n" % ("да" if gate.get("approvedRuntime", false) else "нет, запланировано")
	output += "После сцены: " + str(trigger.get("postSceneAction", ""))
	_preview.text = output


func _on_scene(index: int) -> void:
	_scene_idx = index
	_scene_switch()


func _on_line(index: int) -> void:
	_line_idx = index
	_line_render()


func _on_locale(index: int) -> void:
	_language = LOCALES[index]
	if _project.is_empty():
		return
	_scene_switch()


func _capture_undo() -> void:
	if not _blocked and not _project.is_empty():
		_undo.append(_draft.duplicate(true))
		_redo.clear()
		_refresh_buttons()


func _on_text_changed() -> void:
	if _suppress or _blocked or _project.is_empty():
		return
	var e: Dictionary = _current_entry()
	if e.is_empty():
		return
	Store.edit(_draft, str(e["id"]), _language, _text_edit.text)
	_dirty = true
	_update_diff()
	_refresh_buttons()


func _on_undo() -> void:
	if _undo.is_empty() or _blocked:
		return
	_redo.append(_draft.duplicate(true))
	_draft = _undo.pop_back()
	_dirty = true
	_scene_switch()
	_refresh_buttons()


func _on_redo() -> void:
	if _redo.is_empty() or _blocked:
		return
	_undo.append(_draft.duplicate(true))
	_draft = _redo.pop_back()
	_dirty = true
	_scene_switch()
	_refresh_buttons()


func _update_diff() -> void:
	_diff.text = "%d изменённых переводов, %d сцен постановки · %s" % [
		Store.change_count(_draft), _draft.get("stagePatches", {}).size(), "есть несохранённые правки" if _dirty else "локально сохранено / без изменений"]


func _refresh_buttons() -> void:
	_save.disabled = _blocked or _project.is_empty()
	_export.disabled = _blocked or _project.is_empty() or Store.change_count(_draft) == 0
	_export_stage.disabled = _blocked or _project.is_empty() or _draft.get("stagePatches", {}).is_empty()
	_undo_button.disabled = _blocked or _undo.is_empty()
	_redo_button.disabled = _blocked or _redo.is_empty()


func _save_local() -> void:
	if _blocked or _project.is_empty():
		return
	var result: Dictionary = Store.save_local(_project, _draft)
	if result["ok"]:
		_dirty = false
		_status.text = "Черновик Raven Manor сохранён локально; канонический JSON ещё не изменён."
		_path.text = str(result["path"])
	else:
		_status.text = "Не удалось сохранить: " + str(result.get("error", ""))
	_update_diff()


func _export_candidate() -> void:
	if _blocked or _project.is_empty() or Store.change_count(_draft) == 0:
		return
	if _dirty:
		_status.text = "Перед экспортом сначала сохраните Raven-черновик."
		return
	var result: Dictionary = Store.export_candidate(_project, _draft)
	if result["ok"]:
		_status.text = "Экспортирован кандидат для code review. Игровой сценарий не изменён."
		_path.text = str(result["path"])
	else:
		_status.text = "Экспорт заблокирован: " + str(result.get("error", ""))


func _on_stage_modified(stage: Dictionary) -> void:
	if _blocked or _project.is_empty():
		return
	var old: Dictionary = Store.effective_stage(_project, _draft, str(stage.get("sceneId", "")))
	if old == stage:
		return
	var snapshot: Dictionary = _draft.duplicate(true)
	var error: String = Store.set_stage(_project, _draft, stage)
	if not error.is_empty():
		_status.text = "Ошибка постановки: " + error
		_stage_designer.set_scene(_project, _draft, str(_project["scenes"][_scene_idx]["sceneId"]))
		return
	_undo.append(snapshot)
	_redo.clear()
	_dirty = true
	_refresh_preview()
	_update_diff()
	_refresh_buttons()


func _export_stage_candidate() -> void:
	if _blocked or _project.is_empty() or _draft.get("stagePatches", {}).is_empty():
		return
	if _dirty:
		_status.text = "Сначала сохраните Raven-черновик, затем экспортируйте постановку."
		return
	var result: Dictionary = Store.export_stage_candidate(_project, _draft)
	if result.get("ok", false):
		_status.text = "Экспортирован JSON-кандидат постановки без перезаписи канона."
		_path.text = str(result["path"])
	else:
		_status.text = "Не удалось экспортировать постановку: " + str(result.get("error", ""))
