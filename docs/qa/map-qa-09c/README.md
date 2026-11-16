# MAP-QA-09C — G1 physical door & route calibration (HC and CB)

**Task:** CODE-05-02 · **Domain:** `manor-map` · **Approval:** DRAFT_ONLY, not owner-accepted.

This folder holds the visual/numeric evidence for the physical calibration of the
two first-slice crossings that Season 1 actually requires:

| Key | Door | Threshold (px) | Opening | Near foot (approach) | Far foot (entry) | Existing floor? |
|---|---|---|---|---|---|---|
| HC | `RM-DOOR-HALL-CORRIDOR` | `[824, 400]` | 48 px, normal `[0,-1]` (north) | `[824, 424]` Hall | `[824, 384]` Corridor | far yes / near no (new underpass) |
| CB | `RM-DOOR-CORRIDOR-BEDROOM` | `[528, 376]` | 48 px, normal `[-1,0]` (west) | `[552, 376]` Corridor | `[512, 376]` Bedroom | near yes / far no (new sill) |

Coordinates are source-image pixels (1672×941, origin upper-left). They are a
calibration proposal layered on the MAP-QA-09B opening blueprint, not a claim
that the painted walls already contain openings.

## Finding

Neither HC nor CB shows an unambiguous walkable doorway in the approved PNG:

- **HC** — the "upper horizontal corridor" sits behind the Hall's central stair
  landing. The proposed 48 px passage runs *under* the landing; the landing's
  elevation and underside are not derivable from the flat painting.
- **CB** — the bedroom partition shows trim/wall caps, not an exposed threshold;
  a new opening must be cut.

Both require architectural/art changes, recorded as `requiresArchitecturalChange`
in `assets/raven/map/qa/drafts/map_qa_09c_g1_door_calibration.v1.json`.

## Evidence

- `g1-door-calibration.png` — gold = opening span + threshold, green = near
  (approach) foot, blue = far (entry) foot, drawn over the unmodified PNG.
  Rebuild with `python -X utf8 docs/qa/map-qa-09c/build_evidence.py`.
- `assets/raven/map/qa/drafts/map_qa_09c_g1_door_calibration.v1.json` — the
  authoritative DRAFT_ONLY calibration record (thresholds, feet, clearances,
  art-change requirements, unresolved questions).

## Validation

`tests/raven/map_qa_09c_g1_door_calibration_smoke.gd` asserts (read-only):

- Approval boundaries (DRAFT_ONLY, no production promotion).
- Immutable PNG hash/blob/dimensions.
- Door IDs, room pairs and lock states preserved against the world map + manifest.
- Canonical `RM-NAV-*-NEAR/FAR` transition anchors still exist, room-owning unchanged.
- Threshold width 24..128 px, unit normal, feet inside image and on opposite sides.
- ≥12 px feet-proxy clearance from every 09B NO-GO polygon.
- Elevation/foreground remain `PROPOSED_FLAT_QA_ONLY` / `NOT_IMPLEMENTED`.

The test does **not** register in `scripts/check.sh` in this change (shared runner
edits are coordinated with Agent E); run it directly:

```
godot --headless --path . --script res://tests/raven/map_qa_09c_g1_door_calibration_smoke.gd --quit-after 120
```

## Rollback

Delete the calibration JSON, this folder, and the smoke test. No canonical file is
modified; the approved PNG, manifest, greybox graph, world map and 09B blueprint
remain byte-for-byte unchanged.
