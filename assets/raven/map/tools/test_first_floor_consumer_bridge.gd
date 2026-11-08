extends SceneTree

# Verifies Agent C's already-merged audit against Agent A's approved reference-only
# manifest. Never constructs world-plan coordinates or gameplay geometry.
const GEOMETRY_ADAPTER = preload("res://scripts/raven/manor_navigation_geometry_adapter.gd")

func _read_dict(path: String) -> Dictionary:
    var text: String = FileAccess.get_file_as_string(path)
    var decoded: Variant = JSON.parse_string(text)
    if not decoded is Dictionary:
        printerr("Invalid JSON dictionary " + path)
        return {}
    return decoded

func _initialize() -> void:
    var manifest: Dictionary = _read_dict("res://assets/raven/map/first_floor_manifest.v1.json")
    var graph: Dictionary = _read_dict("res://data/raven/manor_greybox_graph.json")
    var world: Dictionary = _read_dict("res://data/raven/season1_world_map.json")
    if manifest.is_empty() or graph.is_empty() or world.is_empty():
        quit(2)
        return
    var audit: Dictionary = GEOMETRY_ADAPTER.audit_art_reference(graph, manifest, world)
    if not audit.get("ok", false):
        printerr("Raven ABC art reference contract audit FAILED: " + str(audit))
        quit(2)
        return
    if int(audit.get("idCount", -1)) != 13 or int(audit.get("calibratedCount", -1)) != 0 or bool(audit.get("usableNavigationData", true)):
        printerr("Raven ABC art contract gained unintended navigation authority: " + str(audit))
        quit(2)
        return
    var unsafe_preview: Dictionary = GEOMETRY_ADAPTER.apply_preview(graph, {
        "schemaVersion": 1,
        "coordinateSpace": "world-plan",
        "productionReady": false,
        "anchors": []
    })
    if bool(unsafe_preview.get("ok", false)):
        printerr("Raven ABC art contract unexpectedly allowed missing coordinates")
        quit(2)
        return
    print("Raven ABC approved reference-only art contract smoke passed")
    quit()
