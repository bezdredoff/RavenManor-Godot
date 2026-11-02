extends SceneTree
## VNS5-06D2A: existing v1 saves remain valid; a new narrative beat ID
## is rejected by old registry, accepted only by a reviewed expanded registry.
## No game files, saves, routes, player progress or scene runtime are mutated.
const Snapshot = preload("res://scripts/raven/raven_snapshot.gd")
const Reducer = preload("res://scripts/raven/raven_reducer.gd")
const Catalog = preload("res://data/raven/foundation_catalog.json")
const Campaign = preload("res://scripts/raven/raven_campaign_store.gd")
const Storage = preload("res://scripts/core/save_storage.gd")
const Contract = preload("res://data/save_contract.json")


func _initialize() -> void:
	var old_catalog: Dictionary = Catalog.data.duplicate(true)
	var new_beat := "RM-BEAT-07-01"
	assert(not old_catalog["storyBeats"].has(new_beat))
	var initial: Dictionary = Snapshot.fresh()
	initial["revision"] = 4
	initial["storyBeatsSeen"] = ["RM-BEAT-00-01", "RM-BEAT-00-02"]
	initial["firstClearLevels"] = ["RM-LVL-001"]
	initial["lastRoomId"] = "RM-ROOM-HALL"
	var old_save: Variant = Snapshot.normalize(initial, old_catalog)
	assert(old_save != null)
	assert(old_save["schemaVersion"] == 1)
	assert(old_save["revision"] == 4)
	assert(old_save["storyBeatsSeen"] == initial["storyBeatsSeen"])
	assert(old_save["firstClearLevels"] == initial["firstClearLevels"])
	var temporary_store := Storage.new("user://raven_vns5_06d2a_save_rehearsal")
	var facade := Campaign.new(temporary_store)
	assert(facade.save_campaign(old_save))
	var loaded: Dictionary = facade.load_campaign()
	assert(facade.last_load_report["status"] == "loaded")
	assert(loaded["storyBeatsSeen"] == old_save["storyBeatsSeen"])
	assert(loaded["revision"] == 4)
	var test_event: Dictionary = {"type": "story_beat_seen", "eventId": "vns5-06d2a/check-1",
		"storyBeatId": new_beat}
	var blocked: Dictionary = Reducer.apply(loaded, test_event, old_catalog)
	assert(not blocked.get("ok", false))
	assert(blocked.get("error", "") == "unknown-story-beat")
	assert(loaded["storyBeatsSeen"].size() == 2)
	var extended: Dictionary = old_catalog.duplicate(true)
	extended["storyBeats"].append(new_beat)
	var compatible: Variant = Snapshot.normalize(loaded, extended)
	assert(compatible != null)
	assert(compatible["schemaVersion"] == 1)
	assert(compatible["revision"] == 4)
	assert(compatible["storyBeatsSeen"] == loaded["storyBeatsSeen"])
	var committed: Dictionary = Reducer.apply(compatible, test_event, extended)
	assert(committed.get("ok", false))
	assert(not committed.get("duplicate", true))
	assert(committed["state"]["storyBeatsSeen"].has(new_beat))
	assert(committed["state"]["revision"] == 5)
	var retry: Dictionary = Reducer.apply(committed["state"], test_event, extended)
	assert(retry.get("ok", false) and retry.get("duplicate", false))
	assert(retry["state"]["revision"] == 5)
	var projected_new: Variant = Snapshot.normalize(committed["state"], extended)
	assert(projected_new["storyBeatsSeen"].has(new_beat))
	assert(projected_new["storyBeatsSeen"].has("RM-BEAT-00-01"))
	var rollback_projection: Variant = Snapshot.normalize(committed["state"], old_catalog)
	assert(rollback_projection != null)
	assert(not rollback_projection["storyBeatsSeen"].has(new_beat),
		"Rollback to old registry drops unrecognized beat; migration requires approval")
	assert(rollback_projection["storyBeatsSeen"].has("RM-BEAT-00-01"))
	assert(rollback_projection["revision"] == 5)
	assert(facade.load_campaign()["revision"] == 4,
		"Rehearsal must not change persisted campaign save")
	assert(temporary_store.remove_item(str(Contract.data.ravenKey)))
	assert(temporary_store.remove_item(str(Contract.data.ravenRecoveryKey)))
	assert(Snapshot.SCHEMA_VERSION == 1)
	assert(Catalog.data.storyBeats.find(new_beat) == -1,
		"Smoke must never register new content in canonical catalog")
	print("Raven VN VNS5-06D2A save and rollback projection smoke passed")
	quit()
