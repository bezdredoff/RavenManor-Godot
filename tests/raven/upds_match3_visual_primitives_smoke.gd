extends SceneTree

## Actual UPDS-origin presentation modules running in Raven's Godot runtime.
## This is a component parity gate, not a claim that the entire Match3Screen
## is integrated into the vertical slice yet.
const Shape = preload("res://scripts/match3/match3_board_shape.gd")
const MotionScene = preload("res://scenes/match3_tile_motion_layer.tscn")
const Tutorials = preload("res://scripts/match3/match3_tutorials.gd")
const CssMotion = preload("res://scripts/ui/css_motion.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var host := Control.new()
	host.size = Vector2(300, 320)
	root.add_child(host)

	var shape := Shape.new()
	shape.size = Vector2(180, 180)
	host.add_child(shape)
	shape.configure(3, 3, [4], false)
	assert(shape.holes.size() == 1)
	assert(shape._is_hole(4))
	assert(not shape._is_hole(3))
	shape.configure(3, 3, [4, 8], true)
	assert(shape.draw_fill)
	assert(shape.holes.size() == 2)

	var pending: String = Tutorials.next_pending(["basic-swap", "activate-special"], [], ["level-start"])
	assert(pending == "basic-swap")
	var completed: Array[String] = Tutorials.completion_events({"valid": true, "blockersCleared": 1})
	assert(completed.has("valid-swap") and completed.has("blocker-cleared"))
	assert(Tutorials.board_reveal_events(["line", "area", "", ""], 2, 2).has("special-combo-ready"))
	assert(is_equal_approx(CssMotion.cubic_bezier(0.0, 0.18, 0.82, 0.28, 1.0), 0.0))
	assert(is_equal_approx(CssMotion.cubic_bezier(1.0, 0.18, 0.82, 0.28, 1.0), 1.0))

	var layer := MotionScene.instantiate() as Control
	layer.size = Vector2(220, 220)
	layer.set("automatic_motion_enabled", false)
	host.add_child(layer)
	var tile := ColorRect.new()
	tile.size = Vector2(42, 42)
	tile.position = Vector2(60, 60)
	layer.add_child(tile)
	await process_frame
	layer.call("animate_tile", tile, {
		"index": 4,
		"spawn": true,
		"rows": 1,
		"clipRect": Rect2(Vector2.ZERO, layer.size),
	}, 0.25)
	assert(not tile.visible, "UPDS motion must conceal original while animating its copy")
	assert((layer.get("_motions") as Array).size() == 1)
	layer.call("advance_motions", 0.25)
	assert((layer.get("_motions") as Array).is_empty())
	assert(tile.visible, "UPDS motion must restore original tile after settle")
	layer.call("cancel_motions")
	host.queue_free()
	print("Raven Manor UPDS Match-3 visual primitives smoke passed (shape, holes, tutorials, easing, settle).")
	quit()
