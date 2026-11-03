@tool
extends ItemList
## Raven-only explicit DnD. Author validates source/target and blocks canonical
## IDs. No gameplay, preview runtime or global drag state is mutated.
signal reorder_requested(from_index: int, to_index: int)


func _get_drag_data(at_position: Vector2) -> Variant:
	var index: int = get_item_at_position(at_position, true)
	if index < 0:
		return null
	var label := Label.new()
	label.text = get_item_text(index)
	set_drag_preview(label)
	return {"ravenLineDrag": true, "owner": get_instance_id(), "sourceIndex": index}


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.get("ravenLineDrag", false) and\
		int(data.get("owner", -1)) == get_instance_id() and\
		int(data.get("sourceIndex", -1)) >= 0 and\
		get_item_at_position(at_position, true) >= 0


func _drop_data(at_position: Vector2, data: Variant) -> void:
	if not _can_drop_data(at_position, data):
		return
	var from_index: int = int(data["sourceIndex"])
	var to_index: int = get_item_at_position(at_position, true)
	if from_index != to_index:
		reorder_requested.emit(from_index, to_index)
