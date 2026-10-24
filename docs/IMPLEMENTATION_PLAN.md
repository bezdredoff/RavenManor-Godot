# RM-HUB-001 — integrated Godot greybox plan

The repository now contains the accepted PR 1 foundation, PR 2 navigation greybox and deployed Prototype Lab. The 70-requirement audit (12 implemented, 30 partial, 6 placeholder, 21 missing, 1 unknown; 0/13 steps E2E) is a historical baseline from `UPDS-godot`, not a current rescore. See `STATUS.md` and `NEXT_PLAN.md`.

## PR 1: Raven foundation — implemented, acceptance passed
Create Raven ID catalogs, independent campaign snapshot and save namespace, resource wallet, first-clear reward tracking, restorations, door/hotspot/story flags, idempotent command/reducer layer, validation and recovery. Import only necessary proven UPDS components. Tests must cover duplicate callbacks, insufficient currency, wrong prerequisites and save/reload.

## PR 2: navigable hall/corridor/bedroom — implemented, acceptance passed
Build placeholder `RM-ROOM-HALL`, `RM-ROOM-CORRIDOR`, `RM-ROOM-BEDROOM`, the `RM-DOOR-CORRIDOR-BEDROOM` portal and foreground occlusion. Hotspot-driven authored navigation graph (not tap-anywhere), camera follow/focus, obstacle-safe routing and debug overlay. Bedroom accessibility must not depend on bathroom. Test transitions, collision/occlusion and portrait touch.

## PR 3: integrated `RM-VS-01` — not started
Wire Raven levels into Match-3 (2/2/2 first-clear rewards), bedroom preparation (-2), bathroom-vignette specialist repair (-4), five task hotspots, childhood clue, Ada before/after dialogue, first-night beat and persisted progression. Update old gates without changing IDs. Automated E2E and manual portrait checks on baseline 390×844 plus narrow/tall variants.

## Acceptance
Run tests and report actual commands/evidence; 13/13 updated slice steps pass end-to-end, callbacks/reloads idempotent, no regressions in imported shared systems. Update docs to show how to add a room, door, authored route, hotspot, level reward, restoration and VN beat. No mass art, no full season content or toolkit publication in this milestone.
