extends RefCounted
## Explicit one-shot source handoff from the Godot EditorPlugin to the
## separate run process. No gameplay state, no production save mutations.
const SOURCE = preload("res://addons/room_builder_routes/route_preview_source.gd")
const FILE := "user://room_builder_routes/preview_launch.v1.json"
const EXPIRY_SECONDS := 300.0


static func stage(kind: String, path: String = "") -> Dictionary:
	if kind not in [SOURCE.BASELINE, SOURCE.USER, SOURCE.PROJECT]:
		return {"ok": false, "error": "Unknown preview selection"}
	if kind == SOURCE.BASELINE and not path.is_empty():
		return {"ok": false, "error": "Original preview cannot override source"}
	if not path.is_empty():
		var adapter = SOURCE.new()
		if not adapter._path_matches_source(kind, path):
			return {"ok": false, "error": "Unapproved QA draft path"}
	var directory := ProjectSettings.globalize_path(FILE.get_base_dir())
	var err := DirAccess.make_dir_recursive_absolute(directory)
	if err != OK:
		return {"ok": false, "error": "Could not create preview launch directory"}
	var f := FileAccess.open(FILE, FileAccess.WRITE)
	if f == null:
		return {"ok": false, "error": "Could not stage preview launch"}
	f.store_string(JSON.stringify({
		"schemaVersion": 1,
		"kind": kind,
		"path": path,
		"approval": "DRAFT_ONLY",
		"createdAt": Time.get_unix_time_from_system()
	}))
	f.close()
	return {"ok": true}


static func consume() -> Dictionary:
	if not FileAccess.file_exists(FILE):
		return {"ok": true, "kind": SOURCE.BASELINE, "path": ""}
	var raw := FileAccess.get_file_as_string(FILE)
	# Consume before parsing so a failed launch cannot become a stale fallback.
	if DirAccess.remove_absolute(ProjectSettings.globalize_path(FILE)) != OK:
		return {"ok": false, "error": "Could not consume preview selection"}
	var candidate: Variant = JSON.parse_string(raw)
	if not candidate is Dictionary:
		return {"ok": false, "error": "Malformed preview selection"}
	if candidate.get("schemaVersion") != 1 or candidate.get("approval") != "DRAFT_ONLY":
		return {"ok": false, "error": "Unsupported preview selection"}
	var kind: Variant = candidate.get("kind", null)
	var path: Variant = candidate.get("path", null)
	var created: Variant = candidate.get("createdAt", null)
	if not kind is String or not path is String or not (created is int or created is float):
		return {"ok": false, "error": "Invalid preview selection fields"}
	if kind not in [SOURCE.BASELINE, SOURCE.USER, SOURCE.PROJECT]:
		return {"ok": false, "error": "Unknown preview source"}
	if kind == SOURCE.BASELINE and not path.is_empty():
		return {"ok": false, "error": "Baseline cannot override its QA source"}
	var elapsed := Time.get_unix_time_from_system() - float(created)
	if not is_finite(elapsed) or elapsed < 0.0 or elapsed > EXPIRY_SECONDS:
		return {"ok": false, "error": "Expired preview selection; choose a source again"}
	if not path.is_empty():
		var adapter = SOURCE.new()
		if not adapter._path_matches_source(kind, path):
			return {"ok": false, "error": "Unapproved preview draft path"}
	return {"ok": true, "kind": kind, "path": path}
