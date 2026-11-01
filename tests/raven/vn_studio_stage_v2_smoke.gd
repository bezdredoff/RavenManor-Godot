extends SceneTree
## VNS5-04B: stage-v2 editor-sidecar, props, focal/z, old draft and no source mutation.
const Store = preload("res://addons/vn_studio/editor/raven_story_store.gd")
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
	var scene: String = str(project["shots"].keys()[0])
	var old_draft: Dictionary = Store.fresh(project)
	old_draft.erase("stageV2Patches") # backward-compatible with existing saved v1 drafts
	assert(Store.validate(project, old_draft).is_empty())
	var original: Dictionary = Store.effective_stage(project, old_draft, scene)
	var stage: Dictionary = StageV2.fresh(scene)
	assert(StageV2.validate(original, stage).is_empty())
	stage["orientation"] = "landscape"
	stage["fitMode"] = "contain"
	stage["focal"] = {"x": 0.13, "y": 0.81}
	stage = StageV2.new_prop(stage)
	# Unique synthetic review ID makes repeat local QA safe without deleting user data.
	stage["props"][0]["label"] = "Smoke_" + str(Time.get_ticks_usec())
	assert(StageV2.validate(original, stage).is_empty())
	assert(StageV2.has_pending_art(stage))
	assert(stage["props"][0]["instanceId"] == "prop-0001")
	var second: Dictionary = StageV2.new_prop(stage)
	assert(second["props"][1]["instanceId"] == "prop-0002")
	assert(stage["props"].size() == 1, "Copy-on-write prop creation required")
	var bad: Dictionary = stage.duplicate(true)
	bad["props"].append(bad["props"][0].duplicate(true))
	assert(not StageV2.validate(original, bad).is_empty(), "Duplicate instance IDs blocked")
	bad = stage.duplicate(true)
	bad["props"][0]["x"] = 1.2
	assert(not StageV2.validate(original, bad).is_empty(), "Out-of-range coordinates blocked")
	bad = stage.duplicate(true)
	bad["props"][0]["assetId"] = "res://private/unsafe.webp"
	assert(not StageV2.validate(original, bad).is_empty(), "Filesystem paths forbidden")
	bad = stage.duplicate(true)
	bad["focal"]["x"] = NAN
	assert(not StageV2.validate(original, bad).is_empty(), "NaN blocked")
	bad = stage.duplicate(true)
	bad["runtimeApproved"] = true
	assert(not StageV2.validate(original, bad).is_empty(), "Unknown v2 fields blocked")
	var draft: Dictionary = Store.fresh(project)
	assert(Store.set_stage_v2(project, draft, stage).is_empty())
	assert(Store.validate(project, draft).is_empty())
	assert(Store.effective_stage(project, draft, scene) == original, "V2 must not modify v1 source")
	assert(StageV2.effective(draft, scene) == stage)
	assert(not Store.export_stage_candidate(project, draft).get("ok", false), "Legacy export must not silently drop v2")
	var review: Dictionary = Store.export_v2_candidate(project, draft)
	assert(review.get("ok", false), str(review.get("error", "")))
	assert(not Store.export_v2_candidate(project, draft).get("ok", false), "No-overwrite review export")
	assert(FileAccess.get_sha256(staging_path) == staging_sha)
	assert(FileAccess.get_sha256(source_path) == source_sha)
	var gui := Designer.new()
	root.add_child(gui)
	gui.set_scene(project, draft, scene)
	assert(gui._stage_v2["orientation"] == "landscape")
	assert(gui._canvas.custom_minimum_size == Vector2(844, 390))
	assert(gui._bg_image.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
	assert(gui._overlay.focal.distance_to(Vector2(0.13, 0.81)) < 0.01)
	gui._on_add_prop()
	assert(gui._stage_v2["props"].size() == 2)
	gui._on_undo_v2()
	assert(gui._stage_v2["props"].size() == 1)
	gui.queue_free()
	assert(FileAccess.get_sha256(staging_path) == staging_sha)
	assert(FileAccess.get_sha256(source_path) == source_sha)
	print("Raven VN Studio VNS5-04B sidecar/focal/prop/z-order safety smoke passed")
	quit()
