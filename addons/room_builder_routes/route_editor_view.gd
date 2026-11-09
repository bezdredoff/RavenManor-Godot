@tool
extends Control
## Godot-native Room Builder Navigation / Routes authoring workspace.
## Writes ONLY explicit QA drafts, never the source pilot or production state.
const Routes = preload("res://addons/room_builder_routes/route_document.gd")
const RouteCanvas = preload("res://addons/room_builder_routes/route_canvas.gd")
const PreviewSource = preload("res://addons/room_builder_routes/route_preview_source.gd")
const PreviewLaunch = preload("res://addons/room_builder_routes/route_preview_launch.gd")
const IMAGE = preload("res://a_detailed_top_down_isometric_game_map_illustratio.png")
const PILOT = "res://scenes/raven/tests/first_floor_hall_movement_pilot.tscn"
const INTEGRATED = "res://scenes/raven/tests/first_floor_integrated_qa.tscn"
const MODES := ["Waypoints", "Add", "Connect", "Routes", "Cells", "Obstacles", "Pan"]
const MODE_LABELS := ["1 Select / drag", "2 Add waypoint", "3 Connect points",
	"4 Select route", "5 Draw route cells", "6 Block cells", "7 Pan map"]
const ROOM_LABELS := ["Hall", "Corridor", "Bedroom", "Library / Archive", "Kitchen"]

var document: Dictionary = {}
var history: Array[Dictionary] = []
var future: Array[Dictionary] = []
var last_saved := ""
var current_mode := "Waypoints"
var selected_waypoint := ""
var selected_route := ""
var selected_cell := ""
var last_pixel := Vector2(836, 746)
var pixel_selected := false
var last_persisted_kind := PreviewSource.PROJECT
var click_route_from := true
var connect_from := ""
var active_room := "RM-ROOM-HALL"
var _suppress := false

var canvas: Control
var status: Label
var dirty_label: Label
var waypoint_list: ItemList
var waypoint_ids: Array[String] = []
var route_list: ItemList
var route_ids: Array[String] = []
var name_edit: LineEdit
var kind_picker: OptionButton
var snap_checkbox: CheckBox
var mode_picker: OptionButton
var room_picker: OptionButton
var waypoint_room_picker: OptionButton
var active_tool_label: Label
var selection_label: Label
var tool_help: Label
var route_cells: LineEdit
var route_bidirectional: CheckBox
var route_hint: Label
var route_from: OptionButton
var route_to: OptionButton
var grid_width: SpinBox
var grid_height: SpinBox
var grid_offset_x: SpinBox
var grid_offset_y: SpinBox
var grid_visible: CheckBox
var grid_coordinates: CheckBox
var cell_inspection: Label
var undo_button: Button
var redo_button: Button
var _preview_route: PackedVector2Array


func _init() -> void:
	name = "Navigation / Routes"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	size_flags_horizontal = SIZE_EXPAND_FILL
	size_flags_vertical = SIZE_EXPAND_FILL


func _ready() -> void:
	_make_ui()
	canvas.set_image(IMAGE)
	_set_mode("Waypoints")
	var imported := Routes.import_hall()
	if not imported.ok:
		_message("ERROR: " + str(imported.error))
		return
	_set_document(imported.document, false)
	if FileAccess.file_exists(Routes.DEFAULT_SAVE):
		var recovered := Routes.load_draft(Routes.DEFAULT_SAVE)
		if recovered.ok:
			_set_document(recovered.document, false)
			_message("Recovered saved QA draft from user://. Source Hall pilot unchanged.")
		else:
			_message("Saved draft invalid; loaded original Hall import: " + str(recovered.error))
	else:
		_message("Imported seven Hall QA points and seven provisional edges. Save draft to keep edits.")
	call_deferred("_fit")


func _fit() -> void:
	canvas.fit_image()


func _make_ui() -> void:
	var outer := VBoxContainer.new()
	outer.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	outer.size_flags_vertical = SIZE_EXPAND_FILL
	outer.size_flags_horizontal = SIZE_EXPAND_FILL
	add_child(outer)
	var toolbar := HFlowContainer.new()
	outer.add_child(toolbar)
	var title := Label.new()
	title.text = "Navigation / Routes · DRAFT_ONLY"
	title.add_theme_font_size_override("font_size", 17)
	toolbar.add_child(title)
	toolbar.add_child(_paragraph("Active tool:"))
	mode_picker = OptionButton.new()
	mode_picker.name = "ToolPicker"
	for i in range(MODES.size()):
		mode_picker.add_item(MODE_LABELS[i])
		mode_picker.set_item_metadata(i, MODES[i])
	mode_picker.item_selected.connect(func(i: int): _set_mode(str(mode_picker.get_item_metadata(i))))
	toolbar.add_child(mode_picker)
	toolbar.add_child(_paragraph("Editing room:"))
	room_picker = OptionButton.new()
	room_picker.name = "RoomPicker"
	for i in range(Routes.ROOM_IDS.size()):
		room_picker.add_item(ROOM_LABELS[i])
		room_picker.set_item_metadata(i, Routes.ROOM_IDS[i])
	room_picker.item_selected.connect(_on_room_selected)
	toolbar.add_child(room_picker)
	active_tool_label = Label.new()
	active_tool_label.name = "ActiveTool"
	toolbar.add_child(active_tool_label)
	var actions := HFlowContainer.new()
	outer.add_child(actions)
	actions.add_child(_button("Load project draft", _load_project))
	actions.add_child(_button("Load saved user", _load_user))
	actions.add_child(_button("Save user draft", _save_user))
	actions.add_child(_button("Export project draft", _export_project))
	actions.add_child(_button("Import original Hall", _import_hall))
	undo_button = _button("Undo", _undo)
	undo_button.name = "Undo"
	actions.add_child(undo_button)
	redo_button = _button("Redo", _redo)
	redo_button.name = "Redo"
	actions.add_child(redo_button)
	actions.add_child(_button("Fit artwork", _fit))
	actions.add_child(_button("Play saved (Hall only)", _open_pilot.bind(PreviewSource.USER)))
	actions.add_child(_button("Play exported (Hall only)", _open_pilot.bind(PreviewSource.PROJECT)))
	actions.add_child(_button("Play original Hall", _open_pilot.bind(PreviewSource.BASELINE)))
	actions.add_child(_button("Play integrated first floor", _open_integrated))
	dirty_label = Label.new()
	dirty_label.text = "Saved"
	actions.add_child(dirty_label)
	status = Label.new()
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.custom_minimum_size.y = 32
	outer.add_child(status)
	var split := HSplitContainer.new()
	split.size_flags_vertical = SIZE_EXPAND_FILL
	outer.add_child(split)
	canvas = RouteCanvas.new()
	canvas.custom_minimum_size = Vector2(650, 480)
	canvas.size_flags_horizontal = SIZE_EXPAND_FILL
	canvas.size_flags_vertical = SIZE_EXPAND_FILL
	split.add_child(canvas)
	canvas.waypoint_chosen.connect(_on_canvas_waypoint)
	canvas.waypoint_dropped.connect(_on_drop_waypoint)
	canvas.route_chosen.connect(_on_canvas_route)
	canvas.image_pixel_chosen.connect(_on_image_clicked)
	canvas.cell_chosen.connect(_on_cell_clicked)
	canvas.obstacle_paint.connect(_on_paint_cell)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.x = 355
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	split.add_child(scroll)
	var inspector := VBoxContainer.new()
	inspector.custom_minimum_size.x = 340
	inspector.add_theme_constant_override("separation", 7)
	scroll.add_child(inspector)
	selection_label = _paragraph("Selected room: Hall · Selected waypoint: —")
	selection_label.name = "SelectionInfo"
	inspector.add_child(selection_label)
	tool_help = _paragraph("Select / drag: click a point to inspect it, drag to move. Choose a room above.")
	tool_help.name = "ToolHelp"
	inspector.add_child(tool_help)
	inspector.add_child(_paragraph("QUICK START: 1) Load project draft. 2) Choose room. 3) Add / drag points. 4) Connect two points. 5) Draw route cells. 6) Save. 7) Play integrated first floor."))
	inspector.add_child(HSeparator.new())
	var grid_section := VBoxContainer.new()
	grid_section.add_child(_heading("GRID · source-image pixels"))
	var row := HBoxContainer.new()
	grid_section.add_child(row)
	grid_width = _spin(row, "W", 4, 512, 32)
	grid_height = _spin(row, "H", 4, 512, 32)
	var origin_row := HBoxContainer.new()
	grid_section.add_child(origin_row)
	grid_offset_x = _spin(origin_row, "Origin X", -4096, 4096, 0)
	grid_offset_y = _spin(origin_row, "Origin Y", -4096, 4096, 0)
	grid_visible = CheckBox.new()
	grid_visible.text = "Grid visible"
	grid_visible.button_pressed = true
	grid_section.add_child(grid_visible)
	grid_coordinates = CheckBox.new()
	grid_coordinates.text = "Show every cell coordinate (zoomed)"
	grid_section.add_child(grid_coordinates)
	grid_section.add_child(_button("Apply grid settings", _apply_grid))
	cell_inspection = _paragraph("Selected cell: —")
	grid_section.add_child(cell_inspection)
	inspector.add_child(_heading("WAYPOINTS · stable IDs"))
	waypoint_list = ItemList.new()
	waypoint_list.custom_minimum_size.y = 155
	waypoint_list.item_selected.connect(_on_waypoint_list_select)
	inspector.add_child(waypoint_list)
	name_edit = LineEdit.new()
	name_edit.placeholder_text = "Display label (stable ID remains unchanged)"
	inspector.add_child(name_edit)
	kind_picker = OptionButton.new()
	for kind in Routes.TYPES:
		kind_picker.add_item(kind)
	inspector.add_child(kind_picker)
	inspector.add_child(_paragraph("Waypoint room (explicit ownership):"))
	waypoint_room_picker = OptionButton.new()
	waypoint_room_picker.name = "WaypointRoom"
	for i in range(Routes.ROOM_IDS.size()):
		waypoint_room_picker.add_item(ROOM_LABELS[i])
		waypoint_room_picker.set_item_metadata(i, Routes.ROOM_IDS[i])
	inspector.add_child(waypoint_room_picker)
	snap_checkbox = CheckBox.new()
	snap_checkbox.text = "Snap dragged/created points to cell centres"
	snap_checkbox.button_pressed = true
	inspector.add_child(snap_checkbox)
	var wp_row := HFlowContainer.new()
	inspector.add_child(wp_row)
	wp_row.add_child(_button("+ Add waypoint here", _add_waypoint))
	wp_row.add_child(_button("Apply label/type/room", _apply_waypoint_info))
	wp_row.add_child(_button("Delete waypoint", _delete_waypoint))
	inspector.add_child(_paragraph("Tool 1: click / drag a point. Tool 2: click empty walkable art to create a point in the editing room. Changing a connected point's room is rejected until its routes are removed."))
	inspector.add_child(HSeparator.new())
	inspector.add_child(_heading("ROUTES · ordered orthogonal cells"))
	var endpoint_row := HBoxContainer.new()
	inspector.add_child(endpoint_row)
	route_from = OptionButton.new()
	route_from.custom_minimum_size.x = 155
	endpoint_row.add_child(route_from)
	route_to = OptionButton.new()
	route_to.custom_minimum_size.x = 155
	endpoint_row.add_child(route_to)
	inspector.add_child(_button("+ Connect selected FROM / TO", _add_route))
	route_list = ItemList.new()
	route_list.custom_minimum_size.y = 160
	route_list.item_selected.connect(_on_route_list_select)
	inspector.add_child(route_list)
	route_hint = _paragraph("Select a route to author its exact cell sequence.")
	inspector.add_child(route_hint)
	route_cells = LineEdit.new()
	route_cells.placeholder_text = "D10 → E10 → F10 → F9 → G9 → H9 → H8 → H7"
	route_cells.text_changed.connect(_on_route_text_changed)
	inspector.add_child(route_cells)
	var route_row := HFlowContainer.new()
	inspector.add_child(route_row)
	route_row.add_child(_button("Start cell path at FROM", _start_cell_path))
	route_row.add_child(_button("Apply cells", _apply_route_cells))
	route_row.add_child(_button("Remove last cell", _remove_last_cell))
	route_row.add_child(_button("Delete route", _delete_route))
	route_bidirectional = CheckBox.new()
	route_bidirectional.text = "Bidirectional (unchecked = one way from → to)"
	route_bidirectional.toggled.connect(_on_direction_changed)
	inspector.add_child(route_bidirectional)
	inspector.add_child(_paragraph("Tool 3: choose two waypoints in the SAME room to connect (temporary provisional edge). Tool 4: click a route line to select it. Tool 5: click adjacent grid cells to redraw the selected route, starting at FROM and ending at TO. Press Apply cells. Existing exact text editor remains available."))
	inspector.add_child(HSeparator.new())
	inspector.add_child(_heading("OBSTACLES + PREVIEW"))
	inspector.add_child(_paragraph("Obstacles mode: click or paint cells to block. Re-click to unblock. No-go polygons remain read-only restrictions."))
	inspector.add_child(_button("Unblock selected cell", _clear_selected_cell))
	inspector.add_child(_button("Test Route: selected from → to", _test_route))
	inspector.add_child(_button("Clear route preview", _clear_preview))
	inspector.add_child(_paragraph("Test Route shows the in-editor path. Play integrated first floor reads the SAVED user / project draft, never unsaved changes. Real doors are still unresolved: transitions are TEST_ONLY."))
	inspector.add_child(HSeparator.new())
	inspector.add_child(_heading("ADVANCED · grid / image pixels"))
	inspector.add_child(grid_section)


func _button(caption: String, callback: Callable) -> Button:
	var b := Button.new()
	b.text = caption
	b.pressed.connect(callback)
	return b


func _heading(caption: String) -> Label:
	var label := Label.new()
	label.text = caption
	label.add_theme_font_size_override("font_size", 15)
	return label


func _paragraph(caption: String) -> Label:
	var label := Label.new()
	label.text = caption
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.y = 38
	return label


func _spin(parent: BoxContainer, caption: String, low: float, high: float, initial: float) -> SpinBox:
	var label := Label.new()
	label.text = caption
	parent.add_child(label)
	var spin := SpinBox.new()
	spin.min_value = low
	spin.max_value = high
	spin.step = 1
	spin.value = initial
	spin.size_flags_horizontal = SIZE_EXPAND_FILL
	parent.add_child(spin)
	return spin


func _message(text: String) -> void:
	status.text = text
	if text.begins_with("ERROR:"):
		push_warning(text)


func _set_mode(mode: String) -> void:
	if not MODES.has(mode):
		_message("ERROR: Unknown editor tool " + mode)
		return
	current_mode = mode
	canvas.set_mode(mode)
	var index := MODES.find(mode)
	if is_instance_valid(mode_picker):
		mode_picker.select(index)
	active_tool_label.text = MODE_LABELS[index]
	match mode:
		"Waypoints": tool_help.text = "SELECT / DRAG: click a waypoint, then drag to move it. Only the selected room's points are editable."
		"Add": tool_help.text = "ADD: choose editing room above, then click EMPTY walkable artwork. New point receives that roomId."
		"Connect": tool_help.text = "CONNECT: click the start waypoint, then the destination in the same room. A provisional edge is created."
		"Routes": tool_help.text = "SELECT ROUTE: click a drawn line or a route in the list. Click waypoints to set FROM and TO."
		"Cells": tool_help.text = "DRAW CELLS: select a route, press Start cell path, then click successive adjacent cells; finish at TO and Apply."
		"Obstacles": tool_help.text = "BLOCK CELLS: click/paint cells to toggle blockers. Existing routes cannot pass through blocked cells."
		"Pan": tool_help.text = "PAN: left/right/middle drag. Mouse wheel always zooms; Fit artwork resets view."
	_message(active_tool_label.text + " · " + ROOM_LABELS[Routes.ROOM_IDS.find(active_room)])


func _on_room_selected(index: int) -> void:
	if index < 0 or index >= Routes.ROOM_IDS.size():
		return
	_change_room(str(room_picker.get_item_metadata(index)))


func _change_room(room_id: String) -> void:
	if not Routes.ROOM_IDS.has(room_id):
		_message("ERROR: Unsupported editing room")
		return
	active_room = room_id
	room_picker.select(Routes.ROOM_IDS.find(room_id))
	canvas.set_active_room(room_id)
	selected_waypoint = ""
	selected_route = ""
	connect_from = ""
	click_route_from = true
	_clear_preview()
	_refresh()
	_message("Editing " + ROOM_LABELS[Routes.ROOM_IDS.find(room_id)] + " · new waypoints will explicitly use " + room_id)


func _set_document(value: Dictionary, push_history: bool = true) -> void:
	if push_history and not document.is_empty() and JSON.stringify(document) != JSON.stringify(value):
		history.append(document.duplicate(true))
		if history.size() > 64:
			history.pop_front()
		future.clear()
	document = value.duplicate(true)
	canvas.set_document(document)
	_clear_preview()
	_refresh()
	if not push_history:
		history.clear()
		future.clear()
		last_saved = JSON.stringify(document)
	_refresh_dirty()


func _refresh_dirty() -> void:
	if is_instance_valid(dirty_label):
		dirty_label.text = "● UNSAVED changes" if JSON.stringify(document) != last_saved else "✓ Saved/unchanged"
	undo_button.disabled = history.is_empty()
	redo_button.disabled = future.is_empty()


func _refresh() -> void:
	if document.is_empty():
		return
	_suppress = true
	var remembered_from := route_from.get_item_text(route_from.selected) if route_from.selected >= 0 else ""
	var remembered_to := route_to.get_item_text(route_to.selected) if route_to.selected >= 0 else ""
	var g: Dictionary = document["grid"]
	grid_width.set_value_no_signal(float(g["cellWidth"]))
	grid_height.set_value_no_signal(float(g["cellHeight"]))
	grid_offset_x.set_value_no_signal(float(g["origin"][0]))
	grid_offset_y.set_value_no_signal(float(g["origin"][1]))
	grid_visible.set_pressed_no_signal(bool(g["visible"]))
	grid_coordinates.set_pressed_no_signal(bool(g["showCoordinates"]))
	waypoint_list.clear()
	waypoint_ids.clear()
	route_from.clear()
	route_to.clear()
	var selected_wp: Dictionary = {}
	var selected_index := -1
	for wp in document["waypoints"]:
		var id := str(wp["id"])
		var room := Routes.waypoint_room(wp)
		if room != active_room and not room.is_empty():
			continue
		if id == selected_waypoint:
			selected_index = waypoint_ids.size()
			selected_wp = wp
		waypoint_ids.append(id)
		var owner_label := "UNASSIGNED" if room.is_empty() else ROOM_LABELS[Routes.ROOM_IDS.find(room)]
		waypoint_list.add_item("%s · %s [%s]" % [id, str(wp["label"]), owner_label])
		if room == active_room:
			route_from.add_item(id)
			route_to.add_item(id)
	for idx in range(route_from.item_count):
		if route_from.get_item_text(idx) == remembered_from:
			route_from.select(idx)
		if route_to.get_item_text(idx) == remembered_to:
			route_to.select(idx)
	if selected_index >= 0:
		waypoint_list.select(selected_index)
		name_edit.text = str(selected_wp["label"])
		kind_picker.select(Routes.TYPES.find(str(selected_wp["type"])))
		var owner: String = Routes.waypoint_room(selected_wp)
		if Routes.ROOM_IDS.has(owner):
			waypoint_room_picker.select(Routes.ROOM_IDS.find(owner))
		else:
			waypoint_room_picker.select(Routes.ROOM_IDS.find(active_room))
		var feet: Vector2 = Routes._vector(selected_wp["pointPx"])
		cell_inspection.text = "%s · feet (%.2f, %.2f) px · cell %s" % [
			selected_waypoint, feet.x, feet.y, Routes.pixel_to_cell(feet, document)]
	else:
		selected_waypoint = ""
		name_edit.clear()
		waypoint_room_picker.select(Routes.ROOM_IDS.find(active_room))
	route_list.clear()
	route_ids.clear()
	var selected_route_data: Dictionary = {}
	var route_index := -1
	for route in document["routes"]:
		if Routes.room_for_id(document, str(route["from"])) != active_room:
			continue
		var id := str(route["id"])
		if id == selected_route:
			route_index = route_ids.size()
			selected_route_data = route
		route_ids.append(id)
		var info := "PROVISIONAL" if route["provisional"] else "%d cells" % route["cells"].size()
		route_list.add_item("%s · %s → %s · %s" % [id, route["from"], route["to"], info])
	if route_index >= 0:
		route_list.select(route_index)
		_show_route_details(selected_route_data)
	else:
		selected_route = ""
		route_cells.clear()
		route_hint.text = "Select a highlighted route on the map or in this list."
		route_bidirectional.set_pressed_no_signal(true)
	var room_name: String = ROOM_LABELS[Routes.ROOM_IDS.find(active_room)]
	selection_label.text = "ROOM: " + room_name + " · WAYPOINT: " + (selected_waypoint if not selected_waypoint.is_empty() else "—") + " · ROUTE: " + (selected_route if not selected_route.is_empty() else "—")
	_suppress = false
	_refresh_dirty()
	canvas.selected_waypoint = selected_waypoint
	canvas.selected_route = selected_route
	canvas.selected_cell = selected_cell
	canvas.set_active_room(active_room)
	canvas.queue_redraw()


func _show_route_details(route: Dictionary) -> void:
	route_bidirectional.set_pressed_no_signal(bool(route["bidirectional"]))
	var cells: Array = route["cells"]
	if cells.is_empty():
		var by_id := Routes._waypoint_lookup(document)
		var wp: Dictionary = by_id.get(str(route["from"]), {})
		route_cells.text = Routes.pixel_to_cell(Routes._vector(wp.get("pointPx", [0, 0])), document) if not wp.is_empty() else ""
	else:
		route_cells.text = " → ".join(PackedStringArray(cells))
	route_hint.text = "%s · %s → %s · %s" % [
		route["id"], route["from"], route["to"],
		"PROVISIONAL straight edge (no cells authored)" if route["provisional"] else "Authored cell route"
	]
	for idx in range(route_from.item_count):
		if route_from.get_item_text(idx) == route["from"]:
			route_from.select(idx)
		if route_to.get_item_text(idx) == route["to"]:
			route_to.select(idx)


func _commit(result: Dictionary, success: String) -> bool:
	if not result.get("ok", false):
		_message("ERROR: " + str(result.get("error", "Invalid change")))
		return false
	_set_document(result.document)
	_message(success)
	return true


func _snap_point(pixel: Vector2) -> Vector2:
	if not snap_checkbox.button_pressed:
		return pixel
	var cell := Routes.pixel_to_cell(pixel, document)
	var midpoint := Routes.cell_to_pixel(cell, document)
	return midpoint if midpoint.is_finite() else pixel


func _on_image_clicked(point: Vector2) -> void:
	last_pixel = point
	pixel_selected = true
	if current_mode == "Add":
		_add_waypoint()


func _on_cell_clicked(cell: String) -> void:
	selected_cell = cell
	if cell.is_empty():
		return
	var blocked: bool = document.get("blockedCells", []).has(cell)
	var point := Routes.cell_to_pixel(cell, document)
	cell_inspection.text = "%s · centre %s · blocked: %s" % [cell, str(point), str(blocked)]
	if current_mode == "Cells" and not selected_route.is_empty():
		_append_route_cell(cell)
	canvas.selected_cell = cell
	canvas.queue_redraw()


func _on_canvas_waypoint(id: String) -> void:
	if id.is_empty():
		return
	selected_waypoint = id
	_refresh()
	if current_mode == "Connect":
		if connect_from.is_empty():
			connect_from = id
			_message("CONNECT: starting at " + id + ". Click a second waypoint in the same room.")
			return
		var start := connect_from
		connect_from = ""
		if start == id:
			_message("ERROR: Choose a different destination waypoint")
			return
		_connect_points(start, id)
	elif current_mode == "Routes":
		for i in range(route_from.item_count):
			if route_from.get_item_text(i) == id:
				if click_route_from:
					route_from.select(i)
				else:
					route_to.select(i)
				click_route_from = not click_route_from
				_message("Endpoint " + id + " chosen as " + ("FROM" if not click_route_from else "TO"))
				break
	else:
		_message("Selected waypoint " + id + " · " + active_room)


func _on_canvas_route(id: String) -> void:
	if id.is_empty() or not route_ids.has(id):
		return
	selected_route = id
	_refresh()
	_clear_preview()
	_message("Selected " + id + ". Choose Draw route cells to edit exact grid turns.")


func _connect_points(from_id: String, to_id: String) -> void:
	var result := Routes.add_route(document, from_id, to_id)
	if _commit(result, "Connected " + from_id + " → " + to_id + " (PROVISIONAL). Select Draw route cells and Apply."):
		selected_route = str(result.id)
		_refresh()


func _on_drop_waypoint(id: String, point: Vector2) -> void:
	var result := Routes.move_waypoint(document, id, _snap_point(point))
	if _commit(result, "Moved " + id):
		selected_waypoint = id
		_refresh()


func _on_waypoint_list_select(index: int) -> void:
	if index < 0 or index >= waypoint_ids.size():
		return
	selected_waypoint = waypoint_ids[index]
	_refresh()


func _add_waypoint() -> void:
	if not pixel_selected:
		_message("ERROR: Click an empty walkable position on the map before adding a waypoint")
		return
	var result := Routes.add_waypoint(document, _snap_point(last_pixel), "New waypoint", active_room)
	if _commit(result, "Added waypoint at " + str(last_pixel.round())):
		selected_waypoint = str(result.id)
		_refresh()


func _apply_waypoint_info() -> void:
	if selected_waypoint.is_empty():
		_message("ERROR: Select a waypoint first")
		return
	var room_id: String = str(waypoint_room_picker.get_item_metadata(waypoint_room_picker.selected))
	var waypoint_id := selected_waypoint
	if _commit(Routes.set_waypoint_info(document, waypoint_id, name_edit.text,
			kind_picker.get_item_text(kind_picker.selected), room_id), "Waypoint label/type/room updated; stable ID unchanged"):
		if room_id != active_room:
			_change_room(room_id)
			selected_waypoint = waypoint_id
			_refresh()


func _delete_waypoint() -> void:
	if selected_waypoint.is_empty():
		_message("ERROR: Select waypoint to delete")
		return
	var result := Routes.delete_waypoint(document, selected_waypoint)
	if _commit(result, "Waypoint removed"):
		selected_waypoint = ""
		_refresh()


func _on_route_list_select(index: int) -> void:
	if index < 0 or index >= route_ids.size():
		return
	selected_route = route_ids[index]
	_refresh()
	_clear_preview()


func _add_route() -> void:
	if route_from.selected < 0 or route_to.selected < 0:
		_message("ERROR: Select from and to waypoints")
		return
	_connect_points(route_from.get_item_text(route_from.selected), route_to.get_item_text(route_to.selected))


func _apply_route_cells() -> void:
	if selected_route.is_empty():
		_message("ERROR: Select a route first")
		return
	_commit(Routes.set_route_cells(document, selected_route, route_cells.text), "Authored cells saved (DRAFT_ONLY)")


func _start_cell_path() -> void:
	if selected_route.is_empty():
		_message("ERROR: Select a route first")
		return
	var route: Dictionary = {}
	for item in document["routes"]:
		if str(item["id"]) == selected_route:
			route = item
			break
	if route.is_empty():
		return
	var source: Dictionary = Routes._waypoint_lookup(document).get(str(route["from"]), {})
	if source.is_empty():
		return
	route_cells.text = Routes.pixel_to_cell(Routes._vector(source["pointPx"]), document)
	_on_route_text_changed(route_cells.text)
	_message("Start at " + route_cells.text + ". Tool 5: click adjacent cells until you reach TO, then Apply cells.")


func _append_route_cell(cell: String) -> void:
	var text := route_cells.text.strip_edges()
	if text.is_empty():
		_start_cell_path()
		text = route_cells.text.strip_edges()
	var last := text.replace("->", "→").split("→")[-1].strip_edges()
	if last == cell:
		return
	var start := Routes.parse_cell(last)
	var next := Routes.parse_cell(cell)
	if not start.ok or not next.ok:
		_message("ERROR: Invalid route cell; choose an A1-style grid coordinate")
		return
	if absi(int(start.col) - int(next.col)) + absi(int(start.row) - int(next.row)) != 1:
		_message("ERROR: Route cell " + cell + " is not adjacent to " + last + ". Move one horizontal/vertical cell.")
		return
	route_cells.text += " → " + cell
	_on_route_text_changed(route_cells.text)


func _remove_last_cell() -> void:
	var split := route_cells.text.replace("->", "→").split("→", false)
	if split.size() > 1:
		split.remove_at(split.size() - 1)
		route_cells.text = " → ".join(PackedStringArray(split))
		_on_route_text_changed(route_cells.text)


func _on_route_text_changed(value: String) -> void:
	if _suppress or document.is_empty():
		return
	var pieces := value.replace("->", "→").split("→", false)
	var points := PackedVector2Array()
	var previous: Dictionary = {}
	for cell in pieces:
		var parsed := Routes.parse_cell(cell)
		if not parsed.ok:
			_message("ERROR: " + str(parsed.error))
			break
		var point := Routes.cell_to_pixel(str(parsed.cell), document)
		if not point.is_finite():
			_message("ERROR: Cell " + str(parsed.cell) + " is outside artwork")
			break
		if not previous.is_empty():
			if absi(int(previous.col) - int(parsed.col)) + absi(int(previous.row) - int(parsed.row)) != 1:
				_message("ERROR: Adjacent orthogonal steps only: " + str(previous.cell) + " → " + str(parsed.cell))
				break
		points.append(point)
		previous = parsed
	_preview_route = points
	canvas.show_preview(points)


func _on_direction_changed(checked: bool) -> void:
	if _suppress or selected_route.is_empty():
		return
	_commit(Routes.set_route_direction(document, selected_route, checked), "Updated route direction")


func _delete_route() -> void:
	if selected_route.is_empty():
		_message("ERROR: Select route to delete")
		return
	if _commit(Routes.delete_route(document, selected_route), "Route deleted"):
		selected_route = ""
		_refresh()


func _on_paint_cell(cell: String, blocked: bool) -> void:
	_commit(Routes.set_blocked(document, cell, blocked), "Cell " + cell + (" blocked" if blocked else " unblocked"))


func _clear_selected_cell() -> void:
	if selected_cell.is_empty():
		_message("ERROR: Select a cell first")
		return
	_commit(Routes.set_blocked(document, selected_cell, false), "Cleared blocked state of " + selected_cell)


func _apply_grid() -> void:
	_commit(Routes.change_grid(document, int(grid_width.value), int(grid_height.value), Vector2(grid_offset_x.value, grid_offset_y.value), grid_visible.button_pressed, grid_coordinates.button_pressed), "Grid settings applied in source-image pixels")


func _test_route() -> void:
	if route_from.selected < 0 or route_to.selected < 0:
		_message("ERROR: Select route start and destination")
		return
	var a := route_from.get_item_text(route_from.selected)
	var b := route_to.get_item_text(route_to.selected)
	var result := Routes.route_preview(document, a, b)
	if not result.ok:
		_message("ERROR: " + str(result.error))
		return
	_preview_route = result.points
	canvas.show_preview(result.points)
	_message("Compiled QA route %s → %s · %.1f image pixels · %d anchors; original Hall Pilot is separate" % [a, b, float(result.lengthPx), result.anchorIds.size()])


func _clear_preview() -> void:
	_preview_route = PackedVector2Array()
	if is_instance_valid(canvas):
		canvas.show_preview(_preview_route)


func _undo() -> void:
	if history.is_empty():
		return
	future.append(document.duplicate(true))
	document = history.pop_back()
	canvas.set_document(document)
	_clear_preview()
	_refresh()
	_message("Undo")


func _redo() -> void:
	if future.is_empty():
		return
	history.append(document.duplicate(true))
	document = future.pop_back()
	canvas.set_document(document)
	_clear_preview()
	_refresh()
	_message("Redo")


func _import_hall() -> void:
	var source := Routes.import_hall()
	if not source.ok:
		_message("ERROR: " + str(source.error))
		return
	_set_document(source.document)
	_message("Imported original Hall DRAFT_ONLY. Save it before launching; original source remains immutable.")


func _save_user() -> void:
	var saved := Routes.save_draft(Routes.DEFAULT_SAVE, document)
	if not saved.ok:
		_message("ERROR: " + str(saved.error))
		return
	last_saved = JSON.stringify(document)
	last_persisted_kind = PreviewSource.USER
	_refresh_dirty()
	_message("Saved DRAFT_ONLY to user://. Press Play integrated first floor, then choose Saved user in the QA scene.")


func _load_user() -> void:
	var loaded := Routes.load_draft(Routes.DEFAULT_SAVE)
	if not loaded.ok:
		_message("ERROR: " + str(loaded.error))
		return
	_set_document(loaded.document, false)
	last_persisted_kind = PreviewSource.USER
	_message("Loaded persistent user:// QA draft")


func _export_project() -> void:
	var path: String = Routes.PROJECT_DRAFT_DIR + "hall_routes_draft.v1.json"
	var result := Routes.save_draft(path, document)
	if not result.ok:
		_message("ERROR: " + str(result.error))
		return
	last_saved = JSON.stringify(document)
	last_persisted_kind = PreviewSource.PROJECT
	_refresh_dirty()
	EditorInterface.get_resource_filesystem().scan()
	_message("Exported versioned QA draft to " + path + " (source pilot untouched)")


func _load_project() -> void:
	var path: String = Routes.PROJECT_DRAFT_DIR + "hall_routes_draft.v1.json"
	var result := Routes.load_draft(path)
	if not result.ok:
		_message("ERROR: " + str(result.error))
		return
	_set_document(result.document, false)
	last_persisted_kind = PreviewSource.PROJECT
	_message("Opened project QA draft: " + path)


func _open_pilot(kind: String = PreviewSource.BASELINE) -> void:
	if kind != PreviewSource.BASELINE and JSON.stringify(document) != last_saved:
		_message("ERROR: Unsaved editor edits are NOT in the preview. Save or export the draft first.")
		return
	# Probe the persisted disk version, not the in-memory editor document.
	var preview = PreviewSource.new()
	if not preview.load_source(kind):
		_message("ERROR: Cannot play %s: %s" % [kind, preview.error_text])
		return
	var staged := PreviewLaunch.stage(kind)
	if not staged.get("ok", false):
		_message("ERROR: Could not select preview: " + str(staged.get("error", "unknown")))
		return
	EditorInterface.play_custom_scene(PILOT)
	_message("Playing %s: %s · DRAFT_ONLY · %d provisional edges. Only saved files are loaded." % [kind, preview.source_path, preview.provisional_routes.size()])


# Launches the existing MAP-QA-07B playable integration without modifying
# manor-map runtime or relying on unsaved editor state. Source is selected
# explicitly in that scene; no hidden in-memory graph handoff.
func _open_integrated() -> void:
	if JSON.stringify(document) != last_saved:
		_message("ERROR: Unsaved changes cannot be played. Save user draft or export project draft first.")
		return
	var path := Routes.DEFAULT_SAVE if last_persisted_kind == PreviewSource.USER else Routes.PROJECT_DRAFT_DIR + "hall_routes_draft.v1.json"
	var loaded := Routes.load_draft(path)
	if not loaded.get("ok", false):
		_message("ERROR: Cannot launch integrated QA: " + str(loaded.get("error", "missing draft")))
		return
	EditorInterface.play_custom_scene(INTEGRATED)
	_message("MAP-QA-07B launched. Choose " + ("Saved user" if last_persisted_kind == PreviewSource.USER else "Project draft") + " in the scene. TEST_ONLY transitions; source DRAFT_ONLY.")
