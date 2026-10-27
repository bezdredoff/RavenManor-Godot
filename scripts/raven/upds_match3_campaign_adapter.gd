extends RefCounted
## Content boundary only. The rules, cascades, RNG, specials, blockers and
## board masks are the UPDS engine imported under scripts/shared/upds/.
const Content = preload("res://data/raven/rm_vs_01_content.json")
const TilePool = preload("res://data/raven/tile_pool.json")

static func normalize(configured: Dictionary) -> Dictionary:
	var level: Dictionary = configured.duplicate(true)
	if level.is_empty():
		return {}
	if not level.has("activeTiles"):
		level["activeTiles"] = level.get("tiles", []).duplicate()
	if not level.has("objectives"):
		var objective: Dictionary = level.get("objective", {})
		level["objectives"] = [{
			"kind": str(objective.get("kind", "collect")),
			"tile": str(objective.get("tile", "")),
			"target": int(objective.get("target", 0)),
			"label": str(objective.get("label", ""))
		}]
	if not level.has("boardHoles"):
		level["boardHoles"] = []
	if not level.has("blockers"):
		level["blockers"] = []
	if not level.has("ingredients"):
		level["ingredients"] = []
	# All eight thematic Raven IDs are the same logical tile types for every level.
	var known := {}
	for item: Dictionary in TilePool.data.types:
		known[str(item.id)] = true
	for key: Variant in level.activeTiles:
		assert(known.has(str(key)), "Unknown Raven Match-3 tile: " + str(key))
	return level

static func load_bundle() -> Dictionary:
	var levels: Array = []
	for level: Dictionary in Content.data.levels:
		levels.append(normalize(level))
	return {"schemaVersion": 1, "levels": levels}

static func get_level(bundle: Dictionary, level_id: String) -> Dictionary:
	for level: Dictionary in bundle.get("levels", []):
		if str(level.get("id", "")) == level_id:
			return level
	return {}
