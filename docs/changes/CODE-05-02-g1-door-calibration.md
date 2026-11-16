# CODE-05-02 — G1 physical door & route calibration (HC and CB)

Task IDs: CODE-05-02 (G1 physical navigation calibration, partial P0 parent);
RM-GAP-006 (overlapping physical-door/route/collision review); MAP-QA-09C (bounded
calibration evidence slice). HA (Hall↔Archive) and CK (Corridor↔Kitchen) remain
later, conditional requirements and are intentionally out of scope here.

Changes: New standalone DRAFT_ONLY calibration record for the two first-slice
crossings the vertical slice actually needs — Hall↔Corridor (HC) and
Corridor↔Bedroom (CB). It proposes exact near/far feet positions in source-image
pixels, thresholds, opening widths, normals, measured NO-GO clearance and the
smallest necessary floor/wall/foreground art changes. It preserves room identity,
the `RM-DOOR-*` IDs and lock states, the canonical `RM-NAV-*-NEAR/FAR` transition
anchors, and the authored 08B/09B orthogonal routes. The approved PNG, the art
manifest, the greybox graph, the world map and the 09B blueprint remain
byte-for-byte unchanged. No production graph, story flag, save or scene is touched.

Verification: New isolated Godot 4.7.2 regression
`tests/raven/map_qa_09c_g1_door_calibration_smoke.gd` EXECUTED_PASS headlessly. It
asserts the DRAFT_ONLY approval boundary, the immutable PNG hash/blob/dimensions,
door IDs/room pairs/lock states against the world map and manifest, unchanged
canonical `RM-NAV-*` anchors, threshold width 24..128 px and unit normals, near/far
feet inside the image and on opposite sides of each threshold, ≥12 px feet-proxy
clearance from every 09B NO-GO polygon, and that elevation/foreground stay
`PROPOSED_FLAT_QA_ONLY` / `NOT_IMPLEMENTED`. A read-only Python analysis (PIL)
sampled the PNG at the HC/CB threshold and foot pixels, confirming warm/dark
wall-and-landing pixels rather than an exposed opening, and produced
`docs/qa/map-qa-09c/g1-door-calibration.png` (gold span/threshold, green near,
blue far feet). Exact-head Linux CI will be recorded in the published PR; the
test is not registered in `scripts/check.sh` here because shared runner edits are
coordinated with Agent E.

Owner QA: Neither HC nor CB is a real painted doorway; both are proposals that
require new architectural/art work. HC cuts a 48 px passage under the central
stair landing (elevation and underside unverifiable from the flat art); CB cuts a
48 px opening in the bedroom partition. The owner must accept or reshape: (1) the
HC under-landing passage vs. an alternative Hall→Corridor route, (2) the CB
threshold position, (3) final opening widths/jambs/floor backfill/foreground masks,
(4) landing elevation versus the flat QA ground-plane. No production promotion and
no auto-merge.

Status impact: Own `manor-map` shard only. CODE-05-02 stays partial P0; no P0 is
closed, no door is promoted, no geometry is marked production-ready.

## Scope and provenance

- New calibration JSON `assets/raven/map/qa/drafts/map_qa_09c_g1_door_calibration.v1.json`;
  new isolated smoke test; QA evidence `docs/qa/map-qa-09c/` (image, build script,
  README); this change record and the own progress shard.
- Base main `832657cb` (PR #266 merged). Approved PNG SHA-256
  `5e0edf97…` / Git blob `b50bc36c…` verified against the local file (1672×941,
  3,126,732 bytes).
- Coordinates are image-pixel only, on top of the AI-proposed MAP-QA-09B blueprint
  (`map_qa_09b_opening_blueprint.v1.json`); no world-plan or greybox mapping is
  invented. `manor_navigation_source.gd`, `raven_hotspot_gameplay_bridge.gd`, the
  campaign store/reducer/snapshot, production scenes and `project.godot` are
  read-only and untouched.
- UPDS reuse: not-applicable — this is Raven-specific map calibration evidence, no
  donor UI/gameplay component.
- Rollback: delete the calibration JSON, the `docs/qa/map-qa-09c/` folder and the
  smoke test. No canonical file is modified.

## Unresolved questions requiring owner approval

1. Is the HC under-landing passage acceptable, or should Hall→Corridor use a
   different route (e.g. an opening in the east Hall wall)?
2. Is `[528, 376]` the correct bedroom threshold, and should the CB opening face
   west (into the bedroom south wall) as proposed?
3. What is the landing elevation relative to the Hall floor, and how must the
   foreground/occlusion be authored for an actor passing beneath it?
4. Confirm final opening widths (48 px proposed) and jamb/trim/floor-backfill art.
