extends Window
## Replayable, spoiler-safe first-session guide. It describes player-facing rules, not story outcomes.
signal closed

const COPY := {
	"ru": {
		"title": "Как играть",
		"intro": "Короткая памятка. Её можно открыть снова из меню в любой момент.",
		"sections": [
			["Исследуйте дом", "Выбирайте доступные двери и заметные точки интереса. Эвелин проходит к ним по проложенному маршруту. Если путь или дверь пока закрыты, осмотрите другие доступные места."],
			["Готовьте работу", "Задачи «три в ряд» обозначают подготовку: разобрать вещи, расчистить место или найти нужные материалы. Награда за подготовку не заменяет ремонт."],
			["Зовите специалиста", "Технические работы выполняет подходящий специалист. Сначала подготовьте место и соберите нужные сведения; затем следуйте подсказке истории к доступному специалисту."],
			["Играйте в «три в ряд»", "Меняйте местами соседние фишки, чтобы собрать три или больше одинаковых и выполнить цели до конца ходов. Подсказка показывает допустимый ход и не тратит ход; кнопка «Как играть» объясняет особые фишки и блокеры."],
			["Сохраняйте прогресс", "Используйте «Сохранить» перед выходом. В главном меню выберите «Продолжить», чтобы вернуться к сохранённому состоянию. Если сохранение не удалось, игра покажет сообщение и не подтвердит выход."]
		],
		"close": "Понятно",
	},
	"be": {
		"title": "Як гуляць",
		"intro": "Кароткая памятка. Яе можна зноў адкрыць з меню ў любы час.",
		"sections": [
			["Даследуйце дом", "Выбірайце даступныя дзверы і прыкметныя кропкі цікавасці. Эвелін ідзе да іх па пракладзеным маршруце. Калі шлях або дзверы пакуль закрытыя, агледзьце іншыя даступныя месцы."],
			["Падрыхтуйце працу", "Задачы «тры ў рад» азначаюць падрыхтоўку: разабраць рэчы, расчысціць месца або знайсці патрэбныя матэрыялы. Узнагарода за падрыхтоўку не замяняе рамонт."],
			["Звярніцеся да спецыяліста", "Тэхнічную працу выконвае адпаведны спецыяліст. Спачатку падрыхтуйце месца і збярыце патрэбныя звесткі; затым ідзіце за падказкай гісторыі да даступнага спецыяліста."],
			["Гуляйце ў «тры ў рад»", "Мяняйце месцамі суседнія фішкі, каб сабраць тры ці больш аднолькавых і выканаць мэты да канца хадоў. Падказка паказвае дазволены ход і не траціць ход; кнопка «Як гуляць» тлумачыць спецыяльныя фішкі і перашкоды."],
			["Захоўвайце прагрэс", "Націсніце «Захаваць» перад выхадам. У галоўным меню выберыце «Працягнуць», каб вярнуцца да захаванага стану. Калі захаванне не ўдалося, гульня пакажа паведамленне і не пацвердзіць выхад."]
		],
		"close": "Зразумела",
	},
	"en": {
		"title": "How to Play",
		"intro": "A short guide. Reopen it from the menu whenever you need it.",
		"sections": [
			["Explore the manor", "Choose an available door or point of interest. Evelyn follows an authored route to it. If a route or door is still closed, inspect another available place."],
			["Prepare the work", "Match-3 tasks stand for preparation: sort belongings, clear a space, or find needed materials. Preparation rewards do not perform repairs."],
			["Call a specialist", "A suitable specialist performs technical work. Prepare the area and gather the needed clues first, then follow the story prompt to an available specialist."],
			["Play Match-3", "Swap neighboring tiles to match three or more and complete the objectives before you run out of moves. Hint shows a legal move without spending a turn; the in-game Help explains special tiles and blockers."],
			["Save your progress", "Choose Save before leaving. Select Continue from the main menu to return to your saved state. If saving fails, the game reports it and does not confirm the exit."]
		],
		"close": "Got it",
	}
}

var _locale := "ru"
var _content: VBoxContainer
var _close: Button


func setup(locale: String) -> void:
	_locale = locale if COPY.has(locale) else "ru"
	title = str(COPY[_locale].title)
	min_size = Vector2i(280, 360)
	size = Vector2i(360, 560)
	exclusive = true
	close_requested.connect(_close_guide)
	var root := VBoxContainer.new()
	root.name = "RavenOnboardingRoot"
	root.add_theme_constant_override("separation", 8)
	add_child(root)
	var scroll := ScrollContainer.new()
	scroll.name = "RavenOnboardingScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	_content = VBoxContainer.new()
	_content.name = "RavenOnboardingSections"
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 12)
	scroll.add_child(_content)
	var intro := Label.new()
	intro.name = "RavenOnboardingIntro"
	intro.text = str(COPY[_locale].intro)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_content.add_child(intro)
	for index in COPY[_locale].sections.size():
		var section: Array = COPY[_locale].sections[index]
		var heading := Label.new()
		heading.name = "RavenOnboardingTopic%d" % index
		heading.text = str(section[0])
		heading.add_theme_font_size_override("font_size", 18)
		_content.add_child(heading)
		var body := Label.new()
		body.name = "RavenOnboardingBody%d" % index
		body.text = str(section[1])
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_content.add_child(body)
	_close = Button.new()
	_close.name = "RavenOnboardingClose"
	_close.text = str(COPY[_locale].close)
	_close.custom_minimum_size.y = 44
	_close.pressed.connect(_close_guide)
	root.add_child(_close)
	hide()


func open_centered() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var target := Vector2i(mini(360, maxi(280, int(viewport_size.x) - 24)), mini(560, maxi(360, int(viewport_size.y) - 24)))
	size = target
	popup_centered(target)


func _close_guide() -> void:
	if visible:
		hide()
		closed.emit()


func set_locale(locale: String) -> void:
	_locale = locale if COPY.has(locale) else "ru"
	title = str(COPY[_locale].title)
	var intro := find_child("RavenOnboardingIntro", true, false) as Label
	if intro != null:
		intro.text = str(COPY[_locale].intro)
	for index in COPY[_locale].sections.size():
		var section: Array = COPY[_locale].sections[index]
		var heading := find_child("RavenOnboardingTopic%d" % index, true, false) as Label
		var body := find_child("RavenOnboardingBody%d" % index, true, false) as Label
		if heading != null: heading.text = str(section[0])
		if body != null: body.text = str(section[1])
	if is_instance_valid(_close):
		_close.text = str(COPY[_locale].close)

