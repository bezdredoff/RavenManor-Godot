# RM-HUB-001 — completion report

## PR 1 — Raven Foundation: COMPLETE

### Added or reused

- Added Raven content catalog, stable ID facade, snapshot v1, pure reducer and Raven save facade.
- Reused the existing atomic `SaveStorage` adapter and extended its allowed-key contract with separate Raven campaign and recovery keys.
- Preserved UPDS story and Match-3 saves without schema or behavioral changes.

### Verified behavior

- First clear grants exactly 2 points once, including when a second callback has a different event ID.
- Duplicate restoration does not spend twice.
- Insufficient balance and missing prerequisites reject the transaction without changing state.
- Doors, hotspots, clues, flags, beats and last safe position normalize and survive reload.
- Invalid Raven data falls back to a fresh snapshot and is copied to a separate recovery slot.

### Affected IDs

Existing: `RM-LVL-001..003`, `RM-REST-001..002`, `RM-HS-001..005`, `RM-DOOR-HALL-CORRIDOR`, `RM-DOOR-CORRIDOR-BEDROOM`, `RM-BEAT-01-01..05`, slice room IDs.

Introduced and documented: `RM-FLAG-BEDROOM-ACCESS-CLEARED`, `RM-CLUE-01-CHILDHOOD-OBJECT`.

### Product correction

Bedroom access no longer depends on bathroom restoration or the childhood clue. The early access flag unlocks the bedroom, and `RM-REST-001` happens after entry. The old Hall→Bedroom ID remains an alias only.

## PR 2 — Manor Navigation Greybox: COMPLETE

### Added or reused

- Added an authored anchor/edge data file and reusable `AStar2D` graph adapter.
- Added Hall, Corridor and Bedroom engineering geometry, five interaction anchors, near/far bedroom doorway anchors, foreground lintel and following portrait camera.
- Uses a neutral procedural technical actor. Onoe source art remains excluded from this standalone repository pending provenance/license confirmation.

### Verified behavior

- Hall and Corridor routes are available before bedroom unlock.
- Bedroom targets are unreachable while the bedroom edge is gated.
- Unlocking `RM-DOOR-CORRIDOR-BEDROOM` creates the expected deterministic route through both doorway anchors.
- Reverse traversal works.
- Doorway access survives save/reload.
- Debug markers and active edges are visible in the greybox.
- Locked and unlocked 390×844 captures render without runtime errors.

### Known limitations

- Art is intentionally schematic.
- Mouse interaction was exercised; real touch-device verification is still outstanding.
- Camera follows the actor rather than using final authored room framing presets.
- Interruption continues from the last reached stable anchor.

## Test evidence

`check.ps1` passed after PR 1 and again after PR 2, including every pre-existing UPDS check plus:

- Raven script parsing;
- `raven_foundation_smoke.gd`;
- `manor_navigation_graph_smoke.gd`.

Visual evidence:

- `docs/evidence/rm_hub_001_greybox_locked.png`
- `docs/evidence/rm_hub_001_greybox_unlocked.png`

## Remaining milestone

PR 3 has not been started. It must connect three Raven Match-3 entries, five task hotspots, two restorations, Ada/Evelyn beats, childhood clue and first-night beat into one end-to-end `RM-VS-01` run. The existing Match-3 and VN engines remain the integration targets, not replacement candidates.
