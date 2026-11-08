# MAP-EDIT-01 — Visual Grid & Authored Route Editor (native Godot MVP)

**Status:** technical QA authoring tool, not production navigation. **Domain:** `room-builder`. **Schema:** `raven-grid-route-draft` v1. **Art:** approved Hall PNG 1672×941 with immutable SHA-256 `5e0edf97bd719fb1df95c7e9bea2f134d90adad0bc04d1771acc82a95a4d549a`. All geometry remains `DRAFT_ONLY`.

## Open the editor

1. Checkout the MAP-EDIT-01 PR branch in Godot **4.7.2** and import `project.godot`.
2. Choose **Project → Project Settings → Plugins** and enable **Room Builder · Navigation / Routes**. This is intentionally opt-in; no shared `project.godot` edit.
3. Switch to the new top-level **Navigation / Routes** tab (similar to native VN Studio).
4. If a user draft already exists in `user://room_builder_routes/hall_routes_draft.v1.json`, it opens automatically. Otherwise it imports the seven Hall QA waypoints and seven draft edges. Press **Import Hall QA** to explicitly re-import the untouched source.
5. **Load project draft** imports the bundled sample at `assets/raven/map/qa/drafts/hall_routes_draft.v1.json`. Saving to this project draft path is explicit via **Export project draft**. It never writes back to `assets/raven/map/qa/first_floor_hall_pilot.v1.json`.

## Manual authoring QA

- **Grid:** default 32×32 source pixels. Edit W/H, Origin X/Y and Show grid/Show cell coordinates, then Apply. Column labels run A...Z, AA, AB..., rows 1...; `H7` means column 8 row 7. The **centre** of H7 at the default grid origin is image coordinate `[240,208]`. Pan with right/middle mouse drag or Pan mode; wheel zoom and Fit do not modify pixel positions.
- **Waypoint:** select a dot from image or sidebar list; drag it on the art, snapping to grid cell centres by default (uncheck Snap for exact pixel calibration). Selected cell, pixel coordinates and obstacle state are shown. To create: click empty image space then **+ Add at selected pixel**. Rename display label/change type and Apply; the internal stable `QA-*` ID stays unchanged. Deletion of connected waypoints is rejected until the referencing routes are removed.
- **Route:** switch to Routes, choose source and target in two dropdowns (or click two waypoint circles in succession), then **+ Add provisional edge**. It starts as an explicit unapproved straight segment. Select it in the route list; enter an *exact* orthogonally adjacent sequence from source cell to destination cell, for example `AA24 → AA23 → AA22` for the existing Hall Spawn→Centre footpoints. Press **Apply cells** to validate and store the authored route. Click next cells on the image to append to the text field; **Remove last cell** backs out a step. Double-step/diagonal/out-of-image/bad syntax, waypoint-cell mismatch and any blocked/no-go/walkable conflict report an actionable error. The text and preview are linked. Direction checkbox toggles one-way/bidirectional; selected route is highlighted. Imported provisional edges remain visually dashed until authoring completes.
- **Obstacle:** switch to Obstacles, paint blocked cells with left mouse (or click again to unblock). Blocked cells are red; read-only source no-go polygons are translucent red and walkable polygon green. The editor refuses blocking a waypoint or route. Unblock selected cell clears a specific cell; errors never commit partial documents.
- **Test Route:** choose start/end in the waypoint dropdowns and press **Test Route**. The editor compiles a separate in-memory `NavigationGraph`, inserts deterministic `QA-ROUTE-*-STEP-NNN` intermediate anchors (one for each non-endpoint authored route cell), and highlights the resulting directed path and length in image pixels. This uses the same AStar/route contract as the Raven runtime, without copying its movement controller. **Open Hall Pilot (original)** opens the existing Onoe scene for separate animation QA; it intentionally does *not* run edited draft paths until a future reviewed runtime handoff is designed.
- **Undo/Redo:** modify a waypoint, grid, route, direction or obstacle and use toolbar Undo/Redo. `● UNSAVED changes` tracks divergence from the last stored draft. Edits use copy-on-write; a rejected edit cannot corrupt the current document.
- **Persistence:** **Save user draft**, leave and reopen Godot, then check automatic recovery (or Load user draft). **Export project draft** saves to `res://assets/raven/map/qa/drafts/hall_routes_draft.v1.json` for review/version control. The import source is immutable. Save outside the two approved draft directories is rejected.

## Architecture and safety

The existing `tools/room-builder/` is a PWA, not a native Godot EditorPlugin. This module follows the verified `addons/vn_studio/plugin.gd` *main-screen* plugin pattern instead of rewriting the PWA. It preserves the approved art source identity and the same DRAFT_ONLY non-promotion rule as the browser `firstFloorDraft` v2; image-pixel route cells are deliberately **not** mistaken for world-plan navigationAnchors.

The data contract contains: schemaVersion/kind/approval/authority flags, source image path/dimensions/hash/blob SHA, grid W/H/origin/visibility, waypoints with stable IDs/display labels/types/exact pixel footpoints, ordered cell route paths and explicit provisional flag, blocked cell IDs, original walkable/no-go polygon copies, and monotonic ID counters.

- All authored steps are orthogonal neighbours. There is **no silent diagonal interpolation** and no extra 65-degree projection of painted art.
- Imported straight edges carry `provisional: true` and `cells: []`, visibly dashed. Compiling such an edge uses its source endpoints, **not an imagined intermediate approved path**.
- The project sample JSON, user draft and in-memory preview contain no campaign state, no door transition, no checkpoint events and no production geometry promotion.
- The QA graph compiler emits existing compatible `anchors`/`edges` as a temporary `NavigationGraph`. A future explicit integration adapter could feed a reviewed export to the original `RouteSession` / `onoe_segment_mover.gd`; not part of this PR.
- Only the preapproved original Hall image (1672×941) is supported in this MVP. General multi-room asset switching, editable polygon vertices, runtime pilot injection and embedded animated Onoe playback are follow-ups.

## Tests (Godot 4.7.2)

```sh
godot --headless --editor --path . --import
godot --headless --path . --script res://tests/raven/map_edit_01_routes_smoke.gd --quit-after 120
# Existing Room Builder import scene smoke is invoked separately in pages.yml
godot --headless --path . --script res://tests/raven/map_qa_03_hall_movement_smoke.gd --quit-after 120
godot --headless --path . --script res://tests/raven/onoe_segment_movement_smoke.gd --quit-after 120
godot --headless --path . --script res://tests/raven/manor_navigation_graph_smoke.gd --quit-after 120
bash scripts/check.sh
```

The isolated `tests/raven/map_edit_01_routes_smoke.gd` invokes `tests/raven/map_edit_01_routes_checks.gd` exactly once in `scripts/check.sh`; the original `room_builder_game_import_smoke.gd` remains unmodified and runs separately in the existing `pages.yml` Godot import step. The shared runner also contains MAP-QA-06 exactly once. The integration-owned `scripts/check.sh` entry is necessary for blocking Godot CI. It verifies import/identities, cell-to-pixel/offset/AA... columns, source bounds, waypoint edits/dependency deletion, orthogonal route parsing, ordered cells, no-go/blocked rejection, one-way/bidirectional compiled AStar connectivity, JSON save/reopen, immutable source/canonical graph and non-promotion. No new workflow or job; one narrowly scoped callsite in shared `scripts/check.sh` requires integration-owner review.

## Limitations and owner QA

Headless tests validate geometry contracts, not actual sprite occlusion or editor ergonomics. The editor needs manual review for clickable grid legibility, viewport pan, drag/drop, undo/redo feedback and GDScript UI. No screenshots are claimed unless captured from a real Godot GUI. The seven original footpoints and polygons are still **unapproved**; compiled QA routes cannot be used for live gameplay until separate owner review and transition-runtime integration.

**Follow-up candidates:** MAP-EDIT-02 (arbitrary-room image selection + polygon editor), MAP-EDIT-03 (runtime draft-preview adapter with physical Onoe, only after owner review), MAP-EDIT-04 (PWA Room Builder import/export of versioned image-pixel route drafts). These are not automatically registered production tasks.

Rollback: delete `addons/room_builder_routes/`, its draft fixture, dedicated MAP-EDIT-01 smoke wrapper and check.sh registration, documentation and own shard evidence; leave independent MAP-QA-06 and existing Room Builder import smoke unchanged. No canonical assets, `project.godot`, campaign or runtime scene changes were made.
