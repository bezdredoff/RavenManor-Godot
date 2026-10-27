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
