extends SceneTree
## VNS5-05B phase 2: reviewed-only FX contract, shared VN and Hall Tea presentation.
## Scene/line clocks must be distinct; editor draft, campaign and source JSON immutable.
const FX = preload("res://scripts/raven/raven_vn_fx_runtime.gd")
const GameVN = preload("res://scripts/raven/raven_vn_game_view.gd")
const TeaScene = preload("res://scenes/raven/hall_tea_vn.tscn")
const Story = preload("res://data/raven/production/season1_dialogue_catalog.json")
const FxCatalog = preload("res://scripts/raven/raven_vn_fx_catalog.gd")
const MathFx = preload("res://scripts/shared/vn/micro_fx_math.gd")

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
	var live: Dictionary = FxCatalog.reviewed_for_scene("RM-BEAT-02-01")
	assert(not live.is_empty() and live["cues"].size() == 4,
		"Live Hall Tea FX must be a minimal, explicit, reviewed resource")
	assert(FxCatalog.reviewed_for_scene("RM-BEAT-00-01").is_empty(),
		"Never animate unrelated story scenes from local Studio drafts")
	assert(live["cues"][0]["loop"] == true)
	var live_runtime := FX.new()
	var load_error: String = live_runtime.configure("RM-BEAT-02-01", ids,
		["RM-CHAR-EVELYN", "RM-CHAR-ADA"], live)
	assert(load_error.is_empty(), "Preloaded approved JSON FX must validate: " + load_error)
	assert(live_runtime.enter_line("RM-BEAT-02-01", first))
	var live_entry: Dictionary = live_runtime.step(0.0)
	assert(live_entry["actor/RM-CHAR-EVELYN"]["offset"].x < -40.0)
	assert(float(live_entry["actor/RM-CHAR-EVELYN"]["alpha"]) < 0.01)
	assert(live_entry["actor/RM-CHAR-ADA"]["offset"].x > 40.0)
	var live_end: Dictionary = live_runtime.step(1.05)
	assert(live_end["actor/RM-CHAR-EVELYN"]["offset"] == Vector2.ZERO)
	assert(float(live_end["actor/RM-CHAR-EVELYN"]["alpha"]) == 1.0)
	# The old runtime clock stopped at 20s. Loop must not freeze after it.
	live_runtime.step(20.0)
	var live_after_twenty: Dictionary = live_runtime.step(2.1)
	assert(live_after_twenty["actor/RM-CHAR-EVELYN"]["scale"].y !=
		live_end["actor/RM-CHAR-EVELYN"]["scale"].y,
		"Breath must still evolve after 20 seconds")
	assert(live_runtime.enter_line("RM-BEAT-02-01", second))
	var live_second: Dictionary = live_runtime.step(0.25)
	assert(live_second["actor/RM-CHAR-EVELYN"]["offset"] == Vector2.ZERO,
		"First-line entrance must not recur on later dialogue")
	assert(live_runtime.step(0.0, false, true).is_empty(),
		"Reduced motion must suppress reviewed loops and slides")
	var invalid_fraction: Dictionary = live.duplicate(true)
	invalid_fraction["cues"][0]["durationMs"] = 1600.5
	assert(not live_runtime.configure("RM-BEAT-02-01", ids,
		["RM-CHAR-EVELYN", "RM-CHAR-ADA"], invalid_fraction).is_empty(),
		"Fractional JSON milliseconds must still fail closed")
	var bad_loop: Dictionary = live.duplicate(true)
	bad_loop["cues"][0]["loop"] = "yes"
	assert(not live_runtime.configure("RM-BEAT-02-01", ids,
		["RM-CHAR-EVELYN", "RM-CHAR-ADA"], bad_loop).is_empty())
	assert(not live_runtime.configured(), "Malformed approval must be fail-closed")
	bad_loop = live.duplicate(true)
	bad_loop["cues"][0]["effect"] = "hop"
	assert(not live_runtime.configure("RM-BEAT-02-01", ids,
		["RM-CHAR-EVELYN", "RM-CHAR-ADA"], bad_loop).is_empty())
	bad_loop = live.duplicate(true)
	bad_loop["cues"][2]["targetType"] = "background"
	bad_loop["cues"][2]["targetId"] = "background"
	assert(not live_runtime.configure("RM-BEAT-02-01", ids,
		["RM-CHAR-EVELYN", "RM-CHAR-ADA"], bad_loop).is_empty())
	for effect in ["slide_in_left", "slide_in_right", "slide_out_left", "slide_out_right", "hop"]:
		var synthetic: Dictionary = live.duplicate(true)
		synthetic["cues"][2]["effect"] = effect
		assert(FX.EFFECTS.has(effect))
		assert(live_runtime.configure("RM-BEAT-02-01", ids,
			["RM-CHAR-EVELYN", "RM-CHAR-ADA"], synthetic).is_empty())
	var exit_cue: Dictionary = live["cues"][2].duplicate(true)
	exit_cue["effect"] = "slide_out_left"
	exit_cue["phase"] = "exit"
	assert(MathFx.sample_reviewed(exit_cue, 1500)["offset"].x < -40.0)
	assert(MathFx.sample_reviewed(exit_cue, 1500)["alpha"] == 0.0,
		"Exit must hold the hidden end pose")
	var fade_exit: Dictionary = {"effect": "fade_out", "phase": "exit",
		"startMs": 0, "durationMs": 500, "repeat": 1, "intensity": 1.0}
	assert(MathFx.sample_reviewed(fade_exit, 800)["alpha"] == 0.0)
	assert(MathFx.sample(fade_exit, 800)["alpha"] == 1.0,
		"Legacy sampler must keep its old neutral-after-cue semantics")
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
	assert(frame["background/background"]["scale"].x > 1.0,
		"Scene-wide cue keeps its clock when changing lines")
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
	assert(game.configure_reviewed_fx("RM-BEAT-02-01", ids, live).is_empty())
	game.set_fx_accessibility(false)
	game.show_beat("RM-BEAT-02-01", "Evelyn", "synthetic", "1/12", Callable(), first)
	game._process(0.0)
	var evelyn_x: float = 0.0
	var evelyn_visual: Control = null
	for cast in game.actors:
		if cast["characterId"] == "RM-CHAR-EVELYN":
			evelyn_visual = cast["node"]
			evelyn_x = evelyn_visual.position.x
			break
	assert(evelyn_visual != null, "Canonical production portrait must be present")
	game._process(0.75)
	assert(evelyn_visual.position.x > evelyn_x, "Shared VN must render approved enter motion")
	game.set_fx_accessibility(true)
	assert(evelyn_visual.modulate.a == 1.0, "Reduced motion immediately restores portrait")
	game.clear_reviewed_fx()
	game.queue_free()
	await process_frame
	var tea := TeaScene.instantiate()
	root.add_child(tea)
	await process_frame
	assert(tea._fx.configured(), "Playable Hall Tea scene must auto-load reviewed res:// FX")
	# Earlier settings tests may persist reducedMotion in user://. Explicitly
	# choose normal playback for the visual checks; separately assert that the
	# live user preference is honored and motion can be suppressed below.
	tea.set_fx_accessibility(false)
	tea._process(0.0)
	assert(tea.actor_left.position.x < -tea.size.x * 0.20 - 40.0,
		"Live Hall Tea should begin with Evelyn entering from the left")
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
