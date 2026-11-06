extends SceneTree
## VNS5-05A: synthetic editor-only micro-FX + no-loss sidecar contract.
const Store = preload("res://addons/vn_studio/editor/raven_story_store.gd")
const StageFx = preload("res://addons/vn_studio/model/stage_fx_store.gd")
const StageV2 = preload("res://addons/vn_studio/model/stage_v2_store.gd")
const Designer = preload("res://addons/vn_studio/editor/raven_stage_designer.gd")
const Timeline = preload("res://addons/vn_studio/editor/raven_fx_timeline.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var root_path: String = ProjectSettings.globalize_path("res://")
	var staging_path: String = root_path.path_join(Store.STAGING)
	var source_path: String = root_path.path_join(Store.RELATIVE)
	var staging_sha: String = FileAccess.get_sha256(staging_path)
	var source_sha: String = FileAccess.get_sha256(source_path)
	var project: Dictionary = Store.open_project(root_path)
	assert(project.get("ok", false), str(project.get("error", "")))
	var scene_id: String = str(project["shots"].keys()[0])
	var draft: Dictionary = Store.fresh(project)
	draft.erase("stageFxPatches") # existing saved v1/v2 Raven drafts stay valid
	assert(Store.validate(project, draft).is_empty())
	var stage: Dictionary = Store.effective_stage(project, draft, scene_id)
	var v2: Dictionary = StageV2.fresh(scene_id)
	var fx: Dictionary = StageFx.fresh(scene_id)
	assert(StageFx.validate(stage, v2, fx).is_empty())
	fx = StageFx.new_cue(fx, "background", "background")
	fx["cues"][0]["effect"] = "pulse"
	fx["cues"][0]["startMs"] = 250
	fx["cues"][0]["durationMs"] = 500
	fx["cues"][0]["repeat"] = 2
	fx["cues"][0]["intensity"] = 0.125 + float(Time.get_ticks_usec() % 4000) / 100000.0
	assert(StageFx.validate(stage, v2, fx).is_empty())
	assert(StageFx.sample(fx["cues"][0], 0)["scale"] == Vector2.ONE)
	assert(StageFx.sample(fx["cues"][0], 500)["scale"].x > 1.0)
	assert(StageFx.sample(fx["cues"][0], 2000)["scale"] == Vector2.ONE)
	assert(StageFx.sample(fx["cues"][0], 500) == StageFx.sample(fx["cues"][0], 500))
	# VNS5-07F5: three phase presets use legacy v1 FX and remain editor-only.
	var phases: Dictionary = StageFx.fresh(scene_id)
	for phase in StageFx.PHASES:
		phases = StageFx.new_phase_cue(phases, "background", "background", phase)
	assert(StageFx.validate(stage, v2, phases).is_empty())
	assert(phases["cues"].size() == 3)
	assert(phases["cues"][0]["phase"] == "enter")
	assert(phases["cues"][1]["phase"] == "idle")
	assert(phases["cues"][2]["phase"] == "exit")
	var json_roundtrip: Dictionary = JSON.parse_string(JSON.stringify(phases))
	assert(StageFx.validate(stage, v2, json_roundtrip).is_empty(),
		"Integer millisecond values must remain valid after JSON save/reload")
	var fractional: Dictionary = json_roundtrip.duplicate(true)
	fractional["cues"][0]["startMs"] = 27.5
	assert(not StageFx.validate(stage, v2, fractional).is_empty(),
		"Fractional milliseconds must still fail closed")
	assert(float(StageFx.sample(phases["cues"][0], 0)["alpha"]) < 0.01)
	assert(float(StageFx.sample(phases["cues"][0], 900)["alpha"]) == 1.0)
	assert(float(StageFx.sample(phases["cues"][2], 9000)["alpha"]) < 0.01)
	assert(StageFx.sample(phases["cues"][1], 900)["scale"] == Vector2.ONE)
	var invalid_phase: Dictionary = phases.duplicate(true)
	invalid_phase["cues"][0]["phase"] = "execute_code"
	assert(not StageFx.validate(stage, v2, invalid_phase).is_empty())
	# VNS5-07F: one-click character presets reuse validated micro-FX.
	var portrait_scene: String = ""
	var portrait_stage: Dictionary = {}
	for candidate_id in project["shots"].keys():
		var candidate_stage: Dictionary = Store.effective_stage(project, draft, str(candidate_id))
		if not candidate_stage.get("cast", []).is_empty():
			portrait_scene = str(candidate_id)
			portrait_stage = candidate_stage
			break
	assert(not portrait_scene.is_empty(), "Need a staged actor for FX presets")
	var portrait_id: String = str(portrait_stage["cast"][0]["characterId"])
	var portrait_fx: Dictionary = StageFx.fresh(portrait_scene)
	for name in StageFx.ACTOR_PRESETS:
		portrait_fx = StageFx.new_actor_preset(portrait_fx, portrait_id, str(name))
	assert(portrait_fx["cues"].size() == StageFx.ACTOR_PRESETS.size())
	assert(StageFx.validate(portrait_stage, StageV2.fresh(portrait_scene), portrait_fx).is_empty())
	assert(portrait_fx["cues"][0]["targetId"] == portrait_id)
	assert(portrait_fx["cues"][0]["phase"] == "enter")
	assert(portrait_fx["cues"][1]["phase"] == "exit")
	assert(portrait_fx["cues"][2]["effect"] == "breathe")
	assert(portrait_fx["cues"][3]["effect"] == "shake")
	var breath: Dictionary = portrait_fx["cues"][2]
	assert(breath["loop"] == true)
	assert(StageFx.sample(breath, 8400)["scale"] == StageFx.sample(breath, 400)["scale"],
		"Idle breathing must continue beyond its original five repetitions")
	assert(StageFx.sample(breath, 8400)["scale"].y > 1.0)
	var legacy_breath: Dictionary = breath.duplicate(true)
	legacy_breath.erase("loop")
	assert(StageFx.sample(legacy_breath, 8400)["scale"] == Vector2.ONE,
		"Saved legacy repeat-limited breathing must stay unchanged")
	var invalid_loop: Dictionary = portrait_fx.duplicate(true)
	invalid_loop["cues"][2]["loop"] = "true"
	assert(not StageFx.validate(portrait_stage, StageV2.fresh(portrait_scene), invalid_loop).is_empty())
	invalid_loop = portrait_fx.duplicate(true)
	invalid_loop["cues"][2]["effect"] = "shake"
	assert(not StageFx.validate(portrait_stage, StageV2.fresh(portrait_scene), invalid_loop).is_empty())
	invalid_loop = portrait_fx.duplicate(true)
	invalid_loop["cues"][2]["targetType"] = "background"
	invalid_loop["cues"][2]["targetId"] = "background"
	assert(not StageFx.validate(portrait_stage, StageV2.fresh(portrait_scene), invalid_loop).is_empty())
	var slide_left: Dictionary = portrait_fx["cues"][6]
	var slide_right: Dictionary = portrait_fx["cues"][7]
	var exit_left: Dictionary = portrait_fx["cues"][8]
	var exit_right: Dictionary = portrait_fx["cues"][9]
	var hop: Dictionary = portrait_fx["cues"][10]
	assert(slide_left["effect"] == "slide_in_left" and slide_left["phase"] == "enter")
	assert(StageFx.sample(slide_left, -1)["offset"] == Vector2.ZERO)
	assert(StageFx.sample(slide_left, 0)["offset"].x < -40.0)
	assert(float(StageFx.sample(slide_left, 0)["alpha"]) < 0.01)
	assert(StageFx.sample(slide_left, 900)["offset"] == Vector2.ZERO)
	assert(StageFx.sample(slide_right, 0)["offset"].x > 40.0)
	assert(StageFx.sample(exit_left, 0)["offset"] == Vector2.ZERO)
	assert(StageFx.sample(exit_left, 2800)["offset"].x < -40.0)
	assert(float(StageFx.sample(exit_left, 2800)["alpha"]) < 0.01)
	assert(StageFx.sample(exit_right, 2800)["offset"].x > 40.0)
	assert(hop["effect"] == "hop" and StageFx.sample(hop, 560)["offset"].y < -10.0)
	assert(StageFx.sample(hop, 900)["offset"] == Vector2.ZERO)
	var invalid_motion: Dictionary = portrait_fx.duplicate(true)
	invalid_motion["cues"][6]["targetType"] = "background"
	invalid_motion["cues"][6]["targetId"] = "background"
	assert(not StageFx.validate(portrait_stage, StageV2.fresh(portrait_scene), invalid_motion).is_empty(),
		"Motion cues must never animate a background or staged prop")
	assert(StageFx.sample(portrait_fx["cues"][0], 0)["alpha"] < 0.01)
	assert(is_equal_approx(float(StageFx.sample(portrait_fx["cues"][0], 850)["alpha"]), 1.0))
	assert(StageFx.sample(portrait_fx["cues"][1], 3000)["alpha"] < 0.01,
		"Editor exit preset must stay hidden after its fade")
	assert(StageFx.sample(portrait_fx["cues"][2], 400)["scale"].y > 1.0)
	assert(StageFx.sample(portrait_fx["cues"][3], 600)["offset"] != Vector2.ZERO)
	assert(StageFx.new_actor_preset(portrait_fx, portrait_id, "unknown") == portrait_fx)
	assert(StageFx.validate(portrait_stage, StageV2.fresh(portrait_scene),
		JSON.parse_string(JSON.stringify(portrait_fx))).is_empty())
	# Old cues do not gain phase and keep the exact legacy preview.
	assert(not fx["cues"][0].has("phase"))
	assert(StageFx.phase_of(fx["cues"][0]) == "idle")
	# The new timeline renders bounded bars without modifying draft data.
	var timeline := Timeline.new()
	root.add_child(timeline)
	timeline.size = Vector2(600, 202)
	timeline.set_timeline(phases["cues"], 0, 8000, "")
	assert(timeline._hit_cue(timeline._bar_rect(phases["cues"][0]).get_center()) == 0)
	assert(timeline._hit_cue(timeline._bar_rect(phases["cues"][2]).get_center()) == 2)
	assert(timeline._time_for_x(timeline._x_for_time(4000)) == 4000)
	var selected: Array[int] = []
	var moved: Array[int] = []
	timeline.cue_selected.connect(func(index: int): selected.append(index))
	timeline.cue_moved.connect(func(index: int, start: int):
		moved.append(index)
		moved.append(start))
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.position = timeline._bar_rect(phases["cues"][2]).get_center()
	click.pressed = true
	timeline._gui_input(click)
	var motion := InputEventMouseMotion.new()
	motion.position = click.position + Vector2(16, 0)
	timeline._gui_input(motion)
	click.pressed = false
	click.position = motion.position
	timeline._gui_input(click)
	assert(selected == [2] and moved.size() == 2 and moved[0] == 2)
	assert(moved[1] > 8000)
	# Keyboard editing follows the same commit signal as drag and leaves data
	# untouched until StageDesigner accepts the cue_moved event.
	timeline.set_timeline(phases["cues"], 2, 8000, "")
	var arrow := InputEventKey.new()
	arrow.pressed = true
	arrow.keycode = KEY_RIGHT
	timeline._gui_input(arrow)
	assert(moved[-2] == 2 and moved[-1] == 8050, "Right arrow must nudge the selected FX cue by 50ms")
	arrow.keycode = KEY_LEFT
	timeline._gui_input(arrow)
	assert(moved[-2] == 2 and moved[-1] == 7950, "Left arrow must nudge the selected FX cue by 50ms")
	# No signal at the start/end of the valid interval, or without selection.
	var near_end: Array = phases["cues"].duplicate(true)
	near_end[2]["startMs"] = 15000
	timeline.set_timeline(near_end, 2, 0, "")
	var count_before: int = moved.size()
	arrow.keycode = KEY_RIGHT
	timeline._gui_input(arrow)
	assert(moved.size() == count_before, "Keyboard nudge must not exceed the FX time limit")
	timeline.set_timeline(phases["cues"], -1, 0, "")
	arrow.keycode = KEY_LEFT
	timeline._gui_input(arrow)
	assert(moved.size() == count_before, "Keyboard nudge requires an explicitly selected cue")
	arrow.pressed = false
	timeline.set_timeline(phases["cues"], 2, 0, "")
	timeline._gui_input(arrow)
	assert(moved.size() == count_before, "Key release must not change a cue")
	timeline.set_timeline(portrait_fx["cues"], 2, 19000, "")
	assert(is_equal_approx(timeline._bar_rect(portrait_fx["cues"][2]).end.x,
		timeline._x_for_time(StageFx.MAX_MS)),
		"Looping cue should be drawn until the end of the visible editor timeline")
	timeline.queue_free()
	var invalid: Dictionary = fx.duplicate(true)
	invalid["cues"].append(invalid["cues"][0].duplicate(true))
	assert(not StageFx.validate(stage, v2, invalid).is_empty())
	invalid = fx.duplicate(true)
	invalid["cues"][0]["targetId"] = "RM-CHAR-NOPE"
	assert(not StageFx.validate(stage, v2, invalid).is_empty())
	invalid = fx.duplicate(true)
	invalid["cues"][0]["durationMs"] = 90000
	assert(not StageFx.validate(stage, v2, invalid).is_empty())
	invalid = fx.duplicate(true)
	invalid["cues"][0]["intensity"] = NAN
	assert(not StageFx.validate(stage, v2, invalid).is_empty())
	invalid = fx.duplicate(true)
	invalid["cues"][0]["script"] = "res://secret"
	assert(not StageFx.validate(stage, v2, invalid).is_empty())
	assert(Store.set_stage_fx(project, draft, fx).is_empty())
	assert(Store.validate(project, draft).is_empty())
	assert(StageFx.effective(draft, scene_id) == fx)
	assert(not Store.export_stage_candidate(project, draft).get("ok", false))
	assert(not Store.export_v2_candidate(project, draft).get("ok", false))
	var export: Dictionary = Store.export_fx_candidate(project, draft)
	assert(export.get("ok", false), str(export.get("error", "")))
	assert(not Store.export_fx_candidate(project, draft).get("ok", false), "FX review must be no-overwrite")
	v2 = StageV2.new_prop(v2)
	assert(Store.set_stage_v2(project, draft, v2).is_empty())
	var with_prop: Dictionary = StageFx.new_cue(fx, "prop", "prop-0001")
	assert(Store.set_stage_fx(project, draft, with_prop).is_empty())
	assert(not Store.set_stage_v2(project, draft, StageV2.fresh(scene_id)).is_empty(), "Removing animated prop blocked")
	assert(FileAccess.get_sha256(staging_path) == staging_sha)
	assert(FileAccess.get_sha256(source_path) == source_sha)
	var designer := Designer.new()
	root.add_child(designer)
	designer.set_scene(project, draft, scene_id)
	assert(designer._fx_data["cues"].size() == 2)
	designer._on_fx_stop()
	designer._on_fx_add()
	assert(designer._fx_data["cues"].size() == 3)
	designer._on_fx_undo()
	assert(designer._fx_data["cues"].size() == 2)
	designer._on_fx_scrub(500)
	assert(designer._bg_image.scale.x > 1.0)
	designer._on_fx_stop()
	# Visible Animation tabs share this real editor instance, not a fake timeline.
	assert(designer._fx_timeline != null)
	designer._on_fx_add_phase("enter")
	assert(designer._fx_data["cues"].size() == 3)
	assert(designer._fx_data["cues"][2]["phase"] == "enter")
	designer._on_fx_undo()
	assert(designer._fx_data["cues"].size() == 2)
	designer._on_fx_add_phase("exit")
	assert(designer._fx_data["cues"][2]["startMs"] == 8000)
	designer._on_timeline_move(2, 8500)
	assert(designer._fx_data["cues"][2]["startMs"] == 8500)
	designer._on_fx_undo()
	assert(designer._fx_data["cues"][2]["startMs"] == 8000)
	designer._on_fx_undo()
	assert(designer._fx_data["cues"].size() == 2)
	# Live native Animation tab uses the same actor preview and undo model.
	designer.set_scene(project, draft, portrait_scene)
	assert(designer._fx_actor_preset_buttons.size() == StageFx.ACTOR_PRESETS.size())
	assert(not designer._fx_actor_preset_buttons[0].disabled)
	var before_presets: int = designer._fx_data["cues"].size()
	designer._on_fx_add_actor_preset("appear")
	assert(designer._fx_data["cues"].size() == before_presets + 1)
	var actor_cue: Dictionary = designer._fx_data["cues"][-1]
	assert(actor_cue["targetType"] == "actor" and actor_cue["targetId"] == portrait_id)
	assert(actor_cue["effect"] == "fade_in" and actor_cue["phase"] == "enter")
	assert(actor_cue.get("lineId", "") == "")
	designer._on_fx_scrub(0)
	assert(designer._cards[0].modulate.a < 0.01, "Appearance starts invisible in editor")
	designer._on_fx_scrub(1000)
	assert(is_equal_approx(designer._cards[0].modulate.a, 1.0))
	designer._on_fx_add_actor_preset("disappear")
	designer._on_fx_scrub(3000)
	assert(designer._cards[0].modulate.a < 0.01, "Exit remains invisible in editor")
	designer._on_fx_undo()
	assert(designer._fx_data["cues"].size() == before_presets + 1)
	designer._on_fx_undo()
	assert(designer._fx_data["cues"].size() == before_presets)
	# The selected Stage actor gets horizontal enter/exit and an isolated hop.
	designer._on_fx_scrub(0)
	var neutral_pos: Vector2 = designer._cards[0].position
	designer._on_fx_add_actor_preset("slide_in_left")
	assert(designer._fx_data["cues"][-1]["effect"] == "slide_in_left")
	designer._on_fx_scrub(0)
	assert(designer._cards[0].position.x < neutral_pos.x - 40.0)
	designer._on_fx_scrub(1000)
	assert(is_equal_approx(designer._cards[0].position.x, neutral_pos.x))
	designer._on_fx_undo()
	designer._on_fx_add_actor_preset("hop")
	designer._on_fx_scrub(560)
	assert(designer._cards[0].position.y < neutral_pos.y - 10.0)
	designer._on_fx_scrub(900)
	assert(is_equal_approx(designer._cards[0].position.y, neutral_pos.y))
	designer._on_fx_undo()
	designer._on_fx_add_actor_preset("breathe")
	assert(designer._fx_data["cues"][-1].get("loop", false))
	assert(designer._fx_loop.button_pressed)
	assert(not designer._fx_loop.disabled)
	designer._on_fx_scrub(8400)
	assert(designer._cards[0].scale.y > 1.0, "Line-idle breathing must continue past eight seconds")
	designer._on_fx_loop(false)
	assert(not designer._fx_data["cues"][-1].has("loop"))
	designer._on_fx_scrub(8400)
	assert(designer._cards[0].scale == Vector2.ONE)
	designer._on_fx_undo()
	assert(designer._fx_data["cues"][-1].get("loop", false))
	designer._on_fx_undo()
	assert(designer._fx_data["cues"].size() == before_presets)
	designer.queue_free()
	assert(FileAccess.get_sha256(staging_path) == staging_sha)
	assert(FileAccess.get_sha256(source_path) == source_sha)
	print("Raven VN Studio VNS5-05A micro-FX timeline safety smoke passed")
	quit()
