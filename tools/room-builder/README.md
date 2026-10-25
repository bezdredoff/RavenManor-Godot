# Raven Manor Room Builder — touch-first PWA v0.2

A self-contained, dependency-free room composition prototype. Designed for Android phone/tablet, S Pen and desktop; built with HTML Canvas, native pointer events and IndexedDB rather than Sprite Fusion's mouse shortcuts. **This is an editor for draft room layout, not canonical game geometry or finished art.**

## Launch

- Hosted: After merge to `main` and successful Pages workflow: `https://bezdredoff.github.io/RavenManor-Godot/builder/`
- Local: `cd tools/room-builder && python3 -m http.server 4173`, visit `http://localhost:4173`.
- Android: visit hosted URL in Chrome and choose **Install app / Add to Home Screen**. Visit once online to cache the editor shell for offline use. Imported images/projects are stored in local IndexedDB; no data leaves the device unless you explicitly export files.

## Workflow

1. Select category and asset; tap **Рисовать** then tap the plan. Repeated taps paint tiles (tile category uses the floor layer). Select and drag to rearrange; use two fingers to pan/zoom; **Рука** pans with one finger. Use +/− and ⤢ as alternatives.
2. Tap **Свойства** to set position, dimensions, rotation, `RM-ASSET-ID`, `RM-HS-*` hotspot link, object `state`, and layer. Locked layers are not selectable/editable. Use layers' checkboxes to hide.
3. **Загрузить PNG / тайлсет** imports a single image or evenly slices a sprite sheet (up to 128 cells). Imports remain in the project. You must have rights to assets you add.
4. Save is automatic to IndexedDB; use **Экспорт → Проект JSON** for portable backup (including imported image bytes), or **Превью PNG** for the art pipeline. No account/sync in this version.
5. To create an optional standalone Godot draft, copy exported JSON into your Godot checkout, then run `python3 scripts/raven/tools/import_room_builder.py /path/to/room.json`. It writes `scenes/raven/generated/RM_ROOM_...tscn` and extracted imported images to `assets/raven/generated/`. Generated scenes are intentionally **not connected** to navigation/state machines and should be reviewed before integration.

## Design constraints

- Editor coordinates are flat **plan-space** only. The actual 65° Godot camera projection, parallax, per-sprite alpha occlusion and physical collision must be calibrated downstream. PNG export is a flat planning render, **not** production anime artwork.
- Example hall layout is illustrative and must not be mistaken for a signed-off floor plan. The source object registry remains `docs/assets/ROOM_OBJECT_REGISTER.csv`; this prototype uses example placeholders with some `RM-ASSET-*` IDs.
- Current graph in `data/raven/manor_greybox_graph.json` stays the single source of truth for authored paths. This tool does not overwrite graph, nav routes, or Godot save schema.
- Any paid/licensed source graphics are imported **locally only**; they must not be embedded in public GitHub Pages or committed without verified rights.
- Offline guarantee applies to shell after a successful first HTTPS load, not necessarily to embedded third-party resources (none are shipped).

## QA / known limits

Run `npm test` (built-in Node test runner) or `npm run check` from this folder; Python importer tests: `python3 -m unittest scripts/raven/tools/test_room_builder_import.py` from repo root.

- Manual Android device QA remains required: Chrome/Samsung Internet installation, multi-touch, pointer capture, S Pen, large PNG quota, offline reopening, portrait viewport and exported JSON restoration.
- No multi-project browser management, cloud sync, asset licensing verification, AI generation or exact 65° preview yet.
- IndexedDB browser storage may be evicted; export JSON regularly. Imported sheets can make JSON large. This does not support arbitrary remote image URLs or SVG imports.

## Season-one production catalog v0.2

The canonical file is `docs/assets/ROOM_OBJECT_REGISTER.csv`. Run `python3 scripts/raven/tools/build_room_catalog.py` in the repo root to regenerate `tools/room-builder/catalog/room-items.json` (and copy it under `builder/catalog/` for the legacy Pages mirror). CI runs `--check` and compares all mirrored web assets.

120 proposed inventory positions in eight room groups are shown in the **Комната** selector; select a room to edit a distinct locally-saved draft, and browse only its catalog plus reusable starter/imported assets. Switching saves the current draft to IndexedDB as `room:RM-ROOM-*` and restores the selected draft; the previous single `current` key remains compatible with v0.1. JSON export remains a manual portable backup per room. Existing user-imported PNG image data is never overwritten by the catalog.

Each catalog item has stable `RM-ASSET-*`, planned state choices, production priority, planned anchor, layer family, and optional *experimental* pilot image path. Catalog cards show schematic symbols, not finished art; sizes in plan-space are placeholders. Each stamp creates an independent instance ID while retaining registry `assetRefId`. Both Hall chairs share one reusable `familyKey` but have separate registry IDs. The pilot PNGs are metadata only: not auto-downloaded, embedded, licensed for reuse, or approved as individual finished states. No bulk PNG production is implied.

`ROOM_OBJECT_REGISTER.csv` remains a **proposed family/position list**, not a count of rendered sprites: bundled lamp pairs, table settings or plant clusters may contain multiple actual objects. Positions/anchors, explicit instances/occluders, geometry and hotspots await the `RM-PIPE-001` approval gates. Catalog changes are never allowed to override authored Raven navigation or campaign save.

## v0.2.1 catalog and data-integrity update

Select a room, inspect its **placed positions / planned positions** count, and optionally activate **Только неразмещённые** to work through all registered entries. Place with a tap, then change its planned state in the properties panel. A catalog reference ID cannot be edited in place; manual imported decoration remains freely configurable. Planning metadata explicitly records unknown dimensions/pivots/occlusion/interaction points and marks every per-state image as **not yet approved**.

Room-specific drafts save in serialized order; a failing write blocks switching rooms to prevent accidental loss. PNG files imported locally can be reused in subsequent room drafts. An exact original v0.1 Hall demonstration has its historical chair/table references corrected without modifying custom placements. PNG export waits for embedded images to decode. Export JSON backups regularly: a browser storage quota failure still requires manually freeing space or exporting the current draft.

**Note:** counting planned positions on the canvas does not certify layout, quantities inside grouped rows, separate image files, story progression or geometric collision. Final asset/pivot/rights/state technique reviews are pending.
## v0.2.2 — full 120-item catalog browse

The default **Обзор предметов → Весь особняк · 120 позиций** shows all 120 proposed entries in eight named groups. This is intentionally separate from **Текущая комната + инструменты** (Hall: 19 registry entries + 16 generic starter tools = 35). Search can match item names, registry IDs or room names. Switching the visible library mode does not change the active room or erase a draft.

Choosing an item assigned to another room while browsing the mansion first saves the current draft and switches to that item's room. Only after a successful switch does it arm that asset for stamping. A storage/save failure blocks switching. The **неразмещённые** filter is available only in room mode.

Service worker cache is now v4 and fetches current assets online first, with offline cache fallback to avoid holding an obsolete catalog UI indefinitely. An already-open PWA may need to be closed and reopened once after the deploy. All 120 entries remain schematic planning data, not 120 generated PNGs.
