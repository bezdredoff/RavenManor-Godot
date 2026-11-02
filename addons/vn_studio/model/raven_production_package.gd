@tool
extends RefCounted
## VNS5-06D1: Four-registry production review candidate only, NEVER a runtime
## activation or writes to res://. Canonical data is deep-copied.
const Promotion = preload("res://addons/vn_studio/model/raven_story_promotion.gd")
const FORMAT := "raven-vn-production-package-manifest-v1"
const PACKAGE := "raven-vn-production-4registry-review-v1"
const KEYS := ["format", "schemaVersion", "sourceSha256", "routeSourceSha256",
	"stageSourceSha256", "castSourceSha256", "cueSourceSha256", "reviewRef",
	"savePolicy", "sceneShots", "routeProposals", "lineCues"]
const SHOT_KEYS := ["backgroundId", "lighting", "roomState", "cast"]
const ACTOR_KEYS := ["characterId", "slot", "pose", "emotion", "micro"]
const CUE_KEYS := ["poseId", "emotionId", "portraitVisible", "microOnEnter"]
const ROUTE_KEYS := ["kind", "ref", "interactionTarget"]
const SLOTS := ["left", "center", "right"]
const SAVE_POLICY := "catalog_only_no_runtime"


static func template(project: Dictionary, draft: Dictionary) -> Dictionary:
	var proposed: Dictionary = Promotion.plan(project, draft)
	if not proposed.get("ok", false):
		return {"ok": false, "error": str(proposed.get("error", ""))}
	var bundle: Dictionary = proposed["bundle"]
	var shots: Dictionary = {}
	var routes: Dictionary = {}
	for source in bundle["idMap"]:
		var scene_id: String = str(bundle["idMap"][source])
		shots[scene_id] = {"backgroundId": "", "lighting": "", "roomState": "", "cast": []}
		routes[scene_id] = {"kind": "scene_complete", "ref": "", "interactionTarget": ""}
	var cues: Dictionary = {}
	for id in bundle["lineIdMap"].values():
		cues[str(id)] = {"poseId": "", "emotionId": "", "portraitVisible": false,
			"microOnEnter": null}
	return {"ok": true, "manifest": {
		"format": FORMAT, "schemaVersion": 1,
		"sourceSha256": project["sha"], "routeSourceSha256": project["routesSha"],
		"stageSourceSha256": project["stagingSha"], "castSourceSha256": project["castSha"],
		"cueSourceSha256": project["cuesSha"], "reviewRef": "",
		"savePolicy": SAVE_POLICY, "sceneShots": shots,
		"routeProposals": routes, "lineCues": cues}}


static func assemble(project: Dictionary, draft: Dictionary, manifest: Variant) -> Dictionary:
	var planned: Dictionary = Promotion.plan(project, draft)
	if not planned.get("ok", false):
		return {"ok": false, "error": str(planned.get("error", ""))}
	var planned_bundle: Dictionary = planned["bundle"]
	if not manifest is Dictionary:
		return {"ok": false, "error": "Promotion package manifest must be an object."}
	for key in manifest:
		if key not in KEYS:
			return {"ok": false, "error": "Unexpected manifest field: " + str(key)}
	if manifest.get("format") != FORMAT or manifest.get("schemaVersion") != 1:
		return {"ok": false, "error": "Unknown production package manifest format."}
	for pair in [["sourceSha256", "sha"], ["routeSourceSha256", "routesSha"],
			["stageSourceSha256", "stagingSha"], ["castSourceSha256", "castSha"],
			["cueSourceSha256", "cuesSha"]]:
		if manifest.get(pair[0]) != project.get(pair[1], ""):
			return {"ok": false, "error": "Source SHA drift for " + str(pair[0])}
	if manifest.get("savePolicy") != SAVE_POLICY:
		return {"ok": false, "error": "Playable/save migration is not authorized by VNS5-06D1."}
	var review: Variant = manifest.get("reviewRef", "")
	if not review is String or review.strip_edges().length() < 4 or review.length() > 160:
		return {"ok": false, "error": "Explicit reviewer reference (4–160 chars) required."}
	for category in ["sceneShots", "routeProposals", "lineCues"]:
		if not manifest.get(category) is Dictionary:
			return {"ok": false, "error": category + " must be a keyed object."}
	# A proposed choice/Match-3 graph is not a supported playable runtime contract.
	for source in planned_bundle.get("reviewGraphPatches", {}):
		if not planned_bundle["reviewGraphPatches"][source].get("edges", []).is_empty():
			return {"ok": false, "error": "Story Map branches still need VNS5-06D2 runtime/save contract: " + str(source)}
	var scenes: Dictionary = {}
	for item in planned_bundle["reviewCatalog"]["scenes"]:
		scenes[str(item["sceneId"])] = true
	var expected_scenes: Array = planned_bundle["idMap"].values()
	if not _exact_keys(manifest["sceneShots"], expected_scenes) or not _exact_keys(manifest["routeProposals"], expected_scenes):
		return {"ok": false, "error": "Every new scene requires exactly one shot and one route proposal."}
	var line_map: Dictionary = planned_bundle["lineIdMap"]
	if not _exact_keys(manifest["lineCues"], line_map.values()):
		return {"ok": false, "error": "Every authored line requires exactly one performance cue."}
	var existing_ids: Dictionary = {}
	for entry in planned_bundle["reviewCatalog"]["entries"]:
		existing_ids[str(entry["id"])] = entry
	var backgrounds: Dictionary = {}
	for bg in project["stagingData"]["masters"]:
		backgrounds[str(bg["id"])] = bg
	var actors: Dictionary = {}
	for actor in project["castData"]["characters"]:
		actors[str(actor["id"])] = actor
	var proposed_shots: Array = []
	for scene_id in expected_scenes:
		var shot: Variant = manifest["sceneShots"][scene_id]
		var shot_error: String = _validate_shot(shot, backgrounds, actors,
			project["castData"].get("commonMicro", []))
		if not shot_error.is_empty():
			return {"ok": false, "error": str(scene_id) + " staging: " + shot_error}
		var normalized: Dictionary = shot.duplicate(true)
		normalized["sceneId"] = scene_id
		normalized["visibleCount"] = shot["cast"].size()
		normalized["layout"] = "portrait_first"
		normalized["note"] = "REVIEW ONLY — no runtime art approval"
		proposed_shots.append(normalized)
	var proposed_routes: Array = []
	var dependencies: Dictionary = {}
	for scene_id in expected_scenes:
		var route: Variant = manifest["routeProposals"][scene_id]
		var route_error: String = _validate_route(route, scene_id, scenes, project)
		if not route_error.is_empty():
			return {"ok": false, "error": str(scene_id) + " route: " + route_error}
		dependencies[scene_id] = route["ref"] if route["kind"] == "scene_complete" else ""
		proposed_routes.append({
			"sceneId": scene_id, "ordinal": project["scenes"].size() + proposed_routes.size(),
			"gate": {"kind": "draft_unapproved", "ref": "none",
				"approvedRuntime": false, "proposedRuntime": true},
			"interactionTarget": "review_only_not_playable",
			"whenReached": "play_once_then_unlock_next_state",
			"revisit": "show_inspect_popup_without_replaying_one_shot_scene",
			"postSceneAction": "record_story_beat_only_after_player_finishes_VN",
			"notes": "Review proposal: " + JSON.stringify(route)
		})
	for id in dependencies:
		var seen: Dictionary = {}
		var at: String = str(id)
		while dependencies.has(at) and not str(dependencies[at]).is_empty():
			if seen.has(at):
				return {"ok": false, "error": "New scene gate dependency cycle at " + str(id)}
			seen[at] = true
			at = str(dependencies[at])
	var cues: Array = []
	for promoted_id in line_map.values():
		var line: Dictionary = existing_ids[str(promoted_id)]
		var cue: Variant = manifest["lineCues"][promoted_id]
		var error: String = _validate_cue(cue, line, actors)
		if not error.is_empty():
			return {"ok": false, "error": str(promoted_id) + " cue: " + error}
		cues.append({"lineId": promoted_id, "sceneId": line["sceneId"],
			"speakerId": line["speakerId"], "portraitVisible": cue["portraitVisible"],
			"poseId": cue["poseId"], "emotionId": cue["emotionId"],
			"microOnEnter": cue["microOnEnter"], "lipSync": "procedural",
			"eyeBlink": "procedural", "propOverlayId": null, "cameraFocus": "center",
			"transitions": {"enter": "fade_or_cut", "expression": "face_layer_fade",
				"reducedMotion": "instant"}, "manualReview": true})
	var dialogues: Dictionary = planned_bundle["reviewCatalog"].duplicate(true)
	var stages: Dictionary = project["stagingData"].duplicate(true)
	stages["sceneShots"].append_array(proposed_shots)
	var routes: Dictionary = project["routesData"].duplicate(true)
	routes["sceneTriggers"].append_array(proposed_routes)
	var performances: Dictionary = project["cuesData"].duplicate(true)
	performances["cues"].append_array(cues)
	for entry in dialogues["scenes"]:
		if planned_bundle["idMap"].values().has(entry["sceneId"]):
			entry["status"] = "review_only_not_runtime"
	for file in [dialogues, stages, routes, performances]:
		file["status"] = "DRAFT_REVIEW_NOT_RUNTIME"
	var output: Dictionary = {
		"format": PACKAGE, "schemaVersion": 1, "reviewRef": review,
		"sourceSha256": manifest["sourceSha256"],
		"routeSourceSha256": manifest["routeSourceSha256"],
		"stageSourceSha256": manifest["stageSourceSha256"],
		"castSourceSha256": manifest["castSourceSha256"],
		"cueSourceSha256": manifest["cueSourceSha256"],
		"sceneIdMap": planned_bundle["idMap"].duplicate(true),
		"lineIdMap": planned_bundle["lineIdMap"].duplicate(true),
		"routeProposals": manifest["routeProposals"].duplicate(true),
		"diffSummary": planned_bundle["diffSummary"].duplicate(true),
		"files": {
			"season1_dialogue_catalog.json": dialogues,
			"vn_staging.json": stages,
			"map_narrative_routes.json": routes,
			"line_performance_cues.json": performances
		},
		"retainedDraft": planned_bundle["retainedDraft"].duplicate(true),
		"releaseBlockers": [
			"Review-only routes use unsupported draft_unapproved gate and cannot enter gameplay",
			"Reviewer approval of art, route activation and renderer integration required",
			"Save ID/catalog migration, story beat replay, Match-3 branch parity and rollback required",
			"Human visual QA, BE/EN release localization and final release validation required"
		],
		"runtimeApplied": false, "readyForRuntime": false,
		"requiresHumanReview": true, "requiresFollowUpPromotion": true
	}
	return {"ok": true, "bundle": output}


static func _exact_keys(data: Dictionary, expected: Array) -> bool:
	if data.size() != expected.size():
		return false
	for key in expected:
		if not data.has(str(key)):
			return false
	return true


static func _validate_shot(shot: Variant, backgrounds: Dictionary, actors: Dictionary,
		common_micro: Array) -> String:
	if not shot is Dictionary:
		return "Shot must be an object."
	for k in shot:
		if k not in SHOT_KEYS:
			return "Unexpected shot field: " + str(k)
	var id: Variant = shot.get("backgroundId", "")
	if not id is String or not backgrounds.has(id):
		return "Unknown approved background master."
	var master: Dictionary = backgrounds[id]
	if shot.get("lighting") not in master.get("lightingVariants", []):
		return "Lighting variant missing from master."
	if shot.get("roomState") not in master.get("stateLayers", []):
		return "Room state missing from master."
	var cast: Variant = shot.get("cast", [])
	if not cast is Array or cast.size() < 1 or cast.size() > 3:
		return "Shot requires 1–3 registered actors."
	var used_ids: Dictionary = {}
	var used_slots: Dictionary = {}
	for actor in cast:
		if not actor is Dictionary:
			return "Actor must be an object."
		for field in actor:
			if field not in ACTOR_KEYS:
				return "Unexpected actor field: " + str(field)
		var actor_id: String = str(actor.get("characterId", ""))
		var slot: String = str(actor.get("slot", ""))
		if not actors.has(actor_id) or used_ids.has(actor_id):
			return "Unknown or repeated actor."
		if slot not in SLOTS or used_slots.has(slot):
			return "Invalid or repeated placement slot."
		var spec: Dictionary = actors[actor_id]
		if actor.get("pose") not in spec.get("poses", []) or actor.get("emotion") not in spec.get("emotions", []):
			return "Actor pose/emotion is not registered."
		var allowed_micro: Array = common_micro.duplicate()
		for micro in spec.get("signatureMicros", []):
			allowed_micro.append(micro.get("id"))
		if actor.get("micro") not in allowed_micro:
			return "Actor micro is not registered."
		used_ids[actor_id] = true
		used_slots[slot] = true
	return ""


static func _validate_route(route: Variant, id: String, scenes: Dictionary,
		project: Dictionary) -> String:
	if not route is Dictionary:
		return "Route proposal must be an object."
	for key in route:
		if key not in ROUTE_KEYS:
			return "Unexpected route proposal field."
	var kind: Variant = route.get("kind")
	var ref: Variant = route.get("ref")
	var interaction: Variant = route.get("interactionTarget")
	if not interaction is String or interaction.strip_edges().is_empty() or interaction.length() > 120:
		return "An explicit interaction target is required."
	if not kind is String or not ref is String:
		return "Route kind and reference must be strings."
	if kind == "scene_complete":
		if ref == id or not scenes.has(ref):
			return "Dependency must refer to a different existing or proposed scene."
	elif kind == "first_clear":
		var existing: Dictionary = {}
		for route_in in project.get("routes", {}).values():
			if route_in.get("gate", {}).get("kind") == "first_clear":
				existing[str(route_in["gate"].get("ref", ""))] = true
		if not existing.has(ref):
			return "Only canonical known Match-3 level refs supported."
	else:
		return "Route kind not supported by review contract."
	return ""


static func _validate_cue(cue: Variant, line: Dictionary, actors: Dictionary) -> String:
	if not cue is Dictionary:
		return "Cue must be an object."
	for key in cue:
		if key not in CUE_KEYS:
			return "Unexpected cue field: " + str(key)
	if not cue.get("portraitVisible") is bool:
		return "portraitVisible must be boolean."
	var actor: String = str(line.get("speakerId", ""))
	if not actors.has(actor):
		return "Speaker is not a registered actor."
	var spec: Dictionary = actors[actor]
	if cue.get("poseId") not in spec.get("poses", []) or cue.get("emotionId") not in spec.get("emotions", []):
		return "Cue pose or emotion not in speaker registry."
	var micro: Variant = cue.get("microOnEnter")
	if micro != null:
		var micros: Array = []
		for item in spec.get("signatureMicros", []):
			micros.append(item.get("id"))
		if micro not in micros:
			return "Cue micro not in speaker registry."
	return ""
