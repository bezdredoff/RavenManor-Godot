extends SceneTree
## MAP-EDIT-02: saved/exported draft -> existing route session -> real Onoe feet.
## Only isolated QA user:// fixture and one-shot selection; never the campaign.
const PILOT = preload("res://scenes/raven/tests/first_floor_hall_movement_pilot.tscn")
const Routes = preload("res://addons/room_builder_routes/route_document.gd")
const Source = preload("res://addons/room_builder_routes/route_preview_source.gd")
const Launch = preload("res://addons/room_builder_routes/route_preview_launch.gd")
const Graph = preload("res://scripts/raven/manor_navigation_graph.gd")
const TEMP := "user://room_builder_routes/map_edit_02_runtime_test.json"
const CANONICAL := "res://data/raven/manor_greybox_graph.json"


func _initialize() -> void:
	call_deferred("_run")


func _write_test_document(doc: Dictionary) -> void:
	var stream := FileAccess.open(TEMP, FileAccess.WRITE)
	assert(stream != null)
	stream.store_string(JSON.stringify(doc) + "\n")
	stream.close()


func _instantiate_pilot():
	var pilot = PILOT.instantiate()
	root.add_child(pilot)
	return pilot


func _run() -> void:
	var qa_source := FileAccess.get_file_as_string(Routes.HALL_SOURCE)
	var canonical := FileAccess.get_file_as_string(CANONICAL)
	assert(not qa_source.is_empty() and not canonical.is_empty())
	var imported := Routes.import_hall()
	assert(imported.ok)
	var original: Dictionary = imported.document
	var drafted := Routes.set_route_cells(original, "QA-ROUTE-001", "AA24 → AA23 → AA22")
	assert(drafted.ok, str(drafted.get("error", "")))
	var doc: Dictionary = drafted.document
	assert(Routes.save_draft(TEMP, doc).ok)
	var saved := Routes.load_draft(TEMP)
	assert(saved.ok and saved.document.routes[0].cells.size() == 3)

	var read = Source.new()
	assert(read.load_source(Source.USER, TEMP), read.error_text)
	assert(read.graph.has_anchor("QA-ROUTE-001-STEP-001"))
	assert(read.graph.position("QA-ROUTE-001-STEP-001") == Vector2(848, 720))
	assert(read.graph.route("QA-HALL-SPAWN", "QA-HALL-CENTRE") == ["QA-HALL-SPAWN", "QA-ROUTE-001-STEP-001", "QA-HALL-CENTRE"])
	assert(read.provisional_routes.size() == 6)
	assert(read.data.approval == "DRAFT_ONLY")
	assert(not read.data.productionReady)
	assert(not read.load_source(Source.USER, "res://data/raven/manor_greybox_graph.json"))
	assert(not read.load_source("bogus"))
	assert(not Launch.stage("user", "../somewhere.json").ok)
	assert(not Launch.stage("original", TEMP).ok)

	# The original Hall remains an independent regression baseline.
	assert(Launch.stage(Source.BASELINE).ok)
	var original_pilot = _instantiate_pilot()
	await process_frame
	assert(original_pilot.ready_for_qa and original_pilot.source_kind == Source.BASELINE)
	assert(original_pilot.qa.graph.anchors().size() == 7)
	assert(original_pilot.actor.position == Vector2(836, 746))
	original_pilot.queue_free()
	await process_frame

	# One-shot selection is explicitly staged by the editor and consumed by
	# a fresh scene. No in-memory unsaved document can enter the pilot.
	assert(Launch.stage(Source.USER, TEMP).ok)
	var pilot = _instantiate_pilot()
	await process_frame
	assert(pilot.ready_for_qa, pilot.feedback)
	assert(pilot.source_kind == Source.USER and pilot.source_path == TEMP)
	assert(pilot.qa.graph.anchors().size() == 8)
	assert(not FileAccess.file_exists(Launch.FILE), "One-shot selection is consumed")
	assert(pilot.request_waypoint("QA-HALL-CENTRE"))
	assert(pilot.actor.segment_destination() == "QA-ROUTE-001-STEP-001", "Must NOT shortcut to Centre")
	var initial: Vector2 = pilot.actor.position
	pilot.actor.advance(0.04)
	assert(pilot.actor.position != initial and pilot.session.current_anchor() == "QA-HALL-SPAWN")
	assert(pilot.pause_movement())
	var held: Vector2 = pilot.actor.position
	pilot.actor.advance(20.0)
	assert(pilot.actor.position == held and pilot.actor.is_paused())
	assert(pilot.resume_movement())
	pilot.actor.advance(10.0)
	assert(pilot.session.current_anchor() == "QA-ROUTE-001-STEP-001")
	assert(pilot.actor.position == Vector2(848, 720))
	assert(pilot.actor.segment_destination() == "QA-HALL-CENTRE")
	pilot.actor.advance(10.0)
	assert(pilot.session.current_anchor() == "QA-HALL-CENTRE")
	assert(pilot.actor.position == Vector2(835, 697))
	assert(not pilot.actor.has_active_segment())
	pilot.set_debug_overlay(true)
	assert(pilot.overlay.visible and pilot.overlay.get_child_count() > 0)
	assert(pilot.request_waypoint("QA-HALL-SPAWN"))
	assert(pilot.actor.segment_destination() == "QA-ROUTE-001-STEP-001")
	assert(pilot.stop_movement())
	pilot.actor.advance(10.0)
	assert(pilot.session.current_anchor() == "QA-ROUTE-001-STEP-001")
	assert(not pilot.actor.has_active_segment(), "Stop must finish current leg but not begin a second")
	assert(pilot.session.pending_hotspot().is_empty())
	pilot.queue_free()
	await process_frame

	# Compile a one-way route with a physical intermediate corner.
	var only: Dictionary = doc.duplicate(true)
	only.routes = [only.routes[0]]
	only.routes[0].bidirectional = false
	var compiled := Routes.compile_qa_graph(only)
	assert(compiled.ok)
	assert(compiled.graph.route("QA-HALL-CENTRE", "QA-HALL-SPAWN").is_empty())
	assert(compiled.graph.active_edges()[0].routeId == "QA-ROUTE-001")
	assert(compiled.graph.active_edges()[0].provisional == false)
	var reversed = Source.new()
	_write_test_document(only)
	assert(reversed.load_source(Source.USER, TEMP))
	assert(reversed.graph.route("QA-HALL-CENTRE", "QA-HALL-SPAWN").is_empty())

	# After a reload the new file is read, never the previous graph or target.
	assert(Launch.stage(Source.USER, TEMP).ok)
	var fresh = _instantiate_pilot()
	await process_frame
	assert(fresh.ready_for_qa and fresh.qa.graph.active_edges().size() == 2)
	assert(fresh.session.current_anchor() == "QA-HALL-SPAWN")
	assert(fresh.session.pending_hotspot().is_empty() and not fresh.actor.has_active_segment())
	assert(fresh.actor.segment_destination().is_empty())
	fresh.queue_free()
	await process_frame

	# Project-exported fixture follows exactly the same contract.
	var project = Source.new()
	assert(project.load_source(Source.PROJECT), project.error_text)
	assert(project.source_path.begins_with(Routes.PROJECT_DRAFT_DIR))
	assert(Launch.stage(Source.PROJECT).ok)
	var exported = _instantiate_pilot()
	await process_frame
	assert(exported.ready_for_qa and exported.source_kind == Source.PROJECT)
	assert(exported.qa.graph.has_anchor("QA-HALL-SPAWN"))
	exported.queue_free()
	await process_frame

	# Explicitly invalid source cannot fall back to original Hall.
	var wrong: Dictionary = doc.duplicate(true)
	wrong.source.sha256 = "wrong-image"
	_write_test_document(wrong)
	assert(Launch.stage(Source.USER, TEMP).ok)
	var rejected = _instantiate_pilot()
	await process_frame
	assert(not rejected.ready_for_qa)
	assert(rejected.source_kind == Source.USER)
	assert(rejected.feedback.contains("rejected"))
	assert(rejected.qa.graph == null)
	rejected.queue_free()
	await process_frame

	# Incompatible blocked route must not be accepted as playable.
	var blocked: Dictionary = doc.duplicate(true)
	blocked.blockedCells.append("AA23")
	_write_test_document(blocked)
	var invalid = Source.new()
	assert(not invalid.load_source(Source.USER, TEMP))
	assert(invalid.error_text.contains("blocked") or invalid.error_text.contains("Route"))
	_write_test_document({"schemaVersion": 1, "kind": "wrong"})
	assert(not invalid.load_source(Source.USER, TEMP))
	assert(invalid.graph == null, "Rejected reload discards stale graph")

	# Missing/bad launch tickets fail closed; normal startup remains original.
	assert(Launch.stage(Source.BASELINE).ok)
	var ticket := Launch.consume()
	assert(ticket.ok and ticket.kind == Source.BASELINE)
	assert(Launch.consume().kind == Source.BASELINE)
	assert(FileAccess.get_file_as_string(Routes.HALL_SOURCE) == qa_source)
	assert(FileAccess.get_file_as_string(CANONICAL) == canonical)
	var real = Graph.new()
	real.rebuild({})
	assert(real.anchors().size() == 13)
	var runtime_source := FileAccess.get_file_as_string("res://scripts/raven/first_floor_hall_movement_pilot.gd")
	for forbidden in ["raven_campaign_store.gd", "raven_reducer.gd", "save_campaign(", "checkpoint_event(", "door_unlock"]:
		assert(not runtime_source.contains(forbidden), "Preview cannot mutate production: " + forbidden)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEMP))
	print("MAP-EDIT-02 saved/exported playable Onoe preview smoke passed (selection, turns, pause/stop, direction, reload, validation and no-save).")
	quit()
