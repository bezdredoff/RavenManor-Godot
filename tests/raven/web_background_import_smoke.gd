extends SceneTree
## Web-only CI: inspect actual Godot-imported texture sizes after second editor import.
const CATALOG = preload("res://data/raven/production/vn_background_catalog.json")
const MAX_SIDE := 1080
const MINIMUM_BG := 26

func _initialize() -> void:
    var entries: Array = CATALOG.data.get("entries", [])
    var errors: Array[String] = []
    if entries.size() < MINIMUM_BG:
        errors.append("Expected at least 26 approved VN backgrounds")
    var seen: Dictionary = {}
    var inspected := 0
    var reduced := 0
    for entry in entries:
        var path := str(entry.get("path", ""))
        if not path.begins_with("res://assets/raven/vn_backgrounds/"):
            errors.append("Background path outside runtime root: " + path)
            continue
        if seen.has(path):
            errors.append("Duplicate catalogued VN background: " + path)
            continue
        seen[path] = true
        if not ResourceLoader.exists(path):
            errors.append("Missing imported VN background: " + path)
            continue
        var texture := load(path) as Texture2D
        if texture == null:
            errors.append("Could not load VN background: " + path)
            continue
        var w := texture.get_width()
        var h := texture.get_height()
        var original_w := int(entry.get("width", 0))
        var original_h := int(entry.get("height", 0))
        if original_w <= 0 or original_h <= 0:
            errors.append("Original dimensions missing: " + path)
        elif absf(float(w) / float(maxi(1, h)) - float(original_w) / float(original_h)) > 0.006:
            errors.append("VN background aspect ratio changed: " + path)
        if w > MAX_SIDE or h > MAX_SIDE or w <= 0 or h <= 0:
            errors.append("Wrong Web background dimensions: %s %dx%d" % [path, w, h])
        if h < original_h:
            reduced += 1
        inspected += 1
    if reduced < MINIMUM_BG:
        errors.append("Not all VN backgrounds were actually reduced")
    if errors.is_empty():
        print("WEB BACKGROUND IMPORT PASS: %d VN backgrounds loaded, all reduced and <= %dpx longest edge." %
            [inspected, MAX_SIDE])
        quit(0)
    else:
        for error in errors:
            push_error(error)
        quit(1)
