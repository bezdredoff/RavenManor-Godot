extends RefCounted
## Synthetic approval exists only in this in-memory test copy. Never saved.
const Candidate = preload("res://data/raven/manor_production_candidate.v1.json")
const Source = preload("res://scripts/raven/manor_navigation_source.gd")

static func plan() -> Dictionary:
	var result: Dictionary = Candidate.data.duplicate(true)
	result.provenance.approval = Source.PRODUCTION_APPROVAL
	result.provenance.productionReady = true
	result.provenance.roomArtCalibration.status = "approved"
	return result

static func request() -> Dictionary:
	return {"schemaVersion": 1, "kind": Source.REQUEST_KIND, "mode": Source.MODE_PRODUCTION,
		"testOnlyProductionFixture": true, "worldPlan": plan()}

static func available(snapshot: Dictionary) -> bool:
	for beat in ["RM-BEAT-00-01", "RM-BEAT-00-02", "RM-BEAT-00-03", "RM-BEAT-01-01"]:
		if not snapshot.storyBeatsSeen.has(beat):
			return false
	return bool(Source.resolve(request().merged({"snapshot": snapshot})).get("ok", false))
