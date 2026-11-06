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



## VN-RUNTIME-01: editor/runtime parity for REVIEWED, opt-in phase/motion cues.
## Keep sample() above unchanged: older approved bundles have identical output.
## Pure deterministic sampling permits random access, scene replay and reduced-
## motion suppression by the caller, without Tween or AnimationPlayer state.
static func sample_reviewed(cue: Dictionary, elapsed_ms: int) -> Dictionary:
	var effect: String = str(cue.get("effect", ""))
	if effect in ["slide_in_left", "slide_in_right", "slide_out_left", "slide_out_right", "hop"]:
		return _sample_actor_motion(cue, elapsed_ms)
	var sampled_ms: int = elapsed_ms
	if cue.get("loop", false) and effect == "breathe" and elapsed_ms >= int(cue.get("startMs", 0)):
		var duration: int = int(cue.get("durationMs", 0))
		if duration > 0:
			var start: int = int(cue.get("startMs", 0))
			sampled_ms = start + posmod(elapsed_ms - start, duration)
	var output: Dictionary = sample(cue, sampled_ms)
	if cue.has("phase") and effect == "fade_in" and cue.get("phase") == "enter":
		if elapsed_ms >= 0 and elapsed_ms < int(cue.get("startMs", 0)):
			output["alpha"] = 1.0 - clampf(float(cue.get("intensity", 0.0)), 0.0, 1.0)
	elif cue.has("phase") and effect == "fade_out" and cue.get("phase") == "exit":
		var end: int = int(cue.get("startMs", 0)) + int(cue.get("durationMs", 0)) * int(cue.get("repeat", 1))
		if elapsed_ms >= end:
			output["alpha"] = 1.0 - clampf(float(cue.get("intensity", 0.0)), 0.0, 1.0)
	return output


## Matches StageFx editor's bounded actor slide/hop preview, intentionally
## independent of texture size and any authority-bearing stage transforms.
static func _sample_actor_motion(cue: Dictionary, elapsed_ms: int) -> Dictionary:
	var output := {"offset": Vector2.ZERO, "scale": Vector2.ONE, "alpha": 1.0}
	if elapsed_ms < 0:
		return output
	var start: int = int(cue.get("startMs", 0))
	var duration: int = int(cue.get("durationMs", 0))
	var repeats: int = int(cue.get("repeat", 1))
	if duration <= 0 or repeats <= 0:
		return output
	var effect: String = str(cue.get("effect", ""))
	var strength: float = clampf(float(cue.get("intensity", 0.0)), 0.0, 1.0)
	var end: int = start + duration * repeats
	if effect == "hop":
		if elapsed_ms < start or elapsed_ms >= end:
			return output
		var phase: float = float((elapsed_ms - start) % duration) / float(duration)
		output["offset"] = Vector2(0.0, -26.0 * strength * sin(PI * phase))
		return output
	var direction: float = -1.0 if effect.ends_with("left") else 1.0
	var distance: float = 80.0 * strength
	var fraction: float = clampf(float(elapsed_ms - start) / float(duration), 0.0, 1.0)
	var eased: float = fraction * fraction * (3.0 - 2.0 * fraction)
	if effect.begins_with("slide_in_"):
		output["offset"] = Vector2(direction * distance * (1.0 - eased), 0.0)
		output["alpha"] = lerpf(1.0 - strength, 1.0, eased)
	else:
		output["offset"] = Vector2(direction * distance * eased, 0.0)
		output["alpha"] = lerpf(1.0, 1.0 - strength, eased)
	return output
