extends Node2D
## MAP-GAME-01A: isolated gameplay integration harness.
##
## This node composes only the existing authored `ManorRoomTransitionController`
## and owner-approved Evelyn (inheriting the existing `OnoeSegmentMover`).
## It owns no save, no Camera2D and no map coordinates.
## Movement starts exclusively from authored hotspots/transitions; a screen or
## ground point is always rejected. Camera and room changes are proposals for a
## future host, and checkpoints are proposals the caller must persist through
## `raven_campaign_store.gd` + reducer.
const Mover = preload("res://scripts/raven/onoe_segment_mover.gd") # Stable movement API.
const EvelynScene = preload("res://scenes/raven/actors/evelyn_walker.tscn")
const Controller = preload("res://scripts/raven/manor_room_transition_controller.gd")

signal room_changed(proposal: Dictionary)
signal checkpoint_proposed(proposal: Dictionary)

var controller: Controller
var actor: Mover
var source_result: Dictionary = {}
var error_text := ""

var _configured := false
var _active_token := 0
var _active_to := ""
var _reported_room := ""
var _camera_room := ""


## Add this harness to the scene tree before calling configure so Evelyn's
## visual child can initialise. The source must be a successful
## `manor_navigation_source.resolve()` result with movement enabled.
func configure(source: Dictionary, snapshot: Dictionary = {}) -> bool:
	error_text = ""
	if _configured:
		return _fail("harness-already-configured")
	if str(source.get("kind", "")) != "raven-navigation-source" \
			or not bool(source.get("ok", false)) or str(source.get("status", "")) != "ready" \
			or not bool(source.get("movementEnabled", false)):
		return _fail("navigation-source-unavailable")
	var contract: Variant = source.get("contract", {})
	var initial_room := str(source.get("initialRoomId", ""))
	var initial_anchor := str(source.get("initialAnchorId", ""))
	if not contract is Dictionary or initial_room.is_empty() or initial_anchor.is_empty():
		return _fail("navigation-source-incomplete")
	# TEST_ONLY candidates use their own virtual doors. Production geometry is
	# re-gated from the authoritative snapshot, never from static trust.
	var gates: Dictionary = {}
	if not bool(source.get("draftOnly", true)):
		gates = {"unlockedDoors": snapshot.get("unlockedDoors", []).duplicate()}
	var trial = Controller.new()
	if not trial.configure(contract, initial_room, initial_anchor, gates):
		return _fail("transition-contract:" + trial.error_text)
	controller = trial
	actor = EvelynScene.instantiate() as Mover
	if actor == null:
		return _fail("evelyn-actor-unavailable")
	actor.sprite_height = float(source.get("visuals", {}).get(initial_room, {}).get("actorHeight", 62.0))
	actor.z_index = 8
	actor.move_speed = 160.0
	add_child(actor)
	# The gameplay caller drives advance(delta); do not double-advance via _process.
	actor.set_process(false)
	actor.position = controller.anchor_position(initial_anchor)
	source_result = source.duplicate(true)
	_reported_room = initial_room
	_camera_room = initial_room
	_configured = true
	return true


func request_hotspot(hotspot_id: String) -> Dictionary:
	if not _configured:
		return _fail_dict("harness-not-configured")
	return controller.request_room_hotspot(hotspot_id, actor)


func request_transition(transition_id: String) -> Dictionary:
	if not _configured:
		return _fail_dict("harness-not-configured")
	return controller.request_transition(transition_id, actor)


## There is no free tap-to-move. Even a valid authored coordinate is rejected;
## only an authored hotspot can start a route.
func request_screen_point(_point: Vector2) -> Dictionary:
	return {"ok": false, "error": "free-tap-to-move-disabled", "movement": false}


func cancel_request() -> Dictionary:
	if not _configured:
		return _fail_dict("harness-not-configured")
	return controller.cancel_transition()


## One deterministic step: dispatch one authorized segment or advance it.
func advance(delta: float = 0.05) -> Dictionary:
	if not _configured:
		return _fail_dict("harness-not-configured")
	if actor.has_active_segment():
		actor.advance(delta)
		if actor.has_active_segment():
			return {"ok": true, "status": "moving"}
		var token := _active_token
		var arrived := _active_to
		_active_token = 0
		_active_to = ""
		var outcome: Dictionary = controller.accept_segment_arrival(token, arrived, actor.position, actor)
		if not controller.ready_transition().is_empty():
			return {
				"ok": true,
				"status": "ready",
				"transitionId": controller.ready_transition(),
				"anchorId": controller.confirmed_anchor(),
			}
		# Normal room hotspots arrive without a handoff; give them one stable
		# status so callers do not need to know controller internals.
		if str(outcome.get("status", "")) == "room-hotspot-arrived":
			outcome.status = "arrived"
			outcome.anchorId = controller.confirmed_anchor()
		return outcome
	var next: Dictionary = controller.next_segment(actor)
	if next.is_empty():
		return {"ok": true, "status": "idle"}
	if bool(next.get("arrived", false)):
		if not controller.ready_transition().is_empty():
			return {
				"ok": true,
				"status": "ready",
				"transitionId": controller.ready_transition(),
				"anchorId": controller.confirmed_anchor(),
			}
		return {
			"ok": true,
			"status": "arrived",
			"hotspotId": str(next.get("hotspotId", "")),
			"anchorId": controller.confirmed_anchor(),
		}
	var token := int(next.get("segmentToken", 0))
	if token == 0 or not actor.start_segment(next):
		if token != 0:
			controller.report_dispatch_failure(token)
		return {"ok": false, "status": "error", "error": "segment-dispatch-failed"}
	_active_token = token
	_active_to = str(next.get("toAnchorId", ""))
	return {"ok": true, "status": "segment_started", "toAnchorId": _active_to}


## Settle a requested route. Stops on arrival, transition-ready or failure.
func drive(max_steps: int = 4000, delta: float = 0.05) -> Dictionary:
	if not _configured:
		return _fail_dict("harness-not-configured")
	var last := {"ok": true, "status": "idle"}
	for _step in range(max_steps):
		last = advance(delta)
		if not bool(last.get("ok", false)):
			return last
		var status := str(last.get("status", ""))
		if status in ["idle", "arrived", "ready"]:
			return last
	return {"ok": false, "status": "error", "error": "movement-did-not-settle"}


## Commit a ready TEST_ONLY/PRODUCTION_APPROVED handoff. The controller has
## already verified the physical approach; this never persists a save.
func commit_transition() -> Dictionary:
	if not _configured:
		return _fail_dict("harness-not-configured")
	var result: Dictionary = controller.commit_transition(actor)
	if bool(result.get("ok", false)):
		emit_signal("room_changed", room_state())
	return result


func checkpoint_proposal(event_id: String) -> Dictionary:
	if not _configured or actor.has_active_segment() or event_id.is_empty():
		return {}
	var graph = controller.room_graph(controller.room_id())
	if graph == null:
		return {}
	var proposal: Dictionary = graph.checkpoint_event(controller.confirmed_anchor(), event_id)
	if not proposal.is_empty():
		emit_signal("checkpoint_proposed", proposal.duplicate(true))
	return proposal


func room_state() -> Dictionary:
	if not _configured:
		return {}
	var room := controller.room_id()
	return {
		"roomId": room,
		"previousReportedRoomId": _reported_room,
		"anchorId": controller.confirmed_anchor(),
		"roomChanged": room != _reported_room,
		"approval": str(source_result.get("approval", "")),
		"draftOnly": bool(source_result.get("draftOnly", true)),
		"movementEnabled": true,
	}


func acknowledge_room() -> void:
	if _configured:
		_reported_room = controller.room_id()


func camera_proposal() -> Dictionary:
	if not _configured:
		return {}
	var anchor := controller.confirmed_anchor()
	var point: Vector2 = controller.anchor_position(anchor)
	var room := controller.room_id()
	return {
		"roomId": room,
		"focusAnchorId": anchor,
		"position": [point.x, point.y],
		"zoom": 1.0,
		"roomChanged": room != _camera_room,
		"resetOnRoomChange": true,
		"cameraNode": null,
	}


func acknowledge_camera() -> void:
	if _configured:
		_camera_room = controller.room_id()


func movement_enabled() -> bool:
	return _configured


func _fail(reason: String) -> bool:
	error_text = reason
	return false


func _fail_dict(reason: String) -> Dictionary:
	return {"ok": false, "error": reason}
