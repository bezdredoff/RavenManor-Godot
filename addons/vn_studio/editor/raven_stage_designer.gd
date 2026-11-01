@tool
extends VBoxContainer
## Godot-native, optional image-backed *editor* stage for canonical Raven Season 1.
## Uses the same approved character registry as the gameplay VN compositor.
signal stage_modified(stage: Dictionary)

const Store = preload("res://addons/vn_studio/editor/raven_story_store.gd")
const VNBackgrounds = preload("res://scripts/raven/raven_vn_backgrounds.gd")
const StageOverlay = preload("res://addons/vn_studio/editor/raven_stage_overlay.gd")
const Characters = preload("res://scripts/raven/raven_vn_characters.gd")
const PortraitLayout = preload("res://scripts/raven/raven_vn_portrait_layout.gd")
const StageLayout = preload("res://addons/vn_studio/model/stage_layout_tools.gd")
const CARD_SIZE := Vector2(114, 176) # only tool-strip thumbnail size
const REFERENCE_SIZE := Vector2(390, 844)
# Hall Tea's current live VN pilot renders portraits at 77% width / 73% height.
# Do not multiply these sizes by an editor thumbnail slider.
const GAME_PORTRAIT_FRACTION := Vector2(0.77, 0.73)

var _project: Dictionary = {}
var _stage_data: Dictionary = {}
var _selected_actor: int = -1
var _dragging_actor: int = -1
var _grab_delta: Vector2 = Vector2.ZERO
var _background: OptionButton
var _actor_pick: OptionButton
var _lighting: OptionButton
var _room_state: OptionButton
var _browse_background: Button
var _pose: OptionButton
var _emotion: OptionButton
var _asset_pick: OptionButton
var _add: Button
var _new_actor: OptionButton
var _remove: Button
var _canvas: Panel
var _bg_image: TextureRect
var _placeholders: Label
var _cards: Array[Button] = []
var _overlay: Control
var _orientation: OptionButton
var _bg_fit: OptionButton
var _safe_toggle: CheckBox
var _template_button: Button
var _undo_button: Button
var _preview_orientation: String = "portrait"
var _undo_stages: Array[Dictionary] = []
var _committed_stage: Dictionary = {}
var _grid_toggle: CheckBox
var _vn_toggle: CheckBox
var _portrait_scale: HSlider
var _thumbnail_strip: HFlowContainer
var _thumbnail_size: Vector2 = CARD_SIZE * 0.55
var _card_size: Vector2 = Vector2(REFERENCE_SIZE.x * GAME_PORTRAIT_FRACTION.x, REFERENCE_SIZE.y * GAME_PORTRAIT_FRACTION.y)
var _browser: ConfirmationDialog
var _browser_list: ItemList
var _browser_image: TextureRect
var _browser_description: Label
var _browser_selected: Dictionary = {}
var _browser_variants: Array[Dictionary] = []
var _status: Label
var _suppress: bool = false


func _ready() -> void:
	size_flags_horizontal = SIZE_EXPAND_FILL
	var controls := HFlowContainer.new()
	add_child(controls)
	var bg_caption := Label.new()
	bg_caption.text = "Фон"
	controls.add_child(bg_caption)
	_background = OptionButton.new()
	_background.custom_minimum_size.x = 134
	_background.item_selected.connect(_on_background)
	controls.add_child(_background)
	_lighting = OptionButton.new()
	_lighting.custom_minimum_size.x = 100
	_lighting.item_selected.connect(_on_lighting)
	controls.add_child(_lighting)
	_room_state = OptionButton.new()
	_room_state.custom_minimum_size.x = 125
	_room_state.item_selected.connect(_on_room_state)
	controls.add_child(_room_state)
	# Browser controls are on their own row so the editor stays usable at
	# the narrower embedded VN Studio panel widths.
	var browser_row := HFlowContainer.new()
	add_child(browser_row)
	_browse_background = Button.new()
	_browse_background.text = "В каталоге: %d фонов…" % VNBackgrounds.all_entries().size()
	_browse_background.tooltip_text = "Показать только реально импортированные варианты фонов VN"
	_browse_background.pressed.connect(_on_browse_imported)
	browser_row.add_child(_browse_background)
	var show_all := Button.new()
	show_all.text = "Все запланированные состояния…"
	show_all.tooltip_text = "Включая состояния без изображений (ART PENDING)"
	show_all.pressed.connect(_on_browse)
	browser_row.add_child(show_all)
	var actors_row := HFlowContainer.new()
	add_child(actors_row)
	_actor_pick = OptionButton.new()
	_actor_pick.custom_minimum_size.x = 130
	_actor_pick.item_selected.connect(_on_actor_select)
	actors_row.add_child(_actor_pick)
	_pose = OptionButton.new()
	_pose.custom_minimum_size.x = 115
	_pose.item_selected.connect(_on_pose)
	actors_row.add_child(_pose)
	_emotion = OptionButton.new()
	_emotion.custom_minimum_size.x = 110
	_emotion.item_selected.connect(_on_emotion)
	actors_row.add_child(_emotion)
	_asset_pick = OptionButton.new()
	_asset_pick.custom_minimum_size.x = 190
	_asset_pick.tooltip_text = "Принятые изображения выбранного персонажа: позы, эмоции и предметы"
	_asset_pick.item_selected.connect(_on_asset_pick)
	actors_row.add_child(_asset_pick)
	_new_actor = OptionButton.new()
	_new_actor.custom_minimum_size.x = 100
	actors_row.add_child(_new_actor)
	_add = Button.new()
	_add.text = "+ Персонаж"
	_add.pressed.connect(_on_add)
	actors_row.add_child(_add)
	_remove = Button.new()
	_remove.text = "−"
	_remove.tooltip_text = "Убрать выделенного персонажа из постановки"
	_remove.pressed.connect(_on_remove)
	actors_row.add_child(_remove)

	var options_row := HFlowContainer.new()
	add_child(options_row)
	_orientation = OptionButton.new()
	_orientation.add_item("Портрет · 390×844")
	_orientation.add_item("Альбом · 844×390")
	_orientation.tooltip_text = "Ориентация preview — editor-only; не меняет текущую схему VN staging v1"
	_orientation.item_selected.connect(_on_orientation)
	options_row.add_child(_orientation)
	_bg_fit = OptionButton.new()
	_bg_fit.add_item("Фон: cover")
	_bg_fit.add_item("Фон: fit")
	_bg_fit.tooltip_text = "Только способ просмотра картинки, не новая генерация и не сохранённый crop"
	_bg_fit.item_selected.connect(_on_background_fit)
	options_row.add_child(_bg_fit)
	_template_button = Button.new()
	_template_button.text = "Шаблон 1/2/3"
	_template_button.tooltip_text = "Применить шаблон для текущего количества персонажей; изменяет черновик, поддерживает отмену"
	_template_button.pressed.connect(_on_template)
	options_row.add_child(_template_button)
	_undo_button = Button.new()
	_undo_button.text = "Отменить постановку"
	_undo_button.tooltip_text = "Отмена последних изменений stage в этой сцене (до 32 шагов)"
	_undo_button.pressed.connect(_on_undo)
	_undo_button.disabled = true
	options_row.add_child(_undo_button)
	_safe_toggle = CheckBox.new()
	_safe_toggle.text = "Safe area"
	_safe_toggle.toggled.connect(_on_safe_toggle)
	options_row.add_child(_safe_toggle)
	_grid_toggle = CheckBox.new()
	_grid_toggle.text = "Сетка (px)"
	_grid_toggle.toggled.connect(_on_grid_toggle)
	options_row.add_child(_grid_toggle)
	_vn_toggle = CheckBox.new()
	_vn_toggle.text = "Показать интерфейс VN"
	_vn_toggle.toggled.connect(_on_vn_toggle)
	options_row.add_child(_vn_toggle)
	var scale_caption := Label.new()
	scale_caption.text = "Миниатюры"
	options_row.add_child(scale_caption)
	_portrait_scale = HSlider.new()
	_portrait_scale.custom_minimum_size.x = 100
	_portrait_scale.min_value = 0.35
	_portrait_scale.max_value = 1.0
	_portrait_scale.step = 0.05
	_portrait_scale.value = 0.55
	_portrait_scale.value_changed.connect(_on_portrait_scale)
	options_row.add_child(_portrait_scale)
	_thumbnail_strip = HFlowContainer.new()
	_thumbnail_strip.size_flags_horizontal = SIZE_EXPAND_FILL
	add_child(_thumbnail_strip)
	_canvas = Panel.new()
	# The preview is a 390x844 logical game frame, never shrunk to thumbnail
	# proportions. On smaller panes the parent ScrollContainer scrolls it.
	_canvas.custom_minimum_size = REFERENCE_SIZE
	_canvas.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
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
	_overlay = StageOverlay.new()
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.add_child(_overlay)
	_build_background_browser()
	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.text = "Изменения здесь остаются только в Raven-черновике до ручного ревью."
	add_child(_status)


func set_scene(project: Dictionary, draft: Dictionary, id: String) -> void:
	_project = project
	_selected_actor = -1
	if not bool(project.get("ok", false)):
		return
	if str(_stage_data.get("sceneId", "")) != id:
		_undo_stages.clear()
	_stage_data = Store.effective_stage(project, draft, id)
	_committed_stage = _stage_data.duplicate(true)
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
	_reload_variants()
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
	_template_button.disabled = cast.is_empty()
	_undo_button.disabled = _undo_stages.is_empty()
	_suppress = false
	_draw_stage()


func _reload_poses() -> void:
	_pose.clear()
	_emotion.clear()
	_asset_pick.clear()
	if _selected_actor < 0 or _selected_actor >= _stage_data.get("cast", []).size():
		_pose.disabled = true
		_emotion.disabled = true
		_asset_pick.disabled = true
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
	_asset_pick.disabled = false
	_asset_pick.add_item("Авто: поза и эмоция")
	_asset_pick.set_item_metadata(0, "")
	for image: Dictionary in Characters.entries_for(str(actor["characterId"])):
		_asset_pick.add_item(str(image.get("labelRu", image["variant"])))
		var index: int = _asset_pick.item_count - 1
		_asset_pick.set_item_metadata(index, image["id"])
		_asset_pick.set_item_tooltip(index, "%s · %s" % [image["pose"], image["emotion"]])
		if image["id"] == actor.get("assetId", ""):
			_asset_pick.select(index)


func _draw_stage() -> void:
	for card in _cards:
		_canvas.remove_child(card)
		card.queue_free()
	_cards.clear()
	_draw_actor_thumbnails()
	var bg_id: String = str(_stage_data.get("backgroundId", ""))
	var light: String = str(_stage_data.get("lighting", ""))
	var state: String = str(_stage_data.get("roomState", ""))
	# The catalog is the only authority for actual VN images. Never substitute
	# another lighting/state (or the legacy Hall pilot) when the exact plate is absent.
	_bg_image.texture = VNBackgrounds.texture_for(bg_id, light, state)
	var available: bool = _bg_image.texture != null
	_placeholders.text = "ФОН: ART CANDIDATE" if available else "ФОН: ART PENDING · %s / %s / %s" % [bg_id, light, state]
	_bg_image.size = _canvas.size
	_placeholders.size = Vector2(_canvas.size.x, 28)
	var cast: Array = _stage_data.get("cast", [])
	var missing_expressions: int = 0
	for index in range(cast.size()):
		var actor: Dictionary = cast[index]
		var card := Button.new()
		card.custom_minimum_size = _card_size
		card.size = _card_size
		card.clip_contents = true
		card.flat = true
		card.tooltip_text = "%s · %s · перетащить на сцене" % [actor["characterId"], actor.get("emotion", "")]
		card.text = "ART PENDING: " + str(actor["characterId"]).trim_prefix("RM-CHAR-")
		card.alignment = HORIZONTAL_ALIGNMENT_CENTER
		card.focus_mode = Control.FOCUS_ALL
		card.gui_input.connect(_on_card_input.bind(index))
		_canvas.add_child(card)
		var resolved: Dictionary = Characters.for_actor(actor)
		var picture: Texture2D = Characters.texture_for_entry(resolved.get("entry", {}))
		if picture != null and not resolved.get("exact", false):
			missing_expressions += 1
			card.tooltip_text += " · показана нейтральная эмоция; точный вариант ещё не создан"
		if picture == null:
			card.text += "\n%s / %s" % [actor.get("pose", ""), actor.get("emotion", "")]
		if picture != null:
			# Full game-sized portrait, not a compact tool/gallery thumbnail.
			card.text = ""
			var display := TextureRect.new()
			display.texture = picture
			display.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			display.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			display.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			display.mouse_filter = Control.MOUSE_FILTER_IGNORE
			display.position = Vector2.ZERO
			display.size = _card_size
			card.add_child(display)
		_cards.append(card)
	_canvas.move_child(_overlay, _canvas.get_child_count() - 1)
	_layout_cards()
	_status.text = "%s / %s / %s · %s · %d персонажей · координаты нормализованы (%s, editor-only)." % [
		bg_id, light, state, "1080×1920 · кандидат" if available else "ART PENDING — смотрите «В каталоге»", cast.size(), _preview_orientation]
	if missing_expressions > 0:
		_status.text += " Для %d персонажей точная эмоция в этой позе ещё не создана: показан нейтральный вариант." % missing_expressions


## Thumbnails only live in the tool row and never modify the stage dimensions
## or normalized coordinates exported to the story.
func _draw_actor_thumbnails() -> void:
	if _thumbnail_strip == null:
		return
	for child in _thumbnail_strip.get_children():
		_thumbnail_strip.remove_child(child)
		child.queue_free()
	for index in range(_stage_data.get("cast", []).size()):
		var actor: Dictionary = _stage_data["cast"][index]
		var thumb := Button.new()
		thumb.custom_minimum_size = _thumbnail_size
		thumb.size = _thumbnail_size
		thumb.clip_contents = true
		thumb.tooltip_text = "Выбрать %s (%s)" % [actor["characterId"], actor.get("emotion", "")]
		thumb.text = str(actor["characterId"]).trim_prefix("RM-CHAR-")
		thumb.pressed.connect(_select_actor.bind(index))
		_thumbnail_strip.add_child(thumb)
		var picture: Texture2D = Characters.texture_for_entry(Characters.for_actor(actor).get("entry", {}))
		if picture != null:
			thumb.text = ""
			var preview := TextureRect.new()
			preview.texture = picture
			preview.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
			preview.position = Vector2.ZERO
			preview.size = _thumbnail_size
			thumb.add_child(preview)


func _select_actor(index: int) -> void:
	if index < 0 or index >= _stage_data.get("cast", []).size():
		return
	_selected_actor = index
	_actor_pick.select(index)
	_reload_poses()
	_remove.disabled = false


func _coordinates(index: int) -> Vector2:
	var actor: Dictionary = _stage_data["cast"][index]
	var fallback: float = PortraitLayout.slot_x(str(actor.get("slot", "center")))
	return Vector2(float(actor.get("x", fallback)), float(actor.get("y", 0.50)))


func _layout_cards() -> void:
	if _canvas == null or _bg_image == null or _placeholders == null:
		return
	_bg_image.size = _canvas.size
	_placeholders.size = Vector2(_canvas.size.x, 28)
	_overlay.size = _canvas.size
	_card_size = StageLayout.actor_size(_canvas.size, _cards.size()) if _preview_orientation == StageLayout.LANDSCAPE else PortraitLayout.actor_size(_canvas.size, _cards.size())
	for i in range(_cards.size()):
		_cards[i].custom_minimum_size = _card_size
		_cards[i].size = _card_size
		for inner in _cards[i].get_children():
			if inner is TextureRect:
				inner.size = _card_size
		_cards[i].position = _position_for(_coordinates(i))


func _position_for(normalized: Vector2) -> Vector2:
	if _preview_orientation == StageLayout.LANDSCAPE:
		return StageLayout.landscape_position(_canvas.size, _cards.size(), normalized)
	return PortraitLayout.position_for(_canvas.size, _cards.size(), normalized)


func _normalize_position(position: Vector2) -> Vector2:
	if _preview_orientation == StageLayout.LANDSCAPE:
		return StageLayout.landscape_normalized(_canvas.size, _cards.size(), position)
	return PortraitLayout.normalize_position(_canvas.size, _cards.size(), position)


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
		var reference: Vector2 = StageLayout.reference_size(_preview_orientation)
		_status.text = "%s · x=%d px, y=%d px (%d×%d preview)" % [
			str(_stage_data["cast"][index]["characterId"]),
			roundi(coords.x * reference.x), roundi(coords.y * reference.y), roundi(reference.x), roundi(reference.y)]


func _on_background(index: int) -> void:
	if _suppress or index < 0:
		return
	_select_background(_background.get_item_text(index))


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
	_stage_data["cast"][_selected_actor].erase("assetId")
	_commit()


func _on_emotion(index: int) -> void:
	if _suppress or _selected_actor < 0 or index < 0:
		return
	_stage_data["cast"][_selected_actor]["emotion"] = _emotion.get_item_text(index)
	_stage_data["cast"][_selected_actor].erase("assetId")
	_commit()


func _on_asset_pick(index: int) -> void:
	if _suppress or _selected_actor < 0 or index < 0:
		return
	var actor: Dictionary = _stage_data["cast"][_selected_actor]
	var asset_id: String = str(_asset_pick.get_item_metadata(index))
	if asset_id.is_empty():
		actor.erase("assetId")
	else:
		var image: Dictionary = Characters.entry_for_id(asset_id)
		if image.get("characterId") != actor.get("characterId"):
			return
		actor["assetId"] = asset_id
		actor["pose"] = image["pose"]
		actor["emotion"] = image["emotion"]
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
		_stage_data = _committed_stage.duplicate(true)
		_reload()
		return
	if _stage_data == _committed_stage:
		_reload()
		return
	_undo_stages.append(_committed_stage.duplicate(true))
	if _undo_stages.size() > 32:
		_undo_stages.remove_at(0)
	_committed_stage = _stage_data.duplicate(true)
	stage_modified.emit(_stage_data.duplicate(true))
	_reload()


func _on_undo() -> void:
	if _undo_stages.is_empty():
		return
	var previous: Dictionary = _undo_stages.pop_back()
	if not Store.validate_stage(_project, previous).is_empty():
		_undo_stages.clear()
		_status.text = "Undo остановлен: исходный проект изменился."
		return
	_stage_data = previous.duplicate(true)
	_committed_stage = previous.duplicate(true)
	stage_modified.emit(previous.duplicate(true))
	_reload()


func _on_template() -> void:
	if _stage_data.is_empty() or _stage_data.get("cast", []).is_empty():
		return
	_stage_data = StageLayout.apply_template(_stage_data, _preview_orientation)
	_commit()


func _on_orientation(index: int) -> void:
	if index < 0:
		return
	_preview_orientation = StageLayout.LANDSCAPE if index == 1 else StageLayout.PORTRAIT
	_canvas.custom_minimum_size = StageLayout.reference_size(_preview_orientation)
	_overlay.reference_size = StageLayout.reference_size(_preview_orientation)
	_overlay.queue_redraw()
	_layout_cards()


func _on_background_fit(index: int) -> void:
	_bg_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED if index == 1 else TextureRect.STRETCH_KEEP_ASPECT_COVERED


func _on_safe_toggle(value: bool) -> void:
	_overlay.show_safe = value
	_overlay.queue_redraw()

func set_dialogue_preview(next_speaker: String, text_value: String, id: String) -> void:
	_overlay.set_preview(next_speaker, text_value, id)


func _reload_variants() -> void:
	var master: Dictionary = Store.stage_master(_project, str(_stage_data.get("backgroundId", "")))
	_lighting.clear()
	_room_state.clear()
	for lighting in master.get("lightingVariants", []):
		_lighting.add_item(str(lighting))
		if lighting == _stage_data.get("lighting"):
			_lighting.select(_lighting.item_count - 1)
	for condition in master.get("stateLayers", []):
		_room_state.add_item(str(condition))
		if condition == _stage_data.get("roomState"):
			_room_state.select(_room_state.item_count - 1)


func _on_lighting(index: int) -> void:
	if _suppress or index < 0:
		return
	_stage_data["lighting"] = _lighting.get_item_text(index)
	_commit()


func _on_room_state(index: int) -> void:
	if _suppress or index < 0:
		return
	_stage_data["roomState"] = _room_state.get_item_text(index)
	_commit()


func _select_background(bg_id: String) -> void:
	var master: Dictionary = Store.stage_master(_project, bg_id)
	if master.is_empty():
		return
	_stage_data["backgroundId"] = bg_id
	var light_valid: bool = _stage_data.get("lighting") in master.get("lightingVariants", [])
	var state_valid: bool = _stage_data.get("roomState") in master.get("stateLayers", [])
	if not light_valid or not state_valid:
		# For a new master prefer an actually imported plate, not an arbitrary
		# product of the first independently declared lighting and state values.
		var candidate: Dictionary = {}
		for entry: Dictionary in VNBackgrounds.all_entries():
			if str(entry.get("backgroundId", "")) == bg_id:
				candidate = entry
				break
		if not candidate.is_empty():
			_stage_data["lighting"] = candidate["lighting"]
			_stage_data["roomState"] = candidate["roomState"]
		else:
			_stage_data["lighting"] = master.get("lightingVariants", [""])[0]
			_stage_data["roomState"] = master.get("stateLayers", [""])[0]
	_commit()


func _on_grid_toggle(value: bool) -> void:
	_overlay.show_grid = value
	_overlay.queue_redraw()


func _on_vn_toggle(value: bool) -> void:
	_overlay.show_vn = value
	_overlay.queue_redraw()


func _on_portrait_scale(value: float) -> void:
	# Only the tools change size. Actor stage scale matches the live VN.
	_thumbnail_size = CARD_SIZE * value
	_draw_actor_thumbnails()


func _build_background_browser() -> void:
	_browser = ConfirmationDialog.new()
	_browser.title = "Фоны Raven Manor: мастер и состояния"
	_browser.ok_button_text = "Выбрать фон"
	_browser.confirmed.connect(_apply_browser_background)
	add_child(_browser)
	var split := HSplitContainer.new()
	split.custom_minimum_size = Vector2(420, 300)
	_browser.add_child(split)
	_browser_list = ItemList.new()
	_browser_list.custom_minimum_size.x = 150
	_browser_list.item_selected.connect(_on_browser_selected)
	split.add_child(_browser_list)
	var details := VBoxContainer.new()
	details.custom_minimum_size.x = 245
	split.add_child(details)
	_browser_image = TextureRect.new()
	_browser_image.custom_minimum_size.y = 210
	_browser_image.size_flags_vertical = SIZE_EXPAND_FILL
	_browser_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_browser_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	details.add_child(_browser_image)
	_browser_description = Label.new()
	_browser_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.add_child(_browser_description)


## All options are derived from canonical staging declarations, never from
## filenames or guessed state combinations in a private asset directory.
## An ungenerated combination remains selectable but visibly ART PENDING.
func _catalog_browser_options() -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	for master: Dictionary in _project.get("stagingData", {}).get("masters", []):
		var bg_id: String = str(master.get("id", ""))
		for light in master.get("lightingVariants", []):
			for state in master.get("stateLayers", []):
				results.append({
					"backgroundId": bg_id,
					"lighting": str(light),
					"roomState": str(state)
				})
	return results


## An artist can discover already imported images immediately, even when
## the first story scene uses a background that has not yet been produced.
func _available_browser_options() -> Array[Dictionary]:
	var available: Array[Dictionary] = []
	for variant: Dictionary in _catalog_browser_options():
		if VNBackgrounds.texture_for(
			str(variant["backgroundId"]),
			str(variant["lighting"]),
			str(variant["roomState"])) != null:
			available.append(variant)
	return available


func _on_browse_imported() -> void:
	_open_background_browser(true)


func _on_browse() -> void:
	_open_background_browser(false)


func _open_background_browser(imported_only: bool) -> void:
	_browser_list.clear()
	_browser_variants = _available_browser_options() if imported_only else _catalog_browser_options()
	_browser_selected = {}
	_browser.title = "Загруженные VN-фоны" if imported_only else "Фоны Raven Manor: все состояния"
	if _browser_variants.is_empty():
		_browser_image.texture = null
		_browser_description.text = "В каталоге нет загруженных изображений для текущего набора master-фонов."
		_popup_background_browser()
		return
	var current_index: int = 0
	for index in range(_browser_variants.size()):
		var variant: Dictionary = _browser_variants[index]
		var entry: Dictionary = VNBackgrounds.entry_for(
			str(variant["backgroundId"]), str(variant["lighting"]), str(variant["roomState"]))
		_browser_list.add_item("%s %s · %s / %s" % [
			"✓" if not entry.is_empty() else "·",
			variant["backgroundId"], variant["lighting"], variant["roomState"]])
		if variant["backgroundId"] == _stage_data.get("backgroundId") \
				and variant["lighting"] == _stage_data.get("lighting") \
				and variant["roomState"] == _stage_data.get("roomState"):
			current_index = index
	if _browser_list.item_count > 0:
		_browser_list.select(current_index)
		_on_browser_selected(current_index)
	_popup_background_browser()


func _on_browser_selected(index: int) -> void:
	if index < 0 or index >= _browser_variants.size():
		return
	_browser_selected = _browser_variants[index].duplicate(true)
	var bg_id: String = str(_browser_selected["backgroundId"])
	var light: String = str(_browser_selected["lighting"])
	var state: String = str(_browser_selected["roomState"])
	var master: Dictionary = Store.stage_master(_project, bg_id)
	var entry: Dictionary = VNBackgrounds.entry_for(bg_id, light, state)
	_browser_image.texture = VNBackgrounds.texture_for(bg_id, light, state)
	var availability: String = "1080×1920 · ART CANDIDATE (не финальный)" if _browser_image.texture != null else "ART PENDING — этот вариант ещё не сгенерирован"
	var scenes: Array[String] = []
	for shot: Dictionary in _project.get("stagingData", {}).get("sceneShots", []):
		if shot.get("backgroundId") == bg_id and shot.get("lighting") == light and shot.get("roomState") == state:
			scenes.append(str(shot.get("sceneId", "")))
	_browser_description.text = "%s · %s / %s\n%s\n%s\nСцены: %s" % [
		bg_id, light, state, str(master.get("description", "")), availability,
		", ".join(scenes) if not scenes.is_empty() else "нет в текущем staging"]


func _apply_browser_background() -> void:
	if _browser_selected.is_empty():
		return
	# Apply the precise triple selected in the browser, preserving all actors,
	# dialogue, story IDs, campaign progression and persisted source assets.
	_stage_data["backgroundId"] = str(_browser_selected["backgroundId"])
	_stage_data["lighting"] = str(_browser_selected["lighting"])
	_stage_data["roomState"] = str(_browser_selected["roomState"])
	_commit()


func _popup_background_browser() -> void:
	# Avoid a fixed 710×475 dialog extending beyond smaller Godot windows.
	var viewport_size: Vector2 = get_viewport_rect().size
	_browser.popup_centered(Vector2i(
		maxi(300, mini(710, roundi(viewport_size.x - 40.0))),
		maxi(280, mini(475, roundi(viewport_size.y - 72.0)))))
