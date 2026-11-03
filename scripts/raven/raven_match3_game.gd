extends "res://scripts/shared/upds/match3_game.gd"
## Raven-compatible facade around the actual UPDS Match3Game implementation.
## Only Raven level content and the legacy 2-field hint API are adapted.
const LevelBridge = preload("res://scripts/raven/upds_match3_campaign_adapter.gd")

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
		else:
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
		if not result.get("valid", false):
			_replaying = false
			reset()
			return false
	_replaying = false
	move_history = actions.duplicate(true)
	return true
