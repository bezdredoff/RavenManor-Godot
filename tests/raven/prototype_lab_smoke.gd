extends SceneTree

const SCENES := [
	"res://scenes/raven/prototype_launcher.tscn",
	"res://scenes/raven/foundation_lab.tscn",
	"res://scenes/raven/manor_greybox.tscn",
	"res://scenes/raven/vertical_slice.tscn",
	"res://scenes/raven/content_preview.tscn",
	"res://scenes/raven/hall_tea_vn.tscn",
	"res://scenes/raven/hall_tea_watercolor.tscn",
]


func _initialize() -> void:
	for path in SCENES:
		var packed: PackedScene = load(path)
		assert(packed != null, "Missing prototype scene: " + path)
		var instance := packed.instantiate()
		assert(instance != null and instance is Control)
		instance.free()
	print("Raven Manor Prototype Lab smoke passed (launcher, foundation, navigation and vertical slice scenes).")
	quit()
