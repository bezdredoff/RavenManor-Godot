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
| Freehand route | **9 Draw route (freehand)** → drag → inspect → **Apply route** | Converts a continuous mouse line into validated orthogonal cells; explicit commit only |
| Undo or redo | **Undo** / **Redo** in toolbar | Reverses/replays committed document edits; selection/dragging alone is not a history step |

**Cell path example:** `AB11 → AC11 → AD11 → AD12`. Each successive cell must share a side (no diagonals or skipped cells), and the first and last must contain the route's FROM and TO waypoint respectively. **Apply cells** is the commit: until then the editor is only previewing the proposed route, not silently changing the document. Provisional imported straight edges remain marked provisional until an authored sequence validates.

## MAP-EDIT-04 — draw a whole route with the mouse (tool 9)

**No cell coordinates are required.** This workflow edits the same DRAFT_ONLY v1 document as the older grid tools.

1. Click **Load project draft**, select Hall/Corridor/Bedroom/Library/Kitchen from the compact **Room** selector, and confirm green WALKABLE / red NO-GO / dark outside-walkable overlays are visible.
2. For an existing path, click it using **4 Select route** or choose it in the route list, then choose **9 Draw route (freehand)** or **Redraw selected**. The route's endpoints, ID and one-way/bidirectional flag are preserved.
3. For a new path, choose **9 Draw route (freehand)**, click **New (FROM / TO)**, and select two same-room waypoints in the existing FROM / TO pickers. You do **not** have to connect them manually first.
4. Hold **left mouse** near the FROM dot, paint along the actual walkable corridor on the approved image and release near the TO dot. Blue is the original mouse stroke; thick lime is the proposed orthogonal grid path. A red marker/segment identifies a rejected location. Use **Simplify px** (0–48, default 4) to reduce pointer noise, but preserve visible turns.
5. Review the status/diagnostic message. If valid, click **Apply route**. Release does **not** save anything, and **Discard** or **Escape** abandons only the preview. Invalid or room-crossing strokes cannot be applied. If the stroke touches furniture/NO-GO/blocked/outside green region, redraw in freehand or explicitly correct the draft zones in tool 8; this tool will **not** silently move walls, enlarge zones or choose a different corridor.
6. **Undo / Redo** revert the single applied document edit. The editor then says **UNSAVED changes**. Click **Save user draft**, followed by **Play integrated first floor**, and choose **Saved user** inside the QA scene. In F3 view, inspect the same route cells and walk Onoe between the two endpoints. For a shareable QA candidate choose **Export project draft** and **Project draft** in the scene instead.

**Room ownership:** freehand steps must remain inside walkable polygons explicitly tagged with the selected room. Newly added WALKABLE rectangles inherit the selected room in the native editor. Older unowned draft rectangles must be redrawn from the appropriate room before freehand will use them; a green polygon for another room is not permission to cross the doorway. This is an authoring-safety check, **not** an approved collision/production geometry boundary.

**Troubleshooting:** A missing green floor is different from an orange blocked cell and a red NO-GO polygon. Examine the error location, select tool 8 to edit a provisional green/red zone or tool 6 for a blocker, and retry. A loop/backtrack is refused rather than silently simplified into a shortcut. The freehand row appears only for tool 9 and leaves the main toolbar compact. Existing tools 1–8, exact cell text, baseline Hall test and save/reload continue to work.

**QA caveat:** headless smoke validates conversion/UI/document-save and the MAP-QA-07B adapter; the owner still must visually verify at the actual Godot editor window size, physical Onoe travel and clearance before declaring the geometry accepted. No campaign or canonical changes are made.

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

## MAP-EDIT-03A — Correcting the map restrictions and toolbar layout

The top **Tool** / **Room** selectors are now in one compact line; they no longer use paragraph labels inside an auto-wrapping flow layout. The grid settings and **Apply grid settings** button have moved near the **top** of the scrolling inspector, directly below Quick Start. If the Godot Output/Debugger dock is open, scroll the right inspector independently; collapsing the bottom Output dock gives the map more height.

### What is actually blocking a click?

The initial project draft contains **5 WALKABLE polygons**, **10 NO-GO polygons** and **0 blockedCells**. Walkable polygons are limited QA proposals, **not** all visually clear floor on the approved PNG. Unlike the old editor, the canvas now explains all restrictions without requiring you to guess:

| Map overlay | Meaning | How to edit the DRAFT_ONLY geometry |
| --- | --- | --- |
| **Green outlines** | Explicit walkable polygons; only places inside the union can receive authored waypoint feet | **+ WALKABLE rectangle**, click two opposite corners; Undo if wrong |
| **Darkened grid cells** | Grid-centre diagnostic preview outside *all* walkable polygons (not inherently walls) | Expand WALKABLE via a new rectangle; keep only plausible floor, then test movement |
| **Red fill/outline** | NO-GO polygons (staircases, tables, furniture; names in the list) | Select zone in list, click **Remove selected draft zone…**, confirm; redraw NO-GO if needed |
| **Orange cells** | Individually blocked cells (initially none) | **6 Block cells** toggles each; **Unblock selected cell** removes the block |

**Important:** These layers are not interchangeable. Removing a blocked cell never overrides a red polygon or a missing green walkable area. All polygon boundaries use **image pixels**, not Room Builder world coordinates. The dark cell overlay samples grid centres for readability; the exact polygon boundaries are the green/red outlines and the validator remains pixel accurate.

### How to expand a walkable room safely

1. **Load project draft** and select the relevant Room at the top. Make sure **Show walkable / no-go / excluded** is checked in the right inspector.
2. Click **+ WALKABLE rectangle**. Tool 8 (**Edit zones**) is selected. Click the first and opposite corners around a plausible piece of floor on the approved image. This adds a new separately named `QA-EDIT-WALK-*` polygon to the draft. The old five polygons and the approved source image remain untouched.
3. Click the previously forbidden location to inspect its reason. Use **2 Add waypoint** to place your new point after its precise pixel/room validation passes.
4. If a red obstacle overlaps your intended route, select its explicit ID from the polygon list; remove it with confirmation and, when appropriate, draw a smaller **+ NO-GO rectangle** that covers the furniture without blocking the floor. Use **Undo/Redo** as needed.
5. **Save user draft**, then **Play integrated first floor** and choose the saved user source inside MAP-QA-07B. Inspect the route overlay/F3. The editor accepts only a draft that still validates **all** its waypoints and routes; it never automatically approves a real door or campaign collision.

Use **Cancel zone drawing** to stop after the first corner. Removing a polygon that would strand an existing waypoint/route is rejected, with a specific reason. Old imported polygons can be removed **from a saved draft only**; the original QA source/canonical geometry never changes. Rectangle authoring with delete-and-redraw is provided here; freeform vertex editing and automatic room collision extraction remain future work.

### Avoiding repeated warnings

Expected invalid clicks now produce feedback in the editor's status line and **constraint explanation** field instead of spamming the Godot Output dock. A rejected edit does not change the document or the Undo history.

## Automated checks

The new `map_edit_03_usability_smoke.gd` checks creation/editing/invalid ownership, same-room and cross-room routes, ordered grid cells, save/load, MAP-QA-07B bridge with an extra point and edge, native UI tool state, selection, undo/redo, and unchanged source/canonical files. It runs exactly once via `scripts/check.sh`, alongside MAP-EDIT-01/02 and MAP-QA-05/07B.

For manual acceptance on Windows/macOS/Linux, inspect plugin layout in the Godot editor at different window sizes and confirm clicking the drawn route line reliably selects it. A green headless CI does not certify visual usability.
