extends RefCounted
## R2b Match-3 session/persistence boundary for Raven Manor.
## The game board is the reused UPDS engine; this adapter prepares atomic
## checkpoint/reward snapshots via RavenReducer and RavenCampaignStore.
## It does not own UI widgets, navigation, level balancing or a second save key.
const Match3 = preload("res://scripts/raven/raven_match3_game.gd")
const Reducer = preload("res://scripts/raven/raven_reducer.gd")


static func open(level: Dictionary, state: Dictionary, checkpoint_callback: Callable) -> RefCounted:
	var game := Match3.new(level)
	var checkpoint: Dictionary = state.get("match3Checkpoint", {})
	if str(checkpoint.get("levelId", "")) == str(level.id):
		if not game.restore_history(checkpoint.get("actions", [])):
			push_warning("Invalid Match-3 checkpoint; starting level afresh")
	if checkpoint_callback.is_valid():
		game.checkpoint_changed.connect(checkpoint_callback)
	return game


static func checkpoint(game: RefCounted, state: Dictionary, step_id: String,
		level_id: String, store: RefCounted) -> Dictionary:
	if game == null:
		return {"ok": true, "state": state, "boosterActionSaved": true}
	var actions: Array = game.move_history
	var pending_booster := not actions.is_empty() and str(actions.back().get("kind", "")) in ["booster", "shuffle"]
	# The winning event and last booster spend are committed in complete(), never
	# as a separate checkpoint; otherwise a failed reward save could spend twice.
	if str(game.state) == "won":
		return {"ok": true, "state": state, "boosterActionSaved": true}
	var updated: Dictionary = state.duplicate(true)
	updated.match3Checkpoint = {"levelId": level_id, "actions": actions.duplicate(true)}
	if not _apply_pending_booster_cost(game, state, step_id, updated):
		return {"ok": false, "reason": "booster", "boosterActionSaved": not pending_booster}
	if store.save_campaign(updated):
		return {"ok": true, "state": updated, "boosterActionSaved": true}
	_restore_last_saved_board(game, state)
	return {"ok": false, "reason": "save", "boosterActionSaved": not pending_booster}


static func complete(game: RefCounted, state: Dictionary, step_id: String,
		level_id: String, event_serial: int, store: RefCounted) -> Dictionary:
	# Reducer is the sole source of level rewards, first-clear idempotency and
	# inventory spend; the store commits those plus checkpoint removal atomically.
	var event := {"eventId": "vs-%s-%d-%d" % [step_id, state.revision, event_serial],
		"type": "level_won", "levelId": level_id}
	var result: Dictionary = Reducer.apply(state, event)
	if not result.get("ok", false):
		return {"ok": false, "reason": "rejected"}
	var updated: Dictionary = result.state
	if not _apply_pending_booster_cost(game, state, step_id, updated):
		return {"ok": false, "reason": "booster"}
	updated.match3Checkpoint = {}
	if not store.save_campaign(updated):
		_restore_last_saved_board(game, state)
		return {"ok": false, "reason": "save"}
	return {"ok": true, "state": updated}


static func _apply_pending_booster_cost(game: RefCounted, state: Dictionary,
		step_id: String, updated: Dictionary) -> bool:
	if game == null or game.move_history.is_empty():
		return true
	var last: Dictionary = game.move_history.back()
	var kind := "hammer" if str(last.get("kind", "")) == "booster" else "shuffle" if str(last.get("kind", "")) == "shuffle" else ""
	if kind.is_empty():
		return true
	var action_count: int = game.move_history.size()
	var event := {"eventId": "booster-%s-%d-%d" % [step_id, state.revision, action_count],
		"type": "booster_spent", "kind": kind}
	var reduced: Dictionary = Reducer.apply(updated, event)
	if not reduced.get("ok", false):
		return false
	updated.clear()
	updated.merge(reduced.state, true)
	return true


static func _restore_last_saved_board(game: RefCounted, state: Dictionary) -> void:
	if game == null:
		return
	# Restore only the last committed replay history; do not persist UI state.
	game._replaying = true
	var previous: Array = state.get("match3Checkpoint", {}).get("actions", [])
	game.restore_history(previous)
	game._replaying = false
