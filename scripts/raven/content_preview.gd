extends Control

const Content = preload("res://data/raven/rm_vs_01_content.json")
const Match3 = preload("res://scripts/raven/raven_match3_game.gd")
const VN = preload("res://scripts/raven/raven_vn_player.gd")
const TILE_COLORS := {"raven":Color("40506b"),"key":Color("b8954d"),"rose":Color("884f62"),"candle":Color("d5c38b"),"book":Color("5d704d"),"cup":Color("e8dcc8"),"brooch":Color("a883bc"),"quill":Color("bc9b73")}
const TILE_MARKS := {"raven":"R","key":"K","rose":"✦","candle":"C","book":"B","cup":"☕","brooch":"◆","quill":"Q"}

var content: Dictionary
var body: VBoxContainer
var match_game: RefCounted
var vn_player: RefCounted
var selected := -1
var current_kind := "menu"
var current_id := ""
var return_to_map := false


func _ready() -> void:
	content = Content.data
	return_to_map = get_tree().has_meta("raven_map_preview_level")
	var requested_level := str(get_tree().get_meta("raven_map_preview_level", ""))
	if return_to_map: get_tree().remove_meta("raven_map_preview_level")
	_build_shell()
	_show_menu()
	if not requested_level.is_empty() and not _level(requested_level).is_empty():
		_open_level(requested_level)


func _build_shell() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new(); bg.color = Color("0d1118"); bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(bg)
	var margin := MarginContainer.new(); margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left","margin_right","margin_top","margin_bottom"]: margin.add_theme_constant_override(side, 14)
	add_child(margin)
	var root := VBoxContainer.new(); root.add_theme_constant_override("separation", 10); margin.add_child(root)
	root.add_child(_label("RAVEN CONTENT PREVIEW", 22, Color("eadbbf")))
	root.add_child(_paragraph("Изолированный запуск контента. Прогресс и Raven-save здесь не изменяются."))
	var scroll := ScrollContainer.new(); scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL; root.add_child(scroll)
	body = VBoxContainer.new(); body.custom_minimum_size = Vector2(354, 0); body.add_theme_constant_override("separation", 9); scroll.add_child(body)
	var footer := HBoxContainer.new(); footer.add_theme_constant_override("separation", 6); root.add_child(footer)
	_add_button(footer, "← Меню preview", _show_menu)
	_add_button(footer, "← Лаунчер", func(): get_tree().change_scene_to_file("res://scenes/raven/prototype_launcher.tscn"))
	if return_to_map:
		_add_button(footer, "← Карта", func(): get_tree().change_scene_to_file("res://scenes/raven/season1_map_greybox.tscn"))


func _clear() -> void:
	for child in body.get_children(): child.queue_free()


func _show_menu() -> void:
	current_kind = "menu"; current_id = ""; match_game = null; vn_player = null; selected = -1; _clear()
	body.add_child(_label("MATCH-3 УРОВНИ", 18, Color("f0dfbd")))
	for level: Dictionary in content.levels:
		_add_button(body, "%s · %s" % [level.id, level.title], _open_level.bind(str(level.id)))
	body.add_child(_label("VN СЦЕНЫ / BEATS", 18, Color("f0dfbd")))
	for scene_id in content.get("prologueScenes", {}):
		var prologue: Dictionary = content.prologueScenes[scene_id]
		_add_button(body, "%s · %s" % [prologue.beatId, scene_id], _open_vn.bind(str(scene_id)))
	for scene_id in content.vnScenes:
		var scene: Dictionary = content.vnScenes[scene_id]
		_add_button(body, "%s · %s" % [scene.beatId, scene_id], _open_vn.bind(str(scene_id)))


func _open_level(level_id: String) -> void:
	current_kind = "match3"; current_id = level_id; selected = -1
	match_game = Match3.new(_level(level_id)); _render_level()


func _render_level() -> void:
	_clear()
	var level: Dictionary = match_game.level_data
	body.add_child(_label("%s · %s" % [level.id, level.title], 18, Color("f0dfbd")))
	body.add_child(_paragraph(str(level.get("fiction", "Подготовить работу в комнате."))))
	body.add_child(_paragraph("Ходы: %d · %s: %d/%d · %s" % [match_game.moves_left, level.objective.label, match_game.collected, level.objective.target, match_game.state]))
	var grid := GridContainer.new(); grid.columns = int(level.columns); grid.add_theme_constant_override("h_separation", 3); grid.add_theme_constant_override("v_separation", 3); body.add_child(grid)
	for index in match_game.tiles.size():
		var button := Button.new(); button.text = TILE_MARKS[match_game.tiles[index]]; button.custom_minimum_size = Vector2(50, 50)
		button.add_theme_color_override("font_color", Color("101217")); button.add_theme_font_size_override("font_size", 18)
		var style := StyleBoxFlat.new(); style.bg_color = TILE_COLORS[match_game.tiles[index]]; style.set_corner_radius_all(8)
		if index == selected: style.border_color = Color("ffffff"); style.set_border_width_all(3)
		button.add_theme_stylebox_override("normal", style); button.pressed.connect(_tile_pressed.bind(index)); grid.add_child(button)
	_add_button(body, "СДЕЛАТЬ ПОДСКАЗАННЫЙ ХОД", _play_hint)
	_add_button(body, "ПЕРЕЗАПУСТИТЬ %s" % level.id, _open_level.bind(str(level.id)))


func _tile_pressed(index: int) -> void:
	if match_game.state != "playing": return
	if selected < 0: selected = index; _render_level(); return
	match_game.attempt_swap(selected, index); selected = -1; _render_level()


func _play_hint() -> void:
	if match_game.state != "playing": return
	var hint: Dictionary = match_game.get_hint_move()
	if not hint.is_empty(): match_game.attempt_swap(int(hint.first), int(hint.second))
	_render_level()


func _open_vn(scene_id: String) -> void:
	current_kind = "vn"; current_id = scene_id; vn_player = VN.new(); vn_player.open(_scene(scene_id)); _render_vn()


func _render_vn() -> void:
	_clear()
	var scene: Dictionary = vn_player.scene
	body.add_child(_label("%s · %s" % [scene.beatId, current_id], 18, Color("f0dfbd")))
	body.add_child(_paragraph("Говорит: " + vn_player.current_speaker()))
	var dialogue := _paragraph(vn_player.current_line()); dialogue.custom_minimum_size.y = 170; dialogue.add_theme_color_override("font_color", Color("eee4d2")); body.add_child(dialogue)
	body.add_child(_paragraph("Реплика " + vn_player.progress_text()))
	_add_button(body, "ДАЛЕЕ", _advance_vn)
	_add_button(body, "ПЕРЕЗАПУСТИТЬ BEAT", _open_vn.bind(current_id))


func _advance_vn() -> void:
	if vn_player.advance(): vn_player.open(_scene(current_id))
	_render_vn()


func _scene(scene_id: String) -> Dictionary:
	return content.get("prologueScenes", {}).get(scene_id, content.vnScenes.get(scene_id, {}))


func _level(id: String) -> Dictionary:
	for item: Dictionary in content.levels:
		if item.id == id: return item
	return {}


func _add_button(parent: Container, text: String, action: Callable) -> void:
	var button := Button.new(); button.text = text; button.custom_minimum_size = Vector2(0, 44); button.pressed.connect(action); parent.add_child(button)


func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new(); label.text = text; label.add_theme_font_size_override("font_size", size); label.add_theme_color_override("font_color", color); return label


func _paragraph(text: String) -> Label:
	var label := _label(text, 14, Color("d4ccbe")); label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; label.custom_minimum_size = Vector2(0, 48); return label
