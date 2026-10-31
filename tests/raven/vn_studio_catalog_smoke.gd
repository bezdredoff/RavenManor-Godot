extends SceneTree
## Character asset catalog smoke: fabricated local assets only, no UPDS donor copies.
const Library = preload("res://addons/vn_studio/editor/character_library.gd")
const Reader = preload("res://addons/vn_studio/editor/legacy_reader.gd")
const Drafts = preload("res://addons/vn_studio/editor/draft_store.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var root: String = ProjectSettings.globalize_path("user://vn_studio_catalog_synthetic")
	var images: String = root.path_join("assets/characters/miku")
	assert(DirAccess.make_dir_recursive_absolute(images) == OK)
	var image := Image.create(12, 12, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.7, 0.3, 0.5))
	assert(image.save_png(images.path_join("neutral.png")) == OK)
	assert(image.save_png(images.path_join("smile.png")) == OK)
	assert(image.save_png(images.path_join("icon.png")) == OK)
	var assets: Dictionary = {"characters": {
		"miku": {
			"icon": "res://assets/characters/miku/icon.png",
			"neutral": "res://assets/characters/miku/neutral.png",
			"smile": "res://assets/characters/miku/smile.png",
			"serious": "res://assets/characters/miku/not_found.png",
			"phone": "res://assets/characters/miku/missing_phone.png"
		},
		"ada": {"neutral": "res://assets/characters/ada/not_found.png"}
	}}
	var characters: Array[String] = Library.character_ids(assets)
	assert(characters == ["ada", "miku"])
	var sheet: Dictionary = Library.inspect(root, assets, "miku")
	assert(sheet["ok"])
	assert(sheet["format"] == "UPDS-flat-portraits")
	assert(sheet["outfits"].is_empty() and not sheet["layeredExpressions"])
	assert(sheet["motionClips"].is_empty())
	var all_poses: Array[String] = Library.pose_ids(root, assets, "miku", true)
	assert(all_poses == ["neutral", "serious", "smile"])
	var available: Array[String] = Library.pose_ids(root, assets, "miku")
	assert(available == ["neutral", "smile"])
	assert(Library.pose_ids(root, assets, "ada").is_empty())
	var missing: bool = false
	for item in sheet["entries"]:
		if item["id"] == "serious":
			assert(item["kind"] == "portrait" and not item["exists"])
			missing = true
		if item["id"] == "phone":
			assert(item["kind"] == "special")
	assert(missing)
	assert(Reader.image_for(root, assets, "characters", "miku", "smile") != null)
	assert(Reader.image_for(root, assets, "characters", "miku", "serious") == null)
	assert(Reader.resource_path(root, "res://assets/../bad.png") == "")
	assert(Reader.resource_path(root, "res://characters/outside.png") == "")
	var presets: Array[Dictionary] = Library.motion_presets()
	assert(presets.size() == 3 and presets[0]["id"] == "none")
	assert(presets[1]["needsMotion"] and presets[2]["needsMotion"])
	# A valid visual pose edit remains an editor-only patch, not a donor or catalog write.
	assert(DirAccess.make_dir_recursive_absolute(root.path_join("data")) == OK)
	var original: Dictionary = {"sceneId": "VN_SCENE_00", "lines": [
		{"id": "VN001", "actors": [{"character": "miku", "pose": "neutral", "layout": "left"}]}
	]}
	var f: FileAccess = FileAccess.open(root.path_join("data/scene.json"), FileAccess.WRITE)
	assert(f != null)
	f.store_string(JSON.stringify(original))
	f.close()
	var before: String = FileAccess.get_file_as_string(root.path_join("data/scene.json"))
	var entry: Dictionary = {"index": 0, "id": "VN_SCENE_00", "file": "scene.json", "groups": {"base": original["lines"]}}
	var draft: Dictionary = Drafts.fresh(root, entry)
	Drafts.set_actor(draft, "base", 0, "VN001", 0, "miku", "pose", "smile")
	assert(Drafts.validate(root, entry, draft).is_empty())
	var result: Dictionary = Drafts.materialize(original["lines"][0], draft, "base", 0)
	assert(result["actors"][0]["pose"] == "smile")
	assert(original["lines"][0]["actors"][0]["pose"] == "neutral")
	assert(FileAccess.get_file_as_string(root.path_join("data/scene.json")) == before)
	print("Raven VN Studio character library smoke passed")
	quit()
