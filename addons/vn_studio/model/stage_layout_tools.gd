@tool
extends RefCounted
## VNS5-04A: editor-only, pure orientation math and reversible arrangement presets.
## Nothing here changes runtime portrait composition or the Raven save schema.
const PORTRAIT := "portrait"
const LANDSCAPE := "landscape"
const PORTRAIT_SIZE := Vector2(390, 844)
const LANDSCAPE_SIZE := Vector2(844, 390)


static func reference_size(orientation: String) -> Vector2:
	return LANDSCAPE_SIZE if orientation == LANDSCAPE else PORTRAIT_SIZE


static func actor_size(view: Vector2, count: int) -> Vector2:
	# A separate editor layout for horizontal VN shots. Portrait delegates to
	# Raven's exact shared gameplay layout in the stage designer.
	return view * Vector2(0.29 if count >= 3 else 0.36, 0.92)


static func landscape_position(view: Vector2, count: int, coords: Vector2) -> Vector2:
	var remaining: Vector2 = (view - actor_size(view, count)).max(Vector2.ZERO)
	return Vector2(clampf(coords.x, 0.0, 1.0), clampf(coords.y, 0.0, 1.0)) * remaining


static func landscape_normalized(view: Vector2, count: int, position: Vector2) -> Vector2:
	var remaining: Vector2 = (view - actor_size(view, count)).max(Vector2.ONE)
	return Vector2(clampf(position.x / remaining.x, 0.0, 1.0), clampf(position.y / remaining.y, 0.0, 1.0))


static func template_points(count: int, orientation: String) -> Array:
	# Values are normalized into the actor's allowed motion range, not pixels.
	# A preset is applied only after the user clicks the explicit action.
	if count < 1 or count > 3:
		return []
	if orientation == LANDSCAPE:
		match count:
			1: return [Vector2(0.5, 0.7)]
			2: return [Vector2(0.17, 0.6), Vector2(0.83, 0.6)]
			3: return [Vector2(0.03, 0.72), Vector2(0.5, 0.45), Vector2(0.97, 0.72)]
	match count:
		1: return [Vector2(0.5, 0.55)]
		2: return [Vector2(0.12, 0.58), Vector2(0.88, 0.58)]
		3: return [Vector2(0.03, 0.63), Vector2(0.5, 0.43), Vector2(0.97, 0.63)]
	return []


static func apply_template(original: Dictionary, orientation: String) -> Dictionary:
	var result: Dictionary = original.duplicate(true)
	var cast: Array = result.get("cast", [])
	var points: Array = template_points(cast.size(), orientation)
	if points.is_empty():
		return result
	for i in range(cast.size()):
		# Stage v1 explicitly permits these three fields; keep IDs, images,
		# emotions, costumes, source shots and all other keys untouched.
		cast[i]["slot"] = "center" if cast.size() == 1 or (cast.size() == 3 and i == 1) else "left" if i == 0 else "right"
		cast[i]["x"] = points[i].x
		cast[i]["y"] = points[i].y
	return result
