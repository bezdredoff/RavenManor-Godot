@tool
extends RefCounted
## VNS5-06C: deterministic, read-only promotion REVIEW. No canonical writes,
## runtime approval, migration, scene routing or save contract mutation.
const Author = preload("res://addons/vn_studio/model/raven_story_authoring.gd")
const FORMAT := "raven-vn-promotion-review-v1"
const REVIEW_STATUS := "DRAFT_PROMOTION_REVIEW_NOT_RUNTIME"


static func validate_mapping(project: Dictionary, draft: Dictionary, mapping: Variant) -> String:
	if not mapping is Dictionary:
		return "Promotion ID mapping must be an object."
	var authored: Dictionary = {}
	for scene in draft.get("authoredScenes", []):
		authored[str(scene.get("sceneId", ""))] = true
	var used: Dictionary = {}
	for scene in project.get("scenes", []):
		used[str(scene.get("sceneId", ""))] = true
	var re: RegEx = RegEx.create_from_string("^RM-BEAT-[0-9]{2}-[0-9]{2}$")
	for source in mapping:
		if not source is String or not authored.has(source):
			return "Promotion map references an unknown draft scene."
		var target: Variant = mapping[source]
		if not target is String or re.search(target) == null:
			return "Promotion target requires a full canonical-style RM-BEAT-XX-YY ID."
		if used.has(target):
			return "Promotion target collides with a canonical or proposed scene ID: " + str(target)
		used[target] = true
	return ""


static func plan(project: Dictionary, draft: Dictionary) -> Dictionary:
	var mapping: Variant = draft.get("promotionSceneIdMap", {})
	var error: String = validate_mapping(project, draft, mapping)
	if not error.is_empty():
		return {"ok": false, "error": error}
	if draft.get("authoredScenes", []).is_empty() and draft.get("authoredLines", []).is_empty() and draft.get("storyGraphPatches", {}).is_empty():
		return {"ok": false, "error": "No scene, line or Story Map changes require promotion."}
	var unmapped: Array[String] = []
	for scene in draft.get("authoredScenes", []):
		var source: String = str(scene["sceneId"])
		if not mapping.has(source):
			unmapped.append(source)
	if not unmapped.is_empty():
		return {"ok": false, "error": "Assign production scene IDs before export: " + ", ".join(unmapped)}
	var line_map: Dictionary = {}
	var used_lines: Dictionary = {}
	for entry in project.get("data", {}).get("entries", []):
		used_lines[str(entry["id"])] = true
	for entry in draft.get("authoredLines", []):
		var id: String = str(entry["id"])
		var scene_id: String = str(entry["sceneId"])
		var mapped: String = str(mapping.get(scene_id, scene_id))
		var next_id: String = mapped + id.substr(scene_id.length())
		if used_lines.has(next_id):
			return {"ok": false, "error": "Proposed line ID collides with canonical/another proposed line: " + next_id}
		used_lines[next_id] = true
		line_map[id] = next_id
	var proposed: Dictionary = Author.export_preview(project, draft)
	var first_existing_scenes: int = project["scenes"].size()
	var first_existing_lines: int = project["data"]["entries"].size()
	var generated_lines: Dictionary = {}
	for scene in proposed["scenes"]:
		var id: String = str(scene["sceneId"])
		if mapping.has(id):
			scene["sceneId"] = mapping[id]
			scene["status"] = "proposed_future_runtime"
			scene["source"] = "vn_studio_promotion_review_only"
	for entry in proposed["entries"]:
		var scene_id: String = str(entry["sceneId"])
		if mapping.has(scene_id):
			entry["sceneId"] = mapping[scene_id]
		if line_map.has(str(entry["id"])):
			entry["id"] = line_map[str(entry["id"])]
			entry["source"] = "vn_studio_promotion_review_only"
			generated_lines[str(entry["id"])] = true
	proposed["status"] = REVIEW_STATUS
	var graph: Dictionary = {}
	var linked_scenes: Dictionary = {}
	for scene_id in draft.get("storyGraphPatches", {}):
		var source: String = str(scene_id)
		var overlay: Dictionary = draft["storyGraphPatches"][scene_id].duplicate(true)
		var mapped_source: String = str(mapping.get(source, source))
		overlay["sceneId"] = mapped_source
		for edge in overlay.get("edges", []):
			if edge.get("kind") != "match3":
				edge["targetId"] = mapping.get(str(edge.get("targetId", "")), edge.get("targetId", ""))
			if edge.has("lineId"):
				edge["lineId"] = line_map.get(str(edge["lineId"]), edge["lineId"])
			if edge.get("kind") == "choice":
				linked_scenes[mapped_source] = true
				linked_scenes[str(edge.get("targetId", ""))] = true
		if graph.has(mapped_source):
			return {"ok": false, "error": "Promotion graph has a duplicated mapped source."}
		graph[mapped_source] = overlay
	var blockers: Array[String] = []
	var warnings: Array[String] = []
	for scene in draft.get("authoredScenes", []):
		var target: String = str(mapping[scene["sceneId"]])
		blockers.append(target + ": needs reviewed vn_staging.sceneShot with approved art/cast/lighting")
		blockers.append(target + ": needs reviewed map_narrative_routes.sceneTrigger/gate and interaction target")
		blockers.append(target + ": needs explicit game progression/save migration and story owner acceptance")
	for source in graph:
		if not graph[source].get("edges", []).is_empty():
			blockers.append(str(source) + ": proposed Story Map edges need approved runtime branch/Match-3/return semantics")
	if not draft.get("stagePatches", {}).is_empty() or not draft.get("stageV2Patches", {}).is_empty() or not draft.get("stageFxPatches", {}).is_empty():
		warnings.append("Staging/FX drafts accompany the candidate but require separate art and runtime approvals.")
	for scene in draft.get("authoredScenes", []):
		for lang in ["be", "en"]:
			if scene.get("title", {}).get(lang) == null or str(scene["title"].get(lang, "")).strip_edges().is_empty():
				warnings.append(str(mapping[scene["sceneId"]]) + ": missing title " + lang.to_upper())
	for entry in draft.get("authoredLines", []):
		var id: String = str(line_map[str(entry["id"])])
		for lang in ["be", "en"]:
			var text_patch: Variant = draft.get("patches", {}).get(str(entry["id"]), {}).get(lang)
			var cell: Variant = entry.get("localized", {}).get(lang)
			if (text_patch == null or str(text_patch).strip_edges().is_empty()) and (not cell is Dictionary or str(cell.get("text", "")).strip_edges().is_empty()):
				warnings.append(id + ": missing line translation " + lang.to_upper())
	if not draft.get("authoredLines", []).is_empty():
		warnings.append("New lines require line-cue, locale paging, and VN save/replay verification.")
	var result: Dictionary = {
		"format": FORMAT, "schemaVersion": 1,
		"sourceSha256": project["sha"], "routeSourceSha256": project["routesSha"],
		"stageSourceSha256": project["stagingSha"], "castSourceSha256": project["castSha"],
		"idMap": mapping.duplicate(true), "lineIdMap": line_map,
		"reviewCatalog": proposed, "reviewGraphPatches": graph,
		"diffSummary": {
			"scenesBefore": first_existing_scenes, "scenesProposed": proposed["scenes"].size(),
			"linesBefore": first_existing_lines, "linesProposed": proposed["entries"].size(),
			"newScenes": draft.get("authoredScenes", []).size(),
			"newLines": draft.get("authoredLines", []).size(),
			"changedTextCells": _count_text_patches(draft),
			"graphSourceScenes": graph.size()},
		"retainedDraft": {
			"storyGraphPatches": draft.get("storyGraphPatches", {}).duplicate(true),
			"textPatches": draft.get("patches", {}).duplicate(true),
			"stagePatches": draft.get("stagePatches", {}).duplicate(true),
			"stageV2Patches": draft.get("stageV2Patches", {}).duplicate(true),
			"stageFxPatches": draft.get("stageFxPatches", {}).duplicate(true)},
		"promotionBlockers": blockers, "localizationWarnings": warnings,
		"runtimeApplied": false, "readyForRuntime": false,
		"requiresHumanReview": true, "requiresFollowUpPromotion": true
	}
	return {"ok": true, "bundle": result, "blockers": blockers, "warnings": warnings}


static func _count_text_patches(draft: Dictionary) -> int:
	var count: int = 0
	for changes in draft.get("patches", {}).values():
		if changes is Dictionary:
			count += changes.size()
	return count
