extends RefCounted
## UPDS-derived presentation adapter for Raven Match-3.
## Donor: UPDS-godot@3deed628 / match3_screen.gd blob 76b42df3.
## This creates only Control/layout nodes; Raven owns game/reward/save state.
const MobileLayout = preload("res://scripts/match3/match3_mobile_layout.gd")
const BACKDROP = preload("res://assets/raven/vn_backgrounds/hall/evening_dusty.webp")
const COPY := {
	"ru": {"title": "Сортировка вещей", "level": "УРОВЕНЬ", "goal": "ЦЕЛЬ", "moves": "ХОДЫ", "back": "Назад", "settings": "Настройки", "hint": "Подсказка", "help": "Как играть"},
	"be": {"title": "Сартаванне рэчаў", "level": "УЗРОВЕНЬ", "goal": "МЭТА", "moves": "ХАДЫ", "back": "Назад", "settings": "Налады", "hint": "Падказка", "help": "Як гуляць"},
	"en": {"title": "Sorting belongings", "level": "LEVEL", "goal": "GOAL", "moves": "MOVES", "back": "Back", "settings": "Settings", "hint": "Hint", "help": "How to play"}
}


static func available_board_width(frame_width: float) -> float:
	# 12px page gutters on both sides + 6px inner frame/gutter on both
	# sides; preserve the donor's responsive, phone-first board sizing.
	return maxf(1.0, frame_width - 36.0)


static func _panel(fill: Color, border: Color, border_px: int = 0, padding: int = 0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_px)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(padding)
	return style


static func _label(parent: Node, name: String, value: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.name = name
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label


static func _button(parent: Node, name: String, caption: String, action: Callable) -> Button:
	var button := Button.new()
	button.name = name
	button.text = caption
	button.custom_minimum_size = Vector2(44, MobileLayout.MIN_TAP)
	button.pressed.connect(action)
	parent.add_child(button)
	return button


static func build(host: Control, level: Dictionary, locale: String,
		on_back: Callable, on_settings: Callable) -> Dictionary:
	var copy: Dictionary = COPY.get(locale, COPY.ru)
	var surface := Control.new()
	surface.name = "UPDSMatch3FullScreen"
	host.add_child(surface)
	surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var backdrop := TextureRect.new()
	backdrop.name = "UPDSMatch3Backdrop"
	backdrop.texture = BACKDROP
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.modulate.a = 0.86
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	surface.add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var wash := ColorRect.new()
	wash.name = "UPDSMatch3BackdropWash"
	wash.color = Color("#1b1727ae")
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	surface.add_child(wash)
	wash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var page := VBoxContainer.new()
	page.name = "UPDSMatch3Layout"
	page.add_theme_constant_override("separation", 0)
	surface.add_child(page)
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Preserve the donor's 60px burgundy / coral header, title stack and
	# left/back and right/help/settings affordances.
	var header := PanelContainer.new()
	header.name = "UPDSMatch3Header"
	header.custom_minimum_size.y = 60
	var header_style := _panel(Color("#6b3855f8"), Color("#f08a72"), 0, 7)
	header_style.set_corner_radius_all(0)
	header_style.border_width_bottom = 2
	header_style.content_margin_left = 9
	header_style.content_margin_right = 9
	header.add_theme_stylebox_override("panel", header_style)
	page.add_child(header)
	var nav := HBoxContainer.new()
	nav.add_theme_constant_override("separation", 7)
	header.add_child(nav)
	var back := _button(nav, "UPDSMatch3Back", "<", on_back)
	back.tooltip_text = str(copy.back)
	back.add_theme_font_size_override("font_size", 23)
	var heading := VBoxContainer.new()
	heading.name = "UPDSMatch3TitleStack"
	heading.alignment = BoxContainer.ALIGNMENT_CENTER
	heading.add_theme_constant_override("separation", 1)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav.add_child(heading)
	var short := "%s %02d" % [str(copy.level), int(level.get("campaignIndex", 0))] if level.has("campaignIndex") else str(level.get("id", "MATCH-3"))
	_label(heading, "UPDSMatch3Level", short, 9, Color("#ffb36b"))
	_label(heading, "UPDSMatch3Title", str(copy.title), 13, Color.WHITE)
	var actions := HBoxContainer.new()
	actions.name = "UPDSMatch3HeaderActions"
	actions.add_theme_constant_override("separation", 5)
	nav.add_child(actions)
	var help_slot := HBoxContainer.new()
	help_slot.name = "UPDSHelpSlot"
	actions.add_child(help_slot)
	var settings := _button(actions, "UPDSMatch3Settings", "SET", on_settings)
	settings.tooltip_text = str(copy.settings)
	settings.add_theme_font_size_override("font_size", 12)

	var margin := MarginContainer.new()
	margin.name = "UPDSMatch3PageMargin"
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 9)
	margin.add_theme_constant_override("margin_bottom", 12)
	page.add_child(margin)
	var scroll := ScrollContainer.new()
	scroll.name = "UPDSMatch3Scroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)
	var column := VBoxContainer.new()
	column.name = "UPDSMatch3Content"
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 8)
	scroll.add_child(column)

	var hud := HBoxContainer.new()
	hud.name = "UPDSMatch3HUD"
	hud.add_theme_constant_override("separation", 7)
	column.add_child(hud)
	var goal_card := PanelContainer.new()
	goal_card.name = "UPDSGoalCard"
	goal_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	goal_card.custom_minimum_size.y = 66
	goal_card.add_theme_stylebox_override("panel", _panel(Color("#ede7d9ef"), Color("#f7ebc8"), 3, 6))
	hud.add_child(goal_card)
	var goal_slot := VBoxContainer.new()
	goal_slot.name = "UPDSGoalContent"
	goal_slot.add_theme_constant_override("separation", 2)
	goal_card.add_child(goal_slot)
	_label(goal_slot, "UPDSGoalHeading", str(copy.goal), 10, Color("#214936"))
	var stage_card := PanelContainer.new()
	stage_card.name = "UPDSMovesCard"
	stage_card.custom_minimum_size = Vector2(76, 66)
	stage_card.add_theme_stylebox_override("panel", _panel(Color("#ede7d9ef"), Color("#f7ebc8"), 3, 6))
	hud.add_child(stage_card)
	var moves_slot := VBoxContainer.new()
	moves_slot.name = "UPDSMovesContent"
	moves_slot.alignment = BoxContainer.ALIGNMENT_CENTER
	stage_card.add_child(moves_slot)
	var moves_title := _label(moves_slot, "UPDSMovesHeading", str(copy.moves), 10, Color("#214936"))
	moves_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var board_card := PanelContainer.new()
	board_card.name = "UPDSMatch3BoardFrame"
	board_card.add_theme_stylebox_override("panel", _panel(Color("#0713289e"), Color("#f7ebc8"), 3, 3))
	column.add_child(board_card)
	var board_slot := VBoxContainer.new()
	board_slot.name = "UPDSMatch3BoardSlot"
	board_slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board_card.add_child(board_slot)

	var bark_card := PanelContainer.new()
	bark_card.name = "UPDSMatch3Bark"
	bark_card.custom_minimum_size.y = 54
	bark_card.add_theme_stylebox_override("panel", _panel(Color("#ede7d9ef"), Color("#f7ebc8"), 3, 8))
	column.add_child(bark_card)
	var bark_slot := VBoxContainer.new()
	bark_slot.name = "UPDSMatch3BarkContent"
	bark_card.add_child(bark_slot)
	var fiction := _label(bark_slot, "UPDSMatch3Fiction", str(level.get("fiction", "")), 11, Color("#29243d"))
	fiction.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var feedback_slot := VBoxContainer.new()
	feedback_slot.name = "UPDSMatch3Feedback"
	bark_slot.add_child(feedback_slot)

	var booster_slot := VBoxContainer.new()
	booster_slot.name = "UPDSMatch3Boosters"
	booster_slot.add_theme_constant_override("separation", 4)
	column.add_child(booster_slot)

	var hint_slot := VBoxContainer.new()
	hint_slot.name = "UPDSMatch3Hint"
	column.add_child(hint_slot)
	var motion_slot := VBoxContainer.new()
	motion_slot.name = "UPDSMatch3Motion"
	column.add_child(motion_slot)
	var retry_slot := VBoxContainer.new()
	retry_slot.name = "UPDSMatch3Retry"
	column.add_child(retry_slot)
	return {
		"surface": surface, "board_slot": board_slot, "goal_slot": goal_slot,
		"moves_slot": moves_slot, "feedback_slot": feedback_slot,
		"booster_slot": booster_slot, "hint_slot": hint_slot,
		"motion_slot": motion_slot, "retry_slot": retry_slot,
		"help_slot": help_slot, "copy": copy
	}


static func adopt_board(board: Variant, slots: Dictionary, host: Control) -> void:
	# Reparent the existing view controls rather than reimplementing hint,
	# feedback, Help, retry or any UPDS game/session logic.
	board.objective.reparent(slots.goal_slot)
	board.objective.add_theme_color_override("font_color", Color("#214936"))
	board.objective.add_theme_font_size_override("font_size", 12)
	board.moves_label = _label(slots.moves_slot, "UPDSMovesValue", "", 24, Color("#214936"))
	board.moves_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	board.separate_hud = true
	board.feedback.reparent(slots.feedback_slot)
	board.feedback.add_theme_color_override("font_color", Color("#214936"))
	board.help_button.reparent(slots.help_slot)
	board.help_button.tooltip_text = str(slots.copy.help)
	board.help_button.text = "?"
	board.help_button.custom_minimum_size = Vector2(44, MobileLayout.MIN_TAP)
	board.help_button.add_theme_font_size_override("font_size", 20)
	board.hint_button.reparent(slots.hint_slot)
	board.hint_button.tooltip_text = board.hint_button.text
	board.hint_button.text = str(slots.copy.hint)
	board.motion_button.reparent(slots.motion_slot)
	board.retry_button.reparent(slots.retry_slot)
	var surface := board.board_area.get_node_or_null("RavenBoardSurface") as TextureRect
	if surface != null:
		surface.modulate.a = 0.14
	board._paint_live()
	board.apply_available_width(available_board_width(host.size.x))
	host.resized.connect(func() -> void:
		if is_instance_valid(board) and board.is_inside_tree():
			board.apply_available_width(available_board_width(host.size.x))
	)
