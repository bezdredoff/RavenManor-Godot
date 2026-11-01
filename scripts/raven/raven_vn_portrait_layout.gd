@tool
extends RefCounted
## Same portrait bounds and normalized placement in gameplay and Studio.

static func actor_size(canvas: Vector2, count: int) -> Vector2:
	return canvas * Vector2(0.60 if count > 2 else 0.77, 0.73)


static func slot_x(slot: String) -> float:
	return 0.0 if slot == "left" else 1.0 if slot == "right" else 0.5


static func _horizontal(count: int) -> Vector3:
	return Vector3(-0.10, 0.20, 0.52) if count > 2 else Vector3(-0.20, 0.115, 0.41)


static func position_for(canvas: Vector2, count: int, normalized: Vector2) -> Vector2:
	var anchors: Vector3 = _horizontal(count)
	var x: float = lerpf(anchors.x, anchors.y, normalized.x * 2.0) if normalized.x <= 0.5 else lerpf(anchors.y, anchors.z, (normalized.x - 0.5) * 2.0)
	var y: float = lerpf(0.0, 0.14, normalized.y * 2.0) if normalized.y <= 0.5 else lerpf(0.14, 0.27, (normalized.y - 0.5) * 2.0)
	return canvas * Vector2(x, y)


static func normalize_position(canvas: Vector2, count: int, position: Vector2) -> Vector2:
	var anchors: Vector3 = _horizontal(count)
	var x: float = position.x / maxf(1.0, canvas.x)
	var y: float = position.y / maxf(1.0, canvas.y)
	var nx: float = inverse_lerp(anchors.x, anchors.y, x) * 0.5 if x <= anchors.y else 0.5 + inverse_lerp(anchors.y, anchors.z, x) * 0.5
	var ny: float = inverse_lerp(0.0, 0.14, y) * 0.5 if y <= 0.14 else 0.5 + inverse_lerp(0.14, 0.27, y) * 0.5
	return Vector2(clampf(nx, 0.0, 1.0), clampf(ny, 0.0, 1.0))
