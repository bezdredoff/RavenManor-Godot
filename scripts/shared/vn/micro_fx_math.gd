@tool
extends RefCounted
## Shared deterministic presentation math for VN micro-FX.
## No EditorInterface, scene tree, audio or campaign state dependencies.

static func sample(cue: Dictionary, elapsed_ms: int) -> Dictionary:
	var neutral := {"offset": Vector2.ZERO, "scale": Vector2.ONE, "alpha": 1.0}
	var start: int = int(cue.get("startMs", 0))
	var duration: int = int(cue.get("durationMs", 1000))
	var repeat_count: int = int(cue.get("repeat", 1))
	if duration <= 0 or repeat_count <= 0 or elapsed_ms < start or elapsed_ms >= start + duration * repeat_count:
		return neutral
	var phase: float = float((elapsed_ms - start) % duration) / float(duration)
	var strength: float = clampf(float(cue.get("intensity", 0.0)), 0.0, 1.0)
	var wave: float = sin(PI * 2.0 * phase)
	match str(cue.get("effect", "")):
		"breathe":
			neutral["scale"] = Vector2(1.0 + 0.018 * strength * wave, 1.0 + 0.028 * strength * wave)
		"blink":
			var close: float = maxf(0.0, 1.0 - absf(phase - 0.5) / 0.12)
			neutral["scale"] = Vector2(1.0, 1.0 - 0.09 * strength * close)
		"shake":
			neutral["offset"] = Vector2(5.0 * strength * wave, 1.7 * strength * sin(PI * 6.0 * phase))
		"pulse":
			var pulse: float = 1.0 - cos(PI * 2.0 * phase)
			neutral["scale"] = Vector2.ONE * (1.0 + 0.06 * strength * pulse)
		"fade_in":
			neutral["alpha"] = lerpf(1.0 - strength, 1.0, phase)
		"fade_out":
			neutral["alpha"] = lerpf(1.0, 1.0 - strength, phase)
	return neutral
