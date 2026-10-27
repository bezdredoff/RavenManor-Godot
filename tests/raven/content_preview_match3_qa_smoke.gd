extends SceneTree
## CODE-02-05: QA shortcut must open the exact UPDS-powered board from RM-VS-01.
## No Raven campaign save, first-clear rewards or story progression in preview.
const Preview = preload("res://scripts/raven/content_preview.gd")
const Board = preload("res://scripts/match3/match3_board_presenter.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var launcher_source := FileAccess.get_file_as_string("res://scripts/raven/prototype_launcher.gd")
	assert(launcher_source.contains("ТЕСТИРОВАТЬ MATCH-3 БЕЗ СЮЖЕТА"))
	assert(launcher_source.contains("raven_direct_preview_level"))
	var preview_source := FileAccess.get_file_as_string("res://scripts/raven/content_preview.gd")
	assert(not preview_source.contains("Store.new("), "QA preview must not read/write campaign store")
	assert(not preview_source.contains("level_won\""), "QA preview must not produce reducer events")

	set_meta("raven_direct_preview_level", "RM-LVL-001")
	var preview := Preview.new()
	preview.size = Vector2(390, 844)
	root.add_child(preview)
	await process_frame
	assert(preview.current_kind == "match3")
	assert(preview.current_id == "RM-LVL-001")
	assert(not preview.return_to_map, "Launcher QA shortcut must not create unwanted map backlink")
	assert(not has_meta("raven_direct_preview_level"), "One-shot level request must be consumed")
	assert(preview.board_view.get_script() == Board)
	assert(preview.board_view.name == "QA_UPDSMatch3Board")
	assert(preview.match_game.state == "playing")
	assert(preview.body.custom_minimum_size.x == 0.0, "Old 354px min width must be gone")
	var scroll := preview.body.get_parent() as ScrollContainer
	assert(scroll != null and scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED)
	assert(preview.board_view.help_button != null)
	assert(preview.board_view.motion_button != null)
	var moves := int(preview.match_game.moves_left)
	preview.board_view.show_hint()
	assert(preview.board_view.highlighted.size() == 2)
	assert(int(preview.match_game.moves_left) == moves, "Hint must be read-only in QA")

	# The same real UPDS gameplay can complete without awarding Raven points.
	preview.board_view.reduced_motion = true
	var safety := 0
	while str(preview.match_game.state) == "playing" and safety < 40:
		var hint: Dictionary = preview.match_game.get_hint_move()
		assert(not hint.is_empty(), "No legal hint while testing QA entry")
		preview.board_view.tap_cell(int(hint.first))
		preview.board_view.tap_cell(int(hint.second))
		safety += 1
	assert(preview.match_game.state == "won")
	assert(preview.level_status.text.contains("не изменены"))
	assert(preview.match_game.level_data.id == "RM-LVL-001")

	preview._open_level("RM-LVL-002")
	await process_frame
	assert(preview.current_id == "RM-LVL-002")
	assert(preview.match_game.level_data.id == "RM-LVL-002")
	assert(preview.board_view.get_script() == Board)
	preview._show_menu()
	assert(preview.current_kind == "menu" and preview.match_game == null)

	# The map's existing selected-object preview link is preserved separately.
	preview.queue_free()
	await process_frame
	set_meta("raven_map_preview_level", "RM-LVL-003")
	var map_preview := Preview.new()
	root.add_child(map_preview)
	await process_frame
	assert(map_preview.return_to_map and map_preview.current_id == "RM-LVL-003")
	assert(map_preview.board_view.get_script() == Board)
	assert(not has_meta("raven_map_preview_level"))
	map_preview.queue_free()
	print("Raven Manor Match-3 QA shortcut and UPDS Content Preview parity smoke passed.")
	quit()
