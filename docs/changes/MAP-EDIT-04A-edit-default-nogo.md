# MAP-EDIT-04A — Editable default navigation constraints (Room Builder)

Task IDs: MAP-EDIT-04A (owner follow-up), CODE-05-01 (P0 parent)
Changes: Native Godot tool 8 now edits ALL imported/default and user-added DRAFT_ONLY NO-GO/WALKABLE polygons; on-canvas hit selection, vertex/body drag, insert/remove corner, preview, Apply/Discard, Undo/Redo, v1 draft persistence.
Verification: `tests/raven/map_edit_04a_default_nogo_polygons_smoke.gd` registered exactly once in `scripts/check.sh`; tests source 10+5 polygon editing, invalid rejection, native mouse/selection, inserted/removed corners, former NO-GO waypoint placement after room-owned walkable expansion, save/reload and MAP-QA-07B adapter. Exact PR-head GitHub Actions to be verified; manual Godot/physical clearance still pending.
Owner QA: Owner confirmed MAP-EDIT-04 freehand works but reported inability to correct the original 10 red NO-GO barriers. Manual follow-up needed to assess default polygons/dragging at real editor size, waypoint placement and Onoe routing.
Status impact: Room Builder `CODE-05-01` remains P0 partial / PR_review; no owner acceptance, production map or canonical navigation promotion. Only own domain progress shard changed.

## Initial audit (2026-11-09)
- Main `0ae9ac103032301cf3614170e489a2473b510d7c`; #253 previously merged; no overlapping PR.
- The first-floor QA draft contains exactly **10 default red noGoPolygons** and **5 default green walkablePolygons**, with IDs already present in the inspector. Tool 8 previously supported rectangle creation and whole-zone deletion only, without on-canvas pick or vertex editing.
- Imported polygons remain ordinary v1 draft objects with stable `id`, `roomId` (when present) and provenance. Editing now changes only `pointsPx` inside an isolated saved draft, preserving existing IDs, metadata and semantic labels.
- `RouteDocument.set_zone_polygon` is the sole edit/validation boundary; it rejects out-of-art, self-crossing or degenerate polygons and revalidates all existing waypoints/routes through `_finish_edit`. No auto-rerouting, no automatic changes to walkable/no-go authority.
- Tool 8 exposes select original zone by map/ID, drag body/corners, insert/remove corner, explicit Apply/Discard, history and persistence. Handles are shown over the original approved PNG; other tools including tool 9 remain intact.

## Scope and rollback
- Godot 4.7.2 native editor, existing document schemaVersion=1 and integrated MAP-QA-07B runtime adapter only.
- Do not modify the approved PNG, original Hall source JSON, canonical first-floor manifest, project baseline draft, campaign saves, runtime movement/controller, other game UI/Match3/VN or generated dashboard.
- Rollback by reverting this PR. Owner must physically approve room walkability and restrictions before any production use. No auto-merge.
