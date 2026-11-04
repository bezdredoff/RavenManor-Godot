extends Node
## UPDS-derived procedural music/effects bridge, shared across Raven scenes.
const Preferences = preload("res://scripts/raven/raven_production_localization.gd")
const Synthesis = preload("res://scripts/raven/raven_audio_synthesis.gd")

var preferences: Variant = Preferences.new()
var music := AudioStreamPlayer.new()
var effects := AudioStreamPlayer.new()
var _activated := false
var _focused := true
var _haptic_generation := 0
var _scene := "menu"
var _music_cache: Dictionary = {}
var haptics_supported: bool:
	get:
		if OS.has_feature("web"):
			return bool(JavaScriptBridge.eval("typeof navigator.vibrate === 'function'"))
		return OS.get_name() in ["Android", "iOS"]


func _ready() -> void:
	music.name = "RavenMusic"
	effects.name = "RavenEffects"
	add_child(music)
	add_child(effects)
	preferences.audio_changed.connect(_apply_settings)
	_apply_settings()


func _input(event: InputEvent) -> void:
	if event.is_pressed() and (event is InputEventMouseButton or event is InputEventKey or event is InputEventScreenTouch):
		activate()


func activate() -> void:
	_activated = true
	_apply_settings()


func set_scene(scene: String) -> void:
	if scene == _scene or scene not in ["menu", "vn", "ending"]:
		return
	_scene = scene
	music.stop()
	music.stream = null
	_apply_settings()


func preview_music() -> void:
	activate()
	if music.playing:
		music.play(0.0)


func preview_effects() -> void:
	activate()
	play_effect("match")


func play_effect(cue: String = "uiClick") -> void:
	if not Synthesis.DEFINITIONS.data.has(cue):
		return
	if not _focused:
		return
	_pulse(cue)
	var settings: Dictionary = preferences.audio
	if settings.muted or settings.effectsVolume <= 0 or not _focused:
		return
	effects.stream = Synthesis.effect(cue)
	effects.play()


func _pulse(cue: String) -> void:
	_haptic_generation += 1
	if not preferences.audio.hapticsEnabled or not haptics_supported or not _focused:
		return
	var generation := _haptic_generation
	var pattern: Array = Synthesis.DEFINITIONS.data[cue].get("haptic", [])
	if pattern.is_empty():
		return
	if OS.has_feature("web"):
		# Submit the complete pattern atomically; browser policy may reject it.
		JavaScriptBridge.eval("try { navigator.vibrate(%s); } catch (_) {}" % JSON.stringify(pattern))
		return
	var tree := get_tree()
	for index in pattern.size():
		if generation != _haptic_generation or not preferences.audio.hapticsEnabled or not _focused:
			return
		if index % 2 == 0:
			Input.vibrate_handheld(int(pattern[index]))
		if index + 1 < pattern.size():
			await tree.create_timer(float(pattern[index]) / 1000.0).timeout


func _apply_settings() -> void:
	if not is_inside_tree():
		return
	var settings: Dictionary = preferences.audio
	if not settings.hapticsEnabled or not _focused:
		_haptic_generation += 1
		if haptics_supported:
			if OS.has_feature("web"):
				JavaScriptBridge.eval("try { navigator.vibrate(0); } catch (_) {}")
			else:
				Input.vibrate_handheld(0)
	music.volume_db = linear_to_db(maxf(0.000001, float(settings.musicVolume) * 0.52))
	effects.volume_db = linear_to_db(maxf(0.000001, float(settings.effectsVolume)))
	if settings.muted or not _focused:
		music.stop()
		effects.stop()
		return
	if settings.effectsVolume <= 0:
		effects.stop()
	if settings.musicVolume <= 0:
		music.stop()
	elif _activated and not music.playing:
		if music.stream == null:
			if not _music_cache.has(_scene):
				_music_cache[_scene] = Synthesis.music(_scene)
			music.stream = _music_cache[_scene]
		music.play()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_focused = false
		_apply_settings()
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_focused = true
		_apply_settings()
