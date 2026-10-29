extends "res://scripts/raven/hall_tea_vn.gd"
## Isolated art comparison: same dialogue and placement, no campaign mutation.
const Watercolor = preload("res://shaders/raven/watercolor_pilot.gdshader")

func _ready() -> void:
    super._ready()
    for target in [background, actor_left, actor_right]:
        if target == null:
            continue
        var material_instance := ShaderMaterial.new()
        material_instance.shader = Watercolor
        target.material = material_instance
    if note != null:
        note.text = "WATERCOLOR TEST · не меняет сохранение"

func _commit_completed_beat() -> void:
    pass
