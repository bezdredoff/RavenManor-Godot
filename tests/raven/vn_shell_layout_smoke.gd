extends SceneTree
const View = preload("res://scripts/raven/raven_vn_game_view.gd")
const Slice = preload("res://scripts/raven/vertical_slice.gd")
const Store = preload("res://scripts/raven/raven_campaign_store.gd")
const Memory = preload("res://tests/support/memory_storage.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for viewport_size in [Vector2(320, 568), Vector2(340, 640), Vector2(360, 780), Vector2(390, 844), Vector2(430, 932), Vector2(844, 390), Vector2(1366, 768)]:
		var host := Control.new()
		host.size = viewport_size
		root.add_child(host)
		var view := View.new()
		view.size = Vector2(minf(viewport_size.x, 430), minf(viewport_size.y, 932))
		host.add_child(view)
		await process_frame
		for locale in ["ru", "be", "en"]:
			var long_text: String = {"ru": "Очень длинная реплика проверяет переносы и чтение всех страниц. ", "be": "Доўгая рэпліка правярае пераносы, літары ў і ўсе старонкі. ", "en": "A long dialogue checks wrapping and reading every page. "}[locale].repeat(4)
			view.show_beat("RM-BEAT-00-02", "Эвелин", long_text, "1/3", func() -> void: pass, "RM-BEAT-00-02-L001", locale)
			await process_frame
			assert(view._pages.size() > 1)
			assert(view.dialogue_panel.position.y > 60)
			assert(view.dialogue_panel.get_rect().end.y <= view.controls_panel.position.y)
			assert(view.progress.get_rect().end.y <= view.dialogue_panel.size.y)
			assert(not view.dialogue.get_rect().intersects(view.progress.get_rect()))
			for button in [view.skip_button, view.auto_button, view.next_button]:
				assert(button.size.y >= 44 and button.size.x >= 44)
				assert(button.get_rect().end.x <= view.controls_panel.size.x)
			assert(not view.skip_button.get_rect().intersects(view.auto_button.get_rect()))
			assert(not view.auto_button.get_rect().intersects(view.next_button.get_rect()))
			for page in view._pages:
				assert(view._fits_dialogue(page), "Page clipped at %s/%s" % [viewport_size, locale])
		view.safe_insets = Vector4(9, 20, 7, 18)
		view._layout()
		assert(view.controls_panel.get_rect().end.y <= view.size.y - 18)
		assert(view.header_menu.position.y >= 20)
		view._toggle_auto()
		assert(not view._auto_timer.is_stopped())
		view.set_interaction_blocked(true)
		var page_before: int = view._page_index
		view._on_auto_timeout()
		view._next()
		assert(view._page_index == page_before and view._auto_timer.is_stopped())
		view.set_interaction_blocked(false)
		assert(not view._auto_timer.is_stopped())
		var touch := InputEventScreenTouch.new()
		touch.pressed = true
		view._on_dialogue_gui_input(touch)
		var mouse := InputEventMouseButton.new()
		mouse.button_index = MOUSE_BUTTON_LEFT
		mouse.pressed = true
		view._on_dialogue_gui_input(mouse)
		assert(view._page_index == page_before + 1, "Touch emulation doubled advance")
		host.queue_free()
		await process_frame
	var slice := Slice.new()
	slice.store = Store.new(Memory.new())
	root.add_child(slice)
	await process_frame
	assert(not slice.technical_shell.visible and slice.vn_frame.visible)
	assert(slice.vn_view.get_parent() == slice.vn_frame)
	var original_view: Control = slice.vn_view
	slice.vn_view._toggle_auto()
	slice._advance_vn()
	assert(slice.vn_view == original_view and slice.vn_view._auto_mode, "Auto/view lost between lines")
	slice._open_pause()
	assert(slice.vn_view._interaction_blocked and slice.vn_view._auto_timer.is_stopped())
	slice.pause_dialog.hide()
	assert(not slice.vn_view._interaction_blocked)
	slice.queue_free()
	print("Raven UPDS VN shell layout and input smoke passed")
	quit()
