extends SceneTree
## CODE-07-02 characterization of the restore/snapshot path that EXISTS today.
## Locks, before the unified interaction/repair pipeline is built:
##   * reducer restoration gates (level / story-flag / work-point / unknown ID),
##   * snapshot normalization of a restore-carrying save,
##   * save -> reload -> re-gate (no second charge, no cached UI truth),
##   * a restoration-gated route re-derived from the loaded snapshot,
##   * corrupt / unsupported / lax JSON recovery and the single recovery slot.
## Deliberate gaps are asserted as CURRENT behavior and must be flipped together
## with the fix documented in docs/changes/CODE-07-02-restore-gap.md.
## Uses injected memory storage; never touches the player's Raven save.

const Snapshot = preload("res://scripts/raven/raven_snapshot.gd")
const Reducer = preload("res://scripts/raven/raven_reducer.gd")
const Store = preload("res://scripts/raven/raven_campaign_store.gd")
const Graph = preload("res://scripts/raven/manor_navigation_graph.gd")
const MemoryStorage = preload("res://tests/support/memory_storage.gd")
const CONTRACT = preload("res://data/save_contract.json")
const CATALOG = preload("res://data/raven/foundation_catalog.json")


func _initialize() -> void:
	_restore_gates_hold_on_loaded_snapshot()
	_restored_state_survives_save_and_reload()
	_restored_gate_drives_authored_routes()
	_snapshot_restore_drops_unknown_ids()
	_corrupt_and_unsupported_saves_recover_to_fresh()
	_lax_json_save_is_accepted_today()
	_new_game_keeps_a_stale_recovery_backup()
	print("Raven Manor restoration restore/snapshot characterization smoke passed")
	quit()


func _restore_gates_hold_on_loaded_snapshot() -> void:
	var state := Snapshot.fresh()
	assert(state.workPoints == 0 and state.completedRestorations.is_empty(), "Fresh campaign must not own a restoration")
	assert(state.unlockedDoors == ["RM-DOOR-HALL-CORRIDOR"], "Fresh campaign must only open Hall->Corridor")
	assert(Reducer.apply(state, _purchase("gate-unknown", "RM-REST-GHOST")).error == "unknown-restoration")
	assert(Reducer.apply(state, _purchase("gate-early", "RM-REST-001")).error == "level-prerequisite-missing")

	state = _accept(state, _level_won("gate-lvl-1", "RM-LVL-001"))
	assert(Reducer.apply(state, _purchase("gate-flag-early", "RM-REST-001")).error == "story-flag-prerequisite-missing")
	state = _accept(state, _level_won("gate-lvl-2", "RM-LVL-002"))
	state = _accept(state, _level_won("gate-lvl-3", "RM-LVL-003"))
	assert(state.workPoints == 6, "Three first clears must award 6 work points, got %d" % state.workPoints)

	# A save written before an authored reward change may carry fewer points than
	# the current cost; the gate must be re-evaluated on restored data, not skipped.
	var starved := _accept(state, {"eventId": "gate-starved-plumber", "type": "story_flag_set", "flagId": "service.plumber_available"})
	starved.workPoints = 3
	assert(Reducer.apply(starved, _purchase("gate-poor", "RM-REST-002")).error == "insufficient-work-points")

	var adapter := MemoryStorage.new()
	assert(Store.new(adapter).save_campaign(state))
	var store := Store.new(adapter)
	var loaded := store.load_campaign()
	assert(store.last_load_report.status == "loaded" and store.last_load_report.detail == "schema-1")
	assert(loaded == state, "Restore prerequisites must survive the save/reload round-trip")
	# Gates are re-evaluated from persisted flags, not from cached UI state.
	assert(Reducer.apply(loaded, _purchase("gate-after-reload", "RM-REST-001")).error == "story-flag-prerequisite-missing")
	loaded = _accept(loaded, {"eventId": "gate-access", "type": "story_flag_set", "flagId": "RM-FLAG-BEDROOM-ACCESS-CLEARED"})
	loaded = _accept(loaded, {"eventId": "gate-plumber", "type": "story_flag_set", "flagId": "service.plumber_available"})
	var bedroom := _accept(loaded, _purchase("gate-restore-1", "RM-REST-001"))
	assert(bedroom.workPoints == 4 and bedroom.completedRestorations == ["RM-REST-001"])
	assert(bedroom.boosterInventory.hammer == 2, "Bedroom restoration must grant exactly two hammers")
	var bathroom := _accept(bedroom, _purchase("gate-restore-2", "RM-REST-002"))
	assert(bathroom.workPoints == 0 and bathroom.completedRestorations == ["RM-REST-001", "RM-REST-002"])
	assert(bathroom.boosterInventory.shuffle == 2 and bathroom.boosterInventory.hammer == 2,
		"Bathroom restoration must grant exactly two shuffles on top of the hammer reward")


func _restored_state_survives_save_and_reload() -> void:
	var state := Snapshot.fresh()
	state = _accept(state, _level_won("restore-lvl-1", "RM-LVL-001"))
	state = _accept(state, {"eventId": "restore-access", "type": "story_flag_set", "flagId": "RM-FLAG-BEDROOM-ACCESS-CLEARED"})
	state = _accept(state, _purchase("restore-bedroom", "RM-REST-001"))
	state = _accept(state, {"eventId": "restore-hotspot", "type": "hotspot_state", "hotspotId": "RM-HS-002", "state": "restored"})
	state = _accept(state, {"eventId": "restore-position", "type": "position_checkpoint", "roomId": "RM-ROOM-BEDROOM", "anchorId": "RM-NAV-BEDROOM-CENTER"})
	assert(state.workPoints == 0 and state.completedRestorations == ["RM-REST-001"])
	assert(state.boosterInventory.hammer == 2)

	var adapter := MemoryStorage.new()
	assert(Store.new(adapter).save_campaign(state))
	var reloaded := Store.new(adapter).load_campaign()
	assert(reloaded == state, "Restored room, hotspot state and checkpoint must round-trip unchanged")
	assert(reloaded.completedRestorations == ["RM-REST-001"])
	assert(reloaded.hotspotStates.get("RM-HS-002", "") == "restored", "Restored hotspot visual state lost on reload")
	assert(reloaded.lastRoomId == "RM-ROOM-BEDROOM" and reloaded.lastSafeAnchorId == "RM-NAV-BEDROOM-CENTER")

	# The restored room must never be chargeable a second time after a reload.
	var recharged := Reducer.apply(reloaded, _purchase("restore-bedroom-again", "RM-REST-001"))
	assert(recharged.ok and recharged.duplicate, "Repeated restoration must resolve as a duplicate")
	assert(recharged.state.workPoints == 0 and recharged.state.revision == reloaded.revision,
		"Repeated restoration must not spend work points or bump the revision")

	# A failed write must not report a restored room that is not actually persisted.
	adapter.fail_write = true
	assert(not Store.new(adapter).save_campaign(reloaded), "Failed restore write must be reported")
	adapter.fail_write = false
	assert(Store.new(adapter).load_campaign() == reloaded, "Failed restore write must not mutate the saved campaign")


func _restored_gate_drives_authored_routes() -> void:
	# No authored greybox edge uses restorationId yet (see the gap record); this
	# fixture proves the snapshot gate itself drives routing after a reload.
	var graph_data := {
		"anchors": [
			{"id": "RM-NAV-TEST-A", "position": [0, 0]},
			{"id": "RM-NAV-TEST-B", "position": [40, 0]},
		],
		"edges": [
			{"from": "RM-NAV-TEST-A", "to": "RM-NAV-TEST-B", "restorationId": "RM-REST-002", "bidirectional": true},
		],
	}
	var graph := Graph.new()
	graph.rebuild(Snapshot.fresh(), graph_data)
	assert(graph.route("RM-NAV-TEST-A", "RM-NAV-TEST-B").is_empty(), "Unrestored room must stay unreachable")

	var restored := Snapshot.fresh()
	restored = _accept(restored, _level_won("route-lvl-2", "RM-LVL-002"))
	restored = _accept(restored, _level_won("route-lvl-3", "RM-LVL-003"))
	restored = _accept(restored, {"eventId": "route-plumber", "type": "story_flag_set", "flagId": "service.plumber_available"})
	restored = _accept(restored, _purchase("route-bathroom", "RM-REST-002"))
	assert(restored.completedRestorations == ["RM-REST-002"])
	var adapter := MemoryStorage.new()
	assert(Store.new(adapter).save_campaign(restored))
	var reopened := Graph.new()
	reopened.rebuild(Store.new(adapter).load_campaign(), graph_data)
	assert(reopened.route("RM-NAV-TEST-A", "RM-NAV-TEST-B") == ["RM-NAV-TEST-A", "RM-NAV-TEST-B"],
		"Completed restoration must open its authored edge after a reload")


func _snapshot_restore_drops_unknown_ids() -> void:
	var hand_written: Dictionary = Snapshot.fresh().duplicate(true)
	hand_written.completedRestorations = ["RM-REST-001", "RM-REST-GHOST", "RM-REST-001"]
	hand_written.hotspotStates = {"RM-HS-002": "restored", "RM-HS-GHOST": "restored"}
	hand_written.unlockedDoors = []
	hand_written.lastRoomId = "RM-ROOM-GHOST"
	hand_written.workPoints = -5
	hand_written.revision = -3
	hand_written.boosterInventory = {"hammer": 500, "shuffle": -2, "bomb": 4}
	var normalized: Variant = Snapshot.normalize(hand_written, CATALOG.data)
	assert(normalized != null, "A schema-1 save must normalize")
	assert(normalized.completedRestorations == ["RM-REST-001"], "Unknown or duplicate restoration IDs must be dropped")
	assert(normalized.hotspotStates.has("RM-HS-002") and not normalized.hotspotStates.has("RM-HS-GHOST"))
	assert(normalized.unlockedDoors == ["RM-DOOR-HALL-CORRIDOR"], "Hall->Corridor must be re-granted on load")
	assert(normalized.lastRoomId == "RM-ROOM-HALL", "Unknown room must fall back to the Hall")
	assert(normalized.workPoints == 0 and normalized.revision == 0, "Negative counters must be clamped to zero")
	assert(normalized.boosterInventory == {"hammer": 99, "shuffle": 0}, "Booster counts must be clamped and filtered")
	assert(Snapshot.normalize({"schemaVersion": 1, "gameId": "upds"}, CATALOG.data) == null,
		"Foreign gameId must be rejected")
	assert(Snapshot.normalize("not-a-save", CATALOG.data) == null, "Non-object save root must be rejected")


func _corrupt_and_unsupported_saves_recover_to_fresh() -> void:
	var empty_store := Store.new(MemoryStorage.new())
	assert(empty_store.get_recovery_backup() == null, "Fresh storage must not report a recovery backup")
	assert(empty_store.load_campaign() == Snapshot.fresh() and empty_store.last_load_report.detail == "no-save")

	var adapter := MemoryStorage.new()
	var future := '{"schemaVersion":2,"gameId":"raven-manor","workPoints":9,"completedRestorations":["RM-REST-001"]}'
	adapter.values[CONTRACT.data.ravenKey] = future
	var store := Store.new(adapter)
	assert(store.load_campaign() == Snapshot.fresh(), "Unsupported schema must restore a fresh campaign")
	assert(store.last_load_report.status == "recovered-corrupt")
	var backup: Variant = store.get_recovery_backup()
	assert(backup is Dictionary, "Unsupported save must be captured in the recovery slot")
	assert(backup.raw == future and backup.saveKey == CONTRACT.data.ravenKey)
	assert(backup.reason == "invalid-or-unsupported-save", "Recovery reason does not distinguish schema from JSON failures")
	assert(adapter.values.get(CONTRACT.data.ravenKey) == future, "Unsupported save must not be overwritten by the load")

	adapter.values[CONTRACT.data.ravenKey] = "{broken"
	var reopened := Store.new(adapter)
	assert(reopened.load_campaign() == Snapshot.fresh() and reopened.last_load_report.status == "recovered-corrupt")
	assert(reopened.get_recovery_backup().raw == "{broken", "Recovery slot must hold the latest corrupt payload")
	assert(Store.new(adapter).load_campaign() == Snapshot.fresh(), "A still-corrupt save must keep restoring fresh")
	assert(not reopened.last_load_report.detail.is_empty())


func _lax_json_save_is_accepted_today() -> void:
	# Gap G2 in docs/changes/CODE-07-02-restore-gap.md: the UPDS donor validates a
	# strict JSON grammar before decoding, but Godot's parser (verified on 4.7.2)
	# accepts a trailing comma, a raw control character and a leading zero. Such a
	# save restores silently instead of being captured as corrupt. Flip these
	# assertions when the strict grammar reaches raven_campaign_store.gd.
	var adapter := MemoryStorage.new()
	adapter.values[CONTRACT.data.ravenKey] = '{"schemaVersion":1,"gameId":"raven-manor","workPoints":3,"completedRestorations":["RM-REST-001",],}'
	var store := Store.new(adapter)
	var loaded := store.load_campaign()
	assert(store.last_load_report.status == "loaded", "Lax JSON is currently accepted, not recovered")
	assert(loaded.workPoints == 3 and loaded.completedRestorations == ["RM-REST-001"])
	assert(store.get_recovery_backup() == null, "Lax JSON must not be captured in the recovery slot")


func _new_game_keeps_a_stale_recovery_backup() -> void:
	# Gap G4: reset_campaign() clears only the live slot, so the previous corrupt
	# payload survives an explicit New Game. Characterized, not endorsed.
	var adapter := MemoryStorage.new()
	adapter.values[CONTRACT.data.ravenKey] = "{broken"
	var store := Store.new(adapter)
	assert(store.load_campaign() == Snapshot.fresh())
	assert(store.get_recovery_backup().raw == "{broken")
	assert(store.reset_campaign(), "New Game reset must succeed")
	assert(store.load_campaign() == Snapshot.fresh() and store.last_load_report.detail == "no-save")
	assert(store.get_recovery_backup().raw == "{broken", "New Game keeps the stale recovery backup")
	assert(adapter.values.has(CONTRACT.data.ravenRecoveryKey), "Recovery slot is not part of the reset contract")


func _accept(state: Dictionary, event: Dictionary) -> Dictionary:
	var result: Dictionary = Reducer.apply(state, event)
	assert(result.ok and not result.get("duplicate", false), "Event rejected: %s / %s" % [str(event), str(result)])
	return result.state


func _level_won(event_id: String, level_id: String) -> Dictionary:
	return {"eventId": event_id, "type": "level_won", "levelId": level_id}


func _purchase(event_id: String, restoration_id: String) -> Dictionary:
	return {"eventId": event_id, "type": "restoration_purchase", "restorationId": restoration_id}
