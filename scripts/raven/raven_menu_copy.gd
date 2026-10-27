extends RefCounted
## Raven reskin for the UPDS PlayerPreferences interface.
const DEFAULT_LOCALE := "ru"
const FALLBACK_LOCALE := "ru"
const COPY := {
	"ru": {"language": "Язык", "next": "Далее", "back": "Назад", "settings": "Настройки", "music": "Музыка", "effects": "Эффекты", "muted": "Без звука", "haptics": "Вибрация"},
	"be": {"language": "Мова", "next": "Далей", "back": "Назад", "settings": "Налады", "music": "Музыка", "effects": "Эфекты", "muted": "Без гуку", "haptics": "Вібрацыя"},
	"en": {"language": "Language", "next": "Next", "back": "Back", "settings": "Settings", "music": "Music", "effects": "Effects", "muted": "Mute", "haptics": "Haptics"}
}

static func default_locale() -> String:
	return DEFAULT_LOCALE

static func text(key: String, locale: String = DEFAULT_LOCALE) -> String:
	var lang: String = locale if COPY.has(locale) else FALLBACK_LOCALE
	return str(COPY[lang].get(key, COPY[FALLBACK_LOCALE].get(key, key)))
