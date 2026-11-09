Task IDs: MAP-EDIT-02 (scoped runtime-preview slice); linked CODE-05-01 (canonical P0 Room Builder parent, remains partial)
Changes: Fail-closed read-only Hall QA selector (original/user/project), strict v1 image hash/schema/coordinateSpace/approval validation, compiled authored-cell anchors and directed routes via existing graph/session/Onoe mover, explicit editor Play actions, one-shot source ticket, pause/resume/stop and QA overlay; no canonical graph/save/transition mutations.
Verification: Local Godot executable unavailable; tests NOT_RUN locally. New Godot MAP-EDIT-02 deterministic smoke registered exactly once in scripts/check.sh with existing MAP-EDIT-01, MAP-QA-03 and movement tests retained; exact-head GitHub Actions PENDING.
Owner QA: NOT_RUN — Godot editor-to-play route roundtrip, changed turns/feet, pause/stop, mobile/touch panel, F3 and source warning require manual confirmation.
Status impact: Scoped MAP-EDIT-02 technical QA PR #247 remains PR_review, linked CODE-05-01 still partial P0. No production first-floor geometry or owner/device acceptance.

# MAP-EDIT-02 — Playable preview of editor-authored Hall routes

**Task:** MAP-EDIT-02 (scoped Room Builder QA, not approval of CODE-05-01).
**Domain:** `room-builder`, cross-boundary Hall QA integration reviewed through this PR.
**Base:** `main@0afb155e8f0528f9bd91760e4c76f38ed61a1e34` (PR #245/#246 merged).
**Status:** PR under review; owner/device acceptance NOT_RUN. Production map and campaign unchanged.

## Changes

- Add a fail-closed read-only `route_preview_source.gd` adapter with explicit `original`, `user`, `project` selectors. Original uses `first_floor_hall_qa_graph.gd`; persisted drafts use `route_document.gd` validation and the existing `compile_qa_graph` contract. Image provenance, image-pixel coordinates, `DRAFT_ONLY`, path and schema are mandatory.
- Keep all authored intermediate cell anchors and directed/bi-directional edges; expose the imported provisional edge count and edge provenance. `ManorNavigationGraph` still runs the graph; `ManorRouteSession` still authorizes each segment and `onoe_segment_mover.gd` moves actual Onoe feet. No `AStarGrid2D` gameplay replacement.
- Add a short-lived, one-shot `user://room_builder_routes/preview_launch.v1.json` ticket to hand the editor's explicit saved draft choice to the separate play process. A missing ticket means original Hall. Invalid/expired tickets and draft validation errors **do not** fall back to original.
- Native Route Editor has separate **Play original Hall**, **Play saved user (Onoe)** and **Play project export (Onoe)** buttons; draft play refuses unsaved editor edits. Runtime source buttons are also explicit. Switching sources restarts an isolated QA scene instead of teleporting a moving actor.
- Hall HUD reports selected source and provisional routes, supports pause/resume, stop-after-current-safe-leg, F3 actual route overlay, camera pan/zoom and touch destination picking. No writes to production checkpoints or doors. Original QA regressions retain their baseline scene.
- Harden draft loader malformed nested structures and path traversal; add a deterministic movement integration smoke, registered exactly once after MAP-EDIT-01 in `scripts/check.sh`.

## Verification

- Automated checks added: `tests/raven/map_edit_02_playable_preview_smoke.gd` covers saved load, exported project load, source identity, compiled turns, intermediate anchors, directed edges, physical Onoe segments, pause/resume, cancellation/stop, stale reload, invalid/blocked file, immutability of 13 canonical anchors and original Hall baseline.
- Required commands:
  ```sh
  godot --headless --editor --path . --import
  godot --headless --path . --script res://tests/raven/map_edit_02_playable_preview_smoke.gd --quit-after 180
  godot --headless --path . --script res://tests/raven/map_edit_01_routes_smoke.gd --quit-after 120
  godot --headless --path . --script res://tests/raven/map_qa_03_hall_movement_smoke.gd --quit-after 120
  godot --headless --path . --script res://tests/raven/onoe_segment_movement_smoke.gd --quit-after 120
  bash scripts/check.sh
  ```
- At authoring time, local execution NOT_RUN (Godot binary unavailable in this environment). GitHub Actions exact-head checks PENDING; do not infer passing behavior from code review.

## Manual Owner QA

1. Enable `Room Builder · Navigation / Routes` in Godot 4.7.2 Editor Plugins, open Navigation / Routes.
2. Select `QA-ROUTE-001` (Hall Spawn → Hall Centre), edit cells to `AA24 → AA23 → AA22`, Apply. Verify the preview line bends via `AA23`.
3. Click **Save user draft**; after the **✓ Saved** indicator, choose **Play saved user (Onoe)**.
4. In the game verify `SOURCE: user` and choose `QA-HALL-CENTRE`. Toggle **QA** / F3: Onoe must stop physically at the intermediate `QA-ROUTE-001-STEP-001` anchor and then finish at Centre. Pause/Resume with button/Space; Stop/S finishes current leg without teleporting.
5. Return to the editor (Stop the running custom scene), edit the path and **do not** save. **Play saved user** should refuse to launch. Save, play again, and verify the new turns.
6. Click **Export project draft** and **Play project export (Onoe)**; the HUD must show `SOURCE: project`. Exercise the Original button / Play original Hall to confirm the original seven-waypoint regression remains distinct.
7. On mobile or a touch simulator verify marker taps, drag-pan, +/- zoom and on-screen Pause/Stop/source buttons.
8. Break a *test copy* of a QA draft (wrong source hash/blocked route) and confirm preview reports an error rather than falling back to the original or moving the actor.

**Limitations:** Hall-only sprite/portal presentation; one fixed user and project draft export filename per category (replacement is explicit). Any future MAP-QA-05 draft compatible with the same v1 schema can use those paths and authored ID/edge compiler without code changes, provided it includes a Hall spawn and at least one reachable destination. Explicitly provisional imported straight edges remain playable only as validated **QA**, prominently flagged; they are NOT owner-approved. No production navigation promotion, room transition controller edits, additional scene assets, checkpoint/store writes or owner geometry acceptance.

**Rollback:** revert the source adapter, launch ticket, QA pilot/editor integration and new smoke, restoring the previous `scripts/check.sh` call list. Do not revert PR #245/#246.
