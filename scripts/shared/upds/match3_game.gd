extends RefCounted

const CampaignData = preload("res://scripts/raven/upds_match3_campaign_adapter.gd")
const SeededRandom = preload("res://scripts/shared/upds/seeded_random.gd")
const CASCADE_LIMIT := 24
const DEFAULT_LEVEL_ID := "RM-LVL-001"

var level_data: Dictionary
var tiles: Array[String] = []
var specials: Array[String] = []
var blocker_layers: Array[int] = []
var ingredients: Array[String] = []
var moves_left := 0
var collected := 0
var collected_by_tile: Dictionary = {}
var ingredients_dropped: Dictionary = {}
var blockers_cleared := 0
var _last_blockers_cleared := 0
var _last_ingredients_dropped := 0
var _last_cleared := 0
var _last_specials_created := 0
var _last_settle_dropped := 0
var state := "playing"
var _random: RefCounted
var _last_swap: Array[int] = []
var _last_frames: Array[Dictionary] = []

func _init(configured_level: Dictionary = {}) -> void:
	if configured_level.is_empty():
		var bundle := CampaignData.load_bundle()
		level_data = CampaignData.get_level(bundle, DEFAULT_LEVEL_ID)
	else:
		level_data = configured_level.duplicate(true)
	assert(not level_data.is_empty(), "Match-3 level data is unavailable")
	reset()

func reset() -> void:
	_last_frames.clear()
	moves_left = int(level_data.moves)
	collected = 0
	collected_by_tile.clear()
	ingredients_dropped.clear()
	blockers_cleared = 0
	_last_blockers_cleared = 0
	_last_ingredients_dropped = 0
	_last_cleared = 0
	_last_specials_created = 0
	_last_settle_dropped = 0
	state = "playing"
	_random = SeededRandom.new(int(level_data.seed))
	var cell_count := _rows() * _columns()
	tiles.resize(cell_count)
	specials.resize(cell_count)
	blocker_layers.resize(cell_count)
	ingredients.resize(cell_count)
	for index in cell_count:
		tiles[index] = ""
		specials[index] = ""
		blocker_layers[index] = 0
		ingredients[index] = ""
	for blocker: Dictionary in level_data.get("blockers", []):
		blocker_layers[int(blocker.index)] = int(blocker.layers)
	for ingredient: Dictionary in level_data.get("ingredients", []):
		ingredients[int(ingredient.index)] = str(ingredient.kind)
	_fill_initial_board()
	if not _find_resolution_match_groups().is_empty() or not has_available_move():
		_reshuffle_playable_board()
		_last_frames.clear()
	assert(find_matches().is_empty() and has_available_move(), "%s opening board must be playable" % str(level_data.id))
	_sync_primary_collect_count()

func objective_value(objective_index: int) -> int:
	var objectives: Array = level_data.get("objectives", [])
	if objective_index < 0 or objective_index >= objectives.size():
		return 0
	var objective: Dictionary = objectives[objective_index]
	match str(objective.get("kind", "")):
		"collect":
			return int(collected_by_tile.get(str(objective.tile), 0))
		"clearBlockers":
			return blockers_cleared
		"drop":
			return int(ingredients_dropped.get(str(objective.ingredient), 0))
		"dropGroup":
			var total := 0
			for ingredient: String in objective.ingredients:
				total += int(ingredients_dropped.get(ingredient, 0))
			return total
	return 0

func _objectives_complete() -> bool:
	var objectives: Array = level_data.get("objectives", [])
	for index in objectives.size():
		if objective_value(index) < int(objectives[index].target):
			return false
	return not objectives.is_empty()

func _sync_primary_collect_count() -> void:
	collected = 0
	for objective: Dictionary in level_data.get("objectives", []):
		if str(objective.get("kind", "")) == "collect":
			collected = int(collected_by_tile.get(str(objective.tile), 0))
			return

func attempt_swap(first: int, second: int) -> Dictionary:
	_last_frames.clear()
	if state != "playing":
		return {"valid": false, "reason": "finished", "specialsCreated": 0, "specialsCombined": false, "primaryFeedback": null}
	if first == second:
		return {"valid": false, "reason": "same-cell", "specialsCreated": 0, "specialsCombined": false, "primaryFeedback": null}
	if not _are_adjacent(first, second):
		return {"valid": false, "reason": "not-adjacent", "specialsCreated": 0, "specialsCombined": false, "primaryFeedback": null}
	if tiles[first].is_empty() or tiles[second].is_empty():
		return {"valid": false, "reason": "ingredient", "specialsCreated": 0, "specialsCombined": false, "primaryFeedback": null}
	if _is_blocked(first) or _is_blocked(second):
		return {"valid": false, "reason": "blocked", "specialsCreated": 0, "specialsCombined": false, "primaryFeedback": null}
	var same_tile := tiles[first] == tiles[second]
	_swap_tiles(first, second)
	_last_frames.append({"phase": "swap", "tiles": tiles.duplicate(), "specials": specials.duplicate(), "blockers": blocker_layers.duplicate(), "ingredients": ingredients.duplicate(), "swap": [first, second]})
	var groups := find_match_groups()
	var activated: Array[int] = []
	if not specials[first].is_empty():
		activated.append(first)
	if not specials[second].is_empty():
		activated.append(second)
	var combo := _resolve_direct_combo(specials[first], specials[second])
	var creations: Array = [] if same_tile and activated.is_empty() else _find_player_special_creations(groups, first, second)
	var primary_feedback := _classify_player_feedback(groups, activated, creations)
	if groups.is_empty() and activated.is_empty() and combo.is_empty() and creations.is_empty():
		_swap_tiles(first, second)
		return {"valid": false, "reason": "no-match", "specialsCreated": 0, "specialsCombined": false, "primaryFeedback": null, "frames": _last_frames.duplicate(true)}
	moves_left -= 1
	_last_blockers_cleared = 0
	_last_ingredients_dropped = 0
	_last_cleared = 0
	_last_specials_created = 0
	_last_swap = [first, second]
	var cascade := _resolve(_find_resolution_match_groups(), activated, creations, combo, first, second, primary_feedback)
	_last_swap.clear()
	_sync_primary_collect_count()
	var reshuffled := false
	if _objectives_complete():
		state = "won"
	elif moves_left <= 0:
		state = "lost"
	elif not has_available_move():
		reshuffled = _reshuffle_playable_board()
	return {"valid": true, "reason": "", "won": state == "won", "lost": state == "lost", "reshuffled": reshuffled, "cascades": cascade, "cleared": _last_cleared, "blockersCleared": _last_blockers_cleared, "ingredientsDropped": _last_ingredients_dropped, "specialsCreated": _last_specials_created, "specialsCombined": not combo.is_empty(), "primaryFeedback": primary_feedback, "frames": _last_frames.duplicate(true)}

func attempt_special_activation(index: int) -> Dictionary:
	_last_frames.clear()
	if state != "playing": return _empty_move_result("finished")
	if index < 0 or index >= tiles.size() or tiles[index].is_empty(): return _empty_move_result("ingredient")
	if _is_blocked(index): return _empty_move_result("blocked")
	if specials[index].is_empty(): return _empty_move_result("no-special")
	moves_left -= 1
	_last_blockers_cleared = 0
	_last_ingredients_dropped = 0
	_last_cleared = 0
	_last_specials_created = 0
	_last_swap = [index, index]
	var cascade := _resolve([], [index], [], "", index, index, "special")
	_last_swap.clear()
	_sync_primary_collect_count()
	var reshuffled := _update_game_state()
	return {"valid": true, "reason": "", "won": state == "won", "lost": state == "lost", "reshuffled": reshuffled, "cascades": cascade, "cleared": _last_cleared, "blockersCleared": _last_blockers_cleared, "ingredientsDropped": _last_ingredients_dropped, "specialsCreated": _last_specials_created, "specialsCombined": false, "primaryFeedback": "special", "frames": _last_frames.duplicate(true)}

func _empty_move_result(reason: String) -> Dictionary:
	return {"valid": false, "reason": reason, "won": state == "won", "lost": state == "lost", "reshuffled": false, "cascades": 0, "cleared": 0, "blockersCleared": 0, "ingredientsDropped": 0, "specialsCreated": 0, "specialsCombined": false, "primaryFeedback": null}

func _update_game_state() -> bool:
	if _objectives_complete():
		state = "won"
		return false
	elif moves_left <= 0:
		state = "lost"
		return false
	elif not has_available_move():
		return _reshuffle_playable_board()
	return false

func get_hint_move() -> Dictionary:
	var best_score := -1
	var best_moves: Array[Dictionary] = []
	for index in tiles.size():
		for candidate in [index + 1, index + _columns()]:
			var evaluation := _evaluate_swap(index, int(candidate))
			if not bool(evaluation.valid): continue
			var score := _score_hint_evaluation(index, int(candidate), evaluation)
			var hint := {"first": index, "second": int(candidate), "score": score}
			if score > best_score:
				best_score = score
				best_moves = [hint]
			elif score == best_score:
				best_moves.append(hint)
	if best_moves.is_empty(): return {}
	return best_moves[_hint_tie_break_index(best_moves.size())]

func _evaluate_swap(first: int, second: int) -> Dictionary:
	var empty := {"valid": false, "groups": [], "activated": [], "creations": [], "combo": ""}
	if first < 0 or second < 0 or first >= tiles.size() or second >= tiles.size(): return empty
	if first == second or not _are_adjacent(first, second): return empty
	if tiles[first].is_empty() or tiles[second].is_empty() or _is_blocked(first) or _is_blocked(second): return empty
	var original_first := tiles[first]
	_swap_tiles(first, second)
	var groups := find_match_groups()
	var activated: Array[int] = []
	if not specials[first].is_empty(): activated.append(first)
	if not specials[second].is_empty(): activated.append(second)
	var combo := _resolve_direct_combo(specials[first], specials[second])
	var creations: Array = [] if original_first == tiles[first] and activated.is_empty() else _find_player_special_creations(groups, first, second)
	_swap_tiles(first, second)
	if groups.is_empty() and activated.is_empty() and combo.is_empty() and creations.is_empty(): return empty
	return {"valid": true, "groups": groups, "activated": activated, "creations": creations, "combo": combo}

func _score_hint_evaluation(first: int, second: int, evaluation: Dictionary) -> int:
	_swap_tiles(first, second)
	var clear := {}
	for group: Dictionary in evaluation.groups:
		for index in group.indices: clear[int(index)] = true
	for index in evaluation.activated: clear[int(index)] = true
	_expand_special_clear(clear)
	var matched := {}
	for group: Dictionary in evaluation.groups:
		for index in group.indices: matched[int(index)] = true
	var tactical: int = 100 + matched.size() * 4 + evaluation.activated.size() * 90
	for group: Dictionary in evaluation.groups:
		if group.indices.size() >= 4: tactical += 24 + (group.indices.size() - 4) * 8
	var objective_progress := 0
	var completion_bonus := 0
	for objective: Dictionary in level_data.get("objectives", []):
		var objective_index: int = level_data.objectives.find(objective)
		var remaining := maxi(0, int(objective.target) - objective_value(objective_index))
		if remaining == 0: continue
		var useful := 0
		if str(objective.kind) == "collect":
			for index in clear:
				if tiles[int(index)] == str(objective.tile) and not _is_blocked(int(index)): useful += 1
		elif str(objective.kind) == "clearBlockers":
			var affected := {}
			for index in clear:
				var row := int(int(index) / _columns())
				var column := int(index) % _columns()
				for neighbour in [int(index), int(index) - 1, int(index) + 1, int(index) - _columns(), int(index) + _columns()]:
					if neighbour < 0 or neighbour >= tiles.size(): continue
					if abs(int(neighbour / _columns()) - row) + abs(neighbour % _columns() - column) == 1 and blocker_layers[neighbour] > 0: affected[neighbour] = true
			useful = affected.size()
			if mini(remaining, useful) >= remaining and affected.keys().all(func(index: Variant) -> bool: return blocker_layers[int(index)] == 1): completion_bonus += 1
		else:
			var ingredient_keys: Array = [str(objective.ingredient)] if str(objective.kind) == "drop" else objective.ingredients
			for ingredient_index in ingredients.size():
				if not ingredient_keys.has(ingredients[ingredient_index]): continue
				var ingredient_row := int(ingredient_index / _columns())
				var ingredient_column := ingredient_index % _columns()
				for index in clear:
					var clear_index := int(index)
					if clear_index % _columns() != ingredient_column or int(clear_index / _columns()) <= ingredient_row or tiles[clear_index].is_empty() or _is_blocked(clear_index): continue
					if _has_locked_barrier_between(ingredient_index, clear_index): continue
					useful += 1
		if str(objective.kind) == "collect":
			useful = mini(remaining, useful)
			if useful >= remaining: completion_bonus += 1
		elif str(objective.kind) == "clearBlockers":
			useful = mini(remaining, useful)
		objective_progress += useful
	_swap_tiles(first, second)
	return objective_progress * 10000 + completion_bonus * 2000 + tactical

func _has_locked_barrier_between(upper_index: int, lower_index: int) -> bool:
	if upper_index % _columns() != lower_index % _columns() or int(lower_index / _columns()) <= int(upper_index / _columns()): return true
	var column := upper_index % _columns()
	for row in range(int(upper_index / _columns()) + 1, int(lower_index / _columns()) + 1):
		var index := row * _columns() + column
		if _is_active(index) and _is_blocked(index): return true
	return false

func _hint_tie_break_index(candidate_count: int) -> int:
	if candidate_count <= 1: return 0
	var signature := "%s|" % str(level_data.id)
	for index in tiles.size():
		var tile_key := tiles[index] if not tiles[index].is_empty() else "-"
		var ingredient_key := ingredients[index] if not ingredients[index].is_empty() else "-"
		var special_key := specials[index] if not specials[index].is_empty() else "-"
		if index > 0: signature += ";"
		signature += "%s,%s,%d,%s" % [tile_key, ingredient_key, blocker_layers[index], special_key]
	var hash_value: int = 0x811c9dc5
	for byte in signature.to_utf8_buffer():
		hash_value = int((hash_value ^ byte) * 16777619) & 0xffffffff
	if _rows() == 8 and _columns() == 8:
		var bucket := (hash_value >> 8) & 7
		if (0xd1 & (1 << bucket)) == 0: return 0
	else:
		hash_value = int(hash_value ^ (hash_value >> 16))
		hash_value = int(hash_value * 0x7feb352d) & 0xffffffff
		hash_value = int(hash_value ^ (hash_value >> 15))
		hash_value = int(hash_value * 0x846ca68b) & 0xffffffff
		hash_value = int(hash_value ^ (hash_value >> 16)) & 0xffffffff
	return hash_value % candidate_count

func find_matches() -> Array[int]:
	var result: Array[int] = []
	var included := {}
	for group in find_match_groups():
		for index in group.indices:
			included[index] = true
	for index in included:
		result.append(int(index))
	result.sort()
	return result

func find_match_groups() -> Array[Dictionary]:
	var groups: Array[Dictionary] = []
	var rows := _rows()
	var columns := _columns()
	for row in range(rows):
		var start := 0
		while start < columns:
			var index := row * columns + start
			var tile := _matchable_tile(index)
			var end := start + 1
			while not tile.is_empty() and end < columns and _matchable_tile(row * columns + end) == tile:
				end += 1
			if not tile.is_empty() and end - start >= 3:
				var indices: Array[int] = []
				for column in range(start, end):
					indices.append(row * columns + column)
				groups.append({"orientation": "row", "indices": indices})
			start = end
	for column in range(columns):
		var start := 0
		while start < rows:
			var index := start * columns + column
			var tile := _matchable_tile(index)
			var end := start + 1
			while not tile.is_empty() and end < rows and _matchable_tile(end * columns + column) == tile:
				end += 1
			if not tile.is_empty() and end - start >= 3:
				var indices: Array[int] = []
				for row in range(start, end):
					indices.append(row * columns + column)
				groups.append({"orientation": "column", "indices": indices})
			start = end
	return groups

func _find_resolution_match_groups() -> Array[Dictionary]:
	var groups := find_match_groups()
	var rows := _rows()
	var columns := _columns()
	for row in range(rows - 1):
		for column in range(columns - 1):
			var index := row * columns + column
			var tile := _matchable_tile(index)
			if tile.is_empty():
				continue
			if _matchable_tile(index + 1) == tile and _matchable_tile(index + columns) == tile and _matchable_tile(index + columns + 1) == tile:
				groups.append({"orientation": "square", "indices": [index, index + 1, index + columns, index + columns + 1]})
	return groups

func has_available_move() -> bool:
	var columns := _columns()
	for index in tiles.size():
		if index % columns < columns - 1 and _swap_creates_match(index, index + 1):
			return true
		if index + columns < tiles.size() and _swap_creates_match(index, index + columns):
			return true
	return false

func _fill_initial_board() -> void:
	var opening: Array = level_data.get("openingBoard", [])
	if opening.size() == tiles.size():
		for index in tiles.size():
			var cell: Dictionary = opening[index]
			tiles[index] = str(cell.get("tile", ""))
			specials[index] = str(cell.get("special", ""))
			blocker_layers[index] = int(cell.get("blockerLayers", blocker_layers[index]))
			ingredients[index] = str(cell.get("ingredient", ingredients[index]))
		return
	var seeded_opening: Array = level_data.get("seededOpeningBoard", [])
	if seeded_opening.size() == tiles.size():
		for index in tiles.size():
			tiles[index] = str(seeded_opening[index])
		return
	var columns := _columns()
	for index in tiles.size():
		if not _is_active(index) or not ingredients[index].is_empty():
			continue
		var candidates := _shuffled_tile_keys()
		for candidate in candidates:
			var tile := str(candidate)
			tiles[index] = tile
			if not _cell_creates_initial_match(index, columns):
				break
			else:
				tiles[index] = ""
		if tiles[index].is_empty():
			tiles[index] = _random_tile()

func _settle_columns() -> Array[Dictionary]:
	var rows := _rows()
	var columns := _columns()
	var origins: Array[int] = []
	for index in tiles.size(): origins.append(index if not tiles[index].is_empty() or not ingredients[index].is_empty() else -1)
	var dropped := _collect_bottom_ingredients(origins)
	_compact_columns(origins)
	dropped += _collect_bottom_ingredients(origins)
	if dropped > 0: _compact_columns(origins)
	_last_settle_dropped = dropped
	for index in tiles.size():
		if not _is_active(index) or _is_blocked(index): continue
		if tiles[index].is_empty() and ingredients[index].is_empty():
			tiles[index] = _random_tile()
			origins[index] = -1
	var motions: Array[Dictionary] = []
	for index in tiles.size():
		if tiles[index].is_empty() and ingredients[index].is_empty(): continue
		var origin := origins[index]
		var segment_top := _segment_top(index)
		var segment_bottom := _segment_bottom(index)
		if origin < 0:
			motions.append({"index": index, "origin": origin, "spawn": true,
				"rows": maxi(1, int(index / columns) - segment_top + 1),
				"segmentTop": segment_top, "segmentBottom": segment_bottom})
		elif origin != index and int(index / columns) > int(origin / columns):
			motions.append({"index": index, "origin": origin, "spawn": false,
				"rows": int(index / columns) - int(origin / columns),
				"segmentTop": segment_top, "segmentBottom": segment_bottom})
	motions.sort_custom(_anchor_precedes)
	return motions

func _compact_columns(origins: Array[int]) -> void:
	var columns := _columns()
	var rows := _rows()
	for column in columns:
		var segment: Array[int] = []
		for row in rows + 1:
			var index := row * columns + column if row < rows else -1
			if row < rows and not _is_active(index):
				_compact_segment(segment, origins)
				segment.clear()
				continue
			if row < rows and _is_blocked(index):
				_compact_segment(segment, origins)
				segment.clear()
				continue
			if row < rows: segment.append(index)
		_compact_segment(segment, origins)

func _compact_segment(indices: Array[int], origins: Array[int]) -> void:
	if indices.is_empty(): return
	var contents: Array[Dictionary] = []
	for offset in range(indices.size() - 1, -1, -1):
		var source := indices[offset]
		if not tiles[source].is_empty() or not ingredients[source].is_empty():
			contents.append({"tile": tiles[source], "special": specials[source], "ingredient": ingredients[source], "origin": origins[source]})
	for offset in range(indices.size() - 1, -1, -1):
		var target := indices[offset]
		var content_index := indices.size() - 1 - offset
		var item: Dictionary = contents[content_index] if content_index < contents.size() else {}
		tiles[target] = str(item.get("tile", ""))
		specials[target] = str(item.get("special", ""))
		ingredients[target] = str(item.get("ingredient", ""))
		origins[target] = int(item.get("origin", -1))

func _collect_bottom_ingredients(origins: Array[int]) -> int:
	var dropped := 0
	for column in _columns():
		var row := _rows() - 1
		while row >= 0 and not _is_active(row * _columns() + column): row -= 1
		if row < 0: continue
		var index := row * _columns() + column
		if ingredients[index].is_empty(): continue
		var kind := ingredients[index]
		ingredients_dropped[kind] = int(ingredients_dropped.get(kind, 0)) + 1
		ingredients[index] = ""
		tiles[index] = ""
		specials[index] = ""
		origins[index] = -1
		dropped += 1
	return dropped

func _segment_top(index: int) -> int:
	var column := index % _columns()
	var row := int(index / _columns())
	for candidate_row in range(row - 1, -1, -1):
		var candidate := candidate_row * _columns() + column
		if not _is_active(candidate) or _is_blocked(candidate): return candidate_row + 1
	return 0

func _segment_bottom(index: int) -> int:
	var column := index % _columns()
	var row := int(index / _columns())
	for candidate_row in range(row + 1, _rows()):
		var candidate := candidate_row * _columns() + column
		if not _is_active(candidate) or _is_blocked(candidate): return candidate_row - 1
	return _rows() - 1

func _anchor_precedes(first: Dictionary, second: Dictionary) -> bool:
	if first.spawn != second.spawn:
		return bool(first.spawn)
	if first.rows != second.rows:
		return int(first.rows) > int(second.rows)
	return int(first.index) < int(second.index)

func _reshuffle_playable_board() -> bool:
	var tile_indices: Array[int] = []
	var shuffled_tiles: Array = []
	for index in tiles.size():
		if tiles[index].is_empty(): continue
		tile_indices.append(index)
		shuffled_tiles.append(tiles[index])
	for attempt in range(100):
		_shuffle(shuffled_tiles)
		for offset in tile_indices.size():
			tiles[tile_indices[offset]] = str(shuffled_tiles[offset])
			specials[tile_indices[offset]] = ""
		if _find_resolution_match_groups().is_empty() and has_available_move():
			_record_reshuffle_frame()
			return true
	for index in tile_indices:
		tiles[index] = _random_tile()
		specials[index] = ""
	while not _find_resolution_match_groups().is_empty():
		for group: Dictionary in _find_resolution_match_groups():
			var indices: Array = group.indices
			tiles[int(indices.back())] = _random_tile()
	_record_reshuffle_frame()
	return true


func _record_reshuffle_frame() -> void:
	var cascade := int(_last_frames.back().get("cascade", 0)) if not _last_frames.is_empty() else 0
	_last_frames.append({
		"phase": "reshuffle",
		"feedback": "reshuffled",
		"cascade": cascade,
		"tiles": tiles.duplicate(),
		"specials": specials.duplicate(),
		"blockers": blocker_layers.duplicate(),
		"ingredients": ingredients.duplicate(),
		"motions": [],
	})

func _swap_creates_match(first: int, second: int) -> bool:
	if not _are_adjacent(first, second) or tiles[first].is_empty() or tiles[second].is_empty() or _is_blocked(first) or _is_blocked(second):
		return false
	_swap_tiles(first, second)
	var found := not find_matches().is_empty() or not specials[first].is_empty() or not specials[second].is_empty()
	_swap_tiles(first, second)
	return found

func _cell_creates_initial_match(index: int, columns: int) -> bool:
	var row := int(index / columns)
	var column := index % columns
	var tile := tiles[index]
	var horizontal := column >= 2 and tiles[index - 1] == tile and tiles[index - 2] == tile
	var vertical := row >= 2 and tiles[index - columns] == tile and tiles[index - columns * 2] == tile
	var square := row >= 1 and column >= 1 and tiles[index - 1] == tile and tiles[index - columns] == tile and tiles[index - columns - 1] == tile
	return horizontal or vertical or square

func _are_adjacent(first: int, second: int) -> bool:
	if not _is_active(first) or not _is_active(second) or first == second:
		return false
	var columns := _columns()
	var first_row := int(first / columns)
	var second_row := int(second / columns)
	var first_column := first % columns
	var second_column := second % columns
	return abs(first_row - second_row) + abs(first_column - second_column) == 1

func _shuffle(values: Array) -> void:
	for index in range(values.size() - 1, 0, -1):
		var other: int = _random.index(index + 1)
		var previous: Variant = values[index]
		values[index] = values[other]
		values[other] = previous

func _swap_tiles(first: int, second: int) -> void:
	var previous := tiles[first]
	tiles[first] = tiles[second]
	tiles[second] = previous
	var previous_special := specials[first]
	specials[first] = specials[second]
	specials[second] = previous_special

func _resolve(groups: Array[Dictionary], activated: Array[int], creations: Array, combo: String, first: int, second: int, primary_feedback: String) -> int:
	var cascade := 0
	var anchors: Array[int] = [first, second]
	while cascade < CASCADE_LIMIT and (not groups.is_empty() or not activated.is_empty() or (cascade == 0 and not creations.is_empty())):
		cascade += 1
		var by_index := {}
		if cascade == 1:
			for creation in creations:
				by_index[creation.index] = creation
		else:
			for creation in _find_automatic_special_creations(groups, anchors):
				by_index[creation.index] = creation
		var clear := {}
		for group in groups:
			for index in group.indices:
				clear[index] = true
		for index in activated:
			clear[index] = true
		for creation in by_index.values():
			for index in creation.get("consumed", []):
				clear[index] = true
		if cascade == 1 and not combo.is_empty():
			for index in _direct_combo_targets(combo, first, second):
				clear[index] = true
		_expand_special_clear(clear)
		for index in by_index:
			if not activated.has(int(index)):
				clear.erase(index)
		var visible_clear: Array[int] = []
		for index in clear:
			if index >= 0 and index < tiles.size() and not tiles[index].is_empty() and not _is_blocked(index):
				visible_clear.append(int(index))
		visible_clear.sort()
		var feedback := "special" if not activated.is_empty() else "chain" if cascade >= 2 else primary_feedback
		_last_frames.append({"phase": "clear", "feedback": feedback, "cascade": cascade, "tiles": tiles.duplicate(), "specials": specials.duplicate(), "blockers": blocker_layers.duplicate(), "ingredients": ingredients.duplicate(), "cleared": visible_clear})
		for index in clear:
			if index < 0 or index >= tiles.size() or tiles[index].is_empty() or _is_blocked(index):
				continue
			var tile := tiles[index]
			collected_by_tile[tile] = int(collected_by_tile.get(tile, 0)) + 1
			tiles[index] = ""
			specials[index] = ""
			_last_cleared += 1
		_last_blockers_cleared += _damage_blockers(clear)
		for index in by_index:
			if tiles[index].is_empty() or clear.has(index):
				continue
			specials[index] = str(by_index[index].kind)
			_last_specials_created += 1
		var motions := _settle_columns()
		anchors.clear()
		for motion in motions:
			anchors.append(int(motion.index))
		_last_ingredients_dropped += _last_settle_dropped
		_last_frames.append({"phase": "settle", "cascade": cascade, "tiles": tiles.duplicate(), "specials": specials.duplicate(), "blockers": blocker_layers.duplicate(), "ingredients": ingredients.duplicate(), "motions": motions})
		groups = _find_resolution_match_groups()
		activated.clear()
	return cascade

func _find_player_special_creations(groups: Array[Dictionary], first: int, second: int) -> Array:
	var swapped: Array[int] = [first, second]
	var candidates: Array = []
	for group in groups:
		if group.orientation != "square" and group.indices.size() >= 5 and _contains_swapped(group.indices, swapped):
			candidates.append({"index": second if group.indices.has(second) else first, "kind": "insight"})
	if not candidates.is_empty():
		return _unique_creations(candidates)
	var row_groups: Array = groups.filter(func(group: Dictionary) -> bool: return group.orientation == "row")
	var column_groups: Array = groups.filter(func(group: Dictionary) -> bool: return group.orientation == "column")
	for row_group in row_groups:
		for column_group in column_groups:
			for index in row_group.indices:
				if column_group.indices.has(index) and _contains_swapped(row_group.indices + column_group.indices, swapped):
					candidates.append({"index": index, "kind": "evidence"})
	if not candidates.is_empty():
		return _unique_creations(candidates)
	for anchor in swapped:
		var row := int(anchor / _columns())
		var column := anchor % _columns()
		for top in [row - 1, row]:
			for left in [column - 1, column]:
				if top < 0 or left < 0 or top >= _rows() - 1 or left >= _columns() - 1:
					continue
				var square: Array[int] = [top * _columns() + left, top * _columns() + left + 1, (top + 1) * _columns() + left, (top + 1) * _columns() + left + 1]
				var tile := tiles[anchor]
				if square.all(func(index: int) -> bool: return tiles[index] == tile):
					candidates.append({"index": second if square.has(second) else anchor, "kind": "lead", "consumed": square})
	if not candidates.is_empty():
		return _unique_creations(candidates)
	for group in groups:
		if group.orientation != "square" and group.indices.size() == 4 and _contains_swapped(group.indices, swapped):
			candidates.append({"index": second if group.indices.has(second) else first, "kind": "flash-row" if group.orientation == "row" else "flash-column"})
	return _unique_creations(candidates)


func _classify_player_feedback(groups: Array[Dictionary], activated: Array[int], creations: Array) -> String:
	if not activated.is_empty(): return "special"
	if not creations.is_empty(): return "combo"
	var seen := {}
	for group in groups:
		if group.indices.size() >= 4: return "combo"
		for index in group.indices:
			if seen.has(index): return "combo"
			seen[index] = true
	return "match"

func _find_automatic_special_creations(groups: Array[Dictionary], preferred: Array[int]) -> Array:
	var candidates: Array = []
	for group in groups:
		if group.orientation == "square" or group.indices.size() < 5:
			continue
		var anchor := _creation_anchor(group.indices, preferred)
		if anchor >= 0:
			candidates.append({"index": anchor, "kind": "insight"})
	if not candidates.is_empty():
		return _unique_creations(candidates)
	var row_groups: Array = groups.filter(func(group: Dictionary) -> bool: return group.orientation == "row")
	var column_groups: Array = groups.filter(func(group: Dictionary) -> bool: return group.orientation == "column")
	for row_group in row_groups:
		for column_group in column_groups:
			for index in row_group.indices:
				if column_group.indices.has(index) and specials[index].is_empty():
					candidates.append({"index": index, "kind": "evidence"})
	if not candidates.is_empty():
		return _unique_creations(candidates)
	for group in groups:
		if group.orientation == "square":
			var anchor := _creation_anchor(group.indices, preferred)
			if anchor >= 0:
				candidates.append({"index": anchor, "kind": "lead", "consumed": group.indices})
	if not candidates.is_empty():
		return _unique_creations(candidates)
	for group in groups:
		if group.orientation != "square" and group.indices.size() == 4:
			var anchor := _creation_anchor(group.indices, preferred)
			if anchor >= 0:
				candidates.append({"index": anchor, "kind": "flash-row" if group.orientation == "row" else "flash-column"})
	return _unique_creations(candidates)

func _unique_creations(candidates: Array) -> Array:
	var seen := {}
	var unique: Array = []
	for creation in candidates:
		var index := int(creation.index)
		if seen.has(index):
			continue
		seen[index] = true
		unique.append(creation)
	return unique

func _creation_anchor(indices: Array, preferred: Array[int]) -> int:
	for index in preferred:
		if indices.has(index) and specials[index].is_empty():
			return index
	var available: Array[int] = []
	for index in indices:
		if specials[index].is_empty():
			available.append(int(index))
	return available[int((available.size() - 1) / 2)] if not available.is_empty() else -1

func _contains_swapped(indices: Array, swapped: Array[int]) -> bool:
	return indices.has(swapped[0]) or indices.has(swapped[1])

func _expand_special_clear(clear: Dictionary) -> void:
	var queue: Array = clear.keys()
	var expanded := {}
	while not queue.is_empty():
		var index := int(queue.pop_front())
		if expanded.has(index):
			continue
		expanded[index] = true
		var kind := specials[index]
		if kind.is_empty():
			continue
		var targets: Array[int] = []
		var rows := _rows()
		var columns := _columns()
		var row := int(index / columns)
		var column := index % columns
		match kind:
			"flash-row":
				for col in range(columns):
					targets.append(row * columns + col)
			"flash-column":
				for target_row in range(rows):
					targets.append(target_row * columns + column)
			"evidence":
				for target_row in range(maxi(0, row - 1), mini(rows - 1, row + 1) + 1):
					for col in range(maxi(0, column - 1), mini(columns - 1, column + 1) + 1):
						targets.append(target_row * columns + col)
			"lead":
				targets = _lead_targets(index)
			"insight":
				var tile := tiles[index]
				if not tile.is_empty():
					for target in tiles.size():
						if tiles[target] == tile: targets.append(target)
		for target in targets:
			if not clear.has(target):
				clear[target] = true
				queue.append(target)

func _lead_targets(index: int) -> Array[int]:
	var columns := _columns()
	var row := int(index / columns)
	var column := index % columns
	var targets: Array[int] = [index]
	if row > 0: targets.append(index - columns)
	if row < _rows() - 1: targets.append(index + columns)
	if column > 0: targets.append(index - 1)
	if column < columns - 1: targets.append(index + 1)
	for objective: Dictionary in level_data.get("objectives", []):
		if str(objective.get("kind", "")) != "collect": continue
		var target_tile := str(objective.tile)
		if int(collected_by_tile.get(target_tile, 0)) >= int(objective.target): continue
		for candidate in tiles.size():
			if not targets.has(candidate) and tiles[candidate] == target_tile and not _is_blocked(candidate):
				targets.append(candidate)
				return targets
	for candidate in tiles.size():
		if not targets.has(candidate) and not tiles[candidate].is_empty():
			targets.append(candidate)
			break
	return targets

func _resolve_direct_combo(first: String, second: String) -> String:
	var first_flash := first == "flash-row" or first == "flash-column"
	var second_flash := second == "flash-row" or second == "flash-column"
	if first.is_empty() and second.is_empty():
		return ""
	if first == "insight" and second.is_empty() or second == "insight" and first.is_empty():
		return "insight-normal"
	if first == "insight" or second == "insight":
		return "insight-special"
	if first_flash and second_flash:
		return "flash-flash"
	if first_flash and second == "evidence" or first == "evidence" and second_flash:
		return "flash-evidence"
	if first == "evidence" and second == "evidence":
		return "evidence-evidence"
	if first == "lead" and second_flash or first_flash and second == "lead":
		return "lead-flash"
	if first == "lead" and second == "evidence" or first == "evidence" and second == "lead":
		return "lead-evidence"
	return "fallback"

func _direct_combo_targets(combo: String, first: int, second: int) -> Array[int]:
	var targets := {}
	var columns := _columns()
	var rows := _rows()
	var center_row := int(second / columns)
	var center_column := second % columns
	if combo == "insight-normal" or combo == "insight-special":
		var insight_index := first if specials[first] == "insight" else second
		var partner := second if insight_index == first else first
		var target_tile := tiles[partner]
		for index in tiles.size():
			if tiles[index] == target_tile:
				targets[index] = true
		targets[insight_index] = true
		if combo == "insight-special": targets[partner] = true
	elif combo == "flash-flash" or combo == "lead-flash":
		for col in columns:
			targets[center_row * columns + col] = true
		for row in rows:
			targets[row * columns + center_column] = true
		if combo == "lead-flash":
			for index in _lead_targets(second):
				targets[index] = true
	elif combo == "flash-evidence":
		for row in range(maxi(0, center_row - 1), mini(rows - 1, center_row + 1) + 1):
			for col in columns:
				targets[row * columns + col] = true
		for col in range(maxi(0, center_column - 1), mini(columns - 1, center_column + 1) + 1):
			for row in rows:
				targets[row * columns + col] = true
	elif combo == "evidence-evidence" or combo == "lead-evidence":
		for row in range(maxi(0, center_row - 2), mini(rows - 1, center_row + 2) + 1):
			for col in range(maxi(0, center_column - 2), mini(columns - 1, center_column + 2) + 1):
				targets[row * columns + col] = true
		if combo == "lead-evidence":
			for index in _lead_targets(second):
				targets[index] = true
	else:
		targets[first] = true
		targets[second] = true
	var result: Array[int] = []
	for index in targets:
		result.append(int(index))
	return result

func _random_tile() -> String:
	var active_tiles: Array = level_data.get("activeTiles", [])
	if active_tiles.is_empty(): return ""
	var weights: Dictionary = level_data.get("spawnWeights", {})
	if weights.is_empty(): return str(active_tiles[_random.index(active_tiles.size())])
	var total := 0.0
	for tile: String in active_tiles: total += float(weights.get(tile, 1.0))
	var roll: float = _random.next_float() * total
	for tile: String in active_tiles:
		roll -= float(weights.get(tile, 1.0))
		if roll < 0.0: return tile
	return str(active_tiles.back())

func _shuffled_tile_keys() -> Array:
	var remaining: Array = level_data.get("activeTiles", []).duplicate()
	var ordered: Array = []
	var weights: Dictionary = level_data.get("spawnWeights", {})
	if weights.is_empty():
		_sort_random_comparator_like_chromium(remaining)
		return remaining
	while not remaining.is_empty():
		var total := 0.0
		for tile: String in remaining: total += float(weights.get(tile, 1.0))
		var roll: float = _random.next_float() * total
		var selected := remaining.size() - 1
		for index in remaining.size():
			roll -= float(weights.get(str(remaining[index]), 1.0))
			if roll < 0.0:
				selected = index
				break
		ordered.append(remaining.pop_at(selected))
	return ordered

func _sort_random_comparator_like_chromium(values: Array) -> void:
	# Mirror Chromium's binary-insertion Array.sort comparator call order so
	# seeded board generation matches the web build across runtimes.
	for start in range(1, values.size()):
		var pivot: Variant = values[start]
		var left := 0
		var right := start
		while left < right:
			var middle := (left + right) >> 1
			if _random.next_float() - 0.5 < 0.0:
				right = middle
			else:
				left = middle + 1
		for index in range(start, left, -1):
			values[index] = values[index - 1]
		values[left] = pivot

func _rows() -> int:
	return int(level_data.get("rows", 0))

func _columns() -> int:
	return int(level_data.get("columns", 0))

func _is_active(index: int) -> bool:
	if index < 0 or index >= tiles.size(): return false
	for hole: Variant in level_data.get("boardHoles", []):
		if int(hole) == index: return false
	return true

func _is_blocked(index: int) -> bool:
	return index >= 0 and index < blocker_layers.size() and blocker_layers[index] > 0 and str(level_data.get("blockerStyle", "solid")) != "overlay"

func can_interact_with_tile(index: int) -> bool:
	return _is_active(index) and index < tiles.size() and not tiles[index].is_empty() and not _is_blocked(index)

func _matchable_tile(index: int) -> String:
	if not _is_active(index) or _is_blocked(index): return ""
	return tiles[index]

func _damage_blockers(cleared: Dictionary) -> int:
	var damaged := {}
	for raw_index: Variant in cleared.keys():
		var index := int(raw_index)
		if index < 0 or index >= blocker_layers.size(): continue
		var row := int(index / _columns())
		var column := index % _columns()
		for neighbour in [index, index - 1, index + 1, index - _columns(), index + _columns()]:
			if neighbour < 0 or neighbour >= blocker_layers.size(): continue
			if absf(float(int(neighbour / _columns()) - row)) + absf(float(neighbour % _columns() - column)) > 1: continue
			if blocker_layers[neighbour] > 0: damaged[neighbour] = true
	var removed := 0
	for index: int in damaged:
		blocker_layers[index] -= 1
		if blocker_layers[index] == 0:
			blockers_cleared += 1
			removed += 1
	return removed
