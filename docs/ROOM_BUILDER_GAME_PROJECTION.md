# RM-EDITOR-002 — in-game projected editing

Status: **working projection/editor pilot**, not production-ready WYSIWYG art certification (2026-10-25).

## Decision
The main Room Builder view is **Игровой 65°**, and **План XY** is a secondary diagnostics tool. Selection, stamping, drag, layer order, canvas zoom, and PNG export share the transform used by `scripts/raven/season1_map_greybox.gd`:

`screenX = viewportX + worldX * zoom`
`screenY = viewportY + worldY * zoom * sin(65°)`

Pointer hit testing/dragging invert the same affine transform. The saved `object.x/y/w/h` stay in unprojected world-plane authoring coordinates; switching modes does not rewrite them. **0.74×** matches the Godot pilot zoom factor; editor layout/viewport is not the game's HUD or identical camera-center framing.

## Hall reference and placement contract
`tools/room-builder/reference/season1_world_map.json` contains an **exact mirrored copy** of `data/raven/season1_world_map.json` (checked by CI). Hall in that *still-unapproved* continuous map is the global rectangle **(500,150,700,690)**; the local editing rectangle must be **700×690** to align to its room bounds. The local origin (0,0) corresponds to world (500,150), and the local doorway/major-prop guide coordinates are derived by subtraction, not copied from guesses.

When room ID **RM-ROOM-HALL** and dimensions **700×690** match, Builder draws the exact AI1 pilot background `assets/raven/hall/generated_pilot/backgrounds/hall_twin_staircases.png` mirrored at `reference/hall_twin_staircases.png`. It uses Godot's same draw-texture rectangle and floor transform. Optional guide markers identify Entry, Archive, Corridor and future doors, plus yellow **provisional physical furniture/clock/staircase footprints** from the same map. Disable them in the properties panel to examine the image without overlays. This view is for **comparison**, not approved coordinates or gameplay-ready artwork.

The previous Room Builder sample is **1000×800**. It remains deliberately untouched; in Game mode the editor **warns and hides the reference painting/door markers** instead of silently stretching or reinterpreting all existing furniture placements. To start a geometrically aligned *new* Hall draft, first export the existing room JSON as backup, then choose **Экспорт → Новая пустая комната** (after confirmation). Builder automatically uses the **provisional Godot floor-map dimensions** (Hall: **700 × 690**) and grid **25**, records the suggested world origin, and exposes the Hall background/door guides. This explicitly replaces the active per-room draft: do not confirm until the old draft is backed up. Keep its asset coordinates local 0–700/0–690. Do not convert an older furnished 1000×800 room just by editing the two width/height fields; redo its placement against the actual door/collider references.

The original world map is a feasibility layout. Its occupancy and candidate room sizes still require user approval; the new PWA does not modify the map or Godot navigation. Every catalog item remains PROPOSED.

## WYSIWYG limits / future acceptance
- Exact current **2D floor projection and inverse picking**, including imported PNG under the same affine transform: **implemented**, tested by geometry round-trips.
- Reused actual Godot AI1 Hall background in correctly sized Hall draft: **implemented**, though the generated background itself has spatially misaligned stairs and door openings. Rendered comparison is not physically certified.
- Real prop cutouts matched to the fixed projection, real footprint anchors, back/front wall occlusion, contact shadow, per-instance depth/Y-sort, animation, interactive hitboxes and canonical character: **not implemented / unapproved**. The 120-item palette mostly renders schematic symbols.
- True Godot HUD in 390×844 portrait, phone safe areas and screenshot-pixel parity: **not implemented**. On an actual phone verify S Pen/touch and scene framing independently. The 0.74× button sets scale, not exact Godot recenter logic.
- Godot draft scene importer does not yet implement game-camera art occlusion, room origin metadata or a canonical coordinate mapping; it remains `DRAFT_ONLY`. Do not attach it to the live save/nav graph.

## QA
The pure helpers `projection.mjs` mirror `_screen_from_world` / `_from_screen` and are regression-tested at several zooms. `tests/projection.test.mjs` also checks current world map door/clock anchors. CI compares two mirrored reference files to source assets and ensures both Jekyll-root `builder/` and custom Godot Pages include the new scripts/reference data.

Manual acceptance sequence: open Builder on tablet → select Game 65° / Plan XY → stamp/drag the same object in both modes → export and reimport JSON without changed world coordinates → export PNG in Game mode → back up old Hall → create separate blank draft 700×690 → check image/door guides visually against `5 · Whole Manor Map` in Godot → verify 0.74× framing, collisions and occlusion before any visual approval.


## RM-PIPE Hall render pilot v0.4 (2026-10-25)

The shared source-of-truth file \`data/raven/hall_visual_contract.json\` describes seven **unapproved pilot cutouts** and exact world drawing rectangles (original images remain unmodified). It is mirrored byte-for-byte to \`tools/room-builder/reference/hall_visual_contract.json\` and \`builder/reference/hall_visual_contract.json\`. Source files under \`assets/raven/hall/generated_pilot/props/\` and the original technical Onoe sheet are mirrored as PNG binaries to the PWA; GitHub Actions checks both paths and builds both publication methods.

The visual pipeline distinguishes two types: **floor** (rug uses floor compression, same as the current Godot map) and **upright** (clock, individual left/right armchairs, table, console, gallery). Upright sprite destination rectangles have a bottom-centre world-foot anchor: the actor foot projects at Y×sin(65°), then the sprite rises by its *uncompressed* art height×zoom. Both editors draw upright items sorted ascending by foot Y behind the actor when item foot ≤ actor foot, and in front when item foot > actor foot. Godot now uses an independent z=6 transparent CanvasItem to draw front silhouettes above the z=5 technical Onoe sprite. PNG alpha supplies the available cutout, not an invented final occlusion mask.

The PWA's **Поставить Оноэ на пол** tool is an isolated preview actor-foot marker; it has no authority over the game's route start or save. The user can move the actor and each item on touch screen to evaluate alpha/overlap, and edit states/positions without transforming JSON coordinates. Drawing and selected-image hit testing use upright *screen-space* rectangles; this is **not yet per-alpha hit picking**. Generic imported PNGs and other 113 registry entries stay schematic and lack calibrated pivots/heights.

### Manual Builder JSON → Godot visual preview

1. In the PWA, choose **Экспорт → Проект JSON** and transfer that file from tablet to a workstation with the RavenManor-Godot checkout. Use a **new, shared-manifest-seeded Hall draft** (700×690) only; old 1000×800 sample geometry is intentionally rejected.
2. Run \`python3 scripts/raven/tools/sync_hall_preview.py path/to/rm-room-hall-room.json\`. This outputs \`data/raven/hall_builder_preview.json\` explicitly marked \`DRAFT_ONLY\`.
3. Run Godot's **5 · Whole Manor Map → Вид: AI1** from the local project. The same PNGs are rendered at the editor's authored coordinates with the same screen-height and foot-depth split. Switch actor position by walking normally; the PWA's debug actor position does not alter campaign route state.
4. Remove \`data/raven/hall_builder_preview.json\` to restore the default baseline. The override file is optional and not committed by this PR; it is intentionally **visual only** and does **not** modify the actual world collision boxes, unlock states, persistent repairs or routes.

The safe converter whitelists art via the versioned shared manifest; it rejects duplicate pilot identities, rotations (not yet supported for cutouts), non-finite geometry and non-rendered states rather than fabricating art. A moved image may no longer match Godot's collision rectangle: debug **Габариты** makes the inconsistency visible, and the game geometry is never silently changed.

### Production gates still not passed

- Real architectural wall occlusion geometry, Y-sort masks at arbitrary elevation, shadows/light variations, clean/dirty/repair texture atlas, scene interaction hit polygons, canonical character artwork and actual Android screenshot matching.
- True bidirectional runtime synchronization, instant in-game editing, automatic movement/collider updates and multi-room production coverage.
- Art visual acceptance; original generated backgrounds still contain perspective/door seam discrepancies and current cutouts are experimental.

The goal for the next slice is to address collisions, alpha masks, physical height/pivots and approved source art for the *one accepted Hall layout* before applying the method to all 120 planned entries.
