extends RefCounted
## Synthetic approval exists only in this in-memory test copy. Never saved.
const Candidate = preload("res://data/raven/manor_production_candidate.v1.json")
static var _original: Dictionary = {}
const Source = preload("res://scripts/raven/manor_navigation_source.gd")

static func plan() -> Dictionary:
	var result: Dictionary = Candidate.data.duplicate(true)
	result.provenance.approval = Source.PRODUCTION_APPROVAL
	result.provenance.productionReady = true
	result.provenance.roomArtCalibration.status = "approved"
	return result

static func request() -> Dictionary:
	return {"schemaVersion": 1, "kind": Source.REQUEST_KIND, "mode": Source.MODE_PRODUCTION}


## Test process only: replace the JSON Resource's in-memory value, never its
## file. Normal entry, source selection, validation and host.configure remain
## untouched. Every test-created host/view receives memory storage explicitly.
static func install_canonical() -> void:
	assert(_original.is_empty(), "Nested canonical fixture")
	_original = Source.WORLD_PLAN.data.duplicate(true)
	var canonical: JSON = Source.WORLD_PLAN
	canonical.data.clear()
	canonical.data.merge(plan(), true)


static func restore_canonical() -> void:
	assert(not _original.is_empty())
	var canonical: JSON = Source.WORLD_PLAN
	canonical.data.clear()
	canonical.data.merge(_original, true)
	_original = {}
