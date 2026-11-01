extends SceneTree
## VNS5-04A — headless, source-immutable native stage orientation/templates/undo smoke.
const Layout = preload("res://addons/vn_studio/model/stage_layout_tools.gd")
const Studio = preload("res://addons/vn_studio/editor/raven_stage_designer.gd")
const Store = preload("res://addons/vn_studio/editor/raven_story_store.gd")


func _initialize() -> void:
	call_deferred("_run")


func _sample(count: int) -> Dictionary:
	var cast: Array = []
	for i in range(count):
		cast.append({"characterId": "RM-CHAR-EXAMPLE-%d" % i, "slot": "center", "pose": "neutral", "emotion": "neutral", "x": 0.27, "y": 0.64, "assetId": "keep-%d" % i})
	return {"sceneId": "RM-SYNTHETIC", "cast": cast, "visibleCount": count, "backgroundId": "BG-HALL"}


func _run() -> void:
	assert(Layout.reference_size("portrait") == Vector2(390, 844))
	assert(Layout.reference_size("landscape") == Vector2(844, 390))
	assert(Layout.reference_size("unknown") == Vector2(390, 844))
	for orientation in ["portrait", "landscape"]:
		for count in [1, 2, 3]:
			var original: Dictionary = _sample(count)
			var before: Dictionary = original.duplicate(true)
			var next: Dictionary = Layout.apply_template(original, orientation)
			assert(original == before, "Template must not mutate caller data")
			assert(next["sceneId"] == before["sceneId"] and next["backgroundId"] == before["backgroundId"])
			assert(next["cast"].size() == count and next["visibleCount"] == count)
			assert(next["cast"][0]["assetId"] == before["cast"][0]["assetId"])
			for actor: Dictionary in next["cast"]:
				assert(float(actor["x"]) >= 0.0 and float(actor["x"]) <= 1.0)
				assert(float(actor["y"]) >= 0.0 and float(actor["y"]) <= 1.0)
		assert(Layout.template_points(0, orientation).is_empty())
		assert(Layout.template_points(4, orientation).is_empty())
	var view := Vector2(844, 390)
	for count in [1, 2, 3]:
		for x in [0.0, 0.15, 0.5, 0.85, 1.0]:
			var original := Vector2(x, 0.7)
			var pixels: Vector2 = Layout.landscape_position(view, count, original)
			var restored: Vector2 = Layout.landscape_normalized(view, count, pixels)
			assert(restored.distance_to(original) < 0.0001, "Normalized landscape coordinates must roundtrip")
			assert(pixels.x >= 0 and pixels.y >= 0)
			assert(pixels.x + Layout.actor_size(view, count).x <= view.x + 0.01)

	var root_path: String = ProjectSettings.globalize_path("res://")
	var production_path: String = root_path.path_join(Store.STAGING)
	var original_sha: String = FileAccess.get_sha256(production_path)
	var project: Dictionary = Store.open_project(root_path)
	assert(project.get("ok", false), str(project.get("error", "")))
	var scene_id: String = str(project["shots"].keys()[0])
	var ui := Studio.new()
	root.add_child(ui)
	ui.set_scene(project, {}, scene_id)
	assert(ui._canvas.custom_minimum_size == Vector2(390, 844))
	ui._on_orientation(1)
	assert(ui._preview_orientation == "landscape")
	assert(ui._canvas.custom_minimum_size == Vector2(844, 390))
	assert(ui._overlay.reference_size == Vector2(844, 390))
	ui._on_background_fit(1)
	assert(ui._bg_image.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
	ui._on_safe_toggle(true)
	assert(ui._overlay.show_safe)
	ui._on_orientation(0)
	assert(ui._canvas.custom_minimum_size == Vector2(390, 844))
	assert(ui._stage_data == Store.effective_stage(project, {}, scene_id), "Preview mode must never modify source draft")
	var spec: Dictionary = Store.stage_options(project)["actors"]
	var ids: Array = spec.keys()
	assert(ids.size() >= 2)
	var stage: Dictionary = Store.effective_stage(project, {}, scene_id)
	var two: Array = []
	for i in [0, 1]:
		var id: String = str(ids[i])
		two.append({"characterId": id, "slot": "center", "pose": str(spec[id]["poses"][0]),
			"emotion": str(spec[id]["emotions"][0]), "micro": "", "x": 0.5, "y": 0.5})
	stage["cast"] = two
	stage["visibleCount"] = 2
	assert(Store.validate_stage(project, stage).is_empty(), "Synthetic pair must be legal stage-v1")
	ui._stage_data = stage.duplicate(true)
	ui._committed_stage = stage.duplicate(true)
	ui._reload()
	ui._on_template()
	assert(ui._undo_stages.size() == 1)
	assert(ui._stage_data != stage)
	assert(Store.validate_stage(project, ui._stage_data).is_empty())
	ui._on_undo()
	assert(ui._stage_data == stage)
	assert(ui._undo_stages.is_empty())
	assert(FileAccess.get_sha256(production_path) == original_sha)
	ui.queue_free()
	print("Raven VN Studio VNS5-04A orientation/template/undo smoke passed")
	quit()
