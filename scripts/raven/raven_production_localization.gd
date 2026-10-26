extends RefCounted
## Independent production-localization adapter; NOT yet wired into playable RM-VS-01.
## Mirrors UPDS language persistence & line-key lookup without importing UPDS story.
signal locale_changed(locale: String)

const DialogueData = preload("res://data/raven/production/season1_dialogue_catalog.json")
const PopupData = preload("res://data/raven/production/hotspot_popup_copy.json")
const SUPPORTED_LOCALES := ["ru", "be", "en"]
const DEFAULT_LOCALE := "ru"
const FALLBACK_LOCALE := "ru"
const SETTINGS_PATH := "user://raven_language.cfg"
const SPEAKERS := {
	"RM-CHAR-EVELYN": {"ru": "Эвелин", "be": "Эвелін", "en": "Evelyn"},
	"RM-CHAR-ADA": {"ru": "Ада", "be": "Ада", "en": "Ada"},
	"RM-CHAR-LUCAS": {"ru": "Лукас", "be": "Лукас", "en": "Lucas"},
	"RM-CHAR-ROWAN": {"ru": "Роуэн", "be": "Роўэн", "en": "Rowan"},
	"RM-CHAR-UNKNOWN-VOICE": {"ru": "Неизвестный голос", "be": "Невядомы голас", "en": "Unknown voice"}
}

var locale := DEFAULT_LOCALE
var settings_path: String


func _init(path: String = SETTINGS_PATH) -> void:
	settings_path = path
	var cfg := ConfigFile.new()
	if cfg.load(settings_path) == OK:
		var selected: String = str(cfg.get_value("interface", "locale", DEFAULT_LOCALE))
		if SUPPORTED_LOCALES.has(selected):
			locale = selected


func set_locale(next_locale: String) -> Error:
	if not SUPPORTED_LOCALES.has(next_locale):
		return ERR_INVALID_PARAMETER
	if locale == next_locale:
		return OK
	var cfg := ConfigFile.new()
	cfg.set_value("interface", "locale", next_locale)
	var result := cfg.save(settings_path)
	if result == OK:
		locale = next_locale
		locale_changed.emit(locale)
	return result


static func normalize_locale(candidate: String) -> String:
	return candidate if SUPPORTED_LOCALES.has(candidate) else FALLBACK_LOCALE


static func localized_text(value: Dictionary, selected_locale: String = DEFAULT_LOCALE) -> String:
	var lang := normalize_locale(selected_locale)
	var source: Variant = value.get(lang)
	if source is Dictionary and not str(source.get("text", "")).is_empty():
		return str(source.text)
	var fallback: Variant = value.get(FALLBACK_LOCALE)
	if fallback is Dictionary:
		return str(fallback.get("text", ""))
	return ""


static func line_by_id(line_id: String) -> Dictionary:
	for entry: Dictionary in DialogueData.data.entries:
		if entry.id == line_id:
			return entry
	return {}


static func line_text(line_id: String, selected_locale: String = DEFAULT_LOCALE) -> String:
	var entry := line_by_id(line_id)
	return localized_text(entry.get("localized", {}), selected_locale) if not entry.is_empty() else ""


static func popup_text(popup_id: String, selected_locale: String = DEFAULT_LOCALE) -> String:
	for popup: Dictionary in PopupData.data.items:
		if popup.id == popup_id:
			return localized_text(popup.get("localized", {}), selected_locale)
	return ""


static func speaker_name(speaker_id: String, selected_locale: String = DEFAULT_LOCALE) -> String:
	var names: Dictionary = SPEAKERS.get(speaker_id, {})
	var language := normalize_locale(selected_locale)
	return str(names.get(language, names.get(FALLBACK_LOCALE, speaker_id)))


static func translation_report() -> Dictionary:
	var missing := {"ru": 0, "be": 0, "en": 0}
	for entry: Dictionary in DialogueData.data.entries:
		for lang: String in SUPPORTED_LOCALES:
			var variant: Variant = entry.localized.get(lang)
			if not variant is Dictionary or str(variant.get("text", "")).is_empty():
				missing[lang] += 1
	return {"total": DialogueData.data.entries.size(), "missingDialogueByLocale": missing}
