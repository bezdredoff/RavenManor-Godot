extends RefCounted

const CONTRACT = preload("res://data/save_contract.json")

var last_error: Error = OK
var _directory: String


func _init(directory: String = "user://campaign_saves") -> void:
	_directory = directory


func get_item(key: String) -> Variant:
	last_error = OK
	var path := _path(key)
	if path.is_empty():
		last_error = ERR_INVALID_PARAMETER
		return null
	if not FileAccess.file_exists(path):
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		last_error = FileAccess.get_open_error()
		return null
	var raw := file.get_as_text()
	last_error = file.get_error()
	file.close()
	return raw if last_error == OK else null


func set_item(key: String, raw: String) -> bool:
	var path := _path(key)
	if path.is_empty():
		last_error = ERR_INVALID_PARAMETER
		return false
	last_error = DirAccess.make_dir_recursive_absolute(_directory)
	if last_error != OK:
		return false
	var temporary := path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		last_error = FileAccess.get_open_error()
		return false
	file.store_string(raw)
	file.flush()
	last_error = file.get_error()
	file.close()
	if last_error == OK:
		last_error = DirAccess.rename_absolute(temporary, path)
	if last_error != OK:
		DirAccess.remove_absolute(temporary)
	return last_error == OK


func remove_item(key: String) -> bool:
	var path := _path(key)
	if path.is_empty():
		last_error = ERR_INVALID_PARAMETER
		return false
	last_error = DirAccess.remove_absolute(path) if FileAccess.file_exists(path) else OK
	return last_error == OK


func _path(key: String) -> String:
	if key not in [CONTRACT.data.ravenKey, CONTRACT.data.ravenRecoveryKey]:
		return ""
	return _directory.path_join(key.uri_encode() + ".json")
