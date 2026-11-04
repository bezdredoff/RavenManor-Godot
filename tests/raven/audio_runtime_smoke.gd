extends SceneTree

const Preferences = preload("res://scripts/raven/raven_production_localization.gd")
const Runtime = preload("res://scripts/raven/raven_audio_runtime.gd")
const Settings = preload("res://scripts/raven/raven_settings_dialog.gd")

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var path := "user://raven_audio_runtime_%d.cfg" % Time.get_ticks_usec()
	var preferences := Preferences.new(path)
	var runtime := Runtime.new()
	runtime.preferences = preferences
	root.add_child(runtime)
	await process_frame
	assert(runtime.music.name == "RavenMusic" and runtime.effects.name == "RavenEffects")
	assert(not runtime.music.playing, "Music waits for the first user gesture")
	runtime.activate()
	assert(runtime.music.playing, "User activation should start menu music")
	var menu_stream := runtime.music.stream as AudioStreamWAV
	assert(menu_stream != null and menu_stream.loop_mode == AudioStreamWAV.LOOP_FORWARD)
	assert(menu_stream.mix_rate == 22050 and menu_stream.get_length() > 11.0 and menu_stream.get_length() < 11.2)
	assert(_has_sound(menu_stream), "Synthesized menu music must contain audible PCM")
	assert(is_equal_approx(db_to_linear(runtime.music.volume_db), 0.32 * 0.52))

	preferences.update_audio({"musicVolume": 0.61, "effectsVolume": 0.27})
	assert(is_equal_approx(db_to_linear(runtime.music.volume_db), 0.61 * 0.52))
	runtime.preview_effects()
	assert(runtime.effects.playing and _has_sound(runtime.effects.stream as AudioStreamWAV))
	assert(is_equal_approx(db_to_linear(runtime.effects.volume_db), 0.27))
	var settings := Settings.new()
	settings.setup(preferences, runtime)
	root.add_child(settings)
	await process_frame
	settings.popup_centered(Vector2i(280, 450))
	await process_frame
	assert(settings.find_child("RavenPreviewMusic", true, false) != null)
	assert(settings.find_child("RavenPreviewEffects", true, false) != null)
	assert(settings.haptics_capability.text == ("Haptics available" if runtime.haptics_supported else "Устройство не поддерживает вибрацию"), "Capability copy must follow the runtime device probe")
	var preview_music := settings.find_child("RavenPreviewMusic", true, false) as Button
	var preview_effects := settings.find_child("RavenPreviewEffects", true, false) as Button
	preview_music.pressed.emit()
	assert(runtime.music.playing, "Music preview should use the shared music player")
	preview_effects.pressed.emit()
	assert(runtime.effects.playing, "Effects preview should use the shared effects player")
	settings.hide()
	settings.queue_free()

	preferences.update_audio({"muted": true})
	assert(not runtime.music.playing and not runtime.effects.playing)
	runtime.preview_music()
	runtime.preview_effects()
	assert(not runtime.music.playing and not runtime.effects.playing, "Preview must respect mute")
	preferences.update_audio({"muted": false})
	assert(runtime.music.playing, "Unmute should resume the active scene theme")
	preferences.update_audio({"effectsVolume": 0.0})
	runtime.preview_effects()
	assert(not runtime.effects.playing, "Zero effect volume must silence previews")
	preferences.update_audio({"musicVolume": 0.0})
	assert(not runtime.music.playing, "Zero music volume must stop the theme")
	preferences.update_audio({"musicVolume": 0.4, "effectsVolume": 0.8})
	assert(runtime.music.playing)
	runtime._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert(not runtime.music.playing and not runtime.effects.playing, "Focus loss must stop playback")
	runtime._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	assert(runtime.music.playing, "Focus regain should resume the active theme")
	runtime.set_scene("vn")
	assert(runtime.music.playing and runtime.music.stream != menu_stream, "VN route should switch music theme")
	runtime.set_scene("unknown")
	assert(runtime._scene == "vn", "Unknown music route must be ignored")
	runtime.play_effect("not-a-cue") # Invalid cue fails closed.
	assert(preferences.set_locale("be") == OK)
	var restored := Preferences.new(path)
	assert(restored.audio == preferences.audio and restored.locale == "be")
	assert(restored.accessibility == preferences.accessibility)
	await process_frame
	runtime.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("Raven procedural audio runtime, preference gating and focus smoke passed")
	quit()


func _has_sound(stream: AudioStreamWAV) -> bool:
	for offset in range(0, stream.data.size(), 2):
		if absi(stream.data.decode_s16(offset)) > 10:
			return true
	return false
