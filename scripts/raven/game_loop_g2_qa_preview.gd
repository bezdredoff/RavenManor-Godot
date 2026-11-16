extends Node2D
## GAME-LOOP-01 G2 human-review harness. Isolated TEST_ONLY runtime:
## no production saves, menus, canonical geometry or actor integration edits.
## Open res://scenes/raven/tests/game_loop_g2_qa_preview.tscn in Godot.

const Host = preload("res://scripts/raven/raven_gameplay_host.gd")
const Source = preload("res://scripts/raven/manor_navigation_source.gd")
const Store = preload("res://scripts/raven/raven_campaign_store.gd")
const Snapshot = preload("res://scripts/raven/raven_snapshot.gd")
const Reducer = preload("res://scripts/raven/raven_reducer.gd")
const Memory = preload("res://tests/support/memory_storage.gd")
const ART = preload("res://a_detailed_top_down_isometric_game_map_illustratio.png")
const QA_PATH := "res://assets/raven/map/qa/drafts/map_qa_08_visual_candidate.v1.json"

var host
var memory: RefCounted
var camera: Camera2D
var ui_layer: CanvasLayer
var status: Label
var overlay: Control
var _moving := false
var _paused := false
var _closing := false


func _ready() -> void:
	var image := Sprite2D.new()
	image.texture = ART
	image.centered = false
	image.z_index = -10
	add_child(image)
	camera = Camera2D.new()
	camera.zoom = Vector2.ONE * 0.75
	add_child(camera)
	camera.make_current()
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)
	memory = Memory.new()
	var initial: Dictionary = Snapshot.fresh()
	for beat in ["RM-BEAT-00-01", "RM-BEAT-00-02", "RM-BEAT-00-03", "RM-BEAT-01-01"]:
		var changed: Dictionary = Reducer.apply(initial, {
			"eventId": "g2-preview-" + beat, "type": "story_beat_seen", "storyBeatId": beat})
		if not changed.get("ok", false):
			push_error("QA intro fixture event refused")
			return
		initial = changed.state
	if not Store.new(memory).save_campaign(initial):
		push_error("QA fixture could not be seeded")
		return
	host = Host.new(memory, true)
	add_child(host)
	var request: Dictionary = {
		"schemaVersion": 1, "kind": Source.REQUEST_KIND, "mode": "qa",
		"allowQaCandidate": true, "qaSourceKind": "project", "qaSourcePath": QA_PATH,
		"qaStoryHotspots": {
			"RM-HS-005": "QA-HS:QA-CORRIDOR-EAST",
			"RM-HS-002": "QA-HS:QA-BEDROOM-RUG",
		},
		"qaTransitionDoors": {
			"QA-07B-TR-HC": "RM-DOOR-HALL-CORRIDOR",
			"QA-07B-TR-CH": "RM-DOOR-HALL-CORRIDOR",
			"QA-07B-TR-CB": "RM-DOOR-CORRIDOR-BEDROOM",
			"QA-07B-TR-BC": "RM-DOOR-CORRIDOR-BEDROOM",
	},
	}
	var start: Dictionary = host.configure(request)
	if not start.get("ok", false):
		push_error("G2 QA source unavailable: " + str(start))
		return
	_build_panel()
	_log("QA only · " + str(start.get("roomId", "")) +
		" · HC/CB are synthetic, NOT approved physical doors")


func _build_panel() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(12, 12)
	panel.custom_minimum_size = Vector2(340, 0)
	ui_layer.add_child(panel)
	var column := VBoxContainer.new()
	panel.add_child(column)
	var title := Label.new()
	title.text = "GAME-LOOP-01 G2 · TEST ONLY"
	column.add_child(title)
	_button(column, "Hall → Corridor (HC)", func(): _transition("QA-07B-TR-HC"))
	_button(column, "Corridor → Hall (CH)", func(): _transition("QA-07B-TR-CH"))
	_button(column, "Corridor → Bedroom (CB)", func(): _transition("QA-07B-TR-CB"))
	_button(column, "Bedroom → Corridor (BC)", func(): _transition("QA-07B-TR-BC"))
	_button(column, "RM-HS-005 · clear bedroom access", func(): _story("RM-HS-005"))
	_button(column, "RM-HS-002 · restore bedroom", func(): _story("RM-HS-002"))
	_button(column, "Cancel", _cancel)
	_button(column, "Pause / Resume", _pause)
	_button(column, "Continue from safe checkpoint", _reload)
	_button(column, "Close VN / Match-3", _close_overlay)
	status = Label.new()
	status.custom_minimum_size = Vector2(320, 90)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(status)


func _button(parent: Node, copy: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = copy
	button.pressed.connect(callback)
	parent.add_child(button)


func _story(id: String) -> void:
	if host == null or is_instance_valid(overlay):
		return
	var response: Dictionary = host.request_story_hotspot(id)
	_log("Story " + id + ": " + str(response))
	_moving = bool(response.get("ok", false))


func _transition(id: String) -> void:
	if host == null or is_instance_valid(overlay):
		return
	var response: Dictionary = host.request_transition(id)
	_log("Door " + id + ": " + str(response))
	_moving = bool(response.get("ok", false))


func _process(delta: float) -> void:
	if host == null or host.navigation == null:
		return
	camera.position = host.navigation.actor.position
	if _moving and not _paused:
		var result: Dictionary = host.advance(delta)
		if not result.get("ok", false):
			_moving = false
			_log("Held/rejected: " + str(result))
		elif str(result.get("status", "")) == "ready":
			_moving = false
			var crossing: Dictionary = host.commit_ready_transition()
			_log("Confirmed doorway: " + str(crossing))
		elif str(result.get("status", "")) == "action-committed":
			_moving = false
			_log("Arrived; story committed: " + str(result.get("nextStep", "")))
			_open_overlay()
		elif str(result.get("status", "")) in ["idle", "arrived"]:
			_moving = false
	if is_instance_valid(overlay) and not _closing:
		var step_id := str(overlay.step.get("id", ""))
		if step_id in ["restore1", "level2"]:
			_closing = true
			call_deferred("_complete_overlay", step_id)


func _open_overlay() -> void:
	if is_instance_valid(overlay):
		return
	overlay = host.mount_presentation(ui_layer)
	if overlay == null:
		_log("Presentation is not currently available")


func _complete_overlay(next: String) -> void:
	_close_overlay()
	_log("Gameplay persisted · next: " + next)


func _close_overlay() -> void:
	if host == null:
		return
	if is_instance_valid(overlay):
		host.close_presentation()
		overlay = null
	else:
		host.close_presentation()
	_closing = false
	_log("UI closed · current step: " + str(host.current_activity().get("id", "")))


func _cancel() -> void:
	if host != null:
		_log("Cancel: " + str(host.cancel()))
		# If a leg is already in flight it is acknowledged safely, then stops.


func _pause() -> void:
	if host != null:
		_paused = not _paused
		host.set_paused(_paused)
		_log("Paused" if _paused else "Resumed")


func _reload() -> void:
	if host == null:
		return
	_close_overlay()
	_moving = false
	_paused = false
	var result: Dictionary = host.reload_session()
	_log("Continue: " + str(result))


func _log(message: String) -> void:
	if is_instance_valid(status):
		status.text = message
