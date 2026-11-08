# Navigation / Routes — native Room Builder module (MAP-EDIT-01)

This is a **Godot 4.7.2 EditorPlugin**, intentionally distinct from the existing browser `tools/room-builder/` PWA. The PWA edits flat rooms/world-plan `firstFloorDraft` v2 and cannot host native Godot UI. This plugin shares approved-image identity and non-production draft boundaries, but introduces a separate **image-pixel grid-route draft** schema v1. No change to Room Builder PWA or its v1/v2 data.

In Godot: **Project → Project Settings → Plugins → enable “Room Builder · Navigation / Routes”**. Then select the **Navigation / Routes** editor tab. The plugin is opt-in: `project.godot` and existing VN Studio plugin registration remain untouched.

See [full workflow and tests](../../docs/MAP_EDIT_01_NAVIGATION_ROUTES_EDITOR.md).

Files:
- `route_document.gd`: pure validated import/edit/serialization and deterministic QA graph compilation.
- `route_canvas.gd`: native image-pixel canvas, uniform pan/zoom and diagnostic overlays.
- `route_editor_view.gd`: grid/waypoint/route/obstacle tools, undo/redo, draft persistence, route preview.
- `assets/raven/map/qa/drafts/hall_routes_draft.v1.json`: first import of the original Hall QA geometry, preserving seven original stable IDs and seven **provisional** edges.

**MAP-EDIT-02 playable QA preview:** the Hall movement scene now supports explicit **Original**, **Saved user** and **Project export** choices. The editor supplies separate **Play** buttons; unsaved changes are refused, not injected. A saved/exported DRAFT_ONLY route graph is compiled in-memory and followed by the existing `ManorRouteSession` and Onoe segment mover. See [MAP-EDIT-02 manual guide](../../docs/MAP_EDIT_02_PLAYABLE_PREVIEW.md). Original Hall remains the regression baseline. No promotion to production.
