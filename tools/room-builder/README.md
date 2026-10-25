# Raven Manor Room Builder — touch-first PWA v0.1

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