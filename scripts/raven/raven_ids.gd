extends RefCounted

## Stable Raven Manor identifiers and legacy alias resolution.
const CATALOG = preload("res://data/raven/foundation_catalog.json")


static func catalog() -> Dictionary:
	return CATALOG.data


static func resolve_door(id: String) -> String:
	return str(CATALOG.data.doorAliases.get(id, id))


static func is_known(kind: String, id: String) -> bool:
	var collection: Variant = CATALOG.data.get(kind)
	if collection is Dictionary:
		return collection.has(id)
	return collection is Array and collection.has(id)
