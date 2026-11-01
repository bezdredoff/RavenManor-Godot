extends SceneTree
## Shared gameplay VN backgrounds render imported scene art, including Entry.
const Preview = preload("res://scripts/raven/content_preview.gd")
const Slice = preload("res://scripts/raven/vertical_slice.gd")
const GameView = preload("res://scripts/raven/raven_vn_game_view.gd")
const Resolver = preload("res://scripts/raven/raven_vn_backgrounds.gd")
const Content = preload("res://data/raven/rm_vs_01_content.json")
const HallTea = preload("res://scenes/raven/hall_tea_vn.tscn")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	assert(Resolver.entry_for_scene("RM-BEAT-00-02").get("id") == "BG-ROAD:dusk:mist")
	var preview := Preview.new()
	preview.size = Vector2(390, 844)
	root.add_child(preview)
	await process_frame
	preview._open_vn("road")
	await process_frame
	assert(preview.vn_view is GameView, "QA road must render an actual in-game VN image")
	var road: Control = preview.vn_view
	assert(road.scene_id == "RM-BEAT-00-02")
	assert(road.background.texture == Resolver.texture_for_scene(road.scene_id))
	assert(road.background.visible and not road.missing_background.visible)
	assert(road.background.texture.get_width() == 1080)
	assert(road.background.texture.get_height() == 1920)
	assert(road.dialogue.text == str(Content.data.prologueScenes.road.lines[0].text))
	assert(road.nameplate.text == "ЭВЕЛИН")
	assert(road.actors.size() == 1)
	assert((road.actors[0]["node"] as TextureRect).texture != null)
	road._next()
	await process_frame
	assert(preview.vn_player.line_index == 1)
	assert(preview.vn_view.dialogue.text == str(Content.data.prologueScenes.road.lines[1].text))
	assert(preview.vn_view.background.texture == Resolver.texture_for_scene("RM-BEAT-00-02"))
	preview._open_vn("gates")
	await process_frame
	assert(preview.vn_view.scene_id == "RM-BEAT-00-03")
	assert(preview.vn_view.background.texture == Resolver.texture_for_scene("RM-BEAT-00-03"), "Entry must render in gameplay once imported")
	assert(not preview.vn_view.missing_background.visible)
	assert(preview.vn_view.dialogue.text == str(Content.data.prologueScenes.gates.lines[0].text))
	assert(preview.vn_view.actors.size() == 2)
	preview._open_vn("bedroom")
	await process_frame
	assert(preview.vn_view.scene_id == "RM-BEAT-01-02")
	assert(preview.vn_view.background.texture == Resolver.texture_for_scene("RM-BEAT-01-02"), "Bedroom daytime art must render behind the actual story dialogue")
	assert(preview.vn_view.background.visible and not preview.vn_view.missing_background.visible)
	assert(preview.vn_view.actors.size() == 2, "Bedroom must compose Evelyn and Ada")
	assert(preview.vn_view.dialogue.text == str(Content.data.vnScenes.bedroom.lines[0].text))
	preview._open_vn("letter")
	await process_frame
	assert(preview.vn_view.background.texture == Resolver.texture_for_scene("RM-BEAT-00-01"))
	preview.queue_free()
	await process_frame

	var slice := Slice.new()
	slice.size = Vector2(390, 844)
	root.add_child(slice)
	await process_frame
	slice.step = {"id":"road", "scene":"road", "kind":"vn"}
	slice.vn_player = null
	slice._render_vn()
	await process_frame
	assert(slice.vn_view is GameView)
	assert(slice.vn_view.scene_id == "RM-BEAT-00-02")
	assert(slice.vn_view.background.texture == Resolver.texture_for_scene("RM-BEAT-00-02"))
	assert(slice.vn_view.dialogue.text == str(Content.data.prologueScenes.road.lines[0].text))
	slice.queue_free()
	await process_frame

	var late_bedroom := GameView.new()
	late_bedroom.size = Vector2(390, 844)
	root.add_child(late_bedroom)
	await process_frame
	late_bedroom.show_beat("RM-BEAT-06-03", "Эвелин", "Решение принято.", "1/1", Callable())
	assert(late_bedroom.background.texture == Resolver.texture_for_scene("RM-BEAT-06-03"))
	assert(late_bedroom.background.texture != null and not late_bedroom.missing_background.visible)
	assert(late_bedroom.actors.size() == 1, "Late-night scene stages only Evelyn")
	late_bedroom.queue_free()
	await process_frame

	var tea := HallTea.instantiate()
	root.add_child(tea)
	await process_frame
	assert(tea.background.texture == Resolver.texture_for_scene("RM-BEAT-02-01"))
	tea.queue_free()
	print("Raven live VN background compositor passed (Road, Apartment, Entry, Slice, Hall Tea).")
	quit()
