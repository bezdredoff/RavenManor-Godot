# RM-EDITOR-001 — Mobile Room Builder PWA (prototype)

**Owner intent (2026-10-25):** Sprite Fusion-style editor that works from Android phone/tablet, without mandatory right-click or keyboard. Deliver as a standalone PWA in `tools/room-builder/`, not as game runtime. Users place tilemap primitives or free-positioned props, attach metadata, export room layout, and optionally generate a draft Godot scene.

## Architecture

- Framework-free ES modules, Canvas2D and pointer events; no build tooling or third-party CDN to compromise offline use and hosting alongside the existing Godot Web export.
- `model.mjs`: versioned `schemaVersion:1` JSON format, validation and unit-testable geometry.
- `app.mjs`: editor gestures, layout, library, layers, image import, undo/redo, auto-save to IndexedDB; it does not call GitHub or ComfyUI.
- `sw.js`, `manifest.webmanifest`, local icon assets: installable/offline shell at `/builder/` on GitHub Pages.
- `scripts/raven/tools/import_room_builder.py`: manual conversion to separate Godot .tscn draft; never overwrite `manor_greybox_graph.json` or gameplay scenes.

## Ownership and compatibility

Keep `RM-ROOM-*`, `RM-ASSET-*`, and `RM-HS-*` identifiers; `source_status=PROPOSED` registry content is not approved art. Example hall layout is illustrative. The approved `RM-HUB-001` authored graph remains game navigation truth; no free tap-to-move. Use the current 65° mobile camera acceptance baseline when integrating finalized visuals. This PWA does **not** render that camera perspective.

## Deploy

The existing `.github/workflows/pages.yml` exports Godot into `build/web/`. The builder is copied into `build/web/builder/` **before** uploading the single artifact so the main Prototype Lab at `/` remains unchanged. Build/check job runs Node tests and Python importer tests first. PR events test builds but do not publish to GitHub Pages; merge to main publishes.

## Acceptance evidence

Automated tests validate schema, geometry, import sanitization, and standalone Godot conversion. Additional manual touch + PWA browser QA is still pending; don't mark device acceptance complete without tablet testing.


## v0.2: linked 120-position production catalog

The source inventory is now `docs/assets/ROOM_OBJECT_REGISTER.csv` (117 original proposals plus three Hall chair/table records). The PWA loads a derived `./catalog/room-items.json` file, chooses a room via touch-friendly `Комната`, shows P1/P2 and concept-PNG metadata, and maintains local per-room draft saves while preserving previous single-project data. An asset stamp retains the registry `RM-ASSET-*` reference, planned state and independent instance identity. Both public `tools/room-builder/` and mirrored root `builder/` versions include this file; service-worker cache version bumped. No art/projection/collider/gameplay approval is implied. See `docs/ROOM_CATALOG_PRODUCTION.md`; generator `scripts/raven/tools/build_room_catalog.py --check` is included in CI.

## RM-CAT-001 final catalog maintenance (2026-10-25)

PWA v0.2.1 preserves the complete 120-position first-season planning register, state/approval/provenance metadata and local per-room drafts. Room progress and missing-position filter help verify placement without pretending noncanonical geometry is final. Browser storage writes are ordered and switching rooms stops if current save fails; user PNG imports can follow the user's drafts between rooms. Historical exact Hall sample placements are migrated conservatively. PNG export waits for image decode. The published static package and the root Jekyll fallback contain identical generated JSON and JavaScript, checked by CI.

The production fields have explicit unknowns (`null` pivots/dimensions/hotspots and undecided per-state art strategies); approved art creation and actual Android/S Pen manual acceptance remain separate gates, not completed by successful code tests.
## 0.3.0: editing on the current Godot 65° floor projection

The main Canvas mode is now **Игровой 65°**, with **План XY** retained only as an alternate technical view. Drawing and picking use the exact floor-depth ratio from Godot `season1_map_greybox.gd` and preserve all existing local project X/Y coordinates. Hall comparison can show the Godot's original AI1 source image and checked door overlays when the draft is exactly 700×690; old 1000×800 demo geometry triggers an explicit warning. The published PWA includes a mirrored copy of current provisional Godot world map and the original generated Hall background; no CSS faux-isometric transform is used. The draft importer and catalog remain unchanged. **This is projection consistency, not approval of production scene height, mask/Y-sort, background seam or phone screenshot parity.** Details: `docs/ROOM_BUILDER_GAME_PROJECTION.md`.
