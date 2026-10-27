extends Control

const Content = preload("res://data/raven/rm_vs_01_content.json")
const Match3 = preload("res://scripts/raven/raven_match3_game.gd")
const VN = preload("res://scripts/raven/raven_vn_player.gd")
const Match3Board = preload("res://scripts/match3/match3_board_presenter.gd")
const Match3Theme = preload("res://scripts/raven/raven_match3_theme.gd")
const MobileLayout = preload("res://scripts/match3/match3_mobile_layout.gd")

var content: Dictionary
var body: VBoxContainer
var match_game: RefCounted
var vn_player: RefCounted
var board_view: VBoxContainer
var level_status: Label
var current_kind := "menu"
var current_id := ""
var return_to_map := false


func _ready() -> void:
	content = Content.data
	return_to_map = get_tree().has_meta("raven_map_preview_level")
	var requested_level := str(get_tree().get_meta("raven_direct_preview_level", ""))
	if get_tree().has_meta("raven_direct_preview_level"):
		get_tree().remove_meta("raven_direct_preview_level")
	if return_to_map:
		requested_level = str(get_tree().get_meta("raven_map_preview_level", ""))
		get_tree().remove_meta("raven_map_preview_level")
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
	var title := _label("RAVEN CONTENT PREVIEW", 18, Color("eadbbf"))
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(title)
	root.add_child(_paragraph("QA: тот же Match-3 интерфейс, что в RM-VS-01. Прогресс и Raven-save не изменяются."))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 9)
	scroll.add_child(body)
	var footer := GridContainer.new()
	footer.columns = 2
	footer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_theme_constant_override("h_separation", 6)
	footer.add_theme_constant_override("v_separation", 6)
	root.add_child(footer)
	_add_button(footer, "← Меню preview", _show_menu)
	_add_button(footer, "← Лаунчер", func(): get_tree().change_scene_to_file("res://scenes/raven/prototype_launcher.tscn"))
	if return_to_map:
		_add_button(footer, "← Карта", func(): get_tree().change_scene_to_file("res://scenes/raven/season1_map_greybox.tscn"))


func _clear() -> void:
	for child in body.get_children(): child.queue_free()


func _show_menu() -> void:
	current_kind = "menu"; current_id = ""; match_game = null; vn_player = null; board_view = null; level_status = null; _clear()
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
	var level := _level(level_id)
	if level.is_empty():
		push_warning("Unknown QA Match-3 level: " + level_id)
		return
	current_kind = "match3"
	current_id = level_id
	match_game = Match3.new(level)
	_render_level()


func _render_level() -> void:
	_clear()
	var level: Dictionary = match_game.level_data
	body.add_child(_label("%s · %s" % [level.id, level.title], 18, Color("f0dfbd")))
	body.add_child(_paragraph(str(level.get("fiction", "Подготовить работу в комнате."))))
	board_view = Match3Board.new()
	board_view.name = "QA_UPDSMatch3Board"
	body.add_child(board_view)
	board_view.setup(match_game, Match3Theme.placeholder())
	board_view.level_won.connect(_level_won_in_preview)
	level_status = _paragraph("Режим QA: свайпы, спецфишки, цели и результат. Без записи в Raven-save.")
	body.add_child(level_status)
	_add_button(body, "ПЕРЕЗАПУСТИТЬ %s (только QA)" % level.id, _open_level.bind(str(level.id)))


func _level_won_in_preview() -> void:
	# A preview intentionally has no reducer, Store or campaign reward event.
	# The same shared presenter sends level_won; only text changes here.
	if is_instance_valid(level_status):
		level_status.text = "Уровень пройден в QA. Сохранение и награды кампании не изменены."


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
	var button := Button.new(); button.text = text; button.custom_minimum_size = Vector2(0, MobileLayout.MIN_TAP); button.size_flags_horizontal = Control.SIZE_EXPAND_FILL; button.pressed.connect(action); parent.add_child(button)


func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new(); label.text = text; label.add_theme_font_size_override("font_size", size); label.add_theme_color_override("font_color", color); return label


func _paragraph(text: String) -> Label:
	var label := _label(text, 14, Color("d4ccbe")); label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; label.custom_minimum_size = Vector2(0, 48); return label
