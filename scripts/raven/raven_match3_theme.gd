extends RefCounted
## Raven-only temporary skin and help copy over the original UPDS match rules.
## Five special kinds come from UPDS Match3Game, not new Raven gameplay.
const COLORS := {"raven": Color("40506b"), "key": Color("b8954d"), "rose": Color("884f62"), "candle": Color("d5c38b"), "book": Color("5d704d"), "cup": Color("e8dcc8"), "brooch": Color("a883bc"), "quill": Color("bc9b73")}
const MARKS := {"raven":"R", "key":"K", "rose":"✦", "candle":"C", "book":"B", "cup":"☕", "brooch":"◆", "quill":"Q"}
const TILE_NAMES := {"raven":"Ворон", "key":"Ключ", "rose":"Роза", "candle":"Свеча", "book":"Книга", "cup":"Чашка", "brooch":"Брошь", "quill":"Перо"}
const SPECIAL_BADGES := {"flash-row":"↔", "flash-column":"↕", "evidence":"✹", "lead":"✚", "insight":"★"}
const SPECIAL_NAMES := {"flash-row":"линия по горизонтали", "flash-column":"линия по вертикали", "evidence":"область вокруг", "lead":"крест и полезный предмет", "insight":"фишки одного типа"}

static func placeholder() -> Dictionary:
	return {
		"colors": COLORS.duplicate(true),
		"marks": MARKS.duplicate(true),
		"tile_names": TILE_NAMES.duplicate(true),
		"special_badges": SPECIAL_BADGES.duplicate(true),
		"special_names": SPECIAL_NAMES.duplicate(true),
		"moves": "Ходы:",
		"hint": "Показать возможный ход",
		"hint_message": "Подсвечен возможный ход",
		"no_hint": "Нет доступных ходов",
		"invalid": "Неверный ход — попробуйте другую комбинацию",
		"matched": "Комбинация!",
		"chain": "Цепочка",
		"special_impact": "Особая комбинация!",
		"reshuffle": "Поле перемешано",
		"won": "Подготовка завершена",
		"lost": "Ходы закончились — уровень не завершён",
		"retry": "Попробовать снова",
		"retry_message": "Новая попытка — прогресс комнаты не изменён",
		"help_button": "Как играть",
		"help_title": "Сортировка вещей",
		"help_intro": "Соединяйте три и более одинаковых предмета свайпом или двумя нажатиями на соседние фишки. Подсказка только показывает ход.",
		"help_blockers": "Блокеры: тёмная клетка с числом слоёв. Разбивайте соседними комбинациями. Сквозь заблокированную клетку нельзя поменять фишки.",
		"help_specials": "Спецфишки: ↔ — горизонтальная линия, ↕ — вертикальная линия, ✹ — область, ✚ — крест и целевой предмет, ★ — все предметы одного типа. Нажмите спецфишку дважды или обменяйте с соседней.",
		"help_goal": "Цели и оставшиеся ходы показаны над полем. При поражении можно начать новую попытку без потери очков реставрации.",
		"help_close": "Закрыть",
		"motion_on": "Анимация: вкл.",
		"motion_off": "Анимация: выкл.",
		"invalid_blocked": "Клетка заблокирована: сначала уберите препятствие",
		"invalid_adjacent": "Переставлять можно только соседние фишки"
	}
