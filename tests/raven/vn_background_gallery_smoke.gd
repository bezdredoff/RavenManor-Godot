extends SceneTree
const Resolver = preload("res://scripts/raven/raven_vn_backgrounds.gd")
const Gallery = preload("res://scenes/raven/vn_background_gallery.tscn")


func _initialize() -> void:
	var entries: Array = Resolver.all_entries()
	assert(entries.size() == 9, "Four Hall and five Library backgrounds expected")
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
	assert(str(Resolver.entry_for_scene("RM-BEAT-02-01").get("id", "")) == "BG-HALL:day:habitable")
	assert(str(Resolver.entry_for_scene("RM-BEAT-05-02").get("id", "")) == "BG-LIBRARY:night:storm_leak")
	assert(Resolver.entry_for_scene("RM-BEAT-00-01").is_empty())
	print("Raven VN background registry and 9 textures PASS (candidate gallery, save neutral)")
	quit()
