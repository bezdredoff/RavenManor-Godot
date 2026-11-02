@tool
extends RefCounted
## VNS5-06A: typed review-only Raven scene routes. No gameplay or canonical writes.
const FORMAT := "raven-vn-story-edges-v1"
const KINDS := ["scene", "choice", "match3"]
const KEYS := ["format", "schemaVersion", "sceneId", "edges"]
const EDGE_KEYS := ["id", "kind", "targetId", "label", "lineId", "choiceKey"]
const MAX_EDGES := 20


static func fresh(scene_id: String) -> Dictionary:
	return {"format": FORMAT, "schemaVersion": 1, "sceneId": scene_id, "edges": []}


static func effective(draft: Dictionary, scene_id: String) -> Dictionary:
	var saved: Variant = draft.get("storyGraphPatches", {}).get(scene_id, {})
	return saved.duplicate(true) if saved is Dictionary and not saved.is_empty() else fresh(scene_id)


static func level_ids(project: Dictionary) -> Array:
	var ids: Array = []
	for trigger in project.get("routes", {}).values():
		if not trigger is Dictionary:
			continue
		var gate: Dictionary = trigger.get("gate", {})
		if gate.get("kind") == "first_clear":
			var id: String = str(gate.get("ref", ""))
			if not id.is_empty() and not ids.has(id):
				ids.append(id)
	ids.sort()
	return ids


static func scene_ids(project: Dictionary) -> Array:
	var ids: Array = []
	for scene in project.get("scenes", []):
		ids.append(str(scene.get("sceneId", "")))
	return ids


static func validate(project: Dictionary, overlay: Variant) -> String:
	if not overlay is Dictionary:
		return "Story Map overlay must be a JSON object."
	for key in overlay.keys():
		if key not in KEYS:
			return "Unexpected Story Map field: " + str(key)
	var scene_id: Variant = overlay.get("sceneId", "")
	if overlay.get("format") != FORMAT or overlay.get("schemaVersion") != 1 or not scene_id is String or not scene_ids(project).has(scene_id):
		return "Invalid Story Map version or source scene."
	var edges: Variant = overlay.get("edges")
	if not edges is Array or edges.size() > MAX_EDGES:
		return "Story Map has an invalid or oversized list of edges."
	var line_ids: Dictionary = {}
	for entry in project.get("linesByScene", {}).get(scene_id, []):
		line_ids[str(entry.get("id", ""))] = true
	var allowed_scenes: Array = scene_ids(project)
	var allowed_levels: Array = level_ids(project)
	var seen_ids: Dictionary = {}
	var seen_choices: Dictionary = {}
	var unconditional: int = 0
	for edge in edges:
		if not edge is Dictionary:
			return "Story Map edge must be an object."
		for key in edge.keys():
			if key not in EDGE_KEYS:
				return "Unexpected Story Map edge field: " + str(key)
		var id: Variant = edge.get("id", "")
		var kind: Variant = edge.get("kind", "")
		var target: Variant = edge.get("targetId", "")
		var label: Variant = edge.get("label", "")
		if not id is String or not id.begins_with("edge-") or id.length() != 9:
			return "Invalid Story Map edge ID."
		for index in range(5, 9):
			if not "0123456789".contains(id.substr(index, 1)):
				return "Story Map edge ID must be numeric."
		if seen_ids.has(id):
			return "Duplicate Story Map edge ID."
		seen_ids[id] = true
		if not kind is String or kind not in KINDS or not target is String:
			return "Unsupported Story Map edge kind or target."
		if not label is String or label.strip_edges().is_empty() or label.length() > 80:
			return "Story Map label is missing or longer than 80 characters."
		if kind == "scene":
			if target not in allowed_scenes or edge.has("lineId") or edge.has("choiceKey"):
				return "Invalid unconditional scene target or extra choice properties."
			unconditional += 1
		elif kind == "match3":
			if target not in allowed_levels or edge.has("lineId") or edge.has("choiceKey"):
				return "Match-3 target must be an existing canonical level."
			unconditional += 1
		else:
			if target not in allowed_scenes:
				return "Choice target must be an existing scene."
			if not edge.get("lineId") is String or not line_ids.has(edge["lineId"]):
				return "Choice checkpoint must belong to the source scene."
			if not edge.get("choiceKey") is String or edge["choiceKey"] not in ["A", "B", "C"]:
				return "Choice key must be A, B, or C."
			var key: String = str(edge["lineId"]) + ":" + str(edge["choiceKey"])
			if seen_choices.has(key):
				return "Duplicate choice branch for the same checkpoint and key."
			seen_choices[key] = true
	if unconditional > 1:
		return "Cannot create multiple unconditional outgoing routes."
	return ""


static func next_edge(data: Dictionary, kind: String, target_id: String, label: String,
		line_id: String = "", choice_key: String = "") -> Dictionary:
	var result: Dictionary = data.duplicate(true)
	var existing: Dictionary = {}
	for edge in result.get("edges", []):
		existing[str(edge.get("id", ""))] = true
	var index: int = 1
	while existing.has("edge-%04d" % index):
		index += 1
	var edge: Dictionary = {"id": "edge-%04d" % index, "kind": kind,
		"targetId": target_id, "label": label}
	if kind == "choice":
		edge["lineId"] = line_id
		edge["choiceKey"] = choice_key
	result["edges"].append(edge)
	return result


## Real canonical trigger graph, NOT inferred scene-order transitions.
## Draft connections are separate 'draft' kind and cannot be interpreted as runtime.
static func build(project: Dictionary, draft: Dictionary) -> Dictionary:
	var nodes: Dictionary = {}
	var connections: Array[Dictionary] = []
	var scenes: Array = scene_ids(project)
	for i in range(scenes.size()):
		var scene_id: String = str(scenes[i])
		nodes[scene_id] = {"id": scene_id, "kind": "scene", "ordinal": i}
	for scene_id in scenes:
		var route: Dictionary = project.get("routes", {}).get(scene_id, {})
		var gate: Dictionary = route.get("gate", {})
		var gate_kind: String = str(gate.get("kind", "unclassified"))
		var ref: String = str(gate.get("ref", ""))
		if gate_kind == "scene_complete" and nodes.has(ref):
			connections.append({"from": ref, "to": scene_id, "kind": "canonical",
				"label": "requires scene_complete"})
		else:
			var gate_id: String = "gate:" + scene_id
			nodes[gate_id] = {"id": gate_id, "kind": "gate", "ordinal": scenes.find(scene_id),
				"title": gate_kind + " · " + ref}
			connections.append({"from": gate_id, "to": scene_id,
				"kind": "canonical", "label": "requires " + gate_kind})
		var overlay: Dictionary = effective(draft, scene_id)
		for edge in overlay.get("edges", []):
			var target: String = str(edge.get("targetId", ""))
			if str(edge.get("kind")) == "match3":
				var target_node: String = "m3:" + target
				if not nodes.has(target_node):
					nodes[target_node] = {"id": target_node, "kind": "match3",
						"ordinal": scenes.find(scene_id), "title": target}
				target = target_node
			if nodes.has(target):
				connections.append({"from": scene_id, "to": target,
					"kind": "draft", "edgeId": str(edge.get("id", "")),
					"sourceSceneId": scene_id,
					"label": str(edge.get("kind")) + ": " + str(edge.get("label"))})
	return {"nodes": nodes, "edges": connections}


static func neighborhood(graph: Dictionary, focus_id: String) -> Dictionary:
	var visible: Dictionary = {focus_id: true}
	var edges: Array = graph.get("edges", [])
	for step in range(2):
		var plus: Dictionary = visible.duplicate()
		for edge in edges:
			if visible.has(edge["from"]):
				plus[edge["to"]] = true
			if visible.has(edge["to"]):
				plus[edge["from"]] = true
		visible = plus
	var nodes: Dictionary = {}
	var subset: Array[Dictionary] = []
	for id in visible:
		if graph.get("nodes", {}).has(id):
			nodes[id] = graph["nodes"][id]
	for edge in edges:
		if nodes.has(edge["from"]) and nodes.has(edge["to"]):
			subset.append(edge)
	return {"nodes": nodes, "edges": subset}


## Projection-only hit testing. These metadata keys are never written to draft JSON.
## Parallel A/B/C lines share one GraphEdit visual cable: the UI must present
## every distinct, stable edge ID rather than guessing which branch was clicked.
static func draft_ids_for_connection(edges: Array, from_id: String,
		to_id: String, active_source: String) -> Array[String]:
	var matches: Array[String] = []
	if from_id != active_source:
		return matches
	for edge in edges:
		if not edge is Dictionary or edge.get("kind") != "draft":
			continue
		if edge.get("from", "") != from_id or edge.get("to", "") != to_id:
			continue
		if edge.get("sourceSceneId", "") != active_source:
			continue
		var edge_id: String = str(edge.get("edgeId", ""))
		if not edge_id.is_empty() and not matches.has(edge_id):
			matches.append(edge_id)
	return matches
