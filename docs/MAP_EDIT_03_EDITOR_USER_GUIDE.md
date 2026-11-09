# MAP-EDIT-03 — How to edit first-floor routes (Godot 4.7.2)

**This editor changes only a DRAFT_ONLY QA navigation draft, not a production map or a saved game.** The five editable room IDs are Hall, Corridor, Bedroom, Library/Archive and Kitchen. Hall, Corridor and Bedroom QA transitions remain **TEST_ONLY**; Library and Kitchen remain independent route islands.

## Open the editor

1. In Godot choose **Project → Project Settings → Plugins**, enable **Room Builder · Navigation / Routes**, then open the **Navigation / Routes** top tab.
2. Click **Load project draft** to see the full 22-point / 19-route MAP-QA-05 starting proposal. **Import original Hall** intentionally resets the editor to the older seven-point test baseline, so use Load project draft for editing the complete map.
3. Choose the **Editing room** at the top. It filters selectable points and routes to one room; all other points remain faint reference markers. Unassigned legacy points appear in the list for recovery.
4. The **Active tool** label tells you what the mouse will do. The right panel displays **ROOM**, **WAYPOINT** and **ROUTE** selections. Mouse wheel zooms; right/middle drag pans in every tool; **Fit artwork** restores framing.

## Common operations

| Goal | Tool / action | Result |
| --- | --- | --- |
| Select a waypoint | **1 Select / drag** → click its dot or the waypoint list | Highlights the selected point and shows exact pixel/cell position |
| Move a waypoint | **1 Select / drag** → hold left button on dot and drag | Validates position and route clearance before committing; invalid moves leave the draft unchanged |
| Add a waypoint | Choose **Editing room** → **2 Add waypoint** → click empty walkable art | New stable `QA-USER-*` point carries explicit `roomId` (never defaults to Hall); check snap-to-grid |
| Change a waypoint's room | Select point → choose **Waypoint room** in inspector → **Apply label/type/room** | Updates ownership and preserves ID if valid; if connected to a route in the old room, remove that route first |
| Delete a waypoint | Select point → **Delete waypoint** | Connected points require deleting dependent routes first |
| Connect points | **3 Connect points** → click FROM dot → click TO dot | Creates an explicit, provisional edge **only within the same room**; selecting points in different rooms explains the error |
| Select a route | **4 Select route** → click its colored line or select from route list | Selected path becomes thick yellow with outlined start (green) and end (orange) |
| Redraw a route | Select it → **5 Draw route cells** → **Start cell path at FROM** → click orthogonally adjacent cells ending at TO → **Apply cells** | Preserves the exact text cell editor and the deterministic per-cell Godot movement path |
| Delete a route | Select route → **Delete route** | Removes edge and allows its endpoint room to change later |
| Undo or redo | **Undo** / **Redo** in toolbar | Reverses/replays committed document edits; selection/dragging alone is not a history step |

**Cell path example:** `AB11 → AC11 → AD11 → AD12`. Each successive cell must share a side (no diagonals or skipped cells), and the first and last must contain the route's FROM and TO waypoint respectively. **Apply cells** is the commit: until then the editor is only previewing the proposed route, not silently changing the document. Provisional imported straight edges remain marked provisional until an authored sequence validates.

For a future freehand pen tool, route hit-testing lives in `RouteCanvas.pick_route()`; saved geometry still goes through `RouteDocument.set_route_cells()`. Freehand drawing is **not** implemented in MAP-EDIT-03.

## Save and actually walk the change

1. Click **Save user draft** to write `user://room_builder_routes/hall_routes_draft.v1.json`, or **Export project draft** to write `res://assets/raven/map/qa/drafts/hall_routes_draft.v1.json`.
2. Click **Play integrated first floor**. Unsaved changes are refused. The MAP-QA-07B scene opens; choose **Saved user** or **Project draft** **inside that QA scene** to match what you saved. The editor does not inject in-memory, unsaved geometry into a running player.
3. Select the same room's authored waypoint and walk Onoe. Inspect **F3** overlay for the exact changed route cells. Use TEST_ONLY transitions Hall → Corridor → Bedroom when appropriate. For Archive/Kitchen use **Restart island (QA)**; this is not a real doorway.
4. Return to **Navigation / Routes** to iterate. Your user draft is isolated; exporting the project draft modifies only the versioned QA candidate. **Play original Hall** is an independent regression baseline.

## Error handling and limits

- An unowned newly authored point is never silently assigned to Hall. If an old user draft contains an unassigned point, select it from the waypoint list and apply a valid room.
- Routes spanning two different room IDs cannot be created. Physical door approaches are not inferred from screen geometry; unresolved portal approvals remain in MAP-QA-05.
- Moving a point can fail because the new position is outside the approved PNG bounds, walkable candidate or intersects no-go/blocked geometry or an existing route. The status line explains the rejection.
- Changing a point's room while it is referenced by routes is refused when it would create mismatched endpoints.
- The editor maintains JSON schemaVersion **1** and `DRAFT_ONLY`; the original source PNG, immutable original Hall QA dataset and canonical 13 production anchors are untouched.
- The integrated QA launcher always boots the existing integrated scene with its own explicit source selector. It does not automatically select the last-saved source or promise device/geometry acceptance.

## Automated checks

The new `map_edit_03_usability_smoke.gd` checks creation/editing/invalid ownership, same-room and cross-room routes, ordered grid cells, save/load, MAP-QA-07B bridge with an extra point and edge, native UI tool state, selection, undo/redo, and unchanged source/canonical files. It runs exactly once via `scripts/check.sh`, alongside MAP-EDIT-01/02 and MAP-QA-05/07B.

For manual acceptance on Windows/macOS/Linux, inspect plugin layout in the Godot editor at different window sizes and confirm clicking the drawn route line reliably selects it. A green headless CI does not certify visual usability.
