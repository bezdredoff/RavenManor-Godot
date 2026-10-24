extends SceneTree

const Snapshot = preload("res://scripts/raven/raven_snapshot.gd")
const Reducer = preload("res://scripts/raven/raven_reducer.gd")
const Graph = preload("res://scripts/raven/manor_navigation_graph.gd")
const Store = preload("res://scripts/raven/raven_campaign_store.gd")
const MemoryStorage = preload("res://tests/support/memory_storage.gd")


func _initialize() -> void:
	var graph_data: Dictionary = load("res://data/raven/manor_greybox_graph.json").data
	assert(graph_data.provenance.geometryStatus == "greybox")
	assert(graph_data.provenance.productionReady == false, "Greybox anchors must not be presented as production-ready before room-art calibration")
	assert(Graph.production_geometry_is_valid(graph_data))
	var false_claim := graph_data.duplicate(true); false_claim.provenance = graph_data.provenance.duplicate(true); false_claim.provenance.productionReady = true
	assert(not Graph.production_geometry_is_valid(false_claim), "Production-ready geometry requires approved room-art calibration metadata")
	var state := Snapshot.fresh()
	var graph := Graph.new()
	graph.rebuild(state)
	assert(graph.interaction_anchor("RM-HS-001") == "RM-NAV-HS-001")
	assert(graph.interaction_anchor("RM-HS-004") == "RM-NAV-HS-004")
	assert(graph.route("RM-NAV-HALL-SPAWN", "RM-NAV-HS-003") == [
		"RM-NAV-HALL-SPAWN", "RM-NAV-HALL-CORRIDOR-NEAR", "RM-NAV-HALL-CORRIDOR-FAR",
		"RM-NAV-CORRIDOR-CENTER", "RM-NAV-HS-003"
	])
	assert(graph.route("RM-NAV-HALL-SPAWN", "RM-NAV-HS-002").is_empty())
	assert(graph.route("missing", "RM-NAV-HS-001").is_empty())

	var unlock := Reducer.apply(state, {
		"eventId": "nav-test-unlock",
		"type": "door_unlock",
		"doorId": "RM-DOOR-CORRIDOR-BEDROOM",
	})
	assert(unlock.ok)
	state = unlock.state
	graph.rebuild(state)
	var route := graph.route("RM-NAV-HALL-SPAWN", "RM-NAV-HS-002")
	assert(route == [
		"RM-NAV-HALL-SPAWN", "RM-NAV-HALL-CORRIDOR-NEAR", "RM-NAV-HALL-CORRIDOR-FAR",
		"RM-NAV-CORRIDOR-CENTER", "RM-NAV-HS-005", "RM-NAV-BEDROOM-NEAR",
		"RM-NAV-BEDROOM-FAR", "RM-NAV-BEDROOM-CENTER", "RM-NAV-HS-002"
	])
	assert(graph.route("RM-NAV-HALL-SPAWN", "RM-NAV-HS-002") == route, "Route selection must be deterministic")
	assert(graph.route_positions("RM-NAV-BEDROOM-FAR", "RM-NAV-HALL-SPAWN").size() == 7)
	var adapter := MemoryStorage.new()
	assert(Store.new(adapter).save_campaign(state))
	var reloaded := Store.new(adapter).load_campaign()
	var reloaded_graph := Graph.new(); reloaded_graph.rebuild(reloaded)
	assert(not reloaded_graph.route("RM-NAV-HALL-SPAWN", "RM-NAV-HS-002").is_empty(), "Unlocked doorway must survive reload")
	print("Raven Manor authored navigation graph smoke passed (locked, unlocked and deterministic routes).")
	quit()
