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
	move_history.clear()
	if not _replaying:
		checkpoint_changed.emit()

func restore_history(actions: Array) -> bool:
	_replaying = true
	reset()
	for action in actions:
		if not action is Dictionary:
			_replaying = false
			reset()
			return false
		var result: Dictionary = {}
		match str(action.get("kind", "")):
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
