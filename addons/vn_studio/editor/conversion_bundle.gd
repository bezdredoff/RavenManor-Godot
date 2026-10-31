@tool
extends RefCounted
## VN-EDITOR-06 first gate: inspect + generate a private, reversible conversion bundle.
## No donor write, no Raven runtime switch, no rewriting of existing player saves.
const Reader = preload("res://addons/vn_studio/editor/legacy_reader.gd")
const Drafts = preload("res://addons/vn_studio/editor/draft_store.gd")

const FORMAT := "vn-studio-scene-v1"
const BUNDLE := "vn-studio-migration-bundle-v1"
const SOURCE_REF := "UPDS-godot"
const LOCALES := ["ru", "en", "be"]
const EXPORTED_SCENES := 45


static func prepare(project: Dictionary, drafts: Dictionary = {}) -> Dictionary:
	var errors: Array[String] = []
	var warnings: Array[String] = []
	if not bool(project.get("ok", false)):
		return _invalid(["Откройте корректный локальный UPDS-godot."])
	var scenes: Array = project.get("scenes", [])
	var contract: Dictionary = project.get("contract", {})
	var expected: Array = contract.get("storySceneIds", [])
	var root: String = str(project.get("root", ""))
	if scenes.size() != EXPORTED_SCENES or expected.size() != EXPORTED_SCENES:
		return _invalid(["Ожидались 45 исходных сцен из UPDS-godot."])
	var outputs: Array[Dictionary] = []
	var per_scene: Array[Dictionary] = []
	var index_map: Dictionary = {}
	var line_positions: Dictionary = {}
	var total_lines: int = 0
	var applied_lines: int = 0
	var candidate_id_seen: Dictionary = {}
	var source_file_ids: Dictionary = {}
	var source_hashes: Array[String] = []
	for i in range(scenes.size()):
		var entry: Dictionary = scenes[i]
		var source_id: String = str(entry.get("id", ""))
		if source_id.is_empty() or candidate_id_seen.has(source_id) or expected[i] != source_id or int(entry.get("index", -1)) != i:
			errors.append("Несогласованность sceneId/sceneIndex у сцены %d" % i)
			continue
		candidate_id_seen[source_id] = true
		var file_name: String = str(entry.get("file", ""))
		if file_name.is_empty() or file_name.find("/") >= 0 or file_name.find("\\") >= 0:
			errors.append("%s: небезопасный путь файла" % source_id)
			continue
		var source_path: String = root.path_join("data").path_join(file_name)
		if not FileAccess.file_exists(source_path):
			errors.append("%s: исходный файл отсутствует" % source_id)
			continue
		var live_json: Variant = JSON.parse_string(FileAccess.get_file_as_string(source_path))
		if not live_json is Dictionary or JSON.stringify(live_json) != JSON.stringify(entry.get("data", {})):
			errors.append("%s: источник изменился после открытия редактора; откройте проект заново" % source_id)
			continue
		var sha: String = FileAccess.get_sha256(source_path)
		if sha.is_empty():
			errors.append("%s: невозможно вычислить SHA256 исходника" % source_id)
			continue
		if source_file_ids.has(file_name):
			errors.append("%s: исходный файл уже встречался" % source_id)
			continue
		source_file_ids[file_name] = true
		source_hashes.append(sha)
		var draft: Dictionary
		if drafts.has(i):
			draft = drafts[i].duplicate(true)
			var result: String = Drafts.validate(root, entry, draft)
			if not result.is_empty():
				errors.append("%s: незаписанный/несовместимый черновик: %s" % [source_id, result])
				continue
		else:
			var loaded: Dictionary = Drafts.load_draft(root, entry)
			if not bool(loaded.get("ok", false)):
				errors.append("%s: %s" % [source_id, str(loaded.get("error", "Ошибка черновика"))])
				continue
			draft = loaded["draft"]
		var original: Dictionary = entry.get("data", {}).duplicate(true)
		var effective: Dictionary = original.duplicate(true)
		var groups: Dictionary = entry.get("groups", {})
		var position_groups: Dictionary = {}
		var changed_here: int = 0
		var count_here: int = 0
		for group_name in groups:
			var lines: Array = groups[group_name]
			var converted_lines: Array = []
			var mapping: Array[Dictionary] = []
			for idx in range(lines.size()):
				var original_line: Dictionary = lines[idx]
				var id: String = str(original_line.get("id", ""))
				if id.is_empty():
					errors.append("%s / %s line %d: отсутствует ID реплики" % [source_id, str(group_name), idx])
				var translated: Dictionary = original_line.get("localized", {})
				for lang in LOCALES:
					if not translated.has(lang) or not translated[lang] is Dictionary:
						errors.append("%s/%s/%s: отсутствует %s" % [source_id, str(group_name), id, lang])
				var merged: Dictionary = Drafts.materialize(original_line, draft, str(group_name), idx)
				converted_lines.append(merged)
				if JSON.stringify(merged) != JSON.stringify(original_line):
					changed_here += 1
				mapping.append({"lineIndex": idx, "legacyLineId": id,
					"lineId": id, "hidden": bool(original_line.get("hidden", false))})
				count_here += 1
			position_groups[str(group_name)] = mapping
			if str(group_name) == "base":
				effective["lines"] = converted_lines
			else:
				if not effective.has("variants"):
					effective["variants"] = {}
				effective["variants"][str(group_name)] = converted_lines
		total_lines += count_here
		applied_lines += changed_here
		var source_metadata: Dictionary = {
			"repository": SOURCE_REF, "relativeFile": "data/" + file_name,
			"sceneSha256": sha, "rootFingerprint": root.simplify_path().sha256_text()
		}
		# Lossless stage-one schema: full legacy data remains available for reverse import.
		# The candidate is NOT yet an executable, fully normalized VN-runtime scene.
		var wrapped: Dictionary = {
			"format": FORMAT, "schemaVersion": 1, "sceneId": source_id,
			"sceneIndex": i, "source": source_metadata,
			"legacyOriginal": original, "payload": effective,
			"capabilities": {"legacyPassThrough": true, "runtimePlayable": false},
			"draftAppliedLineCount": changed_here
		}
		var output_name: String = "%02d.json" % i
		var json: String = JSON.stringify(wrapped, "\t") + "\n"
		outputs.append({"path": "scenes/" + output_name, "json": json})
		per_scene.append({"sceneId": source_id, "sceneIndex": i, "sourceFile": "data/" + file_name,
			"sourceSha256": sha, "targetFile": "scenes/" + output_name,
			"targetSha256": json.sha256_text(), "lines": count_here,
			"patchedLines": changed_here, "branchGroups": position_groups.keys()})
		index_map[str(i)] = source_id
		line_positions[source_id] = position_groups
		if effective.has("choiceGate"):
			warnings.append("%s: choiceGate сохранён в payload, не исполняется новым runtime" % source_id)
		if effective.has("nextLevelId") and str(effective.get("nextLevelId", "")) != "":
			warnings.append("%s: переход Match-3 сохранён, требует совместимого адаптера" % source_id)
	var root_fingerprint: String = root.simplify_path().sha256_text()
	if outputs.size() != EXPORTED_SCENES:
		errors.append("Обработано %d из 45 сцен" % outputs.size())
	if not errors.is_empty():
		return _invalid(errors, warnings)
	# Save keys and scene positions are MAPPING CANDIDATES, not a migrated save.
	var map: Dictionary = {"format": "vn-studio-save-map-v1", "sourceStoryKey": str(contract.get("storyKey", "")),
		"sourceStorySchema": contract.get("storySchema", null), "sceneIndexToId": index_map,
		"linePositionsByScene": line_positions, "choiceGateIds": contract.get("storyChoiceGateIds", []),
		"levelIds": contract.get("levelIds", []),
		"status": "PROPOSED_NOT_VALIDATED_WITH_EXISTING_SAVES"}
	var map_json: String = JSON.stringify(map, "\t") + "\n"
	var manifest: Dictionary = {
		"format": BUNDLE, "schemaVersion": 1, "source": SOURCE_REF,
		"sourceRootFingerprint": root_fingerprint,
		"sceneCount": outputs.size(), "lineOccurrences": total_lines,
		"patchedLineOccurrences": applied_lines, "saveMigrationStatus": "NOT_EXECUTABLE",
		"assets": "REFERENCED_ONLY_NOT_COPIED",
		"preview": "not runtime parity", "sceneMap": per_scene,
		"saveMapFile": "save_migration_map.json",
		"saveMapSha256": map_json.sha256_text(),
		"warnings": warnings
	}
	var manifest_json: String = JSON.stringify(manifest, "\t") + "\n"
	var fingerprint: String = (manifest_json + map_json).sha256_text()
	var bundle_id: String = fingerprint.substr(0, 16)
	outputs.append({"path": "save_migration_map.json", "json": map_json})
	outputs.append({"path": "conversion_manifest.json", "json": manifest_json})
	return {"ok": true, "bundleId": bundle_id, "files": outputs,
		"manifest": manifest, "errors": errors, "warnings": warnings,
		"stats": {"scenes": EXPORTED_SCENES, "lines": total_lines,
			"changed": applied_lines, "files": outputs.size()}}


static func export_new_bundle(project: Dictionary, preview: Dictionary, explicit_approval: bool) -> Dictionary:
	if not explicit_approval:
		return {"ok": false, "error": "Требуется явное подтверждение экспорта."}
	if not bool(preview.get("ok", false)):
		return {"ok": false, "error": "Сначала выполните успешный dry-run."}
	# Re-run from disk to prevent exporting a stale report after an upstream source edit.
	var fresh: Dictionary = prepare(project)
	if not bool(fresh.get("ok", false)) or fresh.get("bundleId") != preview.get("bundleId"):
		return {"ok": false, "error": "Источник/черновик изменился после dry-run; повторите анализ."}
	var source_root: String = str(project.get("root", "")).simplify_path()
	var home: String = ProjectSettings.globalize_path("user://vn_studio_conversions/v1")
	var base: String = home.path_join(source_root.sha256_text())
	var destination: String = base.path_join("bundle-" + str(preview["bundleId"]))
	if destination == source_root or destination.begins_with(source_root + "/") or source_root.begins_with(destination + "/"):
		return {"ok": false, "error": "Каталог экспорта пересекается с источником."}
	if DirAccess.dir_exists_absolute(destination):
		return {"ok": false, "error": "Такой экспорт уже существует; данные не перезаписываются."}
	if DirAccess.make_dir_recursive_absolute(base) != OK:
		return {"ok": false, "error": "Не удалось создать приватную папку экспорта."}
	var staging: String = destination + ".staging"
	if DirAccess.dir_exists_absolute(staging):
		return {"ok": false, "error": "Есть незавершённый staging. Проверьте и удалите его вручную."}
	if DirAccess.make_dir_recursive_absolute(staging.path_join("scenes")) != OK:
		return {"ok": false, "error": "Не удалось создать временную папку."}
	for file in fresh["files"]:
		var relative: String = str(file["path"])
		# Paths are generated entirely in this module, never accepted from drafts.
		var path: String = staging.path_join(relative)
		var handle: FileAccess = FileAccess.open(path, FileAccess.WRITE)
		if handle == null:
			return {"ok": false, "error": "Не удалось записать %s; staging сохранён для осмотра." % relative}
		handle.store_string(str(file["json"]))
		handle.flush()
		handle.close()
		if FileAccess.get_sha256(path) != str(file["json"]).sha256_text():
			return {"ok": false, "error": "Контрольная сумма экспорта не совпала: " + relative}
	if DirAccess.rename_absolute(staging, destination) != OK:
		return {"ok": false, "error": "Не удалось завершить экспорт; staging не удалён."}
	return {"ok": true, "path": destination, "bundleId": fresh["bundleId"],
		"notice": "Экспорт — только локальная копия. Игра и сохранения не переключены."}


static func _invalid(errors: Array[String], warnings: Array[String] = []) -> Dictionary:
	return {"ok": false, "errors": errors, "warnings": warnings, "files": []}
