@tool
extends RefCounted
## VN-EDITOR-05: deterministic, immutable graph description from legacy UPDS data.
## Source of truth stays in StorySession/save_contract; this is NOT a simulator.

static func build(project: Dictionary) -> Dictionary:
	var scenes: Array = project.get("scenes", [])
	var contract: Dictionary = project.get("contract", {})
	var scene_ids: Array = contract.get("storySceneIds", [])
	var level_ids: Array = contract.get("levelIds", [])
	var gate_ids: Array = contract.get("storyChoiceGateIds", [])
	var nodes: Dictionary = {}
	var edges: Array[Dictionary] = []
	var warnings: Array[String] = []
	var unique_edges: Dictionary = {}
	var endings: Dictionary = {}
	for entry in scenes:
		if not entry is Dictionary:
			continue
		var id: String = str(entry.get("id", ""))
		var index: int = int(entry.get("index", -1))
		if id.is_empty() or nodes.has("scene:" + id):
			warnings.append("Повтор или пустой ID сцены: " + id)
			continue
		if index < 0 or index >= scene_ids.size() or scene_ids[index] != id:
			warnings.append("Несовпадение порядка save_contract: " + id)
		var data: Dictionary = entry.get("data", {})
		if str(data.get("sceneId", "")) != id:
			warnings.append("sceneId файла и контракта различаются: " + id)
		var titles: Dictionary = data.get("titles", {})
		nodes["scene:" + id] = _node("scene:" + id, "scene", id, index, {
			"file": entry.get("file", ""), "titles": titles,
			"lines": data.get("lines", []).size() if data.get("lines", []) is Array else 0,
			"variants": data.get("variants", {}).keys() if data.get("variants", {}) is Dictionary else []
		})
	# Add all known story destinations first, so edges can be checked without guessing.
	for entry in scenes:
		if not entry is Dictionary:
			continue
		var id: String = str(entry.get("id", ""))
		var index: int = int(entry.get("index", -1))
		var data: Dictionary = entry.get("data", {})
		var source: String = "scene:" + id
		if not nodes.has(source):
			continue
		var flow: String = source
		var gate: Dictionary = data.get("choiceGate", {})
		if not gate.is_empty():
			var gate_id: String = str(gate.get("id", ""))
			var gate_key: String = "choice:" + id + ":" + gate_id
			var checkpoint: String = str(gate.get("checkpointLineId", ""))
			var found: bool = false
			for line in data.get("lines", []):
				if line is Dictionary and str(line.get("id", "")) == checkpoint:
					found = true
					break
			if not found:
				warnings.append("%s: checkpointLineId отсутствует: %s" % [id, checkpoint])
			if gate_id not in gate_ids:
				warnings.append("%s: не зарегистрирован choiceGate %s" % [id, gate_id])
			var choices: Dictionary = gate.get("choices", {})
			nodes[gate_key] = _node(gate_key, "choice", gate_id, index, {
				"sourceScene": id, "checkpointLineId": checkpoint,
				"prompt": gate.get("prompt", {}), "choices": choices,
				"branchChoiceId": data.get("branchChoiceId", "")
			})
			_add_edge(edges, unique_edges, source, gate_key, "контрольная реплика", "choice", nodes, warnings)
			flow = gate_key
		var variants: Dictionary = data.get("variants", {})
		if not variants.is_empty():
			var choice_titles: Dictionary = data.get("choices", {})
			for variant in variants.keys():
				var tag: String = str(variant)
				var key: String = "variant:" + id + ":" + tag
				var lines: Array = variants[variant] if variants[variant] is Array else []
				nodes[key] = _node(key, "variant", "Вариант " + tag, index, {
					"sourceScene": id, "variant": tag, "lineCount": lines.size(),
					"choicePrompt": data.get("choicePrompt", {}),
					"choice": choice_titles.get(tag, {})
				})
				_add_edge(edges, unique_edges, source, key, tag, "variant", nodes, warnings)
			# All variants rejoin the source's following transition, without inventing separate destinations.
		var targets: Dictionary = data.get("nextSceneIndices", {})
		if not targets.is_empty():
			for tag in targets:
				var target: String = _scene_at(scenes, int(targets[tag]))
				if target.is_empty():
					warnings.append("%s: неизвестный путь %s → %s" % [id, str(tag), str(targets[tag])])
				else:
					_add_edge(edges, unique_edges, flow, "scene:" + target, str(tag), "route", nodes, warnings)
			if str(data.get("branchChoiceId", "")) != str(gate.get("id", "")):
				warnings.append("%s: branchChoiceId не совпадает с choiceGate" % id)
			continue
		var destination: String = ""
		var outcome_kind: String = ""
		if str(data.get("nextLevelId", "")) != "":
			var level: String = str(data["nextLevelId"])
			if level not in level_ids:
				warnings.append("%s: Match-3 ID отсутствует в контракте: %s" % [id, level])
			var match_key: String = "m3:" + level
			if not nodes.has(match_key):
				nodes[match_key] = _node(match_key, "match3", level, index, {"levelId": level})
			destination = match_key
			outcome_kind = "match3"
			var return_index: int = int(data.get("onWinSceneIndex", -1))
			var resumed: String = _scene_at(scenes, return_index)
			if resumed.is_empty():
				warnings.append("%s: Match-3 без корректного onWinSceneIndex" % id)
			else:
				_add_edge(edges, unique_edges, match_key, "scene:" + resumed, "победа", "win", nodes, warnings)
		elif data.get("nextSceneIndex", -1) is int and int(data["nextSceneIndex"]) >= 0:
			var next_index: int = int(data["nextSceneIndex"])
			var next_id: String = _scene_at(scenes, next_index)
			if next_id.is_empty():
				warnings.append("%s: nextSceneIndex вне списка: %d" % [id, next_index])
			else:
				if str(data.get("nextSceneId", "")) != "" and str(data["nextSceneId"]) != next_id:
					warnings.append("%s: nextSceneId и nextSceneIndex различаются" % id)
				destination = "scene:" + next_id
				outcome_kind = "scene"
		elif str(data.get("nextSceneId", "")) != "":
			destination = "scene:" + str(data["nextSceneId"])
			outcome_kind = "scene"
		var ending: Dictionary = data.get("ending", {})
		if not ending.is_empty():
			var ending_id: String = str(ending.get("endingId", ""))
			var ending_key: String = "ending:" + ending_id
			if ending_id.is_empty():
				warnings.append("%s: пустой endingId" % id)
			else:
				if not nodes.has(ending_key):
					nodes[ending_key] = _node(ending_key, "ending", ending_id, index, {
						"endingId": ending_id, "successRequirement": ending.get("successRequirement", {})
					})
				_add_edge(edges, unique_edges, flow, ending_key, "финал", "ending", nodes, warnings)
				endings[ending_id] = ending_key
				if ending.has("fallbackEndingId"):
					var fallback: String = str(ending["fallbackEndingId"])
					var fallback_key: String = "ending:" + fallback
					if not nodes.has(fallback_key):
						nodes[fallback_key] = _node(fallback_key, "ending", fallback, index, {"endingId": fallback})
					_add_edge(edges, unique_edges, ending_key, fallback_key, "условие не выполнено", "fallback", nodes, warnings)
		elif not destination.is_empty():
			if variants.is_empty():
				_add_edge(edges, unique_edges, flow, destination, "далее", outcome_kind, nodes, warnings)
			else:
				for tag in variants:
					_add_edge(edges, unique_edges, "variant:" + id + ":" + str(tag), destination, "далее", outcome_kind, nodes, warnings)
		else:
			warnings.append("%s: не указан переход, Match-3 или финал" % id)
	var seen_ids: Dictionary = {}
	for id in scene_ids:
		if seen_ids.has(id):
			warnings.append("Дублируется ID в save_contract: " + str(id))
		seen_ids[id] = true
	for id in scene_ids:
		if not nodes.has("scene:" + str(id)):
			warnings.append("Нет сцены по save_contract: " + str(id))
	return {"nodes": nodes, "edges": edges, "warnings": warnings,
		"stats": {"scenes": scenes.size(), "sceneNodes": _count_kind(nodes, "scene"),
			"match3": _count_kind(nodes, "match3"), "choiceGates": _count_kind(nodes, "choice"),
			"variants": _count_kind(nodes, "variant"), "endings": _count_kind(nodes, "ending"),
			"links": edges.size()}}


static func neighborhood(graph: Dictionary, focus: String, steps: int = 2) -> Dictionary:
	var nodes: Dictionary = graph.get("nodes", {})
	if not nodes.has(focus):
		return graph
	var edges: Array = graph.get("edges", [])
	var selected: Dictionary = {focus: true}
	for _depth in range(maxi(steps, 0)):
		var added: Dictionary = selected.duplicate()
		for e in edges:
			if selected.has(e["from"]):
				added[e["to"]] = true
			if selected.has(e["to"]):
				added[e["from"]] = true
		selected = added
	var subset: Dictionary = {}
	var connections: Array[Dictionary] = []
	for id in nodes:
		if selected.has(id):
			subset[id] = nodes[id]
	for e in edges:
		if selected.has(e["from"]) and selected.has(e["to"]):
			connections.append(e)
	return {"nodes": subset, "edges": connections, "warnings": graph.get("warnings", []),
		"stats": graph.get("stats", {})}


static func _count_kind(nodes: Dictionary, kind: String) -> int:
	var count: int = 0
	for node in nodes.values():
		if node.get("kind") == kind:
			count += 1
	return count


static func _node(key: String, kind: String, label: String, idx: int, metadata: Dictionary) -> Dictionary:
	return {"id": key, "kind": kind, "label": label, "index": idx, "metadata": metadata}


static func _scene_at(scenes: Array, idx: int) -> String:
	if idx < 0 or idx >= scenes.size():
		return ""
	return str(scenes[idx].get("id", ""))


static func _add_edge(edges: Array[Dictionary], unique: Dictionary, from_id: String, to_id: String, label: String, kind: String, nodes: Dictionary, warnings: Array[String]) -> void:
	if not nodes.has(from_id) or not nodes.has(to_id):
		warnings.append("Ссылка на отсутствующий узел: %s → %s" % [from_id, to_id])
		return
	var key: String = JSON.stringify([from_id, to_id, label, kind])
	if unique.has(key):
		return
	unique[key] = true
	edges.append({"from": from_id, "to": to_id, "label": label, "kind": kind})
