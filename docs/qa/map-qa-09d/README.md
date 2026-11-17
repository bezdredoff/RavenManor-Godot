# CODE-05-02 / MAP-QA-09D — HC / CB architectural decision package

**State:** `DRAFT_ONLY`, `productionReady=false`, `runtimeAuthority=false`.
**Base:** main `0d1886b0d01491047dbd900b260757623c6ef9bc`. Reconciles merged PRs #258, #261, #270, #272. Reviewed source is the **immutable** 1672×941 PNG (`b50bc36cffd3d3aca7e81a0cea28bb3d0c0e9563` Git blob, SHA-256 `5e0edf97bd719fb1df95c7e9bea2f134d90adad0bc04d1771acc82a95a4d549a`). The numeric blueprint is the prior 09B TEST_ONLY fixture, not a production map.

## Before / after over the approved painting

- **[HC visual compare](hc-before-after.svg):** original on left; conditional floor backfill, 48px sill, jamb, possible stair-front masks, 12px feet and 62px bodies on right. The **after** is an *annotated hypothetical underpass*, not a physically verified opening. Under-landing floor, wall, structural bearing, underside headroom and stair elevation cannot be deduced from the flat image. No automatic travel promotion.
- **[CB visual compare](cb-before-after.svg):** original partition on left; proposed continuous 88×48px floor strip (x480..568, y352..400), wall cut x520..536, 48px opening y352..400 at x528, upper/lower caps and 12px foot contacts on right. Requires real painting and owner acceptance. No bathroom gate.
- The SVG files reference the approved PNG via relative path `../../../a_detailed_top_down_isometric_game_map_illustratio.png`. Open the SVGs **from a repository checkout** for original-pixel comparison. They are intentionally vector, non-destructive overlays, *not* standalone baked PNGs or accepted Godot foreground textures. If a GitHub viewer blocks relative images, use a local clone or view the [original image](../../../a_detailed_top_down_isometric_game_map_illustratio.png) with the overlay; do not mistake a blank image panel for missing approved art.

## Architectural finding and options

| Door | Contacts, pixel plane | Geometry outcome | Decision |
|---|---|---|---|
| **HC** | Hall (824,424) → sill (824,400) → Corridor (824,384); 48px | **Blocked** for production. A flat QA floor strip through the central stair landing is geometrically testable but its headroom/elevation is not certified; painted riser/landing cannot be called a ground-level passage. A shift to x≈992 also crosses the 09B east-stair NO-GO box (x938..1024, y450..632). West flank (x642..735 stair) is likewise constrained. No proven 48px flat bypass exists in current authored evidence. | **HC-1** explicitly redesign/reveal structural underpass, with sectional proof and foreground masking; or **HC-2** commission a visible ground-level opening with floor and new calibrated coordinates. Until then do not invent an invisible alternative. |
| **CB** | Corridor (552,376) → sill (528,376) → Bedroom (512,376); 48px | **Candidate** for visible partition cut, same elevation. No door painted at existing mark. Continuous sill and jamb caps need raster art/foreground review. | Approve or revise x528/y352..400, finish, width and masks. Bedroom entry remains independent of bathroom work (RM-DEC-006). |

Both paths keep their **canonical door IDs**, room pairs and near/far RM-NAV anchors. Existing 08B room-owned orthogonal routes and 09B shared XY sills are **unchanged**. No door unlock, campaign state, save migration, actor sprite, production collision or projection change occurs.

## Coordinate and layering contract

Approved PNG already includes its intended painted ~65° elevation. Feet positions above are **source pixel XY**, not compressed once more by `sin(65°)`. Ground contact is a 12px-radius QA disk. A nominal 48px clear opening offers 12px disk margin per side at its centered sill; **this does not prove a full 62px actor fits below the HC landing**.

Review overlay layer order (not applied to runtime): original image `z0` → proposed floor/backfill `z1` → painted wall-cut / jamb `z2` → actor `z10` → **new** landing/partition-cap foreground masks `z20`. Foreground masks must be cut from repainted architectural art, not the original image wholesale. Gate-closed must still block both directions independently of occlusion visibility.

The machine-readable [review record](../../../assets/raven/map/qa/drafts/map_qa_09d_hc_cb_architectural_review.v1.json) contains the review polygons, collision metadata, conditional masks and explicit approval flags. It does not become a new runtime source.

## QA and limits

The map-specific `tests/raven/map_qa_09d_hc_cb_architectural_smoke.gd` extends the existing 09B Godot fixture with per-door **AB→BA physical movement**, originally locked gates, cancellation, missing approach route failure, no handoff displacement and the existing 12px NO-GO disk proxy. **This test is added but not registered in the shared `scripts/check.sh`: that runner belongs to the integration owner.** Execute explicitly:

```sh
godot --headless --path . --script res://tests/raven/map_qa_09d_hc_cb_architectural_smoke.gd --quit-after 120
```

Tests cover technical 09B movement, **not** architectural elevations, real art-layer occlusion, full 62px-body collisions or phone performance. This change authoring environment cannot run Godot or inspect binary PNG pixels directly; no new claim of local test pass / owner visual acceptance is made. Evidence consists of reproducible image-coordinate overlays and reviewable geometry. Existing 09B tests have historical CI evidence, but do not substitute for an executed 09D test.

## Owner's gate for Agent B

**Production navigation MUST NOT be enabled by Agent B** until the owner approves (1) HC's visible structural solution or a newly authored alternative, (2) CB's wall cut, floor continuation, exact opening width and trim, then an integration owner verifies actual foreground masks, collisions, camera, reverse/blocked travel and mobile rendering. Mark `approval=DRAFT_ONLY` and `productionReady=false` until all gates genuinely pass. In particular, **a merge of this review PR is not architecture acceptance**.

Rollback: remove this 09D JSON, the two SVGs, the isolated smoke and the unique change note/shard entry. No 08B/09B/09C JSON, approved PNG, manifest, canonical graph, production gameplay or story system is touched.
