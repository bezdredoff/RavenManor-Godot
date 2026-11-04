extends "res://scripts/shared/upds/match3_game.gd"
## Raven-compatible facade around the actual UPDS Match3Game implementation.
## Only Raven level content and the legacy 2-field hint API are adapted.
const LevelBridge = preload("res://scripts/raven/upds_match3_campaign_adapter.gd")
const BoosterInventory = preload("res://scripts/raven/raven_booster_inventory.gd")

func _init(configured_level: Dictionary) -> void:
	super(LevelBridge.normalize(configured_level))

func get_hint_move() -> Dictionary:
	var hint: Dictionary = super.get_hint_move()
	if hint.is_empty():
		return {}
	# RM-VS-01 smoke and current HUD expect exactly these two fields.
	return {"first": int(hint.first), "second": int(hint.second)}

signal checkpoint_changed
var move_history: Array = []
var _replaying := false

func attempt_swap(first: int, second: int) -> Dictionary:
	var result: Dictionary = super.attempt_swap(first, second)
	if result.get("valid", false) and not _replaying:
		move_history.append({"kind": "swap", "first": first, "second": second})
		checkpoint_changed.emit()
	return result

func attempt_special_activation(index: int) -> Dictionary:
	var result: Dictionary = super.attempt_special_activation(index)
	if result.get("valid", false) and not _replaying:
		move_history.append({"kind": "special", "index": index})
		checkpoint_changed.emit()
	return result


func use_hammer(index: int) -> Dictionary:
	if state != "playing" or index < 0 or index >= tiles.size() or not _is_active(index):
		return {"valid": false, "reason": "target", "frames": []}
	if blocker_layers[index] <= 0 and tiles[index].is_empty():
		return {"valid": false, "reason": "target", "frames": []}
	_last_frames.clear()
	_last_cleared = 0
	_last_blockers_cleared = 0
	_last_ingredients_dropped = 0
	_last_settle_dropped = 0
	_last_specials_created = 0
	if blocker_layers[index] > 0:
		blocker_layers[index] -= 1
		if blocker_layers[index] == 0:
			blockers_cleared += 1
			_last_blockers_cleared = 1
	else:
		collected_by_tile[tiles[index]] = int(collected_by_tile.get(tiles[index], 0)) + 1
		tiles[index] = ""
		specials[index] = ""
		_last_cleared = 1
	_last_frames.append({"phase":"clear", "feedback":"booster", "cascade":1, "tiles":tiles.duplicate(), "specials":specials.duplicate(), "blockers":blocker_layers.duplicate(), "ingredients":ingredients.duplicate(), "cleared":[index] if _last_cleared else []})
	var motions := _settle_columns()
	_last_frames.append({"phase":"settle", "cascade":1, "tiles":tiles.duplicate(), "specials":specials.duplicate(), "blockers":blocker_layers.duplicate(), "ingredients":ingredients.duplicate(), "motions":motions})
	var cascades := _resolve(_find_resolution_match_groups(), [], [], "", index, index, "booster")
	_sync_primary_collect_count()
	_update_game_state()
	var result := {"valid":true, "reason":"", "won":state == "won", "lost":state == "lost", "reshuffled":false, "cascades":cascades, "cleared":_last_cleared, "blockersCleared":_last_blockers_cleared, "ingredientsDropped":_last_ingredients_dropped, "specialsCreated":_last_specials_created, "specialsCombined":false, "primaryFeedback":"booster", "frames":_last_frames.duplicate(true)}
	if not _replaying:
		move_history.append({"kind":"booster", "booster":"hammer", "index":index})
		checkpoint_changed.emit()
	return result


func use_shuffle() -> Dictionary:
	if state != "playing":
		return {"valid":false, "reason":"unavailable", "frames":[]}
	_last_frames.clear()
	_last_cleared = 0
	_last_blockers_cleared = 0
	_last_ingredients_dropped = 0
	_last_settle_dropped = 0
	_last_specials_created = 0
	if not _reshuffle_playable_board():
		return {"valid":false, "reason":"unavailable", "frames":[]}
	var result := {"valid":true, "reason":"", "won":false, "lost":false, "reshuffled":true, "cascades":0, "cleared":0, "blockersCleared":0, "ingredientsDropped":0, "specialsCreated":0, "specialsCombined":false, "primaryFeedback":"booster", "frames":_last_frames.duplicate(true)}
	if not _replaying:
		move_history.append({"kind":"shuffle"})
		checkpoint_changed.emit()
	return result

func reset() -> void:
	super.reset()
	if move_history != null:
		move_history.clear()
	if not _replaying:
		checkpoint_changed.emit()

func restore_history(actions: Array) -> bool:
	if actions.size() > 500:
		return false
	_replaying = true
	reset()
	for action in actions:
		if not action is Dictionary:
			_replaying = false
			reset()
			return false
		var result: Dictionary = {}
		var cell_count: int = tiles.size()
		var kind := str(action.get("kind", ""))
		if kind == "swap":
			if not (action.get("first") is int and action.get("second") is int):
				_replaying = false
				reset()
				return false
			if int(action.first) < 0 or int(action.second) < 0 or int(action.first) >= cell_count or int(action.second) >= cell_count:
				_replaying = false
				reset()
				return false
		elif kind == "special":
			if not action.get("index") is int or int(action.index) < 0 or int(action.index) >= cell_count:
				_replaying = false
				reset()
				return false
		elif kind == "booster":
			if not BoosterInventory.KINDS.has(str(action.get("booster", ""))) or not action.get("index") is int or int(action.index) < 0 or int(action.index) >= cell_count:
				_replaying = false
				reset()
				return false
		elif kind != "shuffle":
			_replaying = false
			reset()
			return false
		if state != "playing":
			_replaying = false
			reset()
			return false
		match kind:
			"swap":
				result = super.attempt_swap(int(action.get("first", -1)), int(action.get("second", -1)))
			"special":
				result = super.attempt_special_activation(int(action.get("index", -1)))
			"booster":
				result = use_hammer(int(action.get("index", -1)))
			"shuffle":
				result = use_shuffle()
		if not result.get("valid", false):
			_replaying = false
			reset()
			return false
	_replaying = false
	move_history = actions.duplicate(true)
	return true
