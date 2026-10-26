extends RefCounted

## Raven VN adapter retaining the UPDS line/page contract without importing its
## coupled StorySession, scene indexes or production asset registry.
## Lines may be legacy strings or dictionaries with per-line speaker/text fields.
var scene: Dictionary = {}
var line_index := 0


func open(config: Dictionary) -> void:
	scene = config.duplicate(true)
	line_index = 0


func current_entry() -> Dictionary:
	var lines: Array = scene.get("lines", [])
	if line_index >= lines.size():
		return {"speaker": str(scene.get("speaker", "")), "text": ""}
	var raw: Variant = lines[line_index]
	if raw is Dictionary:
		return {
			"speaker": str(raw.get("speaker", scene.get("speaker", ""))),
			"text": str(raw.get("text", ""))
		}
	return {"speaker": str(scene.get("speaker", "")), "text": str(raw)}


func current_speaker() -> String:
	return str(current_entry().get("speaker", ""))


func current_line() -> String:
	return str(current_entry().get("text", ""))


func advance() -> bool:
	line_index += 1
	return line_index >= scene.get("lines", []).size()


func progress_text() -> String:
	return "%d/%d" % [mini(line_index + 1, scene.get("lines", []).size()), scene.get("lines", []).size()]
