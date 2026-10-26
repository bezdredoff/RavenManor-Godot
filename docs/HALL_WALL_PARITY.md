# Hall wall, portal and stair parity

Status: **measured playable review geometry; not final art or collision approval** (26 October 2026).

## Implemented source of truth

`data/raven/hall_wall_plan.json` now describes the Hall as ten authored segments with five non-overlapping openings. The three perimeter crossings preserve the entry, archive and corridor map points. The two upper intents are deliberately separate short structures: `RM-DOOR-HALL-EAST-WING` remains at local `(350, 200)`, while `RM-DOOR-HALL-UPPER-FLOOR` remains a stair approach at local `(350, 170)`. The old single painted central door is not treated as evidence that these IDs are interchangeable.

Both staircase rectangles remain exact local translations of the map: left `(140, 40, 115, 195)` and right `(445, 40, 115, 195)`. Four thin balustrade review segments follow their outer and inner edges. These segments are rendered in the foreground pass so the actor can pass behind them, but they are intentionally schematic gold strokes rather than claimed final alpha art.

The original Builder example and test fixture are generated from the world map, visual contract and wall plan. The Godot importer emits split wall runs and five opening markers with `NONE_DRAFT_ONLY`; the live Hall bridge rereads and validates those nodes against all five canonical `RM-DOOR-*` points before displaying them. Any missing, duplicated or moved opening disables the imported Hall rather than changing navigation.

## Real render evidence

Godot 4.7.2 OpenGL captures were produced from the committed generated scene at [390×844](evidence/hall_wall_parity/hall_390x844.png), [412×915](evidence/hall_wall_parity/hall_412x915.png) and [430×932](evidence/hall_wall_parity/hall_430x932.png). A separate [balustrade depth capture](evidence/hall_wall_parity/hall_balustrade_depth_390x844.png) places Onoe across the left rail and demonstrates that the review rail is redrawn above the actor.

The captures confirm coordinate/render parity and also preserve the visible limitation: the experimental background still contains one central painted door and side arches at the wrong height. Gold wall/portal guides expose that mismatch; they do not disguise it or grant art approval.

## Collision decision

No production collision changed. The existing combined seating obstacle remains the default. The already available runtime-only **Кресла: 3 ТЕСТ** mode uses three measured footprints for the two chairs and table, rebuilds navigation in memory, verifies Hall→Archive, Hall→Bedroom and clock-approach routes, and restores the original obstacle on toggle or reload. Nothing is written to campaign saves.

Promotion of those footprints requires explicit visual review of the new wall art and both default/candidate route modes. Stair and wall strokes never create `StaticBody2D` or navigation blockers.

## Acceptance result and next step

- PASS: five distinct opening IDs reproduce exact world-local positions.
- PASS: two staircase bounds reproduce exact map-local rectangles.
- PASS: live and standalone Godot views consume the same generated wall nodes.
- PASS: foreground rail ordering is exercised in an actual renderer capture.
- PASS: existing routes, story gates, saves and interaction IDs remain unchanged.
- NOT APPROVED: experimental background pixels, final jamb/rail alpha masks, final wall tiles and default three-piece seating collision.

The next art task is to replace the pilot background with geometry-conditioned wall tiles or a repaint that visibly contains five separate intents, then replace the schematic rail strokes with transparent cutouts. Only after screenshot signoff should the three-piece seating collision become the default.
