extends RefCounted
## VNS5-05B phase 2: opt-in, reviewed VN presentation FX only.
## NEVER load user:// studio drafts or apply gameplay/save/reducer events.
const MathFx = preload("res://scripts/shared/vn/micro_fx_math.gd")
const FORMAT := "raven-vn-runtime-fx-v1"
const EFFECTS := ["breathe", "blink", "shake", "pulse", "fade_in", "fade_out"]
const KEYS := ["format", "schemaVersion", "sceneId", "approvalStatus", "approvalRef", "cues"]
const CUE_KEYS := ["id", "targetType", "targetId", "effect", "startMs", "durationMs", "repeat", "intensity", "lineId"]

var _bundle: Dictionary = {}
var _scene_id: String = ""
var _line_ids: Array = []
var _actor_ids: Array = []
var _active_line: String = ""
var _scene_ms: float = 0.0
var _line_ms: float = 0.0


func clear() -> void:
	_bundle.clear()
	_scene_id = ""
	_line_ids.clear()
	_actor_ids.clear()
	_active_line = ""
	_scene_ms = 0.0
	_line_ms = 0.0


func configured() -> bool:
	return not _bundle.is_empty()


## Only explicitly approved bundles are permitted. The Studio FX review format
## intentionally does not satisfy this contract (runtimeApplied:false).
func configure(scene_id: String, line_ids: Array, actor_ids: Array, bundle: Dictionary) -> String:
	clear()
	if bundle.is_empty():
		return "" # unconfigured gameplay has no FX by default
	for key in bundle.keys():
		if key not in KEYS:
			return "Unexpected runtime FX bundle field: " + str(key)
	if bundle.get("format") != FORMAT or bundle.get("schemaVersion") != 1 or bundle.get("sceneId") != scene_id:
		return "Runtime FX format, version or scene does not match."
	if bundle.get("approvalStatus") != "approved" or not bundle.get("approvalRef") is String or str(bundle["approvalRef"]).strip_edges().is_empty():
		return "FX requires explicit approval reference; local Studio review exports are not playable."
	if scene_id.is_empty() or line_ids.is_empty():
		return "Runtime FX requires a non-empty scene and canonical line IDs."
	var allowed_lines: Dictionary = {}
	for item in line_ids:
		if not item is String or item.is_empty() or allowed_lines.has(item):
			return "Invalid or duplicate runtime scene line ID."
		allowed_lines[item] = true
	var allowed_actors: Dictionary = {}
	for item in actor_ids:
		if not item is String or item.is_empty():
			return "Invalid runtime actor ID."
		allowed_actors[item] = true
	var cues: Variant = bundle.get("cues")
	if not cues is Array or cues.size() > 32:
		return "Runtime FX cue list is invalid or too long."
	var used: Dictionary = {}
	for cue in cues:
		if not cue is Dictionary:
			return "Runtime FX cue is not an object."
		for key in cue.keys():
			if key not in CUE_KEYS:
				return "Unexpected runtime FX cue field: " + str(key)
		var cue_id: Variant = cue.get("id", "")
		if not cue_id is String or not cue_id.begins_with("fx-") or cue_id.length() != 7:
			return "Invalid runtime FX cue id."
		for i in range(3, 7):
			if not "0123456789".contains(cue_id.substr(i, 1)):
				return "Invalid runtime FX numeric cue id."
		if used.has(cue_id):
			return "Duplicate runtime FX cue id."
		used[cue_id] = true
		if cue.has("lineId") and (not cue["lineId"] is String or not allowed_lines.has(cue["lineId"])):
			return "Runtime FX references a missing line."
		var kind: Variant = cue.get("targetType", "")
		var target: Variant = cue.get("targetId", "")
		if not kind is String or not target is String:
			return "Runtime FX target must be an ID."
		if kind == "background":
			if target != "background":
				return "Runtime FX background target is invalid."
		elif kind == "actor":
			if not allowed_actors.has(target):
				return "Runtime FX actor is absent from approved stage."
		else:
			return "Runtime FX target is unsupported (props require a reviewed renderer)."
		if cue.get("effect", "") not in EFFECTS:
			return "Runtime FX effect is unsupported."
		var start: Variant = cue.get("startMs")
		var duration: Variant = cue.get("durationMs")
		var repeats: Variant = cue.get("repeat")
		var strength: Variant = cue.get("intensity")
		if not start is int or not duration is int or not repeats is int or start < 0 or start > 15000 or duration < 120 or duration > 4000 or repeats < 1 or repeats > 5 or start + duration * repeats > 20000:
			return "Runtime FX timing is out of bounds."
		if not (strength is float or strength is int) or not is_finite(float(strength)) or float(strength) < 0.0 or float(strength) > 1.0:
			return "Runtime FX intensity is invalid."
	_scene_id = scene_id
	_line_ids = line_ids.duplicate()
	_actor_ids = actor_ids.duplicate()
	_bundle = bundle.duplicate(true)
	return ""


## Returns false on stale scene/line; no implicit migration or fallback.
func enter_line(scene_id: String, line_id: String) -> bool:
	if not configured() or scene_id != _scene_id or not _line_ids.has(line_id):
		_active_line = ""
		return false
	if _active_line != line_id:
		_active_line = line_id
		_line_ms = 0.0
	return true


## Pure presentation output, keyed by background/background or actor/RM-CHAR-*.
## Scene-wide cues keep the scene clock across lines; line FX reset on line entry.
## Skip/reduced-motion disables visuals without advancing or mutating story state.
func step(delta: float, skipping: bool = false, reduced_motion: bool = false) -> Dictionary:
	if not configured() or _active_line.is_empty():
		return {}
	if not is_finite(delta) or delta < 0.0:
		return {}
	var elapsed: float = minf(delta * 1000.0, 20000.0)
	_scene_ms = minf(20000.0, _scene_ms + elapsed)
	_line_ms = minf(20000.0, _line_ms + elapsed)
	if skipping or reduced_motion:
		return {}
	var samples: Dictionary = {}
	for cue in _bundle["cues"]:
		var line_bound: bool = cue.has("lineId")
		if line_bound and cue["lineId"] != _active_line:
			continue
		var clock: int = roundi(_line_ms if line_bound else _scene_ms)
		var current: Dictionary = MathFx.sample(cue, clock)
		var target_key: String = str(cue["targetType"]) + "/" + str(cue["targetId"])
		var composed: Dictionary = samples.get(target_key, {"offset": Vector2.ZERO, "scale": Vector2.ONE, "alpha": 1.0})
		composed["offset"] += current["offset"]
		composed["scale"] *= current["scale"]
		composed["alpha"] *= float(current["alpha"])
		samples[target_key] = composed
	return samples


func reset_clocks() -> void:
	_scene_ms = 0.0
	_line_ms = 0.0
	_active_line = ""
