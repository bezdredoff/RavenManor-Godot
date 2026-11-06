@tool
extends RefCounted
## VNS5-06B: immutable draft-only Raven scene/line additions.
## Stable reserved IDs deliberately cannot masquerade as promoted runtime scenes.
const NARRATOR_ID := "RM-NARRATOR" # Review-only speaker; no portrait or canonical actor
const MAX_NEW_SCENES := 32
const MAX_NEW_LINES := 320
const SCENE_KEYS := ["sceneId", "title", "status", "chapter"]
const LINE_KEYS := ["id", "sceneId", "speakerId", "delivery", "localized", "source"]
const LOCALES := ["ru", "be", "en"]


static func scenes(project: Dictionary, draft: Dictionary) -> Array:
	var result: Array = project.get("scenes", []).duplicate(true)
	result.append_array(draft.get("authoredScenes", []).duplicate(true))
	return result


static func lines(project: Dictionary, draft: Dictionary, scene_id: String) -> Array:
	var result: Array = project.get("linesByScene", {}).get(scene_id, []).duplicate(true)
	for entry in draft.get("authoredLines", []):
		if entry is Dictionary and entry.get("sceneId", "") == scene_id:
			result.append(entry.duplicate(true))
	return result


static func is_authored_scene(draft: Dictionary, scene_id: String) -> bool:
	for scene in draft.get("authoredScenes", []):
		if scene is Dictionary and scene.get("sceneId", "") == scene_id:
			return true
	return false


static func actor_ids(project: Dictionary) -> Array:
	var ids: Array = []
	for entry in project.get("castData", {}).get("characters", []):
		if entry is Dictionary:
			ids.append(str(entry.get("id", "")))
	return ids


static func preview_project(project: Dictionary, draft: Dictionary) -> Dictionary:
	# Copy the source catalog, never mutate it. Gate nodes are marked draft,
	# not approved runtime or playable transitions.
	var preview: Dictionary = project.duplicate(true)
	preview["scenes"] = scenes(project, draft)
	for scene in draft.get("authoredScenes", []):
		var id: String = str(scene["sceneId"])
		preview["linesByScene"][id] = []
		preview["routes"][id] = {"sceneId": id,
			"gate": {"kind": "draft_unapproved", "ref": "none", "approvedRuntime": false},
			"postSceneAction": "none_not_playable"}
	for entry in draft.get("authoredLines", []):
		var scene_id: String = str(entry["sceneId"])
		if not preview["linesByScene"].has(scene_id):
			preview["linesByScene"][scene_id] = []
		preview["linesByScene"][scene_id].append(entry.duplicate(true))
	return preview


static func next_scene_id(project: Dictionary, draft: Dictionary) -> String:
	var used: Dictionary = {}
	for scene in scenes(project, draft):
		used[str(scene.get("sceneId", ""))] = true
	for index in range(1, 10000):
		var id: String = "RM-DRAFT-BEAT-%04d" % index
		if not used.has(id):
			return id
	return ""


static func next_line_id(project: Dictionary, draft: Dictionary, scene_id: String) -> String:
	var used: Dictionary = {}
	for entry in project.get("data", {}).get("entries", []):
		used[str(entry.get("id", ""))] = true
	for entry in draft.get("authoredLines", []):
		used[str(entry.get("id", ""))] = true
	for index in range(1, 10000):
		var id: String = scene_id + "-L%03d" % index
		if not used.has(id):
			return id
	return ""


static func add_scene(project: Dictionary, draft: Dictionary, title_ru: String,
		initial_line_ru: String, speaker_id: String, chapter: String = "") -> Dictionary:
	var scene_id: String = next_scene_id(project, draft)
	if scene_id.is_empty() or draft.get("authoredScenes", []).size() >= MAX_NEW_SCENES:
		return {"ok": false, "error": "Scene draft limit reached."}
	if title_ru.strip_edges().is_empty() or title_ru.length() > 120:
		return {"ok": false, "error": "Scene title in RU must contain 1–120 characters."}
	if initial_line_ru.strip_edges().is_empty() or initial_line_ru.length() > 6000:
		return {"ok": false, "error": "First dialogue line requires RU text (max 6000 characters)."}
	if not actor_ids(project).has(speaker_id) and speaker_id != NARRATOR_ID:
		return {"ok": false, "error": "Speaker is not in the approved character registry."}
	if not chapter.is_empty() and not _valid_chapter(chapter):
		return {"ok": false, "error": "Draft chapter must use a two-digit group such as 02."}
	var candidate: Dictionary = draft.duplicate(true)
	if not candidate.has("authoredScenes"):
		candidate["authoredScenes"] = []
	if not candidate.has("authoredLines"):
		candidate["authoredLines"] = []
	var authored: Dictionary = {"sceneId": scene_id,
		"title": {"ru": title_ru.strip_edges(), "be": null, "en": null},
		"status": "draft_not_runtime"}
	if not chapter.is_empty():
		authored["chapter"] = chapter
	candidate["authoredScenes"].append(authored)
	var line_id: String = scene_id + "-L001"
	candidate["authoredLines"].append(_line(line_id, scene_id, initial_line_ru, speaker_id))
	var error: String = validate(project, candidate)
	if not error.is_empty():
		return {"ok": false, "error": error}
	return {"ok": true, "draft": candidate, "sceneId": scene_id, "lineId": line_id}


static func add_line(project: Dictionary, draft: Dictionary, scene_id: String,
		text_ru: String, speaker_id: String) -> Dictionary:
	var allowed: Dictionary = {}
	for scene in scenes(project, draft):
		allowed[str(scene.get("sceneId", ""))] = true
	if not allowed.has(scene_id):
		return {"ok": false, "error": "Line source scene does not exist."}
	if text_ru.strip_edges().is_empty() or text_ru.length() > 6000:
		return {"ok": false, "error": "Dialogue requires non-empty RU text (max 6000 characters)."}
	if not actor_ids(project).has(speaker_id) and speaker_id != NARRATOR_ID:
		return {"ok": false, "error": "Speaker is not in the approved character registry."}
	if draft.get("authoredLines", []).size() >= MAX_NEW_LINES:
		return {"ok": false, "error": "Draft line count exceeds limit."}
	var id: String = next_line_id(project, draft, scene_id)
	if id.is_empty():
		return {"ok": false, "error": "No available stable line ID."}
	var candidate: Dictionary = draft.duplicate(true)
	if not candidate.has("authoredLines"):
		candidate["authoredLines"] = []
	candidate["authoredLines"].append(_line(id, scene_id, text_ru, speaker_id))
	var error: String = validate(project, candidate)
	if not error.is_empty():
		return {"ok": false, "error": error}
	return {"ok": true, "draft": candidate, "sceneId": scene_id, "lineId": id}



## Chapter is editorial metadata for draft scene navigation. It does not
## fabricate a canonical route, runtime chapter or RM-BEAT ID.
static func _valid_chapter(chapter: String) -> bool:
	if chapter.length() != 2:
		return false
	for pos in range(2):
		if not "0123456789".contains(chapter.substr(pos, 1)):
			return false
	return true


## Reorder *authored* lines only; canonical authored order is immutable.
## Stable lineIds, cue targets, locale patches and FX anchors are not renamed.
static func move_line(project: Dictionary, draft: Dictionary, scene_id: String,
		line_id: String, direction: int) -> Dictionary:
	if direction != -1 and direction != 1:
		return {"ok": false, "error": "Direction must be -1 or +1."}
	var own: Array = []
	var lines_new: Array = draft.get("authoredLines", [])
	for index in range(lines_new.size()):
		if str(lines_new[index].get("sceneId", "")) == scene_id:
			own.append(index)
	var current: int = -1
	for index in range(own.size()):
		if str(lines_new[own[index]].get("id", "")) == line_id:
			current = index
			break
	if current < 0:
		return {"ok": false, "error": "Only draft-authored lines can be moved."}
	var to_index: int = current + direction
	if to_index < 0 or to_index >= own.size():
		return {"ok": false, "error": "Line is already at the edge of its authored block."}
	var candidate: Dictionary = draft.duplicate(true)
	var left: int = own[current]
	var right: int = own[to_index]
	var saved: Dictionary = candidate["authoredLines"][left]
	candidate["authoredLines"][left] = candidate["authoredLines"][right]
	candidate["authoredLines"][right] = saved
	var error: String = validate(project, candidate)
	if not error.is_empty():
		return {"ok": false, "error": error}
	return {"ok": true, "draft": candidate, "lineId": line_id}


## Keep canonical lines immutable and protect referenced draft checkpoints.
## An authored scene must retain at least one line.
## Stable-ID move across any number of authored lines in one scene.
## One UI Undo point, preserves translations, FX and Story Map checkpoints.
static func move_line_to(project: Dictionary, draft: Dictionary, scene_id: String,
		line_id: String, target_line_id: String) -> Dictionary:
	var own: Array = []
	for item in draft.get("authoredLines", []):
		if item is Dictionary and item.get("sceneId", "") == scene_id:
			own.append(str(item.get("id", "")))
	var from_index: int = own.find(line_id)
	var to_index: int = own.find(target_line_id)
	if from_index < 0 or to_index < 0:
		return {"ok": false, "error": "Перемещать можно только черновые реплики одной сцены."}
	var candidate: Dictionary = draft
	var direction: int = 1 if from_index < to_index else -1
	for _step in range(absi(to_index - from_index)):
		var moved: Dictionary = move_line(project, candidate, scene_id, line_id, direction)
		if not moved.get("ok", false):
			return moved
		candidate = moved["draft"]
	return {"ok": true, "draft": candidate, "lineId": line_id}


static func delete_line(project: Dictionary, draft: Dictionary, scene_id: String,
		line_id: String) -> Dictionary:
	var candidate: Dictionary = draft.duplicate(true)
	var to_delete: int = -1
	var count_in_scene: int = 0
	for index in range(candidate.get("authoredLines", []).size()):
		var line: Dictionary = candidate["authoredLines"][index]
		if str(line.get("sceneId", "")) == scene_id:
			count_in_scene += 1
			if str(line.get("id", "")) == line_id:
				to_delete = index
	if to_delete < 0:
		return {"ok": false, "error": "Canonical or unknown line cannot be deleted."}
	if is_authored_scene(candidate, scene_id) and count_in_scene == 1:
		return {"ok": false, "error": "New scenes need at least one authored line."}
	for patch in candidate.get("storyGraphPatches", {}).values():
		for edge in patch.get("edges", []):
			if str(edge.get("lineId", "")) == line_id:
				return {"ok": false, "error": "Line is referenced by a Story Map choice."}
	for fx in candidate.get("stageFxPatches", {}).values():
		for cue in fx.get("cues", []):
			if str(cue.get("lineId", "")) == line_id:
				return {"ok": false, "error": "Line is referenced by an animation cue."}
	candidate["authoredLines"].remove_at(to_delete)
	candidate.get("patches", {}).erase(line_id)
	var error: String = validate(project, candidate)
	if not error.is_empty():
		return {"ok": false, "error": error}
	return {"ok": true, "draft": candidate, "lineId": line_id}


## Remove a scene created in this draft, and all of its own review-only
## resources. Incoming Story Map links from other scenes must be explicitly
## removed first: silently removing those edges would lose authored choices.
## All source scenes and lines remain immutable.
static func delete_scene(project: Dictionary, draft: Dictionary, scene_id: String) -> Dictionary:
	if not is_authored_scene(draft, scene_id):
		return {"ok": false, "error": "Only a draft-authored scene may be deleted."}
	for source_id in draft.get("storyGraphPatches", {}):
		if str(source_id) == scene_id:
			continue
		var graph: Variant = draft["storyGraphPatches"][source_id]
		if not graph is Dictionary:
			continue
		for edge in graph.get("edges", []):
			if edge is Dictionary and str(edge.get("targetId", "")) == scene_id:
				return {"ok": false, "error": "Scene is referenced by a Story Map edge from " + str(source_id) + ". Remove the incoming edge first."}
	var candidate: Dictionary = draft.duplicate(true)
	for index in range(candidate.get("authoredScenes", []).size() - 1, -1, -1):
		if str(candidate["authoredScenes"][index].get("sceneId", "")) == scene_id:
			candidate["authoredScenes"].remove_at(index)
	for index in range(candidate.get("authoredLines", []).size() - 1, -1, -1):
		var line: Dictionary = candidate["authoredLines"][index]
		if str(line.get("sceneId", "")) == scene_id:
			candidate.get("patches", {}).erase(str(line.get("id", "")))
			candidate["authoredLines"].remove_at(index)
	for key in ["stagePatches", "stageV2Patches", "stageFxPatches", "storyGraphPatches", "promotionSceneIdMap"]:
		candidate.get(key, {}).erase(scene_id)
	var error: String = validate(project, candidate)
	if not error.is_empty():
		return {"ok": false, "error": error}
	return {"ok": true, "draft": candidate, "sceneId": scene_id}


static func _line(id: String, scene_id: String, text_ru: String, speaker_id: String) -> Dictionary:
	return {"id": id, "sceneId": scene_id, "speakerId": speaker_id,
		"delivery": "narration" if speaker_id == NARRATOR_ID else "speech",
		"source": "vn_studio_draft_not_runtime",
		"localized": {"ru": {"text": text_ru.strip_edges()}, "be": null, "en": null}}


static func validate(project: Dictionary, draft: Dictionary) -> String:
	var scenes_new: Variant = draft.get("authoredScenes", [])
	var lines_new: Variant = draft.get("authoredLines", [])
	if not scenes_new is Array or not lines_new is Array:
		return "Authored scene/line collections must be arrays."
	if scenes_new.size() > MAX_NEW_SCENES or lines_new.size() > MAX_NEW_LINES:
		return "Authored scene/line limit exceeded."
	var ids: Dictionary = {}
	for scene in project.get("scenes", []):
		ids[str(scene.get("sceneId", ""))] = "canonical"
	var new_ids: Dictionary = {}
	for scene in scenes_new:
		if not scene is Dictionary:
			return "Authored scene is not an object."
		for key in scene.keys():
			if key not in SCENE_KEYS:
				return "Unexpected scene draft field: " + str(key)
		var id: Variant = scene.get("sceneId")
		if not id is String or not id.begins_with("RM-DRAFT-BEAT-") or id.length() != 18:
			return "Authored scene must use reserved RM-DRAFT-BEAT-0001 IDs."
		for i in range(14, 18):
			if not "0123456789".contains(id.substr(i, 1)):
				return "Authored scene ID has an invalid suffix."
		if ids.has(id):
			return "Duplicate authored scene ID."
		ids[id] = "draft"
		new_ids[id] = true
		var title: Variant = scene.get("title")
		if not title is Dictionary or title.get("ru") is not String or\
				str(title["ru"]).strip_edges().is_empty() or str(title["ru"]).length() > 120:
			return "Authored scene needs a valid RU title."
		for lang in title.keys():
			if lang not in LOCALES or (title[lang] != null and (not title[lang] is String or str(title[lang]).length() > 120)):
				return "Invalid authored scene title translation."
		if scene.has("chapter") and (not scene["chapter"] is String or not _valid_chapter(str(scene["chapter"]))):
			return "Authored scene chapter must be a two-digit draft group."
		if scene.get("status") != "draft_not_runtime":
			return "New scene cannot claim approved runtime status."
	var known_lines: Dictionary = {}
	for line in project.get("data", {}).get("entries", []):
		known_lines[str(line.get("id", ""))] = true
	var per_scene: Dictionary = {}
	for line in lines_new:
		if not line is Dictionary:
			return "Authored line must be an object."
		for key in line.keys():
			if key not in LINE_KEYS:
				return "Unexpected authored line field: " + str(key)
		var scene_id: Variant = line.get("sceneId")
		var id: Variant = line.get("id")
		if not scene_id is String or not ids.has(scene_id) or not id is String or\
				not id.begins_with(scene_id + "-L") or id.length() != scene_id.length() + 5:
			return "Authored line has an invalid source or ID."
		for i in range(scene_id.length() + 2, id.length()):
			if not "0123456789".contains(id.substr(i, 1)):
				return "Authored line ID must have a numeric suffix."
		if known_lines.has(id):
			return "Duplicate line ID."
		known_lines[id] = true
		per_scene[scene_id] = int(per_scene.get(scene_id, 0)) + 1
		var is_narration: bool = line.get("speakerId") == NARRATOR_ID
		if not is_narration and line.get("speakerId") not in actor_ids(project):
			return "Authored line speaker is not in the character registry."
		if line.get("delivery") != ("narration" if is_narration else "speech") or line.get("source") != "vn_studio_draft_not_runtime":
			return "Authored line has an unsupported delivery or claimed production source."
		var localized: Variant = line.get("localized")
		if not localized is Dictionary or not localized.get("ru") is Dictionary or\
				str(localized["ru"].get("text", "")).strip_edges().is_empty():
			return "Authored line requires non-empty RU original."
		for lang in localized:
			if lang not in LOCALES or (localized[lang] != null and (not localized[lang] is Dictionary or\
					not localized[lang].get("text") is String)):
				return "Authored line contains invalid localization."
	for id in new_ids:
		if not per_scene.has(id):
			return "Draft scenes must contain at least one dialogue line."
	return ""


static func export_preview(project: Dictionary, draft: Dictionary) -> Dictionary:
	## An explicit candidate, not an application to the runtime corpus.
	var payload: Dictionary = project["data"].duplicate(true)
	payload["scenes"].append_array(draft.get("authoredScenes", []).duplicate(true))
	payload["entries"].append_array(draft.get("authoredLines", []).duplicate(true))
	for entry in payload["entries"]:
		var patches: Dictionary = draft.get("patches", {}).get(str(entry["id"]), {})
		for lang in patches:
			entry["localized"][lang] = {"text": patches[lang]}
	payload["status"] = "DRAFT_REVIEW_NOT_RUNTIME"
	return payload
