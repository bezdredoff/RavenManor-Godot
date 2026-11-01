extends SceneTree
## Editor-only preview routing, future-state ART PENDING and safe exact selection.
const Store = preload("res://addons/vn_studio/editor/raven_story_store.gd")
const Designer = preload("res://addons/vn_studio/editor/raven_stage_designer.gd")
const Resolver = preload("res://scripts/raven/raven_vn_backgrounds.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var project: Dictionary = Store.open_project(ProjectSettings.globalize_path("res://"))
	assert(project.get("ok", false))
	var draft: Dictionary = Store.fresh(project)
	var designer := Designer.new()
	root.add_child(designer)
	# Toolbars wrap on smaller embedded stage widths, not fixed HBoxes.
	assert(designer.get_child(0) is HFlowContainer)
	assert(designer.get_child(1) is HFlowContainer)
	assert(designer.get_child(2) is HFlowContainer)
	assert(designer.get_child(3) is HFlowContainer)

	designer.set_scene(project, draft, "RM-BEAT-03-01")
	assert(Resolver.all_entries().size() >= 13)
	designer.set_scene(project, draft, "RM-BEAT-00-01")
	assert(designer._stage_data["backgroundId"] == "BG-APARTMENT")
	assert(designer._stage_data["lighting"] == "day")
	assert(designer._stage_data["roomState"] == "packed_boxes")
	assert(designer._bg_image.texture != null, "Prologue apartment texture missing in VN Studio")
	assert(designer._bg_image.texture.get_width() == 1080 and designer._bg_image.texture.get_height() == 1920)
	designer._on_browse_imported()
	assert(designer._browser_list.item_count == Resolver.all_entries().size(), "Imported-only browser must show all apartment plates")
	designer._browser.hide()
	designer.set_scene(project, draft, "RM-BEAT-03-01")
	assert(designer._stage_data["backgroundId"] == "BG-LIBRARY")
	assert(designer._stage_data["lighting"] == "evening")
	assert(designer._stage_data["roomState"] == "shut_dusty")
	assert(designer._bg_image.texture != null)
	assert(designer._bg_image.texture.get_width() == 1080)
	assert(designer._bg_image.texture.get_height() == 1920)
	assert(designer._canvas.custom_minimum_size == designer.REFERENCE_SIZE)
	assert(is_equal_approx(designer._card_size.x, designer.REFERENCE_SIZE.x * 0.77))
	assert(is_equal_approx(designer._card_size.y, designer.REFERENCE_SIZE.y * 0.73))
	var full_actor_dimensions: Vector2 = designer._card_size
	designer._on_portrait_scale(0.35)
	assert(designer._card_size == full_actor_dimensions, "Tool thumbnails must not alter stage portraits")
	assert(designer._thumbnail_size.x < 60)
	assert(designer._thumbnail_strip.get_child_count() == designer._cards.size())
	assert(designer._placeholders.text.contains("ART CANDIDATE"))

	# An allowed master lighting/state product without a published image must
	# show an explicit pending state, not the old Hall master or another plate.
	designer._stage_data["lighting"] = "day"
	designer._stage_data["roomState"] = "shut_dusty"
	designer._draw_stage()
	assert(designer._bg_image.texture == null)
	assert(designer._placeholders.text.contains("ART PENDING"))

	designer.set_scene(project, draft, "RM-BEAT-05-02")
	assert(designer._bg_image.texture != null)
	assert(designer._stage_data["lighting"] == "night")
	assert(designer._stage_data["roomState"] == "storm_leak")
	assert(designer._cards.size() == designer._stage_data["cast"].size())

	var options: Array[Dictionary] = designer._catalog_browser_options()
	assert(options.size() > Resolver.all_entries().size())
	var available: Array[Dictionary] = designer._available_browser_options()
	assert(available.size() == Resolver.all_entries().size(), "All currently imported backgrounds should appear without any missing states")
	assert(designer._browse_background.text.contains(str(Resolver.all_entries().size())), "Imported catalogue count should match current registry")
	designer._on_browse_imported()
	assert(designer._browser_list.item_count == available.size())
	assert(designer._browser_description.text.contains("ART CANDIDATE"))
	designer._browser.hide()
	var has_library_storm := false
	for item: Dictionary in available:
		if item["backgroundId"] == "BG-LIBRARY" and item["lighting"] == "night" and item["roomState"] == "storm_leak":
			has_library_storm = true
	assert(has_library_storm, "Library storm needs to be discoverable among available images")
	var selected: Dictionary = {}
	var missing: Dictionary = {}
	for option: Dictionary in options:
		if option["backgroundId"] == "BG-HALL" and option["lighting"] == "day" and option["roomState"] == "habitable":
			selected = option
		if option["backgroundId"] == "BG-CORRIDOR" and option["lighting"] == "day" and option["roomState"] == "blocked":
			missing = option
	assert(not selected.is_empty() and not missing.is_empty())
	assert(Resolver.entry_for("BG-CORRIDOR", "day", "blocked").is_empty())
	designer._on_browse()
	assert(designer._browser_list.item_count == options.size())
	designer._browser.hide()

	var original_scene_id: String = str(designer._stage_data["sceneId"])
	var original_cast: Array = designer._stage_data["cast"].duplicate(true)
	designer._browser_selected = selected
	designer._apply_browser_background()
	assert(designer._stage_data["backgroundId"] == "BG-HALL")
	assert(designer._stage_data["lighting"] == "day")
	assert(designer._stage_data["roomState"] == "habitable")
	assert(designer._bg_image.texture != null)
	assert(designer._stage_data["sceneId"] == original_scene_id)
	assert(designer._stage_data["cast"] == original_cast)

	# Other backgrounds remain selectable even before an asset is produced.
	designer._browser_selected = missing
	designer._apply_browser_background()
	assert(designer._stage_data["backgroundId"] == "BG-CORRIDOR")
	assert(designer._bg_image.texture == null)
	assert(designer._placeholders.text.contains("ART PENDING"))
	assert(designer._stage_data["cast"] == original_cast)
	# Every approved location is available in the live editor stage without custom asset paths.
	var new_stage_cases := {
		"RM-BEAT-01-03": "BG-BATH-VIGNETTE:day:wet_unsafe",
		"RM-BEAT-02-03": "BG-KITCHEN:day:power_off",
		"RM-BEAT-02-04": "BG-KITCHEN:evening:partial_lighting",
		"RM-BEAT-04-01": "BG-GARDEN:day:unsafe_path",
		"RM-BEAT-04-02": "BG-CONSERVATORY:day:partially_safe",
		"RM-BEAT-04-03": "BG-CONSERVATORY:day:partially_safe",
		"RM-BEAT-04-04": "BG-CONSERVATORY:dusk:partially_safe",
	}
	for scene_id: String in new_stage_cases:
		designer.set_scene(project, draft, scene_id)
		var key: String = "%s:%s:%s" % [
			str(designer._stage_data["backgroundId"]),
			str(designer._stage_data["lighting"]),
			str(designer._stage_data["roomState"])
		]
		assert(key == new_stage_cases[scene_id], "Wrong native VN Studio background: " + scene_id)
		assert(designer._bg_image.texture == Resolver.texture_for_scene(scene_id),
			"VN Studio must display the exact same image as gameplay: " + scene_id)
		assert(designer._bg_image.texture != null)
	assert(designer._available_browser_options().size() == 26,
		"Native VN Studio must discover all 26 imported variants")
	designer.queue_free()
	print("Raven VN Studio background-state preview smoke passed")
	quit()
