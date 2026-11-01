extends SceneTree
## VNS5-05A: synthetic editor-only micro-FX + no-loss sidecar contract.
const Store = preload("res://addons/vn_studio/editor/raven_story_store.gd")
const StageFx = preload("res://addons/vn_studio/model/stage_fx_store.gd")
const StageV2 = preload("res://addons/vn_studio/model/stage_v2_store.gd")
const Designer = preload("res://addons/vn_studio/editor/raven_stage_designer.gd")

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
	designer.queue_free()
	assert(FileAccess.get_sha256(staging_path) == staging_sha)
	assert(FileAccess.get_sha256(source_path) == source_sha)
	print("Raven VN Studio VNS5-05A micro-FX timeline safety smoke passed")
	quit()
