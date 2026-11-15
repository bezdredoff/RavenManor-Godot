extends SceneTree
## MAP-EDIT-05: bulk AI-only constraints clear with preview, confirmation,
## provenance, OPEN boundary policy, Undo/Redo and saved MAP-QA-07B replay.
const Routes = preload("res://addons/room_builder_routes/route_document.gd")
const Freehand = preload("res://addons/room_builder_routes/route_freehand.gd")
const View = preload("res://addons/room_builder_routes/route_editor_view.gd")
const Adapter = preload("res://scripts/raven/first_floor_integrated_draft_adapter.gd")
const Preview = preload("res://addons/room_builder_routes/route_preview_source.gd")
const SOURCE := "res://assets/raven/map/qa/first_floor_hall_pilot.v1.json"
const PROJECT := "res://assets/raven/map/qa/drafts/hall_routes_draft.v1.json"
const CANONICAL := "res://data/raven/manor_greybox_graph.json"
const ART := "res://a_detailed_top_down_isometric_game_map_illustratio.png"
const TEMP := "user://room_builder_routes/map_edit_05_constraints_smoke.json"
const HALL := "RM-ROOM-HALL"


func _initialize() -> void:
	call_deferred("_run")


func _contains_zone(doc: Dictionary, group: String, id: String) -> bool:
	for zone in doc[group]:
		if str(zone.get("id", "")) == id:
			return true
	return false


func _run() -> void:
	var source_before: String = FileAccess.get_file_as_string(SOURCE)
	var project_before: String = FileAccess.get_file_as_string(PROJECT)
	var canonical_before: String = FileAccess.get_file_as_string(CANONICAL)
	var art_before: String = FileAccess.get_sha256(ART)
	var opened: Dictionary = Routes.load_draft(PROJECT)
	assert(opened.get("ok", false), str(opened.get("error", "")))
	var original: Dictionary = opened["document"]
	assert(original["approval"] == "DRAFT_ONLY" and original["productionReady"] == false)
	assert(not original.has("blockedCellOrigins") and not original.has("walkableBoundaryMode"))
	assert(original["walkablePolygons"].size() == 5)
	assert(original["noGoPolygons"].size() == 10)
	assert(original["blockedCells"].is_empty())
	assert(Routes.zone_origin(original["walkablePolygons"][0], "walkablePolygons") == "AI_DRAFT")
	assert(Routes.zone_origin(original["noGoPolygons"][0], "noGoPolygons") == "AI_DRAFT")

	# A legacy draft loads without migrating/deleting anything. New manually
	# authored zones and painted cells are never silently treated as AI.
	var add_green := Routes.add_zone_rectangle(original, "walkablePolygons",
		Vector2(20, 20), Vector2(60, 60), HALL)
	assert(add_green.get("ok", false), str(add_green.get("error", "")))
	var green_id: String = str(add_green["id"])
	var add_red := Routes.add_zone_rectangle(add_green["document"], "noGoPolygons",
		Vector2(4, 4), Vector2(12, 12), HALL)
	assert(add_red.get("ok", false), str(add_red.get("error", "")))
	var red_id: String = str(add_red["id"])
	var painted := Routes.set_blocked(add_red["document"], "A1", true)
	assert(painted.get("ok", false), str(painted.get("error", "")))
	assert(painted["document"]["blockedCellOrigins"]["A1"] == "USER_DRAFT")
	var generated := Routes.set_blocked(painted["document"], "B1", true)
	assert(generated.get("ok", false), str(generated.get("error", "")))
	var editing: Dictionary = generated["document"]
	# Explicit provenance for a future imported AI cell; older unclassified
	# blockedCells remain unchanged by the bulk-clear selector.
	editing["blockedCellOrigins"]["B1"] = "AI_DRAFT"
	assert(Routes.validate(editing).get("ok", false))
	var baseline := JSON.stringify(editing)
	var summary: Dictionary = Routes.ai_constraints_preview(editing)
	assert(summary.get("ok", false), str(summary.get("error", "")))
	assert(summary["walkableIds"].size() == 5)
	assert(summary["noGoIds"].size() == 10)
	assert(summary["blockedCells"] == ["B1"])
	assert(int(summary["count"]) == 16)
	assert(summary["retainedWalkable"] == 1 and summary["retainedNoGo"] == 1)
	assert(summary["retainedBlocked"] == 1)

	var cleared: Dictionary = Routes.clear_ai_constraints(editing)
	assert(cleared.get("ok", false), str(cleared.get("error", "")))
	var cleaned: Dictionary = cleared["document"]
	assert(cleaned["approval"] == "DRAFT_ONLY")
	assert(cleaned["walkableBoundaryMode"] == "OPEN")
	assert(cleaned["walkablePolygons"].size() == 1 and _contains_zone(cleaned, "walkablePolygons", green_id))
	assert(cleaned["noGoPolygons"].size() == 1 and _contains_zone(cleaned, "noGoPolygons", red_id))
	assert(cleaned["blockedCells"] == ["A1"] and cleaned["blockedCellOrigins"]["A1"] == "USER_DRAFT")
	assert(cleaned["waypoints"] == editing["waypoints"], "Clearing must never move or re-ID waypoints")
	assert(cleaned["routes"] == editing["routes"], "Clearing must never modify existing routes")
	assert(Routes.restriction_at(Vector2(100, 100), cleaned)["kind"] == "allowed")
	assert(Freehand._room_error(cleaned, HALL, Vector2(100, 100)).is_empty(),
		"No invisible source WALKABLE mask may remain in freehand validation")
	var outside_wp := Routes.add_waypoint(cleaned, Vector2(100, 100), "User draft waypoint", HALL)
	assert(outside_wp.get("ok", false), str(outside_wp.get("error", "")))
	assert(Routes.room_for_id(outside_wp["document"], str(outside_wp["id"])) == HALL)
	assert(not Routes.set_walkable_boundary_mode(cleaned, true).get("ok", false),
		"Re-enabling a restrictive partial user mask must fail rather than strand routes")
	assert(not Routes.clear_ai_constraints(cleaned).get("ok", false))
	assert(JSON.stringify(editing) == baseline, "Bulk-clear proposals cannot mutate the input")

	# Godot-native preview, destructive confirmation, cancelled previews, single
	# history step, Undo/Redo and no unintended persistence before Save.
	var view = View.new()
	root.add_child(view)
	view._set_document(editing, false)
	view._preview_clear_ai()
	assert(JSON.stringify(view.document) == baseline)
	assert(not view.clear_ai_proposal.is_empty())
	assert(view.canvas.clear_ai_preview["count"] == 16)
	assert(view.clear_ai_confirmation.dialog_text.contains("PREVIEW"))
	view._discard_clear_ai_preview()
	assert(JSON.stringify(view.document) == baseline)
	assert(view.canvas.clear_ai_preview.is_empty())
	view._preview_clear_ai()
	view._confirm_clear_ai()
	assert(JSON.stringify(view.document) == JSON.stringify(cleaned))
	assert(view.history.size() == 1 and view.future.is_empty())
	assert(view.canvas.clear_ai_preview.is_empty())
	assert(view.dirty_label.text.contains("UNSAVED"))
	view._undo()
	assert(JSON.stringify(view.document) == baseline)
	view._redo()
	assert(JSON.stringify(view.document) == JSON.stringify(cleaned))
	assert(view.history.size() == 1)
	# A further policy edit has its own Undo/Redo and updates canvas immediately.
	view.walkable_boundary_checkbox.set_pressed_no_signal(false)
	assert(not view.canvas.document.is_empty())
	view.queue_free()

	var saved: Dictionary = Routes.save_draft(TEMP, outside_wp["document"])
	assert(saved.get("ok", false), str(saved.get("error", "")))
	var loaded: Dictionary = Routes.load_draft(TEMP)
	assert(loaded.get("ok", false), str(loaded.get("error", "")))
	assert(loaded["document"]["walkableBoundaryMode"] == "OPEN")
	assert(loaded["document"]["waypoints"].size() == original["waypoints"].size() + 1)
	assert(loaded["document"]["noGoPolygons"].size() == 1)
	var runtime: Dictionary = Adapter.load_source(Preview.USER, TEMP)
	assert(runtime.get("ok", false), str(runtime.get("error", "")))
	assert(runtime["contract"]["approval"] == "TEST_ONLY")
	assert(runtime["document"]["approval"] == "DRAFT_ONLY")
	assert(runtime["waypointCount"] == original["waypoints"].size() + 1)
	assert(FileAccess.get_file_as_string(SOURCE) == source_before)
	assert(FileAccess.get_file_as_string(PROJECT) == project_before)
	assert(FileAccess.get_file_as_string(CANONICAL) == canonical_before)
	assert(FileAccess.get_sha256(ART) == art_before)
	assert(DirAccess.remove_absolute(ProjectSettings.globalize_path(TEMP)) == OK)
	print("MAP-EDIT-05 editable AI navigation constraints and integrated runtime passed")
	quit()
