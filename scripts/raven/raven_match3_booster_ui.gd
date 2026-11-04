extends RefCounted
## Read-only Match-3 booster presentation. Only this file owns booster
## button labels, unlock visibility and locale copy; game rules and inventory
## mutations remain in RavenReducer/RavenMatch3Session.
const MobileLayout = preload("res://scripts/match3/match3_mobile_layout.gd")
const COPY := {
	"ru": {"hammer":"Молот", "shuffle":"Перемешать", "selected":"Выбран", "target":"Выберите плитку или блокер для молотка.", "saved":"Не удалось сохранить применение бустера", "unavailable":"Перемешивание сейчас недоступно"},
	"be": {"hammer":"Молат", "shuffle":"Перамяшаць", "selected":"Выбраны", "target":"Абярыце плітку або блакер для молата.", "saved":"Не ўдалося захаваць выкарыстанне бустара", "unavailable":"Перамяшэнне цяпер недаступнае"},
	"en": {"hammer":"Hammer", "shuffle":"Shuffle", "selected":"Selected", "target":"Select a tile or blocker for the hammer.", "saved":"Could not save booster use", "unavailable":"Shuffle is unavailable right now"}
}


static func text(key: String, locale: String) -> String:
	var lang: String = locale if COPY.has(locale) else "en"
	return str(COPY[lang].get(key, key))


static func render_bar(parent: VBoxContainer, state: Dictionary, locale: String,
		active_booster: String, on_hammer: Callable, on_shuffle: Callable) -> void:
	# Parent order (fiction / bar / board / hint) must match the existing UI.
	var bar := HBoxContainer.new()
	bar.name = "RavenBoosterBar"
	bar.add_theme_constant_override("separation", 8)
	parent.add_child(bar)
	var inventory: Dictionary = state.get("boosterInventory", {})
	var restorations: Array = state.get("completedRestorations", [])
	var hammer_count := int(inventory.get("hammer", 0))
	var shuffle_count := int(inventory.get("shuffle", 0))
	var hammer_text := text("hammer", locale)
	if active_booster == "hammer":
		hammer_text += " · " + text("selected", locale)
	var hammer := _button(bar, "%s ×%d" % [hammer_text, hammer_count], on_hammer)
	hammer.name = "RavenHammerBooster"
	hammer.disabled = not restorations.has("RM-REST-001") or hammer_count <= 0
	var shuffle := _button(bar, "%s ×%d" % [text("shuffle", locale), shuffle_count], on_shuffle)
	shuffle.name = "RavenShuffleBooster"
	shuffle.disabled = not restorations.has("RM-REST-002") or shuffle_count <= 0


static func render_target_hint(parent: VBoxContainer, locale: String) -> void:
	var label := Label.new()
	label.text = text("target", locale)
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color("d4ccbe"))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(0, 54)
	parent.add_child(label)


static func _button(parent: Container, caption: String, on_pressed: Callable) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(0, MobileLayout.MIN_TAP)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(on_pressed)
	parent.add_child(button)
	return button
