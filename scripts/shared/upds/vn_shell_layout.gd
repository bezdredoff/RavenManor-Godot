extends RefCounted
## Extract/adapt UPDS vn_screen.gd::_layout_vn (donor 3deed628, blob c44edec0).
## Pure geometry; Raven owns artwork/staging, text metrics and campaign state.
## Donor controls are a separate strip; no story or private asset dependencies.

static func geometry(size: Vector2, insets: Vector4 = Vector4.ZERO) -> Dictionary:
	var w := maxf(1, size.x - insets.x - insets.z)
	var h := maxf(1, size.y - insets.y - insets.w)
	var tiny := w <= 340.0
	var header_height := 56.0 if tiny else 60.0
	var controls_height := maxf(clampf(h * 0.09, 58.0 if tiny else 60.0, 82.0), 58.0 if tiny else 63.0)
	var dialogue_height := clampf(h * 0.22, 154.0, 198.0)
	var margin := 8.0 if tiny else 12.0
	var top := h - (controls_height + dialogue_height - (8.0 if tiny else 10.0))
	var panel_height := dialogue_height - (13.0 if tiny else 17.0)
	var panel_width := w - margin * 2.0
	var text_margin := 16.0 if tiny else 22.0
	var button_width := (w - 20.0 - 14.0) / 3.0
	var origin := Vector2(insets.x, insets.y)
	var buttons: Array[Rect2] = []
	for index in 3:
		buttons.append(Rect2(10 + index * (button_width + 7), 6, button_width, controls_height - 12))
	return {
		"header": Rect2(origin, Vector2(w, header_height)),
		"menu": Rect2(origin + Vector2(6, 5), Vector2(44, 44)),
		"history": Rect2(origin + Vector2(w - 100, 5), Vector2(44, 44)),
		"settings": Rect2(origin + Vector2(w - 50, 5), Vector2(44, 44)),
		"title": Rect2(origin + Vector2(56, 5), Vector2(maxf(1, w - 162), 44)),
		"dialogue": Rect2(origin + Vector2(margin, top), Vector2(panel_width, panel_height)),
		"nameplate": Rect2(14, -28, minf(200, panel_width - 28), 38),
		"text": Rect2(text_margin, 34, maxf(1, panel_width - 2 * text_margin), panel_height - 65),
		"progress": Rect2(text_margin, panel_height - 28, panel_width - 2 * text_margin, 22),
		"controls": Rect2(origin + Vector2(0, h - controls_height), Vector2(w, controls_height)),
		"buttons": buttons,
	}
