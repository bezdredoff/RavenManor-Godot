@tool
extends RefCounted
## VNS5-06B: immutable draft-only Raven scene/line additions.
## Stable reserved IDs deliberately cannot masquerade as promoted runtime scenes.
const MAX_NEW_SCENES := 32
const MAX_NEW_LINES := 320
const SCENE_KEYS := ["sceneId", "title", "status"]
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
		initial_line_ru: String, speaker_id: String) -> Dictionary:
	var scene_id: String = next_scene_id(project, draft)
	if scene_id.is_empty() or draft.get("authoredScenes", []).size() >= MAX_NEW_SCENES:
		return {"ok": false, "error": "Scene draft limit reached."}
	if title_ru.strip_edges().is_empty() or title_ru.length() > 120:
		return {"ok": false, "error": "Scene title in RU must contain 1–120 characters."}
	if initial_line_ru.strip_edges().is_empty() or initial_line_ru.length() > 6000:
		return {"ok": false, "error": "First dialogue line requires RU text (max 6000 characters)."}
	if not actor_ids(project).has(speaker_id):
		return {"ok": false, "error": "Speaker is not in the approved character registry."}
	var candidate: Dictionary = draft.duplicate(true)
	if not candidate.has("authoredScenes"):
		candidate["authoredScenes"] = []
	if not candidate.has("authoredLines"):
		candidate["authoredLines"] = []
	candidate["authoredScenes"].append({"sceneId": scene_id,
		"title": {"ru": title_ru.strip_edges(), "be": null, "en": null},
		"status": "draft_not_runtime"})
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
	if not actor_ids(project).has(speaker_id):
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


static func _line(id: String, scene_id: String, text_ru: String, speaker_id: String) -> Dictionary:
	return {"id": id, "sceneId": scene_id, "speakerId": speaker_id,
		"delivery": "speech", "source": "vn_studio_draft_not_runtime",
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
		if line.get("speakerId") not in actor_ids(project):
			return "Authored line speaker is not in the character registry."
		if line.get("delivery") != "speech" or line.get("source") != "vn_studio_draft_not_runtime":
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
