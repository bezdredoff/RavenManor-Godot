# GFX-07-01 — Approved Evelyn production walker integration

**Domain:** chibi-animation · **Priority:** P0 · **Base:** `0d1886b0d01491047dbd900b260757623c6ef9bc` (main after merged #269 and #274).

## Owner decision and change

Owner explicitly approved the corrected **merged #274** Evelyn design and animation after personally reviewing its Godot preview (2026-11-17). This is visual approval, **not** physical-phone, full gameplay, or occlusion acceptance. Approved atlas pixels and the native scene previews are not redesigned.

- Add `scenes/raven/actors/evelyn_walker.tscn`: stable reusable scene bound to the **existing** #274 `evelyn_actor.gd` / `evelyn_visual.gd` / atlas / `frames.json`.
- `manor_gameplay_integration_harness.gd` now instantiates approved Evelyn instead of placeholder Onoe. Existing `Mover` type, graph, room transition controller, source fail-closed validation, event names, position, current speed (160), height (62), physical endpoint arrivals and save/checkpoint proposals remain unchanged. The harness disables the inherited mover's automatic `_process` so the game caller's explicit `harness.advance(delta)` is the only step: no double movement.
- Add separate `evelyn_chibi_multi_room_preview.tscn` which inherits the historic multi-room QA host and overrides only its child actor script. Existing `$Onoe` node path stays intact there for API compatibility; original Onoe scene/test retains its regression baseline. This extra scene remains TEST_ONLY.
- Record `ownerApproved=true` and dated approval evidence in the **generator** `measure_frames.py`; regenerate matching `frames.json`. Keep `productionReplacementAllowed=false`, `productionIntegrationVerified=false`, `deviceVerified=false` and `foregroundOcclusionVerified=false`. Atlas and source SHA-256 are unchanged.
- Update preview expectation, release notes and `chibi-animation.json` (owning shard only); register a new gameplay-host smoke in shell and Windows runners.

## Verification / release state

New focused smoke `tests/raven/gfx_07_01_evelyn_gameplay_host_smoke.gd` exercises the **real reusable gameplay host**, not only F6: source-unavailable fail-closed, Evelyn identity, QA authored hotspot, rejection of free taps and invalid starts, pause/resume, cancellation without snap, phase after physical travel, reduced-motion idle pose with continued travel, re-instantiated host, four direction feet contacts, and TEST_ONLY Hall → Corridor → Bedroom → Corridor → Hall transitions. The original Onoe movement suite and #274 preview/bake suites are preserved. The wider MAP-GAME-01A smoke already exercises the production-approved **synthetic fixture** and unchanged source contract; synthetic approval is not proof that canonical production geometry is approved.

**Run on exact PR head** (execution not assumed): `godot --headless --editor --path . --quit`, `godot --headless --path . --script res://tests/raven/gfx_07_01_evelyn_gameplay_host_smoke.gd --quit-after 300`, `godot --headless --path . --script res://tests/raven/map_game_01a_navigation_source_smoke.gd --quit-after 300`, `godot --headless --path . --script res://tests/raven/onoe_segment_movement_smoke.gd --quit-after 120`, `godot --headless --path . --script res://assets/raven/chibi/evelyn/g1_candidate/repair_v1/preview_smoke.gd --quit-after 240`, `python3 assets/raven/chibi/evelyn/g1_candidate/repair_v1/measure_frames.py --check`, and `godot --headless --path . --script res://assets/raven/chibi/evelyn/g1_candidate/repair_v1/bake_atlas.gd --quit-after 300 -- --check`; `bash scripts/check.sh` and all required CI jobs.

**Owner visual QA:** APPROVED (only current #274 design/motion). **Production PR:** pending review/merge and exact-head CI. **Normal New Game:** NOT YET; `main_menu.gd` launches `vertical_slice.gd`, and Agent B owns menu → manor, story/Match-3/save orchestration. **Device and foreground:** NOT_RUN; HC/CB layer and door-sill / actual phone FPS/readability are not certified. No save schema migration or story ID changes.

## UPDS-first reuse audit and boundary

#274 pinned `bezdredoff/UPDS-godot@3deed628efd6c22bcd1717f7c545b7d3ca865781`: no donor directional walker. **Reuse as adapter:** Raven `scripts/raven/onoe_visual.gd` blob `b85fac3b7658de2224f39225a72be921535bc793` and `scripts/raven/onoe_segment_mover.gd` blob `5c7a43ea6b99c4ad6681ca82303b7ac0422ee222`. No second movement/controller/graph, new art, or frame-rate clock.

Explicit untouched boundaries: `main_menu.gd`, `vertical_slice.gd`, reducer/store/snapshot, navigation source, canonical geometry, approved art pixels and historical Onoe tests. Authoritative status comes solely from chibi-animation shard; dashboard is generated.

## Rollback

Revert this bounded PR to restore the old gameplay-harness Onoe default and prior preview flags. Historic `scenes/raven/tests/onoe_segment_actor.tscn` and `tests/raven/onoe_segment_movement_smoke.gd` remain available before/after. Preserve separate owner visual approval if gameplay wiring must be rolled back. Never auto-merge.
