# MAP-EDIT-02 — Play authored Route Editor geometry with Onoe

The Hall movement preview loads **three explicitly distinct sources**, each in approved Hall **source-image pixels** on the 1672×941 PNG. It is isolated QA: no production save, scene transitions, doorway unlock or authoritative map edits.

| Source | Disk path | Behavior |
|---|---|---|
| Original | `res://assets/raven/map/qa/first_floor_hall_pilot.v1.json` | Immutable seven-waypoint legacy regression |
| Saved user | `user://room_builder_routes/hall_routes_draft.v1.json` | Last explicit **Save user draft** in native Route Editor |
| Project export | `res://assets/raven/map/qa/drafts/hall_routes_draft.v1.json` | Last explicit **Export project draft**, version-controlled and shareable |

All three are **DRAFT_ONLY**. The editor's in-memory unsaved changes are NEVER used for movement. Malformed JSON, wrong image hashes, wrong schema/coordinate space, blocked or no-go crossings, illegal source selection or missing spawn are rejected and reported on-screen.

## How to use (Godot 4.7.2)

1. Go to **Project → Project Settings → Plugins**; enable **Room Builder · Navigation / Routes**. Open the **Navigation / Routes** tab.
2. Click **Import Hall QA** for a pristine draft or **Load user draft** / **Load project draft** to continue an existing document.
3. Choose a route. For example, **QA-ROUTE-001** (Hall spawn → centre): enter **AA24 → AA23 → AA22**, then click **Apply cells**. Grid W/H, origin, F3 overlay, no-go polygons and obstacle paint remain available in the editor. An edge with `provisional=true` is still a **provisional straight QA edge**; author cells to define precise turns.
4. Click **Save user draft** or **Export project draft** and verify the saved indicator. Then press the corresponding **Play saved user (Onoe)** or **Play project export (Onoe)**. To compare, click **Play original Hall**.
5. The Hall Pilot shows `SOURCE: original/user/project` on its top panel. Tap a waypoint circle to move Onoe along the compiled real route. Toggle F3 or **QA** to see exact intermediate anchor segments, no-go overlays and footpoint. **Space** pauses/resumes, **S** stops after the current authorized segment, and screen buttons provide the same actions. Drag to pan, wheel/+/− to zoom; touch taps and drags work as before.
6. To try a different source **in the running preview**, choose Original / Saved user / Project export on the top panel. This starts a **new, isolated Hall preview scene** instead of reinterpreting the moving actor's position in different geometry.
7. Stop the Godot custom game in the editor and return to the Navigation / Routes tab. Change routes and repeat; saving is always required for a new playable preview.

A file selection travels from the editor to the game via a temporary, one-use launch ticket under `user://room_builder_routes/`. It expires after five minutes and is removed as soon as the game reads it. Failure is visible; it never silently selects the original. Running the Hall Pilot without a ticket starts the original baseline. User drafts are local to the Godot project user data directory; exported QA drafts are shared with the project.

## Constraints and extension point

`route_preview_source.gd` validates the saved draft using the existing `route_document.gd` v1 compiler, which yields `ManorNavigationGraph` nodes and edges in image pixels. Intermediates are stable `QA-ROUTE-*-STEP-NNN` IDs for every non-endpoint cell, retaining turns. One-way routes work in one direction only. Each physical leg is issued by `ManorRouteSession.next_segment()` to the existing `OnoeSegmentMover`; completion confirms exact footpoint before progressing. No free tap-to-move and no `AStarGrid2D` replacement. Provisional edges remain marked and rendered in QA, never promoted as production-approved.

The source compiler is data-driven for **additional authored Hall waypoints/routes**: a compatible MAP-QA-05 file can replace the project export under the same filename without code changes. It must retain the approved source image identity and include `QA-HALL-SPAWN` with at least one reachable authored destination. True multi-room scenes and real Corridor door gates are intentionally owned by the separate map integration agent; this pilot emits only the legacy **virtual** portal diagnostic.

Automated check: `godot --headless --path . --script res://tests/raven/map_edit_02_playable_preview_smoke.gd --quit-after 180`, plus original MAP-EDIT-01/MAP-QA-03/MAP-QA-02/ManorGraph smoke and the full `scripts/check.sh`.
