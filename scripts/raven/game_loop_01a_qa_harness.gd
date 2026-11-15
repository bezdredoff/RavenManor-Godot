extends Node2D

## Explicit QA scene: real RM-HS-005 -> Match-3 -> RM-HS-002 -> VN.
## The map is greybox TEST_ONLY, seed lives in memory, and gameplay uses
## the existing vertical_slice UI/store plus the existing physical Onoe mover.
const Bridge = preload("res://scripts/raven/raven_hotspot_gameplay_bridge.gd")
const Memory = preload("res://tests/support/memory_storage.gd")
const Store = preload("res://scripts/raven/raven_campaign_store.gd")
const Snapshot = preload("res://scripts/raven/raven_snapshot.gd")
const Reducer = preload("res://scripts/raven/raven_reducer.gd")
const Slice = preload("res://scenes/raven/vertical_slice.tscn")

@onready var actor = $Onoe
@onready var camera: Camera2D = $Camera2D
@onready var layer: CanvasLayer = $UILayer

var bridge
var memory: RefCounted
var gameplay: Control
var message_label: Label
var _closing_gameplay := false


func _ready() -> void:
	memory = Memory.new()
	var fixture: Dictionary = Snapshot.fresh()
	# Real prelude IDs: QA explicitly simulates the already-watched intro;
	# no production save, story data or canonical gates are changed.
	for beat in ["RM-BEAT-00-01", "RM-BEAT-00-02", "RM-BEAT-00-03", "RM-BEAT-01-01"]:
		var changed: Dictionary = Reducer.apply(fixture, {
			"eventId": "loop01a-preview-" + beat,
			"type": "story_beat_seen", "storyBeatId": beat})
		if not changed.get("ok", false):
			push_error("QA seed rejected")
			return
		fixture = changed.state
	if not Store.new(memory).save_campaign(fixture):
		push_error("QA seed save failed")
		return
	bridge = Bridge.new(memory)
	actor.position = bridge.graph.position(bridge.session.current_anchor())
	actor.set_sprite_height(62.0)
	actor.move_speed = 270.0
	actor.segment_completed.connect(_on_segment_completed)
	camera.make_current()
	camera.zoom = Vector2.ONE * 0.8
	_build_ui()
	_status("TEST ONLY · Intro seeded in memory. Select RM-HS-005 to clear bedroom access.")
	queue_redraw()


func _build_ui() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(12, 12)
	panel.custom_minimum_size = Vector2(355, 0)
	layer.add_child(panel)
	var content := VBoxContainer.new()
	panel.add_child(content)
	var title := Label.new()
	title.text = "GAME-LOOP-01A · GREYBOX · QA ONLY"
	content.add_child(title)
	_button(content, "RM-HS-005 · Clear bedroom door", func(): _request("RM-HS-005"))
	_button(content, "RM-HS-002 · Restore bedroom", func(): _request("RM-HS-002"))
	_button(content, "Cancel next route / keep current leg", _cancel)
	_button(content, "Reload from in-memory safe checkpoint", _reload)
	_button(content, "Close VN / Match-3 preview", _close_gameplay)
	message_label = Label.new()
	message_label.custom_minimum_size = Vector2(345, 72)
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(message_label)


func _button(parent: Container, copy: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = copy
	button.pressed.connect(callback)
	parent.add_child(button)


func _status(copy: String) -> void:
	if is_instance_valid(message_label):
		message_label.text = copy


func _request(hotspot_id: String) -> void:
	if bridge == null or is_instance_valid(gameplay):
		return
	var result: Dictionary = bridge.request_hotspot(hotspot_id)
	_status("Request %s: %s" % [hotspot_id, str(result.get("status", result.get("error", "?")))])
	if result.get("ok", false):
		_pump()


func _pump() -> void:
	if bridge == null or actor.has_active_segment() or is_instance_valid(gameplay):
		return
	var leg: Dictionary = bridge.next_segment()
	if leg.has("presentation"):
		_open_gameplay(leg)
		return
	if leg.is_empty():
		return
	if not leg.has("toAnchorId"):
		_status("Route blocked: " + str(leg.get("error", "unknown")))
		return
	if not actor.start_segment(leg):
		bridge.cancel()
		_status("Physical movement refused; no story action committed")


func _on_segment_completed(anchor_id: String, actual_position: Vector2) -> void:
	if bridge == null or actual_position.distance_to(bridge.graph.position(anchor_id)) > 0.01:
		_status("Unexpected physical arrival; no action committed")
		return
	var result: Dictionary = bridge.finish_segment(anchor_id)
	if not result.get("ok", false):
		_status("Arrival rejected: " + str(result.get("error", "unknown")))
		return
	if result.has("presentation"):
		_open_gameplay(result)
	else:
		_status("Confirmed: " + anchor_id + " · " + str(result.get("status", "")))
		_pump()


func _open_gameplay(result: Dictionary) -> void:
	if is_instance_valid(gameplay):
		return
	# Reuse the complete UPDS-derived VN shell / Raven Match-3 controller.
	# Inject the one in-memory RavenCampaignStore before _ready().
	gameplay = Slice.instantiate()
	gameplay.store = bridge.store
	layer.add_child(gameplay)
	_status("Real gameplay UI: " + str(result.get("nextStep", "?")))


func _process(_delta: float) -> void:
	if bridge == null:
		return
	camera.position = actor.position
	# The real vertical slice handles each board, read-only Skip, locale,
	# checkpoint/reward and VN completion. Map QA retakes control only at
	# the next authored hotspot, or after the bedroom VN beat.
	if is_instance_valid(gameplay) and not _closing_gameplay:
		var current: String = str(gameplay.step.get("id", ""))
		if current == "restore1" or current == "level2":
			_closing_gameplay = true
			call_deferred("_complete_ui_handoff", current)


func _complete_ui_handoff(current: String) -> void:
	_close_gameplay()
	_status("Gameplay committed · next: " +
		("Select RM-HS-002 on the map" if current == "restore1" else
		"Bedroom VN complete; later bathroom work remains in legacy slice"))


func _close_gameplay() -> void:
	if is_instance_valid(gameplay):
		gameplay.queue_free()
		gameplay = null
	if bridge != null:
		bridge.refresh()
	_closing_gameplay = false
	queue_redraw()


func _cancel() -> void:
	if bridge == null:
		return
	var result: Dictionary = bridge.cancel()
	_status("Cancelled: current physical leg finishes safely" if
		result.get("finishCurrentSegment", false) else "Cancelled: no active movement")


func _reload() -> void:
	if bridge == null or actor.has_active_segment():
		_status("Reload refused in flight; cancel and finish current leg")
		return
	_close_gameplay()
	var safe_anchor: String = bridge.reload()
	# Explicit QA scene re-spawn, never a mid-route teleport in production.
	actor.position = bridge.graph.position(safe_anchor)
	_status("Reloaded in-memory Raven save at " + safe_anchor)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2(40, 160), Vector2(820, 1300)), Color("#202631"))
	if bridge == null:
		return
	for edge in bridge.graph.active_edges():
		draw_line(bridge.graph.position(str(edge.get("from", ""))),
			bridge.graph.position(str(edge.get("to", ""))), Color("#65c0d7"), 4.0)
	for id in bridge.graph.anchors():
		var anchor: Dictionary = bridge.graph.anchor(str(id))
		var pos: Vector2 = bridge.graph.position(str(id))
		var hotspot := str(anchor.get("hotspotId", ""))
		draw_circle(pos, 11.0, Color("#f5c576") if not hotspot.is_empty() else Color("#78b4a5"))
