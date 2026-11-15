extends SceneTree
## MAP-QA-08A: story-aware navigation requirements without guessed pixels.
## Read-only assertions; does not generate or promote navigation.
const Routes = preload("res://addons/room_builder_routes/route_document.gd")
const TARGETS := "res://assets/raven/map/qa/drafts/map_qa_08_story_targets.v1.json"
const STORY := "res://data/raven/production/map_narrative_routes.json"
const MANIFEST := "res://assets/raven/map/first_floor_manifest.v1.json"
const ORIGINAL := "res://assets/raven/map/qa/drafts/hall_routes_draft.v1.json"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var original_bytes := FileAccess.get_file_as_string(ORIGINAL)
	var hall_bytes := FileAccess.get_file_as_string(Routes.HALL_SOURCE)
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(TARGETS))
	var story: Variant = JSON.parse_string(FileAccess.get_file_as_string(STORY))
	var manifest: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	assert(raw is Dictionary and story is Dictionary and manifest is Dictionary)
	var data: Dictionary = raw
	assert(data["kind"] == "raven-map-qa-08-story-navigation-targets")
	assert(data["approval"] == "DRAFT_ONLY" and data["productionReady"] == false)
	assert(data["runtimeAuthority"] == false and data["coordinateSpace"] == "image-pixel")
	assert(data["sourceImage"]["sha256"] == Routes.IMAGE_SHA256)
	assert(data["sourceImage"]["gitBlobSha"] == Routes.IMAGE_BLOB_SHA)
	assert(data["sourceImage"]["path"] == Routes.IMAGE_PATH)
	assert(data["sourceImage"]["sizePx"] == [1672, 941])
	assert(data["legacyDraft"] == ORIGINAL)
	var original: Dictionary = Routes.load_draft(ORIGINAL)
	assert(original.get("ok", false), str(original.get("error", "")))
	assert(original["document"]["approval"] == "DRAFT_ONLY")

	var real_story_ids := {}
	for item in story["sceneTriggers"]:
		real_story_ids[str(item["sceneId"])] = true
	var room_ids := {}
	for room in manifest["rooms"]:
		room_ids[str(room["id"])] = true
	room_ids["RM-ROOM-BACK-GARDEN"] = true # Excluded external scene, no pixel route
	var seen_poi := {}
	var assigned_hotspots := {}
	for item in data["targetPoints"]:
		assert(item is Dictionary)
		var target: Dictionary = item
		var id := str(target.get("id", ""))
		assert(id.begins_with("QA-POI-") and not seen_poi.has(id))
		seen_poi[id] = true
		assert(room_ids.has(str(target.get("roomId", ""))))
		assert(target.has("pointPx") and target["pointPx"] == null,
			"Do not invent image-pixel POI coordinates without visual inspection")
		assert(target.get("approval") == "DRAFT_ONLY")
		assert(not str(target.get("visualCue", "")).is_empty())
		assert(target.get("relatedStoryIds", null) is Array)
		assert(target.get("relatedHotspotIds", null) is Array)
		for beat in target["relatedStoryIds"]:
			assert(real_story_ids.has(str(beat)), "Unknown narrative scene: " + str(beat))
		for hotspot in target["relatedHotspotIds"]:
			assert(str(hotspot).begins_with("RM-HS-"))
			assigned_hotspots[str(hotspot)] = int(assigned_hotspots.get(str(hotspot), 0)) + 1
		if bool(target["routeRequired"]):
			assert(Routes.ROOM_IDS.has(target["roomId"]),
				"Only five currently playable room islands can require routes")
			assert(target["status"] == "NOT_CALIBRATED")
		else:
			assert(target["status"] == "OUT_OF_SCOPE")
	for id in ["RM-HS-001", "RM-HS-002", "RM-HS-003", "RM-HS-004", "RM-HS-005"]:
		assert(int(assigned_hotspots.get(id, 0)) == 1,
			"Every first-slice hotspot must have exactly one planned POI: " + id)

	var expected_doors := {}
	for door in manifest["doors"]:
		expected_doors[str(door["id"])] = true
	var doors_seen := {}
	for candidate in data["doorCalibration"]:
		assert(candidate is Dictionary)
		var id := str(candidate.get("doorId", ""))
		assert(expected_doors.has(id) and not doors_seen.has(id))
		doors_seen[id] = true
		assert(candidate["status"] == "UNRESOLVED")
		assert(candidate["nearSidePointPx"] == null and candidate["farSidePointPx"] == null)
		assert(candidate["authority"] == "DRAFT_ONLY_NO_REAL_TRANSITION")
	assert(doors_seen.size() == expected_doors.size())
	assert(FileAccess.get_file_as_string(ORIGINAL) == original_bytes)
	assert(FileAccess.get_file_as_string(Routes.HALL_SOURCE) == hall_bytes)
	print("MAP-QA-08A narrative POI targets and unresolved-geometry contract passed")
	quit(0)
