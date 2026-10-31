# UPDS-godot VN corpus — pinned migration audit (VN-EDITOR-01)

**Date:** 2026-10-31 · **Status:** source-corpus analysis delivered; full runtime/parity acceptance remains **pending**.  
**Canonical donor:** private `bezdredoff/UPDS-godot` `main`, pinned commit `3deed628efd6c22bcd1717f7c545b7d3ca865781`.  
**Raven public artifact:** `data/raven/production/upds_vn_corpus_manifest.json`; **only file paths, source Git blob SHA, sizes and numerical metadata**. No protected dialogue, translations, sprites or UPDS audio have been imported into Raven.

## Evidence and observed shape

We inspected all **45** `data/*_scene.json` / `prologue.json` story JSON files through the connected private GitHub source at the pinned commit. `data/save_contract.json` gives the canonical `storySceneIds` index list `0..44`; `locker_scene.json` is intentionally **missing** `sceneIndex`, so importer must resolve index by that list instead of inferring it from filenames.

| Measure | Observed from 45 source JSON files | Contract warning |
|---|---:|---|
| Scene files and scene IDs | 45 | `sceneIndex` absent in one variant scene |
| Line **occurrences** | 1,026 | Counts one occurrence per A/B/C branch; **not unique line IDs** |
| `hidden: true` occurrences | 213 | These stage directions must stay editable but non-player-facing |
| Locales appearing in each scene | `ru`, `en`, `be` | Presence does not prove editorial/translation quality |
| Scenes containing `variants` | 1 | `locker_scene`: A/B/C alternate line sequences |
| Scenes containing `choiceGate` | 8 | Inline decision checkpoints, `checkpointLineId`, effect text |
| Scenes containing `nextLevelId` | 22 | Story→Match-3 gates; match result returns by `onWinSceneIndex` |
| Scenes containing `ending` | 3 | Existing ending outcomes and fallback logic remain donor-owned |
| `nextSceneIndices` final routes | 3 | Branch A/B/C routes after `final-strategy` |

Other donor sources pinned in manifest: `data/save_contract.json`, `data/actor_layouts.json`, `data/asset_catalog.json`, `data/ending_outcomes.json`, `scripts/core/story_session.gd`, `scripts/vn/vn_screen.gd`, `scripts/vn/dialogue_paging.gd`, `scripts/vn/portrait_motion_rig.gd`. Character frame and named slot geometry are resolved by **`actor_layouts.json`**, while assets are addressed through **`asset_catalog.json`**, not assumed to exist by assembling filenames.

### Source differences that matter to migration

- **Donor authority:** `UPDS-godot` is the maintained native Godot project. The older private `UPDS` monorepo exported its `godot/data` JSON via `scripts/export-godot-prologue.cjs` from TypeScript/Markdown. Those exported files and the current native `UPDS-godot` schema **differ**; do not silently write into the old export output or treat it as current authoritative native content.
- **Timeline vs graph:** scenes generally have `nextSceneId`/`nextSceneIndex`, pre-Match-3 scenes have `nextLevelId`/`onWinSceneIndex`, later choices have `choiceGate` and the final split uses `branchChoiceId` + `nextSceneIndices`. Do not flatten to sequential scene numbers.
- **Actors:** canonical Godot `actors` usually specify `character`, `pose`, `layout`; frame sizes/anchors come from the catalog. The old generated JSON used absolute image paths and per-line pixel placement; the import adapter must be version-sensitive.
- **Saved progress:** donor `StorySession` and save contract own `scene/line`, choice outcomes, read line history, Match-3 and ending state. A new editor cannot be the new save authority. Any future switching to stable ID positions requires a measured mapping from the old saved index and branch selection.
- **Privacy:** even when a file can be read through the private connector, *never* copy story text, translations, unpublished character art or source screenshots into this public Raven repository or public Pages. Audit aggregates are intentionally safe.

## Reproducible reader / fixture workflow

Run from a **separate authorized local checkout of the private donor** with the pinned commit checked out (the script itself never clones or downloads donor data):

```bash
git -C /path/to/UPDS-godot checkout 3deed628efd6c22bcd1717f7c545b7d3ca865781
python3 scripts/raven/tools/audit_upds_vn.py --upds-root /path/to/UPDS-godot --output /tmp/upds-vn-audit.json
python3 -m unittest scripts/raven/tools/test_audit_upds_vn.py
```

The first command is a **donor checkout operation performed by the owner**; ensure its worktree is clean or make a separate clone/worktree to avoid discarding changes. The Python command is **read-only** in the donor and writes aggregate summary to `/tmp`, not donor. It verifies: Git blob hashes and bytes of 45 scene JSON files plus 8 donor-reference files; exact scene set; `save_contract` IDs and scene index equivalence; A/B/C variants; locale fields; actor layouts; choice checkpoints; Match-3 IDs; destination scene bounds; per-file and global counts. Unexpected new scene, changed SHA, missing locale, invalid choice, missing asset layout or target returns a nonzero exit status. Unknown backgrounds are reported separately as warnings, not treated as approved/available imagery.

The repository's `scripts/check.sh` runs **synthetic tests only**; it does not have access to private `UPDS-godot` checkout on public CI. Six tests cover harmless synthetic fixtures, immutable source, provenance SHA drift, locale omission, route validation, path traversal and separate branches. The source-specific audit above must be executed on the donor checkout with permission; this is **not yet evidence** of a green real-donor Python run or a renderer parity test.

## Priority fixture matrix for VN-EDITOR-02

| Fixture | Purpose | Required reviewer behavior |
|---|---|---|
| `data/prologue.json` | base dialog, speaker/facial states, RU/EN/BE | Inspect line `VN0001`, stage, localizations without writing donor |
| `data/locker_scene.json` | A/B/C variants, initial `choices`, variant-specific line IDs | Switch alternatives without accidental flattening, preserve selection |
| `data/emergency_meeting_scene.json` | inline `choiceGate`, checkpoint | Branch preview at gate, no actual saved storyChoice write |
| `data/post_full_timeline_proof_scene.json` | final branch routing `nextSceneIndices` | Show all three scene targets, distinguish from line order |
| `data/post_private_return_scene.json` | ending `ENDING_B_CASE_CLOSED` | Ending renderer/data semantics remain donor-owned |
| `data/post_full_truth_scene.json` | different ending route | No copy of private ending prose into public fixtures |
| `data/post_convenient_case_scene.json` | third ending route | No fake/default ending used for unselected branches |

**Required next deliverable:** `VN-EDITOR-02` native `EditorPlugin` **Legacy Viewer** using the pinned reader/scene provider. Initially support private donor path selection from the editor, protect source read-only, render timeline and portraits with real resolved donor catalogs, and show unsupported/warnings. Conversion and game save writes are explicitly out of scope; the viewer must be validated through actual Godot editor QA.

## Outstanding work / limits

- The manifest hashes **file identities**, not behavior. This PR does **not** prove all 1,026 lines can be displayed or converted without loss.
- `StorySession` choice/read/skip/match3/ending state is catalogued at API level but not independently replayed by this audit; save parity, screenshot parity, locale overflow, actual asset resolution and full semantic round-trip remain future gates.
- Current counts were obtained from connector-side analysis of all 45 donor JSON files; synthetic unit tests were run against local test data, **not a private donor checkout**. Do not mark migration E3/E4, Godot E2 or VN-EDITOR-02 accepted.
- Dependency on `CODE-03` VN runtime extraction remains unchanged. Audit tooling is deliberately independent of renderer/gameplay state.
