extends SceneTree
## Independent optional-campaign model/UI characterization (no save or game-core writes).
const Campaign = preload("res://scripts/raven/raven_optional_campaign_controller.gd")
const Content = preload("res://data/raven/rm_vs_01_content.json")

var started: Array[String] = []
var left := 0


func _initialize() -> void:
	call_deferred("_run")


func _on_start(level_id: String) -> void:
	started.append(level_id)


func _on_leave() -> void:
	left += 1


func _buttons(container: VBoxContainer) -> Array[Button]:
	var found: Array[Button] = []
	for child in container.get_children():
		if child is Button:
			found.append(child)
	return found


func _render(completed: Array, locale: String = "ru", from_menu: bool = false) -> VBoxContainer:
	var body := VBoxContainer.new()
	root.add_child(body)
	Campaign.render_list(body, Content.data.levels, completed, locale, from_menu,
		_on_start, _on_leave)
	return body


func _run() -> void:
	assert(Campaign.campaign_step().kind == "campaign")
	assert(Campaign.campaign_step().id == "optional-campaign")
	# The integration consumer is vertical_slice.gd; the controller is the
	# single source of locale text for the status header and metadata title.
	assert(Campaign.status_text("ru") == Campaign.STATUS_COPY)
	assert(Campaign.status_text("be") == "Дадатковыя ўзроўні · ачкі за падрыхтоўку не налічваюцца")
	assert(Campaign.status_text("en") == "Bonus levels · no preparation points awarded")
	assert(Campaign.status_text("de") == Campaign.STATUS_COPY, "Unknown locale must fall back to Russian")
	assert(Campaign.campaign_step("ru").title == "Подготовка имущества")
	assert(Campaign.campaign_step("be").title == "Падрыхтоўка маёмасці")
	assert(Campaign.campaign_step("en").title == "Preparing the estate")
	assert(Campaign.campaign_step("de").title == Campaign.campaign_step("ru").title)
	var level: Dictionary = Content.data.levels[3]
	assert(Campaign.level_step(level).id == "optional-RM-LVL-101")
	var completed: Array = []
	var clean: Array[Dictionary] = Campaign.entries(Content.data.levels, completed)
	assert(clean.size() == 22, "Exactly 22 authored optional levels in current catalogue")
	assert(clean.front().levelId == "RM-LVL-101" and clean.back().levelId == "RM-LVL-122")
	assert(clean[0].unlocked and clean[0].isNext and not clean[0].completed)
	assert(not clean[1].unlocked and not clean[1].isNext)
	assert(completed.is_empty(), "Entry model must not mutate campaign state")
	var first := _render(completed)
	var buttons: Array[Button] = _buttons(first)
	assert(buttons.size() == 23, "22 optional levels plus return action")
	assert(buttons[0].text == "ДАЛЕЕ · Уровень 01 · Играть" and not buttons[0].disabled)
	assert(buttons[1].text == "Закрыто · Играть" and buttons[1].disabled)
	assert(buttons[22].text == "Вернуться к истории")
	buttons[0].pressed.emit()
	assert(started == ["RM-LVL-101"], "Level callback must preserve authored level ID")
	buttons[22].pressed.emit()
	assert(left == 1, "Back callback not delivered")
	first.queue_free()
	await process_frame

	var progress := ["RM-LVL-101", "RM-LVL-102"]
	var partially_complete: Array[Dictionary] = Campaign.entries(Content.data.levels, progress)
	assert(partially_complete[0].completed and partially_complete[0].unlocked)
	assert(partially_complete[2].unlocked and partially_complete[2].isNext)
	assert(not partially_complete[3].unlocked)
	assert(progress == ["RM-LVL-101", "RM-LVL-102"], "Status model mutated firstClearLevels")
	var menu := _render(progress, "be", true)
	var menu_buttons := _buttons(menu)
	assert(menu_buttons[0].text == "✓ Узровень 01 · Паўтарыць" and not menu_buttons[0].disabled)
	assert(menu_buttons[2].text == "ДАЛЕЙ · Узровень 03 · Гуляць" and not menu_buttons[2].disabled)
	assert(menu_buttons[3].text == "Заблакавана · Гуляць" and menu_buttons[3].disabled)
	assert(menu_buttons[22].text == "У галоўнае меню")
	assert((menu.get_child(0) as Label).text == str(Campaign.UI_COPY.be.intro))
	assert((menu.get_child(0) as Label).autowrap_mode == TextServer.AUTOWRAP_WORD_SMART)
	for button in menu_buttons:
		assert(button.custom_minimum_size.y >= 44.0, "Localized controls retain minimum touch height")
	menu.queue_free()
	await process_frame

	var all_done: Array = []
	for entry in clean:
		all_done.append(str(entry.levelId))
	var finished: Array[Dictionary] = Campaign.entries(Content.data.levels, all_done)
	assert(finished.size() == 22)
	for entry in finished:
		assert(entry.completed and entry.unlocked and not entry.isNext)
	var english := _render(all_done, "en", true)
	var english_buttons := _buttons(english)
	assert(english_buttons[22].text == "To Main Menu")
	assert((english.get_child(0) as Label).text == str(Campaign.UI_COPY.en.intro))
	assert(english_buttons[0].text == "✓ Level 01 · Replay", "English complete labels must be translated")
	for index in range(22):
		assert(not english_buttons[index].text.begins_with("NEXT"), "Completed campaign must not advertise next")
		assert(english_buttons[index].text.begins_with("✓ Level "), "Every English completed entry must be translated")
	english.queue_free()
	await process_frame
	var english_progress := _render(progress, "en")
	var english_progress_buttons := _buttons(english_progress)
	assert(english_progress_buttons[0].text == "✓ Level 01 · Replay")
	assert(english_progress_buttons[2].text == "NEXT · Level 03 · Play")
	assert(english_progress_buttons[3].text == "Locked · Play" and english_progress_buttons[3].disabled)
	assert(english_progress_buttons[22].text == "Return to story")
	english_progress.queue_free()
	await process_frame
	var fallback := _render([], "de", true)
	var fallback_buttons := _buttons(fallback)
	assert(fallback_buttons[0].text == "ДАЛЕЕ · Уровень 01 · Играть")
	assert(fallback_buttons[22].text == "В главное меню")
	assert((fallback.get_child(0) as Label).text == Campaign.INTRO_COPY)
	fallback.queue_free()
	print("Raven optional Match-3 campaign controller smoke passed")
	quit()
