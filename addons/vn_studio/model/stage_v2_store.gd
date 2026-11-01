@tool
extends RefCounted
## VNS5-04B: editor-only stage overlay. The existing Raven stage-v1 and runtime
## remain authoritative; no automatic migration/promotion to res://.
const FORMAT := "raven-vn-stage-overlay-v2"
const ORIENTATIONS := ["portrait", "landscape"]
const FIT_MODES := ["cover", "contain"]
const MAX_PROPS := 24
const ALLOWED := ["format", "schemaVersion", "sceneId", "orientation", "fitMode", "focal", "actorZ", "props"]
const PROP_FIELDS := ["instanceId", "assetId", "state", "x", "y", "z", "scale", "pivot", "label"]


static func fresh(scene_id: String) -> Dictionary:
	return {"format": FORMAT, "schemaVersion": 2, "sceneId": scene_id,
		"orientation": "portrait", "fitMode": "cover", "focal": {"x": 0.5, "y": 0.5},
		"actorZ": {}, "props": []}


static func effective(draft: Dictionary, scene_id: String) -> Dictionary:
	var record: Variant = draft.get("stageV2Patches", {}).get(scene_id, {})
	return record.duplicate(true) if record is Dictionary and not record.is_empty() else fresh(scene_id)


static func _number(value: Variant, minimum: float, maximum: float) -> bool:
	return (value is int or value is float) and is_finite(float(value)) \
		and float(value) >= minimum and float(value) <= maximum


static func _token(value: Variant, maximum: int) -> bool:
	if not value is String or value.is_empty() or value.length() > maximum:
		return false
	for i in value.length():
		var c: String = value.substr(i, 1)
		if not ("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-".contains(c)):
			return false
	return true


static func _asset(value: Variant) -> bool:
	if value == "": # A prop placeholder is NOT an approved or published asset.
		return true
	if not value is String or not value.begins_with("asset-") or value.length() != 70:
		return false
	for i in range(6, 70):
		if not "0123456789abcdef".contains(value.substr(i, 1)):
			return false
	return true


static func validate(stage: Dictionary, overlay: Variant) -> String:
	if not overlay is Dictionary:
		return "V2-слой должен быть объектом."
	for key in overlay.keys():
		if not ALLOWED.has(key):
			return "Недопустимое поле v2: " + str(key)
	if overlay.get("format") != FORMAT or overlay.get("schemaVersion") != 2 or overlay.get("sceneId") != stage.get("sceneId"):
		return "Несовместимая версия или sceneId stage-v2."
	if overlay.get("orientation") not in ORIENTATIONS or overlay.get("fitMode") not in FIT_MODES:
		return "Неверная ориентация или fitMode."
	var focal: Variant = overlay.get("focal", {})
	if not focal is Dictionary or focal.size() != 2 or not focal.has("x") or not focal.has("y") \
			or not _number(focal["x"], 0, 1) or not _number(focal["y"], 0, 1):
		return "Focal должен содержать только нормализованные x/y."
	var actor_z: Variant = overlay.get("actorZ", {})
	if not actor_z is Dictionary:
		return "Неверный actorZ."
	var cast_ids: Dictionary = {}
	for actor in stage.get("cast", []):
		if not actor is Dictionary:
			return "Повреждённая stage-v1 постановка."
		cast_ids[str(actor.get("characterId", ""))] = true
	for character_id in actor_z:
		if not cast_ids.has(character_id) or not _number(actor_z[character_id], -10, 100) or not actor_z[character_id] is int:
			return "Actor z-order содержит отсутствующего персонажа или неверный z."
	var props: Variant = overlay.get("props", [])
	if not props is Array or props.size() > MAX_PROPS:
		return "Не более 24 props в одном кадре."
	var ids: Dictionary = {}
	for prop in props:
		if not prop is Dictionary:
			return "Некорректный экземпляр prop."
		for key in prop.keys():
			if not PROP_FIELDS.has(key):
				return "Запрещённое поле prop: " + str(key)
		var id: Variant = prop.get("instanceId", "")
		if not _token(id, 48) or not str(id).begins_with("prop-") or ids.has(id):
			return "Отсутствующий, повторный или неверный prop instanceId."
		ids[id] = true
		if not _asset(prop.get("assetId", "")):
			return "Prop assetId должен быть staged SHA-256 ID или пустым ART PENDING."
		if not _token(prop.get("state", ""), 32) or not _token(prop.get("label", ""), 48):
			return "Недопустимое состояние/метка prop."
		if prop.get("pivot", "") != "center" or not _number(prop.get("x"), 0, 1) or not _number(prop.get("y"), 0, 1) \
				or not _number(prop.get("scale"), 0.1, 3) or not _number(prop.get("z"), -10, 100) or not prop.get("z") is int:
			return "Недопустимые нормализованные координаты/scale/z/pivot prop."
	return ""


static func trim_actor_z(stage: Dictionary, overlay: Dictionary) -> Dictionary:
	var next: Dictionary = overlay.duplicate(true)
	var known: Dictionary = {}
	for actor in stage.get("cast", []):
		known[str(actor.get("characterId", ""))] = true
	for key in next.get("actorZ", {}).keys():
		if not known.has(key):
			next["actorZ"].erase(key)
	return next


static func new_prop(overlay: Dictionary) -> Dictionary:
	var next: Dictionary = overlay.duplicate(true)
	var occupied: Dictionary = {}
	for prop in next.get("props", []):
		occupied[str(prop.get("instanceId", ""))] = true
	var index: int = 1
	while occupied.has("prop-%04d" % index):
		index += 1
	var id: String = "prop-%04d" % index
	next["props"].append({"instanceId": id, "assetId": "", "state": "clean",
		"x": 0.5, "y": 0.5, "z": 20, "scale": 1.0, "pivot": "center", "label": "Prop_%d" % index})
	return next


static func has_pending_art(overlay: Dictionary) -> bool:
	for prop in overlay.get("props", []):
		if str(prop.get("assetId", "")).is_empty():
			return true
	return false
