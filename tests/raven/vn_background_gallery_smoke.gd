extends SceneTree
const Resolver = preload("res://scripts/raven/raven_vn_backgrounds.gd")
const Gallery = preload("res://scenes/raven/vn_background_gallery.tscn")


func _initialize() -> void:
	var entries: Array = Resolver.all_entries()
	assert(entries.size() >= 9, "At least the nine merged Hall and Library backgrounds expected")
	assert(Gallery != null)
	var ids := {}
	for entry: Dictionary in entries:
		var id: String = str(entry.get("id", ""))
		assert(not ids.has(id), "Duplicate background variant")
		ids[id] = true
		assert(entry.get("width", 0) == 1080 and entry.get("height", 0) == 1920)
		var texture: Texture2D = Resolver.texture_for(str(entry["backgroundId"]), str(entry["lighting"]), str(entry["roomState"]))
		assert(texture != null, "Missing background asset: " + id)
		assert(texture.get_width() == 1080 and texture.get_height() == 1920, id)
		if str(entry.get("backgroundId", "")) == "BG-APARTMENT":
			var asset_path: String = str(entry.get("path", ""))
			assert(FileAccess.file_exists(asset_path), "Missing apartment source file: " + asset_path)
			assert(FileAccess.get_sha256(asset_path) == str(entry.get("sha256", "")),
				"Apartment asset SHA-256 mismatch (incorrect image revision): " + id)
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
		"BG-APARTMENT:day:packed_boxes"
	]:
		assert(ids.has(required), "Apartment asset missing: " + required)
	assert(entries.size() >= 13, "Four additional Apartment plates must be integrated")
	print("Raven VN background registry and 9 textures PASS (actual total: %d, save neutral)" % entries.size())
	quit()
