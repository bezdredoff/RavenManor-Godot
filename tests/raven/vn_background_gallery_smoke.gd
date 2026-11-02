extends SceneTree
const Resolver = preload("res://scripts/raven/raven_vn_backgrounds.gd")
const Gallery = preload("res://scenes/raven/vn_background_gallery.tscn")


func _initialize() -> void:
	var entries: Array = Resolver.all_entries()
	assert(entries.size() == 26, "All 26 stage-backed and optional already approved backgrounds expected")
	assert(Gallery != null)
	var ids := {}
	for entry: Dictionary in entries:
		var id: String = str(entry.get("id", ""))
		assert(str(entry.get("status", "")) == "accepted", "Owner-approved imported background must stay accepted: " + id)
		assert(not ids.has(id), "Duplicate background variant")
		ids[id] = true
		assert(entry.get("width", 0) == 1080 and entry.get("height", 0) == 1920)
		var texture: Texture2D = Resolver.texture_for(str(entry["backgroundId"]), str(entry["lighting"]), str(entry["roomState"]))
		assert(texture != null, "Missing background asset: " + id)
		assert(texture.get_width() == 1080 and texture.get_height() == 1920, id)
		if str(entry.get("backgroundId", "")) in ["BG-APARTMENT", "BG-ROAD", "BG-ENTRY", "BG-BEDROOM", "BG-BATH-VIGNETTE", "BG-KITCHEN", "BG-GARDEN", "BG-CONSERVATORY"]:
			var asset_path: String = str(entry.get("path", ""))
			assert(FileAccess.file_exists(asset_path), "Missing VN background source file: " + asset_path)
			assert(FileAccess.get_sha256(asset_path) == str(entry.get("sha256", "")),
				"VN background asset SHA-256 mismatch: " + id)
	var baseline_ids := [
		"BG-HALL:evening:dusty",
		"BG-HALL:day:habitable",
		"BG-HALL:night:habitable",
		"BG-HALL:night:storm",
		"BG-LIBRARY:evening:shut_dusty",
		"BG-LIBRARY:evening:usable",
		"BG-LIBRARY:day:usable",
		"BG-LIBRARY:night:usable",
		"BG-LIBRARY:night:storm_leak"
	]
	for required in baseline_ids:
		assert(ids.has(required), "Baseline asset missing: " + required)
	assert(str(Resolver.entry_for_scene("RM-BEAT-02-01").get("id", "")) == "BG-HALL:day:habitable")
	assert(str(Resolver.entry_for_scene("RM-BEAT-05-02").get("id", "")) == "BG-LIBRARY:night:storm_leak")
	assert(str(Resolver.entry_for_scene("RM-BEAT-00-01").get("id", "")) == "BG-APARTMENT:day:packed_boxes")
	for required in [
		"BG-APARTMENT:day:inhabited",
		"BG-APARTMENT:evening:rainy",
		"BG-APARTMENT:night:rainy",
		"BG-APARTMENT:day:packed_boxes",
		"BG-ROAD:dusk:mist",
		"BG-ENTRY:dusk:approachable",
		"BG-ENTRY:day:approachable",
		"BG-ENTRY:dusk:overgrown",
		"BG-ENTRY:day:overgrown",
		"BG-BEDROOM:day:livable",
		"BG-BEDROOM:night:livable",
		"BG-BATH-VIGNETTE:day:wet_unsafe",
		"BG-KITCHEN:day:power_off",
		"BG-KITCHEN:evening:partial_lighting",
		"BG-GARDEN:day:unsafe_path",
		"BG-CONSERVATORY:day:partially_safe",
		"BG-CONSERVATORY:dusk:partially_safe"
	]:
		assert(ids.has(required), "Missing imported art: " + required)
	assert(str(Resolver.entry_for_scene("RM-BEAT-00-02").get("id", "")) == "BG-ROAD:dusk:mist", "Prologue road must use the imported dusk/mist plate")
	assert(Resolver.texture_for_scene("RM-BEAT-00-02") != null, "Road must be loadable in the same registry as VN Studio")
	assert(str(Resolver.entry_for_scene("RM-BEAT-00-03").get("id", "")) == "BG-ENTRY:dusk:overgrown", "First manor gate beat must use dusk/overgrown")
	assert(str(Resolver.entry_for_scene("RM-BEAT-02-02").get("id", "")) == "BG-ENTRY:day:approachable", "Post-hall return beat must use day/approachable")
	assert(Resolver.texture_for_scene("RM-BEAT-00-03") != null, "Entry dusk/overgrown must be loadable")
	assert(Resolver.texture_for_scene("RM-BEAT-02-02") != null, "Entry day/approachable must be loadable")
	assert(str(Resolver.entry_for_scene("RM-BEAT-01-02").get("id", "")) == "BG-BEDROOM:day:livable", "Chapter I bedroom must resolve to day livable")
	assert(str(Resolver.entry_for_scene("RM-BEAT-06-03").get("id", "")) == "BG-BEDROOM:night:livable", "Chapter VI bedroom must resolve to night livable")
	assert(Resolver.texture_for_scene("RM-BEAT-01-02") != null, "Bedroom daytime scene texture missing")
	assert(Resolver.texture_for_scene("RM-BEAT-06-03") != null, "Bedroom nighttime scene texture missing")
	assert(Resolver.entry_for("BG-BEDROOM", "day", "covered").is_empty(), "Covered bedroom state not drawn: must remain ART PENDING")
	# New six scene-authorized assets must resolve from exact shared studio staging.
	var story_plates := {
		"RM-BEAT-01-03": "BG-BATH-VIGNETTE:day:wet_unsafe",
		"RM-BEAT-02-03": "BG-KITCHEN:day:power_off",
		"RM-BEAT-02-04": "BG-KITCHEN:evening:partial_lighting",
		"RM-BEAT-04-01": "BG-GARDEN:day:unsafe_path",
		"RM-BEAT-04-02": "BG-CONSERVATORY:day:partially_safe",
		"RM-BEAT-04-03": "BG-CONSERVATORY:day:partially_safe",
		"RM-BEAT-04-04": "BG-CONSERVATORY:dusk:partially_safe",
	}
	for scene_id: String in story_plates:
		assert(str(Resolver.entry_for_scene(scene_id).get("id", "")) == str(story_plates[scene_id]),
			"Wrong stage art for " + scene_id)
		assert(Resolver.texture_for_scene(scene_id) != null, "Unloaded gameplay art for " + scene_id)
	assert(Resolver.entry_for("BG-BATH-VIGNETTE", "day", "specialist_fixed").is_empty())
	assert(Resolver.entry_for("BG-GARDEN", "dusk", "after_storm").is_empty())
	assert(Resolver.entry_for("BG-CONSERVATORY", "storm", "storm_damage").is_empty())
	print("Raven VN background registry and 9 textures PASS (actual total: %d, save neutral)" % entries.size())
	quit()
