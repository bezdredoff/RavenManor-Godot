extends RefCounted
## VNS5-06D2C: opt-in production VN dispatch, with fail-closed art/route/save
## gates. Pure read-only selector. Only canonical res:// registries can opt in.
## A D1/D2B review-only candidate is never a runtime scene.

const Copy = preload("res://scripts/raven/raven_production_localization.gd")
const Dialogue = preload("res://data/raven/production/season1_dialogue_catalog.json")
const Routes = preload("res://data/raven/production/map_narrative_routes.json")
const Staging = preload("res://data/raven/production/vn_staging.json")
const Cues = preload("res://data/raven/production/line_performance_cues.json")
const Foundation = preload("res://data/raven/foundation_catalog.json")
const Backgrounds = preload("res://data/raven/production/vn_background_catalog.json")
const Portraits = preload("res://data/raven/production/vn_character_catalog.json")

const APPROVED_SCENE_STATUS := "runtime_approved"
const APPROVED_ART_STATUS := "accepted"


static func next_scene(state: Dictionary, locale: String = "ru") -> Dictionary:
	return find_approved(state, Copy.normalize_locale(locale), Dialogue.data, Routes.data,
		Staging.data, Cues.data, Foundation.data, Backgrounds.data, Portraits.data)


## The extra parameters make this testable with synthetic *copies* of catalogs.
## They never allow a runtime user:// or staged-editor file path.
static func find_approved(state: Dictionary, locale: String, dialogue: Dictionary,
		routes: Dictionary, staging: Dictionary, cues: Dictionary, foundation: Dictionary,
		backgrounds: Dictionary, portraits: Dictionary) -> Dictionary:
	if locale not in ["ru", "be", "en"]:
		return {}
	if not state.get("storyBeatsSeen", []) is Array or not state.get("firstClearLevels", []) is Array:
		return {}
	var known_scenes: Dictionary = {}
	for scene in dialogue.get("scenes", []):
		if not scene is Dictionary:
			return {}
		var id: String = str(scene.get("sceneId", ""))
		if id.is_empty() or known_scenes.has(id):
			return {}
		known_scenes[id] = scene
	var all_routes: Array = routes.get("sceneTriggers", [])
	var selected: Dictionary = {}
	var best_ordinal: int = 2147483647
	for route in all_routes:
		if not route is Dictionary:
			return {}
		var beat_id: String = str(route.get("sceneId", ""))
		if not known_scenes.has(beat_id):
			continue
		if known_scenes[beat_id].get("status") != APPROVED_SCENE_STATUS:
			continue
		var gate: Variant = route.get("gate", {})
		if not gate is Dictionary or gate.get("approvedRuntime") is not bool or gate.get("approvedRuntime") is not bool:
			continue
		if gate.get("approvedRuntime") is not true or gate.get("proposedRuntime") is not false:
			continue
		if not foundation.get("storyBeats", []).has(beat_id) or state["storyBeatsSeen"].has(beat_id):
			continue
		if not _gate_satisfied(gate, state, foundation, known_scenes):
			continue
		var ordinal: Variant = route.get("ordinal", -1)
		if not ordinal is int or ordinal < 0 or ordinal >= best_ordinal:
			continue
		if route.get("postSceneAction") != "record_story_beat_only_after_player_finishes_VN":
			continue
		if route.get("whenReached") != "play_once_then_unlock_next_state":
			continue
		if str(route.get("interactionTarget", "")).is_empty():
			continue
		var config: Dictionary = build_config(beat_id, locale, known_scenes[beat_id],
			dialogue.get("entries", []), staging.get("sceneShots", []), cues.get("cues", []),
			backgrounds.get("entries", []), portraits.get("entries", []))
		if config.is_empty():
			continue
		selected = config
		best_ordinal = ordinal
	return selected


static func _gate_satisfied(gate: Dictionary, state: Dictionary,
		foundation: Dictionary, scenes: Dictionary) -> bool:
	var kind: String = str(gate.get("kind", ""))
	var ref: String = str(gate.get("ref", ""))
	match kind:
		"scene_complete":
			return scenes.has(ref) and state["storyBeatsSeen"].has(ref)
		"first_clear":
			return foundation.get("levels", {}).has(ref) and state["firstClearLevels"].has(ref)
	return false  # No choice, script, time or arbitrary branch in D2C.


static func build_config(beat_id: String, locale: String, scene: Dictionary, entries: Array,
		shots: Array, cues: Array, backgrounds: Array, portraits: Array) -> Dictionary:
	if scene.get("sceneId") != beat_id or scene.get("status") != APPROVED_SCENE_STATUS:
		return {}
	var title: Variant = scene.get("title", {})
	if not title is Dictionary or not title.get(locale) is String or str(title[locale]).strip_edges().is_empty():
		return {}
	var scene_shots: Array = shots.filter(func(item): return item is Dictionary and item.get("sceneId") == beat_id)
	if scene_shots.size() != 1:
		return {}
	var shot: Dictionary = scene_shots[0]
	var variants: Array = backgrounds.filter(func(item):
		return item is Dictionary and item.get("backgroundId") == shot.get("backgroundId") and
			item.get("lighting") == shot.get("lighting") and item.get("roomState") == shot.get("roomState"))
	if variants.size() != 1 or not _accepted_asset(variants[0], "res://assets/raven/vn_backgrounds/"):
		return {}
	var cast: Variant = shot.get("cast", [])
	if not cast is Array or cast.size() < 1 or cast.size() > 3 or shot.get("visibleCount") != cast.size():
		return {}
	var actor_map: Dictionary = {}
	var used_slots: Dictionary = {}
	for actor in cast:
		if not actor is Dictionary or actor.get("slot") not in ["left", "center", "right"]:
			return {}
		var character_id: String = str(actor.get("characterId", ""))
		if character_id.is_empty() or actor_map.has(character_id) or used_slots.has(actor.get("slot")):
			return {}
		used_slots[actor["slot"]] = true
		actor_map[character_id] = actor
		if not _has_art(character_id, str(actor.get("pose", "")), str(actor.get("emotion", "")), portraits):
			return {}
	var beat_lines: Array = entries.filter(func(item): return item is Dictionary and item.get("sceneId") == beat_id)
	if beat_lines.is_empty():
		return {}
	var line_ids: Dictionary = {}
	var output_lines: Array = []
	var ordered_line_ids: Array = []
	for line in beat_lines:
		var line_id: String = str(line.get("id", ""))
		if line_id.is_empty() or line_ids.has(line_id):
			return {}
		line_ids[line_id] = true
		var speaker: String = str(line.get("speakerId", ""))
		if not actor_map.has(speaker):
			return {}  # No unapproved narrator or speaking offscreen cast.
		var localized: Variant = line.get("localized", {})
		if not localized is Dictionary:
			return {}
		for lang in ["ru", "be", "en"]:
			var cell: Variant = localized.get(lang)
			if not cell is Dictionary or str(cell.get("text", "")).strip_edges().is_empty():
				return {}  # No fallback for newly playable scenes.
		var line_cues: Array = cues.filter(func(item): return item is Dictionary and item.get("lineId") == line_id)
		if line_cues.size() != 1:
			return {}
		var cue: Dictionary = line_cues[0]
		if cue.get("manualReview") is not false or cue.get("sceneId") != beat_id or cue.get("speakerId") != speaker:
			return {}
		if cue.get("portraitVisible") is not true:
			return {}
		if not _has_art(speaker, str(cue.get("poseId", "")), str(cue.get("emotionId", "")), portraits):
			return {}
		ordered_line_ids.append(line_id)
		output_lines.append({
			"speaker": Copy.speaker_name(speaker, locale),
			"text": str(localized[locale].get("text", "")),
		})
	return {
		"beatId": beat_id,
		"sceneId": beat_id,
		"speaker": "",
		"title": str(title[locale]),
		"lines": output_lines,
		"lineIds": ordered_line_ids,
		"source": "canonical_production_only",
	}


static func _has_art(character_id: String, pose: String, emotion: String, portraits: Array) -> bool:
	for variant in portraits:
		if variant is Dictionary and variant.get("characterId") == character_id and 				variant.get("pose") == pose and variant.get("emotion") == emotion and 				bool(variant.get("defaultForPose", false)) and 				_accepted_asset(variant, "res://assets/raven/characters/"):
			return true
	return false


static func _accepted_asset(asset: Dictionary, root: String) -> bool:
	var path: Variant = asset.get("path")
	return asset.get("status") == APPROVED_ART_STATUS and 		asset.get("approved") is String and not str(asset.get("approved")).strip_edges().is_empty() and 		path is String and path.begins_with(root) and not path.contains("..") and 		ResourceLoader.exists(path)


static func completion_event(config: Dictionary, at_end: bool, event_id: String) -> Dictionary:
	# UI may call only when RavenVNPlayer.advance() returns true.
	if not at_end or event_id.is_empty() or config.get("source") != "canonical_production_only":
		return {}
	var beat_id: String = str(config.get("beatId", ""))
	if not beat_id.begins_with("RM-BEAT-"):
		return {}
	return {"type": "story_beat_seen", "storyBeatId": beat_id, "eventId": event_id}
