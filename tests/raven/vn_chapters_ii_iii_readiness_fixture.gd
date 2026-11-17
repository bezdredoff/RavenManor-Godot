extends RefCounted
## VN-RUNTIME-01: review-only Chapter II-III contract and canonical Hall Tea
## regression. Invoked by the already-registered D2C smoke. All approvals,
## portraits and routes below are synthetic deep copies; never persisted.
const Runtime = preload("res://scripts/raven/raven_vn_runtime_dispatch.gd")
const Dialogue = preload("res://data/raven/production/season1_dialogue_catalog.json")
const Routes = preload("res://data/raven/production/map_narrative_routes.json")
const Staging = preload("res://data/raven/production/vn_staging.json")
const Cues = preload("res://data/raven/production/line_performance_cues.json")
const Foundation = preload("res://data/raven/foundation_catalog.json")
const Backgrounds = preload("res://data/raven/production/vn_background_catalog.json")
const Portraits = preload("res://data/raven/production/vn_character_catalog.json")
const Readiness = preload("res://data/raven/production/vn_chapters_ii_iii_readiness.json")
const Copy = preload("res://scripts/raven/raven_production_localization.gd")
const ReadHistory = preload("res://scripts/raven/raven_vn_read_history.gd")
const VN = preload("res://scripts/raven/raven_vn_player.gd")
const Snapshot = preload("res://scripts/raven/raven_snapshot.gd")
const Reducer = preload("res://scripts/raven/raven_reducer.gd")
const Store = preload("res://scripts/raven/raven_campaign_store.gd")
const Memory = preload("res://tests/support/memory_storage.gd")

const BEAT := "RM-BEAT-02-01"
const PREVIOUS := "RM-BEAT-01-05"
const LOCALES := ["ru", "be", "en"]


static func run() -> void:
	_verify_readiness_manifest()
	_verify_hall_tea_fixture()


## Guard the handoff against source drift. This manifest is review-only data,
## never a new selection/approval or story-state authority.
static func _verify_readiness_manifest() -> void:
	assert(Readiness.data.kind == "vn_chapters_ii_iii_scene_readiness_review_only")
	assert(Readiness.data.runtimePromotion == false)
	assert(Readiness.data.firstPlayableCandidate == BEAT)
	assert(Readiness.data.scenes.size() == 8)
	var line_total := 0
	var missing_cue_total := 0
	var scene_ids := {}
	for record: Dictionary in Readiness.data.scenes:
		var id: String = str(record.get("sceneId", ""))
		assert(id.begins_with("RM-BEAT-02-") or id.begins_with("RM-BEAT-03-"))
		assert(not scene_ids.has(id))
		scene_ids[id] = true
		var scene: Dictionary = {}
		var route: Dictionary = {}
		var shot: Dictionary = {}
		for entry: Dictionary in Dialogue.data.scenes:
			if entry.sceneId == id:
				scene = entry
		for entry: Dictionary in Routes.data.sceneTriggers:
			if entry.sceneId == id:
				route = entry
		for entry: Dictionary in Staging.data.sceneShots:
			if entry.sceneId == id:
				assert(shot.is_empty(), id + ": multiple shots")
				shot = entry
		assert(not scene.is_empty() and not route.is_empty() and not shot.is_empty())
		assert(record.catalogStatus == scene.status and record.catalogStatus != "runtime_approved")
		assert(record.ordinal == route.ordinal)
		assert(record.interactionTarget == route.interactionTarget)
		assert(record.gate.kind == route.gate.kind and record.gate.ref == route.gate.ref)
		assert(record.gate.approvedRuntime == false and route.gate.approvedRuntime == false)
		assert(record.gate.proposedRuntime == true and route.gate.proposedRuntime == true)
		assert(record.saveBeatRegistered == Foundation.data.storyBeats.has(id))
		assert(record.background.backgroundId == shot.backgroundId)
		assert(record.background.lighting == shot.lighting)
		assert(record.background.roomState == shot.roomState)
		assert(record.cast == shot.cast)
		var background_count := 0
		for asset: Dictionary in Backgrounds.data.entries:
			if asset.backgroundId == shot.backgroundId and asset.lighting == shot.lighting and asset.roomState == shot.roomState:
				background_count += 1
				assert(asset.path == record.background.path and asset.status == "accepted")
				assert(ResourceLoader.exists(str(asset.path)), id + ": accepted background file missing")
		assert(background_count == 1 and record.backgroundMatches == 1)
		var cast_ids := {}
		for actor: Dictionary in shot.cast:
			cast_ids[str(actor.characterId)] = true
		var lines: Array = []
		for line: Dictionary in Dialogue.data.entries:
			if line.sceneId == id:
				lines.append(line)
		assert(lines.size() == record.lineCount and lines.size() == record.lineIds.size())
		line_total += lines.size()
		var missing_keys := {}
		for actor: Dictionary in shot.cast:
			if not Runtime._has_art(str(actor.characterId), str(actor.pose), str(actor.emotion), Portraits.data.entries):
				missing_keys["%s/%s/%s" % [actor.characterId, actor.pose, actor.emotion]] = true
		var missing_cue_ids: Array = []
		var scene_cues: Array = []
		for cue: Dictionary in Cues.data.cues:
			if cue.sceneId == id:
				scene_cues.append(cue)
				if not Runtime._has_art(str(cue.speakerId), str(cue.poseId), str(cue.emotionId), Portraits.data.entries):
					missing_keys["%s/%s/%s" % [cue.speakerId, cue.poseId, cue.emotionId]] = true
					missing_cue_ids.append(str(cue.lineId))
		assert(scene_cues.size() == record.cueCount and scene_cues.size() == lines.size())
		var captured_ids: Array = []
		for index in lines.size():
			var line: Dictionary = lines[index]
			assert(line.id == record.lineIds[index], id + ": line order drift")
			assert(cast_ids.has(str(line.speakerId)), line.id + ": offstage speaker")
			for locale in LOCALES:
				assert(line.localized.get(locale) is Dictionary and str(line.localized[locale].get("text", "")).strip_edges() != "",
					line.id + ": missing " + locale)
			var matches := 0
			for cue: Dictionary in scene_cues:
				if cue.lineId == line.id:
					matches += 1
					assert(cue.speakerId == line.speakerId)
					assert(cue.manualReview == false and cue.portraitVisible == true)
			assert(matches == 1, line.id + ": cue cardinality")
			captured_ids.append(str(line.id))
		for locale in LOCALES:
			assert(record.localeLineCounts.get(locale, -1) == lines.size(), id + ": missing locale cells")
			assert(str(scene.title.get(locale, "")).strip_edges() != "", id + ": missing title")
		var observed_missing: Array = missing_keys.keys()
		observed_missing.sort()
		var recorded_missing: Array = []
		for portrait: Dictionary in record.missingPortraitVariants:
			recorded_missing.append("%s/%s/%s" % [portrait.characterId, portrait.pose, portrait.emotion])
		recorded_missing.sort()
		assert(observed_missing == recorded_missing, id + ": portrait gap manifest drift")
		missing_cue_ids.sort()
		var recorded_cues: Array = record.missingCuePortraitLineIds.duplicate()
		recorded_cues.sort()
		assert(missing_cue_ids == recorded_cues, id + ": missing cue art list drift")
		missing_cue_total += missing_cue_ids.size()
		assert(record.cueManualReviewLineIds.is_empty() and record.cueHiddenLineIds.is_empty())
	assert(scene_ids.size() == 8)
	assert(line_total == 96 and Readiness.data.summary.canonicalLineCount == line_total)
	assert(missing_cue_total == 43 and Readiness.data.summary.missingCuePortraitOccurrences == missing_cue_total)


static func _verify_hall_tea_fixture() -> void:
	var clean: Dictionary = Snapshot.fresh()
	var after_slice: Dictionary = Snapshot.fresh()
	after_slice.storyBeatsSeen.append(PREVIOUS)
	# Real canonical production stays unavailable even after RM-VS-01.
	for locale in LOCALES:
		assert(Runtime.next_scene(after_slice, locale).is_empty())
		assert(Runtime.next_scene(clean, locale).is_empty())

	var fixture := _synthetic_hall_tea()
	assert(_find(fixture, clean).is_empty(), "Hall Tea started without predecessor")
	assert(_find(fixture, after_slice, "ru", "other_hotspot").is_empty(),
		"Hall Tea launched after arrival at an unrelated hotspot")
	assert(_find(fixture, after_slice, "ru", "", true).is_empty(),
		"Physically triggered Hall Tea launched through automatic Continue")
	# The production entrypoint rejects null/forged map hosts, rather than
	# allowing UI-provided flags to pass as a verified physical arrival.
	assert(Runtime.next_scene_at_confirmed_hotspot(null, "hall_chair_table").is_empty())
	var unverified_host := Node2D.new()
	assert(Runtime.next_scene_at_confirmed_hotspot(unverified_host, "hall_chair_table").is_empty())
	unverified_host.free()
	var ids: Array = []
	for locale in LOCALES:
		var config: Dictionary = _find(fixture, after_slice, locale, "hall_chair_table")
		assert(config.get("sceneId") == BEAT and config.get("source") == "canonical_production_only")
		assert(config.get("interactionTarget") == "hall_chair_table" and config.get("ordinal") == 8)
		assert(config.lines.size() == 12 and config.lineIds.size() == 12)
		if ids.is_empty():
			ids = config.lineIds.duplicate()
		assert(ids == config.lineIds, "Locale must not change canonical line IDs")
		var index := 0
		for entry: Dictionary in Dialogue.data.entries:
			if entry.sceneId != BEAT:
				continue
			assert(config.lineIds[index] == entry.id)
			assert(config.lines[index].text == entry.localized[locale].text, "Accidental locale fallback")
			assert(config.lines[index].speaker == Copy.speaker_name(str(entry.speakerId), locale))
			index += 1
		assert(index == 12)
		var player := VN.new()
		player.open(config)
		assert(Runtime.completion_event(config, false, "not-finished").is_empty())
		for line_index in config.lines.size():
			assert(player.current_line() == config.lines[line_index].text)
			assert(player.current_speaker() == config.lines[line_index].speaker)
			assert(player.advance() == (line_index == config.lines.size() - 1))
		assert(Runtime.completion_event(config, true, "").is_empty())
		var event: Dictionary = Runtime.completion_event(config, true, "vn-runtime-01-" + locale)
		assert(event.type == "story_beat_seen" and event.storyBeatId == BEAT)
		var applied: Dictionary = Reducer.apply(after_slice, event, Foundation.data)
		assert(applied.ok and applied.state.storyBeatsSeen.has(BEAT))
		var duplicate: Dictionary = Reducer.apply(applied.state, event, Foundation.data)
		assert(duplicate.ok and duplicate.duplicate and duplicate.state.revision == applied.state.revision)
		assert(_find(fixture, applied.state, locale).is_empty(), "Completed scene replayed")
		var stored := Store.new(Memory.new())
		assert(stored.save_campaign(applied.state))
		assert(stored.load_campaign().storyBeatsSeen.has(BEAT))

		# Existing Raven/UPDS read-only Skip boundary, using real Hall Tea IDs.
		assert(ReadHistory.skip_target(config, 0, []) == 0)
		assert(ReadHistory.skip_target(config, 0, ids.slice(0, 2)) == 2)
		assert(ReadHistory.skip_target(config, 0, ids) == 0, "Skip may not finish a scene")
		var choice: Dictionary = config.duplicate(true)
		choice.choiceGate = {"checkpointLineId": ids[1]}
		assert(ReadHistory.skip_target(choice, 0, ids.slice(0, 3)) == 1)
		choice.erase("choiceGate")
		choice.match3Gate = {"checkpointLineId": ids[1]}
		assert(ReadHistory.skip_target(choice, 0, ids.slice(0, 3)) == 1)
		var mid: Dictionary = after_slice.duplicate(true)
		mid.vnCursor = {"beatId": BEAT, "lineIndex": 2}
		ReadHistory.mark_read(mid, str(ids[0]))
		ReadHistory.mark_read(mid, str(ids[1]))
		var memory_store := Store.new(Memory.new())
		assert(memory_store.save_campaign(mid))
		var restored: Dictionary = memory_store.load_campaign()
		assert(restored.vnCursor == mid.vnCursor and restored.vnReadLines == ids.slice(0, 2))
		var reopened := VN.new()
		reopened.open(config)
		reopened.line_index = int(restored.vnCursor.lineIndex)
		assert(reopened.current_line() == config.lines[2].text, "Synthetic Continue line mismatch")
		assert(ReadHistory.skip_target(config, reopened.line_index, restored.vnReadLines) == 2)

	# Every synthetic override is needed; none can bypass an unknown interaction.
	var unsafe: Dictionary = _synthetic_hall_tea()
	for route: Dictionary in unsafe.routes.sceneTriggers:
		if route.sceneId == BEAT:
			route.gate.kind = "npc_tap"
	assert(_find(unsafe, after_slice).is_empty(), "Unsupported NPC gate bypassed")
	unsafe = _synthetic_hall_tea()
	for route: Dictionary in unsafe.routes.sceneTriggers:
		if route.sceneId == BEAT:
			route.gate.approvedRuntime = false
	assert(_find(unsafe, after_slice).is_empty(), "Unapproved route launched")
	unsafe = _synthetic_hall_tea()
	for scene: Dictionary in unsafe.dialogue.scenes:
		if scene.sceneId == BEAT:
			scene.status = "pilot_runtime"
	assert(_find(unsafe, after_slice).is_empty(), "Unapproved status launched")
	unsafe = _synthetic_hall_tea()
	unsafe.portraits.entries.pop_back()
	assert(_find(unsafe, after_slice).is_empty(), "Absent Ada variant launched")
	unsafe = _synthetic_hall_tea()
	for line: Dictionary in unsafe.dialogue.entries:
		if line.sceneId == BEAT:
			line.localized.be.text = ""
			break
	assert(_find(unsafe, after_slice).is_empty(), "Missing BE cell fell back silently")
	unsafe = _synthetic_hall_tea()
	for cue: Dictionary in unsafe.cues.cues:
		if cue.sceneId == BEAT:
			cue.manualReview = true
			break
	assert(_find(unsafe, after_slice).is_empty(), "Manual cue bypassed")
	unsafe = _synthetic_hall_tea()
	for route: Dictionary in unsafe.routes.sceneTriggers:
		if route.sceneId == BEAT:
			route.ordinal = 8.5
	assert(_find(unsafe, after_slice).is_empty(), "Fractional route ordinal accepted")
	# Verify test-only art/route/status mutation never changed the live registry.
	assert(Runtime.next_scene(after_slice).is_empty())
	for scene: Dictionary in Dialogue.data.scenes:
		if scene.sceneId == BEAT:
			assert(scene.status == "pilot_runtime")


static func _find(data: Dictionary, state: Dictionary, locale: String = "ru",
		arrived_target: String = "", auto_only: bool = false) -> Dictionary:
	return Runtime.find_approved(state, locale, data.dialogue, data.routes, data.staging,
		data.cues, data.foundation, data.backgrounds, data.portraits, arrived_target, auto_only)


static func _synthetic_hall_tea() -> Dictionary:
	var data := {
		"dialogue": Dialogue.data.duplicate(true),
		"routes": Routes.data.duplicate(true),
		"staging": Staging.data.duplicate(true),
		"cues": Cues.data.duplicate(true),
		"foundation": Foundation.data.duplicate(true),
		"backgrounds": Backgrounds.data.duplicate(true),
		"portraits": Portraits.data.duplicate(true),
	}
	for scene: Dictionary in data.dialogue.scenes:
		if scene.sceneId == BEAT:
			scene.status = "runtime_approved"  # Synthetic copy, never canonical.
	for route: Dictionary in data.routes.sceneTriggers:
		if route.sceneId == BEAT:
			route.gate.approvedRuntime = true
			route.gate.proposedRuntime = false
	# Exact offer_tray/dry_amused art is *not* approved. The synthetic test
	# temporarily aliases Ada's accepted composed/dry_amused asset path in a
	# deep-copied catalog. It proves selection mechanics, NOT visual readiness.
	var candidate: Dictionary = {}
	for art: Dictionary in data.portraits.entries:
		if art.characterId == "RM-CHAR-ADA" and art.pose == "composed" and art.emotion == "dry_amused" \
				and art.defaultForPose == true and art.status == "accepted":
			candidate = art.duplicate(true)
			break
	assert(not candidate.is_empty(), "Expected accepted Ada source art unavailable")
	candidate.id = "SYNTHETIC-TEST-ONLY-ADA-TRAY"
	candidate.pose = "offer_tray"
	candidate.emotion = "dry_amused"
	candidate.syntheticOnly = true
	data.portraits.entries.append(candidate)
	return data
