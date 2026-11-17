extends SceneTree
## GAME-LOOP-02 standalone contract smoke (Agent E owns shared runner registration).
## godot --headless --path . --script res://tests/raven/game_loop_02_player_map_smoke.gd
const Entry = preload("res://scripts/raven/raven_player_map_entry.gd")
const PlayerMap = preload("res://scripts/raven/raven_player_map.gd")
const Source = preload("res://scripts/raven/manor_navigation_source.gd")
const Controller = preload("res://scripts/raven/manor_room_transition_controller.gd")
const Snapshot = preload("res://scripts/raven/raven_snapshot.gd")
const Host = preload("res://scripts/raven/raven_gameplay_host.gd")
const Memory = preload("res://tests/support/memory_storage.gd")

const DOOR := "RM-DOOR-HALL-CORRIDOR"

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var fresh: Dictionary = Snapshot.fresh()
	assert(not Entry.can_enter(fresh), "Never skip the authored opening VN")
	var after_intro: Dictionary = fresh.duplicate(true)
	for beat in ["RM-BEAT-00-01", "RM-BEAT-00-02", "RM-BEAT-00-03", "RM-BEAT-01-01"]:
		after_intro.storyBeatsSeen.append(beat)
	var selection: Dictionary = Source.resolve({
		"schemaVersion": Source.SCHEMA_VERSION, "kind": Source.REQUEST_KIND,
		"mode": Source.MODE_PRODUCTION, "snapshot": after_intro,
	})
	var ready := bool(selection.get("ok", false)) and bool(selection.get("movementEnabled", false)) \
		and not bool(selection.get("draftOnly", true)) \
		and str(selection.get("approval", "")) == Source.PRODUCTION_APPROVAL
	assert(Entry.can_enter(after_intro) == ready, "Only canonical approved source allows map entry")
	assert(ResourceLoader.exists(Entry.MAP_SCENE), "Player map scene not in normal build")
	assert(load(Entry.MAP_SCENE) is PackedScene, "Player map must be a playable scene")
	assert(PlayerMap.LABELS.has("ru") and PlayerMap.LABELS.has("be") and PlayerMap.LABELS.has("en"))
	assert(PlayerMap.HOTSPOT_NAMES.has("RM-HS-005") and PlayerMap.HOTSPOT_NAMES.has("RM-HS-002"))
	# The actual production host never accepts fake geometry, even if the
	# caller attempts to mark a fixture as PRODUCTION_APPROVED.
	var isolated = Host.new(Memory.new(), true)
	root.add_child(isolated)
	await process_frame
	assert(isolated.configure({
		"schemaVersion": Source.SCHEMA_VERSION, "kind": Source.REQUEST_KIND,
		"mode": Source.MODE_PRODUCTION, "worldPlan": {"provenance": {
			"approval": Source.PRODUCTION_APPROVAL}},
	}).get("error", "") == "injected-production-plan-forbidden")
	assert(isolated.navigation == null)
	isolated.queue_free()
	# Production gate refresh must be snapshot-only, preserve physical room
	# and confirmed anchor, and reject malformed or TEST_ONLY updates.
	var controller = Controller.new()
	assert(controller.configure(_production_contract(), "RM-ROOM-HALL", "H0",
		{"unlockedDoors": []}), controller.error_text)
	assert(controller.room_id() == "RM-ROOM-HALL" and controller.confirmed_anchor() == "H0")
	assert(not controller._unlocked_doors.has(DOOR))
	assert(not controller.refresh_production_doors({"unlockedDoors": "fake"}, null))
	assert(controller.refresh_production_doors({"unlockedDoors": [DOOR]}, null))
	assert(controller._unlocked_doors.has(DOOR))
	assert(controller.room_id() == "RM-ROOM-HALL" and controller.confirmed_anchor() == "H0",
		"No relocation on door unlock")
	assert(controller.refresh_production_doors({"unlockedDoors": []}, null))
	assert(not controller._unlocked_doors.has(DOOR))
	assert(controller.room_id() == "RM-ROOM-HALL" and controller.confirmed_anchor() == "H0",
		"No mid-wall relocation on door lock")
	print("GAME-LOOP-02 player map entry and production gate refresh smoke passed")
	quit()


func _production_contract() -> Dictionary:
	var hall := {"id": "RM-ROOM-HALL", "graph": {
		"anchors": [
			{"id": "H0", "roomId": "RM-ROOM-HALL", "position": [0, 0], "kind": "safe"},
			{"id": "H1", "roomId": "RM-ROOM-HALL", "position": [10, 0],
				"kind": "interaction", "hotspotId": "HALL-DOOR"},
		],
		"edges": [{"from": "H0", "to": "H1"}],
	}}
	var corridor := {"id": "RM-ROOM-CORRIDOR", "graph": {
		"anchors": [
			{"id": "C0", "roomId": "RM-ROOM-CORRIDOR", "position": [20, 0], "kind": "safe"},
			{"id": "C1", "roomId": "RM-ROOM-CORRIDOR", "position": [30, 0],
				"kind": "interaction", "hotspotId": "CORRIDOR-DOOR"},
		],
		"edges": [{"from": "C0", "to": "C1"}],
	}}
	var hc := {"id": "HC", "sourceRoomId": "RM-ROOM-HALL",
		"destinationRoomId": "RM-ROOM-CORRIDOR", "approachAnchorId": "H1",
		"destinationEntryAnchorId": "C0", "reverseTransitionId": "CH",
		"doorId": DOOR, "authority": Source.PRODUCTION_APPROVAL,
		"physicalPortalApproved": true}
	var ch := {"id": "CH", "sourceRoomId": "RM-ROOM-CORRIDOR",
		"destinationRoomId": "RM-ROOM-HALL", "approachAnchorId": "C1",
		"destinationEntryAnchorId": "H0", "reverseTransitionId": "HC",
		"doorId": DOOR, "authority": Source.PRODUCTION_APPROVAL,
		"physicalPortalApproved": true}
	return {"schemaVersion": 1, "kind": "raven-authored-room-transitions",
		"approval": Source.PRODUCTION_APPROVAL, "draftAuthority": "NONE",
		"rooms": [hall, corridor], "doors": [{"id": DOOR, "status": "gated"}],
		"transitions": [hc, ch]}
