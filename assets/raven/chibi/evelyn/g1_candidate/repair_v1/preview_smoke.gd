extends SceneTree

const Actor = preload("res://assets/raven/chibi/evelyn/g1_candidate/repair_v1/evelyn_actor.gd")
const MAP = preload("res://scenes/raven/tests/evelyn_chibi_map_preview.tscn")
const CLOSEUP = preload("res://scenes/raven/tests/evelyn_chibi_preview.tscn")
var arrivals := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var actor = Actor.new()
	root.add_child(actor)
	actor.set_process(false)
	actor.set_sprite_height(62)
	await process_frame
	var visual = actor.visual()
	var sprite: AnimatedSprite2D = actor.get_sprite()
	assert(sprite.material == null, "Clean raw atlas must work without an alpha material")
	assert(not visual._meta.ownerApproved and not visual._meta.productionReplacementAllowed)
	actor.segment_completed.connect(func(_id: String, _point: Vector2): arrivals += 1)
	var steps := [Vector2(100, 0), Vector2(0, -100), Vector2(-100, 0), Vector2(0, 100)]
	for direction in steps:
		var start: Vector2 = actor.position
		actor.move_speed = 55
		assert(actor.start_segment({"fromAnchorId": "A", "toAnchorId": "B", "fromPosition": start, "toPosition": start+direction}))
		var clip := "side" if direction.x != 0 else ("up" if direction.y < 0 else "down")
		assert(sprite.animation == clip and sprite.flip_h == (direction.x < 0))
		var scale_before := sprite.scale
		var offset_before := sprite.position
		for frame in range(4):
			sprite.frame = frame
			var texture: AtlasTexture = sprite.sprite_frames.get_frame_texture(clip, frame)
			assert(texture.region.size == Vector2(256, 512) and texture.filter_clip)
			assert(sprite.scale == scale_before and sprite.position == offset_before, "Frame changes must not resize/recenter the body")
			assert((sprite.position + Vector2(0, 224)*sprite.scale).length() < 0.001)
		# Half a body-relative cycle at different speeds covers exactly the
		# same physical distance and phase. This fails timer/clamped-FPS code.
		var initial_phase: float = visual.phase()
		for invalid_delta in [-1.0, 0.0, INF, NAN]:
			actor.advance(invalid_delta)
		assert(actor.position == start and visual.phase() == initial_phase)
		actor.advance(7.75 / 55.0)
		actor.move_speed = 0.5
		actor.advance(7.75 / 0.5)
		assert(absf(fposmod(visual.phase()-initial_phase, 1.0)-0.5) < 0.0001)
		var held: Vector2 = actor.position
		assert(actor.pause_segment())
		var held_phase: float = visual.phase()
		var held_frame := sprite.frame
		actor.advance(100)
		await create_timer(0.08).timeout
		assert(actor.position == held and visual.phase() == held_phase and sprite.frame == held_frame)
		assert(actor.resume_segment())
		visual.set_reduced_motion(true)
		actor.move_speed = 130
		actor.advance(0.1)
		assert(actor.position != held and sprite.frame == visual.IDLE_FRAME)
		visual.set_reduced_motion(false)
		actor.advance(100)
		assert(actor.position == start+direction and not actor.has_active_segment())
		assert(sprite.frame == visual.IDLE_FRAME and not sprite.is_playing())
		var idle_phase: float = visual.phase()
		actor.advance(100)
		assert(visual.phase() == idle_phase)
	assert(arrivals == 4 and actor.position == Vector2.ZERO)
	assert(not actor.start_segment({"fromAnchorId": "A", "toAnchorId": "B", "fromPosition": Vector2(500, 0), "toPosition": Vector2(600, 0)}))
	actor.queue_free()
	await process_frame
	var closeup = CLOSEUP.instantiate()
	root.add_child(closeup)
	await process_frame
	assert(closeup.actors.size() == 8)
	closeup._step()
	closeup._background()
	closeup.queue_free()
	await process_frame
	var host = MAP.instantiate()
	root.add_child(host)
	await process_frame
	await process_frame
	assert(host.ready_for_qa)
	assert(host.actor.move_speed == 55.0, "Candidate review speed must be explicit")
	host.actor.set_process(false)
	var accepted := false
	for point in host.qa.waypoint_ids():
		if point != host.session.current_anchor() and host.request_waypoint(point) and host.actor.has_active_segment():
			accepted = true
			break
	assert(accepted)
	host.actor.advance(0.01)
	var mid: Vector2 = host.actor.position
	var destination: String = host.actor.segment_destination()
	assert(host.pause_movement())
	host.actor.advance(2)
	assert(host.actor.position == mid)
	assert(host.resume_movement() and host.stop_movement())
	assert(host.actor.position == mid, "Cancel cannot teleport")
	for i in range(1000):
		if not host.actor.has_active_segment():
			break
		host.actor.advance(0.05)
	assert(not host.actor.has_active_segment())
	assert(host.session.current_anchor() == destination and host.session.next_segment().is_empty())
	host.queue_free()
	await process_frame
	print("GFX-07-01 Evelyn preview PASS: uniform atlas, fixed grounding, real-distance cadence at 0.5/55/130 px/s, four turns, pause, reduced motion, real Hall cancellation; art approval pending")
	quit()
