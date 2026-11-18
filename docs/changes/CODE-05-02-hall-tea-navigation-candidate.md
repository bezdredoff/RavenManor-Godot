# CODE-05-02 / MAP-TEA-01 — Hall Tea physical navigation candidate

**Registered task:** CODE-05-02 · **domain:** manor-map · **priority:** P0  
**Branch:** `agent/manor-map/CODE-05-02-hall-tea-route-candidate`, stacked on PR #293 (`agent/manor-map/CODE-05-02-chapter-ii-iii-spatial-readiness`).  
**Status:** **DRAFT_ONLY / TEST_ONLY / owner review pending**. No production authority, no canonical Hall Tea activation. Physical phone, browser and owner acceptance **NOT_RUN / NOT_APPROVED**.

## Source and review contract

- Pinned G2 world plan: `data/raven/manor_production_candidate.v1.json`, SHA-256 `f9c7ee86fa5e819cc3cfb1e1415537ee38c952b80d2c3b611e2346d9525d171a`; 119 anchors and 120 edges. Signed `manor_production_acceptance.v1.json` remains unchanged.
- Immutable approved first-floor bitmap: `a_detailed_top_down_isometric_game_map_illustratio.png`, Git blob `b50bc36cffd3d3aca7e81a0cea28bb3d0c0e9563`, SHA-256 `5e0edf97bd719fb1df95c7e9bea2f134d90adad0bc04d1771acc82a95a4d549a`, dimensions 1672×941.
- Reuses production source's **single** image-pixel→world-plan translation `(+128,+128)` and its 65° **already painted** projection. No second sin(65°) distortion.
- Existing approved Hall route reaches `RM-NAV-HS-001` at world `(952,792)`, original image `(824,664)`. This is a source-owned route waypoint/interaction, not an invented diagonal.
- Existing Hall no-go `QA-08B-HALL-TABLE` is image rectangle `x=788..880, y=548..623`, documented as the **central round flower table** in earlier QA calibration. Hall Tea story calls for a tea table/chairs; the owner must visually confirm that this rendered furniture is the correct canonical target. No claim that the old historical greybox `RM-NAV-HALL-TEA=[290,340]` is calibrated.
- **Proposal:** one `RM-NAV-HALL-TEA` interaction anchor at world **`(984,784)`** = image **`(856,656)`**, `hotspotId=RM-HS-TEA-TABLE`, `checkpointAllowed=false`; one bidirectional authored Hall edge from `RM-NAV-HS-001`. Source image approach **`(824,664) → (856,656)`** is a ~33px southeast move on the existing southern parquet. Table south edge y=623 gives **33px vertical footpoint gap** at the arrival; the production validator uses 12px foot radius. Table visual tap centre proposal is image `(834,584)`, deliberately distinct from the actor's physical footpoint. This is *not* an owner-confirmed touch hitbox.
- In-memory QA assembly: **120 anchors / 121 edges**, no other changed anchor, no additional door, no collision polygon changes. Signed on-disk production geometry stays at **119/120**.

## Implementation / reversibility

The tiny data delta lives at `assets/raven/map/qa/drafts/map_tea_01_hall_route_candidate.v1.json`. `scripts/raven/map_tea_01_candidate.gd` loads the immutable pinned G2 world-plan **read-only**, verifies the image SHA and base counts, deep-copies the graph in memory, explicitly forces `approval=DRAFT_ONLY`, `productionReady=false`, `activationEnabled=false`, `runtimeAuthority=false`, `ownerApproved=false`, appends exactly the anchor and one edge, then calls **the existing** `ManorNavigationSource.validate_calibrated_plan`. `ManorNavigationSource.resolve(mode=production, worldPlan=QA_delta)` must refuse the candidate. No save, reducer, VN dispatch, gameplay-host, player-map, first-floor PNG, doorway, Foundation ID, source activation switch or QA runner scripts are modified.

`scenes/raven/tests/map_tea_01_hall_review.tscn` is a standalone Godot review scene. It renders the original Hall bitmap, already existing V4 HC/CB foreground art and accepted Evelyn. Tapping the visible tea table marker or pressing **Tap tea table** calls the **existing `ManorRouteSession` + `ManorNavigationGraph`**, and Evelyn's existing segment mover advances physically after authorized segments. The render includes on/off walkable green overlays, red no-go polygons, existing blue Hall waypoints, yellow tea approach/footpoint and a mobile camera crop. Buttons reset review-only spawns to Hall safe, HC-return or another Hall anchor; pause, resume and cancellation are available. No VN is triggered and no game state is persisted.

### Reproducible verification

- Godot 4.7.2, existing scene: `godot --path . res://scenes/raven/tests/map_tea_01_hall_review.tscn`
- Dedicated test: `godot --headless --path . --script res://tests/raven/map_tea_01_navigation_smoke.gd`
- Real Godot-rendered visual capture under xvfb: `xvfb-run -a godot --path . --script res://tests/raven/map_tea_01_visual_capture.gd`; emits five files under `build/map-tea-01/`: before, after-route/NO-GO, clean Evelyn arrival, 390×844 mobile with and without overlay.
- Isolated `.github/workflows/map-tea-01.yml` runs original 09B authored routes, existing HC/CB visual/door smoke, original G2 production E2E, new Hall Tea navigation smoke and actual Godot capture. It uploads `map-tea-01-Hall-Tea-Godot-Review-TEST-ONLY`. Shared `scripts/check.sh`, `check.ps1`, all existing workflow YAMLs and Agent B QA runners remain untouched.
- Existing repository-wide CI remains required at the **exact final PR head**. Any test without logs and matching SHA is **NOT_RUN**, never PASS by inference. Real phone/browser visual/touch/manual tests are **NOT_RUN** pending genuine execution. The visual review cannot certify animation/foreground or chair collision merely by reading the JSON.

### Expected test cases

1. Hall safe spawn → tea: full authored A* route, continuous Evelyn segment movement, no teleport.
2. After HC return (`RM-NAV-HALL-CORRIDOR-NEAR`) → tea: reverse approved Hall waypoints and branch.
3. Other Hall anchors → tea: route available and no clipping.
4. Pause/resume: walker holds same XY; cancel during movement: finish only the current confirmed segment and no false arrival event.
5. Safe Hall checkpoint/reload → tea; forged last-safe anchor at interaction point rejected.
6. Historical HC/CB four directions and room anchors preserved. Both doors retain original gates and no new cross-room edge.
7. 12px foot radius clearance from source no-go polygons using existing production validator. Do **not** infer independent furniture/art silhouette clearance without viewing captures.

### Coordination / collision prevention

| Open concurrent PR | Boundary |
| --- | --- |
| #293 Entry/Kitchen/Archive access audit | **Stacked on its head**. This PR adds exactly one owned, append-only entry to the same manor-map progress shard; preserves #293 evidence and documentation. After #293 merges, rebase/re-target to main and run exact-head CI again. |
| #295 VN-HALL-TEA-01 | Its gameplay host/dispatcher maps `RM-HS-TEA-TABLE` to `hall_chair_table` but remains fail-closed until a signed production route and VN approvals. No edit to its six files. |
| #294 GAME-QA-03 | No shared test-runner or QA shard changes; dedicated map test uses unique filename. |
| #292 VN-ART-REUSE-01 | No art or staging/cue edits. |
| #296 VN-GATES-01 | No gate contract, story, locale or VN readiness edits. |

**UPDS-first reuse classification:** **not applicable** to a Raven-only geometry delta/standalone QA review scene. No gameplay or menu UI is replaced. Existing Raven RouteSession/AStar, collision validator, approved Evelyn and G2 artwork are reused; no second controller, renderer or state authority is introduced.

## Production activation proposal — separate integration owner and owner decision

1. Run the dedicated workflow and all existing repo checks at final head. Inspect the **actual** Godot screenshots, including clean artwork, table/armchair relationship, Evelyn feet and mobile crop; owner manually confirms which rendered table is canonical Hall Tea and whether `(856,656)` is visually correct and chairs clear.
2. Owner explicitly records **new Hall Tea-specific approval** in `docs/DECISIONS.md` with reviewed captures/coordinate/footprint. HC/CB decisions RM-DEC-030/031 do **not** automatically approve Hall Tea. If declined, adjust only QA delta and rerender/retest.
3. In a **separate shared integration-owner reviewed PR**, migrate the approved delta into a new version of authoritative production world-plan, verify Room Builder graph provenance, re-run the native collision checker and Hall→Corridor→Bedroom→Corridor→Hall, acquire exact new world-plan SHA-256 and update its signed acceptance receipt/owner decision/provenance. Never alter the old signed receipt merely to make this QA candidate pass.
4. Combine with approved #295 runtime bridge and independent Hall Tea scene/portrait readiness. Verify real player input → confirmed physical arrival → exact hotspot ID → canonical 12 lines → reducer beat event → save → Continue, RU/BE/EN, interrupted route, failed saves, read-only Skip, foreground and no autoplay. Only the integration owner enables normal gameplay, and the source authority switches **after** its receipt matches.
5. Real phones/tablets and browser: click/touch hitbox not overlapping other Hall hotspot, safe areas at 390×844, no furniture or wall clipping, no hard jump at arrival, pause/cancel/reload, route overlay off in production. Record **NOT_RUN** until performed.

**Rollback:** before activation, revert only the isolated QA files, new workflow, this document and appended manor-map progress evidence; production unchanged. After a separately approved activation, restore the previous signed G2 world-plan bytes + matching receipt atomically, re-run full G2 regressions, and continue to load saved position only through safe Hall anchor resolution (tea interaction anchor is never a persisted checkpoint). Do not silently remap save/scene authority.

**Progress:** CODE-05-02 remains `partial / P0`; this bounded route candidate is not task completion. This record does not certify any CI, owner, mobile or browser result until its exact evidence is added.
