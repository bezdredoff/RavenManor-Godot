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
