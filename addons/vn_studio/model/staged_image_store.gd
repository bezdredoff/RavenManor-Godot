@tool
extends RefCounted
## VNS5-03 editor-only, project-scoped image staging. No res:// writes or runtime authority.
const Registry = preload("res://addons/vn_studio/model/asset_registry.gd")
const FORMAT := "raven-vn-image-staging-v1"
const MAX_BYTES := 8 * 1024 * 1024
const STAGING_BASE := "user://raven_vn_asset_staging/v1"
const CATALOGS := [Registry.STAGING, Registry.BACKGROUNDS, Registry.CHARACTERS, Registry.CHARACTER_ART]
const CATEGORIES := ["background", "character", "prop"]
const FIELDS := ["category", "displayName", "groupId", "lighting", "state", "pose", "emotion", "costume", "provenance", "license"]

var folder: String = ""
var project_root: String = ""
var manifest: Dictionary = {}
var error: String = ""
var blocked: bool = false


func open_project(root_path: String) -> Dictionary:
	project_root = root_path.simplify_path()
	if not project_root.is_absolute_path() or not DirAccess.dir_exists_absolute(project_root):
		return _fail("Недопустимый корень проекта.")
	var fingerprint: String = project_root.to_utf8_buffer().sha256_text()
	folder = "%s/%s" % [STAGING_BASE, fingerprint]
	var locks: Dictionary = _current_locks()
	if locks.size() != CATALOGS.size():
		return _fail("Отсутствует production catalog; staging заблокирован.")
	if not _safe("", false):
		return _fail("Staging path содержит ссылку или выходит за user://.")
	var manifest_path: String = folder.path_join("manifest.json")
	# Interrupted writes are never silently recovered or overwritten.
	if FileAccess.file_exists(manifest_path + ".bak") or FileAccess.file_exists(manifest_path + ".tmp"):
		return _fail("Найден temp/backup manifest: требуется ручная проверка.")
	if not FileAccess.file_exists(manifest_path):
		manifest = {"format": FORMAT, "schemaVersion": 1, "projectFingerprint": fingerprint,
			"sourceLocks": locks, "items": []}
		blocked = false
		error = ""
		return {"ok": true, "items": []}
	if not _safe("manifest.json", true):
		return _fail("Manifest link/reparse path запрещён.")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
	if not parsed is Dictionary or parsed.get("format") != FORMAT or parsed.get("schemaVersion") != 1 \
			or parsed.get("projectFingerprint") != fingerprint or parsed.get("sourceLocks") != locks or not parsed.get("items") is Array:
		return _fail("Manifest повреждён или source catalog SHA изменился. Экспорт и запись заблокированы.")
	manifest = parsed
	var ids: Dictionary = {}
	var shas: Dictionary = {}
	for item in manifest["items"]:
		if not item is Dictionary or not _valid_item(item):
			return _fail("Manifest содержит недопустимую запись или изменённый binary.")
		if ids.has(item["id"]) or shas.has(item["sha256"]):
			return _fail("Повторный asset ID/SHA в manifest.")
		ids[item["id"]] = true
		shas[item["sha256"]] = true
	blocked = false
	error = ""
	return {"ok": true, "items": manifest["items"].duplicate(true)}


func list_items() -> Array:
	return manifest.get("items", []).duplicate(true)


func stage_files(paths: PackedStringArray) -> Array[Dictionary]:
	var outcomes: Array[Dictionary] = []
	for path in paths:
		outcomes.append(stage_file(path))
	return outcomes


func stage_file(source_path: String) -> Dictionary:
	if blocked or folder.is_empty():
		return {"ok": false, "error": error if not error.is_empty() else "Staging не открыт."}
	if not source_path.is_absolute_path() or source_path.contains("\u0000") or not FileAccess.file_exists(source_path):
		return {"ok": false, "error": "Укажите существующий абсолютный путь исходного изображения."}
	var filename: String = source_path.get_file()
	if not _safe_name(filename):
		return {"ok": false, "error": "Небезопасное имя исходного файла."}
	var ext: String = filename.get_extension().to_lower()
	if not ["png", "jpg", "jpeg", "webp"].has(ext):
		return {"ok": false, "error": "Разрешены только PNG, JPEG и WebP; SVG/code запрещён."}
	var f: FileAccess = FileAccess.open(source_path, FileAccess.READ)
	if f == null:
		return {"ok": false, "error": "Файл недоступен для чтения."}
	var size: int = f.get_length()
	if size <= 0 or size > MAX_BYTES:
		return {"ok": false, "error": "Размер должен быть 1..%d байт (8 MiB)." % MAX_BYTES}
	var bytes: PackedByteArray = f.get_buffer(size)
	f.close()
	if bytes.size() != size or not _magic_ok(bytes, ext):
		return {"ok": false, "error": "Неверная сигнатура изображения или fake extension."}
	var image: Image = Image.new()
	var err: Error = OK
	match ext:
		"png": err = image.load_png_from_buffer(bytes)
		"jpg", "jpeg": err = image.load_jpg_from_buffer(bytes)
		"webp": err = image.load_webp_from_buffer(bytes)
	if err != OK or image.is_empty() or image.get_width() <= 0 or image.get_height() <= 0:
		return {"ok": false, "error": "Изображение не декодируется как %s." % ext}
	var sha: String = bytes.sha256_text()
	for old in manifest["items"]:
		if old["sha256"] == sha:
			return {"ok": false, "duplicate": true, "existingId": old["id"],
				"error": "Такие же байты уже staged: %s." % old["id"]}
	var collision: bool = false
	for old in manifest["items"]:
		if str(old["originalFilename"]).to_lower() == filename.to_lower():
			collision = true
	# Binary names are content-addressed, never based on a user-controlled path.
	var canonical_ext: String = "jpg" if ext == "jpeg" else ext
	var relative: String = "images/%s.%s" % [sha, canonical_ext]
	if not _safe(relative, false) or not _ensure_dirs():
		return {"ok": false, "error": "Небезопасный staging target или ошибка создания каталога."}
	if FileAccess.file_exists(folder.path_join(relative)):
		return {"ok": false, "error": "Target уже существует; silent overwrite запрещён."}
	var binary_result: Dictionary = _write_new(relative, bytes)
	if not binary_result.get("ok", false):
		return binary_result
	var id: String = "asset-" + sha # stable and collision-free across categories
	var now: String = Time.get_datetime_string_from_system(true)
	var item: Dictionary = {"id": id, "sha256": sha, "relativePath": relative,
		"originalFilename": filename, "byteCount": size, "width": image.get_width(),
		"height": image.get_height(), "alpha": image.detect_alpha() != Image.ALPHA_NONE,
		"orientation": _orientation(image.get_width(), image.get_height()),
		"category": "background", "groupId": "", "displayName": filename.get_basename(),
		"lighting": "", "state": "", "pose": "", "emotion": "", "costume": "",
		"provenance": "", "license": "", "importedAt": now, "importVersion": 1}
	manifest["items"].append(item)
	var saved: Dictionary = _save_manifest()
	if not saved.get("ok", false):
		manifest["items"].pop_back()
		# Intentionally leave a content-addressed orphan for manual recovery; never touch external paths.
		return saved
	return {"ok": true, "item": item.duplicate(true), "filenameCollision": collision}


func update_metadata(id: String, values: Dictionary) -> Dictionary:
	if blocked:
		return _fail(error)
	for key in values.keys():
		if not FIELDS.has(key) or not values[key] is String or not _safe_metadata_value(key, values[key]):
			return {"ok": false, "error": "Недопустимое metadata field или path-like значение: %s" % key}
	var index: int = _find(id)
	if index < 0:
		return {"ok": false, "error": "Staged ID не найден."}
	var old: Dictionary = manifest["items"][index].duplicate(true)
	var edited: Dictionary = old.duplicate(true)
	for key in values.keys():
		edited[key] = values[key].strip_edges()
	if not CATEGORIES.has(edited["category"]) or edited["displayName"].is_empty() or edited["groupId"].is_empty():
		return {"ok": false, "error": "Display name и group ID обязательны."}
	if not _valid_group(str(edited["category"]), str(edited["groupId"])):
		return {"ok": false, "error": "Group ID не соответствует категории или реестру."}
	if edited["category"] != "character" and (not edited["pose"].is_empty() or not edited["emotion"].is_empty() or not edited["costume"].is_empty()):
		return {"ok": false, "error": "Pose/emotion/costume разрешены только персонажам."}
	manifest["items"][index] = edited
	var result: Dictionary = _save_manifest()
	if not result.get("ok", false):
		manifest["items"][index] = old
	return result


func set_category(id: String, category: String) -> Dictionary:
	if blocked or not CATEGORIES.has(category):
		return {"ok": false, "error": "Неверная категория или staging заблокирован."}
	var index: int = _find(id)
	if index < 0:
		return {"ok": false, "error": "Staged ID не найден."}
	var previous: Dictionary = manifest["items"][index].duplicate(true)
	manifest["items"][index]["category"] = category
	manifest["items"][index]["groupId"] = ""
	for field in ["lighting", "state", "pose", "emotion", "costume"]:
		manifest["items"][index][field] = ""
	var result: Dictionary = _save_manifest()
	if not result.get("ok", false):
		manifest["items"][index] = previous
	return result


func remove_item(id: String) -> Dictionary:
	if blocked:
		return _fail(error)
	var index: int = _find(id)
	if index < 0:
		return {"ok": false, "error": "Staged ID не найден."}
	var entry: Dictionary = manifest["items"][index]
	if not _safe(str(entry["relativePath"]), true):
		return _fail("Binary path не прошёл containment check.")
	manifest["items"].remove_at(index)
	var saved: Dictionary = _save_manifest()
	if not saved.get("ok", false):
		manifest["items"].insert(index, entry)
		return saved
	# After manifest is safe, remove only the known content-addressed binary.
	var remove_error: Error = DirAccess.remove_absolute(ProjectSettings.globalize_path(folder.path_join(entry["relativePath"])))
	return {"ok": remove_error == OK, "error": "" if remove_error == OK else "Metadata removed; orphan binary can be removed manually."}


func export_review_candidate() -> Dictionary:
	if blocked or manifest.get("items", []).is_empty():
		return {"ok": false, "error": "Staging заблокирован или пуст."}
	if _current_locks() != manifest["sourceLocks"]:
		return _fail("Production catalog SHA drift: review export заблокирован.")
	for item in manifest["items"]:
		if not _valid_item(item):
			return _fail("Staged binary повреждён: review export заблокирован.")
		if not _reviewable_rights(str(item["license"])) or not _reviewable_rights(str(item["provenance"])) or str(item["groupId"]).is_empty():
			return {"ok": false, "error": "Для export обязательны group, provenance и license: " + str(item["id"])}
	var payload: Dictionary = manifest.duplicate(true)
	payload["format"] = "raven-vn-image-review-candidate-v1"
	payload["status"] = "review_only_not_approved"
	payload["sourceStagingFormat"] = FORMAT
	var json: String = JSON.stringify(payload, "\t", true) + "\n"
	var candidate: String = "exports/review-" + json.to_utf8_buffer().sha256_text()
	if not _safe(candidate, false) or not _ensure_dirs():
		return {"ok": false, "error": "Export root небезопасен."}
	var absolute: String = ProjectSettings.globalize_path(folder.path_join(candidate))
	if DirAccess.dir_exists_absolute(absolute) or FileAccess.file_exists(absolute):
		return {"ok": false, "error": "Review candidate уже существует (no overwrite).", "path": absolute}
	if DirAccess.make_dir_recursive_absolute(absolute.path_join("images")) != OK or not _safe(candidate + "/images", false):
		return {"ok": false, "error": "Не удалось создать review folder безопасно."}
	for item in manifest["items"]:
		var dst: String = candidate.path_join(str(item["relativePath"]))
		var b: PackedByteArray = FileAccess.get_file_as_bytes(folder.path_join(str(item["relativePath"])))
		var r: Dictionary = _write_new(dst, b)
		if not r.get("ok", false):
			return {"ok": false, "error": "Частичный review export; проверьте папку вручную: " + str(r.get("error", "")), "path": absolute}
	var manifest_written: Dictionary = _write_new(candidate + "/review_manifest.json", json.to_utf8_buffer())
	if not manifest_written.get("ok", false):
		return {"ok": false, "error": "Review manifest не записан; частичный export оставлен для проверки.", "path": absolute}
	return {"ok": true, "path": absolute}


func get_preview(id: String) -> Image:
	var index: int = _find(id)
	if index < 0:
		return null
	var item: Dictionary = manifest["items"][index]
	if not _valid_item(item):
		return null
	var bytes: PackedByteArray = FileAccess.get_file_as_bytes(folder.path_join(item["relativePath"]))
	var image: Image = Image.new()
	match str(item["relativePath"]).get_extension():
		"png": image.load_png_from_buffer(bytes)
		"jpg": image.load_jpg_from_buffer(bytes)
		"webp": image.load_webp_from_buffer(bytes)
	return image if not image.is_empty() else null


func _find(id: String) -> int:
	for i in manifest.get("items", []).size():
		if manifest["items"][i]["id"] == id:
			return i
	return -1


func _current_locks() -> Dictionary:
	var result: Dictionary = {}
	for path in CATALOGS:
		var absolute: String = project_root.path_join(path)
		if not FileAccess.file_exists(absolute):
			return {}
		result[path] = FileAccess.get_sha256(absolute)
	return result


func _valid_item(item: Dictionary) -> bool:
	for key in ["id", "sha256", "relativePath", "originalFilename", "category", "groupId", "displayName",
		"lighting", "state", "pose", "emotion", "costume", "provenance", "license", "importedAt"]:
		if not item.has(key) or not item[key] is String:
			return false
	if not CATEGORIES.has(item["category"]) or not _safe_name(item["originalFilename"]):
		return false
	if not str(item["groupId"]).is_empty() and not _valid_group(item["category"], item["groupId"]):
		return false
	if item["category"] != "character" and (not item["pose"].is_empty() or not item["emotion"].is_empty() or not item["costume"].is_empty()):
		return false
	if item.get("importVersion") != 1 or int(item.get("byteCount", 0)) > MAX_BYTES or int(item.get("byteCount", 0)) <= 0:
		return false
	var sha: String = str(item["sha256"])
	if sha.length() != 64 or not sha.is_valid_hex_number() or item["id"] != "asset-" + sha:
		return false
	var rel: String = str(item["relativePath"])
	if rel != "images/%s.%s" % [sha, rel.get_extension()] or not ["png", "jpg", "webp"].has(rel.get_extension()) or not _safe(rel, true):
		return false
	for field in FIELDS:
		if not _safe_metadata_value(field, item[field]):
			return false
	var path: String = folder.path_join(rel)
	if not FileAccess.file_exists(path):
		return false
	var source: FileAccess = FileAccess.open(path, FileAccess.READ)
	if source == null:
		return false
	var actual_size: int = source.get_length()
	source.close()
	if actual_size != int(item["byteCount"]) or FileAccess.get_sha256(path) != sha:
		return false
	var image: Image = get_image_without_manifest(path, rel.get_extension())
	return image != null and image.get_width() == int(item.get("width", -1)) and image.get_height() == int(item.get("height", -1)) \
		and (image.detect_alpha() != Image.ALPHA_NONE) == bool(item.get("alpha", false)) \
		and str(item.get("orientation", "")) == _orientation(image.get_width(), image.get_height())


static func get_image_without_manifest(path: String, ext: String) -> Image:
	var image: Image = Image.new()
	var bytes: PackedByteArray = FileAccess.get_file_as_bytes(path)
	var err: Error = ERR_FILE_UNRECOGNIZED
	match ext:
		"png": err = image.load_png_from_buffer(bytes)
		"jpg": err = image.load_jpg_from_buffer(bytes)
		"webp": err = image.load_webp_from_buffer(bytes)
	return image if err == OK and not image.is_empty() else null


func _valid_group(category: String, group: String) -> bool:
	if not _safe_metadata_value("groupId", group) or group.length() > 80 or group.is_empty():
		return false
	if category == "background":
		return group.begins_with("BG-")
	if category == "prop":
		return group.begins_with("PROP-")
	var registry: Dictionary = Registry.open_project(project_root)
	if not registry.get("ok", false):
		return false
	for record in registry["records"]:
		if record["category"] == "character" and record["id"] == group and record["groupId"] == group:
			return true
	return false


static func _reviewable_rights(value: String) -> bool:
	var normalized: String = value.strip_edges().to_lower()
	return not normalized.is_empty() and not ["unknown", "none", "not_recorded", "pending", "n/a", "unverified", "todo"].has(normalized)


static func _safe_name(name: String) -> bool:
	return not name.is_empty() and name.length() < 200 and name != "." and name != ".." \
		and not name.contains("/") and not name.contains("\\") and not name.contains(":") and not name.contains("\u0000")


static func _safe_metadata_value(key: String, value: String) -> bool:
	if value.length() > 1000 or value.contains("\u0000") or value.contains("\n") or value.contains("\r"):
		return false
	# Provenance and license are descriptive text, often URLs. They never become paths.
	if key in ["provenance", "license"]:
		return true
	return not value.contains("\\") and not value.contains("/") and not value.contains("..") and not value.contains(":")


static func _magic_ok(bytes: PackedByteArray, extension: String) -> bool:
	if extension == "png":
		return bytes.size() >= 8 and bytes.slice(0, 8) == PackedByteArray([137, 80, 78, 71, 13, 10, 26, 10])
	if extension == "jpg" or extension == "jpeg":
		return bytes.size() >= 3 and bytes[0] == 255 and bytes[1] == 216 and bytes[2] == 255
	return bytes.size() >= 12 and bytes.slice(0, 4) == "RIFF".to_ascii_buffer() and bytes.slice(8, 12) == "WEBP".to_ascii_buffer()


static func _orientation(width: int, height: int) -> String:
	return "portrait" if height > width else "landscape" if width > height else "square"


func _safe(rel: String, _is_file: bool) -> bool:
	if folder.is_empty() or rel.begins_with("/") or rel.contains("\\") or rel.contains(":") or rel.contains("..") or rel.contains("\u0000"):
		return false
	# Access all ancestry from the real user root. A symlinked/reparse directory must never be followed.
	var user_abs: String = ProjectSettings.globalize_path("user://").simplify_path()
	var dest: String = ProjectSettings.globalize_path(folder.path_join(rel)).simplify_path()
	if not dest.begins_with(user_abs + "/"):
		return false
	var relative: String = dest.trim_prefix(user_abs + "/")
	var access: DirAccess = DirAccess.open("user://")
	if access == null:
		return false
	var running: String = ""
	var parts: PackedStringArray = relative.split("/")
	for i in parts.size():
		running = parts[i] if running.is_empty() else running + "/" + parts[i]
		if access.is_link(running):
			return false
	return true


func _ensure_dirs() -> bool:
	if not _safe("", false):
		return false
	var images: String = ProjectSettings.globalize_path(folder.path_join("images"))
	if DirAccess.make_dir_recursive_absolute(images) != OK:
		return false
	return _safe("images", false)


func _write_new(rel: String, bytes: PackedByteArray) -> Dictionary:
	if not _safe(rel, false):
		return {"ok": false, "error": "Escape/link в staging path."}
	var dst: String = ProjectSettings.globalize_path(folder.path_join(rel))
	if FileAccess.file_exists(dst) or DirAccess.dir_exists_absolute(dst):
		return {"ok": false, "error": "Target существует: overwrite запрещён."}
	var tmp: String = dst + ".tmp"
	if FileAccess.file_exists(tmp) or not _safe(rel + ".tmp", false):
		return {"ok": false, "error": "Temporary target уже существует или небезопасен."}
	var file: FileAccess = FileAccess.open(tmp, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "error": "Невозможно записать staging temp."}
	file.store_buffer(bytes)
	file.flush()
	file.close()
	if FileAccess.get_sha256(tmp) != bytes.sha256_text() or FileAccess.file_exists(dst) or DirAccess.rename_absolute(tmp, dst) != OK:
		DirAccess.remove_absolute(tmp)
		return {"ok": false, "error": "SHA/temp rename failed."}
	return {"ok": true}


func _save_manifest() -> Dictionary:
	if blocked or _current_locks() != manifest.get("sourceLocks", {}) or not _ensure_dirs() or not _safe("manifest.json", false):
		return {"ok": false, "error": "Staging заблокирован или путь небезопасен."}
	var dst: String = ProjectSettings.globalize_path(folder.path_join("manifest.json"))
	var tmp: String = dst + ".tmp"
	var bak: String = dst + ".bak"
	if FileAccess.file_exists(tmp) or FileAccess.file_exists(bak) or not _safe("manifest.json.tmp", false) or not _safe("manifest.json.bak", false):
		return {"ok": false, "error": "Остатки предыдущей записи; требуется ручная проверка."}
	var payload: PackedByteArray = (JSON.stringify(manifest, "\t", true) + "\n").to_utf8_buffer()
	var f: FileAccess = FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return {"ok": false, "error": "Не удалось записать временный manifest."}
	f.store_buffer(payload)
	f.flush()
	f.close()
	if FileAccess.get_sha256(tmp) != payload.sha256_text():
		return {"ok": false, "error": "Manifest SHA mismatch; temp оставлен для recovery."}
	var had_old: bool = FileAccess.file_exists(dst)
	if had_old and DirAccess.rename_absolute(dst, bak) != OK:
		return {"ok": false, "error": "Не удалось создать backup manifest."}
	if DirAccess.rename_absolute(tmp, dst) != OK:
		if had_old:
			DirAccess.rename_absolute(bak, dst)
		return {"ok": false, "error": "Manifest rename failed; recovery необходим."}
	if had_old:
		DirAccess.remove_absolute(bak)
	return {"ok": true}


func _fail(message: String) -> Dictionary:
	blocked = true
	error = message
	return {"ok": false, "error": message}
