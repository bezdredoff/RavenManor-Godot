# MAP-QA-04 — First-floor Hall movement manual acceptance

**Status: MANUAL_PENDING throughout.** Run Godot 4.7.2 on native desktop, open the standalone Onoe lab (scenes/raven/tests/onoe_movement_lab.tscn, F6), and — **only after Agent 1 lands** — its first-floor Hall movement scene through Prototype Lab. The approved 1672×941 PNG and seven QA feet anchors remain DRAFT_ONLY.

| ID / status | Reproducible steps | Expected |
| --- | --- | --- |
| M01 MANUAL_PENDING | Desktop F6 Onoe movement lab; move all four directions | Down/up/right sprites animate; left mirrors side; idle on arrival |
| M02 MANUAL_PENDING | In Hall pilot, click each authored hotspot/waypoint using mouse | Only authored edges used; blank art does not cause free-walk |
| M03 MANUAL_PENDING | Click same target repeatedly mid-leg, then another target | No teleport; repeat idempotent; replacement queued to next leg |
| M04 MANUAL_PENDING | Space pauses lab mid-segment; Space resumes | Physical footpoint holds; original leg resumes; one arrival |
| M05 MANUAL_PENDING | Real phone: tap each Hall waypoint/hotspot | Touch picks same image-pixel target as mouse, no double projection |
| M06 MANUAL_PENDING | 390×844, 412×915, 430×932 portrait; tablet | Image ratio preserved; zoom/pan/hotspot targeting remain usable |
| M07 MANUAL_PENDING | Overlay all seven feet XY on approved art | Character foot contact at pointPx, not sprite center |
| M08 MANUAL_PENDING | Compare avatar height near door/table/planters and zoom | No stretched sprite; pivot and avatar/image zoom remain aligned |
| M09 MANUAL_PENDING | Spawn→centre→west/east→table→return | No contact with table/planter collision proxies or stair furniture |
| M10 MANUAL_PENDING | Click both stair treads/upper landing | Unreachable: no route to either elevated flight |
| M11 MANUAL_PENDING | Reach yellow virtual Hall→Corridor marker | Clearly virtual, not a painted door; no unapproved Corridor spawn |
| M12 MANUAL_PENDING | Interrupt/requeue mid-movement; force gate change if scene supports it | No early checkpoint; explicit safe host stop/rollback on blocked segment, no silent teleport |
| M13 MANUAL_PENDING | Pan and zoom to viewport extremes | Actor recoverable on-screen; authored target remains selectable |
| M14 MANUAL_PENDING | Move in front of table/planters/banister | Document Y-layer and composite-PNG occlusion limits; no false approval |
| M15 MANUAL_PENDING | Run original Onoe lab after Agent 1 integration | Standalone movement and arrow/Space controls remain functional |

## Failure report

For each ID capture PASS/FAIL/MANUAL_PENDING, exact commit/PR SHA, Godot version, OS/device, native screen resolution/viewport size, scene, starting waypoint, destination waypoint, numbered reproduction steps, expected and actual behavior, source image-pixel foot XY, screenshot/video, and Godot console errors. If a click or gate change occurred mid-segment, record that timing. Visual/art/device approval requires owner inspection; automated green CI does not approve geometry.

## Agent 1 integration gate

Test Hall controller, QA navigation adapter, scene/Prototype Lab registration once independently merged. The existing RouteSession can return segment-blocked and a rollbackAnchorId **after** Onoe visually completes a leg: the host must explicitly reconcile that mismatch safely. A missing virtualPortal.farSideSpawnPointPx is intentional and must preclude a physical Corridor switch. This remains an integration acceptance test rather than a change to Agent 1 files.
