extends SceneTree
## MAP-EDIT-01: isolated native route authoring smoke.
## Kept separate from room_builder_game_import_smoke.gd because pages.yml
## already runs that import test independently after scripts/check.sh.
const RouteEditorChecks = preload("res://tests/raven/map_edit_01_routes_checks.gd")


func _initialize() -> void:
	call_deferred("_check")


func _check() -> void:
	RouteEditorChecks.run(root)
	quit(0)
