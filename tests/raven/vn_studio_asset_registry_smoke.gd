extends SceneTree
const Registry = preload("res://addons/vn_studio/model/asset_registry.gd")
const Library = preload("res://addons/vn_studio/editor/raven_asset_library.gd")


func _initialize() -> void:
	call_deferred("_run")


func _read(root_path: String, name: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(root_path.path_join(name)))


func _run() -> void:
	var source_root: String = ProjectSettings.globalize_path("res://")
	var background_path: String = source_root.path_join("data/raven/production/vn_background_catalog.json")
	var original_sha: String = FileAccess.get_sha256(background_path)
	var live_catalog: Dictionary = _read(source_root, Registry.BACKGROUNDS)
	var expected_backgrounds: int = int(live_catalog.get("variantCount", -1))
	assert(expected_backgrounds == live_catalog.get("entries", []).size())
	var registry: Dictionary = Registry.open_project(source_root)
	assert(registry.get("ok", false), str(registry.get("error", "")))
	assert(registry["backgroundCount"] == expected_backgrounds and registry["characterCount"] == 4)
	assert(registry["propCount"] == 0 and registry["masterIds"].size() == 11)
	assert(registry["portraitCount"] == 62)
	assert(registry["records"].size() == expected_backgrounds + 4 + 62)
	assert(registry["issues"].is_empty(), JSON.stringify(registry["issues"]))
	var background_ids: Dictionary = {}
	for record: Dictionary in registry["records"]:
		if record["category"] == "background":
			assert(record["orientation"] == "portrait" and record["status"] == "candidate")
			assert(record["integrity"] == "ok" and not background_ids.has(record["id"]))
			background_ids[record["id"]] = true
		else:
			assert(record["category"] == "character" and record["integrity"] == "ok")
			assert(record["status"] == "accepted" and record["path"].begins_with("res://assets/raven/characters/"))
	var staging: Dictionary = _read(source_root, Registry.STAGING)
	var catalog: Dictionary = live_catalog
	var cast: Dictionary = _read(source_root, Registry.CHARACTERS)
	var duplicate: Dictionary = catalog.duplicate(true)
	duplicate["entries"].append(duplicate["entries"][0].duplicate(true))
	duplicate["variantCount"] += 1
	assert(not Registry.build(staging, duplicate, cast, source_root)["ok"])
	var drift: Dictionary = catalog.duplicate(true)
	drift["entries"][0]["sha256"] = "bad-sha"
	assert(Registry.build(staging, drift, cast, source_root)["issues"].size() == 1)
	var missing: Dictionary = catalog.duplicate(true)
	missing["entries"][0]["path"] = "res://assets/raven/vn_backgrounds/absent.webp"
	assert(Registry.build(staging, missing, cast, source_root)["issues"].size() == 1)
	var escape: Dictionary = catalog.duplicate(true)
	escape["entries"][0]["path"] = "res://assets/raven/vn_backgrounds/../private.webp"
	assert(Registry.build(staging, escape, cast, source_root)["issues"].size() == 1)
	var library := Library.new()
	root.add_child(library)
	assert(library._visible.size() == expected_backgrounds + 4 + 62)
	library._category.select(1)
	library._refresh()
	assert(library._visible.size() == expected_backgrounds)
	library._search.text = "BG-ROAD"
	library._refresh()
	assert(library._visible.size() == 1)
	library._list.select(0)
	library._pin("A")
	assert(library._compare_labels[0].text.contains("BG-ROAD"))
	library._status_filter.select(2) # Backgrounds remain candidates; cast art is accepted.
	library._refresh()
	assert(library._visible.is_empty())
	library._status_filter.select(1)
	library._orientation.select(2) # The registered plates are portrait.
	library._refresh()
	assert(library._visible.is_empty())
	library._orientation.select(0)
	library._search.text = ""
	library._group.select(1)
	library._refresh()
	assert(not library._visible.is_empty())
	library._list.select(0)
	library._pin("B")
	assert(library._compare_labels[1].text.contains(str(library._visible[0]["id"])))
	library._group.select(0)
	library._status_filter.select(0)
	library._category.select(2)
	library._refresh()
	assert(library._visible.size() == 4 + 62)
	library._status_filter.select(2)
	library._refresh()
	assert(library._visible.size() == 4 + 62)
	library._list.select(4)
	library._pin("A")
	assert(library._compare_images[0].texture != null)
	assert(library._compare_images[0].texture.get_height() >= 1920)
	library._category.select(3)
	library._refresh()
	assert(library._visible.is_empty())
	assert(FileAccess.get_sha256(background_path) == original_sha)
	library.queue_free()
	print("Raven VN Studio asset registry read-only smoke passed")
	quit()
