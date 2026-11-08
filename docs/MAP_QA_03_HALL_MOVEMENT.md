# MAP-QA-03 — First-floor Hall playable Onoe movement pilot

**Scope:** QA-only playable first-floor PNG; `CODE-05-02` partial / `MAP-QA-03` technical slice; owning domain `manor-map`. **Approval:** image art approved; its collision polygons, 7 footpoints and virtual portal are **DRAFT_ONLY**, not accepted world-plan coordinates.

## Open in Godot 4.7.2

1. Checkout PR branch and open `project.godot` with Godot 4.7.2; allow asset import to finish.
2. **F6**: open `res://scenes/raven/tests/first_floor_hall_movement_pilot.tscn` and Run Current Scene. Alternatively run the main menu → Prototype Lab → **9 · MAP-QA-03 · Hall movement on approved first-floor image**.
3. On desktop, **left click the small white waypoint circles**. Drag with left/right mouse to pan; wheel or UI `−`/`+` to zoom. On mobile, **tap circles**, drag to pan, and use `−`/`+` to zoom.
4. Click `QA-HALL-WEST`, then while Onoe is moving click `QA-HALL-EAST`. The current leg must finish physically before the route changes at its next confirmed anchor. Watch for no snapping.
5. Use the **Pause/Resume** button or Space mid-leg: footpoint remains exactly in place; the same leg resumes without an arrival during pause.
6. Tap the pink `QA-HALL-PORTAL-APPROACH` circle. Onoe should follow authored Hall edges and stop with feet at `[959,746]`. UI must say **VIRTUAL QA PORTAL: Corridor request deferred**, with no teleport, save or unlocked door.
7. Toggle **QA** (F3) to show seven IDs, seven authored edges, the green walkable draft polygon, five red no-go draft polygons, and the actor's physical foot-contact crosshair. Toggle off to see the approved PNG without overlay.
8. Review portrait viewports **390×844, 412×915, 430×932** and a tablet. Inspect foot-contact, furniture/stair overlap, portrait cropping, tap radius, avatar size and zoom readability. These are **manual/owner acceptance gates**, not asserted as device-tested.

## Architecture / coordinates

- Exact source: `a_detailed_top_down_isometric_game_map_illustratio.png` (1672×941; sha256 `5e0edf97bd719fb1df95c7e9bea2f134d90adad0bc04d1771acc82a95a4d549a`).
- QA-only source: `assets/raven/map/qa/first_floor_hall_pilot.v1.json`; **seven image-pixel footpoints only**. The runtime rejects schema/source/portal and geometry deviations; validates raw image SHA when its bytes are present (exported PCK may supply only imported texture), always checks imported image size.
- Adapter `scripts/raven/first_floor_hall_qa_graph.gd` builds an ephemeral seven-anchor graph using existing `manor_navigation_graph.gd`. Each waypoint maps to a QA-only hotspot ID `QA-HS:<waypoint-id>`, except portal approach mapped to `QA-PORTAL-HALL-CORRIDOR`. `manor_route_session.gd` owns target queue and confirmed anchors. `onoe_segment_mover.gd` owns the only physical move loop and Onoe's up/down/side/idle animation.
- RouteSession's contract: `request_hotspot` → `next_segment` → actor `start_segment` → physical `segment_completed` → `finish_segment` → repeat. Never acknowledge a segment based on elapsed Tween time, mouse position or UI target alone.
- Root `Node2D.position` of Onoe is physical feet in image pixels. Camera pan/zoom is a uniform screen presentation transform; **no second 65° projection**, no conversion to `season1_world_map.json` or overwrite of 13 canonical anchors.
- Virtual portal emits `portal_transition_requested("QA-PORTAL-HALL-CORRIDOR", "RM-ROOM-CORRIDOR")` **on physical arrival only**. Far-side spawn remains `null`; this test intentionally does not change rooms, saved checkpoints, door gates or gameplay flags.
- The new scene has **no campaign store/reducer/snapshot dependencies**; main menu and campaign flow remain untouched. The lab entry is registered only in `prototype_launcher.gd`.
- Accepted first-floor image bytes, manifest, canonical geometry, Room Builder schema and artwork remain unchanged.

## Automated checks

```sh
python3 -m unittest assets.raven.map.tools.test_map_qa_01_hall_pilot -v
godot --headless --editor --path . --import
godot --headless --path . --script res://tests/raven/map_qa_01_hall_smoke.gd --quit-after 120
godot --headless --path . --script res://tests/raven/onoe_segment_movement_smoke.gd --quit-after 120
godot --headless --path . --script res://tests/raven/map_qa_03_hall_movement_smoke.gd --quit-after 120
godot --headless --path . --script res://tests/raven/manor_navigation_graph_smoke.gd --quit-after 120
godot --headless --path . --script res://tests/raven/prototype_lab_smoke.gd --quit-after 120
bash scripts/check.sh
```

The integration branch explicitly adds the MAP-QA-01/02/03 smoke invocations to `scripts/check.sh` so the existing Godot CI job executes them on the exact head; earlier MAP-QA-01/02 tests existed but were not retained as permanent CI checks.

## Known limitations / follow-up

- All seven footpoints and no-go/walkable polygons are approximate; pixel-accurate clearance, collision, furniture occlusion, stairs and character display scale require manual owner review.
- This graph intentionally has no arbitrary walkable-area pathfinding or physical collision response: **only authored edges** can be traversed. No automatic obstacle avoidance.
- No real Hall→Corridor door location or Corridor-side spawn has been identified. Test is **successful** when the approach emits the safe diagnostic, not when an invented transition executes.
- No persistent location or movement checkpoint events; pause state lasts only while this QA scene runs.
- Approval of actual Hall-to-Corridor geometry and registration of the 13 canonical RM-NAV anchors in image/world-plan coordinates is separate, follow-up `CODE-05-02` / `RM-GAP-006` owner work.
- Screenshots and native touch QA must be performed on actual supported render/device setups; headless CI does not provide visual acceptance.

Rollback: remove the QA graph adapter/controller/scene/smoke, lab card, three CI test callsites and these QA docs/status evidence. Canonical content remains unaffected.
