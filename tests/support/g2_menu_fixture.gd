extends "res://scripts/raven/main_menu.gd"
## Capture the real menu's scene request and mount its real view with the same
## in-memory campaign store. Tests never load or overwrite user campaign data.
const Fixture = preload("res://tests/support/g2_production_fixture.gd")
const FixtureMap = preload("res://scripts/raven/raven_player_map.gd")
const Host = preload("res://scripts/raven/raven_gameplay_host.gd")
var launched_scene: Node
var launched_path := ""

func _open_normal_scene(target: String) -> Error:
	launched_path = target
	if target == MapEntry.MAP_SCENE:
		launched_scene = FixtureMap.new()
		launched_scene.host = Host.new(store.storage)
	else:
		launched_scene = load(target).instantiate()
		launched_scene.store = store
	get_tree().root.add_child(launched_scene)
	return OK
