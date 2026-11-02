@tool
extends VBoxContainer
## Project-owned Raven scenario editor. Not a replacement for the actual game runtime.
const Store = preload("res://addons/vn_studio/editor/raven_story_store.gd")
const StageDesigner = preload("res://addons/vn_studio/editor/raven_stage_designer.gd")
const AssetLibrary = preload("res://addons/vn_studio/editor/raven_asset_library.gd")
const LOCALES := ["ru", "be", "en"]
const PANE_SETTING := "vn_studio/raven_scene_pane_width"

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
var _export_stage_v2: Button
var _export_fx: Button
var _stage_designer: Control
var _scene_panel: Control
var _line_panel: Control
var _stage_scroll: ScrollContainer
var _workspace_scroll: ScrollContainer
var _dialogue_scroll: ScrollContainer
var _undo_button: Button
var _redo_button: Button
var _workspace_tabs: TabContainer
var _context_views: Array[RichTextLabel] = []
var _asset_library: Control
var _panel_split: HSplitContainer


func _ready() -> void:
	size_flags_horizontal = SIZE_EXPAND_FILL
	size_flags_vertical = SIZE_EXPAND_FILL
	_build()
	open_raven()


func _build() -> void:
	var sticky := HFlowContainer.new()
	add_child(sticky)
	var sticky_title := Label.new()
	sticky_title.text = "VN Studio · Raven Manor"
	sticky_title.size_flags_horizontal = SIZE_EXPAND_FILL
	sticky.add_child(sticky_title)
	# The whole Raven workspace remains vertically reachable in shorter Godot
	# windows, including heading, toolbar, scene panels and export path.
	_workspace_scroll = ScrollContainer.new()
	_workspace_scroll.size_flags_horizontal = SIZE_EXPAND_FILL
	_workspace_scroll.size_flags_vertical = SIZE_EXPAND_FILL
	_workspace_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	add_child(_workspace_scroll)
	var body := VBoxContainer.new()
	body.custom_minimum_size.y = 720
	body.size_flags_horizontal = SIZE_EXPAND_FILL
	_workspace_scroll.add_child(body)
	var heading := Label.new()
	heading.text = "Raven Manor · собственный сценарий (28 сцен / 280 реплик)"
	heading.add_theme_font_size_override("font_size", 17)
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(heading)
	var toolbar := sticky
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
	_export_stage_v2 = Button.new()
	_export_stage_v2.text = "Экспорт V2 review"
	_export_stage_v2.tooltip_text = "Сохранить отдельный JSON-кандидат ориентации/props/layers в user://"
	_export_stage_v2.pressed.connect(_export_stage_v2_candidate)
	toolbar.add_child(_export_stage_v2)
	_export_fx = Button.new()
	_export_fx.text = "Экспорт FX review"
	_export_fx.tooltip_text = "Локальный кандидат анимаций и постановки, не runtime"
	_export_fx.pressed.connect(_export_fx_candidate)
	toolbar.add_child(_export_fx)
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
	var scene_toggle := Button.new()
	scene_toggle.text = "Скрыть сцены"
	scene_toggle.tooltip_text = "Освободить место для редактора. Повторное нажатие возвращает список."
	scene_toggle.pressed.connect(func():
		_scene_panel.visible = not _scene_panel.visible
		scene_toggle.text = "Скрыть сцены" if _scene_panel.visible else "Показать сцены"
	)
	toolbar.add_child(scene_toggle)
	var lines_toggle := Button.new()
	lines_toggle.text = "Скрыть реплики"
	lines_toggle.tooltip_text = "Освободить место для постановки. Повторное нажатие возвращает список."
	lines_toggle.pressed.connect(func():
		_line_panel.visible = not _line_panel.visible
		lines_toggle.text = "Скрыть реплики" if _line_panel.visible else "Показать реплики"
	)
	toolbar.add_child(lines_toggle)
	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_status)
	var panel := HSplitContainer.new()
	_panel_split = panel
	panel.size_flags_vertical = SIZE_EXPAND_FILL
	panel.size_flags_horizontal = SIZE_EXPAND_FILL
	body.add_child(panel)
	var left := VBoxContainer.new()
	_scene_panel = left
	left.custom_minimum_size.x = 150
	panel.add_child(left)
	if Engine.is_editor_hint():
		var settings := EditorInterface.get_editor_settings()
		if settings.has_setting(PANE_SETTING):
			panel.split_offset = clampi(int(settings.get_setting(PANE_SETTING)), 120, 420)
	panel.dragged.connect(_on_pane_dragged)
	_scenes = ItemList.new()
	_scenes.size_flags_vertical = SIZE_EXPAND_FILL
	_scenes.item_selected.connect(_on_scene)
	left.add_child(_scenes)
	var middle := VBoxContainer.new()
	_line_panel = middle
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
	_workspace_tabs = TabContainer.new()
	_workspace_tabs.size_flags_vertical = SIZE_EXPAND_FILL
	_workspace_tabs.size_flags_horizontal = SIZE_EXPAND_FILL
	editor.add_child(_workspace_tabs)
	var director := VBoxContainer.new()
	director.name = "Director"
	director.size_flags_vertical = SIZE_EXPAND_FILL
	_workspace_tabs.add_child(director)
	var workspace := TabContainer.new()
	workspace.size_flags_vertical = SIZE_EXPAND_FILL
	workspace.size_flags_horizontal = SIZE_EXPAND_FILL
	director.add_child(workspace)
	var dialogue_column := VBoxContainer.new()
	dialogue_column.name = "Диалог"
	dialogue_column.size_flags_vertical = SIZE_EXPAND_FILL
	workspace.add_child(dialogue_column)
	_dialogue_scroll = ScrollContainer.new()
	_dialogue_scroll.size_flags_horizontal = SIZE_EXPAND_FILL
	_dialogue_scroll.size_flags_vertical = SIZE_EXPAND_FILL
	_dialogue_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	dialogue_column.add_child(_dialogue_scroll)
	var text_column := VBoxContainer.new()
	text_column.size_flags_horizontal = SIZE_EXPAND_FILL
	_dialogue_scroll.add_child(text_column)
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
	# Tall art and multiple tool rows need vertical scrolling rather than
	# clipping the asset controls and dialogue preview below the viewport.
	_stage_scroll = ScrollContainer.new()
	_stage_scroll.size_flags_horizontal = SIZE_EXPAND_FILL
	_stage_scroll.size_flags_vertical = SIZE_EXPAND_FILL
	_stage_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	visual_column.add_child(_stage_scroll)
	var stage_contents := VBoxContainer.new()
	stage_contents.size_flags_horizontal = SIZE_EXPAND_FILL
	_stage_scroll.add_child(stage_contents)
	_stage_designer = StageDesigner.new()
	_stage_designer.stage_modified.connect(_on_stage_modified)
	_stage_designer.stage_v2_modified.connect(_on_stage_v2_modified)
	_stage_designer.stage_fx_modified.connect(_on_stage_fx_modified)
	stage_contents.add_child(_stage_designer)
	var visual_label := Label.new()
	visual_label.text = "Фоны: точные состояния из каталога; недоступные — ART PENDING. Не игровой runtime."
	visual_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stage_contents.add_child(visual_label)
	_preview = RichTextLabel.new()
	_preview.custom_minimum_size.y = 140
	_preview.bbcode_enabled = false
	stage_contents.add_child(_preview)
	var library_scroll := ScrollContainer.new()
	library_scroll.name = "Asset Library"
	library_scroll.size_flags_vertical = SIZE_EXPAND_FILL
	library_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_workspace_tabs.add_child(library_scroll)
	_asset_library = AssetLibrary.new()
	_asset_library.custom_minimum_size.x = 230
	library_scroll.add_child(_asset_library)
	for title in ["Story Map", "Animation"]:
		var context_scroll := ScrollContainer.new()
		context_scroll.name = title
		context_scroll.size_flags_vertical = SIZE_EXPAND_FILL
		context_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		_workspace_tabs.add_child(context_scroll)
		var context := RichTextLabel.new()
		context.custom_minimum_size = Vector2(230, 350)
		context.size_flags_horizontal = SIZE_EXPAND_FILL
		context.fit_content = true
		context_scroll.add_child(context)
		_context_views.append(context)
	_path = LineEdit.new()
	_path.editable = false
	_path.placeholder_text = "Путь локального черновика / JSON-кандидата"
	add_child(_path)


func _on_pane_dragged(offset: int) -> void:
	if Engine.is_editor_hint():
		EditorInterface.get_editor_settings().set_setting(PANE_SETTING, clampi(offset, 120, 420))


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
	_stage_designer.set_selected_line(str(_current_entry().get("id", "")))
	_refresh_preview()
	_refresh_context()


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
	_sync_dialogue_preview()
	# A line click changes only editor FX preview time origin; never game progress.
	_stage_designer.set_selected_line(str(e["id"]))
	_refresh_context()


func selected_context() -> Dictionary:
	var entry: Dictionary = _current_entry()
	return {"sceneId": str(entry.get("sceneId", "")) if not entry.is_empty() else "",
		"lineId": str(entry.get("id", "")) if not entry.is_empty() else "",
		"assetInstanceId": ""}


func _refresh_context() -> void:
	if _context_views.size() != 2 or _project.is_empty():
		return
	var scene: Dictionary = _project["scenes"][_scene_idx]
	var scene_id: String = str(scene["sceneId"])
	_asset_library.set_scene_context(scene_id)
	var trigger: Dictionary = _project["routes"].get(scene_id, {})
	_context_views[0].text = "Story Map · %s\n\nТекущий trigger: %s\nПосле сцены: %s\n\nПереходы только для просмотра; редактирование графа — VNS5-06." % [
		scene_id, JSON.stringify(trigger.get("gate", {})), str(trigger.get("postSceneAction", ""))]
	var entry: Dictionary = _current_entry()
	var line_id: String = str(entry.get("id", ""))
	var cue: Dictionary = _project["cues"].get(line_id, {})
	_context_views[1].text = "Animation · %s\n\nПоза: %s\nЭмоция: %s\nМикродвижение: %s\n\nЭто исходный cue только для просмотра. Timeline и clips — VNS5-07." % [
		line_id, str(cue.get("poseId", "—")), str(cue.get("emotionId", "—")), str(cue.get("microOnEnter", "—"))]


func _refresh_preview() -> void:
	var scene: Dictionary = _project["scenes"][_scene_idx]
	var id: String = str(scene["sceneId"])
	var shot: Dictionary = Store.effective_stage(_project, _draft, id)
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
	_sync_dialogue_preview()
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
	_diff.text = "%d изменённых переводов, %d сцен v1, %d сцен v2 · %s" % [
		Store.change_count(_draft), _draft.get("stagePatches", {}).size(), _draft.get("stageV2Patches", {}).size(),
		"есть несохранённые правки" if _dirty else "локально сохранено / без изменений"]


func _refresh_buttons() -> void:
	_save.disabled = _blocked or _project.is_empty()
	_export.disabled = _blocked or _project.is_empty() or Store.change_count(_draft) == 0
	_export_stage.disabled = _blocked or _project.is_empty() or _draft.get("stagePatches", {}).is_empty() or not _draft.get("stageV2Patches", {}).is_empty() or not _draft.get("stageFxPatches", {}).is_empty()
	_export_stage_v2.disabled = _blocked or _project.is_empty() or _draft.get("stageV2Patches", {}).is_empty() or not _draft.get("stageFxPatches", {}).is_empty()
	_export_fx.disabled = _blocked or _project.is_empty() or _draft.get("stageFxPatches", {}).is_empty()
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
	_refresh_context()
	_update_diff()
	_refresh_buttons()


func _on_stage_v2_modified(overlay: Dictionary) -> void:
	if _blocked or _project.is_empty():
		return
	var id: String = str(overlay.get("sceneId", ""))
	var before: Dictionary = _draft.get("stageV2Patches", {}).get(id, {})
	if before == overlay:
		return
	var snapshot: Dictionary = _draft.duplicate(true)
	var error: String = Store.set_stage_v2(_project, _draft, overlay)
	if not error.is_empty():
		_status.text = "V2-постановка не сохранена: " + error
		_stage_designer.set_scene(_project, _draft, str(_project["scenes"][_scene_idx]["sceneId"]))
		return
	_undo.append(snapshot)
	_redo.clear()
	_dirty = true
	_update_diff()
	_refresh_buttons()


func _on_stage_fx_modified(data: Dictionary) -> void:
	if _blocked or _project.is_empty():
		return
	var id: String = str(data.get("sceneId", ""))
	if _draft.get("stageFxPatches", {}).get(id, {}) == data:
		return
	var snapshot: Dictionary = _draft.duplicate(true)
	var error: String = Store.set_stage_fx(_project, _draft, data)
	if not error.is_empty():
		_status.text = "FX не сохранено: " + error
		_stage_designer.set_scene(_project, _draft, str(_project["scenes"][_scene_idx]["sceneId"]))
		return
	_undo.append(snapshot)
	_redo.clear()
	_dirty = true
	_update_diff()
	_refresh_buttons()


func _export_fx_candidate() -> void:
	if _blocked or _project.is_empty() or _draft.get("stageFxPatches", {}).is_empty():
		return
	if _dirty:
		_status.text = "Сначала сохраните локальный черновик, затем экспортируйте FX."
		return
	var result: Dictionary = Store.export_fx_candidate(_project, _draft)
	if result.get("ok", false):
		_status.text = "Создан отдельный FX review candidate (только редактор)."
		_path.text = str(result["path"])
	else:
		_status.text = "FX export заблокирован: " + str(result.get("error", ""))


func _export_stage_v2_candidate() -> void:
	if _blocked or _project.is_empty() or _draft.get("stageV2Patches", {}).is_empty():
		return
	if _dirty:
		_status.text = "Сначала сохраните Raven-черновик, затем экспортируйте V2 review."
		return
	var result: Dictionary = Store.export_v2_candidate(_project, _draft)
	if result.get("ok", false):
		_status.text = "Создан локальный V2 review candidate (не runtime, не production)."
		_path.text = str(result["path"])
	else:
		_status.text = "V2 review export заблокирован: " + str(result.get("error", ""))


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

func _sync_dialogue_preview() -> void:
	if _stage_designer == null or _project.is_empty():
		return
	var entry: Dictionary = _current_entry()
	if entry.is_empty():
		_stage_designer.set_dialogue_preview("", "", "")
		return
	var loc: Dictionary = Store.localized(entry, _draft, _language)
	_stage_designer.set_dialogue_preview(
		str(entry.get("speakerId", "")).trim_prefix("RM-CHAR-"),
		str(loc.get("text", "")), str(entry.get("id", "")))
