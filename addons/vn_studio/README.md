# VN Studio — Godot legacy authoring (VN-EDITOR-03)

**Status:** proposed native editor draft-authoring pilot, not a converter or runtime renderer. Requires Godot 4.7.2 desktop editor. UPDS-godot source files are **read-only**.

## Workflow

1. Open RavenManor-Godot in the Godot desktop editor. Select the **VN Studio** tab, then **Открыть UPDS-godot…** and select the root of an authorized separate checkout of private `bezdredoff/UPDS-godot`.
2. Browse 45 scenes from `data/save_contract.json`, switch A/B/C branches and RU/EN/BE languages. Choose a line. If the scene has a saved local draft based on the **same source SHA**, it is reloaded automatically. If source changed, the scene is **blocked** and requires a manual diff/rebase; other scenes remain browsable.
3. Edit **speaker/emotion/dialogue text** for the currently selected language. Change a character's pose using the dropdown (only poses offered by the donor asset catalog), or drag a portrait on the stage to adjust normalized X/Y. The original legacy scene IDs, hidden stage directions, branch conditions, Match-3 gates and original line order are immutable.
4. **Undo / Redo** changes to the selected scene; typing is grouped by focus session, and each pose change/drag begins an undo step. Choose **Сохранить черновик** to persist edits. Unsaved changes stay in memory when browsing scenes; the editor blocks switching source projects if unsaved edits exist.
5. Close/reopen Godot, select the same donor root, scene and line: the draft reappears. The original UPDS source is not written, and nothing changes in campaign progression or saved player state.

## Where drafts live

`user://vn_studio_drafts/v1/<sha256-of-local-UPDS-root>/<sceneIndex>.json`

This is local Godot user data, **outside the publicly tracked Raven repository**. **Private edited UPDS text may appear in these files**. They must never be staged/committed to public Raven, uploaded as CI artifacts, attached to a PR or placed under `res://data`. Use appropriate local backup/access controls. The path is local to the Raven Godot user-data directory on that machine; these edits are not automatically synchronized or portable to another workstation.

Each `vn-studio-legacy-overlay-v1` file pins `sceneId`, source relative filename, `baseSha256` and a SHA256 fingerprint of the selected root path. Patch keys contain exact `[variant, lineIndex, lineId]`; localized changes use `speaker/emotion/text` and actors use index, original character ID, pose and normalized X/Y. Saving never touches `UPDS-godot/data`, `Raven/data`, `RavenReducer` or game saves.

Overlays are **not** imported runtime scene files. The existing UPDS VN renderer does **not** apply them. They are authoring drafts for the later reviewed converter (`VN-EDITOR-06`), not an implicit migration of gameplay or translations. They also do not grant publication rights for private UPDS assets.

### Conflicts and recovery

If a source file's content differs from the recorded base SHA, the draft is refused; the plugin does not silently rebase, discard, or overwrite it. Keep the source revision pinned or review/rebase patches in a later migration workflow. Saving uses a local temporary file, backup and rename; a backup may remain after an interrupted operation, so inspect locally before deleting it.

## Current limitations

- The stage preview is **approximate**, not pixel-perfect UPDS runtime preview. Drag uses normalized anchors, not donor `actor_layouts.json` global changes; it is per-line only. No free-added actors, new costumes or assets.
- Undo/redo covers the active scene, not a multi-scene transaction; built-in text editor shortcuts and plugin Undo button are distinct mechanisms.
- Missing/unsupported images render placeholders; an empty actor list has nothing to drag. The project must still pass the original UPDS donor path/version checks. No file chooser or right-click export for public source assets.
- Choices and level transitions are **read-only metadata**. No state mutation, save conversion, automatic GitHub upload, runtime line insertion/reorder, voice playback or interactive story graph.
- Only Godot desktop/editor UI has the visual controls; web Pages exports are not authoring surfaces.
- Re-read of the private donor in a real local Godot Editor is still a manual QA gate. CI only tests **synthetic** private-content-free fixtures.

## Tests

```bash
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/raven/vn_studio_legacy_smoke.gd --quit-after 120
godot --headless --path . --script res://tests/raven/vn_studio_drafts_smoke.gd --quit-after 120
bash scripts/check.sh
```

The draft smoke verifies line translations, pose/position, original bytes untouched, save/reopen, repeat save, wrong actor position blocked, separated A/B/C keys and SHA drift fail-closed. Manual acceptance: edit a line in UPDS prologue, pose/drag in the tea/other scene, switch languages and variants, save/restart, inspect no donor differences, check screenshot/font overflow, Undo/Redo. **Do not call acceptance passed from CI alone.**
