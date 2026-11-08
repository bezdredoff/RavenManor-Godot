# Room Builder — First Floor Draft Import Contract v2

Task: CODE-05-01. Owner: room-builder. Approval: DRAFT_ONLY; NOT canonical gameplay geometry.

## Compatibility / sources of truth

The existing Room Builder room project keeps outer schemaVersion=1. An **optional nested firstFloorDraft** with schemaVersion=2 and kind=raven-first-floor-draft carries floor-wide authoring data. No legacy room must migrate. A draft is saved with the current room project in IndexedDB and preserved by the existing full Project JSON export. This is not the approved map, collision, navigation graph or save-state schema.

Reference: data/raven/season1_world_map.json (geometryStatus=season1-connected-feasibility, NOT APPROVED). The PNG supplied by Agent A is the art authority only after explicit owner approval. Agent C owns authored routes, connectivity and movement; their contract can be imported as *markers* only after schema mapping/review, never as live graph edges.

## Schema v2

The optional firstFloorDraft object has:

- schemaVersion: **2**, kind: **raven-first-floor-draft**, provenance: source/author/approval description.
- baseImage: exactly one of path (repo-relative PNG) or dataUri (embedded PNG); pixelSize: [actualWidth, actualHeight].
- calibration: imageRect [0,0,imageWidth,imageHeight], worldRect [x,y,width,height] and controlPoints. **Agent A imported/unregistered** draft uses `calibration.status=unresolved` and **zero** control points; the original illustrative v2 path can still round-trip its two legacy control points. No crop in v2.
- roomRegions: [{id:"RM-ROOM-...",rect:[x,y,width,height]}]; all coordinates are WORLD-space. Axis-aligned bounds are a visual draft, not collision geometry.
- doorPlacements: [{id:"RM-DOOR-...",rooms:[existingRoomA,existingRoomB_or_null],point:[x,y],width:80}]. IDs and room pairs match the proposed world-map contract. Door points must touch registered rooms within 16 world units.
- foregroundObjects: [{id:"RM-FG-...",roomId:"RM-ROOM-...",assetPath:"relative/file.png",position:[footX,footY],size:[width,height],pivot:[x,y],occlusion:{mode:"foot_y",alphaMaskPath:"relative/mask.png"}}]. Occlusion mode is foot_y, fixed_front or none. Mask path is optional, validated but not applied to gameplay.
- navigationAnchors: [{id:"RM-NAV-...",roomId:"RM-ROOM-...",point:[x,y]}]. Distinct coordinates and IDs; markers only, never edges.
- Extra producer metadata is preserved in the source JSON, but it never silently becomes runtime geometry.

The image is **already painted/projected**. Imported Agent A v1 art is **not spatially registered**: PNG is displayed in its own `image-pixel` coordinates at native dimensions; `world-plan` room/door guides are stored separately and **hidden** in Godot, never overlaid as if calibrated. Existing independently authored illustrative v2 drafts retain their explicit preview transform only. Neither path infers pixel-space navigation or reuses the old sin(65 degrees) floor compression.

Reference rectangle worldSize is presently [2150,2250], but that is **provisional**, not owner-approved calibration. Real pixelSize must come from the actual PNG and is checked against its PNG header. Coordinates and dimensions are not silently adjusted when calibration changes.

## Workflow

1. Open the existing Room Builder PWA and back up Export → Project JSON.
2. In Properties and Layers, use **Карта первого этажа · DRAFT v2** → **Загрузить PNG карты**. This embeds the uploaded PNG bytes into the room draft; no automatic low-resolution substitute. Or import an external matching JSON manifest from Agent A/C using **Загрузить map manifest JSON**. For Agent A v1 in the PWA **upload the exact owner-selected PNG first**: the adapter reads PNG bytes, verifies Git blob/SHA-256, then reads the art manifest. The Python CLI can import Agent A's raw v1 manifest directly.
3. The initial eight room rectangles and eleven door points are copied from the **provisional** world map. Edit worldRect (X/Y/W/H), select an individual room/door/anchor and edit coordinates. Click the mini map to move a selected door or anchor. Invalid edits are rejected before storage. Room region boxes are editable numerically.
4. The **world-plan report** compares proposed room/door coordinates with the existing reference, highlighting shifts beyond 12 world units. When registration is unresolved, the preview shows **only the original PNG**; plan markers are never overlaid and clicking the raster cannot set door or navigation coordinates. Initial room positions are not rescaled when worldRect changes.
5. Use **Проверить карту** for client checks; **Экспорт map draft JSON** saves just v2; existing **Экспорт → Проект JSON** preserves all v1 room content and v2 overlay.
6. Run on the Godot checkout:

    python3 scripts/raven/tools/import_room_builder_game.py /path/to/room-project.json

   Either an opt-in firstFloorDraft **or a raw Agent A `raven.first-floor-art` schemaVersion=1 manifest** (through a strict read-only adapter) creates scenes/raven/generated/RM_FIRST_FLOOR_DRAFT_v2.tscn, plus RM_FIRST_FLOOR_DRAFT_v2.json machine-readable source/delta report and content-hashed embedded PNG in assets/raven/generated/first_floor/. The generated scene is disposable and isolated from the game. The original v1 importer path is unchanged when firstFloorDraft is absent.

## Strict failures

Both editor and Python validate version, known room/door IDs and door-room pairs, finite typed world-plan coordinates, non-zero sizes, rectangle/calibration bounds, duplicate IDs and navigation points, floor-contact pivots and occlusion modes. Python additionally verifies image bytes/header, exact pixel size, repo-relative path safety and actual file presence **before** creating output folders. Missing assets, bad schema, malformed JSON and mismatched calibration fail explicitly. No missing-asset placeholder in v2. For large first-floor art, the PWA still has a 45 MB total project JSON import limit and a 20 MB PNG upload limit.

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

## Agent A v1 → Room Builder v2 interoperability (PR #239)

**Producer is authoritative for its own contract and remains unmodified**: `assets/raven/map/first_floor_manifest.v1.json` (in Agent A's PR #239). The Room Builder consumer accepts `contractId: raven.first-floor-art`, `schemaVersion: 1` and produces a **non-authoritative**, opt-in `firstFloorDraft` v2 carrier. The immutable producer JSON is preserved verbatim under `firstFloorDraft.producerManifest` for round-trip diagnostics. The fixture `tests/fixtures/first_floor_art_A_v1_unapproved.json` freezes Agent A's current v1 draft for compatibility tests; it is **not** a second authoritative art manifest.

The adapter maps `source.path` and **measured** PNG dimensions into `baseImage`, `rooms[].referenceWorldPlanRect` into `roomRegions`, and `doors[].referenceWorldPlanPoint/roomIds` into `doorPlacements` (door width 80 is explicitly tagged `widthAuthority=editor_placeholder_not_art`). Source SHA-256 and actual pixel dimensions are checked from the real PNG bytes in Python; browser import requires the user to upload that exact PNG first and performs SHA-1/Git-blob + SHA-256 verification via WebCrypto before adapting. Missing image, drifted byte count/SHA, wrong dimensions, duplicate IDs, incompatible schema and wrong door references are hard errors.

The adapter deliberately **does not** map Agent A's `RM-ASSET-*` proposals to `RM-FG-*` (no verified alpha cutouts); nor does it move `navigationReferenceAnchors` from `independent_greybox` into `world-plan`. It asserts `worldPlanToSourcePixel.status=unresolved`, `matrix=null`, `controlPoints=[]`, `allowInterpolation=false`. This is preserved as `registration:{status:"unresolved",imageSpace:"image-pixel",referenceSpace:"world-plan",previewSpace:"screen-projected",pixelToWorld:null,navigationAllowed:false}`. No fake corner fiducials, affine/homography fit, navigation anchors or foreground masks are generated.

**Spatial typing:** `image-pixel` is the raw PNG upper-left raster; `world-plan` is the provisional `season1_world_map.json` rectangle; `screen-projected` is a presentation-only viewport using Godot camera parameters; `independent_greybox` is Agent C's separate navigation source. These spaces have **no common transform** until Agent A/C approve at least four reviewed non-collinear floor fiducials and local residuals. A proposed world rectangle is never evidence of pixel registration. No screen-to-navigation conversion is permitted.

To import **directly from Agent A's manifest** on a checkout with the selected PNG:

    python3 scripts/raven/tools/import_room_builder_game.py assets/raven/map/first_floor_manifest.v1.json

When Agent A's PR is not yet merged, save its v1 JSON locally and pass that path instead (the source PNG is already in main). Output is draft-only: `scenes/raven/generated/RM_FIRST_FLOOR_DRAFT_v2.tscn` and matching JSON. For unresolved art, the Godot scene's `BasePainting` uses native raster pixel dimensions and `ReviewGuides` are **hidden** and explicitly labelled `world-plan`. Inspect them separately rather than turning both on as an assumed alignment. The importer never updates canonical map scenes, campaign state or Agent C's navigation graph.

Cross-agent gates remaining: Agent A must confirm SHA256/dimensions, artwork rights, actual floor fiducials/room polygons/foreground segmentation; Agent C must verify routes against real approved geometry. First-floor on-device/visual acceptance is a separate step; existing Hall Godot smoke is not this acceptance.
