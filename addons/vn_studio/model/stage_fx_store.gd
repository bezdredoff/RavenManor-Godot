@tool
extends RefCounted
## VNS5-05A: pure, bounded editor-only micro-animation cues and deterministic preview.
## No gameplay, dialogue timing or save effects. Any future runtime consumer requires review.
const FORMAT := "raven-vn-stage-fx-v1"
const EFFECTS := ["breathe", "blink", "shake", "pulse", "fade_in", "fade_out"]
const TARGET_TYPES := ["actor", "prop", "background"]
const MAX_CUES := 32
const MAX_MS := 20000
const KEYS := ["format", "schemaVersion", "sceneId", "cues"]
const CUE_KEYS := ["id", "targetType", "targetId", "effect", "startMs", "durationMs", "repeat", "intensity", "lineId"]


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
		var start: Variant = cue.get("startMs")
		var duration: Variant = cue.get("durationMs")
		var repeat_count: Variant = cue.get("repeat")
		var intensity: Variant = cue.get("intensity")
		if not start is int or not duration is int or not repeat_count is int \
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


## Scene-wide cues are always visible; per-line cues only on their exact line.
## Pure editor-preview predicate; never advances story or writes game state.
static func visible_for_line(cue: Dictionary, line_id: String) -> bool:
	if not cue.has("lineId"):
		return true
	return not line_id.is_empty() and cue["lineId"] == line_id


## Time-sampling is pure and independent of frame rate. Returns a visual-only
## additive offset, scale factor and opacity factor for a single cue.
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
