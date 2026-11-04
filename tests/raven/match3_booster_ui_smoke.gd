extends SceneTree
## Read-only booster UI characterization, including all languages and unlock gates.
const BoosterUI = preload("res://scripts/raven/raven_match3_booster_ui.gd")
const Snapshot = preload("res://scripts/raven/raven_snapshot.gd")

var hammer_presses := 0
var shuffle_presses := 0


func _initialize() -> void:
	call_deferred("_run")


func _on_hammer() -> void:
	hammer_presses += 1


func _on_shuffle() -> void:
	shuffle_presses += 1


func _buttons(container: VBoxContainer) -> Dictionary:
	var bar: HBoxContainer = container.get_node("RavenBoosterBar")
	return {"bar": bar, "hammer": bar.get_node("RavenHammerBooster"),
		"shuffle": bar.get_node("RavenShuffleBooster")}


func _render(state: Dictionary, locale: String, selected: String) -> VBoxContainer:
	var parent := VBoxContainer.new()
	root.add_child(parent)
	BoosterUI.render_bar(parent, state, locale, selected, _on_hammer, _on_shuffle)
	return parent


func _run() -> void:
	var locked: Dictionary = Snapshot.fresh()
	var initial := _render(locked, "ru", "")
	var defaults := _buttons(initial)
	assert(defaults.bar.get_theme_constant("separation") == 8)
	assert(defaults.hammer.text == "Молот ×0" and defaults.hammer.disabled)
	assert(defaults.shuffle.text == "Перемешать ×0" and defaults.shuffle.disabled)
	initial.queue_free()
	await process_frame
	# Inventory alone cannot unlock a booster before its restoration gate.
	var stocked: Dictionary = Snapshot.fresh()
	stocked.boosterInventory.hammer = 2
	stocked.boosterInventory.shuffle = 1
	var no_repairs := _render(stocked, "en", "")
	var before_gates := _buttons(no_repairs)
	assert(before_gates.hammer.text == "Hammer ×2" and before_gates.hammer.disabled)
	assert(before_gates.shuffle.text == "Shuffle ×1" and before_gates.shuffle.disabled)
	no_repairs.queue_free()
	await process_frame
	# Bedroom unlocks hammer, bathroom unlocks shuffle independently.
	stocked.completedRestorations = ["RM-REST-001"]
	var bedroom := _render(stocked, "ru", "hammer")
	var h := _buttons(bedroom)
	assert(h.hammer.text == "Молот · Выбран ×2" and not h.hammer.disabled)
	assert(h.shuffle.text == "Перемешать ×1" and h.shuffle.disabled)
	h.hammer.pressed.emit()
	assert(hammer_presses == 1 and shuffle_presses == 0)
	BoosterUI.render_target_hint(bedroom, "ru")
	assert((bedroom.get_child(1) as Label).text == "Выберите плитку или блокер для молотка.")
	bedroom.queue_free()
	await process_frame
	stocked.completedRestorations.append("RM-REST-002")
	var belarusian := _render(stocked, "be", "")
	var b := _buttons(belarusian)
	assert(b.hammer.text == "Молат ×2" and not b.hammer.disabled)
	assert(b.shuffle.text == "Перамяшаць ×1" and not b.shuffle.disabled)
	b.shuffle.pressed.emit()
	assert(shuffle_presses == 1)
	assert(BoosterUI.text("saved", "be") == "Не ўдалося захаваць выкарыстанне бустара")
	belarusian.queue_free()
	await process_frame
	var english := _render(stocked, "en", "hammer")
	var e := _buttons(english)
	assert(e.hammer.text == "Hammer · Selected ×2")
	assert(e.shuffle.text == "Shuffle ×1")
	assert(BoosterUI.text("unavailable", "en") == "Shuffle is unavailable right now")
	assert(BoosterUI.text("hammer", "unsupported") == "Hammer")
	assert(stocked.boosterInventory.hammer == 2 and stocked.boosterInventory.shuffle == 1,
		"UI must never spend inventory or mutate campaign state")
	english.queue_free()
	print("Raven Match-3 booster UI labels, gates and callbacks smoke passed")
	quit()
