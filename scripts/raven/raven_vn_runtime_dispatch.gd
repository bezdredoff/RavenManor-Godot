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
const ARRIVAL_FOOT_TOLERANCE := 0.25

## Legacy vertical_slice invokes next_scene() after the RM-VS-01 director.
## Physically triggered scenes MUST NOT auto-start without verified arrival.


static func next_scene(state: Dictionary, locale: String = "ru") -> Dictionary:
	return find_approved(state, Copy.normalize_locale(locale), Dialogue.data, Routes.data,
		Staging.data, Cues.data, Foundation.data, Backgrounds.data, Portraits.data, "", true)


## Production-only map entry. No caller-provided success Boolean or client
## receipt: inspect the actual configured Raven gameplay host, its authored
## graph, confirmed room/anchor and physical mover position. Agent B owns
## invoking this at its validated arrival boundary and saving the result.
static func next_scene_at_confirmed_hotspot(host: Node, hotspot_id: String,
		locale: String = "ru") -> Dictionary:
	if host == null or not is_instance_valid(host) or hotspot_id.is_empty():
		return {}
	var script: Script = host.get_script()
	if script == null or script.resource_path != "res://scripts/raven/raven_gameplay_host.gd":
		return {}
	var source: Variant = host.get("source")
	var state: Variant = host.get("state")
	var navigation: Variant = host.get("navigation")
	if not source is Dictionary or source.get("draftOnly", true) != false or not state is Dictionary:
		return {}
	if navigation == null or not is_instance_valid(navigation) or navigation.actor == null:
		return {}
	if not is_instance_valid(navigation.actor) or navigation.actor.has_active_segment():
		return {}
	if not navigation.controller.ready_transition().is_empty():
		return {}
	var room_id: String = str(navigation.controller.room_id())
	var anchor_id: String = str(navigation.controller.confirmed_anchor())
	var graph: Variant = navigation.controller.room_graph(room_id)
	if graph == null or anchor_id.is_empty() or graph.interaction_anchor(hotspot_id) != anchor_id:
		return {}
	if navigation.actor.position.distance_to(graph.position(anchor_id)) > ARRIVAL_FOOT_TOLERANCE:
		return {}
	return find_approved(state, Copy.normalize_locale(locale), Dialogue.data, Routes.data,
		Staging.data, Cues.data, Foundation.data, Backgrounds.data, Portraits.data, hotspot_id)


## The extra parameters make this testable with synthetic *copies* of catalogs.
## They never allow a runtime user:// or staged-editor file path.
static func find_approved(state: Dictionary, locale: String, dialogue: Dictionary,
		routes: Dictionary, staging: Dictionary, cues: Dictionary, foundation: Dictionary,
		backgrounds: Dictionary, portraits: Dictionary,
		arrived_target: String = "", auto_only: bool = false) -> Dictionary:
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
	var used_ordinals: Dictionary = {}
	for route in all_routes:
		if not route is Dictionary:
			return {}
		var beat_id: String = str(route.get("sceneId", ""))
		if not known_scenes.has(beat_id):
			continue
		if known_scenes[beat_id].get("status") != APPROVED_SCENE_STATUS:
			continue
		var ordinal := _strict_integral_ordinal(route.get("ordinal", null))
		if ordinal < 0:
			continue
		if used_ordinals.has(ordinal):
			return {}
		used_ordinals[ordinal] = true
		var gate: Variant = route.get("gate", {})
		if not gate is Dictionary or not (gate.get("approvedRuntime") is bool) or not (gate.get("proposedRuntime") is bool):
			continue
		if gate.get("approvedRuntime") != true or gate.get("proposedRuntime") != false:
			continue
		if auto_only and str(gate.get("kind", "")) != "auto_new_game":
			continue
		if not arrived_target.is_empty() and route.get("interactionTarget") != arrived_target:
			continue
		if not foundation.get("storyBeats", []).has(beat_id) or state["storyBeatsSeen"].has(beat_id):
			continue
		if not _gate_satisfied(gate, state, foundation, known_scenes):
			continue
		if ordinal >= best_ordinal:
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
		config["interactionTarget"] = str(route.get("interactionTarget", ""))
		config["ordinal"] = ordinal
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
		"auto_new_game":
			return ref == "none" and state["storyBeatsSeen"].is_empty() and \
				state["firstClearLevels"].is_empty()
		"restoration_done":
			return foundation.get("restorations", {}).has(ref) and state.get("completedRestorations", []).has(ref)
		"clue_recorded":
			return foundation.get("clues", {}).has(ref) and state.get("recordedClues", []).has(ref)
	return false  # No choice, script, time or arbitrary branch in D2C.


static func _strict_integral_ordinal(value: Variant) -> int:
	if value is bool or not (value is int or value is float):
		return -1
	var numeric := float(value)
	if not is_finite(numeric) or numeric < 0.0 or floor(numeric) != numeric:
		return -1
	if numeric > 2147483646.0:
		return -1
	return int(numeric)


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
	var variants: Array = []
	for item in backgrounds:
		if item is Dictionary and item.get("backgroundId") == shot.get("backgroundId") and item.get("lighting") == shot.get("lighting") and item.get("roomState") == shot.get("roomState"):
			variants.append(item)
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
		# Stable line ordering is also the Continue/save boundary contract.
		if line_id != ("%s-L%03d" % [beat_id, ordered_line_ids.size() + 1]) or line_ids.has(line_id):
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
		if cue.get("manualReview") != false or cue.get("sceneId") != beat_id or cue.get("speakerId") != speaker:
			return {}
		if cue.get("portraitVisible") != true:
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
