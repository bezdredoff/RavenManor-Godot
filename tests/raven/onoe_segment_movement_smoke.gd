extends SceneTree

## MAP-QA-02: deterministic headless test; NO canonical map or saved campaign writes.
const ACTOR = preload("res://scenes/raven/tests/onoe_segment_actor.tscn")
const LAB = preload("res://scenes/raven/tests/onoe_movement_lab.tscn")
const Graph = preload("res://scripts/raven/manor_navigation_graph.gd")
const Session = preload("res://scripts/raven/manor_route_session.gd")
const Snapshot = preload("res://scripts/raven/raven_snapshot.gd")

var _completed: Array[Dictionary] = []


func _initialize() -> void:
	call_deferred("_run")


func _leg(actor: Node2D, direction: Vector2, label: String, sprite: AnimatedSprite2D) -> void:
	var source: Vector2 = actor.position
	var segment := {
		"fromAnchorId": label + "-FROM", "toAnchorId": label,
		"fromPosition": source, "toPosition": source + direction
	}
	assert(actor.start_segment(segment))
	assert(actor.has_active_segment())
	var clip := "side" if absf(direction.x) > absf(direction.y) else ("down" if direction.y > 0 else "up")
	assert(sprite.animation == clip)
	assert(sprite.flip_h == (clip == "side" and direction.x < 0))
	assert(sprite.is_playing())
	actor.advance(0.05)
	assert(actor.has_active_segment())
	assert(actor.position != segment.toPosition, "Short step must never prematurely finish")
	assert(_completed.is_empty(), "No premature completion")
	var rounds := 0
	while actor.has_active_segment() and rounds < 40:
		actor.advance(0.05)
		rounds += 1
	assert(not actor.has_active_segment(), "Segment must finish after real movement")
	assert(actor.position.is_equal_approx(segment.toPosition))
	assert(_completed.size() == 1 and _completed[0].id == label)
	assert(_completed[0].point == actor.position)
	assert(not sprite.is_playing() and sprite.frame == 0, "Idle = first frame")
	_completed.clear()


func _run() -> void:
	assert(LAB != null, "Standalone lab must load")
	var actor := ACTOR.instantiate()
	root.add_child(actor)
	await process_frame
	var sprite: AnimatedSprite2D = actor.get_sprite()
	assert(sprite != null and sprite.sprite_frames != null)
	var frames: SpriteFrames = sprite.sprite_frames
	assert(frames.get_animation_names().has("down"))
	assert(frames.get_animation_names().has("up"))
	assert(frames.get_animation_names().has("side"))
	assert(frames.get_frame_count("down") == 4)
	assert(frames.get_frame_count("up") == 4)
	assert(frames.get_frame_count("side") == 8)
	assert(is_equal_approx(frames.get_animation_speed("down"), 7.0))
	assert(is_equal_approx(frames.get_animation_speed("side"), 10.0))
	for clip in ["down", "up", "side"]:
		for index in range(frames.get_frame_count(clip)):
			var atlas: AtlasTexture = frames.get_frame_texture(clip, index) as AtlasTexture
			assert(atlas != null and atlas.atlas != null, "Every real sheet frame loads")
	assert(sprite.animation == "down" and not sprite.is_playing() and sprite.frame == 0)
	assert(actor.position == Vector2.ZERO, "Node origin is physical footpoint")
	assert(is_equal_approx(sprite.position.y + 384.0 * sprite.scale.y * 0.5, 0.0))
	actor.set_sprite_height(125.0)
	assert(is_equal_approx(actor.get_sprite().position.y, -62.5))
	actor.set_sprite_height(104.0)
	actor.segment_completed.connect(_on_completed)
	actor.move_speed = 300.0
	_leg(actor, Vector2(70.0, 0.0), "RIGHT", sprite)
	_leg(actor, Vector2(-70.0, 0.0), "LEFT", sprite)
	_leg(actor, Vector2(0.0, -65.0), "UP", sprite)
	_leg(actor, Vector2(0.0, 65.0), "DOWN", sprite)
	assert(is_equal_approx(sprite.position.y + 384.0 * sprite.scale.y * 0.5, 0.0))

	# Pause is a physical hold; cannot signal a segment complete or checkpoint.
	var pause_seg := {
		"fromAnchorId": "P0", "toAnchorId": "P1",
		"fromPosition": actor.position, "toPosition": actor.position + Vector2(120, 0)
	}
	assert(actor.start_segment(pause_seg))
	actor.advance(0.12)
	var foot_before_pause: Vector2 = actor.position
	assert(actor.pause_segment())
	assert(not actor.pause_segment())
	actor.advance(2.0)
	assert(actor.position == foot_before_pause and _completed.is_empty())
	assert(actor.is_paused() and actor.has_active_segment())
	assert(not actor.start_segment(pause_seg), "Cannot start a different segment while paused")
	assert(actor.resume_segment())
	actor.advance(1.0)
	assert(actor.position == pause_seg.toPosition and _completed.size() == 1)
	_completed.clear()
	
	# A different segment cannot restart from the old anchor while in flight.
	var state := Snapshot.fresh()
	var graph := Graph.new()
	graph.rebuild(state)
	var session := Session.new(graph)
	var safe_id: String = session.restore(state)
	assert(safe_id == "RM-NAV-HALL-SPAWN")
	actor.position = graph.position(safe_id)  # Test-only initial spawn, never during a leg.
	assert(session.request_hotspot("RM-HS-003").ok)
	var authorized: Dictionary = session.next_segment()
	assert(not authorized.is_empty())
	assert(actor.start_segment(authorized))
	actor.advance(0.1)
	var mid_leg: Vector2 = actor.position
	assert(mid_leg != authorized.fromPosition and mid_leg != authorized.toPosition)
	assert(session.current_anchor() == safe_id, "No confirmed arrival from visual progress")
	assert(session.checkpoint_event("onoe-early-checkpoint").is_empty())
	assert(not session.finish_segment("RM-NAV-HS-003").ok)
	assert(actor.position == mid_leg, "Failed acknowledgement cannot teleport")
	assert(session.request_hotspot("RM-HS-001").status == "queued")
	assert(not actor.start_segment(authorized), "Replacement cannot interrupt or snap to fromAnchorId")
	assert(session.next_segment().is_empty(), "Only one segment can be in flight")
	var rounds := 0
	while actor.has_active_segment() and rounds < 200:
		actor.advance(0.05)
		rounds += 1
	assert(not actor.has_active_segment())
	assert(actor.position == authorized.toPosition)
	assert(_completed.size() == 1 and _completed[0].id == authorized.toAnchorId)
	_completed.clear()
	var confirmed: Dictionary = session.finish_segment(authorized.toAnchorId)
	assert(confirmed.ok and confirmed.status == "continue")
	assert(session.current_anchor() == authorized.toAnchorId)
	var replacement: Dictionary = session.next_segment()
	assert(replacement.fromAnchorId == authorized.toAnchorId)
	assert(actor.start_segment(replacement), "New leg begins at exact physical arrival only")
	assert(actor.position == authorized.toPosition)
	assert(session.cancel().finishCurrentSegment)
	assert(session.checkpoint_event("onoe-queued-cancel").is_empty())
	rounds = 0
	while actor.has_active_segment() and rounds < 200:
		actor.advance(0.05)
		rounds += 1
	assert(not actor.has_active_segment() and actor.position == replacement.toPosition)
	assert(session.finish_segment(replacement.toAnchorId).status == "cancelled")
	assert(not session.cancel().finishCurrentSegment)
	# Bad origin after a paused/interrupted leg must be rejected, no actor snap.
	var broken := replacement.duplicate(true)
	broken.fromPosition = Vector2(0, 0)
	broken.toPosition = Vector2(800, 800)
	var stable: Vector2 = actor.position
	assert(not actor.start_segment(broken))
	assert(actor.position == stable)
	
	actor.queue_free()
	print("Raven MAP-QA-02 Onoe animated segment movement smoke passed")
	quit()


func _on_completed(anchor_id: String, actual_pos: Vector2) -> void:
	_completed.append({"id": anchor_id, "point": actual_pos})
