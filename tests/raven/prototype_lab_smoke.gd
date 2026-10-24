extends SceneTree

const SCENES := [
	"res://scenes/raven/prototype_launcher.tscn",
	"res://scenes/raven/foundation_lab.tscn",
	"res://scenes/raven/manor_greybox.tscn",
]


func _initialize() -> void:
	for path in SCENES:
		var packed: PackedScene = load(path)
		assert(packed != null, "Missing prototype scene: " + path)
		var instance := packed.instantiate()
		assert(instance != null and instance is Control)
		instance.free()
	print("Raven Manor Prototype Lab smoke passed (launcher, foundation and navigation scenes).")
	quit()
