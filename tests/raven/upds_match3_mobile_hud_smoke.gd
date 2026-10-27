extends SceneTree
## CODE-02D viewport contract; actual Godot presenter and shell, no campaign save.
const Layout = preload("res://scripts/match3/match3_mobile_layout.gd")
const Board = preload("res://scripts/match3/match3_board_presenter.gd")
const Game = preload("res://scripts/raven/raven_match3_game.gd")
const Skin = preload("res://scripts/raven/raven_match3_theme.gd")
const Content = preload("res://data/raven/rm_vs_01_content.json")
const Slice = preload("res://scripts/raven/vertical_slice.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var safe := Layout.native_safe_insets(Vector2(390, 844), Vector2i(1170, 2532), Rect2i(0, 60, 1170, 2442))
	assert(safe == Vector4(0, 20, 0, 10))
	assert(Layout.native_safe_insets(Vector2(390, 844), Vector2i(1170, 2532), Rect2i(-1, 0, 1170, 2532)) == Vector4.ZERO)
	assert(Layout.gutter(14, safe.y) == 34)
	var game := Game.new(Content.data.levels[0])
	var host := Control.new()
	host.size = Vector2(390, 844)
	root.add_child(host)
	var board := Board.new()
	host.add_child(board)
	board.setup(game, Skin.placeholder())
	await process_frame
	for viewport_width in [320.0, 390.0, 412.0, 430.0]:
		var usable := Layout.content_width(viewport_width)
		board.apply_available_width(usable)
		await process_frame
		var dims := Layout.board_extent(board._cell_size, 6, 6)
		assert(dims.x <= usable, "Board must not force horizontal scrolling")
		assert(is_equal_approx(board.board_area.custom_minimum_size.x, dims.x))
		assert(board.cells.size() == 36)
		assert(board.hint_button.custom_minimum_size.y >= 44)
		assert(board.help_button.custom_minimum_size.y >= 44)
		assert(board.motion_button.custom_minimum_size.y >= 44)
		assert(board.retry_button.custom_minimum_size.y >= 44)
		assert(board.objective.text.contains("Ходы:"))
		assert(board.objective.text.contains("\n"), "Moves must be distinct line beneath objectives")
		assert(board.board_area.get_node("UPDSBoardShape").size.x == dims.x)
		assert(board.board_area.get_node("UPDSTileMotion").size.x == dims.x)
		assert(board.board_area.get_node("UPDSClearImpacts").size.x == dims.x)
	var saved_seed := game.moves_left
	board.apply_available_width(Layout.content_width(320.0))
	assert(game.moves_left == saved_seed, "Reflow must not recreate UPDS game or spend moves")
	assert(Layout.tile_size(292.0, 6) >= 44.0, "320px viewport must have usable thumb targets")
	assert(Layout.tile_size(260.0, 8) < 44.0, "Narrow eight-column boards need a future screen gate")
	var scene := Slice.new()
	host.add_child(scene)
	await process_frame
	var vertical_root: VBoxContainer = scene.body.get_parent().get_parent() as VBoxContainer
	assert(vertical_root != null)
	assert(scene.body.custom_minimum_size.x == 0.0, "No old 354px hard-coded min width")
	var scroll := scene.body.get_parent() as ScrollContainer
	assert(scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED)
	var footer: GridContainer = vertical_root.get_child(vertical_root.get_child_count() - 1) as GridContainer
	assert(footer.columns == 2, "Footer must fit narrow portrait screens")
	host.queue_free()
	print("Raven Manor CODE-02D mobile HUD layout and safe-area smoke passed.")
	quit()
