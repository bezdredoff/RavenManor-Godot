extends RefCounted
## Explicit, project-owned reviewed FX resources, never local Studio draft IO.
## The game's content author must review each bundle in a GitHub PR.
const Registry = preload("res://data/raven/production/vn_reviewed_fx_catalog.json")
const FORMAT := "raven-vn-reviewed-fx-catalog-v1"


static func reviewed_for_scene(scene_id: String) -> Dictionary:
	if Registry.data.get("format", "") != FORMAT or Registry.data.get("schemaVersion", 0) != 1:
		return {}
	for record in Registry.data.get("bundles", []):
		if record is Dictionary and str(record.get("sceneId", "")) == scene_id \
				and record.get("approvalStatus") == "approved" \
				and not str(record.get("approvalRef", "")).strip_edges().is_empty():
			return record.duplicate(true)
	return {}
