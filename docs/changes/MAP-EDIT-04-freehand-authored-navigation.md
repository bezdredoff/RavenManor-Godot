# MAP-EDIT-04 — Freehand authored navigation (Room Builder)

Task IDs: MAP-EDIT-04 (P0 scoped technical task), CODE-05-01 (P0 parent partial)

Changes: Native freehand draw/preview/Apply/Discard, deterministic orthogonal converter, same-room and walkability protection, redraw stable IDs, optional owned WALKABLE rectangles, owner guide.

Verification: New Godot MAP-EDIT-04 smoke plus all existing regressions registered; initial GitHub Actions CI pending repair; no local Godot binary or claim of passing tests.

Owner QA: HUMAN_PENDING — Godot visual window sizes, drag and route geometry, persisted user draft and physical Onoe playback in MAP-QA-07B.

Status impact: Only room-builder shard updated, CODE-05-01 remains P0 partial and PR_review while PR #253 is open; no owner acceptance, no approved art or canonical geometry.


Date: 2026-11-09. Domain: `room-builder`. Priority: P0 technical subtask of `CODE-05-01`. Baseline: main `2d692e48129ee3d391816e4e405d50c217225f99` (#251/#252 merged). Approval: **DRAFT_ONLY**, **AI_PROVISIONAL_UNAPPROVED**, **TEST_ONLY** QA playback.

## Scope and reuse
- Reuse native `RouteCanvas`, `RouteEditorView`, `RouteDocument.set_route_cells()`, existing v1 draft persistence and MAP-QA-07B adapter/compiler. Godot-native editor workflow; no UPDS donor because pixel-authoring is Raven-specific editor functionality (not gameplay UI or movement). No duplicate runtime controller.
- Tool **9 Draw route (freehand)**: press/drag/release over approved PNG; raw blue line, proposed lime grid, red error marker; adjustable 0–48 px simplification; explicit Apply/Discard, Escape, history, stable redraw ID/direction.
- New routes are created via existing add_route API only as part of a validated, atomic proposal; user draft changes only on Apply. Existing routes use set_route_cells with the same ID, endpoints and bidirectional flag.
- Converter interpolates sparse samples with deterministic Manhattan steps; rejects repeated backtracking, blocked/nonwalkable/no-go pixels, crossing between allowed centres, wrong room ownership, image exit and endpoint misalignment. Full final validation uses RouteDocument, not a second navigation policy.
- Existing `walkablePolygons[].roomId` is now also attached to newly drawn WALKABLE draft rectangles when edited natively; older unowned rectangles remain readable (and must be explicitly redrawn under an editing room to authorize freehand routes). No source, canonical or production mutation.

## Verification
- New `tests/raven/map_edit_04_freehand_routes_smoke.gd` covers horizontal/vertical/L/multi-turn, sparse/diagonal/noisy/repeated samples, blocked/NO-GO/room boundaries, endpoints, redraw/direction, actual native input and explicit commit, Undo/Redo, save/reload, MAP-QA-07B adapter and untouched canonical files.
- Registered once in `scripts/check.sh`; prior MAP-EDIT-01/02/03/03A and MAP-QA-05/07B untouched.
- **Execution evidence:** local Godot unavailable in the connector environment; GitHub Actions exact-head result to be recorded when available. Any failing result remains a blocker; no claim of success from merely adding tests.

## Owner QA / rollback
- HUMAN_PENDING: inspect the native Godot 4.7.2 workspace at common window sizes, drag/mouse capture, simplified corners, red invalid previews, save → Play integrated first floor → actual Onoe route and physical clearance.
- All routes remain owner-unapproved provisional QA geometry, no canonical first-floor manifest, source PNG, runtime authority, saves, match3, VN, main menu or other dashboard shards edited.
- Rollback: revert the scoped PR; the unchanged DRAFT_ONLY v1 draft and existing numbered tools remain compatible.
