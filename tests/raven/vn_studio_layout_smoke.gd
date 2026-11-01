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
	raven._scene_panel.visible = false
	raven._line_panel.visible = false
	assert(not raven._scene_panel.visible and not raven._line_panel.visible)
	raven._scene_panel.visible = true
	raven._line_panel.visible = true
	studio._stage_tabs.current_tab = 0
	studio._on_workspace_changed(0)
	assert(studio._legacy_scenes_panel.visible and studio._legacy_details_panel.visible)
	assert(studio._legacy_toolbar.visible)
	assert(studio._status.visible)
	studio._stage_tabs.current_tab = 3
	studio._on_workspace_changed(3)
	assert(not studio._legacy_scenes_panel.visible and not studio._legacy_details_panel.visible)
	studio.queue_free()
	print("Raven VN Studio responsive layout smoke passed")
	quit()
