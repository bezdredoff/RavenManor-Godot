# MAP-QA-09 — physical door evidence and room-side review

This delivery starts the physical-door stage after merged #257 and the owner's chat
confirmation that the MAP-QA-08B room movement/editor checks are OK. That confirmation
is recorded in the manor-map shard and review metadata. It does not silently approve
missing door geometry, production integration or an untested device.

## Actual finding

The immutable 1672×941 PNG does **not** provide eleven physically calibrated portals.
Enlarging the original wall strips shows why: apparent openings may be luminous trim,
wall caps or closed panels. The approved manifest already records these limitations.
The historical 08B threshold estimates were never approved; this stage explicitly
keeps them as historical observations rather than compiling them into movement.

See [eleven enlarged crops](door-contact-sheet.jpg), [full-image review map](door-evidence-map.jpg)
and [door-by-door evidence table](door-review-table.md). Original image SHA-256 remains
`5e0edf97bd719fb1df95c7e9bea2f134d90adad0bc04d1771acc82a95a4d549a`, Git blob
`b50bc36cffd3d3aca7e81a0cea28bb3d0c0e9563`.

| Physical link | Finding / required decision |
|---|---|
| Entry ↔ Hall | Entrance leaves visible; outside steps need elevation, exact ground contact and foreground. |
| Hall ↔ Archive | Bright vertical strip between wall caps; no confirmed exposed floor opening. |
| Hall ↔ Corridor | Central upper feature is stair landing. No proven ground-floor route behind it. |
| Corridor ↔ Bedroom | Illuminated partition segments, no reliable door opening. |
| Corridor ↔ Bathroom | Small panel/trim; usable corridor vignette stop, no full room traversal. |
| Corridor ↔ Kitchen | Painted rooms are not directly adjacent; covered northeast room intervenes. |
| Kitchen ↔ Conservatory | Glasshouse is outside beyond intervening room/garden; no shared sill. |
| Hall ↔ East Wing | Bright trim does not identify the story-locked double doors. Keep closed. |
| Hall ↔ Upper Floor | Stairs visible, elevation/collision not calibrated. Keep closed. |
| Kitchen ↔ Service | Panel/seam faces covered room; destination/threshold not confirmed. Keep closed. |
| Conservatory ↔ Garden | Glazing/foliage hides ground contacts and sill. |

All **11 physical doors remain UNRESOLVED**. Exactly one entrance landmark is retained;
all physical near/far feet, opening widths, collision and foreground masks remain null/
unresolved. Approved logical topology and narrative gates are unchanged. No actual
crossing, teleport, collision opening or art modification is included.

## Implemented review workflow

In `scenes/raven/tests/first_floor_integrated_qa.tscn`:

1. Select **08B visual candidate** explicitly.
2. Open **Door evidence (09)** and select any of the 11 door IDs.
3. Inspect the enlarged original PNG crop, classification, existing manifest finding
   and missing calibration requirements. Physical crossing is unavailable.
4. **QA reset side A/B + walk** explicitly resets a QA room, then uses its existing
   graph/session/controller/Onoe mover to reach an accepted 08B stop. These are nearby
   room stops, **not physical threshold contacts**. Reset is refused during movement
   or handoff; the selected route source is never silently substituted.
5. Reopen the panel to inspect the other side. Conservatory/Garden have no invented
   walkable stop. Entry has only an inside-Hall stop. Original/mock sources remain available.

The existing room picker now reflects the active room after a QA restart. Existing
MAP-QA-07B transitions remain TEST_ONLY and separate from this physical-door review.
The panel writes no files, unlocks no doors and has no approval button.

Data: `assets/raven/map/qa/drafts/map_qa_09_door_review.v1.json`.
Model: `scripts/raven/first_floor_door_review.gd`; panel:
`scripts/raven/first_floor_door_review_panel.gd`.
The v1 review document is separate from RouteDocument v1, not a replacement schema.
It pins the normalized-LF 08B text hash, image identity, all door IDs and logical room
pairs. Manual 08B project exports require explicit recalibration before reusing stale
door-review stop references. No existing route source is changed here.

## Verification and limits

- Targeted Godot 4.7.2 smoke actually traverses every available room-side stop with
  0.025s actor substeps, checks room ownership, current picker, movement/reset refusal,
  explicit source selection, all crops, JSON round-trip, unchanged art/route/manifest.
- Invalid/duplicate IDs, wrong stop rooms, stale route hash, crop overflow and attempts
  to set physical contact/approval flags fail validation. `crossing_request` always fails
  closed; this model cannot create runtime transitions.
- New smoke is registered once in `scripts/check.sh`; all earlier QA/editor smokes remain.
- Full local/runtime and exact-head CI results are recorded in the change note / PR.
- Local full `bash scripts/check.sh` attempted: existing Windows path-separator assertion
  in `test_sharded_dashboard` stops data phase. Isolated runtime suite: 129 stages PASS;
  final panel changes also rechecked with the targeted test. Linux CI is a separate gate.
- This is a **reviewable first slice of MAP-QA-09**, not completion of physical calibration.
  No physical actor crossing or door occlusion is claimed tested.
- Native desktop inspector was opened and visually checked after the embedded-layer
  iteration; [entrance](native-door-review.jpg), [Archive partition](native-archive-review.jpg).
  Full mobile/device QA remains separate.

## Required next decision

Preserve the accepted logical topology. For missing openings the owner must choose
the actual architecture: approve separately layered opening/foreground art and the
corresponding floor geometry, or explicitly specify a supported hidden/elevation route.
The nonadjacent Corridor→Kitchen and Kitchen→Conservatory relations need particular
attention. A flat coordinate line or test-only room reset cannot resolve those conflicts.
The original approved PNG must remain immutable; any future art work is a separate layer
and requires concrete placement/owner review before navigation promotion.

Only after those decisions can MAP-QA-09 calibrate real two-sided thresholds and test
continuous movement/occlusion; MAP-GAME-01 production switching remains gated.
CODE-05-02 stays partial P0; owner acceptance of 08B does not close the broader task.

Reproduce images with `python -X utf8 docs/qa/map-qa-09/build_evidence.py` (Pillow).
Base main: `20e17e189b81147f6368dec4339d543e7e384f96`.
