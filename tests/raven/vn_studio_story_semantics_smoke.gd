extends SceneTree
## Synthetic only. Replay checks source-data vs migrated-data semantics, not donor StorySession execution.
const Parity = preload("res://addons/vn_studio/editor/story_semantic_parity.gd")
const Bundle = preload("res://addons/vn_studio/editor/conversion_bundle.gd")


func _initialize() -> void:
	call_deferred("_run")


func _line(id: String, hidden: bool = false) -> Dictionary:
	return {"id": id, "hidden": hidden, "actors": [{"character": "test_actor", "pose": "neutral"}],
		"localized": {"ru": {"speaker": "ИМЯ", "emotion": "нейтрально", "text": "Тест"},
		"en": {"speaker": "NAME", "emotion": "neutral", "text": "Test"},
		"be": {"speaker": "ІМЯ", "emotion": "нейтральна", "text": "Тэст"}}}


func _run() -> void:
	var ids: Array = []
	var entries: Array = []
	var output: Array[Dictionary] = []
	var found_gate: int = 0
	var found_m3: int = 0
	for i in range(45):
		var id: String = "SCENE_%02d" % i
		ids.append(id)
		var scene: Dictionary = {
			"sceneId": id, "sceneIndex": i,
			"lines": [_line("VN%04d" % (100 + i))],
			"nextSceneIndex": i + 1 if i < 44 else -1
		}
		if i == 0:
			scene["lines"] = [_line("VN0001", true), _line("VN0002")]
		if i == 1:
			scene.erase("lines")
			scene.erase("sceneIndex")
			scene["variants"] = {
				"A": [_line("VN0040"), _line("VN0041A"), _line("VN0050")],
				"B": [_line("VN0040"), _line("VN0041B"), _line("VN0050")],
				"C": [_line("VN0040"), _line("VN0041C"), _line("VN0050")]
			}
			scene["nextLevelId"] = "M3_00"
			scene["onWinSceneIndex"] = 2
		if i == 9:
			found_gate += 1
			scene["lines"] = [_line("VN0200", true), _line("VN0201"), _line("VN0202")]
			scene["choiceGate"] = {"id": "meeting-tone", "checkpointLineId": "VN0201",
				"choices": {"A": {}, "B": {}, "C": {}}}
			scene["nextLevelId"] = "M3_01"
			scene["onWinSceneIndex"] = 10
		if i == 38:
			found_gate += 1
			scene["choiceGate"] = {"id": "final-strategy", "checkpointLineId": "VN0138",
				"choices": {"A": {}, "B": {}, "C": {}}}
			scene["branchChoiceId"] = "final-strategy"
			scene["nextSceneIndices"] = {"A": 39, "B": 41, "C": 43}
			scene["nextSceneIndex"] = -1
		if i in [40, 42, 44]:
			scene["ending"] = {"endingId": {"40": "ENDING_B_CASE_CLOSED",
				"42": "ENDING_A_FULL_TRUTH", "44": "ENDING_C_PERFECT_SUSPECT"}[str(i)]}
			if i == 42:
				scene["ending"]["fallbackEndingId"] = "ENDING_B_CASE_CLOSED"
				scene["ending"]["successRequirement"] = {
					"evidence": 7, "teamTrust": 2, "sourceTrust": 2}
		var migrated: Dictionary = scene.duplicate(true)
		if i == 0:
			migrated["lines"][1]["localized"]["ru"]["text"] = "Изменённая реплика"
		var wrapped: Dictionary = {
			"format": Bundle.FORMAT, "schemaVersion": 1,
			"sceneIndex": i, "sceneId": id, "legacyOriginal": scene,
			"payload": migrated
		}
		output.append({"path": "scenes/%02d.json" % i, "json": JSON.stringify(wrapped)})
		entries.append({"index": i, "id": id, "data": scene})
	var rules: Dictionary = {
		"evidenceClueIds": ["CUE_010", "CUE_011", "CUE_012", "CUE_013",
			"CUE_014", "CUE_015", "CUE_016", "CUE_017"],
		"baseTrustByChoice": {"A": {"teamTrust": 0, "sourceTrust": 1},
			"B": {"teamTrust": 0, "sourceTrust": 0},
			"C": {"teamTrust": 1, "sourceTrust": 0}},
		"storyChoiceEffects": {
			"meeting-tone": {
				"A": {"teamTrust": 1}, "B": {"sourceTrust": 1}, "C": {"teamTrust": 1}},
			"final-strategy": {
				"A": {"teamTrust": 1, "sourceTrust": 1},
				"B": {"teamTrust": 1, "sourceTrust": 2},
				"C": {"teamTrust": 1, "sourceTrust": 1}}}
	}
	var contract: Dictionary = {"storySceneIds": ids, "levelIds": ["M3_00", "M3_01"],
		"storyChoiceGateIds": ["meeting-tone", "final-strategy"]}
	var project: Dictionary = {"ok": true, "scenes": entries, "contract": contract, "outcomeRules": rules}
	var plan: Dictionary = {"ok": true, "files": output}
	plan["files"].append({"path": "save_migration_map.json", "json": "{}"})
	plan["files"].append({"path": "conversion_manifest.json", "json": "{}"})
	var source_before: String = JSON.stringify(project)
	var result: Dictionary = Parity.compare(project, plan)
	assert(result.get("ok", false), JSON.stringify(result.get("errors", [])))
	assert(result["scenarioCount"] > 400, JSON.stringify(result))
	assert(result["match3Observations"] > 0)
	assert(result["choiceGateObservations"] > 0)
	assert(result["endingObservations"] > 0)
	assert(result["hiddenResumeObservations"] > 0)
	assert(JSON.stringify(project) == source_before)
	var donor: Dictionary = {}
	var candidate: Dictionary = {}
	for i in range(45):
		donor[i] = entries[i]["data"]
		candidate[i] = JSON.parse_string(output[i]["json"])["payload"]
	var low: Dictionary = {"scene": 42, "line": 1, "choice": "B",
		"storyChoices": {"final-strategy": "B"}, "clues": [], "completed": [], "readLines": []}
	var low_ending: Dictionary = Parity._observe(donor, low, contract, rules)
	assert(low_ending["endingId"] == "ENDING_B_CASE_CLOSED")
	assert(low_ending["endingCopyKey"] == "fallbackCopy")
	var high: Dictionary = {"scene": 42, "line": 1, "choice": "B",
		"storyChoices": {"meeting-tone": "A", "final-strategy": "B"},
		"clues": rules["evidenceClueIds"], "completed": [], "readLines": []}
	var high_ending: Dictionary = Parity._observe(donor, high, contract, rules)
	assert(high_ending["endingId"] == "ENDING_A_FULL_TRUTH")
	# Mutating content is allowed; changing a story route or choice gate must fail closed.
	var altered: Dictionary = JSON.parse_string(output[38]["json"])
	altered["payload"]["nextSceneIndices"]["B"] = 43
	var mutation: Dictionary = plan.duplicate(true)
	mutation["files"][38]["json"] = JSON.stringify(altered)
	assert(not Parity.compare(project, mutation)["ok"])
	var changed_original: Dictionary = plan.duplicate(true)
	var item: Dictionary = JSON.parse_string(output[0]["json"])
	item["legacyOriginal"]["lines"][0]["id"] = "CORRUPT"
	changed_original["files"][0]["json"] = JSON.stringify(item)
	assert(not Parity.compare(project, changed_original)["ok"])
	var wrong_format: Dictionary = plan.duplicate(true)
	wrong_format["files"][0]["json"] = "{}"
	assert(not Parity.compare(project, wrong_format)["ok"])
	var missing_rules: Dictionary = project.duplicate(true)
	missing_rules.erase("outcomeRules")
	assert(not Parity.compare(missing_rules, plan)["ok"])
	print("Raven VN Studio data semantic parity replay smoke passed")
	quit()
