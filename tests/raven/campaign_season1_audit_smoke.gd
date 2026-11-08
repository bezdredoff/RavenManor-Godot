extends SceneTree
## CODE-08-01 Season 1 executability audit (read-only, bounded).
##
## Answers two separate questions with executable evidence:
##  1. Which of the 28 authored Season 1 scenes are actually playable today?
##     The only live path is RM-VS-01 (raven_slice_director.gd + vertical_slice.gd):
##     eight beats, played here through the real vertical_slice scene, the real
##     reducer/store and the real VN player, locale by locale.
##  2. For every other scene, which exact production gate refuses it?
##     Each blocker below is observed, not asserted from documentation: the
##     dialogue catalog status, the map_narrative_routes gate (evaluated by
##     RavenVNRuntimeDispatch._gate_satisfied itself), foundation story-beat
##     registration, and the staging/background/portrait/line-cue contract
##     evaluated by RavenVNRuntimeDispatch.build_config itself. The per-scene
##     blocker list is cross-checked against RavenVNRuntimeDispatch.find_approved,
##     and a synthetic approved copy acts as a positive control so this audit
##     cannot pass vacuously.
##
## Any change that makes a scene playable must update EXPECTED_EXECUTABLE and the
## CODE-08-01 change note on purpose; a silent divergence fails here.
const Content = preload("res://data/raven/rm_vs_01_content.json")
const Dialogue = preload("res://data/raven/production/season1_dialogue_catalog.json")
const Routes = preload("res://data/raven/production/map_narrative_routes.json")
const Staging = preload("res://data/raven/production/vn_staging.json")
const Cues = preload("res://data/raven/production/line_performance_cues.json")
const Backgrounds = preload("res://data/raven/production/vn_background_catalog.json")
const Portraits = preload("res://data/raven/production/vn_character_catalog.json")
const Foundation = preload("res://data/raven/foundation_catalog.json")
const Director = preload("res://scripts/raven/raven_slice_director.gd")
const Snapshot = preload("res://scripts/raven/raven_snapshot.gd")
const Reducer = preload("res://scripts/raven/raven_reducer.gd")
const Store = preload("res://scripts/raven/raven_campaign_store.gd")
const CatalogAdapter = preload("res://scripts/raven/raven_vn_catalog_adapter.gd")
const RuntimeDispatch = preload("res://scripts/raven/raven_vn_runtime_dispatch.gd")
const MemoryStorage = preload("res://tests/support/memory_storage.gd")

const LOCALES := ["ru", "be", "en"]
const SLOTS := ["left", "center", "right"]
const EXPECTED_SCENE_COUNT := 28
const EXPECTED_EXECUTABLE := [
	"RM-BEAT-00-01", "RM-BEAT-00-02", "RM-BEAT-00-03", "RM-BEAT-01-01",
	"RM-BEAT-01-02", "RM-BEAT-01-03", "RM-BEAT-01-04", "RM-BEAT-01-05",
]
const EXPECTED_STEPS := [
	"letter", "road", "gates", "arrival", "access", "level1", "restore1",
	"bedroom", "level2", "trace", "level3", "restore2", "clue", "night", "complete",
]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_audit_catalogs()
	var audit := _audit_scenes()
	_audit_positive_control()
	await _play_current_path()
	_report(audit)
	quit()


func _audit_catalogs() -> void:
	var scenes: Array = Dialogue.data.scenes
	assert(scenes.size() == EXPECTED_SCENE_COUNT, "Season 1 catalog must hold 28 authored scenes")
	var routes: Array = Routes.data.sceneTriggers
	assert(routes.size() == scenes.size(), "Every authored scene needs exactly one map route trigger")
	var seen := {}
	var ordinals := {}
	for scene: Dictionary in scenes:
		var id := str(scene.get("sceneId", ""))
		assert(not id.is_empty(), "Scene without a stable RM-BEAT id")
		assert(not seen.has(id), "Duplicate scene id " + id)
		seen[id] = true
		assert(scene.get("title", {}).get("ru", "").strip_edges() != "", id + " has no Russian title")
	var covered := {}
	for route: Dictionary in routes:
		var id := str(route.get("sceneId", ""))
		assert(seen.has(id), "Route for unknown scene " + id)
		assert(not covered.has(id), "Duplicate route for " + id)
		covered[id] = true
		var ordinal := int(route.get("ordinal", -1))
		assert(not ordinals.has(ordinal), "Duplicate route ordinal %d" % ordinal)
		ordinals[ordinal] = id
	assert(covered.size() == scenes.size(), "Route registry does not cover every scene")
	# The legacy RM-VS-01 content is the only executable playback path today.
	var legacy := {}
	for group in ["prologueScenes", "vnScenes"]:
		for key in Content.data[group]:
			var scene: Dictionary = Content.data[group][key]
			legacy[str(scene.get("beatId", ""))] = key
	assert(legacy.size() == EXPECTED_EXECUTABLE.size(), "Legacy runtime content must hold exactly eight scenes")
	for beat_id in EXPECTED_EXECUTABLE:
		assert(legacy.has(beat_id), "Legacy content lost executable beat " + beat_id)
		var catalog_status := ""
		for scene: Dictionary in scenes:
			if str(scene.get("sceneId", "")) == beat_id:
				catalog_status = str(scene.get("status", ""))
				assert(str(scene.get("legacyRuntimeScene", "")) == str(legacy[beat_id]),
					beat_id + " legacy scene key drifted from the dialogue catalog")
		assert(catalog_status == "already_runtime", beat_id + " is expected to be the already_runtime class")
	# The save layer only knows the foundation story beats; anything else is dropped.
	for beat_id in legacy:
		assert(Foundation.data.storyBeats.has(beat_id), beat_id + " is playable but unregistered in the save catalog")


func _audit_scenes() -> Array[Dictionary]:
	var known_scenes := {}
	for scene: Dictionary in Dialogue.data.scenes:
		known_scenes[str(scene.get("sceneId", ""))] = scene
	var legacy := {}
	for group in ["prologueScenes", "vnScenes"]:
		for key in Content.data[group]:
			legacy[str(Content.data[group][key].get("beatId", ""))] = key
	var audit: Array[Dictionary] = []
	var executable: Array[String] = []
	for scene: Dictionary in Dialogue.data.scenes:
		var beat_id := str(scene.get("sceneId", ""))
		var entry := {"sceneId": beat_id, "status": str(scene.get("status", "")),
			"playback": "none", "blockers": [] as Array[String]}
		if legacy.has(beat_id):
			entry.playback = "legacy_runtime"
			executable.append(beat_id)
		var blockers: Array[String] = []
		if entry.status != RuntimeDispatch.APPROVED_SCENE_STATUS:
			blockers.append("scene_status:" + entry.status)
		var route := _route_for(beat_id)
		if route.is_empty():
			blockers.append("route_missing")
		else:
			var gate: Variant = route.get("gate", {})
			assert(gate is Dictionary, beat_id + " route gate must be a dictionary")
			if gate.get("approvedRuntime") != true or gate.get("proposedRuntime") != false:
				blockers.append("route_gate_not_approved_runtime")
			# JSON resources decode every number as float; the dispatcher accepts
			# only int ordinals, so every route in this canonical registry is
			# currently refused before its gate is even evaluated.
			var ordinal: Variant = route.get("ordinal", -1)
			if typeof(ordinal) != TYPE_INT:
				blockers.append("route_ordinal_json_float:%s" % str(ordinal))
			# Same production predicate the runtime uses; a fully satisfied state
			# isolates "is this gate kind even supported" from "is it reached".
			var satisfied := _state_with_all_others_seen(beat_id)
			if not RuntimeDispatch._gate_satisfied(gate, satisfied, Foundation.data, known_scenes):
				blockers.append("gate_kind_unsupported:" + str(gate.get("kind", "")))
		if not Foundation.data.storyBeats.has(beat_id):
			blockers.append("story_beat_not_registered")
		var problems := _line_contract_problems(scene)
		for problem in problems:
			blockers.append("line_contract:" + problem)
		# The catalogs above are the audit's own reading; build_config is the
		# production reader. Disagreement means the audit is wrong, so fail loudly.
		var probe := scene.duplicate(true)
		probe["status"] = RuntimeDispatch.APPROVED_SCENE_STATUS
		var config: Dictionary = RuntimeDispatch.build_config(beat_id, "ru", probe,
			Dialogue.data.entries, Staging.data.sceneShots, Cues.data.cues,
			Backgrounds.data.entries, Portraits.data.entries)
		assert(config.is_empty() != problems.is_empty(),
			"%s: audit line-contract reading disagrees with build_config (%s vs %s)" %
			[beat_id, str(problems), str(config.get("beatId", "<build_config rejected>"))])
		entry.blockers = blockers
		var selected: Dictionary = RuntimeDispatch.find_approved(_state_with_all_others_seen(beat_id),
			"ru", Dialogue.data, Routes.data, Staging.data, Cues.data, Foundation.data,
			Backgrounds.data, Portraits.data)
		var selectable := str(selected.get("beatId", "")) == beat_id
		assert(selectable == blockers.is_empty(),
			"%s: dispatcher decision (%s) contradicts the recorded blockers %s" %
			[beat_id, str(selectable), str(blockers)])
		entry["selectable"] = selectable
		audit.append(entry)
	assert(audit.size() == EXPECTED_SCENE_COUNT, "Audit must classify every authored scene")
	assert(executable == EXPECTED_EXECUTABLE, "Executable scene set changed: " + str(executable))
	var blocked := 0
	for entry: Dictionary in audit:
		if entry.playback == "none":
			blocked += 1
			assert(not entry.blockers.is_empty(), entry.sceneId + " is unplayable but has no recorded blocker")
	assert(blocked == EXPECTED_SCENE_COUNT - EXPECTED_EXECUTABLE.size(),
		"Blocked scene count changed; update the CODE-08-01 audit note deliberately")
	# Nothing is currently selectable through the production dispatcher: no scene
	# is runtime_approved yet, so the legacy path is the only live campaign.
	for entry: Dictionary in audit:
		assert(not entry.selectable, entry.sceneId + " became production-selectable; re-audit needed")
	return audit


func _audit_positive_control() -> void:
	# RM-BEAT-00-02 is the closest scene to switch-over: approved route gate,
	# supported gate kind, complete art/line/cue contract, already reachable
	# story beat. Two independent things keep it off-screen, and both are proved
	# here instead of assumed, so this audit cannot pass vacuously.
	var target := "RM-BEAT-00-02"
	var approved: Dictionary = Dialogue.data.duplicate(true)
	var found := false
	for scene: Dictionary in approved.scenes:
		if str(scene.get("sceneId", "")) == target:
			scene["status"] = RuntimeDispatch.APPROVED_SCENE_STATUS
			found = true
	assert(found, "Positive-control scene missing from the catalog")
	var state: Dictionary = _state_with_all_others_seen(target)
	assert(not state.storyBeatsSeen.has(target))
	# Stage A: the canonical route registry is JSON, so every ordinal decodes as
	# float; the dispatcher's `ordinal is int` guard then refuses every route.
	assert(typeof(_route_for(target).get("ordinal", -1)) == TYPE_FLOAT,
		"Canonical route ordinals are expected to decode as JSON floats")
	var refused: Dictionary = RuntimeDispatch.find_approved(state, "ru", approved, Routes.data,
		Staging.data, Cues.data, Foundation.data, Backgrounds.data, Portraits.data)
	assert(refused.is_empty(),
		"With the real JSON route registry the dispatcher must still refuse a fully ready scene")
	# Stage B: int-typed ordinals only. Everything else stays canonical, so a
	# selection here proves the remaining defect is exactly the ordinal typing.
	var typed_routes: Dictionary = Routes.data.duplicate(true)
	for route: Dictionary in typed_routes.sceneTriggers:
		route["ordinal"] = int(route["ordinal"])
	var selected: Dictionary = RuntimeDispatch.find_approved(state, "ru", approved, typed_routes,
		Staging.data, Cues.data, Foundation.data, Backgrounds.data, Portraits.data)
	assert(str(selected.get("beatId", "")) == target,
		"%s must be selectable once its status and route ordinals are canonical" % target)
	assert(selected.get("source") == "canonical_production_only", "Positive control must be a production config")
	assert(selected.get("lines", []).size() > 0 and selected.get("lineIds", []).size() == selected.get("lines", []).size(),
		"Positive control must produce playable lines")
	for line: Dictionary in selected.lines:
		assert(not str(line.get("text", "")).strip_edges().is_empty(), "Positive control produced an empty line")


func _play_current_path() -> void:
	var adapter := MemoryStorage.new()
	var game := _spawn(adapter)
	await process_frame
	assert(game.step.get("kind") == "vn", "New campaign must start in the prologue VN")
	var visited: Array[String] = []
	var played: Array[String] = []
	var loops := 0
	while game.step.get("kind") != "done":
		loops += 1
		assert(loops <= 32, "Current campaign path did not terminate")
		var step: Dictionary = game.step
		visited.append(str(step.get("id", "")))
		match str(step.get("kind", "")):
			"vn":
				var beat_id := str(game.vn_player.scene.get("beatId", ""))
				assert(EXPECTED_EXECUTABLE.has(beat_id), "Runtime reached an unaudited scene " + beat_id)
				assert(not played.has(beat_id), beat_id + " replayed inside one campaign walk")
				played.append(beat_id)
				_assert_locale_copy(step, beat_id)
				var total: int = game.vn_player.scene.get("lines", []).size()
				assert(total > 0, beat_id + " has no lines")
				var advanced := 0
				while game.vn_player != null and str(game.vn_player.scene.get("beatId", "")) == beat_id:
					game._advance_vn()
					advanced += 1
					assert(advanced <= total + 1, beat_id + " did not finish after %d advances" % advanced)
				assert(advanced == total, "%s needed %d advances for %d lines" % [beat_id, advanced, total])
				assert(game.state.storyBeatsSeen.has(beat_id), beat_id + " was not recorded after playback")
			"match3":
				var level_id := str(step.get("level", ""))
				assert(game.match_game != null, level_id + " opened without a board")
				var moves := 0
				while str(game.match_game.state) == "playing":
					var hint: Dictionary = game.match_game.get_hint_move()
					assert(not hint.is_empty(), level_id + " has no playable move")
					var result: Dictionary = game.match_game.attempt_swap(int(hint.first), int(hint.second))
					assert(result.get("valid", false), level_id + " rejected a hint move")
					moves += 1
					assert(moves <= 64, level_id + " did not complete inside the board limit")
				assert(str(game.match_game.state) == "won", level_id + " ended without a win")
				game._complete_level()
				assert(game.state.firstClearLevels.has(level_id), level_id + " reward was not committed")
			_:
				game._complete_action()
		await process_frame
	assert(visited == EXPECTED_STEPS, "Current campaign path changed: " + str(visited))
	assert(played == EXPECTED_EXECUTABLE, "Playable scene set changed: " + str(played))
	assert(Director.next_step(game.state).get("id") == "done", "Campaign did not stay completed")
	assert(game.state.workPoints == 0, "Season 1 economy must end at zero work points")
	assert(game.state.completedRestorations.size() == 2, "Both first-stage restorations must be complete")
	assert(game.state.boosterInventory == {"hammer": 2, "shuffle": 2}, "Restoration boosters must be granted once")
	assert(game.state.recordedClues == ["RM-CLUE-01-CHILDHOOD-OBJECT"], "Story clue was not recorded")
	# The production dispatcher has nothing approved to continue with, in any locale.
	for locale in LOCALES:
		assert(RuntimeDispatch.next_scene(game.state, locale).is_empty(),
			"Production dispatch must stay empty until a scene is runtime_approved (" + locale + ")")
	# Persistence: the completed campaign must resume as completed.
	assert(Store.new(adapter).load_campaign().storyBeatsSeen.size() == EXPECTED_EXECUTABLE.size(),
		"Saved campaign lost story beats")
	assert(Director.next_step(Store.new(adapter).load_campaign()).get("id") == "done",
		"Saved campaign did not resume as completed")
	# Unregistered story beats cannot be persisted even if a reducer call accepted them.
	for beat_id in ["RM-BEAT-02-02", "RM-BEAT-06-POST"]:
		assert(not Foundation.data.storyBeats.has(beat_id), beat_id + " unexpectedly registered")
		var rejected: Dictionary = Reducer.apply(game.state,
			{"eventId": "audit-unregistered-" + beat_id, "type": "story_beat_seen", "storyBeatId": beat_id})
		assert(not rejected.get("ok", false) and rejected.get("error") == "unknown-story-beat",
			beat_id + " must be rejected by the save authority, not silently stored")
	game.queue_free()
	await process_frame


func _spawn(adapter: RefCounted) -> Control:
	var scene: PackedScene = load("res://scenes/raven/vertical_slice.tscn")
	assert(scene != null, "Vertical slice scene missing")
	var game: Control = scene.instantiate()
	game.store = Store.new(adapter)
	root.add_child(game)
	return game


## Every executable scene must localize through the catalogue adapter in RU/BE/EN.
func _assert_locale_copy(step: Dictionary, beat_id: String) -> void:
	var source: Dictionary = Content.data.get("prologueScenes", {}).get(str(step.get("scene", "")),
		Content.data.vnScenes.get(str(step.get("scene", "")), {}))
	assert(str(source.get("beatId", "")) == beat_id, beat_id + " source beat mismatch")
	var authored: int = source.get("lines", []).size()
	for locale in LOCALES:
		var config: Dictionary = CatalogAdapter.for_legacy(source, locale)
		var line_ids: Array = config.get("lineIds", [])
		assert(line_ids.size() == authored,
			"%s/%s did not resolve %d catalog lines" % [beat_id, locale, authored])
		var lines: Array = config.get("lines", [])
		assert(lines.size() == authored, beat_id + " lost lines in " + locale)
		for index in lines.size():
			assert(not str(lines[index].get("speaker", "")).strip_edges().is_empty(),
				"%s/%s line %d has no speaker" % [beat_id, locale, index])
			assert(not str(lines[index].get("text", "")).strip_edges().is_empty(),
				"%s/%s line %d has no text" % [beat_id, locale, index])


func _route_for(scene_id: String) -> Dictionary:
	for route: Dictionary in Routes.data.sceneTriggers:
		if str(route.get("sceneId", "")) == scene_id:
			return route
	return {}


func _state_with_all_others_seen(scene_id: String) -> Dictionary:
	var state: Dictionary = Snapshot.fresh()
	for scene: Dictionary in Dialogue.data.scenes:
		var id := str(scene.get("sceneId", ""))
		if id != scene_id and not state.storyBeatsSeen.has(id):
			state.storyBeatsSeen.append(id)
	for level_id in Foundation.data.levels:
		if not state.firstClearLevels.has(level_id):
			state.firstClearLevels.append(level_id)
	return state


## Concrete, human-readable reasons a scene's staging/art/line/cue contract is
## incomplete. Deliberately mirrors RavenVNRuntimeDispatch.build_config; the
## caller asserts the two agree for every scene.
func _line_contract_problems(scene: Dictionary) -> Array[String]:
	var problems: Array[String] = []
	var beat_id := str(scene.get("sceneId", ""))
	var title: Variant = scene.get("title", {})
	if not title is Dictionary or str(title.get("ru", "")).strip_edges().is_empty():
		problems.append("title_missing")
	var shots: Array = []
	for shot in Staging.data.sceneShots:
		if shot is Dictionary and shot.get("sceneId") == beat_id:
			shots.append(shot)
	if shots.size() != 1:
		problems.append("staging_shots=%d" % shots.size())
		return problems
	var shot: Dictionary = shots[0]
	var variants: Array = []
	for item in Backgrounds.data.entries:
		if item is Dictionary and item.get("backgroundId") == shot.get("backgroundId") \
				and item.get("lighting") == shot.get("lighting") \
				and item.get("roomState") == shot.get("roomState"):
			variants.append(item)
	if variants.size() != 1:
		problems.append("background_variants=%d" % variants.size())
	elif not _accepted_asset(variants[0], "res://assets/raven/vn_backgrounds/"):
		problems.append("background_not_accepted")
	var cast: Array = shot.get("cast", [])
	if cast.size() < 1 or cast.size() > 3:
		problems.append("cast_size=%d" % cast.size())
	if int(shot.get("visibleCount", -1)) != cast.size():
		problems.append("visible_count_mismatch")
	var cast_ids := {}
	var slots := {}
	for actor in cast:
		if not actor is Dictionary:
			problems.append("cast_entry_invalid")
			continue
		var character_id := str(actor.get("characterId", ""))
		var slot := str(actor.get("slot", ""))
		if character_id.is_empty() or cast_ids.has(character_id):
			problems.append("cast_character_invalid:" + character_id)
		cast_ids[character_id] = true
		if slot not in SLOTS or slots.has(slot):
			problems.append("cast_slot_invalid:" + slot)
		slots[slot] = true
		if not _portrait_ok(character_id, str(actor.get("pose", "")), str(actor.get("emotion", ""))):
			problems.append("portrait_missing:%s/%s/%s" % [character_id, str(actor.get("pose", "")), str(actor.get("emotion", ""))])
	var lines: Array = []
	for entry in Dialogue.data.entries:
		if entry is Dictionary and entry.get("sceneId") == beat_id:
			lines.append(entry)
	if lines.is_empty():
		problems.append("no_lines")
		return problems
	var line_ids := {}
	for line: Dictionary in lines:
		var line_id := str(line.get("id", ""))
		var speaker := str(line.get("speakerId", ""))
		if line_id.is_empty() or line_ids.has(line_id):
			problems.append("line_id_invalid:" + line_id)
		line_ids[line_id] = true
		if not cast_ids.has(speaker):
			problems.append("speaker_not_on_stage:%s:%s" % [line_id, speaker])
		var localized: Variant = line.get("localized", {})
		if not localized is Dictionary:
			problems.append("localized_missing:" + line_id)
		else:
			for locale in LOCALES:
				var cell: Variant = localized.get(locale)
				if not cell is Dictionary or str(cell.get("text", "")).strip_edges().is_empty():
					problems.append("locale_missing:%s:%s" % [line_id, locale])
		var line_cues: Array = []
		for cue in Cues.data.cues:
			if cue is Dictionary and cue.get("lineId") == line_id:
				line_cues.append(cue)
		if line_cues.size() != 1:
			problems.append("cues=%d:%s" % [line_cues.size(), line_id])
			continue
		var cue: Dictionary = line_cues[0]
		if cue.get("sceneId") != beat_id or cue.get("speakerId") != speaker:
			problems.append("cue_scene_or_speaker_mismatch:" + line_id)
		if cue.get("manualReview") != false:
			problems.append("cue_needs_manual_review:" + line_id)
		if cue.get("portraitVisible") != true:
			problems.append("cue_portrait_hidden:" + line_id)
		if not _portrait_ok(speaker, str(cue.get("poseId", "")), str(cue.get("emotionId", ""))):
			problems.append("cue_portrait_missing:" + line_id)
	return problems


func _portrait_ok(character_id: String, pose: String, emotion: String) -> bool:
	for variant in Portraits.data.entries:
		if variant is Dictionary and variant.get("characterId") == character_id \
				and variant.get("pose") == pose and variant.get("emotion") == emotion \
				and bool(variant.get("defaultForPose", false)) \
				and _accepted_asset(variant, "res://assets/raven/characters/"):
			return true
	return false


func _accepted_asset(asset: Dictionary, root_path: String) -> bool:
	var path: Variant = asset.get("path")
	return asset.get("status") == RuntimeDispatch.APPROVED_ART_STATUS \
		and asset.get("approved") is String and not str(asset.get("approved")).strip_edges().is_empty() \
		and path is String and str(path).begins_with(root_path) and not str(path).contains("..") \
		and ResourceLoader.exists(str(path))


func _report(audit: Array[Dictionary]) -> void:
	var playable := 0
	for index in audit.size():
		var entry: Dictionary = audit[index]
		if entry.playback == "legacy_runtime":
			playable += 1
		var reasons := "none" if entry.blockers.is_empty() else ";".join(entry.blockers)
		print("AUDIT %02d/28 %s status=%s playback=%s dispatch=%s reasons=%s" % [
			index + 1, entry.sceneId, entry.status, entry.playback,
			"selectable" if entry.selectable else "blocked", reasons])
	print("AUDIT summary scenes=28 playable=%d blocked=%d production_selectable=0" % [
		playable, audit.size() - playable])
	print("Raven Manor campaign Season 1 audit passed")
