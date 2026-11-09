extends RefCounted
## MAP-QA-07A Stage A fixture assembler. Hall anchors come from the existing
## DRAFT_ONLY Hall QA adapter; Corridor/Bedroom are synthetic TEST_ONLY rectangles.
## In particular, Hall's virtual portal is *mocked* here for integration QA;
## this fixture proves no physical Hall/Corridor connection in production.
const HallQaGraph = preload("res://scripts/raven/first_floor_hall_qa_graph.gd")
const HALL_ART := "res://a_detailed_top_down_isometric_game_map_illustratio.png"


static func build() -> Dictionary:
	var qa = HallQaGraph.new()
	if not qa.load_pilot():
		push_error("MAP-QA-07A refused stale Hall draft: " + qa.error_text)
		return {}
	var hall_anchors: Array = []
	for id in qa.waypoint_ids():
		hall_anchors.append(qa.graph.anchor(str(id)).duplicate(true))
	var hall_edges: Array = qa.graph.active_edges()
	var corridor := {
		"provenance": {"productionReady": false, "geometryStatus": "synthetic-test-only"},
		"anchors": [
			{"id":"QA-F7-C-ENTRY-H", "roomId":"QA-F7-CORRIDOR", "kind":"safe", "position":[135,280]},
			{"id":"QA-F7-C-TO-H", "roomId":"QA-F7-CORRIDOR", "kind":"transition", "hotspotId":"QA-HS-F7-C-TO-H", "position":[65,280]},
			{"id":"QA-F7-C-MID", "roomId":"QA-F7-CORRIDOR", "kind":"safe", "position":[405,280]},
			{"id":"QA-F7-C-ENTRY-B", "roomId":"QA-F7-CORRIDOR", "kind":"safe", "position":[685,280]},
			{"id":"QA-F7-C-TO-B", "roomId":"QA-F7-CORRIDOR", "kind":"transition", "hotspotId":"QA-HS-F7-C-TO-B", "position":[765,280]},
			{"id":"QA-F7-C-SIDE", "roomId":"QA-F7-CORRIDOR", "kind":"interaction", "hotspotId":"QA-HS-F7-C-SIDE", "position":[405,145]}
		],
		"edges": [
			{"from":"QA-F7-C-TO-H", "to":"QA-F7-C-ENTRY-H"},
			{"from":"QA-F7-C-ENTRY-H", "to":"QA-F7-C-MID"},
			{"from":"QA-F7-C-MID", "to":"QA-F7-C-ENTRY-B"},
			{"from":"QA-F7-C-ENTRY-B", "to":"QA-F7-C-TO-B"},
			{"from":"QA-F7-C-MID", "to":"QA-F7-C-SIDE"}
		]
	}
	var bedroom := {
		"provenance": {"productionReady": false, "geometryStatus": "synthetic-test-only"},
		"anchors": [
			{"id":"QA-F7-B-ENTRY", "roomId":"QA-F7-BEDROOM", "kind":"safe", "position":[135,280]},
			{"id":"QA-F7-B-TO-C", "roomId":"QA-F7-BEDROOM", "kind":"transition", "hotspotId":"QA-HS-F7-B-TO-C", "position":[65,280]},
			{"id":"QA-F7-B-MID", "roomId":"QA-F7-BEDROOM", "kind":"safe", "position":[335,280]},
			{"id":"QA-F7-B-SIDE", "roomId":"QA-F7-BEDROOM", "kind":"interaction", "hotspotId":"QA-HS-F7-B-SIDE", "position":[550,185]}
		],
		"edges": [
			{"from":"QA-F7-B-TO-C", "to":"QA-F7-B-ENTRY"},
			{"from":"QA-F7-B-ENTRY", "to":"QA-F7-B-MID"},
			{"from":"QA-F7-B-MID", "to":"QA-F7-B-SIDE"}
		]
	}
	var contract := {
		"schemaVersion": 1,
		"kind": "raven-authored-room-transitions",
		"approval": "TEST_ONLY",
		"doors": [
			{"id":"QA-F7-DOOR-HC", "status":"open"},
			{"id":"QA-F7-DOOR-CB", "status":"open"},
			{"id":"QA-F7-DOOR-LOCKED", "status":"gated"}
		],
		"rooms": [
			{"id":"RM-ROOM-HALL", "label":"HALL QA DRAFT", "graph":{
				"provenance":{"productionReady":false, "geometryStatus":"hall-qa-draft-image-pixel"},
				"anchors":hall_anchors, "edges":hall_edges}},
			{"id":"QA-F7-CORRIDOR", "label":"SYNTHETIC CORRIDOR", "graph":corridor},
			{"id":"QA-F7-BEDROOM", "label":"SYNTHETIC BEDROOM", "graph":bedroom}
		],
		"transitions": [
			{"id":"QA-F7-TR-HC", "sourceRoomId":"RM-ROOM-HALL", "destinationRoomId":"QA-F7-CORRIDOR", "approachAnchorId":"QA-HALL-PORTAL-APPROACH", "destinationEntryAnchorId":"QA-F7-C-ENTRY-H", "reverseTransitionId":"QA-F7-TR-CH", "doorId":"QA-F7-DOOR-HC", "authority":"TEST_ONLY"},
			{"id":"QA-F7-TR-CH", "sourceRoomId":"QA-F7-CORRIDOR", "destinationRoomId":"RM-ROOM-HALL", "approachAnchorId":"QA-F7-C-TO-H", "destinationEntryAnchorId":"QA-HALL-RETURN-SAFE", "reverseTransitionId":"QA-F7-TR-HC", "doorId":"QA-F7-DOOR-HC", "authority":"TEST_ONLY"},
			{"id":"QA-F7-TR-CB", "sourceRoomId":"QA-F7-CORRIDOR", "destinationRoomId":"QA-F7-BEDROOM", "approachAnchorId":"QA-F7-C-TO-B", "destinationEntryAnchorId":"QA-F7-B-ENTRY", "reverseTransitionId":"QA-F7-TR-BC", "doorId":"QA-F7-DOOR-CB", "authority":"TEST_ONLY"},
			{"id":"QA-F7-TR-BC", "sourceRoomId":"QA-F7-BEDROOM", "destinationRoomId":"QA-F7-CORRIDOR", "approachAnchorId":"QA-F7-B-TO-C", "destinationEntryAnchorId":"QA-F7-C-ENTRY-B", "reverseTransitionId":"QA-F7-TR-CB", "doorId":"QA-F7-DOOR-CB", "authority":"TEST_ONLY"},
			{"id":"QA-F7-TR-LOCKED", "sourceRoomId":"RM-ROOM-HALL", "destinationRoomId":"QA-F7-CORRIDOR", "approachAnchorId":"QA-HALL-WEST", "destinationEntryAnchorId":"QA-F7-C-ENTRY-H", "reverseTransitionId":"", "doorId":"QA-F7-DOOR-LOCKED", "authority":"TEST_ONLY"}
		]
	}
	var visuals := {
		"RM-ROOM-HALL":{"source":"hall-qa", "texturePath":HALL_ART, "bounds":[0,0,1672,941], "cameraZoom":0.9, "actorHeight":62},
		"QA-F7-CORRIDOR":{"source":"synthetic", "bounds":[0,0,900,550], "cameraZoom":0.8, "actorHeight":70},
		"QA-F7-BEDROOM":{"source":"synthetic", "bounds":[0,0,780,520], "cameraZoom":0.8, "actorHeight":70}
	}
	return {"contract":contract, "visuals":visuals, "initialRoomId":"RM-ROOM-HALL",
		"initialAnchorId":"QA-HALL-SPAWN"}
