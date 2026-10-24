extends RefCounted

## Raven VN adapter retaining the UPDS line/page contract without importing its
## coupled StorySession, scene indexes or production asset registry.
var scene: Dictionary = {}
var line_index := 0


func open(config: Dictionary) -> void:
	scene = config.duplicate(true)
	line_index = 0


func current_line() -> String:
	var lines: Array = scene.get("lines", [])
	return str(lines[line_index]) if line_index < lines.size() else ""


func advance() -> bool:
	line_index += 1
	return line_index >= scene.get("lines", []).size()


func progress_text() -> String:
	return "%d/%d" % [mini(line_index + 1, scene.get("lines", []).size()), scene.get("lines", []).size()]
