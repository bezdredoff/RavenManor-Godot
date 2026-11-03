extends SceneTree
const Snapshot = preload("res://scripts/raven/raven_snapshot.gd")
const Ids = preload("res://scripts/raven/raven_ids.gd")

func _initialize() -> void:
	var fresh := Snapshot.fresh()
	assert(fresh.vnCursor.is_empty(), "New game must not resume old VN")
	var state := fresh.duplicate(true)
	state.vnCursor = {"beatId": "RM-BEAT-00-01", "lineIndex": 2}
	var restored: Variant = Snapshot.normalize(state, Ids.CATALOG.data)
	assert(restored != null and restored.vnCursor == state.vnCursor, "Valid VN line checkpoint lost")
	state.vnCursor = {"beatId": "unknown", "lineIndex": 2}
	assert(Snapshot.normalize(state, Ids.CATALOG.data).vnCursor.is_empty(), "Unknown beat checkpoint accepted")
	state.vnCursor = {"beatId": "RM-BEAT-00-01", "lineIndex": -1}
	assert(Snapshot.normalize(state, Ids.CATALOG.data).vnCursor.is_empty(), "Negative VN cursor accepted")
	state.vnCursor = {"beatId": "RM-BEAT-00-01", "lineIndex": 2}
	state.storyBeatsSeen.append("RM-BEAT-00-01")
	assert(Snapshot.normalize(state, Ids.CATALOG.data).vnCursor.is_empty(), "Completed beat must not resume")
	print("Raven Manor VN line checkpoint smoke passed")
	quit()
