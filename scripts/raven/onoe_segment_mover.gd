extends Node2D

## One real-position, one-segment-at-a-time visual executor.
## A RouteSession-approved next_segment() is the ONLY authorized gameplay input.
## Neither this script nor Onoe knows map coordinates, routes, doors or saving.
const OnoeVisual = preload("res://scripts/raven/onoe_visual.gd")

signal segment_completed(to_anchor_id: String, actual_position: Vector2)
signal segment_started(from_anchor_id: String, to_anchor_id: String)

@export_range(1.0, 1200.0, 1.0) var move_speed: float = 230.0
@export_range(0.0, 10.0, 0.1) var start_tolerance: float = 0.75
@export_range(24.0, 300.0, 1.0) var sprite_height: float = 104.0

var _visual
var _active := false
var _paused := false
var _to_point := Vector2.ZERO
var _from_id := ""
var _to_id := ""


func _ready() -> void:
	_visual = OnoeVisual.new()
	_visual.name = "OnoeVisual"
	add_child(_visual)
	_visual.set_display_height(sprite_height)


func get_sprite() -> AnimatedSprite2D:
	return _visual.get_sprite()


func visual() -> Node2D:
	return _visual


func set_sprite_height(pixels: float) -> void:
	if is_finite(pixels) and pixels > 0.0:
		sprite_height = pixels
		if is_instance_valid(_visual):
			_visual.set_display_height(sprite_height)


func has_active_segment() -> bool:
	return _active


func is_paused() -> bool:
	return _paused


func segment_destination() -> String:
	return _to_id if _active else ""


func start_segment(segment: Dictionary) -> bool:
	# A replacement command is queued in RouteSession, never interrupts a leg.
	if _active or not is_finite(move_speed) or move_speed <= 0.0:
		return false
	var from_id := str(segment.get("fromAnchorId", ""))
	var to_id := str(segment.get("toAnchorId", ""))
	var from_value: Variant = segment.get("fromPosition", null)
	var to_value: Variant = segment.get("toPosition", null)
	if from_id.is_empty() or to_id.is_empty() or from_id == to_id:
		return false
	if not from_value is Vector2 or not to_value is Vector2:
		return false
	var from_point: Vector2 = from_value
	var to_point: Vector2 = to_value
	if not from_point.is_finite() or not to_point.is_finite():
		return false
	if from_point.distance_to(to_point) <= 0.00001:
		return false
	# Prevent Hall's old mid-Tween "restart from last confirmed anchor" bug.
	if position.distance_to(from_point) > start_tolerance:
		return false
	_from_id = from_id
	_to_id = to_id
	_to_point = to_point
	_active = true
	_paused = false
	_visual.face(_to_point - position)
	segment_started.emit(_from_id, _to_id)
	return true


func _process(delta: float) -> void:
	advance(delta)


func advance(delta: float) -> void:
	# Also used by headless deterministic tests; only one movement implementation.
	if not _active or _paused or not is_finite(delta) or delta <= 0.0:
		return
	if not is_finite(move_speed) or move_speed <= 0.0:
		pause_segment()
		return
	var remaining := _to_point - position
	if remaining.length_squared() > 0.00000001:
		_visual.face(remaining)
	position = position.move_toward(_to_point, move_speed * delta)
	if position.distance_to(_to_point) > 0.00001:
		return
	# Emit only AFTER feet physically reached the authorized target.
	position = _to_point
	_active = false
	_paused = false
	_visual.set_idle()
	var destination := _to_id
	_from_id = ""
	_to_id = ""
	segment_completed.emit(destination, position)


func pause_segment() -> bool:
	# Emergency hold retains exact physical XY and in-flight destination.
	# Caller MUST NOT acknowledge RouteSession.finish_segment() while paused.
	if not _active or _paused:
		return false
	_paused = true
	_visual.set_idle()
	return true


func resume_segment() -> bool:
	if not _active or not _paused:
		return false
	_paused = false
	_visual.face(_to_point - position)
	return true


func show_idle() -> void:
	if not _active and is_instance_valid(_visual):
		_visual.set_idle()
