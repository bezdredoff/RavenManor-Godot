# RM-PIPE-003 — Imported Hall in the live Godot world

Status: **DRAFT_ONLY visual integration**, not approved art, physics, navigation or final staging (26 October 2026).

## What the live mode actually does

The 'Whole Manor Map' entry 5 now loads the **actual committed imported scene** at `scenes/raven/generated/RM_ROOM_HALL_GamePreview.tscn`, through `scripts/raven/hall_import_bridge.gd`.
The bridge extracts its PNG textures, world-local rectangles, floor/upright modes and foot contact depths; it never instantiates the imported camera, actor, guide colliders or navigation into the active game.
The map draws these cutouts using its own 65-degree projection and existing character occlusion. It deliberately suppresses the old Hall pilot draw pass and six world-map prop render rectangles.

Default art mode: **Импорт**. The debug selector cycles **Импорт → AI1 → AI2 → ПЛАН → SVG → Импорт**. AI1 is retained for visual comparison, never composited on the same imported layer.

## Spatial parity of original door and obstacle anchors

| Element | Existing world-space source | Imported Hall check |
|---|---|---|
| Hall bounds | (500, 150, 700, 690) | exact local origin and size |
| Entry door | (850, 840) | local (350, 690), 65-degree Y projection |
| Archive door | (500, 550) | local (0, 400), 65-degree Y projection |
| Corridor door | (1200, 585) | local (700, 435), 65-degree Y projection |
| East wing future | (850, 350) | local (350, 200) |
| Upper floor future | (850, 320) | local (350, 170) |
| Original physics geometry | 6 map prop rectangles | 6 identical reference footprints |
| Imported standalone PNGs | 7 cutouts | 1 runner + 6 upright furnishings |

The map props include clock (575,460,60,90), left/right staircase bounds (640,190,115,195)/(945,190,115,195), seats interaction/collision group (640,560,160,125), console (1110,720,70,65), and gallery (525,220,65,165). The two chairs and side table share the old one-piece seats collider; we are NOT splitting navigation obstacles as part of a visual import.

The bridge **fails closed**: if the scene's room identity, world origin, dimensions, camera contract, door markers or six physics guides disagree with the current map, imported mode is disabled in favor of AI1. It does not silently remap the world.

## Render and gameplay isolation

One background and one floor runner are drawn from the imported file; six upright images are drawn by foot Y relative to the existing animated Onoe (no second actor). Both front and rear depth passes are used and no old Hall furniture is drawn in imported mode. The existing locked-door markers remain diagnostic overlays.

**Unchanged:** AStar2D grid, six Hall collider footprints and physical stairs, door statuses, authorized fixed routes, interactable object IDs, repair hooks, campaign save, Match-3 integration and VN story flow.

**Still unapproved:** exact painted door/stair visual openings, wall occlusion masks, inconsistent furniture perspective, shadowing, carved/baked duplicate details, unique collision shapes for two chairs and table, image states. Moving a visual in future Builder drafts does **not** automatically move any real obstacle or alter campaign logic.

## How to compare on the published site

1. Open [Prototype Lab](https://bezdredoff.github.io/RavenManor-Godot/), then select **5 · Whole Manor Map**.
2. The Hall's default **Импорт** view renders the imported scene inside the navigable whole-house map.
3. Select **Настр. → Вид: AI1** to compare with legacy art, and cycle back to **Импорт**. Enable **Габариты** to see where the unchanged physical furniture colliders sit relative to pixels.
4. Open **6 · Room Builder → Godot** for the same imported art standing alone. Navigation and doors can only be tested in entry 5.

CI regenerates the exact scene from `examples/room_builder_hall_original.json`, performs a byte-for-byte diff with the committed scene, loads it in Godot, validates five door anchors and six physical rectangles against the live map, verifies imported draw counts and old-art exclusion, and runs the existing cross-room/locked-gate route tests at mobile viewport sizes.

Next production approval gate: compare actual images with doorstep markers and stairs on a mobile screenshot, correct background perspective/occlusion, then explicitly sign off collision/interactive footprint edits. This is a visual integration milestone, not the final art pass.

The measured follow-up, real Godot viewport captures, opt-in three-piece seating footprints and remaining acceptance criteria are recorded in [HALL_VISUAL_ACCURACY_GATE.md](HALL_VISUAL_ACCURACY_GATE.md). The legacy seating obstacle remains the default.

## Measured art QA controls

**Настр. → Стыки: ВИД** overlays the source map stair boxes and true door-vs-painting discrepancy arrows from `data/raven/hall_render_calibration.json`, and displays the existing seating collider next to three provisional contact shapes. **Кресла: 3 ТЕСТ** runs a reversible in-memory pathfinding comparison; default **Кресла: ОРИГ.** remains canonical. Both controls are protected by map/calibration parity validation and never persist to saves. Current background geometry and foreground rail masks still fail final art acceptance; see `docs/HALL_VISUAL_ACCURACY_GATE.md`.
