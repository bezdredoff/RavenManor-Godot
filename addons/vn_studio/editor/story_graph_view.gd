@tool
extends VBoxContainer
## GraphEdit view of the real donor transitions. Read-only: move/pan/zoom for inspection only.
signal open_scene_requested(scene_index: int)
const Model = preload("res://addons/vn_studio/editor/story_graph_model.gd")

var _project: Dictionary = {}
var _model: Dictionary = {}
var _focus_id: String = ""
var _locale: String = "ru"
var _show_all: CheckBox
var _canvas: GraphEdit
var _inspector: RichTextLabel
var _summary: Label
var _open_scene: Button
var _selected_key: String = ""
var _graph_names: Dictionary = {}
var _visible: Dictionary = {}


func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	var bar := HBoxContainer.new()
	add_child(bar)
	var title := Label.new()
	title.text = "Граф сюжета UPDS · только просмотр"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(title)
	_show_all = CheckBox.new()
	_show_all.text = "Все сцены"
	_show_all.toggled.connect(_on_full_toggle)
	bar.add_child(_show_all)
	_open_scene = Button.new()
	_open_scene.text = "Открыть сцену"
	_open_scene.disabled = true
	_open_scene.pressed.connect(_on_open_scene)
	bar.add_child(_open_scene)
	_summary = Label.new()
	_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_summary.text = "Откройте локальный UPDS-godot для построения графа."
	add_child(_summary)
	var splitter := VSplitContainer.new()
	splitter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	splitter.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(splitter)
	_canvas = GraphEdit.new()
	_canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_canvas.custom_minimum_size = Vector2(320, 260)
	_canvas.minimap_enabled = true
	_canvas.show_menu = true
	_canvas.connection_request.connect(_reject_connection)
	_canvas.disconnection_request.connect(_reject_disconnection)
	splitter.add_child(_canvas)
	_inspector = RichTextLabel.new()
	_inspector.bbcode_enabled = false
	_inspector.custom_minimum_size.y = 112
	_inspector.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_inspector.text = "Выберите узел: сцена, выбор, Match-3 или финал."
	splitter.add_child(_inspector)


func set_project(project: Dictionary) -> void:
	_project = project
	_model = Model.build(project) if not project.is_empty() else {}
	_selected_key = ""
	_show_all.button_pressed = false
	_show_focus()


func set_locale(locale: String) -> void:
	if locale not in ["ru", "en", "be"]:
		return
	_locale = locale
	if not _selected_key.is_empty():
		_inspect(_selected_key)


func focus_scene(scene_id: String) -> void:
	_focus_id = "scene:" + scene_id
	if not _show_all.button_pressed:
		_show_focus()


func _on_full_toggle(_value: bool) -> void:
	_show_focus()


func _show_focus() -> void:
	if _canvas == null:
		return
	var model: Dictionary = _model if _show_all.button_pressed or _focus_id.is_empty() else Model.neighborhood(_model, _focus_id, 2)
	_visible = model.get("nodes", {})
	_canvas.clear_connections()
	for child in _canvas.get_children():
		if child is GraphNode:
			_canvas.remove_child(child)
			child.queue_free()
	_graph_names.clear()
	_open_scene.disabled = true
	var keys: Array = _visible.keys()
	keys.sort_custom(func(a, b):
		var x: Dictionary = _visible[a]
		var y: Dictionary = _visible[b]
		if x["index"] != y["index"]:
			return int(x["index"]) < int(y["index"])
		return str(a) < str(b))
	var outgoing: Dictionary = {}
	for edge in model.get("edges", []):
		var source: String = str(edge["from"])
		if not outgoing.has(source):
			outgoing[source] = []
		outgoing[source].append(edge)
	var min_x: float = INF
	var min_y: float = INF
	var positions: Dictionary = {}
	for key in keys:
		var info: Dictionary = _visible[key]
		var idx: int = maxi(int(info["index"]), 0)
		var cx: float = float(idx % 6) * 390.0
		var cy: float = float(idx / 6) * 410.0
		match str(info["kind"]):
			"choice": cy += 160.0; cx += 50.0
			"variant": cy += 210.0; cx += 65.0
			"match3": cy += 250.0; cx += 40.0
			"ending": cy += 260.0; cx += 70.0
		# Separate virtual nodes that share a source index.
		if info["kind"] == "variant":
			cx += float(["A", "B", "C"].find(str(info["metadata"].get("variant", "A")))) * 90.0
		min_x = minf(min_x, cx)
		min_y = minf(min_y, cy)
		positions[key] = Vector2(cx, cy)
	for i in range(keys.size()):
		var key: String = str(keys[i])
		var info: Dictionary = _visible[key]
		var node := GraphNode.new()
		node.name = "node_%03d" % i
		node.title = _title(info)
		node.custom_minimum_size.x = 260.0
		node.position_offset = positions[key] - Vector2(min_x, min_y) + Vector2(30, 30)
		var links: Array = outgoing.get(key, [])
		var row := Label.new()
		row.text = str(info["label"]).left(42)
		row.custom_minimum_size = Vector2(240, 28)
		node.add_child(row)
		var accent: Color = _color(str(info["kind"]))
		node.set_slot(0, true, 0, accent, not links.is_empty(), 0, accent)
		for n in range(1, links.size()):
			var out := Label.new()
			out.text = str(links[n]["label"]).left(26)
			out.custom_minimum_size = Vector2(240, 26)
			node.add_child(out)
			node.set_slot(n, false, 0, accent, true, 0, accent)
		node.node_selected.connect(_on_node_selected.bind(key))
		_canvas.add_child(node)
		_graph_names[key] = node.name
	for edge in model.get("edges", []):
		var from: String = str(edge["from"])
		var to: String = str(edge["to"])
		if not _graph_names.has(from) or not _graph_names.has(to):
			continue
		var port: int = 0
		var links: Array = outgoing.get(from, [])
		for j in range(links.size()):
			if links[j] == edge:
				port = j
				break
		_canvas.connect_node(StringName(_graph_names[from]), port, StringName(_graph_names[to]), 0)
	var stats: Dictionary = _model.get("stats", {})
	_summary.text = "Сцены %d · выборы %d · варианты %d · Match-3 %d · финалы %d · предупреждения %d · линии %d%s" % [
		int(stats.get("sceneNodes", 0)), int(stats.get("choiceGates", 0)),
		int(stats.get("variants", 0)), int(stats.get("match3", 0)),
		int(stats.get("endings", 0)), _model.get("warnings", []).size(),
		model.get("edges", []).size(), " · режим: все" if _show_all.button_pressed else " · режим: вокруг сцены"]
	_inspector.text = "Выберите узел, чтобы увидеть исходные ID, варианты, требования и переходы."
	_selected_key = ""


func _title(info: Dictionary) -> String:
	var prefix: String = ""
	match str(info["kind"]):
		"scene": prefix = "СЦЕНА"
		"choice": prefix = "ВЫБОР"
		"variant": prefix = "ВЕТКА"
		"match3": prefix = "MATCH-3"
		"ending": prefix = "ФИНАЛ"
	return "%s · %s" % [prefix, str(info["label"]).left(30)]


func _color(kind: String) -> Color:
	match kind:
		"choice": return Color(0.95, 0.74, 0.3)
		"match3": return Color(0.3, 0.8, 0.96)
		"variant": return Color(0.7, 0.6, 0.95)
		"ending": return Color(0.9, 0.45, 0.6)
	return Color(0.42, 0.82, 0.65)


func _on_node_selected(key: String) -> void:
	_selected_key = key
	_inspect(key)


func _inspect(key: String) -> void:
	if not _visible.has(key):
		return
	var item: Dictionary = _visible[key]
	var meta: Dictionary = item["metadata"]
	var detail: String = "%s\n%s\n" % [_title(item), key]
	match str(item["kind"]):
		"scene":
			var title: Dictionary = meta.get("titles", {})
			detail += "Заголовок: %s\nИсходный файл: %s\nНомер: %d\n" % [str(title.get(_locale, item["label"])), str(meta.get("file", "")), int(item["index"])]
			detail += "Базовых реплик: %d\nВетви: %s\n" % [int(meta.get("lines", 0)), ", ".join(meta.get("variants", []))]
		"choice":
			var prompt: Dictionary = meta.get("prompt", {})
			detail += "Контрольная реплика: %s\nВопрос: %s\n" % [str(meta.get("checkpointLineId", "")), str(prompt.get(_locale, ""))]
			var choices: Dictionary = meta.get("choices", {})
			for variant in choices:
				var localized: Dictionary = choices[variant].get(_locale, {})
				detail += "%s · %s | %s\n" % [str(variant), str(localized.get("title", "")), str(localized.get("effect", ""))]
			detail += "Эффекты — описание, не расчёт условий во время игры.\n"
		"variant":
			var choice: Dictionary = meta.get("choice", {}).get(_locale, {})
			detail += "Ветка %s · реплик: %d\n%s\n" % [str(meta.get("variant", "")), int(meta.get("lineCount", 0)), str(choice.get("title", ""))]
		"match3":
			detail += "Уровень: %s · переход по победе — отдельная связь\n" % [str(meta.get("levelId", ""))]
		"ending":
			detail += "Ending ID: %s\nТребования: %s\n" % [str(meta.get("endingId", "")), JSON.stringify(meta.get("successRequirement", {}))]
	var graph_edges: Array = _model.get("edges", [])
	for edge in graph_edges:
		if edge["from"] == key:
			detail += "→ %s [%s]\n" % [str(edge["to"]), str(edge["label"])]
	_open_scene.disabled = str(item["kind"]) != "scene"
	if str(item["kind"]) == "scene":
		_open_scene.tooltip_text = "Открыть сцену %s в редакторе" % str(item["label"])
	_inspector.text = detail


func _on_open_scene() -> void:
	if not _visible.has(_selected_key):
		return
	var info: Dictionary = _visible[_selected_key]
	if info["kind"] == "scene":
		open_scene_requested.emit(int(info["index"]))


func _reject_connection(_from: StringName, _from_port: int, _to: StringName, _to_port: int) -> void:
	_inspector.text = "Связи пока доступны только для просмотра. Нельзя изменить сюжет или сейвы, перетянув провод."


func _reject_disconnection(_from: StringName, _from_port: int, _to: StringName, _to_port: int) -> void:
	_inspector.text = "Отключение переходов заблокировано. Используйте утверждённый конвертер на следующем этапе."
