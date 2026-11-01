extends SceneTree
## Synthetic inputs only; never checks generated art into Git.
const Store = preload("res://addons/vn_studio/model/staged_image_store.gd")
const Registry = preload("res://addons/vn_studio/model/asset_registry.gd")

func _initialize() -> void:
	call_deferred("_run")


func _write(path: String, bytes: PackedByteArray) -> void:
	assert(DirAccess.make_dir_recursive_absolute(path.get_base_dir()) == OK)
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	assert(file != null)
	file.store_buffer(bytes)
	file.close()


func _make_image(width: int, height: int, alpha: float) -> Image:
	var image: Image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.25, 0.45, 0.75, alpha))
	return image


func _run() -> void:
	var base: String = ProjectSettings.globalize_path("user://vns503_smoke_%d" % Time.get_ticks_usec())
	var synthetic_project: String = base.path_join("project")
	var files: String = base.path_join("fixtures")
	assert(DirAccess.make_dir_recursive_absolute(files) == OK)
	for catalog in Store.CATALOGS:
		_write(synthetic_project.path_join(catalog), FileAccess.get_file_as_bytes("res://" + catalog))
	var source_locks: Dictionary = {}
	for catalog in Store.CATALOGS:
		source_locks[catalog] = FileAccess.get_sha256(synthetic_project.path_join(catalog))
	var store = Store.new()
	assert(Store.CATALOGS.has(Registry.CHARACTER_ART))
	assert(store.open_project(synthetic_project).get("ok", false))
	var portraits: Array[String] = []
	var landscapes: Array[String] = []
	var p_alpha: Image = _make_image(64, 128, 0.5)
	var p_opaque: Image = _make_image(64, 128, 1.0)
	var l_opaque: Image = _make_image(128, 64, 1.0)
	var l_alpha: Image = _make_image(128, 64, 0.25)
	assert(p_alpha.save_png(files.path_join("portrait_alpha.png")) == OK)
	assert(p_opaque.save_jpg(files.path_join("portrait.jpg")) == OK)
	assert(l_opaque.save_webp(files.path_join("landscape.webp")) == OK)
	assert(l_alpha.save_png(files.path_join("landscape_alpha.png")) == OK)
	portraits = [files.path_join("portrait_alpha.png"), files.path_join("portrait.jpg")]
	landscapes = [files.path_join("landscape.webp"), files.path_join("landscape_alpha.png")]
	var results: Array[Dictionary] = store.stage_files(PackedStringArray(portraits + landscapes))
	assert(results.size() == 4)
	for result in results:
		assert(result.get("ok", false), JSON.stringify(result))
	assert(store.list_items().size() == 4)
	assert(store.list_items()[0]["orientation"] == "portrait" and store.list_items()[0]["alpha"])
	assert(store.list_items()[1]["orientation"] == "portrait" and not store.list_items()[1]["alpha"])
	assert(store.list_items()[2]["orientation"] == "landscape" and not store.list_items()[2]["alpha"])
	assert(store.list_items()[3]["orientation"] == "landscape" and store.list_items()[3]["alpha"])
	var original_id: String = store.list_items()[0]["id"]
	var duplicate: String = files.path_join("same_bytes_different_name.png")
	_write(duplicate, FileAccess.get_file_as_bytes(portraits[0]))
	assert(store.stage_file(duplicate).get("duplicate", false))
	assert(store.list_items().size() == 4)
	# Same filename + different bytes must not overwrite either content-addressed image.
	var other: String = files.path_join("other")
	assert(DirAccess.make_dir_recursive_absolute(other) == OK)
	var collision_image: Image = _make_image(32, 64, 1.0)
	assert(collision_image.save_png(other.path_join("portrait_alpha.png")) == OK)
	var collision: Dictionary = store.stage_file(other.path_join("portrait_alpha.png"))
	assert(collision.get("ok", false) and collision.get("filenameCollision", false))
	assert(store.list_items().size() == 5 and store.list_items()[0]["id"] == original_id)
	var png_fake: String = files.path_join("fake.png")
	_write(png_fake, "<svg><script>NO</script></svg>".to_utf8_buffer())
	assert(not store.stage_file(png_fake).get("ok", false))
	var bad_svg: String = files.path_join("bad.svg")
	_write(bad_svg, "<svg/>".to_utf8_buffer())
	assert(not store.stage_file(bad_svg).get("ok", false))
	var code: String = files.path_join("evil.gd")
	_write(code, "extends Node".to_utf8_buffer())
	assert(not store.stage_file(code).get("ok", false))
	var nonsense: String = files.path_join("invalid.jpg")
	_write(nonsense, PackedByteArray([255, 216, 255, 4, 9, 10]))
	assert(not store.stage_file(nonsense).get("ok", false))
	assert(not store.stage_file(files.path_join("missing.png")).get("ok", false))
	var oversized: String = files.path_join("oversized.png")
	var large: PackedByteArray = PackedByteArray()
	large.resize(10 * 1024 * 1024)
	_write(oversized, large)
	large.clear()
	assert(not store.stage_file(oversized).get("ok", false))
	assert(not store._safe("../../escape", false))
	assert(not store._safe("/tmp/escape", false))
	assert(not store._safe("C:\\windows\\escape", false))
	assert(not store.update_metadata(original_id, {"groupId": "../res://escape"}).get("ok", false))
	assert(not store.update_metadata(original_id, {"groupId": "BG-../escape"}).get("ok", false))
	assert(not store.export_review_candidate().get("ok", false)) # Missing rights.
	var updated: Dictionary = store.update_metadata(original_id, {"displayName": "Hall portrait", "groupId": "BG-HALL", "provenance": "Original synthetic test", "license": "CC0-1.0"})
	assert(updated.get("ok", false), JSON.stringify(updated))
	assert(store.list_items()[0]["id"] == original_id)
	for item in store.list_items():
		assert(store.update_metadata(item["id"], {"groupId": "BG-HALL", "license": "CC0-1.0", "provenance": "Generated test fixture"}).get("ok", false))
	var reopened = Store.new()
	assert(reopened.open_project(synthetic_project).get("ok", false))
	assert(reopened.list_items().size() == 5)
	var review: Dictionary = reopened.export_review_candidate()
	assert(review.get("ok", false), JSON.stringify(review))
	assert(review["path"].begins_with(ProjectSettings.globalize_path("user://")))
	assert(not reopened.export_review_candidate().get("ok", false)) # No overwrite.
	for catalog in source_locks:
		assert(FileAccess.get_sha256(synthetic_project.path_join(catalog)) == source_locks[catalog])
	# External source SHA drift invalidates reopen and prevents writes/export.
	var drifted: String = synthetic_project.path_join(Registry.STAGING)
	_write(drifted, (FileAccess.get_file_as_string(drifted) + " ").to_utf8_buffer())
	var stale = Store.new()
	assert(not stale.open_project(synthetic_project).get("ok", false))
	assert(not stale.stage_file(portraits[0]).get("ok", false))
	# Corrupted manifest similarly fails closed, unrelated catalog remains readable.
	var manifest_file: String = ProjectSettings.globalize_path(reopened.folder.path_join("manifest.json"))
	_write(manifest_file, "{not JSON".to_utf8_buffer())
	var corrupt = Store.new()
	assert(not corrupt.open_project(synthetic_project).get("ok", false))
	assert(Registry.open_project(synthetic_project).get("ok", false))
	assert(Registry.open_project(synthetic_project).get("portraitCount", 0) == 62)
	print("Raven VN Studio staged image import safety smoke passed")
	quit()
