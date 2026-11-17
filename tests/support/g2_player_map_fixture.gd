extends "res://scripts/raven/raven_player_map.gd"
## Tests instantiate the real view with an isolated host and the same source
## validator. No shipped flag, global metadata or persistent approval injection.
const Fixture = preload("res://tests/support/g2_production_fixture.gd")

func _entry_allowed(snapshot: Dictionary) -> bool:
	return Fixture.available(snapshot)

func _navigation_request() -> Dictionary:
	return Fixture.request()
