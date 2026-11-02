@tool
extends VBoxContainer
## VNS5-06A: native, review-only Raven Story Map workspace.
## Canonical gates remain read-only. Scene-to-scene drag creates only reviewed draft edges.
signal graph_modified(overlay: Dictionary)
signal scene_focus_requested(scene_id: String)

const Graph = preload("res://addons/vn_studio/model/raven_story_graph_draft.gd")
var _project: Dictionary = {}
var _draft: Dictionary = {}
var _scene_id: String = ""
var _overlay: Dictionary = {}
var _canvas: GraphEdit
var _summary: Label
var _full: CheckBox
var _kind: OptionButton
var _target: OptionButton
var _checkpoint: OptionButton
var _choice: OptionButton
var _label: LineEdit
var _edge_list: ItemList
var _remove: Button
var _update: Button
var _inspect: Label
var _name_map: Dictionary = {}
var _node_to_id: Dictionary = {}
var _visible_edges: Array = []
var _edge_popup: PopupMenu
var _popup_edge_ids: Array[String] = []
var _editing_edge: int = -1


func _ready() -> void:
	size_flags_horizontal = SIZE_EXPAND_FILL
	size_flags_vertical = SIZE_EXPAND_FILL
	var toolbar := HFlowContainer.new()
	add_child(toolbar)
	var title := Label.new()
	title.text = "Story Map · канон (только просмотр) + черновые связи"
	title.size_flags_horizontal = SIZE_EXPAND_FILL
	toolbar.add_child(title)
	_full = CheckBox.new()
	_full.text = "Все сцены"
	_full.toggled.connect(_on_full)
	toolbar.add_child(_full)
	_summary = Label.new()
	_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_summary)
	_canvas = GraphEdit.new()
	_canvas.custom_minimum_size = Vector2(340, 310)
	_canvas.size_flags_horizontal = SIZE_EXPAND_FILL
	_canvas.size_flags_vertical = SIZE_EXPAND_FILL
	_canvas.minimap_enabled = true
	_canvas.connection_request.connect(_on_connection_request)
	_canvas.disconnection_request.connect(_reject_disconnection)
	_canvas.gui_input.connect(_on_canvas_input)
	add_child(_canvas)
	_edge_popup = PopupMenu.new()
	_edge_popup.id_pressed.connect(_on_edge_popup_selected)
	add_child(_edge_popup)
	_inspect = Label.new()
	_inspect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_inspect.text = "Кликните сцену для выбора источника, протяните провод для создания draft-связи или кликните существующий провод для её редактирования."
	add_child(_inspect)
	var bar := HFlowContainer.new()
	add_child(bar)
	_kind = OptionButton.new()
	for kind in Graph.KINDS:
		_kind.add_item(kind)
	_kind.item_selected.connect(_on_kind)
	bar.add_child(_kind)
	_target = OptionButton.new()
	_target.custom_minimum_size.x = 185
	bar.add_child(_target)
	_checkpoint = OptionButton.new()
	_checkpoint.custom_minimum_size.x = 185
	_checkpoint.tooltip_text = "Контрольная реплика выбора принадлежит текущей сцене"
	bar.add_child(_checkpoint)
	_choice = OptionButton.new()
	for choice in ["A", "B", "C"]:
		_choice.add_item(choice)
	bar.add_child(_choice)
	_label = LineEdit.new()
	_label.custom_minimum_size.x = 190
	_label.placeholder_text = "Подпись перехода (черновик)"
	bar.add_child(_label)
	var add := Button.new()
	add.text = "+ Связь"
	add.tooltip_text = "Создать review-only переход; не изменяет игровой reducer или route gate"
	add.pressed.connect(_on_add)
	bar.add_child(add)
	_update = Button.new()
	_update.text = "Сохранить связь"
	_update.disabled = true
	_update.tooltip_text = "Изменить выделенную черновую связь (id сохранится). Канон неизменяем."
	_update.pressed.connect(_on_update)
	bar.add_child(_update)
	var list_row := HFlowContainer.new()
	add_child(list_row)
	_edge_list = ItemList.new()
	_edge_list.custom_minimum_size = Vector2(320, 70)
	_edge_list.size_flags_horizontal = SIZE_EXPAND_FILL
	_edge_list.item_selected.connect(_on_edge_selected)
	list_row.add_child(_edge_list)
	_remove = Button.new()
	_remove.text = "− Связь"
	_remove.disabled = true
	_remove.pressed.connect(_on_remove)
	list_row.add_child(_remove)
	_on_kind(0)


func set_context(project: Dictionary, draft: Dictionary, scene_id: String) -> void:
	_project = project
	_draft = draft
	_scene_id = scene_id
	_overlay = Graph.effective(draft, scene_id)
	_refresh()


func _on_kind(_index: int) -> void:
	if _target == null:
		return
	_target.clear()
	var kind: String = _kind.get_item_text(_kind.selected)
	var targets: Array = Graph.level_ids(_project) if kind == "match3" else Graph.scene_ids(_project)
	for target in targets:
		_target.add_item(str(target))
	_checkpoint.clear()
	for entry in _project.get("linesByScene", {}).get(_scene_id, []):
		_checkpoint.add_item(str(entry.get("id", "")))
	_checkpoint.disabled = kind != "choice"
	_choice.disabled = kind != "choice"
	if _label.text.is_empty():
		_label.placeholder_text = "Выбор / переход / Match-3 (для review)"


func _select_option(control: OptionButton, value: String) -> bool:
	for index in range(control.item_count):
		if control.get_item_text(index) == value:
			control.select(index)
			return true
	return false


func _fields() -> Dictionary:
	var kind: String = _kind.get_item_text(_kind.selected)
	return {
		"kind": kind,
		"targetId": _target.get_item_text(_target.selected) if _target.selected >= 0 else "",
		"label": _label.text.strip_edges(),
		"lineId": _checkpoint.get_item_text(_checkpoint.selected) if kind == "choice" and _checkpoint.selected >= 0 else "",
		"choiceKey": _choice.get_item_text(_choice.selected) if kind == "choice" and _choice.selected >= 0 else ""
	}


func _commit_overlay(candidate: Dictionary) -> bool:
	var error: String = Graph.validate(_project, candidate)
	if not error.is_empty():
		_summary.text = "Связь не сохранена: " + error
		return false
	_overlay = candidate
	graph_modified.emit(candidate.duplicate(true))
	_refresh()
	return true


func _on_add() -> void:
	if _scene_id.is_empty() or _target.selected < 0:
		_summary.text = "Выберите исходную сцену и существующий target."
		return
	var fields: Dictionary = _fields()
	var candidate: Dictionary = Graph.next_edge(_overlay, fields["kind"], fields["targetId"],
		fields["label"], fields["lineId"], fields["choiceKey"])
	_commit_overlay(candidate)


func _on_edge_selected(index: int) -> void:
	if index < 0 or index >= _overlay.get("edges", []).size():
		return
	_editing_edge = index
	var edge: Dictionary = _overlay["edges"][index]
	var kind: String = str(edge["kind"])
	_select_option(_kind, kind)
	_on_kind(_kind.selected)
	_select_option(_target, str(edge["targetId"]))
	if kind == "choice":
		_select_option(_checkpoint, str(edge.get("lineId", "")))
		_select_option(_choice, str(edge.get("choiceKey", "A")))
	_label.text = str(edge["label"])
	_remove.disabled = false
	_update.disabled = false
	_inspect.text = "Черновик %s · %s → %s. Поля выше можно изменить, затем нажать «Сохранить связь»." % [
		edge["id"], _scene_id, edge["targetId"]]


func _on_update() -> void:
	if _editing_edge < 0 or _editing_edge >= _overlay.get("edges", []).size():
		_summary.text = "Сначала выберите черновую связь из списка."
		return
	var candidate: Dictionary = _overlay.duplicate(true)
	var edge: Dictionary = candidate["edges"][_editing_edge]
	var fields: Dictionary = _fields()
	edge["kind"] = fields["kind"]
	edge["targetId"] = fields["targetId"]
	edge["label"] = fields["label"]
	if fields["kind"] == "choice":
		edge["lineId"] = fields["lineId"]
		edge["choiceKey"] = fields["choiceKey"]
	else:
		edge.erase("lineId")
		edge.erase("choiceKey")
	_commit_overlay(candidate)


func _on_remove() -> void:
	var selected: PackedInt32Array = _edge_list.get_selected_items()
	if selected.is_empty():
		return
	var candidate: Dictionary = _overlay.duplicate(true)
	candidate["edges"].remove_at(selected[0])
	_commit_overlay(candidate)


func _on_node_selected(id: String) -> void:
	var is_scene: bool = Graph.scene_ids(_project).has(id)
	_inspect.text = ("%s · кликните и протяните провод из правого порта к левой точке целевой сцены. " % id +
		"Все изменения — только draft/review, не gameplay.") if is_scene else (
		"%s · канонический gate или Match-3, не редактируется перетаскиванием." % id)
	if is_scene and id != _scene_id:
		scene_focus_requested.emit(id)


func _on_connection_request(from_name: StringName, _from_port: int,
		to_name: StringName, _to_port: int) -> void:
	var source: String = str(_node_to_id.get(str(from_name), ""))
	var target: String = str(_node_to_id.get(str(to_name), ""))
	if not Graph.scene_ids(_project).has(source) or source != _scene_id:
		_summary.text = "Сначала кликните исходную сцену, затем протяните связь из её правого порта."
		return
	if target.begins_with("m3:"):
		_select_option(_kind, "match3")
		_on_kind(_kind.selected)
		target = target.trim_prefix("m3:")
	elif Graph.scene_ids(_project).has(target):
		if _kind.get_item_text(_kind.selected) == "match3":
			_select_option(_kind, "scene")
			_on_kind(_kind.selected)
	else:
		_summary.text = "Редактировать канонические gate-связи нельзя. Выберите другую сцену."
		return
	if not _select_option(_target, target):
		_summary.text = "Целевая сцена или уровень не найдены: " + target
		return
	var fields: Dictionary = _fields()
	var label_text: String = fields["label"]
	if label_text.is_empty():
		label_text = ("Выбор %s" % fields["choiceKey"]) if fields["kind"] == "choice" else ("Переход к " + target)
	var candidate: Dictionary = Graph.next_edge(_overlay, fields["kind"], target,
		label_text, fields["lineId"], fields["choiceKey"])
	if _commit_overlay(candidate):
		_inspect.text = "Создан черновой %s → %s: %s. Для изменения выберите строку в списке связей." % [
			source, target, label_text]



## GraphEdit itself receives left clicks on the rendered connection layer.
## The Godot API returns node names and ports, never our stable draft edge IDs.
func _on_canvas_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	var mouse: InputEventMouseButton = event
	if mouse.button_index != MOUSE_BUTTON_LEFT or not mouse.pressed:
		return
	var connection: Dictionary = _canvas.get_closest_connection_at_point(mouse.position, 12.0)
	if not connection.is_empty():
		_select_graph_connection(connection, mouse.position)


func _clear_edge_selection() -> void:
	_edge_list.deselect_all()
	_editing_edge = -1
	_update.disabled = true
	_remove.disabled = true


func _edge_index_for_id(edge_id: String) -> int:
	for index in range(_overlay.get("edges", []).size()):
		if str(_overlay["edges"][index].get("id", "")) == edge_id:
			return index
	return -1


func _select_edge_id(edge_id: String) -> void:
	var index: int = _edge_index_for_id(edge_id)
	if index < 0:
		_clear_edge_selection()
		_summary.text = "Черновая связь больше не существует: " + edge_id
		return
	_edge_list.select(index)
	_on_edge_selected(index)


func _on_edge_popup_selected(item_id: int) -> void:
	if item_id < 0 or item_id >= _popup_edge_ids.size():
		return
	_select_edge_id(_popup_edge_ids[item_id])


func _select_graph_connection(connection: Dictionary, position: Vector2 = Vector2.ZERO) -> void:
	var from_id: String = str(_node_to_id.get(str(connection.get("from_node", "")), ""))
	var to_id: String = str(_node_to_id.get(str(connection.get("to_node", "")), ""))
	var matches: Array[String] = Graph.draft_ids_for_connection(
		_visible_edges, from_id, to_id, _scene_id)
	if matches.is_empty():
		_clear_edge_selection()
		if from_id == _scene_id:
			_inspect.text = "Канонический переход %s → %s. Его нельзя редактировать в Story Map; для изменения нужен отдельный approval." % [from_id, to_id]
		else:
			_inspect.text = "Связь %s → %s принадлежит другой сцене или является канонической. Сначала выберите исходную сцену." % [from_id, to_id]
		return
	if matches.size() == 1:
		_select_edge_id(matches[0])
		return
	# GraphEdit paints parallel A/B/C edges to the same target as one wire.
	# Never edit an arbitrary branch: ask the user which stable ID they mean.
	_popup_edge_ids = matches
	_edge_popup.clear()
	for index in range(matches.size()):
		var edge_index: int = _edge_index_for_id(matches[index])
		if edge_index < 0:
			continue
		var edge: Dictionary = _overlay["edges"][edge_index]
		_edge_popup.add_item("%s · %s · %s" % [
			matches[index], str(edge.get("choiceKey", edge.get("kind", ""))),
			str(edge.get("label", ""))], index)
	_inspect.text = "На этом проводе %d черновых переходов: выберите конкретный ID из меню." % matches.size()
	_edge_popup.popup(Rect2i(
		Vector2i(_canvas.get_screen_position() + position), Vector2i(300, 24 * matches.size() + 12)))


func _on_full(_pressed: bool) -> void:
	_render_graph()


func _refresh() -> void:
	if _canvas == null or _project.is_empty():
		return
	_on_kind(_kind.selected)
	_edge_list.clear()
	_editing_edge = -1
	_update.disabled = true
	for edge in _overlay.get("edges", []):
		var suffix: String = (" · " + str(edge.get("lineId", "")) + "/" +
			str(edge.get("choiceKey", ""))) if edge.get("kind") == "choice" else ""
		_edge_list.add_item("%s · %s → %s%s · %s" % [edge["id"], edge["kind"], edge["targetId"], suffix, edge["label"]])
	_remove.disabled = true
	_render_graph()


func _render_graph() -> void:
	if _canvas == null or _project.is_empty():
		return
	_canvas.clear_connections()
	for child in _canvas.get_children():
		if child is GraphNode:
			_canvas.remove_child(child)
			child.queue_free()
	_name_map.clear()
	_node_to_id.clear()
	_visible_edges.clear()
	_popup_edge_ids.clear()
	# Draw the exact existing route gates and authored draft edges separately.
	var graph: Dictionary = Graph.build(_project, _draft)
	# The local overlay may have been edited but not yet committed into _draft.
	var preview_draft: Dictionary = _draft.duplicate(true)
	if not preview_draft.has("storyGraphPatches"):
		preview_draft["storyGraphPatches"] = {}
	preview_draft["storyGraphPatches"][_scene_id] = _overlay.duplicate(true)
	graph = Graph.build(_project, preview_draft)
	if not _full.button_pressed:
		graph = Graph.neighborhood(graph, _scene_id)
	_visible_edges = graph.get("edges", []).duplicate(true)
	var node_ids: Array = graph.get("nodes", {}).keys()
	node_ids.sort_custom(func(a, b):
		var first: Dictionary = graph["nodes"][a]
		var second: Dictionary = graph["nodes"][b]
		return int(first["ordinal"]) < int(second["ordinal"]) if first["ordinal"] != second["ordinal"] else str(a) < str(b))
	for id in node_ids:
		var info: Dictionary = graph["nodes"][id]
		var kind: String = str(info["kind"])
		var node := GraphNode.new()
		node.name = "Node%03d" % _name_map.size()
		node.title = ("СЦЕНА · " if kind == "scene" else "GATE · " if kind == "gate" else "MATCH-3 · ") + str(info.get("title", id)).left(58)
		node.resizable = false
		node.position_offset = Vector2(float(int(info["ordinal"]) % 5) * 325.0 + (100.0 if kind != "scene" else 0.0),
			float(int(info["ordinal"]) / 5) * 235.0 + (95.0 if kind != "scene" else 0.0))
		var label := Label.new()
		label.text = str(id).left(64)
		label.custom_minimum_size.x = 165
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		node.add_child(label)
		node.node_selected.connect(_on_node_selected.bind(str(id)))
		node.set_slot(0, true, 0, Color(0.3, 0.82, 0.65), true, 0, Color(0.3, 0.82, 0.65))
		_canvas.add_child(node)
		_name_map[id] = node.name
		_node_to_id[str(node.name)] = str(id)
	for edge in graph.get("edges", []):
		if _name_map.has(edge["from"]) and _name_map.has(edge["to"]):
			var a: StringName = StringName(_name_map[edge["from"]])
			var b: StringName = StringName(_name_map[edge["to"]])
			if not _canvas.is_node_connected(a, 0, b, 0):
				_canvas.connect_node(a, 0, b, 0)
	_summary.text = "%s · %d канонических trigger/связей (без редактирования) · %d draft связей. Никакой runtime не изменён." % [
		_scene_id, graph.get("edges", []).filter(func(edge): return edge.get("kind") == "canonical").size(),
		_overlay.get("edges", []).size()]


func _reject_disconnection(_from: StringName, _from_port: int, _to: StringName, _to_port: int) -> void:
	_summary.text = "Удаляйте только черновые связи в списке ниже; канонические гейты защищены."
