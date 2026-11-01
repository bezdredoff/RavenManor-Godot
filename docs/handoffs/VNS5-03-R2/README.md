# VNS5-03-R2 — patched after PR #97 merge; incoming carrier, not implementation

Frozen main: `8313a109b708e0ae244f5516d9a80d952bcd508f` (PR #97 merged). This archive is a `raven-delta-v1` with only `docs/handoffs/VNS5-03-R2/` files. It **passes the existing incoming validator** without violating protected `addons/`, `check.ps1`, `scripts/check.sh`, or GitHub Actions.

## Why this is a handoff
The existing validated incoming importer explicitly denies `addons/` and runner file writes. No legitimate VNS5-03 Godot EditorPlugin installation can be done by a single direct incoming ZIP under current policy. This carrier produces a documentation-only candidate PR containing a reviewed implementation patch. Its incoming CI can pass while the plugin remains unchanged. **Do not merge the handoff PR as VNS5-03 implementation.**

## What changed since R1
- Main now contains merged PR #97 (62 owner-accepted character frames, character catalog, Stage Designer exact image selector, portraits A/B, and art smoke tests).
- Preserved all PR97 additions in `raven_asset_library.gd`, `check.ps1`, `scripts/check.sh`, `docs/STATUS.md` and progress records.
- New `vn_character_catalog.json` is included in staging's SHA locks, and smoke fixtures copy all four locked catalogs. Character group ID is limited to canonical characters, not individual art entries.
- Progress marks VNS5-02 merged, VNS5-03 in progress and GFX-06 implementation records merged; no owner/device acceptance inferred.
- Full patch has nine touched files and was applied/verified byte-for-byte against the reconstructed main source blobs. No Godot binary was available to run tests.

## After automatic incoming candidate PR
1. Give the candidate PR URL to an agent with GitHub connector/worktree and Godot access.
2. Agent reads `implementation.patch.txt` and SHA integrity, creates **a separate code branch from current main**, checks for newer main/PRs, applies patch **only after** `git apply --check`, and reconciles if main advanced again.
3. Run `godot --headless --editor --path . --quit`, staged smoke and the entire regular Godot 4.7.2 suite, data validators, PR governance, Windows UI/manual QA.
4. Agent opens normal `code/vns5-03-staged-image-import` PR with source files in original paths, updates docs/status/evidence, waits for CI on last head. Human merges manually after review. Do not use this docs-only candidate as implementation evidence.

Only one ZIP in the `incoming` folder at a time. Upload this ZIP directly (do not unpack), branch `incoming`, under `incoming/RM-VNS5-03_HANDOFF_R2.zip`. If main has moved, do NOT upload this stale ZIP; regenerate with the new `baseSha` and rebase the patch first. No secret/private UPDS donor materials are included.
