extends SceneTree
## Actual rendered player-view evidence. Run with a GPU or xvfb, not --headless.
const Map = preload("res://tests/support/g2_player_map_fixture.gd")
const Host = preload("res://scripts/raven/raven_gameplay_host.gd")
const Memory = preload("res://tests/support/memory_storage.gd")
const Store = preload("res://scripts/raven/raven_campaign_store.gd")
const Snapshot = preload("res://scripts/raven/raven_snapshot.gd")
const Reducer = preload("res://scripts/raven/raven_reducer.gd")
var map
var output := "res://build/map-prod-01"

func _initialize() -> void:
	call_deferred("_run")

func _shot(name: String, focus: Vector2, zoom: float = 2.0) -> void:
	map.camera.position = focus
	map.camera.zoom = Vector2.ONE * zoom
	map.camera.force_update_scroll()
	await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(output.path_join(name)) == OK)
	print("G2 integrated GPU capture: " + name)

func _cross(door: String, name: String, contact: Vector2) -> void:
	for transition in map.host.source.contract.transitions:
		if transition.doorId == door and transition.sourceRoomId == map.host.room_state().roomId:
			map._request_door(str(transition.id))
			break
	assert(map._moving)
	var at_contact := false
	var under_landing := false
	for _tick in range(10000):
		map._process(0.025)
		var feet: Vector2 = map.host.navigation.actor.position
		if not under_landing and door == "RM-DOOR-HALL-CORRIDOR" and absf(feet.x - 952) < 0.1 and absf(feet.y - 628) < 2.1:
			under_landing = true
			await _shot(name + "-under-landing.png", Vector2(952, 608))
		if not at_contact and feet.distance_to(contact) < 0.1:
			at_contact = true
			await _shot(name + "-contact.png", contact)
		if not map._moving:
			break
	assert(at_contact, "Rendered route must pass exact physical portal")
	if is_instance_valid(map.overlay):
		map._dismiss_presentation()
		await process_frame

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	root.size = Vector2i(390, 844)
	root.content_scale_size = Vector2i(390, 844)
	var storage = Memory.new()
	var state := Snapshot.fresh()
	for beat in ["RM-BEAT-00-01", "RM-BEAT-00-02", "RM-BEAT-00-03", "RM-BEAT-01-01"]:
		state = Reducer.apply(state, {"eventId": "capture-" + beat, "type": "story_beat_seen", "storyBeatId": beat}).state
	assert(Store.new(storage).save_campaign(state))
	map = Map.new()
	map.host = Host.new(storage, true)
	root.add_child(map)
	map.set_process(false)
	await process_frame
	assert(map._ready_for_input, map.status.text)
	map.prefs.set_locale("en")
	await _shot("G2-player-map-390x844.png", map.host.navigation.actor.position, 1.0)
	map.ui_layer.visible = false
	map.targets.visible = false
	root.size = Vector2i(960, 720)
	root.content_scale_size = Vector2i(960, 720)
	await _cross("RM-DOOR-HALL-CORRIDOR", "G2-HC-forward", Vector2(952, 528))
	map._request_story("RM-HS-005")
	for _tick in range(10000):
		map._process(0.025)
		if not map._moving:
			break
	assert(map.host.state.unlockedDoors.has("RM-DOOR-CORRIDOR-BEDROOM"))
	await _cross("RM-DOOR-CORRIDOR-BEDROOM", "G2-CB-forward", Vector2(656, 504))
	await _cross("RM-DOOR-CORRIDOR-BEDROOM", "G2-CB-return", Vector2(656, 504))
	await _cross("RM-DOOR-HALL-CORRIDOR", "G2-HC-return", Vector2(952, 528))
	map.queue_free()
	quit()
