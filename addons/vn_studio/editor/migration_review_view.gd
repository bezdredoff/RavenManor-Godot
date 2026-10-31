@tool
extends VBoxContainer
## Private local conversion review, no donor writes or runtime/story save mutation.
signal analyze_requested

const Bundle = preload("res://addons/vn_studio/editor/conversion_bundle.gd")

var _project: Dictionary = {}
var _result: Dictionary = {}
var _summary: Label
var _warnings: ItemList
var _files: ItemList
var _details: RichTextLabel
var _confirm: CheckBox
var _export_button: Button
var _path_hint: LineEdit


func _ready() -> void:
	size_flags_horizontal = SIZE_EXPAND_FILL
	size_flags_vertical = SIZE_EXPAND_FILL
	var heading := Label.new()
	heading.text = "Migration & Review · UPDS → VN Studio v1 (private export)"
	heading.add_theme_font_size_override("font_size", 18)
	add_child(heading)
	var description := Label.new()
	description.text = "1. Анализ без записи · 2. Просмотр изменений · 3. Экспорт ТОЛЬКО в user://. UPDS и игра не изменяются."
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(description)
	var actions := HBoxContainer.new()
	add_child(actions)
	var inspect := Button.new()
	inspect.text = "Проверить 45 сцен (dry-run)"
	inspect.pressed.connect(func(): analyze_requested.emit())
	actions.add_child(inspect)
	_confirm = CheckBox.new()
	_confirm.text = "Я проверил отчёт и подтверждаю приватный экспорт"
	_confirm.toggled.connect(_on_confirm)
	actions.add_child(_confirm)
	_export_button = Button.new()
	_export_button.text = "Экспортировать новый bundle"
	_export_button.disabled = true
	_export_button.pressed.connect(_on_export)
	actions.add_child(_export_button)
	_summary = Label.new()
	_summary.text = "Откройте UPDS-godot и выполните dry-run."
	_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_summary)
	var sections := HSplitContainer.new()
	sections.size_flags_vertical = SIZE_EXPAND_FILL
	add_child(sections)
	var list_column := VBoxContainer.new()
	list_column.custom_minimum_size.x = 240
	sections.add_child(list_column)
	var files_label := Label.new()
	files_label.text = "Нормализованные сцены (без записи)"
	list_column.add_child(files_label)
	_files = ItemList.new()
	_files.size_flags_vertical = SIZE_EXPAND_FILL
	_files.item_selected.connect(_on_scene_select)
	list_column.add_child(_files)
	var detail_column := VBoxContainer.new()
	detail_column.size_flags_horizontal = SIZE_EXPAND_FILL
	sections.add_child(detail_column)
	var warn_label := Label.new()
	warn_label.text = "Предупреждения / ограничения"
	detail_column.add_child(warn_label)
	_warnings = ItemList.new()
	_warnings.custom_minimum_size.y = 175
	detail_column.add_child(_warnings)
	_details = RichTextLabel.new()
	_details.bbcode_enabled = false
	_details.size_flags_vertical = SIZE_EXPAND_FILL
	detail_column.add_child(_details)
	var destination_caption := Label.new()
	destination_caption.text = "Путь последнего экспорта (локальная приватная папка, не Git):"
	add_child(destination_caption)
	_path_hint = LineEdit.new()
	_path_hint.editable = false
	_path_hint.placeholder_text = "Появится после явного экспорта."
	add_child(_path_hint)


func set_project(project: Dictionary) -> void:
	_project = project
	invalidate()


func invalidate() -> void:
	_result = {}
	_files.clear()
	_warnings.clear()
	_confirm.button_pressed = false
	_export_button.disabled = true
	_details.text = "Схема предварительная: оригинал сохраняется в legacyOriginal, новые поля в payload. Не подключена к VN runtime."
	_summary.text = "Выполните dry-run для исходной версии и сохранённых черновиков."


func analyze(project: Dictionary, drafts: Dictionary, dirty: Dictionary) -> void:
	_project = project
	invalidate()
	if not dirty.is_empty():
		_summary.text = "Есть несохранённые черновики (%d). Сохраните их, затем повторите анализ." % dirty.size()
		return
	var result: Dictionary = Bundle.prepare(project, drafts)
	if not bool(result.get("ok", false)):
		_summary.text = "Dry-run заблокирован: обнаружены ошибки. Никаких файлов не записано."
		for message in result.get("errors", []):
			_warnings.add_item("ОШИБКА · " + str(message))
		for message in result.get("warnings", []):
			_warnings.add_item("⚠ " + str(message))
		return
	_result = result
	var stats: Dictionary = result["stats"]
	_summary.text = "Готово: %d сцен · %d реплик (ветки учитываются) · %d правок · %d выходных файлов. Источники не изменены." % [
		int(stats["scenes"]), int(stats["lines"]), int(stats["changed"]), int(stats["files"])]
	for item in result["manifest"]["sceneMap"]:
		_files.add_item("%02d · %s · %d изменений" % [int(item["sceneIndex"]), str(item["sceneId"]), int(item["patchedLines"])])
	for message in result["warnings"]:
		_warnings.add_item("⚠ " + str(message))
	_details.text = "Отчёт готов. Выберите сцену слева, затем подтвердите экспорт.\n\n" + (
		"Сохранённые позиции: только карта соответствия; реальные сейвы не конвертируются.\n" +
		"Исходные изображения не копируются. Новый VN-плеер пока не читает этот формат.\n" +
		"Bundle ID: " + str(result["bundleId"]))


func _on_scene_select(idx: int) -> void:
	if not bool(_result.get("ok", false)):
		return
	var map: Array = _result["manifest"]["sceneMap"]
	if idx < 0 or idx >= map.size():
		return
	var item: Dictionary = map[idx]
	_details.text = "Сцена: %s\nIndex: %d\nИсточник: %s\nSHA256: %s\nНовый файл: %s\nНовая SHA256: %s\nГруппы: %s\nРеплик: %d · изменённых: %d\n" % [
		str(item["sceneId"]), int(item["sceneIndex"]), str(item["sourceFile"]),
		str(item["sourceSha256"]), str(item["targetFile"]), str(item["targetSha256"]),
		", ".join(item["branchGroups"]), int(item["lines"]), int(item["patchedLines"])]
	_details.text += "\nОбратимость: legacyOriginal сохранён. Экспорт не затрагивает UPDS, RavenReducer и старые сейвы."


func _on_confirm(_pressed: bool) -> void:
	_export_button.disabled = not bool(_result.get("ok", false)) or not _confirm.button_pressed


func _on_export() -> void:
	if not _confirm.button_pressed or not bool(_result.get("ok", false)):
		return
	var reply: Dictionary = Bundle.export_new_bundle(_project, _result, true)
	if not bool(reply.get("ok", false)):
		_summary.text = "Экспорт НЕ выполнен: " + str(reply.get("error", "неизвестная ошибка"))
		_confirm.button_pressed = false
		return
	_path_hint.text = str(reply["path"])
	_summary.text = "Экспортирован приватный bundle " + str(reply["bundleId"]) + ". Игровая версия и сохранения НЕ переключены."
	_confirm.button_pressed = false
