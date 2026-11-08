extends SceneTree
## MAP-QA-01: standalone Godot JSON parsing/coordinate smoke; no scene or save mutation.
const DATA_PATH := "res://assets/raven/map/qa/first_floor_hall_pilot.v1.json"

func _initialize() -> void:
    var json_string := FileAccess.get_file_as_string(DATA_PATH)
    assert(not json_string.is_empty(), "Missing Hall QA data")
    var candidate: Variant = JSON.parse_string(json_string)
    assert(candidate is Dictionary, "QA JSON must load in Godot")
    assert(candidate.kind == "raven-first-floor-hall-qa-pilot")
    assert(candidate.approval == "DRAFT_ONLY" and not candidate.integrationAllowed)
    assert(candidate.coordinateSpaces.pilot == "image-pixel")
    assert(candidate.coordinateSpaces.pixelToWorldPlan == null)
    assert(not candidate.coordinateSpaces.apply65DegreeProjectionToBaseImage)
    assert(candidate.source.dimensionsPx.size() == 2)
    assert(int(candidate.source.dimensionsPx[0]) == 1672 and int(candidate.source.dimensionsPx[1]) == 941)
    assert(candidate.canonicalReferences.anchorIdentities.size() == 13)
    assert(candidate.waypoints.size() == 7)
    var known: Dictionary = {}
    for point in candidate.waypoints:
        var xy: Array = point.pointPx
        assert(xy.size() == 2)
        var foot := Vector2(float(xy[0]), float(xy[1]))
        assert(foot.x >= 0.0 and foot.x < 1672.0 and foot.y >= 0.0 and foot.y < 941.0)
        assert(not known.has(point.id))
        known[point.id] = foot
    assert(known.has(candidate.actor.initialPointId))
    for edge in candidate.edges:
        assert(known.has(edge["from"]) and known.has(edge["to"]))
    assert(known.has(candidate.virtualPortal.approachPointId))
    assert(known.has(candidate.virtualPortal.returnSpawnPointId))
    assert(not candidate.virtualPortal.physicalDoorConfirmed)
    var png_texture: Texture2D = load("res://a_detailed_top_down_isometric_game_map_illustratio.png")
    assert(png_texture != null and png_texture.get_width() == 1672 and png_texture.get_height() == 941)
    print("MAP-QA-01 Hall pilot Godot JSON/image smoke passed (QA-only pixel coordinates).")
    quit()
