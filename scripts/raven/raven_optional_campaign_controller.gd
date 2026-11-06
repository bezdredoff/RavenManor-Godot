extends RefCounted
## Optional Match-3 campaign presentation and unlock model.
## This module is deliberately read-only with respect to campaign state: only
## RavenReducer/RavenCampaignStore may award levels, boosters or save progress.
const MobileLayout = preload("res://scripts/match3/match3_mobile_layout.gd")
const RETURN_COPY := {"ru": "В главное меню", "be": "У галоўнае меню", "en": "To Main Menu"}
const STATUS_COPY := "Дополнительные уровни · награда за подготовку не начисляется"
const INTRO_COPY := "Match-3 помогает осмотреть и подготовить вещи. Ремонт выполняет специалист."
# Mirror the locale-keyed presentation map of UPDS Match3CampaignScreen.
# The game/save/level state is intentionally not owned by these strings.
const UI_COPY := {
	"ru": {"intro": INTRO_COPY, "next": "ДАЛЕЕ · ", "level": "Уровень %02d",
		"locked": "Закрыто", "play": "Играть", "replay": "Повторить", "return_story": "Вернуться к истории"},
	"be": {"intro": "Match-3 дапамагае агледзець і падрыхтаваць рэчы. Рамонт выконвае спецыяліст.",
		"next": "ДАЛЕЙ · ", "level": "Узровень %02d", "locked": "Заблакавана",
		"play": "Гуляць", "replay": "Паўтарыць", "return_story": "Вярнуцца да гісторыі"},
	"en": {"intro": "Match-3 helps inspect and prepare belongings. A specialist handles repairs.",
		"next": "NEXT · ", "level": "Level %02d", "locked": "Locked",
		"play": "Play", "replay": "Replay", "return_story": "Return to story"}
}


static func campaign_step() -> Dictionary:
	return {"id": "optional-campaign", "kind": "campaign", "title": "Подготовка имущества"}


static func level_step(level: Dictionary) -> Dictionary:
	return {"id": "optional-" + str(level.id), "kind": "match3",
		"level": str(level.id), "title": str(level.title)}


static func entries(levels: Array, completed: Array) -> Array[Dictionary]:
	# campaignIndex is authored content, unlike the three story levels.
	# Sorting instead of assuming RM-LVL-101..122 keeps this system independent
	# of future catalogue size while preserving today's ordering.
	var catalog: Array[Dictionary] = []
	for level in levels:
		if level is Dictionary and level.has("campaignIndex"):
			catalog.append({"levelId": str(level.id), "index": int(level.campaignIndex)})
	catalog.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.index) < int(b.index))
	var next_id := ""
	for entry in catalog:
		if not completed.has(entry.levelId):
			next_id = str(entry.levelId)
			break
	for position in catalog.size():
		var entry: Dictionary = catalog[position]
		entry["completed"] = completed.has(entry.levelId)
		entry["unlocked"] = position == 0 or completed.has(catalog[position - 1].levelId)
		entry["isNext"] = str(entry.levelId) == next_id
	return catalog


static func render_list(body: VBoxContainer, levels: Array, completed: Array,
		locale: String, from_main_menu: bool, on_level: Callable, on_leave: Callable) -> void:
	var copy: Dictionary = UI_COPY.get(locale, UI_COPY.ru)
	var intro := Label.new()
	intro.text = str(copy.intro)
	intro.add_theme_font_size_override("font_size", 14)
	intro.add_theme_color_override("font_color", Color("d4ccbe"))
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.custom_minimum_size = Vector2(0, 54)
	body.add_child(intro)
	var campaign: Array[Dictionary] = entries(levels, completed)
	for position in campaign.size():
		var entry: Dictionary = campaign[position]
		var completed_level := bool(entry.completed)
		var unlocked := bool(entry.unlocked)
		var prefix := str(copy.next) if bool(entry.isNext) else ""
		var level_caption := str(copy.level) % (position + 1)
		var title := "✓ " + level_caption if completed_level else (level_caption if unlocked else str(copy.locked))
		var action := str(copy.replay) if completed_level else str(copy.play)
		var button := _button(body, "%s%s · %s" % [prefix, title, action],
			on_level.bind(str(entry.levelId)))
		button.disabled = not unlocked
	_button(body, str(RETURN_COPY.get(locale, RETURN_COPY.ru)) if from_main_menu else str(copy.return_story), on_leave)


static func _button(parent: Container, label: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(0, MobileLayout.MIN_TAP)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(callback)
	parent.add_child(button)
	return button
