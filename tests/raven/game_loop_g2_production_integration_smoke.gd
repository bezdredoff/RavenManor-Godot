extends SceneTree
## Real approved production source/controller/view/Evelyn/VN/Match-3/store with isolated memory saves.
const Fixture = preload("res://tests/support/g2_production_fixture.gd")
const Map = preload("res://scripts/raven/raven_player_map.gd")
const Host = preload("res://scripts/raven/raven_gameplay_host.gd")
const Source = preload("res://scripts/raven/manor_navigation_source.gd")
const Memory = preload("res://tests/support/memory_storage.gd")
const Store = preload("res://scripts/raven/raven_campaign_store.gd")
const Snapshot = preload("res://scripts/raven/raven_snapshot.gd")
const Reducer = preload("res://scripts/raven/raven_reducer.gd")
const MatchSession = preload("res://scripts/raven/raven_match3_session.gd")
const Dispatch = preload("res://scripts/raven/raven_vn_runtime_dispatch.gd")
const Contract = preload("res://data/save_contract.json")

func _initialize() -> void:
	call_deferred("_run")

func _seed(storage: RefCounted) -> void:
	var state := Snapshot.fresh()
	for beat in ["RM-BEAT-00-01", "RM-BEAT-00-02", "RM-BEAT-00-03", "RM-BEAT-01-01"]:
		var result := Reducer.apply(state, {"eventId": "opening-" + beat, "type": "story_beat_seen", "storyBeatId": beat})
		assert(result.ok)
		state = result.state
	assert(Store.new(storage).save_campaign(state))

func _map(storage: RefCounted):
	var map = Map.new()
	map.host = Host.new(storage)
	root.add_child(map)
	map.set_process(false)
	return map

func _transition(map: Node, door: String) -> String:
	for item in map.host.source.contract.transitions:
		if item.doorId == door and item.sourceRoomId == map.host.room_state().roomId:
			return str(item.id)
	return ""

func _settle(map: Node) -> void:
	for _tick in range(10000):
		var before: Vector2 = map.host.navigation.actor.position
		map._process(0.025)
		assert(before.distance_to(map.host.navigation.actor.position) <= 4.01, "Frame jump / incorrect spawn")
		if not map._moving:
			assert(not map.host.navigation.actor.has_active_segment())
			return
	assert(false, "Movement did not settle")

func _travel(map: Node, door: String, room: String) -> void:
	map._request_door(_transition(map, door))
	assert(map._moving, map.status.text)
	_settle(map)
	assert(map.host.room_state().roomId == room)
	var saved: Dictionary = map.host.store.load_campaign()
	assert(saved.lastRoomId == room)
	assert(saved.lastSafeAnchorId not in ["RM-NAV-HALL-CORRIDOR-NEAR", "RM-NAV-HALL-CORRIDOR-FAR", "RM-NAV-BEDROOM-NEAR", "RM-NAV-BEDROOM-FAR"])

func _run() -> void:
	root.size = Vector2i(390, 844)
	var canonical_hash := FileAccess.get_sha256("res://data/raven/manor_greybox_graph.json")
	var candidate_hash := FileAccess.get_sha256("res://data/raven/manor_production_candidate.v1.json")
	assert(Source.validate_calibrated_plan(Fixture.plan()).is_empty(), Source.validate_calibrated_plan(Fixture.plan()))
	# One explicit map identifier -> authored route target. A narrative string
	# is never accepted as a raw map hotspot or a physical-arrival receipt.
	assert(Dispatch.canonical_interaction_target("RM-HS-TEA-TABLE") == "hall_chair_table")
	assert(Dispatch.canonical_interaction_target("hall_chair_table").is_empty())
	assert(Dispatch.canonical_interaction_target("RM-HS-001").is_empty())
	# #291 approved the HC/CB graph, NOT a Hall Tea table anchor. A real
	# production request must continue to fail closed pending mapped geometry.
	assert(not Fixture.plan().anchors.any(func(a): return a.get("hotspotId", "") == "RM-HS-TEA-TABLE"))
	var broken := Fixture.plan()
	broken.anchors[0].position = [300, 400]
	assert(not Source.validate_calibrated_plan(broken).is_empty())
	broken = Fixture.plan()
	broken.provenance.roomArtCalibration.rooms["RM-ROOM-HALL"].bounds[0] = 0
	assert(not Source.resolve(Fixture.request().merged({"worldPlan": broken}, true)).ok)
	var normal = Host.new()
	root.add_child(normal)
	var injected := Fixture.request().merged({"worldPlan": Fixture.plan()})
	assert(normal.configure(injected).error == "injected-production-plan-forbidden")
	normal.queue_free()
	var unsafe_storage = Host.new(Store.new().storage, true)
	root.add_child(unsafe_storage)
	assert(unsafe_storage.configure(injected).error == "injected-production-plan-forbidden", "Test approval cannot use persistent storage")
	unsafe_storage.queue_free()
	assert(Source.resolve(Fixture.request()).ok, "Accepted default world plan must be enabled")
	for locale in ["ru", "be", "en"]:
		root.size = {"ru": Vector2i(320, 568), "be": Vector2i(430, 932), "en": Vector2i(390, 844)}[locale]
		root.content_scale_size = root.size
		var storage = Memory.new()
		_seed(storage)
		var map = _map(storage)
		await process_frame
		assert(map._ready_for_input, map.status.text)
		map.prefs.set_locale(locale)
		assert(map.status.text == map._copy(0), "Status must follow the selected locale, like the HUD")
		map._process(0.0)
		map.camera.force_update_scroll()
		var actor_on_screen: Vector2 = map.host.navigation.actor.get_global_transform_with_canvas().origin
		assert(actor_on_screen.y < float(root.size.y) - 164.0, "Evelyn feet must remain above the portrait HUD")
		assert(map.camera.limit_left == 128 and map.camera.limit_bottom == 1069)
		assert(map.host.source.mode == "production" and not map.host.source.draftOnly)
		assert(map.host.source.contract.transitions.size() == 4)
		var before_tea: Dictionary = map.host.store.load_campaign()
		assert(map.host.request_runtime_hotspot("RM-HS-TEA-TABLE").get("error") == "runtime-story-gate-closed")
		assert(map.host.request_runtime_hotspot("RM-HS-001").get("error") == "unknown-runtime-hotspot")
		assert(map.host.store.load_campaign() == before_tea, "Unapproved tea taps cannot persist or complete scenes")
		assert(map.host.navigation.actor.get_script().resource_path.ends_with("evelyn_actor.gd"))
		assert(not map.host.navigation.request_screen_point(Vector2(952, 528)).ok)
		map._request_door(_transition(map, "RM-DOOR-HALL-CORRIDOR"))
		map._process(0.025)
		map._toggle_pause()
		var feet: Vector2 = map.host.navigation.actor.position
		map._process(0.5)
		assert(map.host.navigation.actor.position == feet)
		map._toggle_pause()
		map._cancel()
		_settle(map)
		assert(map.host.state.storyFlags.is_empty())
		_travel(map, "RM-DOOR-HALL-CORRIDOR", "RM-ROOM-CORRIDOR")
		assert(map.host.request_transition(_transition(map, "RM-DOOR-CORRIDOR-BEDROOM")).error == "locked-door")
		map._request_story("RM-HS-005")
		assert(not map.host.state.storyFlags.has("RM-FLAG-BEDROOM-ACCESS-CLEARED"))
		_settle(map)
		assert(map.host.state.unlockedDoors.has("RM-DOOR-CORRIDOR-BEDROOM"))
		assert(map.host.state.completedRestorations.is_empty())
		assert(not is_instance_valid(map.overlay), "Bedroom Match-3 before physical entry")
		_travel(map, "RM-DOOR-CORRIDOR-BEDROOM", "RM-ROOM-BEDROOM")
		var presentation = map.overlay
		assert(is_instance_valid(presentation) and presentation.store == map.host.store)
		assert(presentation.step.id == "level1" and presentation.match_game != null)
		var first_hint: Dictionary = presentation.match_game.get_hint_move()
		assert(presentation.match_game.attempt_swap(first_hint.first, first_hint.second).valid)
		var board_checkpoint: Dictionary = map.host.store.load_campaign().match3Checkpoint.duplicate(true)
		assert(not board_checkpoint.is_empty())
		map.queue_free()
		await process_frame
		map = _map(storage)
		await process_frame
		assert(map.host.room_state().roomId == "RM-ROOM-BEDROOM" and map.host.room_state().anchorId == "RM-NAV-BEDROOM-CENTER")
		presentation = map.overlay
		assert(presentation.step.id == "level1" and presentation.match_game.move_history.size() == board_checkpoint.actions.size())
		for _move in range(100):
			if presentation.match_game.state != "playing":
				break
			var hint: Dictionary = presentation.match_game.get_hint_move()
			assert(presentation.match_game.attempt_swap(hint.first, hint.second).valid)
		assert(presentation.match_game.state == "won")
		presentation._complete_level()
		map._process(0.025)
		assert(map.host.store.load_campaign().workPoints == 2)
		var once: Dictionary = map.host.store.load_campaign()
		assert(MatchSession.complete(null, once, "level1", "RM-LVL-001", 999, map.host.store).state.workPoints == 2)
		assert(not is_instance_valid(map.overlay))
		map._request_story("RM-HS-002")
		_settle(map)
		assert(map.host.store.load_campaign().workPoints == 0)
		assert(map.host.store.load_campaign().completedRestorations == ["RM-REST-001"])
		assert(is_instance_valid(map.overlay) and map.overlay.step.id == "bedroom")
		map.overlay._advance_vn()
		var cursor: Dictionary = map.host.store.load_campaign().vnCursor.duplicate(true)
		assert(cursor.beatId == "RM-BEAT-01-02")
		map.queue_free()
		await process_frame
		map = _map(storage)
		await process_frame
		assert(map.host.room_state().roomId == "RM-ROOM-BEDROOM" and map.host.room_state().anchorId == "RM-NAV-BEDROOM-CENTER")
		assert(map.overlay.vn_player.line_index == int(cursor.lineIndex))
		for _line in range(100):
			if map.overlay.state.storyBeatsSeen.has("RM-BEAT-01-02"):
				break
			map.overlay._advance_vn()
		assert(map.overlay.state.storyBeatsSeen.has("RM-BEAT-01-02"))
		map._dismiss_presentation()
		await process_frame
		_travel(map, "RM-DOOR-CORRIDOR-BEDROOM", "RM-ROOM-CORRIDOR")
		_travel(map, "RM-DOOR-HALL-CORRIDOR", "RM-ROOM-HALL")
		var checkpoint: Dictionary = map.host.store.load_campaign()
		assert(checkpoint.lastSafeAnchorId == "RM-NAV-HALL-SPAWN")
		assert(Dispatch.next_scene_at_confirmed_hotspot(map.host, "RM-HS-TEA-TABLE", locale).is_empty())
		assert(Dispatch.next_scene_at_confirmed_hotspot(map.host, "hall_chair_table", locale).is_empty())
		assert(not map.host.runtime_hotspot_available("RM-HS-TEA-TABLE"))
		assert(map.host.state.get("vnCursor", {}).is_empty(), "No premature Hall Tea cursor")
		assert(map.host.reload_session().ok)
		assert(map.host.room_state().anchorId == checkpoint.lastSafeAnchorId)
		assert(map.host.state.workPoints == 0 and map.host.state.completedRestorations.size() == 1)
		map.queue_free()
		await process_frame
	var failed = Memory.new()
	_seed(failed)
	var host = Host.new(failed)
	root.add_child(host)
	assert(host.configure(Fixture.request()).ok)
	assert(host.request_transition(str(host.source.contract.transitions[0].id)).ok)
	assert(host.drive().status == "ready")
	assert(host.commit_ready_transition().ok)
	failed.fail_write = true
	assert(not host.drive().ok)
	assert(Store.new(failed).load_campaign().lastRoomId == "RM-ROOM-HALL")
	failed.fail_write = false
	assert(host.reload_session().ok and host.room_state().roomId == "RM-ROOM-HALL")
	host.queue_free()
	var corrupt = Memory.new()
	corrupt.values[Contract.data.ravenKey] = "{broken"
	host = Host.new(corrupt)
	root.add_child(host)
	assert(host.configure(Fixture.request()).error.begins_with("save-unreadable:"))
	assert(corrupt.values[Contract.data.ravenKey] == "{broken")
	host.queue_free()
	assert(Source.resolve(Fixture.request()).ok, "Accepted default world plan must remain enabled")
	assert(FileAccess.get_sha256("res://data/raven/manor_greybox_graph.json") == canonical_hash)
	assert(FileAccess.get_sha256("res://data/raven/manor_production_candidate.v1.json") == candidate_hash)
	print("G2 production-contract integrated map, Evelyn, traversal, VN/Match-3, save/recovery and RU/BE/EN PASS")
	quit()
