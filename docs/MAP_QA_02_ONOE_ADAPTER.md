# MAP-QA-02 — reusable Onoe animation and segment movement

**Stage:** isolated technical preview, not first-floor or campaign integration.  
**Domain:** manor-map. **Game:** Godot 4.7.2.  
**Authoritative navigation:** existing \`manor_navigation_graph.gd\` + \`manor_route_session.gd\`; **no new router, graph or saved progress**.

## Provenance / reuse check

The canonical UPDS native donor \`bezdredoff/UPDS-godot@3deed628efd6c22bcd1717f7c545b7d3ca865781\` has Onoe VN portrait assets, not these walking atlas/movement adapters (checked donor recursive tree, 2026-11-08). The **already committed Raven** assets are used unchanged:

- \`assets/prototypes/onoe/onoe_walk_sheet_v1.png\` (Git blob \`907a5723c2cfffa8eebce4a8961927da24fa29dd\`) — 4 down frames row 0, 4 up frames row 3, each 256×384, 7 FPS.
- \`assets/prototypes/onoe/onoe_side_walk_v2.png\` (Git blob \`2440c37e97e598c7234af6224e8553bbb77bb4bd\`) — 8 horizontal frames each 272×724, 10 FPS; left is a flip.
- Actual reusable behavior extracted from **Raven** \`scripts/raven/manor_greybox.gd::_make_actor/_start_animation\` and \`season1_map_greybox.gd::_make_onoe/_set_actor_motion\`; the two existing scenes now only call the **same** \`OnoeVisual.build_sprite_frames\` and \`play_sprite_direction\`. Hall still uses its old Tween prototype; Whole Manor still uses its old grid route/move_toward and camera. Neither old movement implementation is called by the new adapter.

**Decision:** Raven sprite behavior **extract**; Raven physical movement \`move_toward()\` **reuse**; \`RouteSession\` **reuse as-is**; independent visual-lab & segment executor **new adapter** because neither old scene provides a safe single-leg, result-driven contract. No UPDS story/content or new character art imported.

## API: instantiate, footpoint, scale, direction

Instantiate \`res://scenes/raven/tests/onoe_segment_actor.tscn\`, a \`Node2D\` with \`scripts/raven/onoe_segment_mover.gd\`. This is an **isolated reusable actor prefab**, not a playable-map scene.

\`\`\`gdscript
const ONOE_SCENE = preload("res://scenes/raven/tests/onoe_segment_actor.tscn")
var onoe = ONOE_SCENE.instantiate()
map_world_node.add_child(onoe)
onoe.position = approved_start_xy  # ONE initial spawn from approved world-plan frame
onoe.set_sprite_height(104.0)      # displayed sprite pixels; also rescales side
onoe.move_speed = 230.0            # pixels/world-plan units per second
onoe.get_sprite()                  # AnimatedSprite2D (down/up/side + flip_h)
\`\`\`

**Footpoint:** The actor's \`Node2D.position\` is **both the movement point and the feet/floor-contact pivot**. The sprite is a centered child whose bottom touches \`(0,0)\` for all clips: for 384px down/up, 724px side, scale \`displayHeight / nativeHeight\`; \`sprite.position.y = -displayHeight / 2\`. Do not directly move the sprite child or use its visual centre as a navigation anchor.

For a static direction preview: \`onoe.visual().face(Vector2.RIGHT)\` (or \`UP/LEFT/DOWN\`), then \`onoe.visual().set_idle()\`. In movement, the executor selects the clip automatically from actual displacement. \`stop\` preserves current facing but shows frame 0; left uses \`flip_h=true\`.

## Execute **only** a RouteSession-authorized segment

\`\`\`gdscript
# graph was rebuilt using the current campaign snapshot and reviewed geometry.
var session = RouteSession.new(graph)
var restored = session.restore(snapshot)
onoe.position = graph.position(restored)  # initial spawn only, NOT mid-flight
onoe.segment_completed.connect(func(anchor_id: String, feet: Vector2):
    # It is safe to call finish_segment ONLY because this physical leg finished.
    # RouteSession rechecks any door gate. Handle segment-blocked without teleport:
    # pause/reverse along explicitly validated safe geometry before any retry.
    var result = session.finish_segment(anchor_id)
    if not result.get("ok", false): return
    if result.get("status") == "continue":
        var next = session.next_segment()
        if not next.is_empty(): assert(onoe.start_segment(next))
)
session.request_hotspot("RM-HS-003")  # controller, not visual component
var first = session.next_segment()
if first.has("toAnchorId"):
    assert(onoe.start_segment(first))
\`\`\`

- Input \`start_segment({fromAnchorId:String,toAnchorId:String,fromPosition:Vector2,toPosition:Vector2}) -> bool\`. Reject missing/wrong types, invalid/degenerate points, busy actor, speed≤0, origin >\`start_tolerance\` (0.75 by default) from **actual** actor feet. **No snap, no fallback** to a previous graph anchor.
- Every rendered frame \`advance(delta)\` uses existing \`move_toward()\` on **actor.position**. This is the same method \`_process\` invokes in real Godot. No separate Tween state or auto-pathfinding. Movement speed is editable; unit/s only, host projection handles pixels.
- \`segment_started(fromId,toId)\` fires upon accepting a leg; \`segment_completed(toId,actualPosition)\` fires only after feet actually reach its exact destination and motion stops at first idle frame. The host, not the executor, calls \`session.finish_segment(toId)\` **after** signal, and only then may use \`checkpoint_event\`/save system. No checkpoint or save code in this adapter.
- New target during movement: \`session.request_hotspot(otherHotspot)\` returns queued and lets current leg finish. \`onoe.start_segment(next)\` is rejected while active; after physical completion the host acknowledges and asks Session for the next leg. This deliberately avoids old Hall's kill-Tween/replan-from-stale-anchor pitfall.
- \`session.cancel()\` means **finishCurrentSegment=true** if already moving. Let the visual leg reach its endpoint and acknowledge it; then stop. **Emergency pause**: \`onoe.pause_segment()\` freezes at exact physical XY with no arrival; \`onoe.resume_segment()\` resumes that same authorized leg, not an arbitrary new target. Do **not** call \`session.finish_segment\` while paused. If the door becomes blocked during transit, the caller must arrange a reviewed physical reverse/hold; it must **not** teleport to \`rollbackAnchorId\` even though existing Session returns that ID.
- Resuming a stopped/aborted game requires a reviewed physical restore policy; this slice **does not implement save, migration or checkpoint recovery**. Host owns its own authority and cannot use this component as a route planner.

## Projection and camera

The mover's position is **already gameplay/world-plan XY** in the host map container. The existing Whole Manor projection is:

\`\`\`gdscript
screen = viewport_center + Vector2(
  (feet.x - camera_center.x) * zoom,
  (feet.y - camera_center.y) * zoom * sin(deg_to_rad(65.0))
)
\`\`\`

If the host draws Onoe as a screen-space overlay, apply this transform **exactly once** to \`actor.position\` (or to a screen-only display holder). If the host is a world-space Node2D with Camera2D mapping, **do not** apply it again. The approved landscape first-floor PNG is already painted/perspectival, not a flat world XY texture; it must not be compressed again by sin(65°). A's unregistered source \`image-pixel\` and C's \`world-plan\` anchors have **no approved conversion** yet. Never infer geometry from the PNG or reuse greybox values as accepted positions.

## Autonomous manual Godot test

- Open \`scenes/raven/tests/onoe_movement_lab.tscn\` in Godot **4.7.2**, press **F6 (Run Current Scene)**.
- Onoe should appear on a gridded independent stage and walk right, left, up, down in turn (looping). Direction clips should change with feet, side walk should flip on left, idle frame 0 after each arrival.
- Use **arrow keys** to queue the next demonstration direction **while the current leg is still moving**; the physical actor must complete the current leg before the new direction begins, with no snap.
- Press **Space** mid-leg to pause; the footpoint must remain stationary and no completion event should occur. Press Space again to resume same leg. Scene is **NOT linked to Main Menu or Prototype Lab**.

## Tests and boundaries

\`\`\`sh
godot --headless --path . --script res://tests/raven/onoe_segment_movement_smoke.gd --quit-after 120
godot --headless --path . --script res://tests/raven/manor_navigation_graph_smoke.gd --quit-after 120
godot --headless --path . --script res://tests/raven/season1_map_smoke.gd --quit-after 120
godot --headless --path . --script res://tests/raven/prototype_lab_smoke.gd --quit-after 120
\`\`\`

The dedicated smoke checks sprites, frame counts/speeds, left flip, all four directions, first-frame idle, footpoint at 0, height scaling, pause/resume, physical completion, busy/replacement refusal, Session queued target, cancel/finish semantics, and no premature checkpoint. The existing Hall/Whole Manor tests must pass unchanged. **CI must be inspected at exact PR head**; visual/device acceptance remains owner's responsibility.

No \`project.godot\`, campaign/reducer/store/snapshot, canonical map, data graph, storyboard or geometry changes.

## Verified CI (2026-11-08)

[Godot diagnostic run #42515189603](https://github.com/bezdredoff/RavenManor-Godot/actions/runs/42515189603): new `onoe_segment_movement_smoke.gd` **PASS**; old Hall-authored navigation, Whole Manor and Prototype Lab smokes **PASS**; all required build jobs **PASS**. The final PR excludes temporary `scripts/check.sh` changes. Full first-floor movement, real map art/occlusion and interactive F6 **not** manually accepted.
