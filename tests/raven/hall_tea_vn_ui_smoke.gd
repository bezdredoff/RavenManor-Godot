extends SceneTree

const HallTea = preload("res://scenes/raven/hall_tea_vn.tscn")
const Map = preload("res://scenes/raven/manor_greybox.tscn")

func _initialize() -> void:
	call_deferred("_test_ui")


func _test_ui() -> void:
	var screen := HallTea.instantiate()
	root.add_child(screen)
	await process_frame
	var dialogue := screen.get("dialogue") as Label
	var nameplate := screen.get("nameplate") as Label
	var selector := screen.get("locale_selector") as OptionButton
	var left := screen.get("actor_left") as TextureRect
	var right := screen.get("actor_right") as TextureRect
	assert(dialogue != null and left != null and right != null)
	assert(selector != null and nameplate != null)
	assert(left.texture != null and right.texture != null)
	assert((screen.get("lines") as Array).size() == 12)
	screen.call("_switch_locale", 0)
	assert(dialogue.text.begins_with("Вчера"))
	assert(nameplate.text == "ЭВЕЛИН")
	screen.call("_switch_locale", 2)
	assert(dialogue.text.begins_with("Yesterday"))
	assert(nameplate.text == "EVELYN")
	screen.call("_next")
	assert(int(screen.get("line_index")) == 1)
	assert(dialogue.text == "And did you?")
	screen.call("_switch_locale", 1)
	assert(dialogue.text == "І як?")
	assert(int(screen.get("line_index")) == 1, "Locale change must not replay/skip lines")
	screen.call("_switch_locale", 0)
	screen.queue_free()
	await process_frame

	var map_scene := Map.instantiate()
	root.add_child(map_scene)
	await process_frame
	map_scene.call("_show_tea_popup")
	await process_frame
	var dialogs := map_scene.get_children().filter(func(child): return child is ConfirmationDialog)
	assert(dialogs.size() == 1)
	assert((dialogs[0] as ConfirmationDialog).get_ok_button().disabled, "Locked chapter must not be enterable from the map")
	map_scene.queue_free()
	await process_frame
	print("Raven Manor Hall VN UI runtime smoke passed (rendered controls, three language swaps, mapped gated popup).")
	quit()
