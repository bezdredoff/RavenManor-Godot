# VN Studio — Godot Legacy Viewer (VN-EDITOR-02)

**Status:** first native editor-only prototype; **read-only**. No drag-and-drop editing, converter, migrated story resources or production runtime integration in this PR.

## Open a real UPDS project

1. Open **RavenManor-Godot** as a project in **Godot 4.7.2** (desktop editor, not deployed GitHub Pages).
2. The project enables the `VN Studio` editor plugin in `project.godot`. If the tab is missing, check **Project → Project Settings → Plugins → VN Studio**.
3. Click the **VN Studio** main-screen tab next to 2D/3D/Script.
4. Click **«Выбрать локальную папку UPDS-godot…»**. Select the root of an **authorized separate checkout** of private `bezdredoff/UPDS-godot`, where `data/save_contract.json`, `data/actor_layouts.json` and `data/asset_catalog.json` are present. Do *not* select old `bezdredoff/UPDS/godot` export.
5. Search scenes by ID/name, choose scene, A/B/C variant if applicable, RU/EN/BE and any line; use **Next** for linear browsing. The right panel shows line IDs, `hidden` stage directions, character poses, source file, choice checkpoints, Match-3 and ending metadata. Stage displays donor background and character art when its local catalog/path is valid.
6. Leave the tab or close editor; the script does not write any donor files, project story JSON, editor overlay, campaign state or saves. It also does not store the chosen source path as a project setting.

## Known deliberate limitations

- **Preview is a staging reference, not runtime-pixel parity**. Portrait anchors are approximated from `actor_layouts.json` and artwork; genuine UPDS `vn_screen.gd` layout/pagination, scale, 4-row shell, transitions, animations, choice outcome and save engine are not being run by the editor. Do not accept screenshot parity from this viewer.
- **Open Scene is not Convert.** Reader recognizes the native UPDS-godot contract of exactly 45 scenes; an unknown source version fails closed. Hash provenance/full audit is via `scripts/raven/tools/audit_upds_vn.py` and `upds_vn_corpus_manifest.json`, not current Viewer.
- Branch selection only shows each branch's lines. Inline `choiceGate` and `nextSceneIndices` are metadata descriptions, not executable game transitions.
- Missing image/locale shows a fallback or warning without mutating source assets. External PNG/WebP files are loaded from selected `assets/` only; no network downloads or source Git cloning.
- Asset licensing/private source remains upstream. Never attach UPDS scenes, art, audio or screenshots to public Raven commits.
- The plugin requires a desktop Godot Editor with local filesystem access. It is not exposed in the exported game or on mobile Pages.
- For actual multiline rendering, editor drag/resize, authoring overlays, graph, schema migration and screenshot parity see follow-up `VN-EDITOR-03..07` and runtime `CODE-03`.

## Tests

```bash
godot --headless --path . --editor --quit
godot --headless --path . --check-only --script res://addons/vn_studio/editor/legacy_reader.gd
godot --headless --path . --check-only --script res://addons/vn_studio/editor/studio_view.gd
godot --headless --path . --script res://tests/raven/vn_studio_legacy_smoke.gd --quit-after 120
bash scripts/check.sh
```

`tests/raven/vn_studio_legacy_smoke.gd` builds an entirely **synthetic** 45-scene fixture in `user://`, verifies index recovery, variants, locale selection, no-writes and invalid sources. No private donor checkout is supplied to public CI.

**Manual editor QA required:** actual desktop Godot 4.7.2 open plugin; browse the authorized private donor; verify all 45 scenes, A/B/C switch in `locker_scene`, RU/EN/BE and backgrounds/portraits, dialogs including `hidden`, no source file changed; check approximate screenshot/visible layout. Until then do not mark `device_verified` or `accepted`.
