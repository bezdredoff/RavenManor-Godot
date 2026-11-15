# MAP-QA-08B — Visual and narrative navigation candidate

Authority: **AI_DRAFT / DRAFT_ONLY / OWNER UNAPPROVED**, image-pixel coordinates.
Base main `5070f7349fa894b08bc7fba4a462f8a689ff5727`; prerequisites #255 and #256 merged.
This is a new independent graph, not a replacement of MAP-QA-05 or production navigation.

## Image evidence and scope

The actual local 1672×941 PNG was opened, then four overlapping native-resolution crops
were inspected: west `(160,130)-(710,780)`, Hall `(585,395)-(1085,825)`, east
`(1015,150)-(1590,755)`, corridor `(505,170)-(1070,435)`. SHA-256 is
`5e0edf97bd719fb1df95c7e9bea2f134d90adad0bc04d1771acc82a95a4d549a`, Git blob
`b50bc36cffd3d3aca7e81a0cea28bb3d0c0e9563`. The PNG is unchanged.

Visual evidence is hand-inspected **proxy geometry**, not computer-generated semantic
segmentation. `visualEvidence` records each feature's bounds, cue, confidence and clearance
limitations in the candidate JSON. Green envelopes cover selected circulation floor;
they do not claim all room floor is navigable. Furniture footprints are intentionally
conservative and independently editable. Red+green overlap excludes the furniture.

| Room | Waypoints | Routes | Image evidence / deliberate limits |
|---|---:|---:|---|
| Hall | 7 | 6 | Lower parquet, arrival, round-table south approach, west/east approaches. C-shaped stairs, inner and foreground pots, flower table excluded. No staircase traversal. |
| Corridor | 4 | 3 | Horizontal rug/parquet lane below sanitary-room wall; bedroom-side and bath-vignette stops. No wall crossing to kitchen. |
| Bedroom | 5 | 4 | Eastern rug aisle and upper free floor; bed/canopy/stool/desk excluded. No invented childhood item. |
| Library / Archive | 6 | 5 | West lane, south of armchair, north/east of desk. Bookcases, pots, globe, chair and desk avoided. Storm window access unconfirmed. |
| Kitchen | 4 | 3 | Compact west tile lane beside island. South loop rejected: chair/barrel gap is too narrow for 12px feet proxy. Hearth, counter and island excluded. |

Total **5 WALKABLE, 19 NO-GO, 26 waypoints, 21 bidirectional cell-authored routes**.
All use `origin: AI_DRAFT`. RouteDocument v1 `provisional:false` only means cells were
authored; `calibrationStatus` and document approval still forbid production promotion.
No schema or runtime engine change was necessary.

## POI and story coverage

The 19 MAP-QA-08A targets retain their IDs, room and story/hotspot references; clock and
portraits add two explicitly unresolved observations. **9 candidate floor stops**, 9
unresolved targets, 3 out-of-scope targets. See [complete keys](annotation-keys.md).
`waypointId` is the editable navigation reference. `pointPx` / `safeStopPointPx` are
inspection snapshots of actor feet, distinct from `interactionObjectPointPx`.
After manual edits resolve the waypoint position again; metadata snapshots are not a
second movement authority. `approachFromAnchorId`, incident `approachRouteIds`, confidence,
uncertainty and original narrative gate records accompany calibrated targets.

| First-episode hotspot | Result |
|---|---|
| RM-HS-001 | Hall arrival staging at QA-HALL-SPAWN; preparation-list/NPC presentation remains narrative-owned. |
| RM-HS-002 | Free rug stop east of bed, object cue on bed; restoration still happens after physical entry. |
| RM-HS-003 | Corridor stop south of the visible bathroom opening; no bathroom room graph. |
| RM-HS-004 | **UNRESOLVED**: childhood object cannot be identified reliably; bedroom desk approach exists but is not falsely labelled as the clue. |
| RM-HS-005 | Bedroom-side corridor staging; door/jam identity remains candidate. Never gated by bathroom repair. |

Later stops cover Hall return/storm, bedroom night, kitchen ledger preparation, archive
desk/album/drawer context and Lucas conversation staging. Precise NPC/prop coordinates
remain unconfirmed where absent from art. Scene gate snapshots come from
`map_narrative_routes.json`; no navigation action mutates flags or plays VN scenes.
Lucas timing remains external (after sunset). Kitchen electricity, Hall estate plan,
clock, portraits, tea chairs, archive window and door-specific story stop remain unresolved.
The painted round Hall table is a flower table; two Hall armchairs are not reliably shown.

Entry steps need elevation handling. Conservatory glazing hides floor, paths and bench.
Exterior scenery is visible, but no authoritative walkable garden room/threshold is
established. These remain out of route scope. Covered northeast room identity is unknown.

## Doors and topology contradictions

All **11 real doors remain unapproved and unconnected**. Four visual candidates have
threshold landmarks and approach metadata (Entry, Archive, Bedroom, Bath); they are not
runtime transitions. Other records stay UNRESOLVED, some with visible but unidentified
architectural landmarks. No fabricated far-side point is provided for steps/bath/hidden floor.
The drawing shows no proven floor passage Hall→Corridor or Corridor→Kitchen; the central
upper Hall is a stair landing, and the northeast covered room intervenes near kitchen.
The required logical topology is preserved as intent, not silently reinterpreted from art.
The east break is not enough evidence to identify the story-locked east double doors.

Existing Hall↔Corridor↔Bedroom handoffs remain explicitly **TEST_ONLY**, using the existing
adapter/controller fixtures. They are separate from door candidate metadata and do not
demonstrate physical threshold traversal. No real-room crossing edge is compiled.

## Iteration and clearance

1. First data pass found an intermediate bedroom cell beyond the floor envelope; the
   southeast stop was moved inward.
2. Rejected a kitchen south loop after comparing the actual island chairs/barrels and
   actor radius. Kept the smaller useful west island.
3. The 32px grid put intermediate centres into narrow margins; selected the existing
   editor-supported **16×16** grid for this candidate only. No engine rewrite.
4. Reviewed all four overlays, snapped feet to cell centres to remove endpoint doglegs,
   and moved the Hall east endpoint one cell inward. Re-ran compiler/movement checks.

The actual `OnoeSegmentMover` is driven in 0.025s steps, using the existing
`ManorNavigationGraph`, `ManorRouteSession`, `ManorRoomTransitionController` and host.
All 26 destinations are reachable within their room, including return trips. Each sampled
footpoint stays allowed and ≥12px from every authored NO-GO edge. The host keeps a 62px
sprite with existing feet pivot. This ground-plane disk is **not proof of body clearance**:
sprite animation, perspective and foreground occlusion lack calibrated depth masks.
Owner review at furniture, walls, stair tips and frames remains mandatory.

## Verification evidence

- Godot **4.7.2.stable.official.ed1daf0bf**, local native executable verified.
- `RAVEN_SKIP_DATA_CHECKS=1 bash scripts/check.sh`: **128 stages PASS**, zero script errors,
  isolated `APPDATA`; includes MAP-QA-03/05/06/07A/07B/08A/08B, MAP-EDIT-01/02/03/03A/04/04A/05.
- Unmodified full `bash scripts/check.sh` attempted: data phase stops at existing
  `test_sharded_dashboard.test_canonical_shards_and_provenance` on Windows backslash paths.
  Do not interpret this as a green full local check. Linux exact-head CI is the final gate.
- `validate_code_plan.py`, `progress_shards.py`: PASS locally. No dashboard hand edits.
- New test: identity/schema, metadata refs, route constraints, isolated room reachability,
  JSON round-trip, existing freehand converter, correct manual bedroom ownership, candidate
  editor loading, AI clear + Undo/Redo, actual physical forward/reverse traversal, pause/resume,
  cancel, overlay, Pan/Follow toggle and candidate QA scene source selection.
- Real native QA window: selected **08B visual candidate**, F3 toggled; observed Hall movement
  to table approach and explicit Bedroom island restart. Screenshots
  [Hall](runtime-hall.jpg), [Bedroom](runtime-bedroom.jpg). This is desktop evidence, not
  owner/mobile acceptance or a complete hands-on editing certification.

## Manual Godot review

1. Open **this checkout/branch** in Godot 4.7.2 (another local checkout may have the same
   project/window title). Enable Room Builder Navigation / Routes in Project Settings → Plugins.
2. Navigation / Routes → **Load 08B visual candidate**. Check 26/21, 16px grid and PNG identity.
   Original Hall and **Load project draft** still select separate regression sources.
3. Select each room before adding a waypoint. Use Zones to select/redraw vertices, drag,
   insert/remove corners, add/delete polygons; use Cells and Freehand to redraw paths.
   Review clear-AI preview, cancel it, then confirm on a disposable copy; Undo/Redo each change.
4. **Save user draft** preserves experiments. **Export project draft** writes the selected
   project file: after loading 08B it writes 08B, not MAP-QA-05. Source pilot/PNG never changes.
5. Play integrated first floor, or F6
   `scenes/raven/tests/first_floor_integrated_qa.tscn`; explicitly choose **08B visual candidate**
   or **Saved user**. Default remains the old project draft; no silent source substitution.
6. Select targets/click waypoint markers. Check Hall spawn→centre→west/east→return, Corridor
   bedroom/bath staging, Bedroom bedside/upper/south, Archive desk/drawer/return, Kitchen west
   lane. **Restart island (QA)** is a labelled test reset, not a door.
7. Check 62px Onoe feet/body, turns, furniture clearance, reverse travel, Pause/Resume,
   Cancel at segment end, middle-button Pan/Follow, zoom and F3. Return to a safe start before
   reloading a draft. Save a changed waypoint, load **Saved user**, and confirm the changed
   physical stop after reload. Preserve baseline files when exporting.
8. Separately exercise TEST_ONLY HC/CB handoffs, locked gate, gate closure mid-approach.
   No result here approves a real door, collision, portrait device, or production graph.

## Editor observations / next stage

The candidate adds one explicit load button to the existing editor and source selector.
Selected project path is tracked for export/preview to avoid overwriting the old draft.
The source buttons wrap via the existing Godot flow container. Existing editor functions
provide all geometry editing; no hidden or GDScript-only constraint was added.
Known follow-ups: dense F3 labels, the older QA target/transition rows still overflow narrow
portrait windows, and POI snapshot metadata does not auto-follow manual waypoint movement.
These are documented improvements, not reasons to replace the editor/runtime here.

MAP-QA-09 must reconcile logical topology against art, owner-confirm each threshold and
both sides, establish elevation, foreground masks, actor clearance, locks and reverse arrival.
Only afterward can MAP-GAME-01 connect an approved graph to production; GAME-LOOP-01 then
binds existing narrative/hotspot availability through the authoritative reducer/store.
No production art/navigation/story/save migration is included; rollback removes only this
candidate, selectors/test/QA artifacts. CODE-05-02 remains partial P0, owner QA pending.

Rebuild four overlays and annotation keys with `python -X utf8 docs/qa/map-qa-08b/build_overlays.py`.
The JPEG package uses the unchanged full-size original as its underlay, ~2.2 MB total for A–D.
