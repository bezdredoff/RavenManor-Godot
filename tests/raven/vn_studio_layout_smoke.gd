extends SceneTree
## Regression: the Raven workspace must not be squeezed by UPDS legacy sidebars,
## and stage controls must remain vertically reachable at short window heights.
const Studio = preload("res://addons/vn_studio/editor/studio_view.gd")
const Raven = preload("res://addons/vn_studio/editor/raven_story_view.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var studio := Studio.new()
	root.add_child(studio)
	studio.size = Vector2(1024, 640)
	await process_frame
	assert(studio._stage_tabs.current_tab == 3)
	for legacy_tab in range(3):
		assert(studio._stage_tabs.is_tab_hidden(legacy_tab), "UPDS tools must not be visible in Raven mode")
	assert(not studio._stage_tabs.is_tab_hidden(3))
	assert(studio._raven_story_view._legacy_tools_button.text.contains("UPDS"))
	assert(not studio._legacy_scenes_panel.visible, "Legacy UPDS scenes must hide in Raven workspace")
	assert(not studio._legacy_details_panel.visible, "Legacy UPDS details must hide in Raven workspace")
	assert(not studio._legacy_toolbar.visible, "UPDS toolbar should not consume Raven height")
	assert(not studio._status.visible)
	assert(studio._raven_story_view is Raven)
	var raven: Control = studio._raven_story_view
	assert(raven._workspace_scroll != null, "All Raven controls should be vertically scrollable")
	assert(raven._workspace_scroll.vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED)
	assert(raven._dialogue_scroll != null, "Dialogue controls should be vertically scrollable")
	assert(raven._stage_scroll != null)
	assert(raven._stage_scroll.vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED)
	assert(raven._stage_designer.get_parent().get_parent() == raven._stage_scroll)
	assert(raven._scene_panel.visible and raven._line_panel.visible)
	assert(raven._workspace_tabs.get_tab_count() == 6)
	assert(raven._stage_column.visible, "Stage remains visible across inspector tabs")
	assert(raven._workspace_tabs.get_tab_title(0) == "Stage Inspector")
	assert(raven._line_info.get_parent().name == "Translations")
	assert(raven._stage_designer._canvas != null)
	assert(raven._stage_designer._background.get_parent() != raven._stage_designer)
	for width in [800, 1024, 1366]:
		studio.size = Vector2(width, 640)
		await process_frame
		await process_frame
		assert(raven._workspace_scroll.vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED)
		assert(raven._workspace_body.custom_minimum_size.y >=
			raven._workspace_scroll.size.y - 1.0, "Raven body must fill its visible viewport")
		assert(raven._panel_split.size.y >=
			raven._workspace_scroll.size.y - 140.0, "Main workspace must use Godot tab height")
		var canvas_size: Vector2 = raven._stage_designer._canvas.custom_minimum_size
		assert(canvas_size.y > 0 and canvas_size.y < 844,
			"Docked portrait Stage must fit a short editor pane, not require 844px scrolling")
		assert(absf(canvas_size.x / canvas_size.y - 390.0 / 844.0) < 0.01,
			"Editor Stage fit must preserve portrait aspect ratio")
	# In a taller Godot window Story Map must expand its *graph canvas*, not
	# leave a large unused dark area below a fixed 310px GraphEdit.
	studio.size = Vector2(1366, 900)
	raven._workspace_tabs.current_tab = 3 # Story Map
	await process_frame
	await process_frame
	assert(raven._story_scroll.size.y > 0)
	assert(raven._raven_graph.custom_minimum_size.y >=
		raven._story_scroll.size.y - 1.0)
	assert(raven._raven_graph._canvas.size.y > 310.0,
		"Story Map canvas should grow with a tall Godot editor pane")
	for tab_index in range(6):
		raven._workspace_tabs.current_tab = tab_index
		assert(raven.selected_context()["sceneId"] == "RM-BEAT-00-01")
	assert(raven._asset_library._scene_label.text.contains("RM-BEAT-00-01"))
	assert(raven._raven_graph != null, "Story Map has a native Raven GraphEdit")
	assert(raven._raven_graph._canvas is GraphEdit)
	assert(raven._promotion_view != null)
	assert(raven._promotion_view._summary != null)
	assert(raven._raven_graph._scene_id == "RM-BEAT-00-01")
	assert(raven._raven_graph._name_map.has("RM-BEAT-00-01"))
	# HTML v5 Director has a case-insensitive scene/ID finder. Filtering may
	# change visible list positions but must never change stable scene IDs.
	var full_scene_count: int = raven._scenes.item_count
	raven._scene_search.text = "RM-BEAT-01-01"
	raven._refresh_scene_items()
	assert(raven._scenes.item_count == 1)
	assert(raven._visible_scene_indices[0] == 3)
	raven._on_scene(0)
	assert(raven.selected_context()["sceneId"] == "RM-BEAT-01-01",
		"Selecting filtered list index 0 must resolve the actual scene ID")
	assert(raven._raven_graph._scene_id == "RM-BEAT-01-01")
	raven._scene_search.text = "НЕСУЩЕСТВУЮЩИЙ-ID"
	raven._refresh_scene_items()
	assert(raven._scenes.item_count == 0)
	assert(raven.selected_context()["sceneId"] == "RM-BEAT-01-01",
		"No-match filtering must leave stage/scene context unchanged")
	raven._scene_search.text = ""
	raven._refresh_scene_items()
	assert(raven._scenes.item_count == full_scene_count)
	assert(raven._scenes.get_selected_items()[0] == 3,
		"Clearing finder must reselect the canonical scene")
	raven._on_scene(0)
	assert(raven.selected_context()["sceneId"] == "RM-BEAT-00-01")
	assert(raven._context_views.size() == 1)
	assert(raven._context_views[0].text.contains("Animation"))
	# VNS5-07F1: the Animation tab must contain the *working* StageDesigner
	# editor, not just the old placeholder info label. Stage stays central.
	var animation_tab: Control = raven._workspace_tabs.get_tab_control(4)
	var fx_editor: VBoxContainer = raven._stage_designer._fx_controls
	assert(fx_editor != null and fx_editor.get_parent() != null)
	assert(fx_editor.get_parent().get_parent() == animation_tab,
		"FX editor widgets belong under the visible Animation tab")
	assert(raven._stage_designer._fx_list.is_ancestor_of(fx_editor) == false)
	assert(fx_editor.is_ancestor_of(raven._stage_designer._fx_list))
	assert(raven._stage_designer._fx_play.is_ancestor_of(fx_editor) == false)
	assert(fx_editor.is_ancestor_of(raven._stage_designer._fx_play))
	assert(not raven._workspace_tabs.get_tab_control(0).is_ancestor_of(fx_editor),
		"Stage Inspector no longer doubles as the animation authoring tab")
	var original_fx_count: int = raven._stage_designer._fx_data.get("cues", []).size()
	assert(raven._stage_designer._fx_target.item_count > 0)
	raven._stage_designer._on_fx_add()
	assert(raven._stage_designer._fx_data["cues"].size() == original_fx_count + 1,
		"Animation tab is live and creates a draft cue")
	raven._stage_designer._on_fx_undo()
	assert(raven._stage_designer._fx_data["cues"].size() == original_fx_count,
		"Animation tab FX Undo must preserve the original cue list")
	raven._on_scene(1)
	var selected: Dictionary = raven.selected_context()
	assert(selected["sceneId"] == "RM-BEAT-00-02")
	assert(raven._raven_graph._scene_id == selected["sceneId"])
	assert(raven._raven_graph._name_map.has(selected["sceneId"]))
	raven._on_line(1)
	assert(raven._context_views[0].text.contains(raven.selected_context()["lineId"]))
	assert(raven._save.get_parent() != raven._workspace_scroll)
	assert(raven._path.get_parent() != raven._workspace_scroll)
	if Engine.is_editor_hint():
		raven._on_pane_dragged(260)
		assert(int(EditorInterface.get_editor_settings().get_setting(raven.PANE_SETTING)) == 260)
	raven._scene_panel.visible = false
	raven._line_panel.visible = false
	assert(not raven._scene_panel.visible and not raven._line_panel.visible)
	raven._scene_panel.visible = true
	raven._line_panel.visible = true
	studio._on_toggle_legacy_mode()
	assert(studio._stage_tabs.current_tab == 0)
	for legacy_tab in range(3):
		assert(not studio._stage_tabs.is_tab_hidden(legacy_tab))
	assert(studio._legacy_scenes_panel.visible and studio._legacy_details_panel.visible)
	assert(studio._legacy_toolbar.visible)
	assert(studio._status.visible)
	studio._on_toggle_legacy_mode()
	assert(studio._stage_tabs.current_tab == 3)
	for legacy_tab in range(3):
		assert(studio._stage_tabs.is_tab_hidden(legacy_tab))
	assert(not studio._legacy_scenes_panel.visible and not studio._legacy_details_panel.visible)
	for scroller: ScrollContainer in [
		studio._legacy_preview_scroll, studio._legacy_dialogue_scroll,
		studio._legacy_characters_scroll, studio._migration_scroll
	]:
		assert(scroller != null)
		assert(scroller.vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED)
	studio.queue_free()
	print("Raven VN Studio responsive layout smoke passed")
	quit()
