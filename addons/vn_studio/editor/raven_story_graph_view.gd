@tool
extends VBoxContainer
## VNS5-06A: native, review-only Raven Story Map workspace.
## Canonical gates are visually read-only. Draft connections use typed controls.
signal graph_modified(overlay: Dictionary)

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
var _name_map: Dictionary = {}
var _suppress: bool = false


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
	_canvas.connection_request.connect(_reject_connection)
	_canvas.disconnection_request.connect(_reject_disconnection)
	add_child(_canvas)
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


func _on_add() -> void:
	if _scene_id.is_empty() or _target.selected < 0:
		_summary.text = "Выберите сцену и существующий target."
		return
	var kind: String = _kind.get_item_text(_kind.selected)
	var target: String = _target.get_item_text(_target.selected)
	var label_text: String = _label.text.strip_edges()
	var line_id: String = _checkpoint.get_item_text(_checkpoint.selected) if kind == "choice" and _checkpoint.selected >= 0 else ""
	var choice_key: String = _choice.get_item_text(_choice.selected) if kind == "choice" and _choice.selected >= 0 else ""
	var candidate: Dictionary = Graph.next_edge(_overlay, kind, target, label_text, line_id, choice_key)
	var error: String = Graph.validate(_project, candidate)
	if not error.is_empty():
		_summary.text = "Связь не сохранена: " + error
		return
	_overlay = candidate
	graph_modified.emit(candidate.duplicate(true))
	_label.clear()
	_refresh()


func _on_edge_selected(_index: int) -> void:
	_remove.disabled = false


func _on_remove() -> void:
	var selected: PackedInt32Array = _edge_list.get_selected_items()
	if selected.is_empty():
		return
	var candidate: Dictionary = _overlay.duplicate(true)
	candidate["edges"].remove_at(selected[0])
	var error: String = Graph.validate(_project, candidate)
	if not error.is_empty():
		_summary.text = error
		return
	_overlay = candidate
	graph_modified.emit(candidate.duplicate(true))
	_refresh()


func _on_full(_pressed: bool) -> void:
	_render_graph()


func _refresh() -> void:
	if _canvas == null or _project.is_empty():
		return
	_on_kind(_kind.selected)
	_edge_list.clear()
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
		node.add_child(label)
		node.set_slot(0, true, 0, Color(0.3, 0.82, 0.65), true, 0, Color(0.3, 0.82, 0.65))
		_canvas.add_child(node)
		_name_map[id] = node.name
	for edge in graph.get("edges", []):
		if _name_map.has(edge["from"]) and _name_map.has(edge["to"]):
			var a: StringName = StringName(_name_map[edge["from"]])
			var b: StringName = StringName(_name_map[edge["to"]])
			if not _canvas.is_node_connected(a, 0, b, 0):
				_canvas.connect_node(a, 0, b, 0)
	_summary.text = "%s · %d канонических trigger/связей (без редактирования) · %d draft связей. Никакой runtime не изменён." % [
		_scene_id, graph.get("edges", []).filter(func(edge): return edge.get("kind") == "canonical").size(),
		_overlay.get("edges", []).size()]


func _reject_connection(_from: StringName, _from_port: int, _to: StringName, _to_port: int) -> void:
	_summary.text = "Drag-connection не создаёт сюжетных переходов: выберите тип, target и подпись ниже."


func _reject_disconnection(_from: StringName, _from_port: int, _to: StringName, _to_port: int) -> void:
	_summary.text = "Исходные гейты нельзя отключить графическим перетаскиванием."
