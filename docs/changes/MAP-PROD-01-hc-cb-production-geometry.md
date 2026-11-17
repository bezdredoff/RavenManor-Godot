# MAP-PROD-01 — HC/CB Godot geometry, Evelyn and production handoff

Task IDs: MAP-PROD-01; scoped continuation of CODE-05-02.
Changes: Inactive Godot-rendered HC/CB door and floor artwork, Evelyn preview, explicit candidate calibration, QA tests and capture workflow.
Verification: Existing Godot 09B and 09D tests passed in focused CI; candidate test failure diagnosed and correction submitted; exact-head verification pending.
Owner QA: RM-DEC-030 architectural positions approved; actual render, occlusion, headroom and physical-phone acceptance pending.
Status impact: CODE-05-02 remains P0 partial; no production activation or merge.

Task ID: `MAP-PROD-01` · domain `manor-map` · P0 · 2026-11-17. Base `ddcc8a646ffbfa60dcfea43849a592bfdddd9f24` (#257/#261/#270/#278/#280 merged). This is an **inactive architectural/art candidate** under the owner-approved RM-DEC-030 positions, **not an owner-accepted production passage**.

## Changes

- Real Godot `Node2D._draw()` layered floor/backfill and dark-wood, limestone and brass jambs, under-landing structural silhouette and balustrade foreground for HC, and a repainted bedroom partition opening/sill/caps for CB. These are runtime CanvasItem-rendered assets, **not** SVG planning diagrams. Background/door z=2; approved Evelyn z=8; opaque balustrade/caps z=12. Approved first-floor image is independently rendered at z=-20, **never overwritten**. 65° painting is left unprojected.
- Immutable image: `a_detailed_top_down_isometric_game_map_illustratio.png`, SHA-256 `5e0edf97bd719fb1df95c7e9bea2f134d90adad0bc04d1771acc82a95a4d549a`, Git blob `b50bc36cffd3d3aca7e81a0cea28bb3d0c0e9563`, 1672×941.
- Manifest: `assets/raven/map/production/map_prod_01_hc_cb_candidate.v1.json` explicitly retains HC threshold [824,400], near/far [824,424]/[824,384], CB threshold [528,376], near/far [552,376]/[512,376], both 48 source pixels. Contains 12px foot disk, all exact route/contact IDs, 3 permitted rooms, asset layers, lock authority and Agent B prerequisites. `productionReady`, `activationEnabled` and `runtimeAuthority` remain **false**.
- `scripts/raven/map_prod_01_geometry.gd` validates pinned PNG SHA, geometry, contacts and reversibility of an explicit image-pixel ↔ **candidate-world** [128,128] translation from four control pairs. This is a **review-space transformation, not a claimed mapping to the canonical world-plan**. Do not relabel the image pixels as canonical world-plan coordinates.
- Visual review: `res://scenes/raven/tests/map_prod_01_hc_cb_review.tscn`, launched by `godot --path . res://scenes/raven/tests/map_prod_01_hc_cb_review.tscn`. Reuses `first_floor_multi_room_host.gd`, its controller, 09B `RouteDocument` and authored orthogonal cell paths. Before startup, its historical `Onoe` child is replaced with `evelyn_walker.tscn`; the `Onoe` **node name only** is retained for host compatibility. Four direction buttons + independent lock/relock controls + Hall restart + route debug. HA/CK and 07B synthetic transitions are removed from **this preview contract** without changing original 09B.
- No edits to `manor_navigation_source.gd`, gameplay host, main menu, reducer, campaign store, canonical world-map, approved PNG, 09B, 09C or 09D. No second controller or alternative save.

## Verification

New `tests/raven/map_prod_01_hc_cb_candidate_smoke.gd` exercises four directions, both gated doors, in-flight relock, cancellation, actual Evelyn actor/z-order, 0.025s steps ≤3.251px, 12px disk NO-GO clearance, fail-closed production and coordinate round-trip. Dedicated `.github/workflows/map-prod-01.yml` runs Godot 4.7.2, imports assets, executes **existing 09B and 09D tests plus new test** without changing Agent E's shared runners.

**Execution truth:** test script and workflow are authored; mark PASS only from an exact-head run, not merely after committing. In this connected environment there is no local Godot binary. Source/visual style and actual foreground occlusion have **not** been certified via screenshot or a physical phone. Godot-native procedural artwork has not been owner-approved for visual quality, and the HC underside is an illustrated solution, **not** a measured structural section. Route validation reuses 09B constraints; no new physics-body collision controller was introduced, so continuous movement must still be reviewed with Evelyn at final sprite scale. Save/Continue return spawns require Agent B's integration pass.

## Exact Agent B handoff

| Field | Value |
|---|---|
| Room IDs | `RM-ROOM-HALL`, `RM-ROOM-CORRIDOR`, `RM-ROOM-BEDROOM` |
| Door IDs | `RM-DOOR-HALL-CORRIDOR`, `RM-DOOR-CORRIDOR-BEDROOM` |
| QA source | `assets/raven/map/qa/drafts/map_qa_09b_opening_blueprint.v1.json` |
| Room-owned HC approaches | `QA-ROUTE-09B-03` (Hall), `QA-ROUTE-09B-04` (Corridor) |
| Room-owned CB approaches | `QA-ROUTE-09B-05` (Corridor), `QA-ROUTE-09B-06` (Bedroom) |
| Same-point test contacts | `QA-09B-HC-A/B`, `QA-09B-CB-A/B` at their respective thresholds |
| Review transition IDs | `QA-09B-HC-AB/BA`, `QA-09B-CB-AB/BA` |
| Image calibration | Candidate affine translation +[128,128] (must reconcile with canonical plan) |
| Art and foreground | `scripts/raven/map_prod_01_hc_cb_art.gd`, z=2 and z=12, Evelyn z=8 |
| Preview scene | `scenes/raven/tests/map_prod_01_hc_cb_review.tscn` |
| Production activation | **disabled**; do not pass this QA fixture as `PRODUCTION_APPROVED` |

Agent B must validate a *replacement world-plan* with canonical RM-NAV IDs, exact room-art placement/bounds, no teleport at paired thresholds, scene-gate authority and safe-anchor restore, then request owner rendered approval and phone QA before setting `roomArtCalibration.status=approved` or promoting source. The existing production source validates `world-plan`; it does **not** accept image-pixel QA directly. An arbitrary affine offset cannot satisfy that authority alone.

## Owner review and rollback

In Godot scene, unlock HC, walk Hall→Corridor, check the stair underside masks as Evelyn approaches [824,400]; unlock CB, walk Corridor→Bedroom and return. Re-lock mid-walk, check full sprite, actual footpoint and viewpoint at 65°, inspect 48px opening against paint, capture screenshots of both doors with route debug OFF and run on a physical phone. If headroom/visual quality fails, correct art or foreground masks, not RM-DEC-030 coordinates without a new decision. Rollback removes only additive MAP-PROD-01 scripts/data/tests/workflow/scene and unique evidence. No auto-merge.

## G2-03 bounded render correction

Inspected actual artifact 14341720755 from run 44111379440; archive SHA-256 0bb01bd5855d96cdddf0151177960ba22d722361cb1ad395d11189115ad340a9. Original thin bars did not establish full body occlusion. V3 restores the full raised HC landing in foreground, replaces a dark east-wall floor sample with local Hall parquet, clears the CB wall's painted vertical rise and uses a full-height near jamb. Godot 4.7.2 GPU captures and four-direction/collision smoke executed locally in integration. The replacement overlays are still crude candidates: owner visual/structural headroom, painted finish and phone review are pending. All production flags remain false; no source PNG or Evelyn changes.
