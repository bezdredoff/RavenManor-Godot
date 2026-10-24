extends RefCounted

## Raven adapter of the proven UPDS Match3Game contract: deterministic board,
## adjacent swaps, match validation, cascades, move limit and objective progress.
## It deliberately consumes Raven data and has no dependency on UPDS story/assets.

var level_data: Dictionary
var tiles: Array[String] = []
var moves_left := 0
var collected := 0
var state := "playing"
var _random := RandomNumberGenerator.new()


func _init(configured_level: Dictionary) -> void:
	level_data = configured_level.duplicate(true)
	reset()


func reset() -> void:
	_random.seed = int(level_data.seed)
	moves_left = int(level_data.moves)
	collected = 0
	state = "playing"
	_generate_board()


func attempt_swap(first: int, second: int) -> Dictionary:
	if state != "playing": return {"valid": false, "reason": "finished"}
	if not _adjacent(first, second): return {"valid": false, "reason": "not-adjacent"}
	_swap(first, second)
	if _matches().is_empty():
		_swap(first, second)
		return {"valid": false, "reason": "no-match"}
	moves_left -= 1
	var cascades := 0
	while true:
		var matched := _matches()
		if matched.is_empty(): break
		cascades += 1
		_clear_and_fill(matched)
		if cascades >= 24: break
	var objective: Dictionary = level_data.objective
	if collected >= int(objective.target): state = "won"
	elif moves_left <= 0: state = "lost"
	elif get_hint_move().is_empty(): _generate_board()
	return {"valid": true, "won": state == "won", "lost": state == "lost", "cascades": cascades}


func get_hint_move() -> Dictionary:
	for index in tiles.size():
		for other in [index + 1, index + int(level_data.columns)]:
			if not _adjacent(index, other): continue
			_swap(index, other)
			var valid := not _matches().is_empty()
			_swap(index, other)
			if valid: return {"first": index, "second": other}
	return {}


func _generate_board() -> void:
	var count := int(level_data.rows) * int(level_data.columns)
	tiles.clear(); tiles.resize(count)
	for index in count:
		var options: Array = level_data.tiles.duplicate()
		while not options.is_empty():
			var pick := _random.randi_range(0, options.size() - 1)
			tiles[index] = str(options[pick])
			if not _creates_match_at(index): break
			options.remove_at(pick)
	if get_hint_move().is_empty(): _generate_board()


func _clear_and_fill(matched: Dictionary) -> void:
	var objective_tile := str(level_data.objective.tile)
	for key in matched:
		var index := int(key)
		if tiles[index] == objective_tile: collected += 1
		tiles[index] = ""
	var columns := int(level_data.columns)
	var rows := int(level_data.rows)
	for column in columns:
		var write := rows - 1
		for row in range(rows - 1, -1, -1):
			var index := row * columns + column
			if not tiles[index].is_empty():
				tiles[write * columns + column] = tiles[index]
				if write != row: tiles[index] = ""
				write -= 1
		while write >= 0:
			tiles[write * columns + column] = str(level_data.tiles[_random.randi_range(0, level_data.tiles.size() - 1)])
			write -= 1


func _matches() -> Dictionary:
	var result := {}
	var columns := int(level_data.columns)
	var rows := int(level_data.rows)
	for row in rows:
		var run := 1
		for column in range(1, columns + 1):
			if column < columns and tiles[row * columns + column] == tiles[row * columns + column - 1]: run += 1
			else:
				if run >= 3:
					for offset in run: result[row * columns + column - 1 - offset] = true
				run = 1
	for column in columns:
		var run := 1
		for row in range(1, rows + 1):
			if row < rows and tiles[row * columns + column] == tiles[(row - 1) * columns + column]: run += 1
			else:
				if run >= 3:
					for offset in run: result[(row - 1 - offset) * columns + column] = true
				run = 1
	return result


func _creates_match_at(index: int) -> bool:
	var columns := int(level_data.columns)
	var row := int(index / columns)
	var column := index % columns
	return (column >= 2 and tiles[index] == tiles[index - 1] and tiles[index] == tiles[index - 2]) or (row >= 2 and tiles[index] == tiles[index - columns] and tiles[index] == tiles[index - columns * 2])


func _adjacent(first: int, second: int) -> bool:
	if first < 0 or second < 0 or first >= tiles.size() or second >= tiles.size(): return false
	var columns := int(level_data.columns)
	return abs(first - second) == columns or (abs(first - second) == 1 and int(first / columns) == int(second / columns))


func _swap(first: int, second: int) -> void:
	var value := tiles[first]; tiles[first] = tiles[second]; tiles[second] = value
