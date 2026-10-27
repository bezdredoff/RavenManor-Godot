extends RefCounted
## Raven-only Match-3 visual skin for the UPDS-origin board presenter.
## No gameplay rules, school story IDs, UPDS session or campaign state here.

const COLORS := {"raven": Color("40506b"), "key": Color("b8954d"), "rose": Color("884f62"), "candle": Color("d5c38b"), "book": Color("5d704d"), "cup": Color("e8dcc8"), "brooch": Color("a883bc"), "quill": Color("bc9b73")}
const MARKS := {"raven":"R", "key":"K", "rose":"✦", "candle":"C", "book":"B", "cup":"☕", "brooch":"◆", "quill":"Q"}

static func placeholder() -> Dictionary:
	return {
		"colors": COLORS.duplicate(true),
		"marks": MARKS.duplicate(true),
		"moves": "Ходы:",
		"hint": "Показать возможный ход",
		"hint_message": "Подсвечен возможный ход",
		"no_hint": "Нет доступных ходов",
		"invalid": "Неверный ход — попробуйте другую комбинацию",
		"matched": "Комбинация!",
		"chain": "Цепочка",
		"won": "Подготовка завершена",
		"lost": "Ходы закончились — попробовать снова"
	}
