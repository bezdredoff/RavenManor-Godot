extends Control
## Shared save-neutral visual-novel compositor used by active Raven gameplay.
## Scenes, lighting/state and character slots come from the same staging as VN Studio.
const Backgrounds = preload("res://scripts/raven/raven_vn_backgrounds.gd")
const Staging = preload("res://data/raven/production/vn_staging.json")
const EVELYN = preload("res://assets/raven/vn_pilot/evelyn_relaxed.webp")
const ADA = preload("res://assets/raven/vn_pilot/ada_offer_tea.webp")

var scene_id := ""
var background: TextureRect
var missing_background: Label
var actor_layer: Control
var actors: Array[Dictionary] = []
var dialogue_panel: Panel
var chapter: Label
var nameplate: Label
var dialogue: Label
var progress: Label
var next_button: Button
var pilot_note: Label
var _advance_callback: Callable


func _init() -> void:
	custom_minimum_size = Vector2(0, 610)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	clip_contents = true


func _ready() -> void:
	_build()
	resized.connect(_layout)
	_layout()


func _build() -> void:
	var dark := ColorRect.new()
	dark.name = "PendingArtBackground"
	dark.color = Color("25202a")
	dark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dark)

	background = TextureRect.new()
	background.name = "GameVNBackground"
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var shade := ColorRect.new()
	shade.name = "VNReadabilityShade"
	shade.color = Color(0.08, 0.07, 0.12, 0.10)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	actor_layer = Control.new()
	actor_layer.name = "VNActors"
	actor_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(actor_layer)

	missing_background = Label.new()
	missing_background.name = "PendingVNArt"
	missing_background.add_theme_color_override("font_color", Color("ecd9bb"))
	missing_background.add_theme_font_size_override("font_size", 14)
	missing_background.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	missing_background.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	missing_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(missing_background)

	var heading := ColorRect.new()
	heading.name = "VNHeadingBar"
	heading.color = Color(0.12, 0.08, 0.12, 0.77)
	heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(heading)
	chapter = _label(15, Color("f8e6bd"))
	chapter.name = "VNSceneTitle"
	chapter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chapter.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(chapter)

	dialogue_panel = Panel.new()
	dialogue_panel.name = "VNDialoguePanel"
	var style := StyleBoxFlat.new()
	style.bg_color = Color("f3e5ceee")
	style.border_color = Color("b58a56")
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	dialogue_panel.add_theme_stylebox_override("panel", style)
	add_child(dialogue_panel)

	nameplate = _label(17, Color("eedab3"))
	nameplate.name = "VNSpeaker"
	nameplate.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nameplate.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var name_style := StyleBoxFlat.new()
	name_style.bg_color = Color("33262d")
	name_style.set_corner_radius_all(7)
	nameplate.add_theme_stylebox_override("normal", name_style)
	dialogue_panel.add_child(nameplate)

	dialogue = _label(17, Color("34252c"))
	dialogue.name = "VNDialogue"
	dialogue.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dialogue_panel.add_child(dialogue)

	progress = _label(12, Color("665044"))
	progress.name = "VNLineProgress"
	dialogue_panel.add_child(progress)

	next_button = Button.new()
	next_button.name = "VNNext"
	next_button.text = "Далее ›"
	next_button.custom_minimum_size = Vector2(100, 40)
	next_button.pressed.connect(_next)
	dialogue_panel.add_child(next_button)

	pilot_note = _label(11, Color("f7e7cb"))
	pilot_note.name = "VNArtStatus"
	pilot_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pilot_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(pilot_note)


func show_beat(beat_id: String, speaker: String, line_text: String, line_progress: String, on_next: Callable) -> void:
	scene_id = beat_id
	_advance_callback = on_next
	chapter.text = beat_id
	nameplate.text = speaker.to_upper()
	dialogue.text = line_text
	progress.text = line_progress
	var texture: Texture2D = Backgrounds.texture_for_scene(beat_id)
	background.texture = texture
	background.visible = texture != null
	missing_background.visible = texture == null
	var entry: Dictionary = Backgrounds.entry_for_scene(beat_id)
	missing_background.text = "ART PENDING · %s" % str(entry.get("id", beat_id))
	_fill_actors(beat_id)
	pilot_note.text = "ПЕРСОНАЖИ: ВРЕМЕННЫЙ АРТ" if not actors.is_empty() else ""
	_layout()


func _fill_actors(beat_id: String) -> void:
	for child in actor_layer.get_children():
		actor_layer.remove_child(child)
		child.queue_free()
	actors.clear()
	var shot: Dictionary = {}
	for candidate: Dictionary in Staging.data.get("sceneShots", []):
		if str(candidate.get("sceneId", "")) == beat_id:
			shot = candidate
			break
	for cast: Dictionary in shot.get("cast", []):
		var character_id := str(cast.get("characterId", ""))
		var slot := str(cast.get("slot", "center"))
		var art: Texture2D = null
		if character_id == "RM-CHAR-EVELYN":
			art = EVELYN
		elif character_id == "RM-CHAR-ADA":
			art = ADA
		var visual: Control
		if art != null:
			var sprite := TextureRect.new()
			sprite.texture = art
			sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			visual = sprite
		else:
			var marker := _label(12, Color("f3daba"))
			marker.text = "%s\nART PENDING" % character_id.trim_prefix("RM-CHAR-")
			marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			marker.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			visual = marker
		visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
		actor_layer.add_child(visual)
		actors.append({"node": visual, "slot": slot, "pilot": art != null})


func _layout() -> void:
	if background == null:
		return
	var w := maxf(1.0, size.x)
	var h := maxf(1.0, size.y)
	(get_node("PendingArtBackground") as ColorRect).size = Vector2(w, h)
	background.size = Vector2(w, h)
	(get_node("VNReadabilityShade") as ColorRect).size = Vector2(w, h)
	actor_layer.size = Vector2(w, h)
	var multi: bool = actors.size() > 2
	var actor_w := w * (0.60 if multi else 0.77)
	var actor_h := h * 0.73
	for item: Dictionary in actors:
		var visual := item["node"] as Control
		var slot := str(item["slot"])
		if bool(item["pilot"]):
			visual.size = Vector2(actor_w, actor_h)
			var left: float = -0.20 if not multi else -0.10
			var center: float = 0.115 if not multi else 0.20
			var right: float = 0.41 if not multi else 0.52
			visual.position = Vector2(w * (left if slot == "left" else right if slot == "right" else center), h * 0.14)
		else:
			visual.size = Vector2(w * 0.29, 58)
			visual.position = Vector2(w * (0.02 if slot == "left" else 0.68 if slot == "right" else 0.35), h * 0.48)
	missing_background.position = Vector2(w * 0.05, h * 0.28)
	missing_background.size = Vector2(w * 0.90, 70)
	var heading := get_node("VNHeadingBar") as ColorRect
	heading.position = Vector2.ZERO
	heading.size = Vector2(w, 40)
	chapter.position = Vector2(8, 0)
	chapter.size = Vector2(w - 16, 40)

	var margin := maxf(8.0, w * 0.032)
	var box_h := maxf(225.0, minf(h * 0.37, 295.0))
	dialogue_panel.position = Vector2(margin, h - box_h - 28)
	dialogue_panel.size = Vector2(w - 2.0 * margin, box_h)
	nameplate.position = Vector2(14, -20)
	nameplate.size = Vector2(minf(170, w * 0.50), 38)
	dialogue.position = Vector2(14, 30)
	dialogue.size = Vector2(maxf(1, dialogue_panel.size.x - 28), box_h - 105)
	progress.position = Vector2(14, box_h - 35)
	progress.size = Vector2(135, 25)
	next_button.position = Vector2(maxf(0, dialogue_panel.size.x - 115), box_h - 51)
	next_button.size = Vector2(105, 43)
	pilot_note.position = Vector2(6, h - 22)
	pilot_note.size = Vector2(w - 12, 20)


func _next() -> void:
	if _advance_callback.is_valid():
		_advance_callback.call()


func _label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
