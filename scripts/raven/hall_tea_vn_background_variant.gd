extends "res://scripts/raven/hall_tea_vn.gd"
## Retains the tested Hall tea dialogue/save mechanics, switches only VN backdrop.
const VNBackgrounds = preload("res://scripts/raven/raven_vn_backgrounds.gd")


func _build_ui() -> void:
	super._build_ui()
	var candidate: Texture2D = VNBackgrounds.texture_for_scene("RM-BEAT-02-01")
	if candidate != null and background != null:
		background.texture = candidate
