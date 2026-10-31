@tool
extends VBoxContainer
## Godot-native, optional image-backed *editor* stage for canonical Raven Season 1.
## No pixel-perfect/runtime claims: actors without an approved pilot PNG are labeled blocks.
signal stage_modified(stage: Dictionary)

const Store = preload("res://addons/vn_studio/editor/raven_story_store.gd")
const BACKDROP_PILOT := {"BG-HALL": "res://assets/raven/vn_pilot/hall_morning.webp"}
const ACTOR_PILOT := {
	"RM-CHAR-EVELYN": "res://assets/raven/vn_pilot/evelyn_relaxed.webp",
	"RM-CHAR-ADA": "res://assets/raven/vn_pilot/ada_offer_tea.webp"
}
const CARD_SIZE := Vector2(114, 176)
const MARGIN := 8.0

var _project: Dictionary = {}
var _stage_data: Dictionary = {}
var _selected_actor: int = -1
var _dragging_actor: int = -1
var _grab_delta: Vector2 = Vector2.ZERO
var _background: OptionButton
var _actor_pick: OptionButton
var _pose: OptionButton
var _emotion: OptionButton
var _add: Button
var _new_actor: OptionButton
var _remove: Button
var _canvas: Panel
var _bg_image: TextureRect
var _placeholders: Label
var _cards: Array[Button] = []
var _status: Label
var _suppress: bool = false


func _ready() -> void:
	size_flags_horizontal = SIZE_EXPAND_FILL
	var controls := HBoxContainer.new()
	add_child(controls)
	_background = OptionButton.new()
	_background.custom_minimum_size.x = 134
	_background.item_selected.connect(_on_background)
	controls.add_child(_background)
	_actor_pick = OptionButton.new()
	_actor_pick.custom_minimum_size.x = 130
	_actor_pick.item_selected.connect(_on_actor_select)
	controls.add_child(_actor_pick)
	_pose = OptionButton.new()
	_pose.custom_minimum_size.x = 115
	_pose.item_selected.connect(_on_pose)
	controls.add_child(_pose)
	_emotion = OptionButton.new()
	_emotion.custom_minimum_size.x = 110
	_emotion.item_selected.connect(_on_emotion)
	controls.add_child(_emotion)
	_new_actor = OptionButton.new()
	_new_actor.custom_minimum_size.x = 100
	controls.add_child(_new_actor)
	_add = Button.new()
	_add.text = "+ Персонаж"
	_add.pressed.connect(_on_add)
	controls.add_child(_add)
	_remove = Button.new()
	_remove.text = "−"
	_remove.tooltip_text = "Убрать выделенного персонажа из постановки"
	_remove.pressed.connect(_on_remove)
	controls.add_child(_remove)

	_canvas = Panel.new()
	_canvas.custom_minimum_size = Vector2(540, 335)
	_canvas.size_flags_horizontal = SIZE_EXPAND_FILL
	_canvas.clip_contents = true
	_canvas.resized.connect(_layout_cards)
	add_child(_canvas)
	_bg_image = TextureRect.new()
	_bg_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bg_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_bg_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.add_child(_bg_image)
	_placeholders = Label.new()
	_placeholders.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_placeholders.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_placeholders.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.add_child(_placeholders)
	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.text = "Изменения здесь остаются только в Raven-черновике до ручного ревью."
	add_child(_status)


func set_scene(project: Dictionary, draft: Dictionary, id: String) -> void:
	_project = project
	_selected_actor = -1
	if not bool(project.get("ok", false)):
		return
	_stage_data = Store.effective_stage(project, draft, id)
	_reload()


func _reload() -> void:
	if _stage_data.is_empty():
		return
	_suppress = true
	var opts: Dictionary = Store.stage_options(_project)
	_background.clear()
	for bg in opts["backgrounds"]:
		_background.add_item(str(bg))
		if bg == _stage_data.get("backgroundId"):
			_background.select(_background.item_count - 1)
	_actor_pick.clear()
	var cast: Array = _stage_data.get("cast", [])
	for item in cast:
		_actor_pick.add_item(str(item["characterId"]).trim_prefix("RM-CHAR-"))
	if not cast.is_empty():
		_selected_actor = clampi(_selected_actor, 0, cast.size() - 1)
		_actor_pick.select(_selected_actor)
	else:
		_selected_actor = -1
	_reload_poses()
	_new_actor.clear()
	for candidate in opts["actors"]:
		var found: bool = false
		for present in cast:
			if present.get("characterId", "") == candidate:
				found = true
				break
		if not found:
			_new_actor.add_item(str(candidate).trim_prefix("RM-CHAR-"))
	_add.disabled = cast.size() >= 3 or _new_actor.item_count == 0
	_remove.disabled = _selected_actor < 0
	_suppress = false
	_draw_stage()


func _reload_poses() -> void:
	_pose.clear()
	_emotion.clear()
	if _selected_actor < 0 or _selected_actor >= _stage_data.get("cast", []).size():
		_pose.disabled = true
		_emotion.disabled = true
		return
	var actor: Dictionary = _stage_data["cast"][_selected_actor]
	var spec: Dictionary = Store.stage_options(_project)["actors"].get(str(actor["characterId"]), {})
	for p in spec.get("poses", []):
		_pose.add_item(str(p))
		if p == actor.get("pose"):
			_pose.select(_pose.item_count - 1)
	for e in spec.get("emotions", []):
		_emotion.add_item(str(e))
		if e == actor.get("emotion"):
			_emotion.select(_emotion.item_count - 1)
	_pose.disabled = false
	_emotion.disabled = false


func _draw_stage() -> void:
	for card in _cards:
		_canvas.remove_child(card)
		card.queue_free()
	_cards.clear()
	var bg_id: String = str(_stage_data.get("backgroundId", ""))
	_bg_image.texture = _texture(str(BACKDROP_PILOT.get(bg_id, "")))
	_placeholders.text = "" if _bg_image.texture != null else "ART PENDING · " + bg_id + " · preview layout only"
	_bg_image.size = _canvas.size
	_placeholders.size = Vector2(_canvas.size.x, 28)
	var cast: Array = _stage_data.get("cast", [])
	for index in range(cast.size()):
		var actor: Dictionary = cast[index]
		var card := Button.new()
		card.custom_minimum_size = CARD_SIZE
		card.size = CARD_SIZE
		card.clip_contents = true
		card.text = str(actor["characterId"]).trim_prefix("RM-CHAR-") + "\n" + str(actor.get("emotion", ""))
		card.alignment = HORIZONTAL_ALIGNMENT_CENTER
		card.focus_mode = Control.FOCUS_ALL
		card.gui_input.connect(_on_card_input.bind(index))
		_canvas.add_child(card)
		var picture: Texture2D = _texture(str(ACTOR_PILOT.get(str(actor["characterId"]), "")))
		if picture != null:
			var display := TextureRect.new()
			display.texture = picture
			display.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			display.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CONTAINED
			display.mouse_filter = Control.MOUSE_FILTER_IGNORE
			display.position = Vector2(8, 5)
			display.size = Vector2(CARD_SIZE.x - 16, CARD_SIZE.y - 47)
			card.add_child(display)
		_cards.append(card)
	_layout_cards()
	_status.text = "%s · %d персонажей · координаты нормализованы; реальные PNG доступны не для всех." % [
		bg_id, cast.size()]


func _texture(path: String) -> Texture2D:
	if not path.begins_with("res://assets/raven/vn_pilot/"):
		return null
	var location: String = ProjectSettings.globalize_path(path)
	if not FileAccess.file_exists(location):
		return null
	var image := Image.new()
	if image.load(location) != OK:
		return null
	return ImageTexture.create_from_image(image)


func _coordinates(index: int) -> Vector2:
	var actor: Dictionary = _stage_data["cast"][index]
	var fallback: float = {"left": 0.12, "center": 0.50, "right": 0.88}.get(str(actor.get("slot", "center")), 0.5)
	return Vector2(float(actor.get("x", fallback)), float(actor.get("y", 0.50)))


func _layout_cards() -> void:
	if _canvas == null:
		return
	_bg_image.size = _canvas.size
	_placeholders.size = Vector2(_canvas.size.x, 28)
	for i in range(_cards.size()):
		_cards[i].position = _position_for(_coordinates(i))


func _position_for(normalized: Vector2) -> Vector2:
	return Vector2(
		MARGIN + normalized.x * maxf(_canvas.size.x - CARD_SIZE.x - 2.0 * MARGIN, 0.0),
		MARGIN + normalized.y * maxf(_canvas.size.y - CARD_SIZE.y - 2.0 * MARGIN, 0.0))


func _normalize_position(position: Vector2) -> Vector2:
	return Vector2(
		clampf((position.x - MARGIN) / maxf(_canvas.size.x - CARD_SIZE.x - 2.0 * MARGIN, 1.0), 0.0, 1.0),
		clampf((position.y - MARGIN) / maxf(_canvas.size.y - CARD_SIZE.y - 2.0 * MARGIN, 1.0), 0.0, 1.0))


func _on_card_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_selected_actor = index
			_actor_pick.select(index)
			_reload_poses()
			_dragging_actor = index
			_grab_delta = event.position
		elif _dragging_actor == index:
			_dragging_actor = -1
			_commit()
	elif event is InputEventMouseMotion and _dragging_actor == index and (event.button_mask & MOUSE_BUTTON_MASK_LEFT):
		var local_position: Vector2 = _cards[index].position + event.position - _grab_delta
		var coords: Vector2 = _normalize_position(local_position)
		_stage_data["cast"][index]["x"] = snappedf(coords.x, 0.001)
		_stage_data["cast"][index]["y"] = snappedf(coords.y, 0.001)
		_cards[index].position = _position_for(coords)


func _on_background(index: int) -> void:
	if _suppress or index < 0:
		return
	_stage_data["backgroundId"] = _background.get_item_text(index)
	_commit()


func _on_actor_select(index: int) -> void:
	if index < 0:
		return
	_selected_actor = index
	_reload_poses()
	_remove.disabled = false


func _on_pose(index: int) -> void:
	if _suppress or _selected_actor < 0 or index < 0:
		return
	_stage_data["cast"][_selected_actor]["pose"] = _pose.get_item_text(index)
	_commit()


func _on_emotion(index: int) -> void:
	if _suppress or _selected_actor < 0 or index < 0:
		return
	_stage_data["cast"][_selected_actor]["emotion"] = _emotion.get_item_text(index)
	_commit()


func _on_add() -> void:
	var specs: Dictionary = Store.stage_options(_project)["actors"]
	var present: Array = _stage_data.get("cast", [])
	if present.size() >= 3:
		return
	var existing: Array[String] = []
	for actor in present:
		existing.append(str(actor["characterId"]))
	var next_id: String = ""
	if _new_actor.item_count > 0 and _new_actor.selected >= 0:
		next_id = "RM-CHAR-" + _new_actor.get_item_text(_new_actor.selected)
	if next_id in existing:
		return
	if next_id.is_empty():
		return
	var spec: Dictionary = specs[next_id]
	present.append({"characterId": next_id, "slot": "center",
		"pose": str(spec["poses"][0]), "emotion": str(spec["emotions"][0]),
		"x": 0.50, "y": 0.50, "micro": ""})
	_stage_data["cast"] = present
	_stage_data["visibleCount"] = present.size()
	_selected_actor = present.size() - 1
	_commit()


func _on_remove() -> void:
	if _selected_actor < 0:
		return
	_stage_data["cast"].remove_at(_selected_actor)
	_stage_data["visibleCount"] = _stage_data["cast"].size()
	_selected_actor = clampi(_selected_actor, 0, _stage_data["cast"].size() - 1) if not _stage_data["cast"].is_empty() else -1
	_commit()


func _commit() -> void:
	var error: String = Store.validate_stage(_project, _stage_data)
	if not error.is_empty():
		_status.text = "Постановка заблокирована: " + error
		return
	stage_modified.emit(_stage_data.duplicate(true))
	_reload()
