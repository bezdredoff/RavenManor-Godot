# MAP-EDIT-03 — Native Navigation Editor usability and waypoint room ownership

Task IDs: MAP-EDIT-03 (technical QA/editor slice), CODE-05-01 (P0 parent, partial)

Changes:
- `route_document.gd`: explicit five-room IDs, stable legacy Hall fallback only for the seven original IDs, required room for newly created points, copy-on-write room changes, validation of explicit malformed room IDs, same-room route creation and fail-closed cross-room route edits.
- `route_canvas.gd`: room-aware editing, selected-route high-contrast path, direct route hit-test as the boundary for future freehand drawing, separate add/connect/route/cell tools.
- `route_editor_view.gd`: named active tools, room selection/filter, explicit waypoint room inspector, click-to-add and click-two-points-to-connect workflows, selected room/point/route labels, adjacent-cell guidance, improved file actions and existing MAP-QA-07B launcher with unsaved-change safety.
- New `tests/raven/map_edit_03_usability_checks.gd` / smoke and one `scripts/check.sh` registration; existing MAP-EDIT-01 tests updated to pass an explicit room on newly authored points.
- Step-by-step owner guide at `docs/MAP_EDIT_03_EDITOR_USER_GUIDE.md`.

Verification:
- Baseline main `bcd459b9b72bcaf971e6da420a928bdf309d3b10`, PR #250 merged. Local Godot execution not available in the connector environment. Exact-head GitHub Actions evidence must be attached after full CI execution. Existing checks MAP-EDIT-01/02, MAP-QA-05/07B, Room Builder and map regression remain mandatory.

Owner QA:
- Godot editor GUI (tool text, route highlighting, dragging, scroll layout, Windows resolution) remains HUMAN_PENDING. No claim of production geometry approval; physical portal positions remain unresolved. PLAYABLE QA uses real Onoe movement but is DRAFT_ONLY / TEST_ONLY.

Status impact:
- `CODE-05-01` still P0 partial/PR_review while PR is open. MAP-EDIT-03 is a scoped enhancement rather than completion of production Hall geometry. The domain owner must record verified merge separately. Rollback: revert scoped files/registration/evidence; immutable baseline assets/canonical navigation/save remain unchanged.
