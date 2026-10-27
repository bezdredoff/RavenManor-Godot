extends SceneTree

const Graph = preload("res://scripts/raven/manor_navigation_graph.gd")
const Catalog = preload("res://data/raven/foundation_catalog.json")
const ScriptData = preload("res://data/raven/production/season1_dialogue_catalog.json")
const Copy = preload("res://scripts/raven/raven_production_localization.gd")
const Snapshot = preload("res://scripts/raven/raven_snapshot.gd")
const Reducer = preload("res://scripts/raven/raven_reducer.gd")
const HallTeaScene = preload("res://scenes/raven/hall_tea_vn.tscn")


func _initialize() -> void:
	var beat_id := "RM-BEAT-02-01"
	assert(Catalog.data.storyBeats.has(beat_id))
	assert(Catalog.data.hotspots.has("RM-HS-TEA-TABLE"))
	var lines: Array = []
	for entry: Dictionary in ScriptData.data.entries:
		if entry.sceneId == beat_id:
			lines.append(entry)
	assert(lines.size() == 12, "Chapter II tea pilot must use 12 canonical screenplay lines")
	for entry: Dictionary in lines:
		assert(not Copy.line_text(entry.id, "ru").is_empty())
		assert(not Copy.line_text(entry.id, "be").is_empty())
		assert(not Copy.line_text(entry.id, "en").is_empty())
		assert(entry.speakerId in ["RM-CHAR-EVELYN", "RM-CHAR-ADA"])
	assert(Copy.line_text(lines[0].id, "ru").begins_with("Вчера мне казалось"))
	assert(Copy.line_text(lines[0].id, "en").begins_with("Yesterday"))
	assert(Copy.popup_text("RM-POP-TEA-TABLE", "be").length() > 8)
	assert(HallTeaScene != null)

	var art := [
		load("res://assets/raven/vn_pilot/hall_morning.webp") as Texture2D,
		load("res://assets/raven/vn_pilot/evelyn_relaxed.webp") as Texture2D,
		load("res://assets/raven/vn_pilot/ada_offer_tea.webp") as Texture2D
	]
	for texture: Texture2D in art:
		assert(texture != null and texture.get_width() >= 300 and texture.get_height() >= 450)

	var state := Snapshot.fresh()
	var graph := Graph.new()
	graph.rebuild(state)
	assert(graph.interaction_anchor("RM-HS-TEA-TABLE") == "RM-NAV-HALL-TEA")
	assert(graph.route("RM-NAV-HALL-SPAWN", "RM-NAV-HALL-TEA") == ["RM-NAV-HALL-SPAWN", "RM-NAV-HALL-TEA"])

	# This beat is allowed as a new saved fact only after Chapter I;
	# it does not disturb the director's existing RM-VS-01 sequence.
	var first := Reducer.apply(state, {"eventId":"pilot-beat-1","type":"story_beat_seen","storyBeatId":beat_id})
	assert(first.ok and first.state.storyBeatsSeen.has(beat_id))
	var replay := Reducer.apply(first.state, {"eventId":"pilot-beat-2","type":"story_beat_seen","storyBeatId":beat_id})
	assert(replay.ok)
	assert(replay.state.storyBeatsSeen.count(beat_id) == 1)
	assert(replay.state.workPoints == state.workPoints)
	assert(replay.state.completedRestorations == state.completedRestorations)
	print("Raven Manor Hall tea VN pilot smoke passed (art, RU/BE/EN, navigation, save-safe replay).")
	quit()
