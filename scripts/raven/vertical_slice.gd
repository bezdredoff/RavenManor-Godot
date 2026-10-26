extends Control

const Content = preload("res://data/raven/rm_vs_01_content.json")
const Snapshot = preload("res://scripts/raven/raven_snapshot.gd")
const Reducer = preload("res://scripts/raven/raven_reducer.gd")
const Store = preload("res://scripts/raven/raven_campaign_store.gd")
const Director = preload("res://scripts/raven/raven_slice_director.gd")
const Match3 = preload("res://scripts/raven/raven_match3_game.gd")
const VN = preload("res://scripts/raven/raven_vn_player.gd")

const TILE_COLORS := {"raven":Color("40506b"),"key":Color("b8954d"),"rose":Color("884f62"),"candle":Color("d5c38b"),"book":Color("5d704d"),"cup":Color("e8dcc8"),"brooch":Color("a883bc"),"quill":Color("bc9b73")}
const TILE_MARKS := {"raven":"R","key":"K","rose":"✦","candle":"C","book":"B","cup":"☕","brooch":"◆","quill":"Q"}

var store := Store.new()
var state := Snapshot.fresh()
var step: Dictionary = {}
var match_game: RefCounted
var vn_player: RefCounted
var selected := -1
var event_serial := 0
var content: Dictionary
var body: VBoxContainer
var status: Label


func _ready() -> void:
	content = Content.data
	state = store.load_campaign()
	_build_shell()
	_render()


func _build_shell() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new(); bg.color = Color("0d1118"); bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(bg)
	var margin := MarginContainer.new(); margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left","margin_right","margin_top","margin_bottom"]: margin.add_theme_constant_override(side, 14)
	add_child(margin)
	var root := VBoxContainer.new(); root.add_theme_constant_override("separation", 10); margin.add_child(root)
	var title := _label("RAVEN MANOR · RM-VS-01", 22, Color("eadbbf")); root.add_child(title)
	status = _label("", 12, Color("9fc8bc")); status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; root.add_child(status)
	var scroll := ScrollContainer.new(); scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL; root.add_child(scroll)
	body = VBoxContainer.new(); body.custom_minimum_size = Vector2(354, 0); body.add_theme_constant_override("separation", 10); scroll.add_child(body)
	var footer := HBoxContainer.new(); footer.add_theme_constant_override("separation", 6); root.add_child(footer)
	_add_button(footer, "← Лаунчер", func(): get_tree().change_scene_to_file("res://scenes/raven/prototype_launcher.tscn"))
	_add_button(footer, "Save", _save)
	_add_button(footer, "Reload", _reload)
	_add_button(footer, "Reset", _reset)


func _render() -> void:
	for child in body.get_children(): child.queue_free()
	step = Director.next_step(state)
	status.text = "Прогресс %d/%d · очки %d · save rev.%d" % [_step_index(step.id), Director.STEPS.size() - 1, state.workPoints, state.revision]
	body.add_child(_label(str(step.title), 20, Color("f0dfbd")))
	match str(step.kind):
		"map","restore","clue":
			body.add_child(_paragraph(str(step.body)))
			_add_button(body, "ВЫПОЛНИТЬ", _complete_action)
		"vn": _render_vn()
		"match3": _render_match3()
		"done":
			body.add_child(_paragraph(str(step.body)))
			body.add_child(_paragraph("Уровни: %s\nРеставрации: %s\nУлики: %s" % [state.firstClearLevels, state.completedRestorations, state.recordedClues]))
			_add_button(body, "ОТКРЫТЬ КАРТУ", func(): get_tree().change_scene_to_file("res://scenes/raven/manor_greybox.tscn"))


func _render_vn() -> void:
	var scene_id := str(step.scene)
	var config: Dictionary = content.get("prologueScenes", {}).get(scene_id, content.vnScenes.get(scene_id, {}))
	if vn_player == null or vn_player.scene.get("beatId", "") != config.beatId:
		vn_player = VN.new(); vn_player.open(config)
	body.add_child(_paragraph("[%s] %s" % [config.beatId, vn_player.current_speaker()]))
	var dialogue := _paragraph(vn_player.current_line()); dialogue.custom_minimum_size.y = 150; dialogue.add_theme_color_override("font_color", Color("eee4d2")); body.add_child(dialogue)
	body.add_child(_paragraph("Реплика " + vn_player.progress_text()))
	_add_button(body, "ДАЛЕЕ", _advance_vn)


func _render_match3() -> void:
	var level := _level(str(step.level))
	if match_game == null or match_game.level_data.id != level.id:
		match_game = Match3.new(level); selected = -1
	body.add_child(_paragraph(str(level.get("fiction", "Подготовить работу в комнате."))))
	body.add_child(_paragraph("%s · Ходы: %d · %s: %d/%d" % [level.id, match_game.moves_left, level.objective.label, match_game.collected, level.objective.target]))
	var grid := GridContainer.new(); grid.columns = int(level.columns); grid.add_theme_constant_override("h_separation", 3); grid.add_theme_constant_override("v_separation", 3); body.add_child(grid)
	for index in match_game.tiles.size():
		var button := Button.new(); button.text = TILE_MARKS[match_game.tiles[index]]; button.custom_minimum_size = Vector2(50, 50)
		button.add_theme_color_override("font_color", Color("101217")); button.add_theme_font_size_override("font_size", 18)
		var style := StyleBoxFlat.new(); style.bg_color = TILE_COLORS[match_game.tiles[index]]; style.set_corner_radius_all(8)
		if index == selected: style.border_color = Color("ffffff"); style.set_border_width_all(3)
		button.add_theme_stylebox_override("normal", style); button.pressed.connect(_tile_pressed.bind(index)); grid.add_child(button)
	_add_button(body, "ПОДСКАЗКА: СДЕЛАТЬ ЛУЧШИЙ ХОД", _play_hint)


func _tile_pressed(index: int) -> void:
	if selected < 0: selected = index; _render(); return
	var result: Dictionary = match_game.attempt_swap(selected, index); selected = -1
	if result.get("won", false): _complete_level()
	elif result.get("lost", false): match_game.reset(); _render()
	else: _render()


func _play_hint() -> void:
	var hint: Dictionary = match_game.get_hint_move()
	if hint.is_empty(): match_game.reset(); _render(); return
	var result: Dictionary = match_game.attempt_swap(int(hint.first), int(hint.second))
	if result.get("won", false): _complete_level()
	elif result.get("lost", false): match_game.reset(); _render()
	else: _render()


func _complete_level() -> void:
	_apply_events([{"type":"level_won","levelId":str(step.level)}]); match_game = null; _render()


func _complete_action() -> void:
	_apply_events(Director.events_for(str(step.id))); _render()


func _advance_vn() -> void:
	if vn_player.advance():
		_apply_events([{"type":"story_beat_seen","storyBeatId":str(vn_player.scene.beatId)}]); vn_player = null
	_render()


func _apply_events(events: Array) -> void:
	for raw: Dictionary in events:
		event_serial += 1
		var event := raw.duplicate(true); event.eventId = "vs-%s-%d-%d" % [step.id, state.revision, event_serial]
		var result := Reducer.apply(state, event)
		if not result.ok: push_error("RM-VS-01 event rejected: " + str(result.error)); return
		state = result.state
	store.save_campaign(state)


func _level(id: String) -> Dictionary:
	for item: Dictionary in content.levels:
		if item.id == id: return item
	return {}


func _step_index(current: String) -> int:
	for index in Director.STEPS.size():
		if Director.STEPS[index].id == current: return index
	return 0


func _save() -> void: store.save_campaign(state); _render()
func _reload() -> void: state = store.load_campaign(); match_game = null; vn_player = null; _render()
func _reset() -> void: store.reset_campaign(); state = Snapshot.fresh(); match_game = null; vn_player = null; _render()


func _add_button(parent: Container, text: String, action: Callable) -> void:
	var button := Button.new(); button.text = text; button.custom_minimum_size = Vector2(0, 44); button.pressed.connect(action); parent.add_child(button)


func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new(); label.text = text; label.add_theme_font_size_override("font_size", size); label.add_theme_color_override("font_color", color); return label


func _paragraph(text: String) -> Label:
	var label := _label(text, 14, Color("d4ccbe")); label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; label.custom_minimum_size = Vector2(0, 54); return label
