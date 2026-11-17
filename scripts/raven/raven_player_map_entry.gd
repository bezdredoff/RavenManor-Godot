extends RefCounted
## GAME-LOOP-02: sole normal-flow routing decision for the production manor.
## Never accepts candidate geometry or a caller-supplied production world plan.
const Source = preload("res://scripts/raven/manor_navigation_source.gd")

const MAP_SCENE := "res://scenes/raven/manor_player_map.tscn"
const OPENING_BEAT := "RM-BEAT-01-01"

static func approved_source(snapshot: Dictionary) -> Dictionary:
	for beat in ["RM-BEAT-00-01", "RM-BEAT-00-02", "RM-BEAT-00-03", OPENING_BEAT]:
		if not snapshot.get("storyBeatsSeen", []).has(beat):
			return {"ok": false, "status": "opening-vn-pending"}
	return Source.resolve({
		"schemaVersion": Source.SCHEMA_VERSION,
		"kind": Source.REQUEST_KIND,
		"mode": Source.MODE_PRODUCTION,
		"snapshot": snapshot.duplicate(true),
	})

static func can_enter(snapshot: Dictionary) -> bool:
	var selection: Dictionary = approved_source(snapshot)
	return bool(selection.get("ok", false)) and bool(selection.get("movementEnabled", false)) \
		and not bool(selection.get("draftOnly", true)) \
		and str(selection.get("approval", "")) == Source.PRODUCTION_APPROVAL
