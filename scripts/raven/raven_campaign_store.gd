extends RefCounted

## Raven save facade using the existing atomic storage adapter with a separate key and recovery slot.
const Storage = preload("res://scripts/core/save_storage.gd")
const Snapshot = preload("res://scripts/raven/raven_snapshot.gd")
const Ids = preload("res://scripts/raven/raven_ids.gd")
const CONTRACT = preload("res://data/save_contract.json")

var storage: RefCounted
var last_load_report := {"status": "fresh", "detail": "not-loaded"}


func _init(adapter: RefCounted = null) -> void:
	storage = adapter if adapter != null else Storage.new()


func load_campaign() -> Dictionary:
	var raw: Variant = storage.get_item(CONTRACT.data.ravenKey)
	if storage.last_error != OK:
		last_load_report = {"status": "fresh", "detail": "storage-read-failed"}
		return Snapshot.fresh()
	if raw == null or raw == "":
		last_load_report = {"status": "fresh", "detail": "no-save"}
		return Snapshot.fresh()
	var parsed: Variant = JSON.parse_string(raw)
	var normalized: Variant = Snapshot.normalize(parsed, Ids.CATALOG.data)
	if normalized == null:
		_backup(str(raw), "invalid-or-unsupported-save")
		last_load_report = {"status": "recovered-corrupt", "detail": "invalid-or-unsupported-save"}
		return Snapshot.fresh()
	last_load_report = {"status": "loaded", "detail": "schema-%d" % Snapshot.SCHEMA_VERSION}
	return normalized


func save_campaign(state: Variant) -> bool:
	var normalized: Variant = Snapshot.normalize(state, Ids.CATALOG.data)
	if normalized == null:
		return false
	return storage.set_item(CONTRACT.data.ravenKey, JSON.stringify(normalized))


func reset_campaign() -> bool:
	return storage.remove_item(CONTRACT.data.ravenKey)


func get_recovery_backup() -> Variant:
	var raw: Variant = storage.get_item(CONTRACT.data.ravenRecoveryKey)
	if raw == null or storage.last_error != OK:
		return null
	return JSON.parse_string(raw)


func _backup(raw: String, reason: String) -> bool:
	return storage.set_item(CONTRACT.data.ravenRecoveryKey, JSON.stringify({
		"reason": reason,
		"saveKey": CONTRACT.data.ravenKey,
		"raw": raw,
	}))
