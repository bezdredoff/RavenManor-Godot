extends RefCounted

# Ported from MusicTheme.ts / AudioCues.ts. JSON parity is checked in Vitest.
const DEFINITIONS = preload("res://data/raven/raven_menu_audio.json")
const SAMPLE_RATE := 22050


static func music(scene: String = "menu") -> AudioStreamWAV:
	var theme: Dictionary = DEFINITIONS.data[scene]
	var beat := 60.0 / float(theme.bpm)
	var samples := PackedFloat32Array()
	samples.resize(ceili(float(theme.beatsPerLoop) * beat * SAMPLE_RATE))
	for tone in theme.tones:
		var duration := float(tone.durationBeats) * beat
		var attack := minf(duration - 0.02, minf(0.18, duration * 0.26))
		var release := maxf(attack, duration - minf(0.34, duration * 0.36))
		_add_tone(samples, float(tone.beat) * beat, duration, float(tone.frequency),
			float(tone.gain), str(tone.wave), attack, release)
	_lowpass(samples)
	return _stream(samples, true)


static func effect(cue: String) -> AudioStreamWAV:
	var definition: Dictionary = DEFINITIONS.data[cue]
	var slice: float = float(definition.durationMs) / 1000.0 / definition.frequencies.size()
	var duration := maxf(0.045, slice * 1.18)
	var samples := PackedFloat32Array()
	samples.resize(ceili((slice * 0.68 * (definition.frequencies.size() - 1) + duration + 0.02) * SAMPLE_RATE))
	for index in definition.frequencies.size():
		_add_tone(samples, index * slice * 0.68, duration,
			float(definition.frequencies[index]), float(definition.gain), str(definition.wave), 0.01, 0.01)
	return _stream(samples, false)


static func _add_tone(samples: PackedFloat32Array, start: float, duration: float,
	frequency: float, gain: float, wave: String, attack: float, release: float) -> void:
	var offset := roundi(start * SAMPLE_RATE)
	for index in mini(ceili(duration * SAMPLE_RATE), samples.size() - offset):
		var time := float(index) / SAMPLE_RATE
		var envelope := gain
		if time < attack:
			envelope = 0.0001 * pow(gain / 0.0001, time / attack)
		elif time > release:
			envelope = gain * pow(0.0001 / gain, (time - release) / (duration - release))
		var value := sin(TAU * frequency * time)
		if wave == "triangle":
			value = asin(value) * 2.0 / PI
		samples[offset + index] += value * envelope


static func _lowpass(samples: PackedFloat32Array) -> void:
	# Web Audio menu low-pass: 2600 Hz, Q=0.45 (RBJ biquad).
	var omega := TAU * 2600.0 / SAMPLE_RATE
	var alpha := sin(omega) / (2.0 * 0.45)
	var a0 := 1.0 + alpha
	var b0 := (1.0 - cos(omega)) / (2.0 * a0)
	var b1 := (1.0 - cos(omega)) / a0
	var a1 := -2.0 * cos(omega) / a0
	var a2 := (1.0 - alpha) / a0
	var x1 := 0.0
	var x2 := 0.0
	var y1 := 0.0
	var y2 := 0.0
	for index in samples.size():
		var x := samples[index]
		var y := b0 * x + b1 * x1 + b0 * x2 - a1 * y1 - a2 * y2
		samples[index] = y
		x2 = x1
		x1 = x
		y2 = y1
		y1 = y


static func _stream(samples: PackedFloat32Array, loop: bool) -> AudioStreamWAV:
	var pcm := PackedByteArray()
	pcm.resize(samples.size() * 2)
	for index in samples.size():
		pcm.encode_s16(index * 2, roundi(clampf(samples[index], -1.0, 1.0) * 32767))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.data = pcm
	if loop:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = samples.size()
	return stream
