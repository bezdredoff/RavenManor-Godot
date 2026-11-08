extends SceneTree
## GFX-11-T08: the live game VN frame (nameplate + dialogue + footer/buttons)
## must stay inside the viewport safe area and must not clip copy in RU/BE/EN
## at the two target mobile sizes.
##
## Reuses the same UPDS shell geometry (`vn_shell_layout.gd`), the real
## `raven_vn_game_view.gd` compositor and the pagination fit check from
## `vn_shell_layout_smoke.gd`; no layout math is duplicated here.
const View = preload("res://scripts/raven/raven_vn_game_view.gd")
const Copy = preload("res://scripts/raven/raven_production_localization.gd")

const BEAT_ID := "RM-BEAT-00-02"
const LINE_ID := "RM-BEAT-00-02-L001"
const SPEAKER_ID := "RM-CHAR-EVELYN"
const LOCALES: Array[String] = ["ru", "be", "en"]
## Target mobile sizes with synthetic (not device-reported) safe insets:
## Vector4(left, top, right, bottom), same convention as the view runtime.
const TARGETS: Array[Dictionary] = [
	{"size": Vector2(320, 568), "insets": Vector4(9, 20, 7, 18)},
	{"size": Vector2(390, 844), "insets": Vector4(10, 24, 8, 20)},
]
const EPSILON := 0.01

var _violations: Array[String] = []
var _checks := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for target: Dictionary in TARGETS:
		var viewport_size: Vector2 = target["size"]
		var insets: Vector4 = target["insets"]
		var host := Control.new()
		host.size = viewport_size
		root.add_child(host)
		var view := View.new()
		view.size = viewport_size
		host.add_child(view)
		await process_frame
		_expect(view.size == viewport_size, "%s view did not take the target size" % viewport_size)
		var safe := Rect2(Vector2(insets.x, insets.y),
			Vector2(viewport_size.x - insets.x - insets.z, viewport_size.y - insets.y - insets.w))
		for locale in LOCALES:
			var tag := "%s/%s" % [viewport_size, locale]
			var speaker: String = Copy.speaker_name(SPEAKER_ID, locale)
			var line: String = Copy.line_text(LINE_ID, locale)
			_expect(not speaker.is_empty(), "%s missing canonical speaker copy" % tag)
			_expect(not line.is_empty(), "%s missing canonical dialogue copy" % tag)
			# Unsafe baseline: unmodified frame must already fit the raw viewport.
			view.safe_insets = Vector4.ZERO
			view._layout()
			view.show_beat(BEAT_ID, speaker, line, "1/3", func() -> void: pass, LINE_ID, locale)
			await process_frame
			_audit(view, Rect2(Vector2.ZERO, viewport_size), tag + " raw")
			# Synthetic mobile safe area, applied through the public field.
			view.safe_insets = insets
			view._layout()
			await process_frame
			_expect(view._paging_box_size == view.dialogue.size,
				"%s dialogue pages measured on a stale text box" % tag)
			_audit(view, safe, tag + " safe")
			# Three canonical lines back to back: pagination must still fit and
			# the footer must not grow outside the safe area.
			view.show_beat(BEAT_ID, speaker, line + " " + line + " " + line, "1/3",
				func() -> void: pass, LINE_ID, locale)
			await process_frame
			_expect(view._pages.size() > 1, "%s long line did not paginate" % tag)
			_audit(view, safe, tag + " long")
		host.queue_free()
		await process_frame
	_self_test_audit()
	_expect(_checks >= 500, "audit executed only %d checks; the frame assertions are vacuous" % _checks)
	_expect(_violations.is_empty(),
		"VN frame safe-area/overflow violations:\n" + "\n".join(PackedStringArray(_violations)))
	assert(_violations.is_empty(),
		"VN frame safe-area/overflow violations:\n" + "\n".join(PackedStringArray(_violations)))
	print("Raven VN game frame safe-area and locale overflow smoke passed (%d checks)" % _checks)
	quit()


## Proves the containment audit is not vacuous: an escaping rect must be
## reported, then the synthetic violations are removed again.
func _self_test_audit() -> void:
	var baseline := _violations.size()
	_inside(Rect2(Vector2(-4, -4), Vector2(8, 8)), Rect2(Vector2.ZERO, Vector2(320, 568)), "self-test")
	var detected := _violations.size() - baseline
	while _violations.size() > baseline:
		_violations.pop_back()
	_expect(detected == 2, "audit self-test failed to detect an escaping rect (%d new violations)" % detected)


## Audits one rendered frame: every VN element inside `bounds`, no overlaps,
## and no locale copy wider than the box that draws it.
func _audit(view: Control, bounds: Rect2, tag: String) -> void:
	var panel := _rect_in_view(view, view.dialogue_panel)
	var nameplate := _rect_in_view(view, view.nameplate)
	var dialogue := _rect_in_view(view, view.dialogue)
	var progress := _rect_in_view(view, view.progress)
	var controls := _rect_in_view(view, view.controls_panel)
	_inside(panel, bounds, tag + " dialogue panel")
	_inside(nameplate, bounds, tag + " nameplate")
	_inside(dialogue, bounds, tag + " dialogue text")
	_inside(progress, bounds, tag + " line progress")
	_inside(controls, bounds, tag + " footer strip")
	_inside(progress, panel, tag + " line progress in panel")
	_expect(panel.end.y <= controls.position.y + EPSILON,
		"%s dialogue panel overlaps footer (%.1f > %.1f)" % [tag, panel.end.y, controls.position.y])
	_expect(nameplate.end.y <= dialogue.position.y + EPSILON,
		"%s nameplate overlaps dialogue text (%.1f > %.1f)" % [tag, nameplate.end.y, dialogue.position.y])
	_expect(not nameplate.intersects(dialogue), "%s nameplate intersects dialogue text" % tag)
	_expect(_text_width(view.nameplate, view.nameplate.text) <= view.nameplate.size.x + EPSILON,
		"%s speaker '%s' wider than nameplate %.1f" % [tag, view.nameplate.text, view.nameplate.size.x])
	_expect(_text_width(view.progress, view.progress.text) <= view.progress.size.x + EPSILON,
		"%s progress '%s' wider than its box %.1f" % [tag, view.progress.text, view.progress.size.x])
	_expect(not view._pages.is_empty(), "%s no dialogue pages" % tag)
	for page in view._pages:
		_expect(view._fits_dialogue(page), "%s page clipped: %s" % [tag, page.substr(0, 28)])

	var buttons: Array[Rect2] = []
	for button: Button in [view.skip_button, view.auto_button, view.next_button]:
		var rect := _rect_in_view(view, button)
		buttons.append(rect)
		_inside(rect, bounds, tag + " footer button " + button.name)
		_inside(rect, controls, tag + " footer button " + button.name + " in strip")
		var inner: float = button.size.x - _style_margins(button)
		_expect(_text_width(button, button.text) <= inner + EPSILON,
			"%s footer copy '%s' overflows button %s (%.1f > %.1f)" % [tag, button.text, button.name,
				_text_width(button, button.text), inner])
	_expect(not buttons[0].intersects(buttons[1]), "%s skip/auto overlap" % tag)
	_expect(not buttons[1].intersects(buttons[2]), "%s auto/next overlap" % tag)
	_expect(not buttons[0].intersects(buttons[2]), "%s skip/next overlap" % tag)

	var chapter := _rect_in_view(view, view.chapter)
	var menu := _rect_in_view(view, view.header_menu)
	var history := _rect_in_view(view, view.header_history)
	var settings := _rect_in_view(view, view.header_settings)
	_inside(chapter, bounds, tag + " header title")
	_inside(menu, bounds, tag + " header menu")
	_inside(history, bounds, tag + " header history")
	_inside(settings, bounds, tag + " header settings")
	_expect(menu.end.x <= chapter.position.x + EPSILON, "%s menu overlaps header title" % tag)
	_expect(chapter.end.x <= history.position.x + EPSILON, "%s header title overlaps history" % tag)
	_expect(history.end.x <= settings.position.x + EPSILON, "%s history overlaps settings" % tag)
	for button: Button in [view.header_menu, view.header_history, view.header_settings]:
		var inner: float = button.size.x - _style_margins(button)
		_expect(_text_width(button, button.text) <= inner + EPSILON,
			"%s header copy '%s' overflows %s (%.1f > %.1f)" % [tag, button.text, button.name,
				_text_width(button, button.text), inner])


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_violations.append(message)


func _inside(rect: Rect2, bounds: Rect2, label: String) -> void:
	_expect(rect.position.x >= bounds.position.x - EPSILON, "%s escapes left (%.2f < %.2f)" % [label, rect.position.x, bounds.position.x])
	_expect(rect.position.y >= bounds.position.y - EPSILON, "%s escapes top (%.2f < %.2f)" % [label, rect.position.y, bounds.position.y])
	_expect(rect.end.x <= bounds.end.x + EPSILON, "%s escapes right (%.2f > %.2f)" % [label, rect.end.x, bounds.end.x])
	_expect(rect.end.y <= bounds.end.y + EPSILON, "%s escapes bottom (%.2f > %.2f)" % [label, rect.end.y, bounds.end.y])


## Control rect relative to the VN view, independent of nesting depth.
func _rect_in_view(view: Control, control: Control) -> Rect2:
	var origin := Vector2.ZERO
	var node: Node = control
	while node != null and node != view:
		if node is Control:
			origin += (node as Control).position
		node = node.get_parent()
	return Rect2(origin, control.size)


func _text_width(control: Control, text: String) -> float:
	var font: Font = control.get_theme_font("font")
	var font_size: int = control.get_theme_font_size("font_size")
	return font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x


func _style_margins(control: Control) -> float:
	var style: StyleBox = control.get_theme_stylebox("normal")
	return style.get_margin(SIDE_LEFT) + style.get_margin(SIDE_RIGHT)
