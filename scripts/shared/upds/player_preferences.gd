extends RefCounted

signal locale_changed(locale: String)
signal audio_changed

const MenuCopy = preload("res://scripts/raven/raven_menu_copy.gd")
const DEFAULT_PATH := "user://raven_language.cfg"
const DEFAULT_AUDIO := {
	"muted": false, "musicVolume": 0.32, "effectsVolume": 0.72, "hapticsEnabled": true,
}

var locale: String
var _path: String
var _audio: Dictionary = DEFAULT_AUDIO.duplicate()
var audio: Dictionary:
	get:
		return _audio.duplicate()


func _init(path: String = DEFAULT_PATH) -> void:
	_path = path
	locale = MenuCopy.default_locale()
	var config := ConfigFile.new()
	if config.load(_path) == OK:
		var saved: Variant = config.get_value("interface", "locale", "")
		if saved is String and MenuCopy.COPY.has(saved):
			locale = saved
		var restored := {}
		for key in DEFAULT_AUDIO:
			restored[key] = config.get_value("audio", key, DEFAULT_AUDIO[key])
		_audio = normalize_audio(restored)


func set_locale(value: String) -> Error:
	if not MenuCopy.COPY.has(value):
		return ERR_INVALID_PARAMETER
	if value == locale:
		return OK
	var error := _save(value, _audio)
	if error != OK:
		return error
	locale = value
	locale_changed.emit(locale)
	return OK


func update_audio(patch: Dictionary) -> Error:
	for key in patch:
		if not DEFAULT_AUDIO.has(key):
			return ERR_INVALID_PARAMETER
	var candidate := _audio.duplicate()
	candidate.merge(patch, true)
	candidate = normalize_audio(candidate)
	var error := _save(locale, candidate)
	if error != OK:
		return error
	_audio = candidate
	audio_changed.emit()
	return OK


func _save(selected_locale: String, settings: Dictionary) -> Error:
	var config := ConfigFile.new()
	config.set_value("interface", "locale", selected_locale)
	for key in DEFAULT_AUDIO:
		config.set_value("audio", key, settings[key])
	return config.save(_path)


static func normalize_audio(candidate: Dictionary) -> Dictionary:
	var result := DEFAULT_AUDIO.duplicate()
	for key in ["muted", "hapticsEnabled"]:
		if candidate.get(key) is bool:
			result[key] = candidate[key]
	for key in ["musicVolume", "effectsVolume"]:
		var value: Variant = candidate.get(key)
		if value is float or value is int:
			result[key] = clampf(float(value), 0.0, 1.0) if is_finite(float(value)) else 0.0
	return result
