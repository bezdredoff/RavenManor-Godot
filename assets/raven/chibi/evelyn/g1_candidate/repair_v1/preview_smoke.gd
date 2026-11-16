extends SceneTree

const Actor = preload("res://assets/raven/chibi/evelyn/g1_candidate/repair_v1/evelyn_actor.gd")
const MAP = preload("res://scenes/raven/tests/evelyn_chibi_map_preview.tscn")
const CLOSEUP = preload("res://scenes/raven/tests/evelyn_chibi_preview.tscn")
var arrivals := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	assert(CLOSEUP != null)
	var actor = Actor.new()
	root.add_child(actor)
	actor.set_process(false)
	actor.set_sprite_height(62)
	await process_frame
	var sprite: AnimatedSprite2D = actor.get_sprite()
	var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(actor.visual().META_PATH))
	actor.segment_completed.connect(func(_id: String, _point: Vector2): arrivals += 1)
	var steps := [Vector2(100, 0), Vector2(0, -100), Vector2(-100, 0), Vector2(0, 100)]
	for direction in steps:
		var start: Vector2 = actor.position
		assert(actor.start_segment({"fromAnchorId": "A", "toAnchorId": "B", "fromPosition": start, "toPosition": start+direction}))
		var clip := "side" if direction.x != 0 else ("up" if direction.y < 0 else "down")
		assert(sprite.animation == clip and sprite.flip_h == (direction.x < 0))
		assert(sprite.is_playing())
		for frame in range(4):
			sprite.frame = frame
			actor.visual()._align()
			var data: Dictionary = meta.frames[clip][frame]
			var point := Vector2(data.pivot[0], data.pivot[1]) - Vector2(data.region[2], data.region[3])*0.5
			if sprite.flip_h:
				point.x = -point.x
			assert((sprite.position + point*sprite.scale).length() < 0.001, "Registered sole must map to physical root")
			assert(absf(float(data.visibleHeight)*sprite.scale.y-62.0) < 0.001)
		actor.advance(0.1)
		var held: Vector2 = actor.position
		assert(actor.pause_segment())
		actor.advance(1)
		assert(actor.position == held and not sprite.is_playing())
		assert(actor.resume_segment())
		actor.visual().set_reduced_motion(true)
		actor.advance(0.1)
		assert(actor.position != held and sprite.frame == 0 and not sprite.is_playing())
		actor.visual().set_reduced_motion(false)
		assert(sprite.is_playing())
		actor.advance(2)
		assert(actor.position == start+direction and not actor.has_active_segment())
		assert(sprite.frame == 0 and not sprite.is_playing())
	assert(arrivals == 4)
	assert(actor.position == Vector2.ZERO, "Four route turns must return to initial root")
	actor.queue_free()
	await process_frame
	var host = MAP.instantiate()
	root.add_child(host)
	await process_frame
	await process_frame
	assert(host.ready_for_qa, "Inherited Hall route harness must initialize")
	host.actor.set_process(false)
	var accepted := false
	for point in host.qa.waypoint_ids():
		if point != host.session.current_anchor() and host.request_waypoint(point) and host.actor.has_active_segment():
			accepted = true
			break
	assert(accepted, "Must walk a real existing Hall route")
	host.actor.advance(0.01)
	var mid: Vector2 = host.actor.position
	var destination: String = host.actor.segment_destination()
	assert(host.pause_movement())
	host.actor.advance(2)
	assert(host.actor.position == mid)
	assert(host.resume_movement())
	assert(host.stop_movement())
	assert(host.actor.position == mid, "Cancellation cannot teleport")
	for i in range(1000):
		if not host.actor.has_active_segment():
			break
		host.actor.advance(0.05)
	assert(not host.actor.has_active_segment())
	assert(host.session.current_anchor() == destination, "Cancel must finish exactly its authorized leg")
	assert(host.session.next_segment().is_empty())
	host.queue_free()
	await process_frame
	print("GFX-07-01 Evelyn preview PASS: 12 frames, both flips, registered feet/height, four turns, idle, pause/resume, reduced motion, real Hall route cancellation")
	quit()
