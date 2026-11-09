# MAP-EDIT-03A — Owner feedback: compact native editor layout and editable walkable/no-go QA zones

Task IDs: MAP-EDIT-03A (scoped owner-defect follow-up), CODE-05-01 (parent P0 partial)

Changes:
- Fix one-line native toolbar, scroll access to GRID/Apply controls, high-contrast polygons and outside-walkable diagnostics, reversible DRAFT_ONLY polygon editing.

Verification:
- Headless Godot MAP-EDIT-03A plus existing MAP-EDIT-01/02/03, MAP-QA-05/07B, CI all six blocking jobs on exact PR head; initial failures actively investigated, no pass claim yet.

Owner QA:
- Owner manual Godot 4.7.2 screenshot proves MAP-EDIT-03 GUI issue; fixing PR still needs real editor visual, mouse/drag and runtime-route QA. No owner acceptance assumed.

Status impact:
- CODE-05-01 remains P0 partial and PR_review while #252 is open; only its own room-builder progress shard changes. No approved geometry, source art or campaign promotion.

Task: `MAP-EDIT-03A` (follow-up to merged `MAP-EDIT-03` PR #251); domain `room-builder`. Parent `CODE-05-01` remains P0 partial. Baseline main `bd60567fb79f28dba45e6236b505827cb122ce20`.

## Owner-reported defect

2026-11-09 owner-provided screenshot (manual Godot 4.7.2) showed top captions vertically character-wrapped into 300+ px labels, grid settings at the bottom of a scroll panel disappearing behind the Output dock, and waypoint placement denied on apparently clear floor with no visible/adjustable limit. The existing project first-floor draft in fact has five walkable polygons, ten no-go polygons and zero individually blocked cells; only the union of the five walkable islands accepts new footpoints.

## Changes

- `route_editor_view.gd`: nonwrapping horizontal toolbar with narrow plain labels; compact canvas minimum; grid controls with Apply moved immediately below Quick Start in the scrollable inspector; visible room/tool, clear single-pixel restriction diagnosis on clicks, quiet user-action rejection instead of repeated Output warnings; two-click WALKABLE/NO-GO rectangle editor and polygon list/select/remove with confirmation. Immutable source never edited.
- `route_canvas.gd`: default-on high-contrast WALKABLE green and NO-GO red polygon fill/outlines and labels; dark cell-centre preview outside walkable union; orange blocked cells; toggle all restriction overlays independently of authored route grid, preview first rectangle corner, highlight selected zone.
- `route_document.gd`: explicit `restriction_at` reasons; copy-on-write `add_zone_rectangle` and `delete_zone` against existing v1 JSON collections only; validate every route and waypoint after any polygon edit; specific invalid-waypoint errors. No new schema or runtime rules.
- New `map_edit_03a_ui_zones_smoke.gd` registered once in `scripts/check.sh`. Verify layout-height/UI controls, 5+10 source polygon counts, overlapping restrictions, reversible polygon edits, add formerly rejected waypoint, blocked-cell distinction, save/load, MAP-QA-07B consumption, and unmodified immutable source/production.
- Updated owner guide `docs/MAP_EDIT_03_EDITOR_USER_GUIDE.md`.

## Boundary and verification

Everything remains `DRAFT_ONLY`. The source PNG, 22-waypoint/19-route versioned baseline draft, production geometry, campaign/save, and MAP-QA-07B movement host remain unchanged. The rectangle editing flow does not claim accurate finished physical collisions, polygons may be too broad until calibrated by owner, and no freehand vertex editing is implemented. Required owner manual GUI/resolution/touch and movement-through-floor QA remain HUMAN_PENDING. All blocked CI jobs on exact final SHA must pass before merge; no auto merge. Rollback: revert scoped PR and re-open unchanged original candidate.

## UPDS-reuse gate

Not applicable to a Raven-specific QA polygon authoring UI: the UPDS donor does not own the approved first-floor image or its draft-only walkability/no-go polygons. Existing RouteDocument, Canvas, integrated adapter and controller are reused; no new gameplay movement architecture.
