# Room Builder — First Floor Draft Import Contract v2

Task: CODE-05-01. Owner: room-builder. Approval: DRAFT_ONLY; NOT canonical gameplay geometry.

## Compatibility / sources of truth

The existing Room Builder room project keeps outer schemaVersion=1. An **optional nested firstFloorDraft** with schemaVersion=2 and kind=raven-first-floor-draft carries floor-wide authoring data. No legacy room must migrate. A draft is saved with the current room project in IndexedDB and preserved by the existing full Project JSON export. This is not the approved map, collision, navigation graph or save-state schema.

Reference: data/raven/season1_world_map.json (geometryStatus=season1-connected-feasibility, NOT APPROVED). The PNG supplied by Agent A is the art authority only after explicit owner approval. Agent C owns authored routes, connectivity and movement; their contract can be imported as *markers* only after schema mapping/review, never as live graph edges.

## Schema v2

The optional firstFloorDraft object has:

- schemaVersion: **2**, kind: **raven-first-floor-draft**, provenance: source/author/approval description.
- baseImage: exactly one of path (repo-relative PNG) or dataUri (embedded PNG); pixelSize: [actualWidth, actualHeight].
- calibration: imageRect [0,0,imageWidth,imageHeight], worldRect [x,y,width,height], controlPoints [{pixel:[px,py],world:[wx,wy]},...] (at least two independently declared correspondences). No crop in v2.
- roomRegions: [{id:"RM-ROOM-...",rect:[x,y,width,height]}]; all coordinates are WORLD-space. Axis-aligned bounds are a visual draft, not collision geometry.
- doorPlacements: [{id:"RM-DOOR-...",rooms:[existingRoomA,existingRoomB_or_null],point:[x,y],width:80}]. IDs and room pairs match the proposed world-map contract. Door points must touch registered rooms within 16 world units.
- foregroundObjects: [{id:"RM-FG-...",roomId:"RM-ROOM-...",assetPath:"relative/file.png",position:[footX,footY],size:[width,height],pivot:[x,y],occlusion:{mode:"foot_y",alphaMaskPath:"relative/mask.png"}}]. Occlusion mode is foot_y, fixed_front or none. Mask path is optional, validated but not applied to gameplay.
- navigationAnchors: [{id:"RM-NAV-...",roomId:"RM-ROOM-...",point:[x,y]}]. Distinct coordinates and IDs; markers only, never edges.
- Extra producer metadata is preserved in the source JSON, but it never silently becomes runtime geometry.

The image is **already painted/projected**. The v2 whole-floor importer maps it linearly over worldRect and never applies the old sin(65 degrees) vertical floor compression twice. The old per-room visual importer retains its original transform.

Reference rectangle worldSize is presently [2150,2250], but that is **provisional**, not owner-approved calibration. Real pixelSize must come from the actual PNG and is checked against its PNG header. Coordinates and dimensions are not silently adjusted when calibration changes.

## Workflow

1. Open the existing Room Builder PWA and back up Export → Project JSON.
2. In Properties and Layers, use **Карта первого этажа · DRAFT v2** → **Загрузить PNG карты**. This embeds the uploaded PNG bytes into the room draft; no automatic low-resolution substitute. Or import an external matching JSON manifest from Agent A/C using **Загрузить map manifest JSON**.
3. The initial eight room rectangles and eleven door points are copied from the **provisional** world map. Edit worldRect (X/Y/W/H), select an individual room/door/anchor and edit coordinates. Click the mini map to move a selected door or anchor. Invalid edits are rejected before storage. Room region boxes are editable numerically.
4. The preview compares room/door geometry with the existing proposed reference, highlighting shifts beyond 12 world units for manual review. Initial room positions are not rescaled when worldRect changes.
5. Use **Проверить карту** for client checks; **Экспорт map draft JSON** saves just v2; existing **Экспорт → Проект JSON** preserves all v1 room content and v2 overlay.
6. Run on the Godot checkout:

    python3 scripts/raven/tools/import_room_builder_game.py /path/to/room-project.json

   An opt-in firstFloorDraft creates scenes/raven/generated/RM_FIRST_FLOOR_DRAFT_v2.tscn, plus RM_FIRST_FLOOR_DRAFT_v2.json machine-readable source/delta report and content-hashed embedded PNG in assets/raven/generated/first_floor/. The generated scene is disposable and isolated from the game. The original v1 importer path is unchanged when firstFloorDraft is absent.

## Strict failures

Both editor and Python validate version, known room/door IDs and door-room pairs, finite world-space coordinates, non-zero sizes, rectangle/calibration bounds, duplicate IDs and navigation points, floor-contact pivots and occlusion modes. Python additionally verifies image bytes/header, exact pixel size, repo-relative path safety and actual file presence **before** creating output folders. Missing assets, bad schema, malformed JSON and mismatched calibration fail explicitly. No missing-asset placeholder in v2. For large first-floor art, the PWA still has a 45 MB total project JSON import limit and a 20 MB PNG upload limit.

The sample tests/fixtures/first_floor_draft_valid.json embeds a 1×1 PNG **only as a deterministic test fixture**, NOT the owner-approved illustration.

## Runbook and QA

    cd tools/room-builder && npm run check
    cd ../..
    python3 -m unittest scripts.raven.tools.test_first_floor_draft_import scripts.raven.tools.test_room_builder_game_import
    python3 scripts/raven/tools/import_room_builder_game.py tests/fixtures/first_floor_draft_valid.json
    godot --headless --editor --path . --import
    godot --headless --path . --script res://tests/raven/room_builder_game_import_smoke.gd --quit-after 80

CI runs Node test wildcard and the existing Python importer test file (which imports the new regression class). Godot CI still exercises the original Hall scene, not first-floor visual acceptance. First-floor F6 visual review with Agent A's real image, correct corner correspondences, precise door positions, foreground masks, phone/tablet/S Pen and explicit owner acceptance remain NOT_RUN / pending.

## Explicitly forbidden promotion

No changes to project.godot, vertical_slice.gd, raven_reducer.gd, raven_campaign_store.gd, raven_snapshot.gd, canonical map scenes, navigation graph, door save states, authored route topology or physical collisions. The generated scene has no StaticBody2D, collision shapes or NavigationRegion2D. Integration requires a separate owner-approved PR involving Agent A's accepted art and Agent C's navigation contract.
