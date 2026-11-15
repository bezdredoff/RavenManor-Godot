extends CanvasLayer
## Diagnostic crop and existing-room approach selector. No crossing authority.
const Review = preload("res://scripts/raven/first_floor_door_review.gd")
const ART = preload("res://a_detailed_top_down_isometric_game_map_illustratio.png")
var qa
var document: Dictionary = {}
var selected_index := 0
var _picker: OptionButton
var _image: TextureRect
var _details: RichTextLabel
var _sides: HFlowContainer
var _result: Label


func _ready() -> void:
	layer = 30
	var panel := PanelContainer.new()
	var background := StyleBoxFlat.new()
	background.bg_color = Color("#101720")
	background.border_color = Color("#5b7287")
	background.set_border_width_all(1)
	panel.add_theme_stylebox_override("panel", background)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 12
	panel.offset_top = 12
	panel.offset_right = -12
	panel.offset_bottom = -12
	add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 10)
	panel.add_child(margin)
	var rows := VBoxContainer.new()
	margin.add_child(rows)
	var title := Label.new()
	title.text = "MAP-QA-09 | Door evidence | NO REAL CROSSINGS"
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rows.add_child(title)
	_picker = OptionButton.new()
	_picker.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_picker.item_selected.connect(select_door)
	rows.add_child(_picker)
	_image = TextureRect.new()
	_image.custom_minimum_size = Vector2(0, 220)
	_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rows.add_child(_image)
	_details = RichTextLabel.new()
	_details.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_details.custom_minimum_size.y = 170
	_details.bbcode_enabled = false
	rows.add_child(_details)
	_sides = HFlowContainer.new()
	rows.add_child(_sides)
	_result = Label.new()
	_result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rows.add_child(_result)
	var close_button := Button.new()
	close_button.text = "Close evidence (no approval / no changes saved)"
	close_button.pressed.connect(hide)
	rows.add_child(close_button)
	var loaded := Review.load_review()
	if not loaded.get("ok", false):
		_result.text = str(loaded.get("error", "Invalid door review"))
		return
	document = loaded.document
	for door in document.doors:
		_picker.add_item(str(door.id))
	select_door(0)
	hide()


func open_review() -> void:
	show()


func select_door(index: int) -> void:
	if index < 0 or index >= document.get("doors", []).size():
		return
	selected_index = index
	_picker.select(index)
	var door: Dictionary = document.doors[index]
	var rect: Array = door.reviewRectPx
	var texture := AtlasTexture.new()
	texture.atlas = ART
	texture.region = Rect2(float(rect[0]), float(rect[1]), float(rect[2]), float(rect[3]))
	_image.texture = texture
	_details.text = "%s\n%s\n\n%s\n\nManifest: %s\n\nNear/far physical feet: UNRESOLVED\nWidth, elevation, collision, foreground: UNRESOLVED\nStory gate: %s (external runtime)\n\nSide actions below only reset a QA room and walk to an existing 08B stop. They never cross this wall." % [
		str(door.id), str(door.classification), str(door.evidence),
		str(door.manifestVisualStatus), str(door.referenceState)]
	for child in _sides.get_children():
		_sides.remove_child(child)
		child.queue_free()
	for i in door.roomSideStops.size():
		var stop: Dictionary = door.roomSideStops[i]
		var button := Button.new()
		button.text = "QA reset side %s (%s) + walk" % [char(65 + i), str(stop.roomId).trim_prefix("RM-ROOM-")]
		button.tooltip_text = str(stop.roomId) + " / " + str(stop.waypointId) + " | NOT a threshold"
		button.pressed.connect(preview_side.bind(i))
		_sides.add_child(button)
	var crossing := Button.new()
	crossing.text = "Real crossing unavailable"
	crossing.disabled = true
	crossing.tooltip_text = "No confirmed opening/contacts. MAP-QA-07B TEST_ONLY transitions are independent."
	_sides.add_child(crossing)
	_result.text = "Original PNG crop %s. Inspection only; zero real portals enabled." % str(rect)


func preview_side(side_index: int) -> bool:
	var door: Dictionary = document.doors[selected_index]
	if side_index < 0 or side_index >= door.roomSideStops.size() or not is_instance_valid(qa):
		return false
	if qa._source_path != Review.CANDIDATE:
		_result.text = "Choose 08B visual candidate in QA first; evidence never substitutes a source silently."
		return false
	var stop: Dictionary = door.roomSideStops[side_index]
	if not qa.restart_island(str(stop.roomId)):
		_result.text = "QA reset refused during movement/handoff. Finish or cancel the current segment."
		return false
	var result: Dictionary = qa.walk_waypoint(str(stop.waypointId))
	if not result.get("ok", false):
		_result.text = str(result.get("error", "Room approach refused"))
		return false
	_result.text = "QA ROOM RESET + existing route to " + str(stop.waypointId) + ". This is NOT door traversal."
	hide()
	return true
