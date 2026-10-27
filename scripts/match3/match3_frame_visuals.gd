extends RefCounted
## View-only interpretation of the original UPDS Match3Game frame contract.
## No match, combo, blocker or campaign rules are reproduced here.

static func clip_for_motion(motion: Dictionary, columns: int, rows: int, cell_size: Vector2, gap: float) -> Rect2:
	if columns < 1 or rows < 1 or cell_size.x <= 0.0 or cell_size.y <= 0.0:
		return Rect2()
	var index := int(motion.get("index", -1))
	if index < 0 or index >= columns * rows:
		return Rect2()
	var column := index % columns
	var row := int(index / columns)
	var first_row := clampi(int(motion.get("segmentTop", row)), 0, rows - 1)
	var last_row := clampi(int(motion.get("segmentBottom", row)), first_row, rows - 1)
	if row < first_row or row > last_row:
		return Rect2()
	var stride := cell_size.y + gap
	return Rect2(
		Vector2(float(column) * (cell_size.x + gap), float(first_row) * stride),
		Vector2(cell_size.x, float(last_row - first_row) * stride + cell_size.y)
	)


static func cleared_indices(frame: Dictionary, maximum: int) -> Array[int]:
	var seen := {}
	var result: Array[int] = []
	for value in frame.get("cleared", []):
		var index := int(value)
		if index >= 0 and index < maximum and not seen.has(index):
			result.append(index)
			seen[index] = true
	return result


static func special_at(frame: Dictionary, index: int) -> String:
	var specials: Array = frame.get("specials", [])
	if index >= 0 and index < specials.size():
		return str(specials[index])
	return ""


static func impact_color(special: String, feedback_kind: String) -> Color:
	match special:
		"flash-row", "flash-column":
			return Color("8cd6f3")
		"evidence":
			return Color("f7be83")
		"lead":
			return Color("bfe19b")
		"insight":
			return Color("d7a8fb")
	return Color("f5d49a") if feedback_kind == "special" else Color("fff2cc")


static func phase_feedback(frame: Dictionary, copy: Dictionary) -> String:
	var phase := str(frame.get("phase", ""))
	var cascade := int(frame.get("cascade", 0))
	if phase == "reshuffle":
		return str(copy.get("reshuffle", "Поле перемешано"))
	if phase == "clear" and cascade >= 2:
		return "%s ×%d" % [str(copy.get("chain", "Цепочка")), cascade]
	if phase == "clear" and str(frame.get("feedback", "")) == "special":
		return str(copy.get("special_impact", "Особая комбинация!"))
	return ""
