extends Node2D
## MAP-PROD-01 standalone visual review; never the normal gameplay host.
const Geometry = preload("res://scripts/raven/map_prod_01_geometry.gd")
const Adapter = preload("res://scripts/raven/first_floor_integrated_draft_adapter.gd")
const Preview = preload("res://addons/room_builder_routes/route_preview_source.gd")
const HostScene = preload("res://scenes/raven/tests/first_floor_multi_room_host.tscn")
const EvelynScene = preload("res://scenes/raven/actors/evelyn_walker.tscn")
const DoorArt = preload("res://scripts/raven/map_prod_01_hc_cb_art.gd")
const HALL := "RM-ROOM-HALL"
const HC := "RM-DOOR-HALL-CORRIDOR"
const CB := "RM-DOOR-CORRIDOR-BEDROOM"

var host: Variant = null
var source: Dictionary = {}
var _status: Label

func _ready() -> void:
	_make_ui()
	load_room(HALL)

func load_room(room_id: String = HALL) -> bool:
	var checked: Dictionary = Geometry.verify()
	if not checked.get("ok", false):
		_message("INVALID: " + str(checked.get("error", "geometry")))
		return false
	var loaded: Dictionary = Adapter.load_source(Preview.PROJECT, Geometry.ROUTES_PATH)
	if not loaded.get("ok", false):
		_message("INVALID: " + str(loaded.get("error", "authored routes")))
		return false
	var allowed: Array = ["RM-ROOM-HALL", "RM-ROOM-CORRIDOR", "RM-ROOM-BEDROOM"]
	if not allowed.has(room_id):
		return false
	var contract: Dictionary = loaded["contract"].duplicate(true)
	var rooms: Array = []
	for entry in contract["rooms"]:
		if allowed.has(str(entry["id"])):
			rooms.append(entry)
	contract["rooms"] = rooms
	var doors: Array = []
	for entry in contract["doors"]:
		if [HC, CB].has(str(entry["id"])):
			doors.append(entry)
	contract["doors"] = doors
	var transitions: Array = []
	for entry in contract["transitions"]:
		if [HC, CB].has(str(entry.get("doorId", ""))):
			transitions.append(entry)
	contract["transitions"] = transitions
	if rooms.size() != 3 or doors.size() != 2 or transitions.size() != 4:
		_message("INVALID: need exactly HC/CB and three rooms")
		return false
	var next_host: Variant = HostScene.instantiate()
	var old_actor: Node = next_host.get_node("Onoe")
	next_host.remove_child(old_actor)
	old_actor.free()
	var evelyn: Node2D = EvelynScene.instantiate()
	evelyn.name = "Onoe" # preserve existing host child path; actual actor is Evelyn
	evelyn.z_index = 8
	next_host.add_child(evelyn)
	add_child(next_host)
	if not next_host.configure_host(contract, loaded["visuals"], room_id, str(loaded["starts"][room_id])):
		var reason: String = str(next_host.last_error)
		next_host.queue_free()
		_message("INVALID: " + reason)
		return false
	var background = DoorArt.new()
	background.name = "HC_CB_FloorAndDoorArt"
	background.z_index = 2
	next_host.add_child(background)
	var foreground = DoorArt.new()
	foreground.name = "HC_CB_TrueForeground"
	foreground.foreground = true
	foreground.z_index = 12
	next_host.add_child(foreground)
	if host != null and is_instance_valid(host):
		host.queue_free()
	host = next_host
	source = loaded
	source["contract"] = contract
	host.room_changed.connect(_on_room_changed)
	_message("HC/CB render candidate; Evelyn walker; TEST_ONLY. Production OFF.")
	return true

func request_transition(transition_id: String) -> Dictionary:
	if host == null or not is_instance_valid(host):
		return {"ok":false,"error":"no-host"}
	if not ["QA-09B-HC-AB","QA-09B-HC-BA","QA-09B-CB-AB","QA-09B-CB-BA"].has(transition_id):
		return {"ok":false,"error":"unapproved-transition"}
	var result: Dictionary = host.request_transition(transition_id)
	_message(transition_id + ": " + ("walking" if result.get("ok", false) else str(result.get("error", "rejected"))))
	return result

func set_gate(door_id: String, status: String) -> bool:
	if host == null or not is_instance_valid(host) or not [HC, CB].has(door_id) or status not in ["open","gated"]:
		return false
	var ok: bool = host.test_gate(door_id, status)
	_message(door_id + " " + status + (" OK" if ok else " REJECTED"))
	return ok

func walk_to_waypoint(id: String) -> Dictionary:
	if host == null or not is_instance_valid(host):
		return {"ok":false,"error":"no-host"}
	var graph = host.current_graph()
	var entry: Dictionary = graph.anchor(id)
	if entry.is_empty():
		return {"ok":false,"error":"missing-waypoint"}
	return host.request_hotspot(str(entry.get("hotspotId", "")))

func _on_room_changed(_details: Dictionary) -> void:
	_message("Room: " + str(host.active_room_id) + "  feet: " + str(host.actor.position))

func _message(value: String) -> void:
	if is_instance_valid(_status):
		_status.text = value

func _button(parent: Control, caption: String, action: Callable) -> void:
	var b := Button.new()
	b.text = caption
	b.custom_minimum_size = Vector2(132, 44)
	parent.add_child(b)
	b.pressed.connect(action)

func _make_ui() -> void:
	var ui := CanvasLayer.new()
	add_child(ui)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	ui.add_child(panel)
	var layout := VBoxContainer.new()
	panel.add_child(layout)
	var title := Label.new()
	title.text = "MAP-PROD-01  |  Painted 65° first-floor  |  REVIEW CANDIDATE, PRODUCTION OFF"
	layout.add_child(title)
	var controls := HFlowContainer.new()
	layout.add_child(controls)
	_button(controls, "Unlock HC", func(): set_gate(HC, "open"))
	_button(controls, "Lock HC", func(): set_gate(HC, "gated"))
	_button(controls, "Hall → Corridor", func(): request_transition("QA-09B-HC-AB"))
	_button(controls, "Corridor → Hall", func(): request_transition("QA-09B-HC-BA"))
	_button(controls, "Unlock CB", func(): set_gate(CB, "open"))
	_button(controls, "Lock CB", func(): set_gate(CB, "gated"))
	_button(controls, "Corridor → Bedroom", func(): request_transition("QA-09B-CB-AB"))
	_button(controls, "Bedroom → Corridor", func(): request_transition("QA-09B-CB-BA"))
	_button(controls, "Restart Hall", func(): load_room(HALL))
	_button(controls, "Show routes", func(): _toggle_debug())
	_status = Label.new()
	layout.add_child(_status)

func _toggle_debug() -> void:
	if host != null and is_instance_valid(host):
		host.toggle_routes()
