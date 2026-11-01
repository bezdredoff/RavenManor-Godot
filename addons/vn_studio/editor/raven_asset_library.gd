@tool
extends VBoxContainer
## Native, read-only Raven asset browser. Candidate images stay candidates.
const Registry = preload("res://addons/vn_studio/model/asset_registry.gd")

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


func _ready() -> void:
	size_flags_horizontal = SIZE_EXPAND_FILL
	size_flags_vertical = SIZE_EXPAND_FILL
	_build_ui()
	set_registry(Registry.open_project(ProjectSettings.globalize_path("res://")))


func _build_ui() -> void:
	_scene_label = Label.new()
	_scene_label.text = "Библиотека Raven · выберите сцену"
	add_child(_scene_label)
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
		var groups: Array = registry.get("masterIds", []).duplicate()
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
		var searchable: String = "%s %s %s %s" % [record["id"], record["groupId"], record.get("roomState", ""), record.get("sourceType", "")]
		if not needle.is_empty() and not searchable.to_lower().contains(needle):
			continue
		_visible.append(record)
		_list.add_item("%s · %s · %s" % [record["id"], record["status"], record["integrity"]])
	_summary.text = "%d фонов / %d персонажей / %d зарегистрированных props · %d показано · %d проблем файлов. Отсутствующие позы и props не создаются автоматически." % [
		_registry["backgroundCount"], _registry["characterCount"], _registry["propCount"],
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
		if record["integrity"] == "ok" and path.begins_with("res://assets/raven/vn_backgrounds/") and ResourceLoader.exists(path):
			_compare_images[i].texture = load(path) as Texture2D
