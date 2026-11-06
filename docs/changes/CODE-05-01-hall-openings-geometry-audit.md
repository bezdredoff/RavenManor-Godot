# CODE-05-01 — Hall geometry & import opening parity (2026-11-06)

**Task IDs:** CODE-05-01 (room-builder, P0). Read-only integration dependencies: CODE-05-02 and RM-GAP-001/006 (manor-map).  
**Baseline:** `main@ff8760946da7bc3b0250eac1dbaad37d8b832abb`; zero open PRs on initial check; main workflow run 42256204532 succeeded.  
**Authority separation:** `examples/room_builder_hall_original.json` is a reproducible PROPOSED Builder fixture; `scenes/raven/generated/RM_ROOM_HALL_GamePreview.tscn` is DRAFT_ONLY. The live Whole Manor Map is a separate runtime. No geometry promotion or state changes.

## Source/coordinate reconciliation

- Provisional whole-world Hall = `(x=500, y=150, w=700, h=690)` from `data/raven/season1_world_map.json`. A Builder local point `(u,v)` projects to world `(u+500, v+150)` and screen draft `(u, v*sin(65°))`; upright sprites use bottom-centre foot projection, full-height art, and a 0.74× preview camera. No horizontal mirror.
- `examples/room_builder_hall_original.json` and the test fixture map the original seven pilot sprites, five doors, ten wall segments, five opening sockets, two stair footprints and six guide obstacles into those coordinates. The test character is excluded from import. The imported `ReferenceGeometry` rectangles and `Marker2D` anchors are NOT physics/navigation.
- `data/raven/manor_greybox_graph.json` is the separately authored first-slice AStar2D route graph; its `(400,300)` Hall spawn and `(400,440)` near-corridor anchor are greybox-local and must NOT be substituted for the world-map coordinates. `season1_world_map.json` and live map navigation are not replaced by Builder geometry.

Coordinates in the table are Builder local (room top-left); world coordinates add (500,150). `px` denotes provisional map/design units, NOT independently approved metres. `painted` measurements below are unapproved estimates recorded in `hall_render_calibration.json`.

| Object | Draft local rect/anchor (px) | Current import / map reference | Expected contract | Audit result |
|---|---|---|---|---|
| Room shell | `(0,0,700,690)` | Source `(500,150,700,690)`, 65° projected preview | No stretch/mirror; game map remains authoritative | **PASS — numerical**, owner architecture approval pending |
| Entry portal | `(350,690)`, 110-wide socket | Exact world `(850,840)`; painted `(850,833)` | Open threshold, intact `RM-DOOR-ENTRY-HALL` | **PARTIAL**: paint offset ~7px; mask/door state still owner QA |
| Archive/library portal | `(0,400)`, 110-wide arch | Exact world `(500,550)`; painted `(527,343)` | Anchor at correct wall seam, unobstructed approach | **FAIL — visual parity**, painted offset (+27,-207) world px |
| Residential corridor portal | `(700,435)`, 110-wide arch | Exact world `(1200,585)`; painted `(1173,343)` | Hall→Corridor→Bedroom independent of Bathroom | **FAIL — visual parity**, painted offset (-27,-242) world px |
| East wing double doors | `(350,200)`, 110-wide | Exact world `(850,350)`; painted `(850,343)` | Double door *under* landing, locked S1 | **PARTIAL**: ID/intent correct; shared central painted door inadequate |
| Upper-floor stair approach | `(350,170)`, 140-wide | Exact world `(850,320)`; same painted central door `(850,343)` | Separate blocked stair approach, not second hinged door | **PARTIAL**: marker distinct; architectural depiction pending |
| Bifurcated staircase — left | `(140,40,115,195)` | Existing map `(640,190,115,195)`; painted approx local `(143,0,109,234)` | Physical flights/landing align independently from artwork | **PARTIAL**: rect exact; visible bounds/rail alpha differ |
| Bifurcated staircase — right | `(445,40,115,195)` | Existing map `(945,190,115,195)`; painted approx local `(447,0,109,234)` | Symmetry, safe route, occlusion | **PARTIAL**: rect exact; visible bounds/rail alpha differ |
| Clock | `(75,310,60,90)` | `RM-ASSET-HALL-CLOCK`; world `(575,460,60,90)` | Inspect foot/approach separate from stairs/library door | **PARTIAL**: visual rect exact, contact pivot/approach requires review |
| Seat cluster physical guide | `(140,410,160,125)` | Existing single world collider `(640,560,160,125)` | Default collider retained; separate seats only after route QA | **PASS — unchanged**; final footprint approval pending |
| Left / right chair cutouts | `(142,422,58,96)` / `(241,422,58,96)` | Two independent PNG nodes; contact candidates local `(142,487,58,31)` / `(241,487,58,31)` | Separate visual items, no split collisions by import | **PARTIAL**: art pivots/3-piece candidate not accepted |
| Round table | `(198,463,46,46)` | Independent PNG; contact candidate local `(198,494,46,15)` | Table remains between chairs; nav clearance | **PARTIAL**: pivot/contact & route QA pending |
| Burgundy runner | `(285,285,130,396)` | Floor-projected PNG (`sin65°` Y) | Visual-only, does not block central route | **PASS — technical preview**, placement/style owner QA pending |
| Entry console | `(610,570,70,65)` | World `(1110,720,70,65)` | No obstruction to Entry approach | **PARTIAL**: source parity, collision/clearance not accepted |
| Ancestor gallery | `(25,70,65,165)` | World `(525,220,65,165)` | Interactive only if authored hotspot; no accidental state mutations | **PARTIAL**: visual placement, final portrait count/occlusion pending |
| Review balustrades | x=140/255/445/560; y=40..235 | Four schematic strokes in draft wall plan | Proper alpha foreground occlusion, foot-based order | **PARTIAL**: ordering smoke/art guides exist; real masks absent |
| Temporary actor/anchors | Builder spawn `(350,620)`; five local door anchors | Excluded Onoe, informational Godot markers | No actor spawn import, no route/door save mutations | **PASS — isolation**; runtime alignment manual QA pending |
| Window and glass wall openings | Synthetic test: 80-wide at 0.5 along 300-long wall | Builder `solidWallRuns` preserves full wall; Python importer previously removed it | Non-traversable opening must keep solid wall; still export `Marker2D` | **FAIL→FIXED in this PR**, regression added |

## One deliberately scoped correction

**Changes:** In `scripts/raven/tools/import_room_builder_game.py`, only traverse `door`, `double_door`, `arch`, and `stair` when cutting visual wall runs. `window` / `glass` still retain opening metadata/markers, but the wall is solid. This matches `tools/room-builder/wall-tools.mjs:isPortal/solidWallRuns`. No Builder schema, canonical scene or collision modifications. Existing five Hall openings are all portals, so the committed Hall fixture should remain byte-identical.

**Verification:** New `test_windows_and_glass_keep_solid_wall_in_draft_preview` in `scripts/raven/tools/test_room_builder_game_import.py` checks a real door (2 runs), window (1 run), glass (1 run), all three markers and no `StaticBody2D`. Existing importer, node/browser and Godot smoke are expected to run in GitHub CI. **Local EXECUTED status: NOT_RUN** (the environment cannot clone GitHub); record actual PR head/check link after CI rather than inventing test output. Baseline main CI (not this change): [run 42256204532](https://github.com/bezdredoff/RavenManor-Godot/actions/runs/42256204532) = success.

**Owner QA:** Pending: Android tablet/S-Pen/touch, portrait 390×844 / 412×915 / 430×932 with `Импорт` + `Габариты`; five distinct visible portal intents, two stair runs, archive/corridor jambs, foreground rail/actor overlap and default vs three-piece seating test routes. Author approval of physical Hall geometry remains explicitly pending.

**Status impact:** `CODE-05-01` remains P0/partial; PR review is not a merge or game-map acceptance. `room-builder` progress shard only. No `manor-map` shard update. Follow-on `CODE-05-02`, `RM-GAP-001/006` require separate owner-approved integration branch/PR.

## Unresolved technical questions (no silent fixes)

1. Importer opening marker at `offset=0` or `1` uses the raw position, while the visual wall-gap interval clamps a door to half its width inside the wall. This could place the marker off-centre from its visible opening; document and separately test/fix, do not move approved Hall anchors in this PR (all five current Hall offsets are central enough not to clamp).
2. An imported visual `ReferenceGeometry` rectangle is not a collision polygon. The world map retains its existing six obstacle footprints and seat-group option until independent route/threshold and foot-pivot QA.
3. Foreground strokes are not cutout alpha masks. Painted right/left arches remain >200 world px away from canonical seams. No CSS/image offset or nav movement can count as approval.
4. `manor_greybox_graph.json` and the whole-season world graph describe distinct technical layouts; a formal authored-anchor coordinate reconciliation is an integration-owner task, not an importer side effect.

**Rollback:** revert the single importer predicate and its test; only DRAFT_ONLY visual scenes with window/glass are affected. No save migration, game schema, shader, map/reducer or player progression changes.
