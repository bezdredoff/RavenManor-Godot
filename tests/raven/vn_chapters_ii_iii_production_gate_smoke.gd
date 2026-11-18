extends SceneTree
## GAME-QA-03 / registered GAME-QA-01 follow-up.
## Independent QA-only smoke. No canonical catalog, gameplay host, runner,
## scene or persistent user:// mutation. Future positive cases are SYNTHETIC.
const Dialogue = preload("res://data/raven/production/season1_dialogue_catalog.json")
const Staging = preload("res://data/raven/production/vn_staging.json")
const Cues = preload("res://data/raven/production/line_performance_cues.json")
const Routes = preload("res://data/raven/production/map_narrative_routes.json")
const Portraits = preload("res://data/raven/production/vn_character_catalog.json")
const Backgrounds = preload("res://data/raven/production/vn_background_catalog.json")
const Foundation = preload("res://data/raven/foundation_catalog.json")
const Readiness = preload("res://data/raven/production/vn_chapters_ii_iii_readiness.json")
const Source = preload("res://scripts/raven/manor_navigation_source.gd")
const Host = preload("res://scripts/raven/raven_gameplay_host.gd")
const Runtime = preload("res://scripts/raven/raven_vn_runtime_dispatch.gd")
const VN = preload("res://scripts/raven/raven_vn_player.gd")
const ReadHistory = preload("res://scripts/raven/raven_vn_read_history.gd")
const Copy = preload("res://scripts/raven/raven_production_localization.gd")
const Snapshot = preload("res://scripts/raven/raven_snapshot.gd")
const Reducer = preload("res://scripts/raven/raven_reducer.gd")
const Store = preload("res://scripts/raven/raven_campaign_store.gd")
const Memory = preload("res://tests/support/memory_storage.gd")
const SaveContract = preload("res://data/save_contract.json")

const SCENES := [
    "RM-BEAT-02-01", "RM-BEAT-02-02", "RM-BEAT-02-03", "RM-BEAT-02-04",
    "RM-BEAT-03-01", "RM-BEAT-03-02", "RM-BEAT-03-03", "RM-BEAT-03-04"
]
const LOCALES := ["ru", "be", "en"]
const TEA := "RM-BEAT-02-01"
const PREVIOUS := "RM-BEAT-01-05"


func _initialize() -> void:
    call_deferred("_run")


func _run() -> void:
    _audit_accepted_portraits()
    _audit_chapter_canon()
    _verify_live_production_closed_paths()
    _synthetic_hall_tea_positive_and_negative()
    _isolation_and_save_failures()
    print("GAME-QA-03 Chapter II-III source contract and SYNTHETIC Hall Tea smoke PASS; production Chapter II-III acceptance NOT claimed")
    quit()


## An accepted file/hash cannot be silently relabelled as another pose/emotion.
## Existing prop-specific non-default entries are legal, but do not satisfy cues.
func _audit_accepted_portraits() -> void:
    var paths := {}
    var hashes := {}
    var ids := {}
    for art: Dictionary in Portraits.data.entries:
        var id := str(art.get("id", ""))
        assert(not id.is_empty() and not ids.has(id), "Duplicate portrait ID: " + id)
        ids[id] = true
        if art.get("status") != "accepted":
            continue
        assert(art.get("defaultForPose") is bool, id + ": no defaultForPose declaration")
        var path := str(art.get("path", ""))
        var hash := str(art.get("provenance", {}).get("sha256", ""))
        assert(path.begins_with("res://assets/raven/characters/") and not path.contains(".."))
        assert(hash.length() == 64, id + ": missing accepted provenance SHA-256")
        assert(not paths.has(path), id + ": existing asset path reused under a second portrait identity")
        assert(not hashes.has(hash), id + ": accepted pixel hash reused under a second portrait identity")
        assert(ResourceLoader.exists(path), id + ": accepted asset not importable")
        paths[path] = id
        hashes[hash] = id


func _exact_art(character: String, pose: String, emotion: String, variants: Array) -> Dictionary:
    var found: Dictionary = {}
    for art: Dictionary in variants:
        if art.get("characterId") != character or art.get("pose") != pose or art.get("emotion") != emotion:
            continue
        if art.get("status") != "accepted" or art.get("defaultForPose") != true:
            continue
        assert(found.is_empty(), "Ambiguous accepted default: %s/%s/%s" % [character, pose, emotion])
        assert(str(art.get("approved", "")).strip_edges() != "")
        assert(ResourceLoader.exists(str(art.get("path", ""))))
        found = art
    return found


func _audited_requirement(character: String, pose: String, emotion: String, missing: Dictionary) -> void:
    assert(character.begins_with("RM-CHAR-") and not pose.is_empty() and not emotion.is_empty())
    if _exact_art(character, pose, emotion, Portraits.data.entries).is_empty():
        missing["%s/%s/%s" % [character, pose, emotion]] = true


## Counts and exact line IDs are canonical; missing-art *counts* are not pinned.
## The audit must pass on current main, and naturally reach zero after Agent A's
## staging/cue substitutions without pretending an old gap manifest is live.
func _audit_chapter_canon() -> void:
    assert(Readiness.data.scenes.size() == SCENES.size())
    var missing := {}
    var cue_missing_count := 0
    var line_total := 0
    var cue_total := 0
    for id: String in SCENES:
        var matching_scenes: Array = Dialogue.data.scenes.filter(func(x): return x.get("sceneId") == id)
        var matching_shots: Array = Staging.data.sceneShots.filter(func(x): return x.get("sceneId") == id)
        var matching_routes: Array = Routes.data.sceneTriggers.filter(func(x): return x.get("sceneId") == id)
        assert(matching_scenes.size() == 1 and matching_shots.size() == 1 and matching_routes.size() == 1, id)
        var scene_missing := {}
        var scene: Dictionary = matching_scenes[0]
        var shot: Dictionary = matching_shots[0]
        var route: Dictionary = matching_routes[0]
        assert(route.get("postSceneAction") == "record_story_beat_only_after_player_finishes_VN")
        assert(route.get("whenReached") == "play_once_then_unlock_next_state")
        assert(shot.cast.size() == int(shot.visibleCount))
        var actors := {}
        var slots := {}
        for actor: Dictionary in shot.cast:
            var character := str(actor.get("characterId", ""))
            var slot := str(actor.get("slot", ""))
            assert(not actors.has(character) and not slots.has(slot), id + ": invalid staging cast")
            actors[character] = true
            slots[slot] = true
            _audited_requirement(character, str(actor.get("pose", "")), str(actor.get("emotion", "")), missing)
            _audited_requirement(character, str(actor.get("pose", "")), str(actor.get("emotion", "")), scene_missing)
        var backgrounds: Array = Backgrounds.data.entries.filter(func(x):
            return x.get("backgroundId") == shot.backgroundId and x.get("lighting") == shot.lighting and x.get("roomState") == shot.roomState)
        assert(backgrounds.size() == 1 and backgrounds[0].get("status") == "accepted")
        assert(ResourceLoader.exists(str(backgrounds[0].path)), id + ": missing approved background")
        var lines: Array = Dialogue.data.entries.filter(func(x): return x.get("sceneId") == id)
        var cues: Array = Cues.data.cues.filter(func(x): return x.get("sceneId") == id)
        assert(lines.size() > 0 and cues.size() == lines.size(), id + ": line/cue mismatch")
        line_total += lines.size()
        cue_total += cues.size()
        for i in range(lines.size()):
            var line: Dictionary = lines[i]
            assert(line.id == ("%s-L%03d" % [id, i + 1]), id + ": Save/Continue line-order drift")
            assert(actors.has(str(line.speakerId)), line.id + ": offstage or wrong speaker")
            for lang in LOCALES:
                assert(str(scene.title.get(lang, "")).strip_edges() != "")
                assert(line.localized.get(lang) is Dictionary and str(line.localized[lang].get("text", "")).strip_edges() != "", line.id + ": missing " + lang)
            var line_cues: Array = cues.filter(func(x): return x.get("lineId") == line.id)
            assert(line_cues.size() == 1, line.id + ": wrong cue cardinality")
            var cue: Dictionary = line_cues[0]
            assert(cue.get("speakerId") == line.speakerId and cue.get("portraitVisible") == true)
            assert(cue.get("manualReview") == false, line.id + ": unreviewed cue")
            var exact := _exact_art(str(cue.speakerId), str(cue.poseId), str(cue.emotionId), Portraits.data.entries)
            if exact.is_empty():
                cue_missing_count += 1
            _audited_requirement(str(cue.speakerId), str(cue.poseId), str(cue.emotionId), missing)
            _audited_requirement(str(cue.speakerId), str(cue.poseId), str(cue.emotionId), scene_missing)
        # A route/scene approved independently of art must still fail closed.
        if scene.status == "runtime_approved" and route.gate.get("approvedRuntime") == true:
            var seeded := _completed_chapter_i()
            var ready := Runtime.find_approved(seeded, "ru", Dialogue.data, Routes.data,
                Staging.data, Cues.data, Foundation.data, Backgrounds.data, Portraits.data,
                str(route.interactionTarget))
            if not scene_missing.is_empty() and id == TEA:
                assert(ready.is_empty(), "Live Hall Tea bypassed missing accepted portrait")
    assert(line_total == 96 and cue_total == 96, "Expected 96 canonical lines/cues across Chapters II-III")
    print("GAME-QA-03 source audit: %d lines x 3 locales; %d distinct unresolved pose/emotion keys; %d cue occurrences (live catalogs)" %
        [line_total, missing.size(), cue_missing_count])
    if missing.is_empty():
        print("GAME-QA-03 portrait contract: zero currently missing variants; physical/owner acceptance remains separate")
    else:
        var report: Array = missing.keys()
        report.sort()
        print("GAME-QA-03 CURRENT ART BLOCKERS (not test failures while scenes are review-only): ", report)


func _production_request() -> Dictionary:
    return {"schemaVersion": 1, "kind": Source.REQUEST_KIND, "mode": Source.MODE_PRODUCTION}


func _verify_live_production_closed_paths() -> void:
    var production: Dictionary = Source.resolve(_production_request())
    assert(production.get("ok", false), "G2 actual approved default production source must resolve")
    assert(production.get("mode") == "production" and production.get("draftOnly") == false)
    assert(production.get("source", {}).get("kind") == "canonical-world-plan")
    var host = Host.new(Memory.new())
    root.add_child(host)
    assert(host.configure(_production_request()).get("ok", false), "Real host must consume default production source")
    assert(host.source.get("draftOnly") == false and host.source.get("mode") == "production")
    assert(Runtime.next_scene_at_confirmed_hotspot(null, "RM-HS-TEA-TABLE").is_empty())
    assert(Runtime.next_scene_at_confirmed_hotspot(host, "RM-HS-UNKNOWN").is_empty())
    # Initial safe Hall spawn is NOT a confirmed tea-table arrival.
    assert(Runtime.next_scene_at_confirmed_hotspot(host, "RM-HS-TEA-TABLE").is_empty(),
        "Spawn must not count as physically confirmed Hall Tea")
    assert(Runtime.next_scene_at_confirmed_hotspot(host, "hall_chair_table").is_empty(),
        "Scene target string cannot substitute for authored hotspot arrival")
    assert(not host.navigation.request_screen_point(Vector2(950, 530)).get("ok", false),
        "No unapproved free tap-to-move")
    host.queue_free()


func _completed_chapter_i() -> Dictionary:
    var state: Dictionary = Snapshot.fresh()
    for id: String in ["RM-BEAT-00-01", "RM-BEAT-00-02", "RM-BEAT-00-03", "RM-BEAT-01-01", "RM-BEAT-01-02", "RM-BEAT-01-03", "RM-BEAT-01-04", PREVIOUS]:
        var result: Dictionary = Reducer.apply(state, {
            "type": "story_beat_seen", "storyBeatId": id, "eventId": "game-qa-03-prereq-" + id})
        assert(result.get("ok", false), id + ": required Chapter I beat missing from Foundation")
        state = result.state
    return state


## Only the COPIES of staging and cues are translated to actual accepted pose
## metadata. Not a new "offer_tray/dry_amused" catalog entry or cloned pixels.
func _best_existing_art(character: String, pose: String, emotion: String, variants: Array) -> Dictionary:
    var best: Dictionary = {}
    var best_score := -1
    for art: Dictionary in variants:
        if art.get("characterId") != character or art.get("status") != "accepted" or art.get("defaultForPose") != true:
            continue
        var score := 0
        if art.get("emotion") == emotion:
            score += 2
        if art.get("pose") == pose:
            score += 1
        if score > best_score:
            best = art
            best_score = score
    assert(not best.is_empty(), "No accepted fallback for " + character)
    return best


func _synthetic_sources() -> Dictionary:
    var data := {
        "dialogue": Dialogue.data.duplicate(true),
        "routes": Routes.data.duplicate(true),
        "staging": Staging.data.duplicate(true),
        "cues": Cues.data.duplicate(true),
        "foundation": Foundation.data.duplicate(true),
        "backgrounds": Backgrounds.data.duplicate(true),
        "portraits": Portraits.data.duplicate(true)
    }
    for scene: Dictionary in data.dialogue.scenes:
        if scene.sceneId == TEA:
            scene.status = "runtime_approved"  # SYNTHETIC; not a production change.
    for route: Dictionary in data.routes.sceneTriggers:
        if route.sceneId == TEA:
            route.gate.approvedRuntime = true
            route.gate.proposedRuntime = false
    for shot: Dictionary in data.staging.sceneShots:
        if shot.sceneId != TEA:
            continue
        for actor: Dictionary in shot.cast:
            var art := _best_existing_art(str(actor.characterId), str(actor.pose), str(actor.emotion), data.portraits.entries)
            actor.pose = art.pose
            actor.emotion = art.emotion
    for cue: Dictionary in data.cues.cues:
        if cue.sceneId != TEA:
            continue
        var art := _best_existing_art(str(cue.speakerId), str(cue.poseId), str(cue.emotionId), data.portraits.entries)
        cue.poseId = art.pose
        cue.emotionId = art.emotion
    return data


func _find(data: Dictionary, state: Dictionary, locale: String = "ru", target: String = "RM-HS-TEA-TABLE", auto_only: bool = false) -> Dictionary:
    return Runtime.find_approved(state, locale, data.dialogue, data.routes, data.staging,
        data.cues, data.foundation, data.backgrounds, data.portraits, target, auto_only)


func _synthetic_hall_tea_positive_and_negative() -> void:
    var copies := _synthetic_sources()
    var initial := Snapshot.fresh()
    var before_end := _completed_chapter_i()
    before_end.storyBeatsSeen.erase(PREVIOUS)
    assert(_find(copies, initial).is_empty(), "Hall Tea before Chapter I")
    assert(_find(copies, before_end).is_empty(), "Hall Tea before RM-BEAT-01-05")
    var state := _completed_chapter_i()
    # Source target is the scene route's authoring string, not a UI tap boolean.
    var target := ""
    for route: Dictionary in copies.routes.sceneTriggers:
        if route.sceneId == TEA:
            target = str(route.interactionTarget)
    assert(target == "hall_chair_table", "Hall Tea authored target changed without reviewed contract")
    assert(_find(copies, state, "ru", "wrong-hotspot").is_empty())
    assert(_find(copies, state, "ru", target, true).is_empty(), "Physical VN auto-played")
    var canonical_ids: Array = []
    for lang in LOCALES:
        var config: Dictionary = _find(copies, state, lang, target)
        assert(config.get("beatId") == TEA and config.get("interactionTarget") == target)
        assert(config.get("source") == "canonical_production_only")
        assert(config.get("lines", []).size() == 12 and config.get("lineIds", []).size() == 12)
        if canonical_ids.is_empty():
            canonical_ids = config.lineIds.duplicate()
        assert(config.lineIds == canonical_ids)
        var player := VN.new()
        player.open(config)
        for index in range(12):
            var id := str(config.lineIds[index])
            var source_line: Dictionary = {}
            for item: Dictionary in Dialogue.data.entries:
                if item.id == id:
                    source_line = item
                    break
            assert(not source_line.is_empty())
            assert(player.line_index == index)
            assert(player.current_line() == str(source_line.localized[lang].text), id + ": locale fallback")
            assert(player.current_speaker() == Copy.speaker_name(str(source_line.speakerId), lang))
            assert(Runtime.completion_event(config, false, "premature").is_empty())
            assert(player.advance() == (index == 11), id + ": early/late completion")
        assert(Runtime.completion_event(config, true, "").is_empty())
        var event := Runtime.completion_event(config, true, "game-qa-03-end-" + lang)
        assert(event.get("type") == "story_beat_seen" and event.get("storyBeatId") == TEA)
        var applied: Dictionary = Reducer.apply(state, event)
        assert(applied.get("ok", false) and applied.state.storyBeatsSeen.has(TEA))
        assert(applied.state.workPoints == state.workPoints)
        var again: Dictionary = Reducer.apply(applied.state, event)
        assert(again.get("duplicate", false) and again.state.revision == applied.state.revision)
        var distinct: Dictionary = Reducer.apply(applied.state, event.merged({"eventId": "game-qa-03-retry-" + lang}, true))
        assert(distinct.get("duplicate", false) and distinct.state.storyBeatsSeen.count(TEA) == 1)
        assert(_find(copies, applied.state, lang, target).is_empty(), "One-shot replayed")

        # Isolated in-memory mid-scene cursor, read history and Continue.
        var mid := state.duplicate(true)
        mid.vnCursor = {"beatId": TEA, "lineIndex": 2}
        ReadHistory.mark_read(mid, str(canonical_ids[0]))
        ReadHistory.mark_read(mid, str(canonical_ids[1]))
        var memory := Memory.new()
        var store := Store.new(memory)
        assert(store.save_campaign(mid))
        var restored: Dictionary = Store.new(memory).load_campaign()
        assert(restored.vnCursor == mid.vnCursor and restored.vnReadLines == canonical_ids.slice(0, 2))
        var resumed := VN.new()
        resumed.open(config)
        resumed.line_index = int(restored.vnCursor.lineIndex)
        assert(resumed.current_line() == config.lines[2].text)
        assert(ReadHistory.skip_target(config, 0, []) == 0, "Skip must stop on unread")
        assert(ReadHistory.skip_target(config, 0, canonical_ids.slice(0, 2)) == 2)
        assert(ReadHistory.skip_target(config, 0, canonical_ids) == 0, "Skip cannot finish")
        var choice := config.duplicate(true)
        choice.choiceGate = {"checkpointLineId": canonical_ids[1]}
        assert(ReadHistory.skip_target(choice, 0, canonical_ids.slice(0, 3)) == 1)
        assert(store.save_campaign(applied.state))
        assert(Store.new(memory).load_campaign().storyBeatsSeen.count(TEA) == 1)

    # Safety cases change only isolated source copies, never live catalogs.
    var unsafe := copies.duplicate(true)
    for scene: Dictionary in unsafe.dialogue.scenes:
        if scene.sceneId == TEA:
            scene.status = "pilot_runtime"
    assert(_find(unsafe, state, "ru", target).is_empty(), "Unapproved scene dispatched")
    unsafe = copies.duplicate(true)
    for route: Dictionary in unsafe.routes.sceneTriggers:
        if route.sceneId == TEA:
            route.gate.approvedRuntime = false
    assert(_find(unsafe, state, "ru", target).is_empty(), "Unapproved route dispatched")
    unsafe = copies.duplicate(true)
    for cue: Dictionary in unsafe.cues.cues:
        if cue.sceneId == TEA and cue.speakerId == "RM-CHAR-ADA":
            cue.poseId = "unaccepted_qa_pose"
            break
    assert(_find(unsafe, state, "ru", target).is_empty(), "Missing portrait dispatched")
    unsafe = copies.duplicate(true)
    for line: Dictionary in unsafe.dialogue.entries:
        if line.sceneId == TEA:
            line.localized.be.text = ""
            break
    assert(_find(unsafe, state, "ru", target).is_empty(), "Missing locale fallback")
    for kind in ["npc_tap", "object_tap", "door_tap", "specialist_result"]:
        unsafe = copies.duplicate(true)
        for route: Dictionary in unsafe.routes.sceneTriggers:
            if route.sceneId == TEA:
                route.gate.kind = kind
        assert(_find(unsafe, state, "ru", target).is_empty(), "Unsupported authoritative gate bypass: " + kind)
    # All seven future scenes with unsupported gates remain closed even if
    # their dialog/route approvals are synthetically toggled.
    for future_id: String in SCENES.slice(1):
        unsafe = copies.duplicate(true)
        for scene: Dictionary in unsafe.dialogue.scenes:
            if scene.sceneId == future_id:
                scene.status = "runtime_approved"
        for route: Dictionary in unsafe.routes.sceneTriggers:
            if route.sceneId == future_id:
                route.gate.approvedRuntime = true
                route.gate.proposedRuntime = false
        var unverified_future := Runtime.find_approved(state, "ru", unsafe.dialogue, unsafe.routes,
            unsafe.staging, unsafe.cues, unsafe.foundation, unsafe.backgrounds,
            unsafe.portraits, str(_target_for(future_id)))
        assert(str(unverified_future.get("beatId", "")) != future_id,
            "Unverified future interaction dispatched without authoritative token: " + future_id)


func _target_for(id: String) -> String:
    for route: Dictionary in Routes.data.sceneTriggers:
        if route.sceneId == id:
            return str(route.interactionTarget)
    return ""


func _isolation_and_save_failures() -> void:
    var memory := Memory.new()
    var original := _completed_chapter_i()
    var store := Store.new(memory)
    assert(store.save_campaign(original))
    memory.fail_write = true
    var later := original.duplicate(true)
    later.vnCursor = {"beatId": TEA, "lineIndex": 3}
    assert(not store.save_campaign(later), "Failed write incorrectly reported as committed")
    assert(Store.new(memory).load_campaign().vnCursor.is_empty(), "Failed write overwrote good snapshot")
    memory.fail_write = false
    assert(store.save_campaign(later), "Write recovery failed")
    assert(Store.new(memory).load_campaign().vnCursor == later.vnCursor)
    # No mutating a real user save. Corrupt input is a fresh isolated adapter.
    var corrupt := Memory.new()
    corrupt.values[SaveContract.data.ravenKey] = "{corrupted"
    var host = Host.new(corrupt)
    root.add_child(host)
    assert(str(host.configure(_production_request()).get("error", "")).begins_with("save-unreadable:"))
    assert(corrupt.values[SaveContract.data.ravenKey] == "{corrupted")
    host.queue_free()
