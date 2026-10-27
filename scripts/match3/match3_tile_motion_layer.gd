extends Control

## Screen-space owner for one-shot tile fall and spawn animations.
## The grid owns state; this layer owns only temporary visual copies.

const CssMotion = preload("res://scripts/ui/css_motion.gd")

var automatic_motion_enabled := true
var _motions: Array[Dictionary] = []


func animate_tile(tile_stack: Control, motion: Dictionary, duration: float) -> void:
	if not is_instance_valid(tile_stack) or duration <= 0.0:
		return
	var index := int(motion.get("index", 0))
	var spawned := bool(motion.get("spawn", false))
	var stack_height := maxf(1.0, tile_stack.size.y)
	# The source stack sits roughly 2 px inside its rounded grid cell. Match its
	# percent-based fall distance instead of using the Godot cell's outer height.
	var distance := float(maxi(1, int(motion.get("rows", 1)))) * maxf(1.0, stack_height - 2.0)
	var layer_transform := get_global_transform_with_canvas()
	var source_transform := tile_stack.get_global_transform_with_canvas()
	var target := layer_transform.affine_inverse() * source_transform.origin
	var source_basis := layer_transform.basis_xform_inv(source_transform.x)
	var source_basis_y := layer_transform.basis_xform_inv(source_transform.y)
	var source_scale := Vector2(source_basis.length(), source_basis_y.length())
	var clip_rect: Rect2 = motion.get("clipRect", Rect2(Vector2.ZERO, size))
	if clip_rect.size.x <= 0.0 or clip_rect.size.y <= 0.0:
		clip_rect = Rect2(Vector2.ZERO, size)
	var clip := Control.new()
	clip.name = "SettleMotionClip_%d" % index
	clip.position = clip_rect.position
	clip.size = clip_rect.size
	clip.clip_contents = true
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(clip)
	var moving_stack := tile_stack.duplicate() as Control
	moving_stack.name = "SettleMotion_%d" % index
	moving_stack.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	moving_stack.size = tile_stack.size
	# The moving copy is a child of the segment clip, so coordinates must be
	# local to that clip, including for columns split by blockers or holes.
	var target_rendered_origin := target - clip_rect.position
	var scaled_pivot := Vector2(tile_stack.size.x, tile_stack.size.y) * 0.5 * source_scale
	var target_position := target_rendered_origin - Vector2(tile_stack.size.x, tile_stack.size.y) * 0.5 + scaled_pivot
	var target_center_in_clip := target_rendered_origin + Vector2(tile_stack.size.x, tile_stack.size.y) * source_scale * 0.5
	var start_center_y := target_center_in_clip.y - distance
	var overshoot_center_y := target_center_in_clip.y + stack_height * source_scale.y * 0.03
	var start_rendered_y := start_center_y - tile_stack.size.y * source_scale.y * 0.5
	var overshoot_rendered_y := overshoot_center_y - tile_stack.size.y * source_scale.y * 0.5
	var start_y := start_rendered_y - tile_stack.size.y * 0.5 + scaled_pivot.y
	var overshoot_y := overshoot_rendered_y - tile_stack.size.y * 0.5 + scaled_pivot.y
	var settle_mark := 0.78 if spawned else 0.72
	moving_stack.position = Vector2(target_position.x, start_y)
	moving_stack.set_meta("settle_target_position", Vector2(target_position.x, target_position.y))
	moving_stack.set_meta("settle_start_distance", distance)
	# Duplicate the complete authored transform. Several blockers intentionally
	# scale their tile stack; resetting this to ONE made the copy grow from its
	# upper-left corner as it fell. Preserve scale and keep the pivot centered.
	moving_stack.pivot_offset = tile_stack.size * 0.5
	moving_stack.scale = tile_stack.scale
	moving_stack.modulate = Color(1, 1, 1, 0.05 if spawned else 1.0)
	clip.add_child(moving_stack)
	tile_stack.hide()
	_motions.append({
		"source_id": tile_stack.get_instance_id(),
		"clip_id": clip.get_instance_id(),
		"moving_stack": moving_stack,
		"elapsed": 0.0,
		"duration": duration,
		"spawned": spawned,
		"start_y": start_y,
		"overshoot_y": overshoot_y,
		"target_y": target_position.y,
		"settle_mark": settle_mark,
	})


func _process(delta: float) -> void:
	if automatic_motion_enabled:
		advance_motions(delta)


func advance_motions(delta: float) -> void:
	for index in range(_motions.size() - 1, -1, -1):
		var motion: Dictionary = _motions[index]
		motion.elapsed = minf(float(motion.duration), float(motion.elapsed) + maxf(0.0, delta))
		var progress := clampf(float(motion.elapsed) / float(motion.duration), 0.0, 1.0)
		var stack := motion.moving_stack as Control
		if not is_instance_valid(stack):
			_motions.remove_at(index)
			continue
		var first_mark := float(motion.settle_mark)
		var ease := Callable(self, "_css_cubic_bezier")
		if progress <= first_mark:
			var phase := float(ease.call(progress / first_mark, 0.18, 0.82, 0.28, 1.0))
			stack.position.y = lerpf(float(motion.start_y), float(motion.overshoot_y), phase)
		else:
			var phase := float(ease.call((progress - first_mark) / (1.0 - first_mark), 0.18, 0.82, 0.28, 1.0))
			stack.position.y = lerpf(float(motion.overshoot_y), float(motion.target_y), phase)
		if bool(motion.spawned):
			var opacity_progress := clampf(progress / 0.68, 0.0, 1.0)
			var opacity_ease := float(ease.call(opacity_progress, 0.18, 0.82, 0.28, 1.0))
			stack.modulate.a = lerpf(0.05, 1.0, opacity_ease)
		if progress >= 1.0:
			_finish(int(motion.source_id), int(motion.clip_id))
			_motions.remove_at(index)


func cancel_motions() -> void:
	for motion in _motions:
		_finish(int(motion.source_id), int(motion.clip_id))
	_motions.clear()


func _finish(tile_instance_id: int, clip_instance_id: int) -> void:
	var tile_stack := instance_from_id(tile_instance_id) as Control
	if is_instance_valid(tile_stack):
		tile_stack.show()
	var clip := instance_from_id(clip_instance_id) as Control
	if is_instance_valid(clip):
		clip.queue_free()


func _css_cubic_bezier(progress: float, x1: float, y1: float, x2: float, y2: float) -> float:
	return CssMotion.cubic_bezier(progress, x1, y1, x2, y2)
