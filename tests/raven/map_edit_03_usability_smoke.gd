extends SceneTree
const Checks = preload("res://tests/raven/map_edit_03_usability_checks.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	Checks.run(root)
	quit()
