extends RefCounted
## UPDS-origin Match3Game preload path; Raven alone owns content adaptation.
const RavenLevels = preload("res://scripts/raven/upds_match3_campaign_adapter.gd")
static func load_bundle() -> Dictionary:
	return RavenLevels.load_bundle()
static func get_level(bundle: Dictionary, level_id: String) -> Dictionary:
	return RavenLevels.get_level(bundle, level_id)
