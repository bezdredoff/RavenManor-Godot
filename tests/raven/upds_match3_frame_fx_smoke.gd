extends SceneTree
## CODE-02C: use actual UPDS frames/engine and original tile motion layer.
## Never write campaign saves or import UPDS story/session.
const Game = preload("res://scripts/raven/raven_match3_game.gd")
const Board = preload("res://scripts/match3/match3_board_presenter.gd")
const FrameVisuals = preload("res://scripts/match3/match3_frame_visuals.gd")
const RavenSkin = preload("res://scripts/raven/raven_match3_theme.gd")
const Content = preload("res://data/raven/rm_vs_01_content.json")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var segment := {"index": 27, "segmentTop": 3, "segmentBottom": 5, "rows": 2, "spawn": false}
	var clip: Rect2 = FrameVisuals.clip_for_motion(segment, 6, 6, Vector2(50, 50), 3.0)
	assert(clip.position == Vector2(159, 159))
	assert(clip.size == Vector2(50, 156))
	assert(clip.position.y > 2 * 53.0, "Clip must exclude blocker row")
	assert(clip.end.y <= 6.0 * 53.0, "Clip must not spill off board")
	assert(FrameVisuals.clip_for_motion({"index": -1}, 6, 6, Vector2(50, 50), 3.0) == Rect2())
	assert(FrameVisuals.clip_for_motion({"index": 6, "segmentTop": 2, "segmentBottom": 4}, 6, 6, Vector2(50, 50), 3.0) == Rect2(), "Motion outside authored segment must be rejected")
	assert(FrameVisuals.cleared_indices({"cleared": [7, 8, 7, -1, 100]}, 36) == [7, 8])
	assert(FrameVisuals.impact_color("flash-row", "special") != FrameVisuals.impact_color("insight", "special"))
	assert(FrameVisuals.phase_feedback({"phase": "clear", "cascade": 3}, {"chain": "Комбо"}) == "Комбо ×3")
	assert(FrameVisuals.phase_feedback({"phase": "reshuffle"}, {"reshuffle": "Мешаем"}) == "Мешаем")

	var game := Game.new(Content.data.levels[0])
	var host := Control.new()
	host.size = Vector2(390, 844)
	root.add_child(host)
	var board := Board.new()
	host.add_child(board)
	board.setup(game, RavenSkin.placeholder())
	await process_frame

	# The original UPDS motion layer must honor exactly the segment passed by
	# the donor game; this tests a blocked/hole-separated lower column.
	board.motion_layer.automatic_motion_enabled = false
	var moving := segment.duplicate()
	moving["clipRect"] = clip
	board.motion_layer.animate_tile(board.stacks[27], moving, 0.3)
	assert(board.motion_layer._motions.size() == 1)
	var clip_node := board.motion_layer.get_node("SettleMotionClip_27") as Control
	assert(clip_node.clip_contents)
	assert(clip_node.position == clip.position and clip_node.size == clip.size)
	board.motion_layer.advance_motions(0.3)
	assert(board.motion_layer._motions.is_empty())
	assert(board.stacks[27].visible)

	# Real special kinds are owned by UPDS. We only draw temporary feedback.
	game.specials[7] = "flash-row"
	var sample := {"phase": "clear", "feedback": "special", "cascade": 1,
		"cleared": [7, 8, 7], "specials": game.specials.duplicate()}
	board._show_clear_impacts(sample)
	assert(board.impact_layer.get_child_count() == 2)
	var effect := board.impact_layer.get_node("ClearImpact_7") as ColorRect
	assert(effect.mouse_filter == Control.MOUSE_FILTER_IGNORE)
	assert(effect.color == FrameVisuals.impact_color("flash-row", "special"))
	assert((effect.get_child(0) as Label).text == str(RavenSkin.SPECIAL_BADGES["flash-row"]))
	board._clear_impacts()
	assert(board.impact_layer.get_child_count() == 0)
	game.specials[7] = ""

	# Exercise an actual two-special combo's full UPDS swap/clear/settle
	# snapshots through the shared presenter, not a fabricated game result.
	game.specials[7] = "flash-row"
	game.specials[8] = "flash-column"
	board._paint_live()
	var combo: Dictionary = game.attempt_swap(7, 8)
	assert(bool(combo.get("valid", false)))
	assert(bool(combo.get("specialsCombined", false)))
	var saw_clear := false
	var saw_settle := false
	for frame in combo.get("frames", []):
		if str(frame.get("phase", "")) == "clear":
			saw_clear = true
		if str(frame.get("phase", "")) == "settle":
			saw_settle = true
			for motion in frame.get("motions", []):
				var bounds: Rect2 = FrameVisuals.clip_for_motion(motion,
					int(game.level_data.columns), int(game.level_data.rows), Vector2(50, 50), 3.0)
				assert(bounds.has_area(), "Each UPDS settle motion needs a valid isolated column segment")
	assert(saw_clear and saw_settle)
	board.motion_layer.automatic_motion_enabled = true
	await board._play_result(combo, 7, 8)
	assert(board.impact_layer.get_child_count() == 0)
	assert(board.motion_layer._motions.is_empty())
	assert(not board.input_locked)

	# Reduced-motion board uses authoritative final UPDS frames without
	# transient overlays or delays; no second campaign reward source exists.
	var another := Game.new(Content.data.levels[0])
	var reduced_board := Board.new()
	host.add_child(reduced_board)
	reduced_board.setup(another, RavenSkin.placeholder())
	reduced_board.reduced_motion = true
	var hint: Dictionary = another.get_hint_move()
	assert(not hint.is_empty())
	var move: Dictionary = another.attempt_swap(int(hint.first), int(hint.second))
	assert(bool(move.get("valid", false)))
	reduced_board._play_result(move, int(hint.first), int(hint.second))
	assert(reduced_board.impact_layer.get_child_count() == 0)
	assert(not reduced_board.input_locked)
	host.queue_free()
	print("Raven Manor UPDS special-impact and blocker-segment settle smoke passed.")
	quit()
