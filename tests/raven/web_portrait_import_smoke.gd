extends SceneTree
## Web CI only: verify actual Godot-imported textures, not merely .import text.
const CATALOG = preload("res://data/raven/production/vn_character_catalog.json")
const EXPECTED_MAX_SIDE := 1024
const EXPECTED_COUNT := 62

func _initialize() -> void:
    var entries: Array = CATALOG.data.get("entries", [])
    var failures: Array[String] = []
    if entries.size() < EXPECTED_COUNT:
        failures.append("Catalog has fewer than 62 portraits")
    var checked := 0
    var transparency_checked := 0
    for entry in entries:
        var path := str(entry.get("path", ""))
        if not path.begins_with("res://assets/raven/characters/"):
            failures.append("Invalid character path: " + path)
            continue
        if not ResourceLoader.exists(path):
            failures.append("Missing character resource: " + path)
            continue
        var texture := load(path) as Texture2D
        if texture == null:
            failures.append("Could not load character texture: " + path)
            continue
        var width := texture.get_width()
        var height := texture.get_height()
        var largest := maxi(width, height)
        if largest > EXPECTED_MAX_SIDE or largest <= 0:
            failures.append("%s imported as %dx%d, expected longest edge <= %d" %
                [path, width, height, EXPECTED_MAX_SIDE])
        var original_width := int(entry.get("width", 0))
        var original_height := int(entry.get("height", 0))
        if original_width <= 0 or original_height <= 0:
            failures.append("Missing original dimensions in catalog: " + path)
        else:
            var ratio := float(width) / float(maxi(1, height))
            var original_ratio := float(original_width) / float(original_height)
            if absf(ratio - original_ratio) > 0.005:
                failures.append("Aspect ratio changed: " + path)
        # Check representative neutral sprites preserve the alpha channel.
        if path.ends_with("/base_neutral.webp"):
            var raw := Image.load_from_file(path)
            var imported := texture.get_image()
            if raw == null or imported == null:
                failures.append("Cannot inspect portrait transparency: " + path)
            elif raw.detect_alpha() != Image.ALPHA_NONE and imported.detect_alpha() == Image.ALPHA_NONE:
                failures.append("Imported portrait lost transparency: " + path)
            transparency_checked += 1
        checked += 1
    if transparency_checked < 4:
        failures.append("Expected neutral portraits from all four characters")
    if failures.is_empty():
        print("WEB PORTRAIT IMPORT PASS: %d textures, <= 1024px longest edge, alpha samples=%d." %
            [checked, transparency_checked])
        quit(0)
    else:
        for failure in failures:
            push_error(failure)
        quit(1)
