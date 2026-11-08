# CODE-05-02 — authored anchor navigation session and fixture geometry adapter

Task IDs: CODE-05-02 (primary); RM-GAP-001 / RM-GAP-006 related, not closed.
Changes: Map-only AStar2D anchor queries, route session, preview coordinate adapter and navigation regression tests.
Verification: Local Godot NOT_RUN; exact-head PR #238 CI initially failed on evidence-field formatting and is being corrected in this branch; full functional CI required.
Owner QA: PENDING — Hall art/geometry, door and stairs, physical collisions, occlusion, 65-degree projection and device playthrough.
Status impact: CODE-05-02 remains P0 / partial / PR_review for #238; no acceptance or closed related GAP.

**Task IDs:** CODE-05-02 (P0); related RM-GAP-001 / RM-GAP-006 are **not** closed.
**Baseline:** `bezdredoff/RavenManor-Godot@4c4145a935419b5cfaa69e8e1bde90a71717ed7a`. Predecessor #212 merged; zero open PRs at audit start.
**Domain:** `manor-map`. Reviewed source: `manor_navigation_graph.gd`, `manor_greybox.gd`, `season1_map_greybox.gd`, both map JSONs, snapshot/reducer/store, map and navigation tests, data contracts.
**UPDS reuse:** *not applicable* to Raven-specific authored hotspot navigation; reuse the existing Raven `AStar2D` graph instead of creating an alternative controller or copying an UPDS player session.

## Navigation audit
- Canonical **engineering greybox** `manor_greybox_graph.json` has 13 anchors and 12 edges. Hall spawn -> Corridor -> Bedroom is connected when two known door gates are open. In a fresh snapshot `RM-DOOR-HALL-CORRIDOR` is unlocked, `RM-DOOR-CORRIDOR-BEDROOM` is locked. No bathroom restoration gate exists on this route. `RM-HS-005` is the corridor-side bedroom-access interaction; `RM-HS-002` is the bedroom restoration interaction *after entry*.
- Six hotspot anchor mappings exist in the narrow greybox graph: `RM-HS-001`, `RM-HS-002`, `RM-HS-003`, `RM-HS-004`, `RM-HS-005`, `RM-HS-TEA-TABLE`. Archive, kitchen, bathroom, east wing, upper floor and garden are **not** represented as walkable destinations here, even if `season1_world_map.json` has provisional world rooms/doors.
- `manor_greybox.gd` uses `AStar2D` and one Tween per full route, but cancelling while a segment is in flight leaves the actor between two committed anchors. Its route replacement can then draw the next leg through a wall; the scene must change in a separate integration-owned patch.
- `season1_map_greybox.gd` uses a separate `AStarGrid2D`, world-plane pilot geometry, provisional wall/prop collision, gated doors and foreground draw order. It selects hotspots/doors (no intentionally free point destination), but it is not certified to consume authored anchors; wall/stair collision and 65-degree render parity remain pending.
- `RavenSnapshot` persists `lastRoomId` and string `lastSafeAnchorId`; reducer accepts `position_checkpoint` room ID from known rooms but does not validate anchor existence. Existing saves may contain historical strings such as `bedroom-entry-safe`, so the graph needs fail-safe restoration without save migration. Doors persist through `unlockedDoors`; `door_unlock`, `hotspot_state`, `position_checkpoint` remain reducer-owned. VN and Match-3 transitions remain single-writer integrations.

## Changes
- `manor_navigation_graph.gd`: AStar2D retained; query-only `route_to_hotspot`, direct `segment_available`, known anchor/door gate checks, deterministic `safe_checkpoint_anchor` and a validated unchanged-schema `checkpoint_event` builder. Unreachable, unknown and blocked IDs fail closed.
- `manor_route_session.gd`: map-specific, **not** an alternative gameplay controller. Emits only the next authored segment; requires explicit arrival acknowledgment. Repeated taps are idempotent. A replacement target while moving is queued, not immediately tweened. A cancel must finish the currently in-flight segment before stopping at a verified anchor. Movement, animation, collision and saving remain the host's responsibility. A changed gate is re-evaluated before every segment.
- `manor_navigation_geometry_adapter.gd`: preview-only candidate overlay of anchor XY positions with strict room/ID validation and immutable edge/gate topology.
- Extend `tests/raven/manor_navigation_graph_smoke.gd` (already executed by `scripts/check.sh`) with target, door, restoration, interruption, checkpoint/save, unknown ID and coordinate overlay negative fixtures.

## Geometry adapter contract (for Agent A / Agent B)
```json
{
  "schemaVersion": 1,
  "coordinateSpace": "world-plan",
  "productionReady": false,
  "anchors": [
    {"id": "RM-NAV-HALL-SPAWN", "roomId": "RM-ROOM-HALL", "position": [410.0, 315.0]}
  ]
}
```

- XY is **unprojected world-plane**, not pixels after 65°/0.74× projection. Source anchors are identified by stable `RM-NAV-*` IDs and must retain their existing `RM-ROOM-*` ownership.
- Partial candidate sets permitted; any unspecified anchor keeps its greybox position. Duplicate or unknown anchors, room mismatches, non-finite coordinates and `productionReady:true` are rejected. Only `anchors[*].position` is overlaid; all edges, portal gates, hotspot IDs, checkpoint/save fields, world dimensions and other canonical geometry are untouched.
- Result provenance is stamped `candidate-preview`, `roomArtCalibration:pending`, `productionReady:false`. The adapter **does not** approve physics, art, layer order or source measurements. Agent B can transform its local room positions into world-plan XY **after** coordinate origin/pivot review, while Agent A supplies calibrated anchors and occlusion/collision evidence for cross-checking.
- Before promotion, integrator independently verifies world-map 65° transform, exact Hall door positions, room origin, foot pivots, staircase footprint, chair/table separation, near/far-wall obstruction, Y-sort, walkable segments, masks and room boundaries.

## Integration patch plan — reserved for integration owner
1. Validate Agent A art/coordinate manifest and Agent B importer preview against approved Hall layout, five planned portal IDs, room origins, the authoritative `season1_world_map.json` and stable `RM-*` identifiers. **Do not** copy sample `manor_greybox_graph.json` XY directly into final scene; Hall sample geometry has a different world origin.
2. Explicitly choose a single movement authority in the final scene: hosted authored AStar2D anchor session, not an arbitrary point-to-point Grid path. Preserve the season1 pilot grid only as a **collision diagnostic**, or integrate it as a read-only corridor clearance validator without permitting new tap-to-move commands. Never silently switch the current pilot's navigation behavior.
3. On hotspot/door selection, query reachable target. Drive one segment via Tween/velocity, then invoke `finish_segment(toAnchorId)` only after arrival. A replacement/cancel during a segment must finish it safely before issuing the next segment. When door accessibility changes, rebuild graph from the Raven snapshot and call `next_segment()` to recheck gates; **never** physically cross a newly blocked portal.
4. Only confirmed `kind:safe` anchors may produce `position_checkpoint` events. Submit those to the existing reducer/store after arrival; on resume load snapshot, rebuild graph, call `restore`, then place feet at returned anchor. Do not persist tween progress or introduce a new campaign save.
5. Integrate tested collision footprints, approved doorway and wall openings, staircase and chair/table occlusion, Y-sort and foreground masks in the single shared game scene under integration ownership; align room transitions with the VN/Match-3 call sites and previously unlocked door visuals.
6. Run exact-head Godot checks, Hall->Corridor->Bedroom playthrough, restore without bathroom repair, door lock/unlock/resume, repeat input/cancel on mobile 390×844/412×915/430×932 and tablet. Require human art/geometry/device approval before `productionReady:true`.

## Verification
- **Local Godot:** NOT_RUN in ChatGPT connector environment (Godot binary unavailable; repository network clone blocked). Reading test code is not counted as execution.
- **CI:** Exact-head Actions result to be added/checked after PR opens. Existing `scripts/check.sh` includes `manor_navigation_graph_smoke.gd` and `season1_map_smoke.gd`; the latter must not regress.
- **Human QA:** PENDING for physical collisions, actors/masks, 65° Hall/door seams, room thresholds, phone/tablet, imported art and story-flow transitions.

**Status impact:** `CODE-05-02` remains `P0 / partial / PR_review` while PR open. `RM-GAP-001/006` remain open; no geometry or owner acceptance implied. Only `progress/manor-map.json` touched. No `project.godot`, canonical map, core save/reducer, VN, Match-3, scripts/check.sh or other domain changes.

## 2026-11-08 — A/B contract reconciliation and mid-route gate hardening

- Rechecked baseline `main@4c4145a935419b5cfaa69e8e1bde90a71717ed7a`, C PR #238 and current A #239 (`a7ef2257`) / B #240 (`8ca6b957`). Previous C head `9bb65623` passed Actions run 42497556598. A's 13 IDs agree with C, as do A/B room (8) and door (11) identity lists; A still has **0 calibrated world-plan navigation anchor positions** and unresolved pixel registration. B's `RM-NAV-HALL-CHECK` fixture is not a stable gameplay anchor.
- Cross-agent comments recorded on PR [#239](https://github.com/bezdredoff/RavenManor-Godot/pull/239#issuecomment-6724324582) and [#240](https://github.com/bezdredoff/RavenManor-Godot/pull/240#issuecomment-6724324900); these are **proposed consumer requirements, not owner-approved geometry**.
- `manor_navigation_geometry_adapter.gd` adds two read-only producer guards: Agent A `audit_art_reference` (IDs/room/door pair parity only, never converting `referenceGreyboxPoint` into navigation coordinates), and Agent B `from_builder_draft` (exact nested v2 shape, worldRect identity, 8 room/11 door parity, complete 13 canonical anchors with correct room, finite in-room world-plan XY, no image/projected coordinate fallback).
- `manor_route_session.gd` refuses `finish_segment` if the direct edge was disabled since dispatch; returns `segment-blocked` and previous confirmed anchor for host rollback. No movement controller or reducer schema was changed.
- Synthetic isolated navigation smoke fixtures cover full B overlay, A art-reference audit, invalid/missing/unknown/duplicate IDs, wrong doors/room pairs, invalid numeric/room/world frames, no bathroom gate, restored saves and mid-segment door gate closure. A/B PR files are **not imported by CI** while those PRs remain unmerged.
- New `docs/architecture/MANOR_NAVIGATION_INTEGRATION_CONTRACT_RU.md` supplies exact host API calls, final Godot scene patch plan, coordinate-space authority and human/device QA gates.

**Verification for this follow-up:** new head CI **PENDING** at commit time; previous exact-head CI on `9bb65623` passed, but that does **not** prove this follow-up. Local Godot **NOT_RUN**; require new Actions godot-runtime and aggregate build PASS. No production art/collision/occlusion, physical movement or device QA accepted.
**Owner QA:** PENDING. **Status impact:** `CODE-05-02` P0 partial/PR_review, `RM-GAP-001/006` remain open, no integration approval.
