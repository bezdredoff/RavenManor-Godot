extends SceneTree
## VNS5-06D2C: synthetic exact approved production route demonstrates
## canonical-only VN with art + 3 languages; defaults stay closed.
## Never modifies committed production, save keys or player's real saves.

const Runtime = preload("res://scripts/raven/raven_vn_runtime_dispatch.gd")
const Dialogue = preload("res://data/raven/production/season1_dialogue_catalog.json")
const Staging = preload("res://data/raven/production/vn_staging.json")
const Routes = preload("res://data/raven/production/map_narrative_routes.json")
const Cues = preload("res://data/raven/production/line_performance_cues.json")
const Foundation = preload("res://data/raven/foundation_catalog.json")
const Backgrounds = preload("res://data/raven/production/vn_background_catalog.json")
const Portraits = preload("res://data/raven/production/vn_character_catalog.json")
const Snapshot = preload("res://scripts/raven/raven_snapshot.gd")
const Reducer = preload("res://scripts/raven/raven_reducer.gd")
const Director = preload("res://scripts/raven/raven_slice_director.gd")
const VN = preload("res://scripts/raven/raven_vn_player.gd")
const Store = preload("res://scripts/raven/raven_campaign_store.gd")
const MemoryStorage = preload("res://tests/support/memory_storage.gd")

const BEAT := "RM-BEAT-07-01"
const LINE := "RM-BEAT-07-01-L001"


func _initialize() -> void:
	var canon := Snapshot.fresh()
	assert(Runtime.next_scene(canon).is_empty(), "Native main must not expose D1/D2B review-only scenes")
	assert(Director.next_step(canon).id == "letter", "Existing RM-VS-01 must remain unchanged")
	var data := _synthetic()
	var state := Snapshot.fresh()
	state.storyBeatsSeen.append("RM-BEAT-01-05")
	var ready: Dictionary = _find(data, state)
	assert(ready.get("beatId") == BEAT, "Only fully approved and eligible beat should launch")
	assert(ready.get("source") == "canonical_production_only")
	assert(ready.get("lineIds") == [LINE])
	assert(ready.lines.size() == 1)
	assert(ready.lines[0]["speaker"] == "Эвелин")
	assert(ready.lines[0]["text"] == "Тестовая фраза")
	assert(_find(data, state, "en").lines[0]["text"] == "Synthetic test line")
	assert(_find(data, state, "be").lines[0]["speaker"] == "Эвелін")
	var player := VN.new()
	player.open(ready)
	assert(player.current_line() == "Тестовая фраза")
	assert(player.current_speaker() == "Эвелин")
	assert(Runtime.completion_event(ready, false, "evt") == {})
	assert(Runtime.completion_event(ready, true, "") == {})
	assert(player.advance())
	var evt: Dictionary = Runtime.completion_event(ready, true, "d2c-test-1")
	assert(evt.type == "story_beat_seen" and evt.storyBeatId == BEAT)
	var result: Dictionary = Reducer.apply(state, evt, data.foundation)
	assert(result.ok and result.state.storyBeatsSeen.has(BEAT))
	var retry: Dictionary = Reducer.apply(result.state, evt, data.foundation)
	assert(retry.ok and retry.duplicate)
	assert(retry.state.revision == result.state.revision)
	assert(_find(data, result.state).is_empty(), "Completed scene cannot replay")
	var store := Store.new(MemoryStorage.new())
	# Real campaign snapshots preserve new IDs ONLY when foundation adds them.
	assert(Snapshot.normalize(result.state, data.foundation).storyBeatsSeen.has(BEAT))
	assert(not Snapshot.normalize(result.state, Foundation.data).storyBeatsSeen.has(BEAT))
	assert(not Store.new(MemoryStorage.new()).load_campaign().storyBeatsSeen.has(BEAT))
	assert(not store.load_campaign().storyBeatsSeen.has(BEAT))
	# Test actor/cue/shot/asset gates independently on deep copies.
	_assert_blocked(_mutate(data, "scene_status"))
	_assert_blocked(_mutate(data, "foundation"))
	_assert_blocked(_mutate(data, "route_flag"))
	_assert_blocked(_mutate(data, "route_proposed"))
	_assert_blocked(_mutate(data, "route_kind"))
	_assert_blocked(_mutate(data, "route_dependency"), state)
	_assert_blocked(_mutate(data, "missing_ru"))
	_assert_blocked(_mutate(data, "missing_be"))
	_assert_blocked(_mutate(data, "missing_en"))
	_assert_blocked(_mutate(data, "unapproved_background"))
	_assert_blocked(_mutate(data, "unknown_background"))
	_assert_blocked(_mutate(data, "missing_shot"))
	_assert_blocked(_mutate(data, "duplicate_shot"))
	_assert_blocked(_mutate(data, "missing_cue"))
	_assert_blocked(_mutate(data, "manual_cue"))
	_assert_blocked(_mutate(data, "unknown_speaker"))
	_assert_blocked(_mutate(data, "no_portrait"))
	_assert_blocked(_mutate(data, "unapproved_portrait"))
	_assert_blocked(_mutate(data, "unknown_line"))
	_assert_blocked(_mutate(data, "new_unknown_gate"))
	assert(Runtime.find_approved(state, "xyz", data.dialogue, data.routes, data.staging,
		data.cues, data.foundation, data.backgrounds, data.portraits).is_empty())
	# first_clear remains eligible ONLY after the canonical level win.
	var first_clear: Dictionary = _synthetic()
	first_clear.routes.sceneTriggers[-1].gate = {
		"kind": "first_clear", "ref": "RM-LVL-001",
		"approvedRuntime": true, "proposedRuntime": false}
	var without_level := Snapshot.fresh()
	assert(_find(first_clear, without_level).is_empty())
	without_level.firstClearLevels.append("RM-LVL-001")
	assert(_find(first_clear, without_level).get("beatId") == BEAT)
	# No new native resource or foundation entry is touched by smoke.
	assert(Runtime.next_scene(state).is_empty())
	assert(not Foundation.data.storyBeats.has(BEAT))
	print("Raven VN VNS5-06D2C approved-only runtime dispatch/save/locale/art smoke passed")
	quit()


func _synthetic() -> Dictionary:
	var data: Dictionary = {
		"dialogue": Dialogue.data.duplicate(true),
		"routes": Routes.data.duplicate(true),
		"staging": Staging.data.duplicate(true),
		"cues": Cues.data.duplicate(true),
		"foundation": Foundation.data.duplicate(true),
		"backgrounds": Backgrounds.data.duplicate(true),
		"portraits": Portraits.data.duplicate(true),
	}
	data.foundation.storyBeats.append(BEAT)
	data.dialogue.scenes.append({
		"sceneId": BEAT, "status": "runtime_approved",
		"title": {"ru":"Тестовая сцена","en":"Synthetic scene","be":"Тэставая сцэна"},
		"source": "synthetic_test_only"
	})
	data.dialogue.entries.append({
		"id":LINE, "sceneId":BEAT, "speakerId":"RM-CHAR-EVELYN", "delivery":"speech",
		"localized": {"ru":{"text":"Тестовая фраза"}, "en":{"text":"Synthetic test line"},
			"be":{"text":"Тэставая фраза"}}
	})
	data.routes.sceneTriggers.append({
		"sceneId":BEAT, "ordinal":900, "interactionTarget":"test-vn-only",
		"gate":{"kind":"scene_complete","ref":"RM-BEAT-01-05",
			"approvedRuntime":true,"proposedRuntime":false},
		"whenReached":"play_once_then_unlock_next_state",
		"postSceneAction":"record_story_beat_only_after_player_finishes_VN"
	})
	var bg: Dictionary = data.backgrounds.entries[0]
	bg.status = "accepted"
	bg.approved = "SYNTHETIC-QA-NOT-CANONICAL-APPROVAL"
	data.staging.sceneShots.append({
		"sceneId":BEAT, "backgroundId":bg.backgroundId, "lighting":bg.lighting,
		"roomState":bg.roomState, "visibleCount":1,
		"cast":[{"characterId":"RM-CHAR-EVELYN", "slot":"center",
			"pose":"relaxed", "emotion":"neutral", "micro":"evelyn_hair_tuck"}]
	})
	data.cues.cues.append({
		"lineId":LINE, "sceneId":BEAT, "speakerId":"RM-CHAR-EVELYN",
		"manualReview":false, "portraitVisible":true,
		"poseId":"relaxed", "emotionId":"neutral"
	})
	return data


func _find(data: Dictionary, state: Dictionary, locale: String = "ru") -> Dictionary:
	return Runtime.find_approved(state, locale, data.dialogue, data.routes, data.staging,
		data.cues, data.foundation, data.backgrounds, data.portraits)


func _assert_blocked(data: Dictionary, initial_state: Dictionary = {}) -> void:
	var state: Dictionary = Snapshot.fresh() if initial_state.is_empty() else initial_state
	if initial_state.is_empty():
		state.storyBeatsSeen.append("RM-BEAT-01-05")
	assert(_find(data, state).is_empty(), "Unsafe synthetic candidate accepted")


func _mutate(data: Dictionary, reason: String) -> Dictionary:
	var copy: Dictionary = data.duplicate(true)
	match reason:
		"scene_status": copy.dialogue.scenes[-1].status = "review_only_not_runtime"
		"foundation": copy.foundation.storyBeats.erase(BEAT)
		"route_flag": copy.routes.sceneTriggers[-1].gate.approvedRuntime = false
		"route_proposed": copy.routes.sceneTriggers[-1].gate.proposedRuntime = true
		"route_kind": copy.routes.sceneTriggers[-1].gate.kind = "custom_script"
		"route_dependency": copy.routes.sceneTriggers[-1].gate.ref = "RM-BEAT-00-03"
		"missing_ru": copy.dialogue.entries[-1].localized.ru.text = ""
		"missing_be": copy.dialogue.entries[-1].localized.be.text = ""
		"missing_en": copy.dialogue.entries[-1].localized.en.text = ""
		"unapproved_background": copy.backgrounds.entries[0].status = "candidate"
		"unknown_background": copy.staging.sceneShots[-1].backgroundId = "BG-NONE"
		"missing_shot": copy.staging.sceneShots.pop_back()
		"duplicate_shot": copy.staging.sceneShots.append(copy.staging.sceneShots[-1].duplicate(true))
		"missing_cue": copy.cues.cues.pop_back()
		"manual_cue": copy.cues.cues[-1].manualReview = true
		"unknown_speaker": copy.dialogue.entries[-1].speakerId = "RM-CHAR-UNKNOWN-VOICE"
		"no_portrait": copy.cues.cues[-1].portraitVisible = false
		"unapproved_portrait":
			for art: Dictionary in copy.portraits.entries:
				if art.characterId == "RM-CHAR-EVELYN" and art.pose == "relaxed" and art.emotion == "neutral":
					art.status = "candidate"
		"unknown_line": copy.dialogue.entries[-1].id = "RM-BEAT-07-01-L999"
		"new_unknown_gate": copy.routes.sceneTriggers[-1].gate.kind = "secret_cheat"
	return copy
