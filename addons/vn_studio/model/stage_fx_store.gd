@tool
extends RefCounted
## VNS5-05A: pure, bounded editor-only micro-animation cues and deterministic preview.
## No gameplay, dialogue timing or save effects. Any future runtime consumer requires review.
const MathFx = preload("res://scripts/shared/vn/micro_fx_math.gd")
const FORMAT := "raven-vn-stage-fx-v1"
const EFFECTS := ["breathe", "blink", "shake", "pulse", "fade_in", "fade_out",
	"slide_in_left", "slide_in_right", "slide_out_left", "slide_out_right", "hop"]
# New motion-only FX are editor-review cues; they are not yet whitelisted by
# the approved gameplay FX runtime and must not activate automatically.
const ACTOR_MOTION := ["slide_in_left", "slide_in_right", "slide_out_left", "slide_out_right", "hop"]
# User-facing actor presets intentionally map onto existing validated v1 FX.
# No new art layers, renderer, scriptable cue kind or runtime promotion.
const ACTOR_PRESETS := ["appear", "disappear", "breathe", "twitch", "emphasis", "blink",
	"slide_in_left", "slide_in_right", "slide_out_left", "slide_out_right", "hop"]
const ACTOR_PRESET_VALUES := {
	"appear": {"effect": "fade_in", "phase": "enter", "startMs": 0,
		"durationMs": 650, "repeat": 1, "intensity": 1.0},
	"disappear": {"effect": "fade_out", "phase": "exit", "startMs": 1800,
		"durationMs": 500, "repeat": 1, "intensity": 1.0},
	"breathe": {"effect": "breathe", "phase": "idle", "startMs": 0,
		"durationMs": 1600, "repeat": 5, "intensity": 0.45, "loop": true},
	"twitch": {"effect": "shake", "phase": "idle", "startMs": 550,
		"durationMs": 220, "repeat": 1, "intensity": 0.45},
	"emphasis": {"effect": "pulse", "phase": "idle", "startMs": 250,
		"durationMs": 400, "repeat": 1, "intensity": 0.45},
	# The existing blink squeezes the entire portrait, not actual eyelids.
	"blink": {"effect": "blink", "phase": "idle", "startMs": 950,
		"durationMs": 200, "repeat": 1, "intensity": 0.55},
	"slide_in_left": {"effect": "slide_in_left", "phase": "enter", "startMs": 0,
		"durationMs": 650, "repeat": 1, "intensity": 1.0},
	"slide_in_right": {"effect": "slide_in_right", "phase": "enter", "startMs": 0,
		"durationMs": 650, "repeat": 1, "intensity": 1.0},
	"slide_out_left": {"effect": "slide_out_left", "phase": "exit", "startMs": 1800,
		"durationMs": 600, "repeat": 1, "intensity": 1.0},
	"slide_out_right": {"effect": "slide_out_right", "phase": "exit", "startMs": 1800,
		"durationMs": 600, "repeat": 1, "intensity": 1.0},
	"hop": {"effect": "hop", "phase": "idle", "startMs": 350,
		"durationMs": 420, "repeat": 1, "intensity": 0.65}
}
const TARGET_TYPES := ["actor", "prop", "background"]
const PHASES := ["enter", "idle", "exit"]
const MAX_CUES := 32
const MAX_MS := 20000
const KEYS := ["format", "schemaVersion", "sceneId", "cues"]
const CUE_KEYS := ["id", "targetType", "targetId", "effect", "startMs", "durationMs", "repeat", "intensity", "lineId", "phase", "loop"]


static func fresh(scene_id: String) -> Dictionary:
	return {"format": FORMAT, "schemaVersion": 1, "sceneId": scene_id, "cues": []}


static func effective(draft: Dictionary, scene_id: String) -> Dictionary:
	var saved: Variant = draft.get("stageFxPatches", {}).get(scene_id, {})
	return saved.duplicate(true) if saved is Dictionary and not saved.is_empty() else fresh(scene_id)


static func target_options(stage: Dictionary, stage_v2: Dictionary) -> Array[Dictionary]:
	var options: Array[Dictionary] = [{"type": "background", "id": "background", "label": "Фон"}]
	for actor in stage.get("cast", []):
		if actor is Dictionary:
			var id: String = str(actor.get("characterId", ""))
			options.append({"type": "actor", "id": id, "label": id.trim_prefix("RM-CHAR-")})
	for prop in stage_v2.get("props", []):
		if prop is Dictionary:
			options.append({"type": "prop", "id": str(prop.get("instanceId", "")),
				"label": str(prop.get("label", "Prop"))})
	return options


## Godot JSON.parse_string may decode whole numeric JSON values as float.
## Accept only finite, mathematically integral numbers; reject 150.5 ms,
## NaN/Inf and wrong types. This keeps old integer-only semantic bounds.
static func _whole_number(value: Variant) -> bool:
	if value is int:
		return true
	if value is float:
		return is_finite(value) and value == floorf(value)
	return false


static func validate(stage: Dictionary, stage_v2: Dictionary, data: Variant, valid_line_ids: Array = []) -> String:
	if not data is Dictionary:
		return "FX-постановка должна быть объектом."
	for key in data.keys():
		if key not in KEYS:
			return "Неизвестное поле FX: " + str(key)
	if data.get("format") != FORMAT or data.get("schemaVersion") != 1 \
			or data.get("sceneId") != stage.get("sceneId"):
		return "Неверная версия или sceneId FX."
	var cues: Variant = data.get("cues")
	if not cues is Array or cues.size() > MAX_CUES:
		return "FX содержит больше 32 событий или некорректный список."
	var valid_targets: Dictionary = {}
	for candidate in target_options(stage, stage_v2):
		valid_targets[str(candidate["type"]) + "/" + str(candidate["id"])] = true
	var seen: Dictionary = {}
	for cue in cues:
		if not cue is Dictionary:
			return "FX событие должно быть объектом."
		for key in cue.keys():
			if key not in CUE_KEYS:
				return "Недопустимое поле события: " + str(key)
		var id: Variant = cue.get("id", "")
		if not id is String or not id.begins_with("fx-") or id.length() != 7:
			return "Некорректный ID события FX."
		for i in range(3, 7):
			if not "0123456789".contains(id.substr(i, 1)):
				return "Некорректный числовой ID FX."
		if seen.has(id):
			return "Повторный ID события FX."
		seen[id] = true
		# Optional VNS5-05B line anchor: old scene-wide cues remain unchanged.
		# Fail closed if a saved line no longer exists in this exact scene.
		if cue.has("lineId"):
			var line_id: Variant = cue["lineId"]
			if not line_id is String or line_id.is_empty() or not valid_line_ids.has(line_id):
				return "FX ссылается на несуществующую реплику выбранной сцены."
		var target_type: Variant = cue.get("targetType", "")
		var target_id: Variant = cue.get("targetId", "")
		if not target_type is String or target_type not in TARGET_TYPES or not target_id is String \
				or not valid_targets.has(target_type + "/" + target_id):
			return "Цель FX отсутствует в выбранной постановке."
		if cue.get("effect", "") not in EFFECTS:
			return "Неизвестная микроанимация."
		if cue.get("effect", "") in ACTOR_MOTION and target_type != "actor":
			return "Вход, выход и подпрыгивание доступны только персонажам."
		# Existing cues without loop keep exact bounded repeat behavior.
		# A looping idle breath is opt-in and allowed only on character art.
		if cue.has("loop"):
			if not cue["loop"] is bool:
				return "FX loop должен быть boolean."
			if cue["loop"] and (target_type != "actor" or cue.get("effect", "") != "breathe" or cue.get("phase", "") != "idle"):
				return "Зацикливание доступно только для idle-дыхания персонажа."
		# Optional annotation. Existing scene/line FX v1 cues with no phase
		# retain their original preview and persist without forced migrations.
		if cue.has("phase") and (not cue["phase"] is String or cue["phase"] not in PHASES):
			return "Неизвестная дорожка FX (enter/idle/exit)."
		var start: Variant = cue.get("startMs")
		var duration: Variant = cue.get("durationMs")
		var repeat_count: Variant = cue.get("repeat")
		var intensity: Variant = cue.get("intensity")
		if not _whole_number(start) or not _whole_number(duration) or not _whole_number(repeat_count) \
				or start < 0 or start > 15000 or duration < 120 or duration > 4000 \
				or repeat_count < 1 or repeat_count > 5 or start + duration * repeat_count > MAX_MS:
			return "Время FX вне лимитов (max 20 секунд)."
		if not (intensity is float or intensity is int) or not is_finite(float(intensity)) \
				or float(intensity) < 0.0 or float(intensity) > 1.0:
			return "Сила FX должна быть конечной в диапазоне 0–1."
	return ""


static func new_cue(data: Dictionary, target_type: String, target_id: String, line_id: String = "") -> Dictionary:
	var result: Dictionary = data.duplicate(true)
	var ids: Dictionary = {}
	for cue in result.get("cues", []):
		ids[str(cue.get("id", ""))] = true
	var number: int = 1
	while ids.has("fx-%04d" % number):
		number += 1
	var cue: Dictionary = {"id": "fx-%04d" % number, "targetType": target_type,
		"targetId": target_id, "effect": "breathe", "startMs": 0,
		"durationMs": 1400, "repeat": 1, "intensity": 0.35}
	if not line_id.is_empty():
		cue["lineId"] = line_id
	result["cues"].append(cue)
	return result


## Create an actual previewable entrance / idle / exit cue with explicit
## bounded timings and the same v1 FX event format. No runtime scheduling.
static func new_phase_cue(data: Dictionary, target_type: String, target_id: String,
		phase: String, line_id: String = "") -> Dictionary:
	if phase not in PHASES:
		return data.duplicate(true)
	var result: Dictionary = new_cue(data, target_type, target_id, line_id)
	var cue: Dictionary = result["cues"][-1]
	cue["phase"] = phase
	match phase:
		"enter":
			cue["effect"] = "fade_in"
			cue["startMs"] = 0
			cue["durationMs"] = 650
			cue["repeat"] = 1
			cue["intensity"] = 1.0
		"idle":
			cue["effect"] = "breathe"
			cue["startMs"] = 1500
			cue["durationMs"] = 1400
			cue["repeat"] = 3
			cue["intensity"] = 0.35
		"exit":
			cue["effect"] = "fade_out"
			cue["startMs"] = 8000
			cue["durationMs"] = 650
			cue["repeat"] = 1
			cue["intensity"] = 1.0
	return result


## One-click character presets. Existing v1 cue schema/validation and
## deterministic preview are preserved for old drafts and exports.
static func new_actor_preset(data: Dictionary, actor_id: String,
		preset: String, line_id: String = "") -> Dictionary:
	if preset not in ACTOR_PRESETS or actor_id.is_empty():
		return data.duplicate(true)
	var result: Dictionary = new_cue(data, "actor", actor_id, line_id)
	var cue: Dictionary = result["cues"][-1]
	for key in ACTOR_PRESET_VALUES[preset]:
		cue[key] = ACTOR_PRESET_VALUES[preset][key]
	return result


static func phase_of(cue: Dictionary) -> String:
	return str(cue.get("phase", "idle"))


## Scene-wide cues are always visible; per-line cues only on their exact line.
## Pure editor-preview predicate; never advances story or writes game state.
static func visible_for_line(cue: Dictionary, line_id: String) -> bool:
	if not cue.has("lineId"):
		return true
	return not line_id.is_empty() and cue["lineId"] == line_id


## Time-sampling is pure and independent of frame rate. Returns a visual-only
## additive offset, scale factor and opacity factor for a single cue.
static func sample(cue: Dictionary, elapsed_ms: int) -> Dictionary:
	var effect: String = str(cue.get("effect", ""))
	# The shared UPDS/Raven sampler deliberately remains untouched: the new
	# preview-only actor gestures are local to the editor until VN Runtime review.
	if effect in ACTOR_MOTION:
		return _sample_actor_motion(cue, elapsed_ms)
	var sampled_ms: int = elapsed_ms
	if cue.get("loop", false) and effect == "breathe" and elapsed_ms >= int(cue.get("startMs", 0)):
		var duration: int = int(cue.get("durationMs", 0))
		if duration > 0:
			var start: int = int(cue.get("startMs", 0))
			sampled_ms = start + posmod(elapsed_ms - start, duration)
	var output: Dictionary = MathFx.sample(cue, sampled_ms)
	# Only NEW explicit phase presets hold the object outside a fade; legacy
	# no-phase cues keep precisely their previous neutral/one-shot semantics.
	if cue.has("phase") and phase_of(cue) == "enter" and cue.get("effect") == "fade_in":
		if elapsed_ms >= 0 and elapsed_ms < int(cue["startMs"]):
			output["alpha"] = 1.0 - float(cue["intensity"])
	elif cue.has("phase") and phase_of(cue) == "exit" and cue.get("effect") == "fade_out":
		if elapsed_ms >= int(cue["startMs"]) + int(cue["durationMs"]) * int(cue["repeat"]):
			output["alpha"] = 1.0 - float(cue["intensity"])
	return output


## Stage preview only: smooth native Control.position and modulate motion, with
## deterministic sampling in either scrub direction (no orphan Godot tweens).
## Baselines come from StageDesigner._layout_cards before each sample.
static func _sample_actor_motion(cue: Dictionary, elapsed_ms: int) -> Dictionary:
	var output := {"offset": Vector2.ZERO, "scale": Vector2.ONE, "alpha": 1.0}
	if elapsed_ms < 0:
		return output # Explicit preview Reset restores original stage.
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
	var towards_left: bool = effect.ends_with("left")
	var direction: float = -1.0 if towards_left else 1.0
	# 80px in the editor's portrait preview; no normalized authoring position
	# is persisted by this visual displacement.
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
