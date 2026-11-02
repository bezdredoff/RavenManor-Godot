extends SceneTree
## VNS5-05B phase 2: reviewed-only FX contract, shared VN and Hall Tea presentation.
## Scene/line clocks must be distinct; editor draft, campaign and source JSON immutable.
const FX = preload("res://scripts/raven/raven_vn_fx_runtime.gd")
const GameVN = preload("res://scripts/raven/raven_vn_game_view.gd")
const TeaScene = preload("res://scenes/raven/hall_tea_vn.tscn")
const Story = preload("res://data/raven/production/season1_dialogue_catalog.json")

func _initialize() -> void:
	call_deferred("_run")


func _bundle(scene_id: String, second: String) -> Dictionary:
	return {"format": FX.FORMAT, "schemaVersion": 1, "sceneId": scene_id,
		"approvalStatus": "approved", "approvalRef": "synthetic-smoke-not-production",
		"cues": [
			{"id": "fx-0001", "targetType": "background", "targetId": "background",
				"effect": "pulse", "startMs": 0, "durationMs": 1400, "repeat": 1, "intensity": 1.0},
			{"id": "fx-0002", "targetType": "background", "targetId": "background",
				"lineId": second, "effect": "fade_out", "startMs": 0,
				"durationMs": 1400, "repeat": 1, "intensity": 1.0}
		]}


func _run() -> void:
	var root_path: String = ProjectSettings.globalize_path("res://")
	var files: Array = ["data/raven/production/season1_dialogue_catalog.json",
		"data/raven/production/vn_staging.json", "data/raven/production/character_performance.json"]
	var hashes: Dictionary = {}
	for path in files:
		hashes[path] = FileAccess.get_sha256(root_path.path_join(path))
	var ids: Array = []
	for entry: Dictionary in Story.data.entries:
		if str(entry.get("sceneId", "")) == "RM-BEAT-02-01":
			ids.append(str(entry["id"]))
	assert(ids.size() == 12)
	var first: String = str(ids[0])
	var second: String = str(ids[1])
	var bundle: Dictionary = _bundle("RM-BEAT-02-01", second)
	var runtime := FX.new()
	assert(runtime.configure("RM-BEAT-02-01", ids, ["RM-CHAR-EVELYN", "RM-CHAR-ADA"], bundle).is_empty())
	assert(runtime.enter_line("RM-BEAT-02-01", first))
	var frame: Dictionary = runtime.step(0.35)
	assert(frame["background/background"]["scale"].x > 1.0)
	assert(is_equal_approx(float(frame["background/background"]["alpha"]), 1.0))
	# Same-line render refresh (pagination/locale) does not reset FX line clock.
	assert(runtime.enter_line("RM-BEAT-02-01", first))
	frame = runtime.step(0.35)
	assert(frame["background/background"]["scale"].x > 1.0)
	assert(runtime.enter_line("RM-BEAT-02-01", second))
	frame = runtime.step(0.35)
	assert(float(frame["background/background"]["alpha"]) < 1.0, "L002 fade active")
	assert(is_equal_approx(float(frame["background/background"]["scale"].x), 1.0),
		"Scene-only pulse is finished after 1400ms test time below")
	# Above scene pulse still at 1050ms; replace with explicit finite scene clock assertion.
	var skipped: Dictionary = runtime.step(0.0, true, false)
	assert(skipped.is_empty(), "Skip hides presentation without progression write")
	var reduced: Dictionary = runtime.step(0.0, false, true)
	assert(reduced.is_empty(), "Reduced motion hides presentation")
	assert(not runtime.enter_line("RM-BEAT-99-99", second), "Reject mismatched scene")
	assert(runtime.step(0.5).is_empty(), "Stale line must not animate")
	var invalid: Dictionary = bundle.duplicate(true)
	invalid["approvalStatus"] = "review"
	assert(not runtime.configure("RM-BEAT-02-01", ids, [], invalid).is_empty())
	assert(not runtime.configured(), "Unapproved bundle must disable existing FX")
	invalid = bundle.duplicate(true)
	invalid["runtimeApplied"] = false
	assert(not runtime.configure("RM-BEAT-02-01", ids, [], invalid).is_empty(), "Editor review flags cannot be loaded")
	invalid = bundle.duplicate(true)
	invalid["cues"][1]["lineId"] = "RM-BEAT-00-01-L001"
	assert(not runtime.configure("RM-BEAT-02-01", ids, [], invalid).is_empty())
	invalid = bundle.duplicate(true)
	invalid["cues"][1]["targetType"] = "prop"
	invalid["cues"][1]["targetId"] = "prop-0001"
	assert(not runtime.configure("RM-BEAT-02-01", ids, [], invalid).is_empty(), "No prop renderer")
	invalid = bundle.duplicate(true)
	invalid["cues"][0]["intensity"] = NAN
	assert(not runtime.configure("RM-BEAT-02-01", ids, [], invalid).is_empty())
	invalid = bundle.duplicate(true)
	invalid["cues"][0]["durationMs"] = 90000
	assert(not runtime.configure("RM-BEAT-02-01", ids, [], invalid).is_empty())
	var game := GameVN.new()
	root.add_child(game)
	await process_frame
	assert(game.configure_reviewed_fx("RM-BEAT-02-01", ids, bundle).is_empty())
	game.show_beat("RM-BEAT-02-01", "Evelyn", "synthetic", "1/12", Callable(), first)
	game._process(0.35)
	assert(game.background.scale.x > 1.0, "Shared gameplay VN animates background")
	assert(is_equal_approx(game.background.modulate.a, 1.0))
	game.show_beat("RM-BEAT-02-01", "Ada", "synthetic", "2/12", Callable(), second)
	game._process(0.35)
	assert(game.background.modulate.a < 1.0, "Shared VN changes line cue without saving")
	game.set_fx_accessibility(true)
	assert(game.background.modulate.a == 1.0, "Reduced motion resets visuals immediately")
	game.clear_reviewed_fx()
	assert(game.background.scale == Vector2.ONE)
	game.queue_free()
	await process_frame
	var tea := TeaScene.instantiate()
	root.add_child(tea)
	await process_frame
	assert(tea.configure_reviewed_fx(bundle).is_empty())
	tea._process(0.35)
	assert(tea.background.scale.x > 1.0, "Playable Hall Tea uses reviewed FX")
	tea.line_index = 1
	tea.dialogue_page = 0
	tea._render(true)
	tea._process(0.35)
	assert(tea.background.modulate.a < 1.0, "Hall Tea line transition applies L002 fade")
	tea.set_fx_accessibility(true)
	assert(tea.background.modulate.a == 1.0)
	tea.queue_free()
	await process_frame
	for path in files:
		assert(FileAccess.get_sha256(root_path.path_join(path)) == hashes[path], "Runtime FX mutated source: " + path)
	print("Raven VN VNS5-05B reviewed-only runtime FX presentation smoke passed")
	quit()
