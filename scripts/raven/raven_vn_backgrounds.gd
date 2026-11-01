extends RefCounted
## Candidate VN-only background registry. It never affects Raven save or map state.
const AssetCatalog = preload("res://data/raven/production/vn_background_catalog.json")
const Staging = preload("res://data/raven/production/vn_staging.json")

static func all_entries() -> Array:
	return AssetCatalog.data.get("entries", [])


static func entry_for(background_id: String, lighting: String, room_state: String) -> Dictionary:
	for entry: Dictionary in all_entries():
		if str(entry.get("backgroundId", "")) == background_id and str(entry.get("lighting", "")) == lighting and str(entry.get("roomState", "")) == room_state:
			return entry
	return {}


static func entry_for_scene(scene_id: String) -> Dictionary:
	for shot: Dictionary in Staging.data.get("sceneShots", []):
		if str(shot.get("sceneId", "")) == scene_id:
			return entry_for(str(shot.get("backgroundId", "")), str(shot.get("lighting", "")), str(shot.get("roomState", "")))
	return {}


static func texture_for(background_id: String, lighting: String, room_state: String) -> Texture2D:
	var entry: Dictionary = entry_for(background_id, lighting, room_state)
	if entry.is_empty():
		return null
	var path := str(entry.get("path", ""))
	if not path.begins_with("res://assets/raven/vn_backgrounds/") or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


static func texture_for_scene(scene_id: String) -> Texture2D:
	var entry: Dictionary = entry_for_scene(scene_id)
	if entry.is_empty():
		return null
	return texture_for(str(entry["backgroundId"]), str(entry["lighting"]), str(entry["roomState"]))
