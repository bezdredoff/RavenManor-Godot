@tool
extends RefCounted
## VN-EDITOR-06C: deterministic scenario replay over *two data representations*.
## This is an independent data-semantics check, NOT a run of the UPDS StorySession.
## Does not modify any save, asset, donor content or Raven runtime.
const Bundle = preload("res://addons/vn_studio/editor/conversion_bundle.gd")

const CHOICES := ["A", "B", "C"]
const EVENT_LIMIT := 14000


static func compare(project: Dictionary, plan: Dictionary) -> Dictionary:
	var errors: Array[String] = []
	var warnings: Array[String] = []
	if not bool(project.get("ok", false)) or not bool(plan.get("ok", false)):
		return _fail(["Откройте UPDS-godot и получите успешный dry-run."])
	var sources: Array = project.get("scenes", [])
	var scenes_by_index: Dictionary = {}
	if sources.size() != 45 or plan.get("files", []).size() != 47:
		return _fail(["Ожидались 45 сцен и 47 файлов миграционного пакета."])
	for i in range(45):
		var entry: Dictionary = sources[i]
		if int(entry.get("index", -1)) != i:
			errors.append("Контракт sceneIndex нарушен: %d" % i)
			continue
		scenes_by_index[i] = entry.get("data", {})
	# Never trust an unvalidated raw manifest path; only generated scene position names.
	var candidates: Dictionary = {}
	for file in plan["files"]:
		var relative: String = str(file.get("path", ""))
		if not relative.begins_with("scenes/"):
			continue
		var parsed: Variant = JSON.parse_string(str(file.get("json", "")))
		if not parsed is Dictionary or parsed.get("format", "") != Bundle.FORMAT:
			errors.append("Неверный формат сцены: " + relative)
			continue
		var idx: Variant = parsed.get("sceneIndex", -1)
		if not idx is int and not idx is float:
			errors.append("Неверный индекс в bundle: " + relative)
			continue
		var index: int = int(idx)
		if index < 0 or index >= sources.size() or candidates.has(index) or relative != "scenes/%02d.json" % index:
			errors.append("Неверное имя, диапазон или повтор: " + relative)
			continue
		if parsed.get("sceneId", "") != sources[index].get("id", ""):
			errors.append("ID исходника не совпадает с bundle: " + relative)
		var original: Dictionary = sources[index].get("data", {})
		if parsed.get("legacyOriginal", {}) != original:
			errors.append("В bundle изменён immutable legacyOriginal: " + relative)
		var candidate: Dictionary = parsed.get("payload", {})
		var changed: Array[String] = Bundle._change_paths(original, candidate)
		for path in changed:
			if not Bundle._allowed_change(path):
				errors.append("Недопустимое структурное изменение: %d %s" % [index, path])
		candidates[index] = candidate
	if candidates.size() != sources.size():
		errors.append("Неполное число мигрированных сцен: %d" % candidates.size())
	if not errors.is_empty():
		return _fail(errors)
	var outcome: Dictionary = project.get("outcomeRules", {})
	if outcome.is_empty():
		var root: String = str(project.get("root", ""))
		var outcome_path: String = root.path_join("data/ending_outcomes.json")
		if not FileAccess.file_exists(outcome_path):
			return _fail(["Отсутствует ending_outcomes.json; нельзя проверить метрики и fallback."])
		var source: Variant = JSON.parse_string(FileAccess.get_file_as_string(outcome_path))
		if not source is Dictionary or not source.get("outcomeRules") is Dictionary:
			return _fail(["ending_outcomes.json повреждён или не содержит outcomeRules."])
		outcome = source["outcomeRules"]
	if not _valid_outcome(outcome):
		return _fail(["Отсутствует полный проверяемый набор outcomeRules."])
	# Recompute immediately before checking the trace; stale donor or draft is a hard blocker.
	# Synthetic project fixtures may supply a prevalidated explicit in-memory plan.
	var path_root: String = str(project.get("root", ""))
	if not path_root.is_empty():
		var fresh: Dictionary = Bundle.prepare(project)
		if not fresh.get("ok", false) or fresh.get("bundleId") != plan.get("bundleId"):
			return _fail(["Данные UPDS/черновики изменились после dry-run. Повторите анализ."])
	var donor_scenes: Dictionary = scenes_by_index
	var trace_count: int = 0
	var skipped: int = 0
	var choice_count: int = 0
	var match3_count: int = 0
	var ending_count: int = 0
	var contract: Dictionary = project["contract"]
	# Sample every position (including hidden), all branch choices and each gate resolved
	# or unresolved; for endings compare both below and above evidence/trust thresholds.
	for scene_index in range(sources.size()):
		var donor: Dictionary = donor_scenes[scene_index]
		for option in CHOICES:
			var donor_lines: Array = _lines(donor, scene_index, option)
			if donor_lines.is_empty():
				errors.append("Нет реплик у сцены %d / %s" % [scene_index, option])
				continue
			for line_index in range(donor_lines.size() + (1 if not donor.get("ending", {}).is_empty() else 0)):
				for variant in [0, 1, 2]:
					var snapshot: Dictionary = _snapshot(scene_index, line_index, option, variant, donor, contract, outcome)
					var reference: Dictionary = _observe(donor_scenes, snapshot, contract, outcome)
					var migrated: Dictionary = _observe(candidates, snapshot, contract, outcome)
					if reference != migrated:
						errors.append("Расходится наблюдаемое поведение: scene=%d line=%d choice=%s mode=%d" % [
							scene_index, line_index, option, variant])
					trace_count += 1
					if trace_count > EVENT_LIMIT:
						return _fail(["Превышено ограничение replay сценариев."])
					if reference.get("hiddenSkipped", false):
						skipped += 1
					if reference.get("gate", false):
						choice_count += 1
					if reference.get("match3", false):
						match3_count += 1
					if reference.get("endingId", "") != "":
						ending_count += 1
	# Each branch and static target is checked again outside any snapshot.
	for idx in range(45):
		var source: Dictionary = donor_scenes[idx]
		var migrated: Dictionary = candidates[idx]
		for key in ["sceneId", "sceneIndex", "nextSceneId", "nextSceneIndex", "nextSceneIndices",
				"nextLevelId", "onWinSceneIndex", "choiceGate", "branchChoiceId", "ending",
				"choices", "choicePrompt"]:
			if source.get(key) != migrated.get(key):
				errors.append("Изменился сюжетный параметр %d/%s" % [idx, key])
	if not errors.is_empty():
		return _fail(errors.slice(0, 40), warnings, trace_count)
	return {
		"ok": true, "status": "DATA_SEMANTICS_PARITY_NOT_RUNTIME_ORACLE",
		"scenarioCount": trace_count, "choiceGateObservations": choice_count,
		"match3Observations": match3_count, "endingObservations": ending_count,
		"hiddenResumeObservations": skipped, "warnings": [
			"Выполнен replay по контракту StorySession, а не сам донорский Godot StorySession.",
			"Результаты выдачи улик после Match-3 зависят от внешней CampaignData и здесь не эмулируются.",
			"Совпадение данных не подтверждает UI, анимации и реальную загрузку сейвов."
		]
	}


static func _snapshot(scene_index: int, line_index: int, option: String, variant: int, data: Dictionary, contract: Dictionary, rules: Dictionary) -> Dictionary:
	var clues: Array = []
	if variant == 2:
		clues = rules.get("evidenceClueIds", []).duplicate(true)
	var story_choices: Dictionary = {}
	if variant != 0:
		for gate_id in contract.get("storyChoiceGateIds", []):
			story_choices[str(gate_id)] = option
	# Zero metrics/low trust or all-evidence high-trust cases.
	return {"scene": scene_index, "line": line_index, "choice": option,
		"storyChoices": story_choices, "clues": clues, "completed": [], "readLines": []}


static func _lines(data: Dictionary, index: int, option: String) -> Array:
	if index == 1:
		return data.get("variants", {}).get(option, data.get("variants", {}).get("A", []))
	return data.get("lines", [])


static func _observe(data: Dictionary, snapshot: Dictionary, contract: Dictionary, rules: Dictionary) -> Dictionary:
	var scene_index: int = int(snapshot["scene"])
	var scene: Dictionary = data.get(scene_index, {})
	var option: String = str(snapshot.get("choice", "A"))
	var lines: Array = _lines(scene, scene_index, option)
	var original_line: int = int(snapshot["line"])
	var at_end: bool = original_line == lines.size() and not scene.get("ending", {}).is_empty()
	var pos: int = original_line
	var choices: Dictionary = snapshot.get("storyChoices", {}).duplicate(true)
	var gate: Dictionary = scene.get("choiceGate", {})
	# Original UPDS StorySession.at_choice_gate and _skip_hidden.
	var is_choice: bool = false
	if pos < lines.size() and pos >= 0:
		if scene_index == 1:
			is_choice = str(lines[pos].get("id", "")) == "VN0040"
		else:
			is_choice = not gate.is_empty() and str(lines[pos].get("id", "")) == str(gate.get("checkpointLineId", "")) and not choices.has(str(gate.get("id", "")))
	var resumes_to: int = pos
	var blocked_by_choice: bool = false
	while resumes_to >= 0 and resumes_to < lines.size():
		var line: Dictionary = lines[resumes_to]
		var checkpoint: bool = (scene_index == 1 and str(line.get("id", "")) == "VN0040")
		if scene_index != 1:
			checkpoint = not gate.is_empty() and str(line.get("id", "")) == str(gate.get("checkpointLineId", "")) and not choices.has(str(gate.get("id", "")))
		if not bool(line.get("hidden", false)) or checkpoint or resumes_to == lines.size() - 1:
			blocked_by_choice = checkpoint
			break
		resumes_to += 1
	var matched_gate: bool = original_line == lines.size() - 1 and not str(scene.get("nextLevelId", "")).is_empty()
	var next_scene: int = int(scene.get("nextSceneIndex", -1))
	var routes: Dictionary = scene.get("nextSceneIndices", {})
	if not routes.is_empty():
		next_scene = int(routes.get(str(choices.get(str(scene.get("branchChoiceId", "")), "")), -1))
	var output: Dictionary = {
		"sceneId": str(scene.get("sceneId", "")),
		"lineIndex": pos, "lineId": "<ending-boundary>" if at_end else (
			str(lines[pos].get("id", "")) if pos >= 0 and pos < lines.size() else ""),
		"hiddenSkipped": resumes_to != pos, "resumeLine": resumes_to,
		"resumeLineId": str(lines[resumes_to].get("id", "")) if resumes_to < lines.size() else "<ending-boundary>",
		"gate": is_choice, "gateOnResume": blocked_by_choice,
		"match3": matched_gate, "match3LevelId": str(scene.get("nextLevelId", "")),
		"match3WinSceneIndex": int(scene.get("onWinSceneIndex", -1)),
		"nextSceneIndex": next_scene,
		"choiceId": str(gate.get("id", "")),
		"choiceOptions": gate.get("choices", {}).keys() if not gate.is_empty() else CHOICES if scene_index == 1 else [],
		"endingId": "",
		"endingCopyKey": ""
	}
	# At checkpoint: choose() writes the selected A/B/C and branches to a line/next state.
	if is_choice and pos < lines.size():
		if scene_index == 1:
			var target: String = "VN0041" + option
			var jump: int = -1
			for j in range(lines.size()):
				if str(lines[j].get("id", "")) == target:
					jump = j
					break
			output["chooseResultLine"] = jump
			output["chooseWrites"] = "choice"
		else:
			output["chooseResultLine"] = pos + 1
			output["chooseWrites"] = str(gate.get("id", ""))
	# Original ending_result: only at boundary, with fallback and copy key.
	if at_end:
		var ending: Dictionary = scene.get("ending", {})
		var result_id: String = str(ending.get("endingId", ""))
		var requirement: Dictionary = ending.get("successRequirement", {})
		var metrics: Dictionary = _metrics(snapshot, rules)
		if not requirement.is_empty() and not _meets(metrics, requirement):
			result_id = str(ending.get("fallbackEndingId", result_id))
		output["endingId"] = result_id
		output["endingMetrics"] = metrics
		output["endingCopyKey"] = "fallbackCopy" if result_id == "ENDING_B_CASE_CLOSED" and choices.get("final-strategy", "A") == "B" else "copy"
	return output


static func _metrics(snapshot: Dictionary, rules: Dictionary) -> Dictionary:
	var evidence: int = 0
	for clue in rules.get("evidenceClueIds", []):
		if snapshot.get("clues", []).has(clue):
			evidence += 1
	var base: Dictionary = rules.get("baseTrustByChoice", {}).get(snapshot.get("choice", "A"), {})
	var team: int = int(base.get("teamTrust", 0))
	var source: int = int(base.get("sourceTrust", 0))
	for gate in snapshot.get("storyChoices", {}):
		var effects: Dictionary = rules.get("storyChoiceEffects", {}).get(gate, {}).get(snapshot["storyChoices"][gate], {})
		team += int(effects.get("teamTrust", 0))
		source += int(effects.get("sourceTrust", 0))
	return {"evidence": evidence, "teamTrust": team, "sourceTrust": source}


static func _meets(metrics: Dictionary, requirements: Dictionary) -> bool:
	return int(metrics["evidence"]) >= int(requirements.get("evidence", 0)) and (
		int(metrics["teamTrust"]) >= int(requirements.get("teamTrust", 0))) and (
		int(metrics["sourceTrust"]) >= int(requirements.get("sourceTrust", 0)))


static func _valid_outcome(rules: Dictionary) -> bool:
	return rules.get("evidenceClueIds") is Array and (
		rules.get("baseTrustByChoice") is Dictionary) and (
		rules.get("storyChoiceEffects") is Dictionary)


static func _fail(errors: Array[String], warnings: Array[String] = [], count: int = 0) -> Dictionary:
	return {"ok": false, "status": "BLOCKED_SEMANTICS_MISMATCH",
		"errors": errors, "warnings": warnings, "scenarioCount": count}
