extends RefCounted

const DEFINITIONS := {
	"basic-swap": {"reveal": "level-start", "complete": "valid-swap"},
	"clear-blocker": {"reveal": "level-start", "complete": "blocker-cleared"},
	"clear-package": {"reveal": "level-start", "complete": "blocker-cleared"},
	"clear-foam": {"reveal": "level-start", "complete": "blocker-cleared"},
	"clear-lock": {"reveal": "level-start", "complete": "blocker-cleared"},
	"drop-ingredient": {"reveal": "level-start", "complete": "ingredient-dropped"},
	"activate-special": {"reveal": "special-created", "complete": "special-activated"},
	"combine-specials": {"reveal": "special-combo-ready", "complete": "special-combined"},
}


static func next_pending(concepts: Array, completed: Array, revealed: Array) -> String:
	for value in concepts:
		var concept := str(value)
		if not DEFINITIONS.has(concept) or completed.has(concept): continue
		if revealed.has(str(DEFINITIONS[concept].reveal)): return concept
	return ""


static func board_reveal_events(specials: Array, rows: int, columns: int) -> Array[String]:
	if rows <= 0 or columns <= 0: return []
	for index in specials.size():
		if str(specials[index]).is_empty(): continue
		var row := int(index / columns)
		var column := index % columns
		for neighbour in [column + 1 if column + 1 < columns else -1, index + columns if row + 1 < rows else -1]:
			if neighbour >= 0 and neighbour < specials.size() and not str(specials[neighbour]).is_empty():
				return ["special-combo-ready"]
	return []


static func completion_events(result: Dictionary, direct_activation := false, direct_combo := false) -> Array[String]:
	if not bool(result.get("valid", false)): return []
	var events: Array[String] = []
	if not direct_activation: events.append("valid-swap")
	if int(result.get("blockersCleared", 0)) > 0: events.append("blocker-cleared")
	if int(result.get("ingredientsDropped", 0)) > 0: events.append("ingredient-dropped")
	if direct_activation: events.append("special-activated")
	if direct_combo: events.append("special-combined")
	return events


static func reveal_events_for_move(result: Dictionary) -> Array[String]:
	if not bool(result.get("valid", false)) or int(result.get("specialsCreated", 0)) <= 0: return []
	return ["special-created"]


static func completed_by_events(concepts: Array, completed: Array, events: Array) -> Array[String]:
	var result: Array[String] = []
	for value in concepts:
		var concept := str(value)
		if DEFINITIONS.has(concept) and not completed.has(concept) and events.has(str(DEFINITIONS[concept].complete)):
			result.append(concept)
	return result
