# MAP-EDIT-05 — Fully editable navigation constraints

Task IDs: MAP-EDIT-05 (P0), CODE-05-01 (P0 parent)
Changes: Provenance labels, bulk AI-only constraints preview/confirmation with native magenta overlays and Undo/Redo, optional OPEN walkable boundary mode, retained manual obstacles, no production promotion.
Verification: MAP-EDIT-05 Godot smoke registered once in scripts/check.sh; existing MAP-EDIT-01–04A and MAP-QA-05/07B retained. Exact-head GitHub Actions pending at initial record; owner visual QA pending.
Owner QA: Manually verify original polygons, clear preview/cancel/confirm, history, waypoint and freehand after clear, Saved user F6 integrated Onoe movement and room transitions at actual window size.
Status impact: Only room-builder status shard updated; CODE-05-01 remains P0 partial / PR_review, no production geometry acceptance.

- **Owner domain:** room-builder
- **Priority:** P0; partial slice under CODE-05-01
- **Baseline main:** beb43cc118c0953db70e1f5644f70bbe512e4130 (2026-11-15)
- **Dependency:** MAP-EDIT-04A PR #254 was already merged after #253; original polygon handles/list selection, insert/remove and Undo/Redo were reused, not rewritten
- **Scope:** native draft-only RouteDocument/RouteCanvas/RouteEditorView/RouteFreehand, dedicated regression test, existing check runner, owner guide, owner shard
- **Donor check:** UPDS gameplay UI is not applicable to the Raven image-pixel authored navigation constraint domain. Keep its existing editor API rather than introducing a second runtime or exporter.

## What changed

1. Explicit in-editor origin labels distinguish AI_DRAFT, USER_DRAFT and UNSPECIFIED_DRAFT polygons. Original Hall source NO-GO identifiers (which lack status fields) are covered by a narrow stable-ID allowlist; explicit AI_ESTIMATE and legacy visual_estimate statuses are recognized. Unclassified legacy obstacles are not deleted.
2. New editor-created polygons and painted blocked cells record USER_DRAFT provenance. Optional blockedCellOrigins metadata is validated; original schemaVersion 1 documents load without it.
3. A non-mutating **Clear AI constraints…** confirmation shows exact removal counts, up to seven IDs, retained user/unknown counts and magenta map overlays. Confirm commits one validated draft edit to normal history; cancel and stale previews cannot mutate.
4. Clearing imported green WALKABLE regions switches the optional draft walkableBoundaryMode to OPEN. This prevents retained partial user zones from silently invalidating original waypoints. An explicit checkbox can re-enable REQUIRE only if document validation permits it. NO-GO, blocked cells, art bounds and waypoint-room ownership remain enforced; Freehand respects the same mode and still forbids entering other known room-owned regions.
5. Existing authored route IDs, waypoint IDs, JSON v1, MAP-QA-07B TEST_ONLY adapter, user/project draft save paths and immutable original map remain unchanged. No auto-routing, no authority promotion.

## Verification

- Added tests/raven/map_edit_05_editable_constraints_smoke.gd, registered once in scripts/check.sh.
- Coverage: original 5/10 polygons, provenance of user zones and AI-tagged blocked cells, preserved manual constraints, clear preview/cancel/confirm, single-step Undo/Redo, safe OPEN mode, invalid REQUIRE rejection, waypoint placement and freehand after clear, save/reload, MAP-QA-07B adapter, byte-stable original/QA source and canonical graph.
- Existing runner retains MAP-EDIT-01/02/03/03A/04/04A, MAP-QA-05 and MAP-QA-07B.
- **Local Godot 4.7.2 and human GUI/device QA: NOT RUN at PR creation.** GitHub Actions exact-head evidence must be appended only after execution, not assumed.
- **Acceptance:** source geometry is DRAFT_ONLY, runtime transitions TEST_ONLY; owner approval of visual navigation and real doors remains separate.

## Risks and rollback

- OPEN floor is deliberately permissive for user authoring after bulk AI clear, not an approved collision plan. Validate visually before recording any accepted route.
- Unknown/legacy unlabeled cells are intentionally excluded from bulk AI clear; unblock them individually if desired.
- Undo before saving, reload the original project draft, or revert this PR. No default source JSON gets silently rewritten.
