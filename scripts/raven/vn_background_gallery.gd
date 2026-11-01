extends Control
## Read-only, save-neutral gallery of candidate VN room/state paintings.
const VNBackgrounds = preload("res://scripts/raven/raven_vn_backgrounds.gd")
const RETURN_SCENE := "res://scenes/raven/prototype_launcher.tscn"
var entries: Array = []
var selected := 0
var artwork: TextureRect
var caption: Label
var picker: OptionButton


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	clip_contents = true
	entries = VNBackgrounds.all_entries()
	_build_ui()
	_show(0)


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color("10131b")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.add_theme_constant_override("separation", 8)
	column.offset_left = 9
	column.offset_top = 8
	column.offset_right = -9
	column.offset_bottom = -9
	add_child(column)
	var top := HBoxContainer.new()
	column.add_child(top)
	var back := Button.new()
	back.text = "← Prototype Lab"
	back.custom_minimum_size = Vector2(115, 42)
	back.pressed.connect(func(): get_tree().change_scene_to_file(RETURN_SCENE))
	top.add_child(back)
	var title := Label.new()
	title.text = "VN BACKGROUNDS · CANDIDATES"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color("f1dec4"))
	top.add_child(title)
	picker = OptionButton.new()
	picker.custom_minimum_size.y = 46
	picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for item: Dictionary in entries:
		picker.add_item("%s · %s / %s" % [item["backgroundId"], item["lighting"], item["roomState"]])
	picker.item_selected.connect(_show)
	column.add_child(picker)
	var frame := PanelContainer.new()
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(frame)
	artwork = TextureRect.new()
	artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	artwork.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	artwork.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	artwork.size_flags_vertical = Control.SIZE_EXPAND_FILL
	artwork.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(artwork)
	caption = Label.new()
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption.add_theme_font_size_override("font_size", 12)
	caption.add_theme_color_override("font_color", Color("ead5bd"))
	column.add_child(caption)
	var controls := HBoxContainer.new()
	column.add_child(controls)
	for pair in [["← Previous", -1], ["Next →", 1]]:
		var button := Button.new()
		button.text = pair[0]
		button.custom_minimum_size.y = 46
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_move.bind(int(pair[1])))
		controls.add_child(button)


func _move(delta: int) -> void:
	if not entries.is_empty():
		_show(posmod(selected + delta, entries.size()))


func _show(index: int) -> void:
	if index < 0 or index >= entries.size():
		return
	selected = index
	picker.select(selected)
	var entry: Dictionary = entries[selected]
	var tex: Texture2D = VNBackgrounds.texture_for(str(entry["backgroundId"]), str(entry["lighting"]), str(entry["roomState"]))
	artwork.texture = tex
	caption.text = "%d/%d · %s / %s / %s · 1080×1920 · %s" % [selected + 1, entries.size(), entry["backgroundId"], entry["lighting"], entry["roomState"], "CANDIDATE — NOT FINAL ART" if tex != null else "ART PENDING"]
