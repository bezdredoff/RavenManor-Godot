extends SceneTree
## Published art -> resolver -> both gameplay screens -> editable Studio draft.
const Art = preload("res://scripts/raven/raven_vn_characters.gd")
const View = preload("res://scripts/raven/raven_vn_game_view.gd")
const Store = preload("res://addons/vn_studio/editor/raven_story_store.gd")
const Designer = preload("res://addons/vn_studio/editor/raven_stage_designer.gd")
const HallTea = preload("res://scenes/raven/hall_tea_vn.tscn")
const Layout = preload("res://scripts/raven/raven_vn_portrait_layout.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for count in [1, 2, 3]:
		for point in [Vector2.ZERO, Vector2(0.5, 0.5), Vector2.ONE, Vector2(0.2, 0.7)]:
			var placed: Vector2 = Layout.position_for(Vector2(390, 844), count, point)
			assert(Layout.normalize_position(Vector2(390, 844), count, placed).is_equal_approx(point))
	assert(Art.all_entries().size() == 62)
	var ids: Dictionary = {}
	for entry: Dictionary in Art.all_entries():
		assert(not ids.has(entry["id"]))
		ids[entry["id"]] = true
		assert(entry["status"] == "accepted")
		var texture: Texture2D = Art.texture_for_entry(entry)
		assert(texture != null, str(entry["id"]))
		assert(texture.get_image().has_mipmaps(), "Native art must be minified without line-art aliasing")
		assert(texture.get_width() == entry["width"] and texture.get_height() == entry["height"])
		assert(Art.resolve(entry["characterId"], entry["pose"], entry["emotion"], entry["id"], "", false)["exact"])
	assert(Art.resolve("RM-CHAR-ADA", "offer_tray", "warm", "", "", false)["entry"].is_empty())
	var neutral_fallback: Dictionary = Art.resolve("RM-CHAR-ADA", "offer_tray", "warm")
	assert(not neutral_fallback["exact"] and neutral_fallback["entry"]["variant"] == "offer_tray")
	assert(Art.resolve("RM-CHAR-EVELYN", "relaxed", "neutral", "RM-VN-ADA-BASE-NEUTRAL")["entry"].is_empty())
	assert(Art.resolve("RM-CHAR-EVELYN", "investigate", "neutral", "", "PROP-LANTERN")["entry"]["characterId"] == "RM-CHAR-EVELYN")
	assert(Art.resolve("RM-CHAR-EVELYN", "investigate", "neutral", "", "PROP-UNSIGNED-LETTER")["entry"]["variant"] == "unsigned_letter")
	assert(Art.texture_for_entry({"path": "res://assets/prototypes/onoe/onoe_walk_sheet_v1.png"}) == null)

	var project: Dictionary = Store.open_project(ProjectSettings.globalize_path("res://"))
	assert(project.get("ok", false))
	var source_sha: String = FileAccess.get_sha256(str(project["sourcePath"]))
	var designer := Designer.new()
	root.add_child(designer)
	designer.set_scene(project, Store.fresh(project), "RM-BEAT-00-01")
	# All 62 published states must actually be selectable/rendered, not merely
	# declared in JSON. Selection must survive the same draft validator/export.
	for entry: Dictionary in Art.all_entries():
		designer._stage_data["cast"] = [{"characterId": entry["characterId"], "slot": "center", "pose": entry["pose"], "emotion": entry["emotion"]}]
		designer._stage_data["visibleCount"] = 1
		designer._selected_actor = 0
		designer._reload()
		var chosen: int = -1
		for i in range(designer._asset_pick.item_count):
			if designer._asset_pick.get_item_metadata(i) == entry["id"]:
				chosen = i
		assert(chosen > 0)
		designer._on_asset_pick(chosen)
		assert(designer._stage_data["cast"][0]["assetId"] == entry["id"])
		assert(designer._cards[0].get_child(0) is TextureRect)
		assert((designer._cards[0].get_child(0) as TextureRect).texture == Art.texture_for_entry(entry))
		var draft: Dictionary = Store.fresh(project)
		assert(Store.set_stage(project, draft, designer._stage_data).is_empty())
		var restored: Dictionary = JSON.parse_string(JSON.stringify(draft))
		assert(Store.validate(project, restored).is_empty())
		assert(Store.effective_stage(project, restored, "RM-BEAT-00-01")["cast"][0]["assetId"] == entry["id"])
	var invalid: Dictionary = designer._stage_data.duplicate(true)
	invalid["cast"][0]["assetId"] = "RM-VN-ADA-BASE-NEUTRAL"
	assert(not Store.validate_stage(project, invalid).is_empty())
	assert(FileAccess.get_sha256(str(project["sourcePath"])) == source_sha)
	designer.queue_free()
	await process_frame

	for scene_id: String in ["RM-BEAT-00-01", "RM-BEAT-02-01", "RM-BEAT-03-01", "RM-BEAT-04-01"]:
		var view := View.new()
		view.size = Vector2(390, 844)
		root.add_child(view)
		var line: Dictionary = project["linesByScene"][scene_id][0]
		var text: String = str(line["localized"]["ru"]["text"])
		assert(Art.line_id_for_text(scene_id, text) == line["id"])
		view.show_beat(scene_id, str(line["speakerId"]), text, "1/1", Callable())
		assert(not view.actors.is_empty())
		for actor: Dictionary in view.actors:
			assert(actor["node"] is TextureRect, actor["characterId"])
			assert(actor["asset"]["characterId"] == actor["characterId"])
			assert(str(actor["asset"]["path"]).begins_with("res://assets/raven/characters/"))
		view.queue_free()
		await process_frame
	var tea: Control = HallTea.instantiate()
	root.add_child(tea)
	assert(tea.actor_left.texture != null and tea.actor_right.texture != null)
	assert(str(tea.actor_left.texture.resource_path).begins_with("res://assets/raven/characters/"))
	assert(str(tea.actor_right.texture.resource_path).begins_with("res://assets/raven/characters/"))
	tea.queue_free()
	await process_frame
	print("Raven approved character art smoke passed (62 images, four actors, Studio selection/draft and gameplay).")
	quit()
