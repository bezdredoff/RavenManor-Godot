extends SceneTree

const Paging = preload("res://scripts/shared/upds/dialogue_paging.gd")
const SourceCases = preload("res://tests/raven/upds_paging_parity_cases.json")
const RavenMatch3 = preload("res://scripts/raven/raven_match3_game.gd")
const UpdsMatch3 = preload("res://scripts/shared/upds/match3_game.gd")
const LevelBridge = preload("res://scripts/raven/upds_match3_campaign_adapter.gd")
const RavenCopy = preload("res://scripts/raven/raven_production_localization.gd")
const SourceLevels = preload("res://data/raven/rm_vs_01_content.json")


func _initialize() -> void:
	# These three RU/BE/EN cases are byte-for-byte expectations from UPDS.
	for entry: Dictionary in SourceCases.data.cases:
		var fits := func(candidate: String) -> bool: return candidate.length() <= int(entry.budget)
		var sentences: Array[String] = []
		sentences.assign(entry.sentences)
		var pages := Paging.paginate(str(entry.text), fits, str(entry.locale), sentences)
		assert(pages == entry.pages, "UPDS paging parity failed: " + str(entry.id))
		for index in pages.size():
			assert(Paging.continuation(pages[index], index < pages.size() - 1) == entry.displayed[index])

	# Raven only owns the level-content conversion. UPDS owns board rules.
	for source: Dictionary in SourceLevels.data.levels:
		var normalized := LevelBridge.normalize(source)
		assert(normalized.activeTiles == source.tiles)
		assert(normalized.objectives.size() == 1)
		assert(normalized.objectives[0].target == source.objective.target)
		var upds := UpdsMatch3.new(normalized)
		var raven := RavenMatch3.new(source)
		assert(upds.tiles == raven.tiles, "Raven must preserve UPDS's seeded initial board")
		assert(upds.moves_left == raven.moves_left)
		assert(upds.specials == raven.specials)
		assert(upds.blocker_layers == raven.blocker_layers)
		assert(upds.find_matches().is_empty())
		var move := raven.get_hint_move()
		assert(move.size() == 2, "Raven's legacy hint API must remain stable")
		var a := raven.attempt_swap(int(move.first), int(move.second))
		var b := upds.attempt_swap(int(move.first), int(move.second))
		assert(a.valid == b.valid)
		assert(a.cascades == b.cascades)
		assert(raven.tiles == upds.tiles, "Raven's board after a swap must match UPDS's")

	# Audio and locale data now use UPDS PlayerPreferences, preserving the
	# existing Raven user://raven_language.cfg file and Russian default.
	var path := "user://raven_upds_reuse_test.cfg"
	var preferences := RavenCopy.new(path)
	assert(preferences.set_locale("be") == OK)
	assert(preferences.update_audio({"musicVolume": 0.52, "effectsVolume": 0.8, "muted": false}) == OK)
	var reloaded := RavenCopy.new(path)
	assert(reloaded.locale == "be")
	assert(is_equal_approx(float(reloaded.audio.musicVolume), 0.52))
	assert(reloaded.set_locale("invalid") == ERR_INVALID_PARAMETER)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("Raven Manor UPDS core reuse smoke passed (paging RU/BE/EN, board parity, audio/locale persistence).")
	quit()
