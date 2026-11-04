extends RefCounted
## Bounded Raven-only inventory for one-use Match-3 helpers.
const KINDS := ["hammer", "shuffle"]
const MAX_COUNT := 99

static func fresh() -> Dictionary:
	return {"hammer": 0, "shuffle": 0}

static func normalize(value: Variant) -> Dictionary:
	var result := fresh()
	if not value is Dictionary:
		return result
	for kind in KINDS:
		var raw: Variant = value.get(kind, 0)
		if raw is int or raw is float:
			var count := float(raw)
			if is_finite(count) and count == floor(count):
				result[kind] = clampi(int(floor(count)), 0, MAX_COUNT)
	return result

static func add(inventory: Dictionary, kind: String, amount: int) -> Dictionary:
	if not KINDS.has(kind) or amount <= 0:
		return {}
	var next := normalize(inventory)
	next[kind] = mini(MAX_COUNT, int(next[kind]) + amount)
	return next

static func spend(inventory: Dictionary, kind: String) -> Dictionary:
	var next := normalize(inventory)
	if not KINDS.has(kind) or int(next.get(kind, 0)) <= 0:
		return {}
	next[kind] = int(next[kind]) - 1
	return next
