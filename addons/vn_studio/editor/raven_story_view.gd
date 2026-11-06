@tool
extends VBoxContainer
## Project-owned Raven scenario editor. Not a replacement for the actual game runtime.
signal legacy_tools_requested
const Store = preload("res://addons/vn_studio/editor/raven_story_store.gd")
const QABranch = preload("res://addons/vn_studio/model/raven_qa_branch_demo.gd")
const DraggableLines = preload("res://addons/vn_studio/editor/raven_draggable_lines.gd")
const StageDesigner = preload("res://addons/vn_studio/editor/raven_stage_designer.gd")
const AssetLibrary = preload("res://addons/vn_studio/editor/raven_asset_library.gd")
const RavenGraph = preload("res://addons/vn_studio/editor/raven_story_graph_view.gd")
const PromotionView = preload("res://addons/vn_studio/editor/raven_promotion_review_view.gd")
const LOCALES := ["ru", "be", "en"]
const PANE_SETTING := "vn_studio/raven_scene_pane_width"
const LINE_PANE_SETTING := "vn_studio/raven_line_pane_width"
# v2 deliberately replaces the old narrow 390px default saved by VNS5-07B.
# Any user-adjusted width in the new layout remains persistent.
const STAGE_PANE_SETTING := "vn_studio/raven_stage_pane_width_v2"

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
var _scene_search: LineEdit
var _visible_scene_indices: Array[int] = []
var _lines: ItemList
var _locale: OptionButton
var _text_edit: TextEdit
var _locale_edits: Dictionary = {}
var _locale_status: Dictionary = {}
var _title_edits: Dictionary = {}
var _stage_column: VBoxContainer
var _inspector: VBoxContainer
var _advanced_actions: HFlowContainer
var _qa_demo_button: Button
var _qa_demo_dialog: ConfirmationDialog
var _heading: Label
var _line_info: Label
var _preview: RichTextLabel
var _status: Label
var _diff: Label
var _path: LineEdit
var _recover_button: Button
var _recover_dialog: ConfirmationDialog
var _legacy_tools_button: Button
var _save: Button
var _export: Button
var _export_stage: Button
var _export_stage_v2: Button
var _export_fx: Button
var _export_graph: Button
var _raven_graph: Control
var _promotion_view: Control
var _create_scene_dialog: ConfirmationDialog
var _create_line_dialog: ConfirmationDialog
var _scene_title_input: LineEdit
var _scene_chapter: OptionButton
var _scene_background: OptionButton
var _scene_backgrounds: Array[Dictionary] = []
var _scene_first_line_input: TextEdit
var _line_up: Button
var _line_down: Button
var _line_delete: Button
var _confirm_delete_line: ConfirmationDialog
var _new_line_input: TextEdit
var _scene_speaker: OptionButton
var _line_speaker: OptionButton
var _draft_stage_hint: Label
var _stage_designer: Control
var _scene_panel: Control
var _line_panel: Control
var _stage_scroll: ScrollContainer
var _workspace_scroll: ScrollContainer
var _workspace_body: VBoxContainer
var _story_scroll: ScrollContainer
var _dialogue_scroll: ScrollContainer
var _undo_button: Button
var _redo_button: Button
var _workspace_tabs: TabContainer
var _context_views: Array[RichTextLabel] = []
var _asset_library: Control
var _panel_split: HSplitContainer
var _line_split: HSplitContainer
var _stage_split: HSplitContainer


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
	_legacy_tools_button = Button.new()
	_legacy_tools_button.text = "Инструменты UPDS…"
	_legacy_tools_button.tooltip_text = "Отдельный донорский инструмент, не обязателен для Raven"
	_legacy_tools_button.pressed.connect(func(): legacy_tools_requested.emit())
	sticky.add_child(_legacy_tools_button)
	# The whole Raven workspace remains vertically reachable in shorter Godot
	# windows, including heading, toolbar, scene panels and export path.
	_workspace_scroll = ScrollContainer.new()
	_workspace_scroll.size_flags_horizontal = SIZE_EXPAND_FILL
	_workspace_scroll.size_flags_vertical = SIZE_EXPAND_FILL
	_workspace_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	add_child(_workspace_scroll)
	var body := VBoxContainer.new()
	_workspace_body = body
	body.custom_minimum_size.y = 440
	body.size_flags_horizontal = SIZE_EXPAND_FILL
	body.size_flags_vertical = SIZE_EXPAND_FILL
	_workspace_scroll.add_child(body)
	# ScrollContainer does not distribute spare vertical space to its content.
	# Keep the workspace body at least as tall as the visible scrolling viewport,
	# so the scene/line lists, Stage and inspector really fill the Godot tab.
	_workspace_scroll.resized.connect(_sync_workspace_height)
	var heading := Label.new()
	heading.text = "Raven Manor · 28 исходных сцен / 280 исходных реплик + локальные черновики"
	heading.add_theme_font_size_override("font_size", 17)
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(heading)
	var toolbar := sticky
	_advanced_actions = HFlowContainer.new()
	_advanced_actions.visible = false
	body.add_child(_advanced_actions)
	var exports_toggle := Button.new()
	exports_toggle.text = "Дополнительно…"
	exports_toggle.pressed.connect(func(): _advanced_actions.visible = not _advanced_actions.visible)
	toolbar.add_child(exports_toggle)
	var new_scene_button := Button.new()
	new_scene_button.text = "+ Сцена"
	new_scene_button.tooltip_text = "Создать локальную draft-сцену с одной репликой. Не runtime."
	new_scene_button.pressed.connect(_show_create_scene)
	toolbar.add_child(new_scene_button)
	var new_line_button := Button.new()
	new_line_button.text = "+ Реплика"
	new_line_button.tooltip_text = "Добавить реплику в выбранную сцену, не изменяя production JSON."
	new_line_button.pressed.connect(_show_create_line)
	toolbar.add_child(new_line_button)
	_line_up = Button.new()
	_line_up.text = "↑ Реплика"
	_line_up.tooltip_text = "Изменить порядок черновых реплик; канонические реплики неизменяемы"
	_line_up.pressed.connect(_on_line_up)
	toolbar.add_child(_line_up)
	_line_down = Button.new()
	_line_down.text = "↓ Реплика"
	_line_down.tooltip_text = "Переместить только созданную в редакторе реплику"
	_line_down.pressed.connect(_on_line_down)
	toolbar.add_child(_line_down)
	_line_delete = Button.new()
	_line_delete.text = "− Реплика"
	_line_delete.tooltip_text = "Удалить только черновую реплику; доступна отмена"
	_line_delete.pressed.connect(_request_delete_line)
	toolbar.add_child(_line_delete)
	var reload := Button.new()
	reload.text = "Перечитать проект"
	reload.pressed.connect(open_raven)
	toolbar.add_child(reload)
	_recover_button = Button.new()
	_recover_button.text = "Архивировать старый черновик и начать новый…"
	_recover_button.tooltip_text = "Не переносит правки автоматически; сохраняет неизменённую JSON-копию в user://"
	_recover_button.pressed.connect(_request_stale_recovery)
	_recover_button.visible = false
	toolbar.add_child(_recover_button)
	_recover_dialog = ConfirmationDialog.new()
	_recover_dialog.title = "Raven · безопасное восстановление редактирования"
	_recover_dialog.ok_button_text = "Сохранить копию и начать новый"
	_recover_dialog.dialog_text = "Старый черновик будет скопирован побайтово в отдельную папку восстановления. Новый пустой черновик привяжется к текущему сценарию. Старые правки НЕ будут автоматически перенесены. Для переноса нужен ручной diff. Игровой сценарий и сохранения не меняются."
	_recover_dialog.confirmed.connect(_on_confirm_stale_recovery)
	add_child(_recover_dialog)
	_save = Button.new()
	_save.text = "Сохранить Raven-черновик"
	_save.pressed.connect(_save_local)
	toolbar.add_child(_save)
	_export = Button.new()
	_export.text = "Экспортировать JSON-кандидат"
	_export.pressed.connect(_export_candidate)
	_advanced_actions.add_child(_export)
	_export_stage = Button.new()
	_export_stage.text = "Экспорт постановки JSON"
	_export_stage.pressed.connect(_export_stage_candidate)
	_advanced_actions.add_child(_export_stage)
	_export_stage_v2 = Button.new()
	_export_stage_v2.text = "Экспорт V2 review"
	_export_stage_v2.tooltip_text = "Сохранить отдельный JSON-кандидат ориентации/props/layers в user://"
	_export_stage_v2.pressed.connect(_export_stage_v2_candidate)
	_advanced_actions.add_child(_export_stage_v2)
	_export_fx = Button.new()
	_export_fx.text = "Экспорт FX review"
	_export_fx.tooltip_text = "Локальный кандидат анимаций и постановки, не runtime"
	_export_fx.pressed.connect(_export_fx_candidate)
	_advanced_actions.add_child(_export_fx)
	_export_graph = Button.new()
	_export_graph.text = "Экспорт Story Map review"
	_export_graph.tooltip_text = "No-overwrite candidate; канонические route gates неизменны"
	_export_graph.pressed.connect(_export_graph_candidate)
	_advanced_actions.add_child(_export_graph)
	_qa_demo_button = Button.new()
	_qa_demo_button.text = "QA · выбор 3 героев + FX"
	_qa_demo_button.tooltip_text = "Добавить четыре сцены в конец локального черновика: A/B/C → Эвелин/Ада/Роуэн → возврат. Не runtime."
	_qa_demo_button.pressed.connect(_request_qa_demo)
	_advanced_actions.add_child(_qa_demo_button)
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
	_build_authoring_dialogs()
	var panel := HSplitContainer.new()
	_panel_split = panel
	panel.split_offset = 145
	panel.size_flags_vertical = SIZE_EXPAND_FILL
	panel.size_flags_horizontal = SIZE_EXPAND_FILL
	body.add_child(panel)
	var left := VBoxContainer.new()
	_scene_panel = left
	left.custom_minimum_size.x = 110
	panel.add_child(left)
	if Engine.is_editor_hint():
		var settings := EditorInterface.get_editor_settings()
		if settings.has_setting(PANE_SETTING):
			panel.split_offset = clampi(int(settings.get_setting(PANE_SETTING)), 120, 420)
	panel.dragged.connect(_on_pane_dragged)
	_scene_search = LineEdit.new()
	_scene_search.placeholder_text = "Найти сцену / ID…"
	_scene_search.clear_button_enabled = true
	_scene_search.text_changed.connect(func(_value: String): _refresh_scene_items())
	left.add_child(_scene_search)
	_scenes = ItemList.new()
	_scenes.size_flags_vertical = SIZE_EXPAND_FILL
	_scenes.item_selected.connect(_on_scene)
	left.add_child(_scenes)
	var line_split := HSplitContainer.new()
	_line_split = line_split
	line_split.split_offset = 175
	line_split.size_flags_horizontal = SIZE_EXPAND_FILL
	line_split.size_flags_vertical = SIZE_EXPAND_FILL
	panel.add_child(line_split)
	var middle := VBoxContainer.new()
	_line_panel = middle
	middle.custom_minimum_size.x = 135
	middle.size_flags_horizontal = SIZE_FILL
	line_split.add_child(middle)
	_heading = Label.new()
	_heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	middle.add_child(_heading)
	_lines = DraggableLines.new()
	_lines.size_flags_vertical = SIZE_EXPAND_FILL
	_lines.item_selected.connect(_on_line)
	_lines.reorder_requested.connect(_on_line_dropped)
	_lines.tooltip_text = "Черновые реплики: перетащите на другую черновую реплику. Канон не перемещается."
	middle.add_child(_lines)
	var stage_split := HSplitContainer.new()
	_stage_split = stage_split
	stage_split.split_offset = 680
	stage_split.size_flags_horizontal = SIZE_EXPAND_FILL
	stage_split.size_flags_vertical = SIZE_EXPAND_FILL
	line_split.add_child(stage_split)
	var stage_column := VBoxContainer.new()
	_stage_column = stage_column
	stage_column.custom_minimum_size.x = 390
	stage_column.size_flags_horizontal = SIZE_EXPAND_FILL
	stage_split.add_child(stage_column)
	var editor := VBoxContainer.new()
	_inspector = editor
	editor.custom_minimum_size.x = 300
	editor.size_flags_horizontal = SIZE_FILL
	stage_split.add_child(editor)
	if Engine.is_editor_hint():
		var pane_settings := EditorInterface.get_editor_settings()
		if pane_settings.has_setting(LINE_PANE_SETTING):
			line_split.split_offset = clampi(int(pane_settings.get_setting(LINE_PANE_SETTING)), 125, 400)
		if pane_settings.has_setting(STAGE_PANE_SETTING):
			stage_split.split_offset = clampi(int(pane_settings.get_setting(STAGE_PANE_SETTING)), 390, 900)
	line_split.dragged.connect(_on_line_pane_dragged)
	stage_split.dragged.connect(_on_stage_pane_dragged)
	_line_info = Label.new()
	_line_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_workspace_tabs = TabContainer.new()
	_workspace_tabs.size_flags_vertical = SIZE_EXPAND_FILL
	_workspace_tabs.size_flags_horizontal = SIZE_EXPAND_FILL
	editor.add_child(_workspace_tabs)
	var inspector_scroll := ScrollContainer.new()
	inspector_scroll.name = "Stage Inspector"
	inspector_scroll.size_flags_vertical = SIZE_EXPAND_FILL
	inspector_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_workspace_tabs.add_child(inspector_scroll)
	var stage_controls := VBoxContainer.new()
	stage_controls.custom_minimum_size.x = 260
	inspector_scroll.add_child(stage_controls)
	var director := VBoxContainer.new()
	director.name = "Translations"
	director.size_flags_vertical = SIZE_EXPAND_FILL
	_workspace_tabs.add_child(director)
	director.add_child(_line_info)
	var dialogue_column := VBoxContainer.new()
	dialogue_column.name = "Диалог"
	dialogue_column.size_flags_vertical = SIZE_EXPAND_FILL
	director.add_child(dialogue_column)
	_dialogue_scroll = ScrollContainer.new()
	_dialogue_scroll.size_flags_horizontal = SIZE_EXPAND_FILL
	_dialogue_scroll.size_flags_vertical = SIZE_EXPAND_FILL
	_dialogue_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	dialogue_column.add_child(_dialogue_scroll)
	var text_column := VBoxContainer.new()
	text_column.custom_minimum_size.x = 525
	text_column.size_flags_horizontal = SIZE_EXPAND_FILL
	_dialogue_scroll.add_child(text_column)
	var title_label := Label.new()
	title_label.text = "Названия сцены · RU / BE / EN"
	text_column.add_child(title_label)
	var title_row := HBoxContainer.new()
	text_column.add_child(title_row)
	for language in LOCALES:
		var title_edit := LineEdit.new()
		title_edit.size_flags_horizontal = SIZE_EXPAND_FILL
		title_edit.placeholder_text = language.to_upper() + " · нет перевода"
		title_edit.focus_entered.connect(_capture_undo)
		title_edit.text_changed.connect(_on_title_changed.bind(language))
		title_row.add_child(title_edit)
		_title_edits[language] = title_edit
	var locale_row := HBoxContainer.new()
	locale_row.size_flags_horizontal = SIZE_EXPAND_FILL
	text_column.add_child(locale_row)
	for language in LOCALES:
		var column := VBoxContainer.new()
		column.custom_minimum_size.x = 170
		column.size_flags_horizontal = SIZE_EXPAND_FILL
		locale_row.add_child(column)
		var locale_label := Label.new()
		locale_label.text = language.to_upper()
		column.add_child(locale_label)
		var edit := TextEdit.new()
		edit.custom_minimum_size.y = 185
		edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
		edit.size_flags_vertical = SIZE_EXPAND_FILL
		edit.focus_entered.connect(_capture_undo)
		edit.text_changed.connect(_on_text_changed.bind(language))
		column.add_child(edit)
		_locale_edits[language] = edit
		var status := Label.new()
		status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		column.add_child(status)
		_locale_status[language] = status
	_text_edit = _locale_edits["ru"]
	_diff = Label.new()
	_diff.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_column.add_child(_diff)
	var visual_column := VBoxContainer.new()
	visual_column.name = "Постановка"
	visual_column.size_flags_vertical = SIZE_EXPAND_FILL
	stage_column.add_child(visual_column)
	var stage_label := Label.new()
	stage_label.text = "STAGE · постановка и preview"
	visual_column.add_child(stage_label)
	# Tall art and multiple tool rows need vertical scrolling rather than
	# clipping the asset controls and dialogue preview below the viewport.
	_draft_stage_hint = Label.new()
	_draft_stage_hint.text = "DRAFT · постановка только для review; сцена не запускается в игре и не меняет art approval."
	_draft_stage_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_draft_stage_hint.visible = false
	visual_column.add_child(_draft_stage_hint)
	_stage_scroll = ScrollContainer.new()
	_stage_scroll.size_flags_horizontal = SIZE_EXPAND_FILL
	_stage_scroll.size_flags_vertical = SIZE_EXPAND_FILL
	_stage_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	visual_column.add_child(_stage_scroll)
	_stage_scroll.resized.connect(_fit_stage_preview)
	var stage_contents := VBoxContainer.new()
	stage_contents.size_flags_horizontal = SIZE_EXPAND_FILL
	_stage_scroll.add_child(stage_contents)
	_stage_designer = StageDesigner.new()
	_stage_designer.stage_modified.connect(_on_stage_modified)
	_stage_designer.stage_v2_modified.connect(_on_stage_v2_modified)
	_stage_designer.stage_fx_modified.connect(_on_stage_fx_modified)
	stage_contents.add_child(_stage_designer)
	# Dock after the Animation tab exists, so the actual FX widgets can be
	# moved there rather than hidden among unrelated Stage properties.
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
	var story_scroll := ScrollContainer.new()
	_story_scroll = story_scroll
	story_scroll.name = "Story Map"
	story_scroll.size_flags_vertical = SIZE_EXPAND_FILL
	story_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_workspace_tabs.add_child(story_scroll)
	story_scroll.resized.connect(_sync_story_map_height)
	_raven_graph = RavenGraph.new()
	_raven_graph.custom_minimum_size.x = 430
	_raven_graph.graph_modified.connect(_on_graph_modified)
	_raven_graph.scene_focus_requested.connect(_on_graph_scene_focus)
	story_scroll.add_child(_raven_graph)
	var animation_scroll := ScrollContainer.new()
	animation_scroll.name = "Animation"
	animation_scroll.size_flags_vertical = SIZE_EXPAND_FILL
	animation_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_workspace_tabs.add_child(animation_scroll)
	var animation_body := VBoxContainer.new()
	animation_body.custom_minimum_size.x = 260
	animation_body.size_flags_horizontal = SIZE_EXPAND_FILL
	animation_scroll.add_child(animation_body)
	var animation_context := RichTextLabel.new()
	animation_context.custom_minimum_size = Vector2(260, 110)
	animation_context.size_flags_horizontal = SIZE_EXPAND_FILL
	animation_context.fit_content = true
	animation_body.add_child(animation_context)
	_context_views.append(animation_context)
	# Stage's existing FX controls (targets, scene/line anchors, cue list,
	# timing, Play/Pause and scrub) are now editable in their named tab.
	_stage_designer.dock_controls(stage_controls, animation_body)
	var promotion_scroll := ScrollContainer.new()
	promotion_scroll.name = "Promotion Review"
	promotion_scroll.size_flags_vertical = SIZE_EXPAND_FILL
	promotion_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_workspace_tabs.add_child(promotion_scroll)
	_promotion_view = PromotionView.new()
	_promotion_view.custom_minimum_size.x = 430
	_promotion_view.mapping_modified.connect(_on_promotion_mapping_modified)
	_promotion_view.export_requested.connect(_export_promotion_review)
	_promotion_view.template_requested.connect(_export_package_template)
	_promotion_view.package_requested.connect(_export_four_registry_review)
	promotion_scroll.add_child(_promotion_view)
	_path = LineEdit.new()
	_path.editable = false
	_path.placeholder_text = "Путь локального черновика / JSON-кандидата"
	add_child(_path)
	# The first nonzero viewport dimensions arrive after Godot's first layout.
	call_deferred("_sync_workspace_height")
	call_deferred("_sync_story_map_height")
	call_deferred("_fit_stage_preview")


func _sync_workspace_height() -> void:
	if _workspace_scroll == null or _workspace_body == null:
		return
	var available: float = _workspace_scroll.size.y
	if available > 0.0:
		_workspace_body.custom_minimum_size.y = maxf(440.0, available)


func _sync_story_map_height() -> void:
	if _story_scroll == null or _raven_graph == null:
		return
	# A GraphEdit inside a ScrollContainer normally stays at its minimum
	# 310px height. Fill the Inspector when tall, but retain scrolling on
	# short windows for the edge fields beneath the canvas.
	if _story_scroll.size.y > 0.0:
		_raven_graph.custom_minimum_size.y = _story_scroll.size.y
		# A ScrollContainer may preserve the content Control's minimum while
		# the nested GraphEdit remains at its own 310px minimum. Reserve room
		# for legend, edge form and list, and enlarge the actual graph itself.
		_raven_graph._canvas.custom_minimum_size.y = maxf(310.0,
			_story_scroll.size.y - 300.0)


func _fit_stage_preview() -> void:
	if _stage_scroll == null or _stage_designer == null:
		return
	if _stage_scroll.size.y <= 0.0 or _stage_scroll.size.x <= 0.0:
		return
	# Only visual Editor bounds: the game's logical frame and all normalized
	# positions remain unchanged. Reserve space for Stage status and captions.
	_stage_designer.fit_docked_preview(
		Vector2(maxf(150.0, _stage_scroll.size.x - 24.0),
			maxf(200.0, _stage_scroll.size.y - 165.0)))


func _build_authoring_dialogs() -> void:
	_create_scene_dialog = ConfirmationDialog.new()
	_create_scene_dialog.title = "Новая сцена Raven · только черновик"
	_create_scene_dialog.min_size = Vector2i(440, 320)
	add_child(_create_scene_dialog)
	var scene_fields := VBoxContainer.new()
	_create_scene_dialog.add_child(scene_fields)
	var chapter_label := Label.new()
	chapter_label.text = "Глава (draft-группа, не runtime)"
	scene_fields.add_child(chapter_label)
	_scene_chapter = OptionButton.new()
	scene_fields.add_child(_scene_chapter)
	var bg_label := Label.new()
	bg_label.text = "Фон / свет / состояние (реальные plate из каталога)"
	scene_fields.add_child(bg_label)
	_scene_background = OptionButton.new()
	_scene_background.custom_minimum_size.x = 390
	scene_fields.add_child(_scene_background)
	var title := Label.new()
	title.text = "Название RU"
	scene_fields.add_child(title)
	_scene_title_input = LineEdit.new()
	_scene_title_input.placeholder_text = "Например: Разговор у ворот"
	scene_fields.add_child(_scene_title_input)
	var first := Label.new()
	first.text = "Первая реплика RU (обязательно)"
	scene_fields.add_child(first)
	_scene_first_line_input = TextEdit.new()
	_scene_first_line_input.custom_minimum_size = Vector2(360, 90)
	scene_fields.add_child(_scene_first_line_input)
	_scene_speaker = OptionButton.new()
	scene_fields.add_child(_scene_speaker)
	_create_scene_dialog.confirmed.connect(_on_create_scene)
	_create_line_dialog = ConfirmationDialog.new()
	_create_line_dialog.title = "Добавить реплику в текущую сцену · только черновик"
	_create_line_dialog.min_size = Vector2i(440, 240)
	add_child(_create_line_dialog)
	var line_fields := VBoxContainer.new()
	_create_line_dialog.add_child(line_fields)
	_new_line_input = TextEdit.new()
	_new_line_input.custom_minimum_size = Vector2(360, 100)
	line_fields.add_child(_new_line_input)
	_line_speaker = OptionButton.new()
	line_fields.add_child(_line_speaker)
	_create_line_dialog.confirmed.connect(_on_create_line)
	_confirm_delete_line = ConfirmationDialog.new()
	_confirm_delete_line.title = "Удалить черновую реплику?"
	_confirm_delete_line.dialog_text = "Только локальная реплика; исходный сценарий не изменится. Можно отменить в редакторе."
	_confirm_delete_line.confirmed.connect(_delete_selected_line)
	add_child(_confirm_delete_line)
	_qa_demo_dialog = ConfirmationDialog.new()
	_qa_demo_dialog.title = "Raven · QA Story Map + FX"
	_qa_demo_dialog.dialog_text = "Добавить в КОНЕЦ локального черновика 4 сцены: выбор Эвелин / Ада / Роуэн, по одному возврату к выбору, три разных эффекта анимации. Существующие сцены и реплики не изменяются. Новые сцены не подключены к игре. Все данные создаются только в памяти до нажатия «Сохранить Raven-черновик»."
	_qa_demo_dialog.ok_button_text = "Добавить только в черновик"
	_qa_demo_dialog.confirmed.connect(_on_confirm_qa_demo)
	add_child(_qa_demo_dialog)


func _refresh_speakers() -> void:
	var actors: Array = Store.Author.actor_ids(_project)
	for picker in [_scene_speaker, _line_speaker]:
		picker.clear()
		for actor_id in actors:
			picker.add_item(str(actor_id).trim_prefix("RM-CHAR-"))
			picker.set_item_metadata(picker.item_count - 1, actor_id)
		picker.add_item("Авторский текст (без персонажа)")
		picker.set_item_metadata(picker.item_count - 1, Store.Author.NARRATOR_ID)
		if picker.item_count > 0:
			picker.select(0)


func _show_create_scene() -> void:
	if _blocked or _project.is_empty():
		return
	_refresh_speakers()
	_scene_chapter.clear()
	var chapters: Array[String] = []
	for record in _project.get("scenes", []):
		var scene_id: String = str(record.get("sceneId", ""))
		var bits: PackedStringArray = scene_id.split("-")
		if bits.size() >= 4 and bits[2].length() == 2 and not chapters.has(bits[2]):
			chapters.append(bits[2])
	chapters.sort()
	for chapter in chapters:
		_scene_chapter.add_item(chapter)
	_scene_chapter.disabled = chapters.is_empty()
	_scene_backgrounds = Store.background_variants(_project)
	_scene_background.clear()
	for bg in _scene_backgrounds:
		_scene_background.add_item("%s · %s · %s" % [
			str(bg["backgroundId"]), str(bg["lighting"]), str(bg["roomState"])])
	_scene_background.disabled = _scene_backgrounds.is_empty()
	_scene_title_input.clear()
	_scene_first_line_input.clear()
	_create_scene_dialog.popup_centered()


func _show_create_line() -> void:
	if _blocked or _project.is_empty():
		return
	_refresh_speakers()
	_new_line_input.clear()
	_create_line_dialog.popup_centered()


func _on_create_scene() -> void:
	if _blocked or _scene_speaker.selected < 0:
		return
	if _scene_background.selected < 0:
		_status.text = "Новая сцена: нет доступного изображения фона."
		return
	var chapter: String = _scene_chapter.get_item_text(_scene_chapter.selected) if _scene_chapter.selected >= 0 else ""
	var background: Dictionary = _scene_backgrounds[_scene_background.selected]
	var result: Dictionary = Store.add_scene(_project, _draft,
		_scene_title_input.text, _scene_first_line_input.text,
		str(_scene_speaker.get_item_metadata(_scene_speaker.selected)), chapter, background)
	if not result.get("ok", false):
		_status.text = "Новая сцена не добавлена: " + str(result.get("error", ""))
		return
	_undo.append(_draft.duplicate(true))
	_redo.clear()
	_draft = result["draft"]
	_dirty = true
	_scene_search.clear() # Ensure the just-created scene is visible.
	_refresh_scene_items()
	_scene_idx = Store.scene_records(_project, _draft).size() - 1
	_scene_switch()
	_status.text = "Черновая сцена " + str(result["sceneId"]) + " создана в главе " + chapter + " с выбранным фоном; не участвует в игре."
	_refresh_buttons()


func _on_create_line() -> void:
	if _blocked or _line_speaker.selected < 0:
		return
	var source: String = str(Store.scene_records(_project, _draft)[_scene_idx]["sceneId"])
	var result: Dictionary = Store.add_line(_project, _draft, source,
		_new_line_input.text, str(_line_speaker.get_item_metadata(_line_speaker.selected)))
	if not result.get("ok", false):
		_status.text = "Реплика не добавлена: " + str(result.get("error", ""))
		return
	_undo.append(_draft.duplicate(true))
	_redo.clear()
	_draft = result["draft"]
	_dirty = true
	_scene_switch()
	_line_idx = Store.entries_for(_project, _draft, source).size() - 1
	_line_render()
	_raven_graph.set_context(Store.visible_project(_project, _draft), _draft, source)
	_status.text = "Добавлена draft-реплика " + str(result["lineId"]) + "." + str(result.get("stageNotice", ""))
	_refresh_buttons()



func _on_line_up() -> void:
	_move_selected_line(-1)


func _on_line_down() -> void:
	_move_selected_line(1)


func _move_selected_line(direction: int) -> void:
	if _blocked or _project.is_empty():
		return
	var entry: Dictionary = _current_entry()
	if entry.is_empty():
		return
	var scene_id: String = str(entry["sceneId"])
	var line_id: String = str(entry["id"])
	var result: Dictionary = Store.move_line(_project, _draft, scene_id, line_id, direction)
	if not result.get("ok", false):
		_status.text = "Порядок не изменён: " + str(result.get("error", ""))
		return
	_undo.append(_draft.duplicate(true))
	_redo.clear()
	_draft = result["draft"]
	_dirty = true
	_scene_switch()
	var entries: Array = Store.entries_for(_project, _draft, scene_id)
	for index in range(entries.size()):
		if str(entries[index]["id"]) == line_id:
			_line_idx = index
			break
	_line_render()
	_status.text = "Черновая реплика перемещена; ID сохранён: " + line_id
	_refresh_buttons()


func _on_line_dropped(from_index: int, to_index: int) -> void:
	if _blocked or _project.is_empty() or from_index == to_index:
		return
	var scene_id: String = str(Store.scene_records(_project, _draft)[_scene_idx]["sceneId"])
	var entries: Array = Store.entries_for(_project, _draft, scene_id)
	if from_index < 0 or to_index < 0 or from_index >= entries.size() or to_index >= entries.size():
		return
	var from_id: String = str(entries[from_index]["id"])
	var to_id: String = str(entries[to_index]["id"])
	var result: Dictionary = Store.move_line_to(_project, _draft, scene_id, from_id, to_id)
	if not result.get("ok", false):
		_status.text = "Drag & drop: " + str(result.get("error", "Не удалось переместить."))
		return
	if result["draft"] == _draft:
		return
	_undo.append(_draft.duplicate(true))
	_redo.clear()
	_draft = result["draft"]
	_dirty = true
	_scene_switch()
	var after: Array = Store.entries_for(_project, _draft, scene_id)
	for index in range(after.size()):
		if str(after[index]["id"]) == from_id:
			_line_idx = index
			break
	_line_render()
	_status.text = "Перетащено: " + from_id + " · ID, переводы и привязки сохранены."
	_refresh_buttons()


func _request_qa_demo() -> void:
	if _blocked or _project.is_empty():
		return
	_qa_demo_dialog.popup_centered(Vector2i(660, 260))


func _on_confirm_qa_demo() -> void:
	if _blocked or _project.is_empty():
		return
	var result: Dictionary = QABranch.build(_project, _draft)
	if not result.get("ok", false):
		_status.text = "QA-развилка не добавлена: " + str(result.get("error", "ошибка"))
		return
	_undo.append(_draft.duplicate(true))
	_redo.clear()
	_draft = result["draft"]
	_dirty = true
	_refresh_scene_items()
	for i in range(Store.scene_records(_project, _draft).size()):
		if str(Store.scene_records(_project, _draft)[i]["sceneId"]) == str(result["hubSceneId"]):
			_scene_idx = i
			break
	_line_idx = 0
	_scene_switch()
	_workspace_tabs.current_tab = 3 # Open Story Map for this draft hub
	_status.text = "QA · 3 выбора + 3 возврата + FX добавлены в конец черновика. Сохраните черновик вручную; это не игра."
	_refresh_buttons()


func _request_delete_line() -> void:
	if _blocked or _current_entry().is_empty() or _line_delete.disabled:
		return
	_confirm_delete_line.dialog_text = "Удалить локальную реплику %s? Исходные реплики неизменяемы; Undo доступен." % str(_current_entry()["id"])
	_confirm_delete_line.popup_centered()


func _delete_selected_line() -> void:
	if _blocked or _project.is_empty() or _current_entry().is_empty():
		return
	var entry: Dictionary = _current_entry()
	var scene_id: String = str(entry["sceneId"])
	var line_id: String = str(entry["id"])
	var result: Dictionary = Store.delete_line(_project, _draft, scene_id, line_id)
	if not result.get("ok", false):
		_status.text = "Реплика не удалена: " + str(result.get("error", ""))
		return
	_undo.append(_draft.duplicate(true))
	_redo.clear()
	_draft = result["draft"]
	_dirty = true
	_line_idx = mini(_line_idx, Store.entries_for(_project, _draft, scene_id).size() - 1)
	_scene_switch()
	_status.text = "Черновая реплика %s удалена; можно использовать Undo." % line_id
	_refresh_buttons()


func _sync_line_actions() -> void:
	if _line_up == null or _line_down == null or _line_delete == null:
		return
	var entry: Dictionary = _current_entry() if not _project.is_empty() else {}
	var scene_id: String = str(entry.get("sceneId", ""))
	var line_id: String = str(entry.get("id", ""))
	var line_ids: Array[String] = []
	for line in _draft.get("authoredLines", []):
		if str(line.get("sceneId", "")) == scene_id:
			line_ids.append(str(line.get("id", "")))
	var index: int = line_ids.find(line_id)
	_line_up.disabled = _blocked or index <= 0
	_line_down.disabled = _blocked or index < 0 or index >= line_ids.size() - 1
	_line_delete.disabled = _blocked or index < 0 or (
		Store.Author.is_authored_scene(_draft, scene_id) and line_ids.size() == 1)


func _refresh_scene_items() -> void:
	_scenes.clear()
	_visible_scene_indices.clear()
	if _project.is_empty():
		return
	var needle: String = _scene_search.text.strip_edges().to_lower()
	var scenes: Array = Store.scene_records(_project, _draft)
	for index in range(scenes.size()):
		var scene: Dictionary = scenes[index]
		var titles: Dictionary = scene.get("title", {})
		var searchable: String = str(scene.get("sceneId", ""))
		for language in LOCALES:
			searchable += " " + str(titles.get(language, ""))
		if not needle.is_empty() and not searchable.to_lower().contains(needle):
			continue
		_visible_scene_indices.append(index)
		_scenes.add_item("%s · %s" % [
			str(scene.get("sceneId", "")), str(titles.get("ru", ""))])
	_sync_scene_list_selection()


func _sync_scene_list_selection() -> void:
	# Filtering is presentation only: the selected scene always remains the
	# canonical scene index, never a positional index in filtered ItemList.
	var visible_index: int = _visible_scene_indices.find(_scene_idx)
	if visible_index >= 0:
		_scenes.select(visible_index)
	else:
		_scenes.deselect_all()


func _on_pane_dragged(offset: int) -> void:
	if Engine.is_editor_hint():
		EditorInterface.get_editor_settings().set_setting(PANE_SETTING, clampi(offset, 120, 420))


func _on_line_pane_dragged(offset: int) -> void:
	if Engine.is_editor_hint():
		EditorInterface.get_editor_settings().set_setting(LINE_PANE_SETTING, clampi(offset, 125, 400))


func _on_stage_pane_dragged(offset: int) -> void:
	if Engine.is_editor_hint():
		EditorInterface.get_editor_settings().set_setting(STAGE_PANE_SETTING, clampi(offset, 390, 900))



func _request_stale_recovery() -> void:
	if not _blocked or _project.is_empty():
		return
	var info: Dictionary = Store.stale_draft_info(_project)
	if not info.get("ok", false):
		_status.text = str(info.get("error", "Нельзя создать резервную копию."))
		return
	var counts: Dictionary = info.get("changes", {})
	_recover_dialog.dialog_text = ("БЛОКИРОВКА: " + str(info["reason"]) +
		"\nВ старом файле: %d правок перевода, %d сцен, %d новых реплик, %d Story Map, %d FX.\n\n" % [
			int(counts.get("translations", 0)), int(counts.get("scenes", 0)),
			int(counts.get("lines", 0)), int(counts.get("graph", 0)), int(counts.get("fx", 0))] +
		"Сохранить исходный JSON побайтово в папке recovery и начать НОВЫЙ чистый черновик? Старые изменения не переносятся и остаются доступными для ручного diff. Релизный сценарий не меняется.")
	_recover_dialog.popup_centered(Vector2i(650, 320))


func _on_confirm_stale_recovery() -> void:
	if not _blocked or _project.is_empty():
		return
	var outcome: Dictionary = Store.archive_and_start_fresh(_project)
	if not outcome.get("ok", false):
		_status.text = "Восстановление остановлено: " + str(outcome.get("error", "ошибка"))
		if outcome.has("backupPath"):
			_path.text = str(outcome["backupPath"])
		return
	var archived_path: String = str(outcome["backupPath"])
	_dirty = false
	open_raven()
	if not _blocked:
		_path.text = archived_path
		_status.text = "Редактирование разблокировано. Старая версия сохранена: " + archived_path + ". Правки не переносились — сравните JSON вручную."


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
		var rescue: Dictionary = Store.stale_draft_info(candidate)
		if rescue.get("ok", false):
			_status.text += " Для продолжения нажмите «Архивировать старый черновик и начать новый…»; исходный JSON будет сохранён."

	else:
		_blocked = false
		_draft = loaded["draft"]
		_status.text = "Raven: %d сцен / %d реплик. %s" % [
			candidate["sceneCount"], candidate["lineCount"],
			"Локальный черновик восстановлен." if loaded["found"] else "Исходный production draft."]
	_undo.clear()
	_redo.clear()
	_refresh_scene_items()
	_scene_idx = 0
	_scene_switch()
	_refresh_buttons()


func _scene_switch() -> void:
	if _project.is_empty():
		return
	var scenes: Array = Store.scene_records(_project, _draft)
	_scene_idx = clampi(_scene_idx, 0, scenes.size() - 1)
	_sync_scene_list_selection()
	var scene: Dictionary = Store.scene_records(_project, _draft)[_scene_idx]
	var id: String = str(scene["sceneId"])
	var title: Dictionary = scene.get("title", {})
	_heading.text = "%s · %s\nСтатус: %s" % [id,
		str(title.get(_language, title.get("ru", ""))) if title.get(_language) != null else str(title.get("ru", "")),
		str(scene.get("status", ""))]
	_lines.clear()
	var entries: Array = Store.entries_for(_project, _draft, id)
	for e in entries:
		var loc: Dictionary = Store.localized(e, _draft, _language)
		_lines.add_item("%s · %s" % [
			str(e["id"]).get_slice("-L", 1),
			str(loc["text"]).replace("\n", " ").left(18)])
	_line_idx = clampi(_line_idx, 0, maxi(entries.size() - 1, 0))
	_line_render()
	var authored: bool = Store.Author.is_authored_scene(_draft, id)
	_stage_scroll.visible = true
	_draft_stage_hint.visible = authored
	_stage_designer.set_scene(_project, _draft, id)
	_stage_designer.set_selected_line(str(_current_entry().get("id", "")))
	_raven_graph.set_context(Store.visible_project(_project, _draft), _draft, id)
	_promotion_view.set_context(_project, _draft)
	_refresh_preview()
	_refresh_context()


func _current_entry() -> Dictionary:
	if _project.is_empty():
		return {}
	var id: String = str(Store.scene_records(_project, _draft)[_scene_idx]["sceneId"])
	var lines: Array = Store.entries_for(_project, _draft, id)
	return lines[_line_idx] if _line_idx >= 0 and _line_idx < lines.size() else {}


func _line_render() -> void:
	var e: Dictionary = _current_entry()
	if e.is_empty():
		return
	_line_idx = clampi(_line_idx, 0, Store.entries_for(_project, _draft, str(e["sceneId"])).size() - 1)
	_lines.select(_line_idx)
	var text_value: Dictionary = Store.localized(e, _draft, _language)
	_suppress = true
	for language in LOCALES:
		var localized: Dictionary = Store.localized(e, _draft, language)
		var edit: TextEdit = _locale_edits[language]
		edit.text = "" if localized["fallback"] else str(localized["text"])
		edit.placeholder_text = "RU fallback: " + str(localized["text"]).left(90) if localized["fallback"] else ""
		edit.editable = not _blocked
		_locale_status[language].text = "Не переведено · RU fallback" if localized["fallback"] else "Перевод есть / оригинал"
	var scene: Dictionary = Store.scene_records(_project, _draft)[_scene_idx]
	var authored: bool = Store.Author.is_authored_scene(_draft, str(scene["sceneId"]))
	for language in LOCALES:
		var title_edit: LineEdit = _title_edits[language]
		var title_value: Variant = scene.get("title", {}).get(language)
		title_edit.text = str(title_value) if title_value != null else ""
		title_edit.editable = authored and not _blocked
	_suppress = false
	_line_info.text = "%s\nГоворящий: %s · тип: %s\n%s" % [
		str(e["id"]), "Автор / без портрета" if e.get("speakerId") == Store.Author.NARRATOR_ID else str(e.get("speakerId", "")),
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
	if _context_views.size() != 1 or _project.is_empty():
		return
	var scene: Dictionary = Store.scene_records(_project, _draft)[_scene_idx]
	var scene_id: String = str(scene["sceneId"])
	_asset_library.set_scene_context(scene_id)
	var entry: Dictionary = _current_entry()
	var line_id: String = str(entry.get("id", ""))
	var cue: Dictionary = _project["cues"].get(line_id, {})
	_context_views[0].text = "Animation · %s\nПоза: %s · Эмоция: %s · исходное micro: %s\n\nВыберите цель, нажмите + FX и редактируйте эффект ниже. FX действует в сцене или на выбранной реплике. Play / Pause / Reset / scrub изменяют только центральный Stage preview, не игровой прогресс. Blink пока геометрический proxy, не анимация глаз." % [
		line_id, str(cue.get("poseId", "—")), str(cue.get("emotionId", "—")), str(cue.get("microOnEnter", "—"))]


func _refresh_preview() -> void:
	var scene: Dictionary = Store.scene_records(_project, _draft)[_scene_idx]
	var id: String = str(scene["sceneId"])
	if Store.Author.is_authored_scene(_draft, id):
		var draft_shot: Dictionary = Store.effective_stage(_project, _draft, id)
		_preview.text = "DRAFT · %s / %s / %s · %d персонажей. Нет утверждённого trigger или runtime." % [
			str(draft_shot.get("backgroundId", "")), str(draft_shot.get("lighting", "")),
			str(draft_shot.get("roomState", "")), draft_shot.get("cast", []).size()]
		return
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
	if index < 0 or index >= _visible_scene_indices.size():
		return
	_scene_idx = _visible_scene_indices[index]
	_line_idx = 0
	_scene_switch()


func _on_line(index: int) -> void:
	_line_idx = index
	_line_render()


func _on_locale(index: int) -> void:
	_language = LOCALES[index]
	if _project.is_empty():
		return
	var scene: Dictionary = Store.scene_records(_project, _draft)[_scene_idx]
	var title: Dictionary = scene.get("title", {})
	_heading.text = "%s · %s\nСтатус: %s" % [str(scene["sceneId"]),
		str(title.get(_language, title.get("ru", ""))) if title.get(_language) != null else str(title.get("ru", "")),
		str(scene.get("status", ""))]
	var selected_line: String = str(_current_entry().get("id", ""))
	_lines.clear()
	for entry in Store.entries_for(_project, _draft, str(scene["sceneId"])):
		var loc: Dictionary = Store.localized(entry, _draft, _language)
		_lines.add_item("%s · %s" % [str(entry["id"]).get_slice("-L", 1), str(loc["text"]).replace("\n", " ").left(18)])
	for i in range(_lines.item_count):
		if str(Store.entries_for(_project, _draft, str(scene["sceneId"]))[i]["id"]) == selected_line:
			_line_idx = i
			break
	_line_render()
	_refresh_preview()


func _capture_undo() -> void:
	if not _blocked and not _project.is_empty():
		_undo.append(_draft.duplicate(true))
		_redo.clear()
		_refresh_buttons()


func _on_text_changed(language: String = "ru") -> void:
	if _suppress or _blocked or _project.is_empty():
		return
	var e: Dictionary = _current_entry()
	if e.is_empty():
		return
	Store.edit(_draft, str(e["id"]), language, _locale_edits[language].text)
	_locale_status[language].text = "Не переведено · RU fallback" if language != "ru" and _locale_edits[language].text.is_empty() else "Перевод есть / оригинал"
	_dirty = true
	_update_diff()
	_sync_dialogue_preview()
	_refresh_buttons()


func _on_title_changed(value: String, language: String) -> void:
	if _suppress or _blocked or _project.is_empty():
		return
	var scene_id: String = str(Store.scene_records(_project, _draft)[_scene_idx]["sceneId"])
	if not Store.Author.is_authored_scene(_draft, scene_id):
		return
	for scene in _draft.get("authoredScenes", []):
		if scene.get("sceneId", "") == scene_id:
			scene["title"][language] = value if language == "ru" or not value.is_empty() else null
			break
	_dirty = true
	_refresh_scene_items()
	var current_scene: Dictionary = Store.scene_records(_project, _draft)[_scene_idx]
	var title: Dictionary = current_scene.get("title", {})
	_heading.text = "%s · %s\nСтатус: %s" % [scene_id,
		str(title.get(_language, title.get("ru", ""))) if title.get(_language) != null else str(title.get("ru", "")),
		str(current_scene.get("status", ""))]
	_update_diff()
	_refresh_buttons()


## History snapshots store drafts, not UI list indices. Restore the same stable
## scene/line ID when it exists on both sides of an Undo/Redo operation;
## otherwise keep the old nearest-index fallback (e.g. undoing a new scene).
func _restore_history_selection(scene_id: String, line_id: String) -> void:
	var scenes: Array = Store.scene_records(_project, _draft)
	if scenes.is_empty():
		return
	for index in range(scenes.size()):
		if str(scenes[index].get("sceneId", "")) == scene_id:
			_scene_idx = index
			break
	_scene_idx = clampi(_scene_idx, 0, scenes.size() - 1)
	var active_scene_id: String = str(scenes[_scene_idx].get("sceneId", ""))
	var entries: Array = Store.entries_for(_project, _draft, active_scene_id)
	for index in range(entries.size()):
		if str(entries[index].get("id", "")) == line_id:
			_line_idx = index
			break
	_scene_switch()


func _on_undo() -> void:
	if _undo.is_empty() or _blocked:
		return
	var selection: Dictionary = selected_context()
	_redo.append(_draft.duplicate(true))
	_draft = _undo.pop_back()
	_dirty = true
	_refresh_scene_items()
	_restore_history_selection(str(selection.get("sceneId", "")), str(selection.get("lineId", "")))
	_refresh_buttons()


func _on_redo() -> void:
	if _redo.is_empty() or _blocked:
		return
	var selection: Dictionary = selected_context()
	_undo.append(_draft.duplicate(true))
	_draft = _redo.pop_back()
	_dirty = true
	_refresh_scene_items()
	_restore_history_selection(str(selection.get("sceneId", "")), str(selection.get("lineId", "")))
	_refresh_buttons()


func _update_diff() -> void:
	_diff.text = "%d переводов, %d сцен v1, %d сцен v2, %d FX, %d Story Map, %d новых сцен, %d реплик, %d ID-привязок · %s" % [
		Store.change_count(_draft), _draft.get("stagePatches", {}).size(), _draft.get("stageV2Patches", {}).size(),
		_draft.get("stageFxPatches", {}).size(), _draft.get("storyGraphPatches", {}).size(),
		_draft.get("authoredScenes", []).size(), _draft.get("authoredLines", []).size(),
		_draft.get("promotionSceneIdMap", {}).size(),
		"есть несохранённые правки" if _dirty else "локально сохранено / без изменений"]


func _refresh_buttons() -> void:
	_recover_button.visible = _blocked and not _project.is_empty() and Store.stale_draft_info(_project).get("ok", false)
	_qa_demo_button.disabled = _blocked or _project.is_empty()
	_save.disabled = _blocked or _project.is_empty()
	var has_additions: bool = not _draft.get("authoredScenes", []).is_empty() or not _draft.get("authoredLines", []).is_empty()
	_export.disabled = _blocked or _project.is_empty() or Store.change_count(_draft) == 0 or not _draft.get("storyGraphPatches", {}).is_empty() or has_additions
	_export_stage.disabled = _blocked or _project.is_empty() or _draft.get("stagePatches", {}).is_empty() or not _draft.get("stageV2Patches", {}).is_empty() or not _draft.get("stageFxPatches", {}).is_empty() or not _draft.get("storyGraphPatches", {}).is_empty() or has_additions
	_export_stage_v2.disabled = _blocked or _project.is_empty() or _draft.get("stageV2Patches", {}).is_empty() or not _draft.get("stageFxPatches", {}).is_empty() or not _draft.get("storyGraphPatches", {}).is_empty() or has_additions
	_export_fx.disabled = _blocked or _project.is_empty() or _draft.get("stageFxPatches", {}).is_empty() or not _draft.get("storyGraphPatches", {}).is_empty() or has_additions
	_export_graph.disabled = _blocked or _project.is_empty() or (_draft.get("storyGraphPatches", {}).is_empty() and not has_additions)
	_undo_button.disabled = _blocked or _undo.is_empty()
	_redo_button.disabled = _blocked or _redo.is_empty()
	_sync_line_actions()


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


func _on_promotion_mapping_modified(mapping: Dictionary) -> void:
	if _blocked or _project.is_empty() or mapping == _draft.get("promotionSceneIdMap", {}):
		return
	var snapshot: Dictionary = _draft.duplicate(true)
	var error: String = Store.set_promotion_map(_project, _draft, mapping)
	if not error.is_empty():
		_status.text = "Promotion ID не сохранён: " + error
		_promotion_view.set_context(_project, _draft)
		return
	_undo.append(snapshot)
	_redo.clear()
	_dirty = true
	_promotion_view.set_context(_project, _draft)
	_update_diff()
	_refresh_buttons()


func _export_promotion_review() -> void:
	if _blocked or _project.is_empty():
		return
	if _dirty:
		_status.text = "Сначала сохраните локальный Raven-черновик, затем экспортируйте Promotion Review."
		return
	var result: Dictionary = Store.export_promotion_review(_project, _draft)
	if result.get("ok", false):
		_status.text = "Создан безопасный Promotion Review: не production, не runtime."
		_path.text = str(result["path"])
	else:
		_status.text = "Promotion Review заблокирован: " + str(result.get("error", ""))


## VNS5-06D1: review-only four-registry package, never res:// or runtime.
func _export_package_template() -> void:
	if _blocked or _project.is_empty():
		return
	if _dirty:
		_status.text = "Сначала сохраните Raven-черновик, затем создайте шаблон manifest."
		return
	var result: Dictionary = Store.export_package_manifest_template(_project, _draft)
	if result.get("ok", false):
		_path.text = str(result["path"])
		_status.text = "Создан пустой manifest в user://. Заполните постановки, маршруты и cue и импортируйте JSON в Promotion Review."
	else:
		_status.text = "Manifest template: " + str(result.get("error", ""))


func _export_four_registry_review(manifest: Dictionary) -> void:
	if _blocked or _project.is_empty():
		return
	if _dirty:
		_status.text = "Сначала сохраните Raven-черновик, затем экспортируйте четыре каталога."
		return
	var result: Dictionary = Store.export_four_registry_review(_project, _draft, manifest)
	if result.get("ok", false):
		_path.text = str(result["path"])
		_status.text = "Создан four-registry JSON review пакет; production не изменён, runtime запрещён."
	else:
		_status.text = "Four-registry export отклонён: " + str(result.get("error", ""))


func _on_graph_scene_focus(scene_id: String) -> void:
	if _blocked or _project.is_empty():
		return
	# A GraphNode click emits during GUI input dispatch. Rebuilding the graph
	# synchronously here could free the node before its click event finishes.
	call_deferred("_apply_graph_scene_focus", scene_id)


func _apply_graph_scene_focus(scene_id: String) -> void:
	if _blocked or _project.is_empty():
		return
	var scenes: Array = Store.scene_records(_project, _draft)
	for index in range(scenes.size()):
		if str(scenes[index].get("sceneId", "")) == scene_id:
			if index != _scene_idx:
				_scene_idx = index
				_scene_switch()
			return


func _on_graph_modified(data: Dictionary) -> void:
	if _blocked or _project.is_empty():
		return
	var id: String = str(data.get("sceneId", ""))
	if _draft.get("storyGraphPatches", {}).get(id, {}) == data:
		return
	var snapshot: Dictionary = _draft.duplicate(true)
	var error: String = Store.set_story_graph(_project, _draft, data)
	if not error.is_empty():
		_status.text = "Story Map не сохранена: " + error
		_raven_graph.set_context(_project, _draft, str(Store.scene_records(_project, _draft)[_scene_idx]["sceneId"]))
		return
	_undo.append(snapshot)
	_redo.clear()
	_dirty = true
	_update_diff()
	_refresh_buttons()


func _export_graph_candidate() -> void:
	if _blocked or _project.is_empty() or (_draft.get("storyGraphPatches", {}).is_empty() and _draft.get("authoredLines", []).is_empty()):
		return
	if _dirty:
		_status.text = "Сначала сохраните локальный Raven-черновик, затем экспортируйте Story Map."
		return
	var result: Dictionary = Store.export_story_graph_candidate(_project, _draft)
	if result.get("ok", false):
		_status.text = "Создан Story Map review JSON (не runtime; без перезаписи канона)."
		_path.text = str(result["path"])
	else:
		_status.text = "Story Map export заблокирован: " + str(result.get("error", ""))


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
		_stage_designer.set_scene(_project, _draft, str(Store.scene_records(_project, _draft)[_scene_idx]["sceneId"]))
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
		_stage_designer.set_scene(_project, _draft, str(Store.scene_records(_project, _draft)[_scene_idx]["sceneId"]))
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
		_stage_designer.set_scene(_project, _draft, str(Store.scene_records(_project, _draft)[_scene_idx]["sceneId"]))
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
		"Автор" if entry.get("speakerId") == Store.Author.NARRATOR_ID else str(entry.get("speakerId", "")).trim_prefix("RM-CHAR-"),
		str(loc.get("text", "")), str(entry.get("id", "")))
