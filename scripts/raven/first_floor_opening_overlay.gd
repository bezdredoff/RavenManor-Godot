extends Node2D
## Code-native greybox floor/backfill blueprint; not generated art or collision.
const Routes = preload("res://addons/room_builder_routes/route_document.gd")
var document: Dictionary = {}


func _draw() -> void:
	if document.is_empty():
		return
	var font := ThemeDB.fallback_font
	for zone in document.get("walkablePolygons", []):
		if zone.get("role") != "PROPOSED_FLOOR_PATCH":
			continue
		var points := Routes._polygon_points(zone)
		draw_colored_polygon(points, Color("#345e70"))
		for i in points.size():
			draw_line(points[i], points[(i+1)%points.size()], Color("#7fe5ff"), 1.0)
	var lookup := Routes._waypoint_lookup(document)
	for contact in document.get("sharedDoorContacts", []):
		var point := Routes._vector(lookup[contact.waypointIds[0]].pointPx)
		var normal := Routes._vector(contact.normalPx)
		var tangent := Vector2(-normal.y, normal.x)
		var radius := float(contact.openingWidthPx) * 0.5
		for sign_value in [-1.0, 1.0]:
			var post: Vector2 = point + tangent * radius * float(sign_value)
			draw_line(post-normal*8, post+normal*8, Color("#ffd17b"), 5.0)
		draw_circle(point, 3.0, Color("#ffd17b"))
		draw_string(font, point+Vector2(8,-10), str(contact.id).trim_prefix("QA-09B-")+" PROPOSED", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#ffd17b"))
	for proposal in document.get("architectureProposals", []):
		var points := PackedVector2Array()
		for raw in proposal.pointsPx:
			points.append(Routes._vector(raw))
		for i in range(1, points.size()):
			draw_dashed_line(points[i-1], points[i], Color("#e4a4ff"), 2.0, 8.0)
		if not points.is_empty():
			draw_string(font, points[-1]+Vector2(8,-8), "CONCEPT ONLY / NO ROUTE", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#e4a4ff"))
