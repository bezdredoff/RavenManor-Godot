@tool
extends VBoxContainer
## Native, read-only Raven asset browser. Candidate images stay candidates.
const Registry = preload("res://addons/vn_studio/model/asset_registry.gd")
const StagedImages = preload("res://addons/vn_studio/model/staged_image_store.gd")

var _registry: Dictionary = {}
var _visible: Array[Dictionary] = []
var _search: LineEdit
var _category: OptionButton
var _status_filter: OptionButton
var _orientation: OptionButton
var _group: OptionButton
var _list: ItemList
var _scene_label: Label
var _summary: Label
var _a: Dictionary = {}
var _b: Dictionary = {}
var _compare_labels: Array[Label] = []
var _compare_images: Array[TextureRect] = []
var _staged_store: RefCounted
var _stage_picker: EditorFileDialog
var _stage_panel: VBoxContainer
var _stage_list: ItemList
var _stage_preview: TextureRect
var _stage_details: Label
var _stage_message: Label
var _stage_id: String = ""
var _stage_category: OptionButton
var _stage_inputs: Dictionary = {}
var _stage_loading: bool = false
var _stage_failures: Array[String] = []


func _ready() -> void:
	size_flags_horizontal = SIZE_EXPAND_FILL
	size_flags_vertical = SIZE_EXPAND_FILL
	_build_ui()
	set_registry(Registry.open_project(ProjectSettings.globalize_path("res://")))
	_staged_store = StagedImages.new()
	var result: Dictionary = _staged_store.open_project(ProjectSettings.globalize_path("res://"))
	_stage_message.text = "Staging загружен · только user://" if result.get("ok", false) else str(result.get("error", "Ошибка staging"))
	_refresh_staged()


func _build_ui() -> void:
	_scene_label = Label.new()
	_scene_label.text = "Библиотека Raven · выберите сцену"
	add_child(_scene_label)
	_build_stage_ui()
	var filters := HFlowContainer.new()
	add_child(filters)
	_search = LineEdit.new()
	_search.placeholder_text = "Поиск ID, состояния или источника…"
	_search.custom_minimum_size.x = 190
	_search.text_changed.connect(func(_value: String): _refresh())
	filters.add_child(_search)
	_category = _filter(filters, ["Все категории", "Фоны", "Персонажи", "Реквизит"])
	_status_filter = _filter(filters, ["Любой статус", "candidate", "accepted", "planned_metadata"])
	_orientation = _filter(filters, ["Любая ориентация", "portrait", "landscape", "unregistered"])
	_group = _filter(filters, ["Все семейства"])
	_summary = Label.new()
	_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_summary)
	_list = ItemList.new()
	_list.custom_minimum_size.y = 150
	_list.size_flags_vertical = SIZE_EXPAND_FILL
	_list.item_selected.connect(_on_selected)
	add_child(_list)
	var actions := HFlowContainer.new()
	add_child(actions)
	for slot in ["A", "B"]:
		var pin := Button.new()
		pin.text = "Сравнить: " + slot
		pin.pressed.connect(_pin.bind(slot))
		actions.add_child(pin)
	var comparison := HBoxContainer.new()
	add_child(comparison)
	for slot in ["A", "B"]:
		var card := VBoxContainer.new()
		card.size_flags_horizontal = SIZE_EXPAND_FILL
		comparison.add_child(card)
		var picture := TextureRect.new()
		picture.custom_minimum_size = Vector2(100, 170)
		picture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		card.add_child(picture)
		_compare_images.append(picture)
		var label := Label.new()
		label.text = slot + ": не выбрано"
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.add_child(label)
		_compare_labels.append(label)


func _filter(parent: Control, choices: Array[String]) -> OptionButton:
	var picker := OptionButton.new()
	for choice in choices:
		picker.add_item(choice)
	picker.item_selected.connect(func(_index: int): _refresh())
	parent.add_child(picker)
	return picker


func set_registry(registry: Dictionary) -> void:
	_registry = registry
	_a = {}
	_b = {}
	if _list == null:
		return
	_group.clear()
	_group.add_item("Все семейства")
	if registry.get("ok", false):
		var groups: Array = registry.get("familyIds", registry.get("masterIds", [])).duplicate()
		groups.sort()
		for group in groups:
			_group.add_item(str(group))
	_refresh()
	_render_compare()


func set_scene_context(scene_id: String) -> void:
	if _scene_label != null:
		_scene_label.text = "Библиотека Raven · " + scene_id


func _refresh() -> void:
	if _list == null:
		return
	_list.clear()
	_visible.clear()
	if not _registry.get("ok", false):
		_summary.text = str(_registry.get("error", "Каталог недоступен"))
		return
	var category_key: String = ["", "background", "character", "prop"][_category.selected]
	var status_key: String = "" if _status_filter.selected == 0 else _status_filter.get_item_text(_status_filter.selected)
	var orientation_key: String = "" if _orientation.selected == 0 else _orientation.get_item_text(_orientation.selected)
	var group_key: String = "" if _group.selected == 0 else _group.get_item_text(_group.selected)
	var needle: String = _search.text.strip_edges().to_lower()
	for record: Dictionary in _registry["records"]:
		if not category_key.is_empty() and record["category"] != category_key:
			continue
		if not status_key.is_empty() and record["status"] != status_key:
			continue
		if not orientation_key.is_empty() and record["orientation"] != orientation_key:
			continue
		if not group_key.is_empty() and record["groupId"] != group_key:
			continue
		var searchable: String = "%s %s %s %s %s %s %s" % [record["id"], record["groupId"], record.get("roomState", ""), record.get("sourceType", ""), record.get("displayName", ""), record.get("pose", ""), record.get("emotion", "")]
		if not needle.is_empty() and not searchable.to_lower().contains(needle):
			continue
		_visible.append(record)
		_list.add_item("%s · %s · %s" % [record.get("displayName", record["id"]), record["status"], record["integrity"]])
	_summary.text = "%d фонов / %d персонажей / %d кадров персонажей / %d отдельных props · %d показано · %d проблем файлов." % [
		_registry["backgroundCount"], _registry["characterCount"], _registry.get("portraitCount", 0), _registry["propCount"],
		_visible.size(), _registry["issues"].size()]


func _on_selected(_index: int) -> void:
	pass # Selection alone never writes a draft or changes stage state.


func _pin(slot: String) -> void:
	var selected: PackedInt32Array = _list.get_selected_items()
	if selected.is_empty() or selected[0] >= _visible.size():
		return
	if slot == "A":
		_a = _visible[selected[0]]
	else:
		_b = _visible[selected[0]]
	_render_compare()


func _render_compare() -> void:
	for i in range(2):
		var record: Dictionary = _a if i == 0 else _b
		_compare_images[i].texture = null
		if record.is_empty():
			_compare_labels[i].text = ("A" if i == 0 else "B") + ": не выбрано"
			continue
		_compare_labels[i].text = "%s · %s\n%s · %s\nПрава: %s\n%s\n%s" % [
			record["id"], record["status"], record["orientation"], record["integrity"],
			record["rights"], record.get("path", ""), record.get("sha256", "Арты не зарегистрированы")]
		var path: String = str(record.get("path", ""))
		var approved_folder: bool = path.begins_with("res://assets/raven/vn_backgrounds/") or path.begins_with("res://assets/raven/characters/")
		if record["integrity"] == "ok" and approved_folder and not path.contains("..") and ResourceLoader.exists(path):
			_compare_images[i].texture = load(path) as Texture2D


func _build_stage_ui() -> void:
	var toggle := Button.new()
	toggle.text = "Локальный импорт PNG / JPEG / WebP (user://)  ▾"
	toggle.pressed.connect(func(): _stage_panel.visible = not _stage_panel.visible)
	add_child(toggle)
	_stage_panel = VBoxContainer.new()
	_stage_panel.visible = false
	add_child(_stage_panel)
	var controls := HFlowContainer.new()
	_stage_panel.add_child(controls)
	for action in ["Выбрать несколько файлов…", "Удалить staged", "Очистить ошибки", "Export review candidate"]:
		var button := Button.new()
		button.text = action
		controls.add_child(button)
		match action:
			"Выбрать несколько файлов…": button.pressed.connect(func(): _stage_picker.popup_centered_ratio(0.75))
			"Удалить staged": button.pressed.connect(_remove_staged)
			"Очистить ошибки": button.pressed.connect(_clear_stage_failures)
			"Export review candidate": button.pressed.connect(_export_staged)
	_stage_picker = EditorFileDialog.new()
	_stage_picker.access = EditorFileDialog.ACCESS_FILESYSTEM
	_stage_picker.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILES
	_stage_picker.add_filter("*.png, *.jpg, *.jpeg, *.webp", "Raster images")
	_stage_picker.files_selected.connect(_on_stage_files)
	add_child(_stage_picker)
	_stage_list = ItemList.new()
	_stage_list.custom_minimum_size.y = 100
	_stage_list.item_selected.connect(_select_staged)
	_stage_panel.add_child(_stage_list)
	_stage_preview = TextureRect.new()
	_stage_preview.custom_minimum_size = Vector2(120, 155)
	_stage_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_stage_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_stage_panel.add_child(_stage_preview)
	_stage_details = Label.new()
	_stage_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_stage_panel.add_child(_stage_details)
	var category_row := HFlowContainer.new()
	_stage_panel.add_child(category_row)
	var category_label := Label.new()
	category_label.text = "Категория"
	category_row.add_child(category_label)
	_stage_category = OptionButton.new()
	for choice in ["background", "character", "prop"]:
		_stage_category.add_item(choice)
	category_row.add_child(_stage_category)
	for key in ["displayName", "groupId", "lighting", "state", "pose", "emotion", "costume", "provenance", "license"]:
		var row := HFlowContainer.new()
		_stage_panel.add_child(row)
		var caption := Label.new()
		caption.text = key
		caption.custom_minimum_size.x = 96
		row.add_child(caption)
		var input := LineEdit.new()
		input.placeholder_text = "BG-HALL / BG-NEW / canonical character ID / PROP-NEW" if key == "groupId" else "Обязательно для export" if key in ["displayName", "provenance", "license"] else "Не задано"
		input.custom_minimum_size.x = 185
		input.size_flags_horizontal = SIZE_EXPAND_FILL
		row.add_child(input)
		_stage_inputs[key] = input
	var save := Button.new()
	save.text = "Сохранить metadata draft (локально)"
	save.pressed.connect(_save_staged_metadata)
	_stage_panel.add_child(save)
	_stage_message = Label.new()
	_stage_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_stage_panel.add_child(_stage_message)


func _refresh_staged() -> void:
	if _stage_list == null or _staged_store == null:
		return
	_stage_list.clear()
	for item in _staged_store.list_items():
		_stage_list.add_item("%s · %s · %s" % [item["originalFilename"], item["category"], item["orientation"]])
	if not _stage_id.is_empty():
		var index: int = _stage_index(_stage_id)
		if index >= 0:
			_stage_list.select(index)
			_show_staged(index)
			return
	_stage_id = ""
	_stage_preview.texture = null
	_stage_details.text = "%d локальных черновиков. Metadata не изменяют production catalogs." % _staged_store.list_items().size()


func _stage_index(id: String) -> int:
	var items: Array = _staged_store.list_items()
	for index in items.size():
		if items[index]["id"] == id:
			return index
	return -1


func _select_staged(index: int) -> void:
	_show_staged(index)


func _show_staged(index: int) -> void:
	var items: Array = _staged_store.list_items()
	if index < 0 or index >= items.size():
		return
	var item: Dictionary = items[index]
	_stage_id = item["id"]
	var img: Image = _staged_store.get_preview(_stage_id)
	_stage_preview.texture = ImageTexture.create_from_image(img) if img != null else null
	_stage_details.text = "%s · %d×%d · %s · alpha=%s · SHA256=%s\n%s" % [
		item["id"], item["width"], item["height"], item["orientation"], str(item["alpha"]),
		item["sha256"], item["originalFilename"]]
	_stage_loading = true
	_stage_category.select(["background", "character", "prop"].find(item["category"]))
	for key in _stage_inputs:
		_stage_inputs[key].text = str(item.get(key, ""))
	_stage_loading = false


func _on_stage_files(paths: PackedStringArray) -> void:
	var outcomes: Array[Dictionary] = _staged_store.stage_files(paths)
	var good: int = 0
	var failed: Array[String] = []
	for result in outcomes:
		if result.get("ok", false):
			good += 1
		else:
			failed.append(str(result.get("error", "Ошибка")))
	_stage_failures = failed
	_stage_message.text = "Добавлено: %d / %d. %s" % [good, paths.size(), "; ".join(failed)]
	_refresh_staged()


func _save_staged_metadata() -> void:
	if _stage_id.is_empty():
		_stage_message.text = "Выберите staged image."
		return
	var changes: Dictionary = {"category": _stage_category.get_item_text(_stage_category.selected)}
	for key in _stage_inputs:
		changes[key] = _stage_inputs[key].text
	var result: Dictionary = _staged_store.update_metadata(_stage_id, changes)
	_stage_message.text = "Metadata сохранены только в user://." if result.get("ok", false) else str(result.get("error", "Не сохранено"))
	_refresh_staged()


func _remove_staged() -> void:
	if _stage_id.is_empty():
		_stage_message.text = "Выберите staged image."
		return
	var result: Dictionary = _staged_store.remove_item(_stage_id)
	_stage_message.text = "Staged image удалён." if result.get("ok", false) else str(result.get("error", "Ошибка"))
	_stage_id = ""
	_refresh_staged()


func _export_staged() -> void:
	var result: Dictionary = _staged_store.export_review_candidate()
	_stage_message.text = "Review only (not promoted): " + str(result["path"]) if result.get("ok", false) else str(result.get("error", "Ошибка export"))


func _clear_stage_failures() -> void:
	_stage_failures.clear()
	_stage_message.text = "Ошибки выбора очищены; staged images не изменены."
