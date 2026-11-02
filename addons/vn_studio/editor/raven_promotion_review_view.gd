@tool
extends VBoxContainer
## VNS5-06C: no-apply promotion review panel. Every mapping is explicit.
signal mapping_modified(mapping: Dictionary)
signal export_requested
signal template_requested
signal package_requested(manifest: Dictionary)

const Store = preload("res://addons/vn_studio/editor/raven_story_store.gd")
const Promotion = preload("res://addons/vn_studio/model/raven_story_promotion.gd")
var _project: Dictionary = {}
var _draft: Dictionary = {}
var _rows: VBoxContainer
var _summary: RichTextLabel
var _export_button: Button
var _inputs: Dictionary = {}
var _package_status: Label
var _file_picker: FileDialog
var _manifest: Dictionary = {}
var _package_button: Button


func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	var headline := Label.new()
	headline.text = "Promotion Review · безопасный перенос, БЕЗ применения к игре"
	headline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(headline)
	var explanation := Label.new()
	explanation.text = "Сопоставьте каждому RM-DRAFT-BEAT-XXXX новый утверждаемый RM-BEAT-XX-YY. Это не автопубликация. Без постановки, route gate и save review новые сцены запускать нельзя."
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(explanation)
	_rows = VBoxContainer.new()
	add_child(_rows)
	var bar := HFlowContainer.new()
	add_child(bar)
	var analyze := Button.new()
	analyze.text = "Проверить миграцию ID"
	analyze.pressed.connect(_render_report)
	bar.add_child(analyze)
	_export_button = Button.new()
	_export_button.text = "Экспорт Promotion Review"
	_export_button.tooltip_text = "Только JSON-кандидат в user://, после сохранения черновика"
	_export_button.pressed.connect(func(): export_requested.emit())
	bar.add_child(_export_button)
	var package_bar := HFlowContainer.new()
	add_child(package_bar)
	var template_button := Button.new()
	template_button.text = "1 · Пустой manifest для review"
	template_button.tooltip_text = "Сохранить шаблон постановки, route proposals и performance cues в user://"
	template_button.pressed.connect(func(): template_requested.emit())
	package_bar.add_child(template_button)
	var load_button := Button.new()
	load_button.text = "2 · Открыть заполненный JSON"
	load_button.pressed.connect(func(): _file_picker.popup_centered_ratio(0.8))
	package_bar.add_child(load_button)
	_package_button = Button.new()
	_package_button.text = "3 · Экспорт 4 каталогов (review only)"
	_package_button.disabled = true
	_package_button.pressed.connect(func(): package_requested.emit(_manifest.duplicate(true)))
	package_bar.add_child(_package_button)
	_package_status = Label.new()
	_package_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_package_status.text = "VNS5-06D1: без заполненного manifest новые сцены не публикуются."
	add_child(_package_status)
	_file_picker = FileDialog.new()
	_file_picker.access = FileDialog.ACCESS_FILESYSTEM
	_file_picker.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_file_picker.add_filter("*.json", "Promotion package JSON manifest")
	_file_picker.file_selected.connect(_load_manifest)
	add_child(_file_picker)
	_summary = RichTextLabel.new()
	_summary.custom_minimum_size = Vector2(340, 280)
	_summary.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_summary.bbcode_enabled = false
	add_child(_summary)


func set_context(project: Dictionary, draft: Dictionary) -> void:
	_project = project
	_draft = draft
	_manifest.clear()
	if _package_button != null:
		_package_button.disabled = true
	if _package_status != null:
		_package_status.text = "Сопоставление обновлено. Для пакета импортируйте manifest заново."
	for child in _rows.get_children():
		_rows.remove_child(child)
		child.queue_free()
	_inputs.clear()
	for scene in draft.get("authoredScenes", []):
		var source: String = str(scene["sceneId"])
		var row := HFlowContainer.new()
		_rows.add_child(row)
		var name_label := Label.new()
		name_label.text = source + " → "
		row.add_child(name_label)
		var input := LineEdit.new()
		input.custom_minimum_size.x = 175
		input.max_length = 22
		input.placeholder_text = "RM-BEAT-07-01"
		input.text = str(draft.get("promotionSceneIdMap", {}).get(source, ""))
		input.tooltip_text = "Привязать зарезервированный draft ID к новому production ID (без публикации)"
		row.add_child(input)
		_inputs[source] = input
		input.text_submitted.connect(func(_submitted: String): _save_mapping(source, input.text))
		input.focus_exited.connect(func(): _save_mapping(source, input.text))
	if draft.get("authoredScenes", []).is_empty():
		var hint := Label.new()
		hint.text = "Нет новых сцен. Для добавленных реплик или Story Map отдельное сопоставление sceneId не требуется."
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_rows.add_child(hint)
	_render_report()


func _save_mapping(source: String, raw_target: String) -> void:
	if not _project.get("ok", false) or not _inputs.has(source):
		return
	var next: Dictionary = _draft.get("promotionSceneIdMap", {}).duplicate(true)
	var target: String = raw_target.strip_edges()
	if target.is_empty():
		next.erase(source)
	else:
		next[source] = target
	if next == _draft.get("promotionSceneIdMap", {}):
		return
	var error: String = Promotion.validate_mapping(_project, _draft, next)
	if not error.is_empty():
		_summary.text = "ID не принят: " + error + "\nТекущее сопоставление не изменено."
		return
	mapping_modified.emit(next)


func _render_report() -> void:
	if _summary == null or not _project.get("ok", false):
		return
	var result: Dictionary = Store.promotion_plan(_project, _draft)
	if not result.get("ok", false):
		_summary.text = "Promotion REVIEW не готов:\n" + str(result.get("error", "неизвестная ошибка"))
		_export_button.disabled = true
		return
	var bundle: Dictionary = result["bundle"]
	var change: Dictionary = bundle["diffSummary"]
	var output: String = "Предпросмотр (не runtime):\n"
	output += "Сцены: %d → %d; реплики: %d → %d; правок переводов: %d; исходных сцен с draft-связями: %d\n" % [
		int(change["scenesBefore"]), int(change["scenesProposed"]), int(change["linesBefore"]),
		int(change["linesProposed"]), int(change["changedTextCells"]), int(change["graphSourceScenes"])]
	output += "\nПереназначение IDs: %s\n" % JSON.stringify(bundle["idMap"])
	output += "Релиз БЛОКИРОВАН — нужны утверждение и отдельный PR.\n"
	output += "\nОбязательные задачи (%d):\n" % result["blockers"].size()
	for item in result["blockers"]:
		output += "• " + str(item) + "\n"
	output += "\nПредупреждения (%d):\n" % result["warnings"].size()
	for item in result["warnings"].slice(0, 24):
		output += "• " + str(item) + "\n"
	if result["warnings"].size() > 24:
		output += "… дополнительные предупреждения находятся в полном JSON-кандидате.\n"
	_summary.text = output
	_export_button.disabled = false


func _load_manifest(path: String) -> void:
	_manifest.clear()
	_package_button.disabled = true
	if not FileAccess.file_exists(path):
		_package_status.text = "Manifest не найден."
		return
	var handle: FileAccess = FileAccess.open(path, FileAccess.READ)
	if handle == null:
		_package_status.text = "Не удалось открыть JSON manifest."
		return
	var size: int = handle.get_length()
	handle.close()
	if size <= 0 or size > 524288:
		_package_status.text = "Manifest должен быть непустым JSON не больше 512 КБ."
		return
	var input: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not input is Dictionary:
		_package_status.text = "Файл должен содержать JSON-объект."
		return
	var plan: Dictionary = Store.promotion_plan(_project, _draft)
	if not plan.get("ok", false):
		_package_status.text = "Сначала исправьте Promotion Review: " + str(plan.get("error", ""))
		return
	var checked: Dictionary = Store.Package.assemble(_project, _draft, input)
	if not checked.get("ok", false):
		_package_status.text = "Manifest отклонён: " + str(checked.get("error", ""))
		return
	_manifest = input.duplicate(true)
	_package_button.disabled = false
	_package_status.text = "Manifest проверен. Пакет будет создан только в user://; runtime выключен."
