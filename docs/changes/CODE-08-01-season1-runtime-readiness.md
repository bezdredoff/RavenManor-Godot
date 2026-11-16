# CODE-08-01 — Season 1 runtime readiness

Task IDs: CODE-08-01, VN-RUNTIME-01, CODE-03-01, CODE-03-02, CODE-03-03

Changes: Harden synthetic approved-scene dispatcher ordinal and snapshot gate validation; canonical scene approvals remain unchanged.
Verification: Prior exact-head CI 43957056367 FAILED on GDScript test parse and governance fields; new-head CI must execute the Godot runtime suite before merge.
Owner QA: NOT_RUN; no physical devices, production VN scene promotion or owner content acceptance.
Status impact: Canonical CODE-08-01 stays ready / partial in campaign-core; this VN-runtime PR records supporting evidence on VN-RUNTIME-01, without duplicating the task ID.

## Changes

- Fixed production dispatcher ordinal decoding: JSON integral floats are accepted, while fractional, negative, non-numeric, out-of-range and ambiguous duplicate ordinals are rejected.
- Added only snapshot-backed gate evaluations: `auto_new_game`, `scene_complete`, `first_clear`, `restoration_done`, and `clue_recorded`. Unknown, interaction, specialist, time and post-credit gates remain fail-closed.
- Added regression coverage for synthetic approved selection, RU/BE/EN resolution, approval/art/line/cue gates, ordinal validation, duplicate ordering, supported gates and unsupported gates. Synthetic catalogs are deep copies and do not touch canonical assets or saves.
- Added the Chapter II–III integration manifest and promotion evidence contract in `docs/changes/CODE-08-01-chapters-II-III-readiness.md`.

## Verification

- Base after PR #266: `832657c`; `origin/main` was unchanged at audit time.
- UPDS reuse provenance: `bezdredoff/UPDS-godot` main `3deed628efd6c22bcd1717f7c545b7d3ca865781`, VN shell path `scripts/vn/vn_screen.gd`; Raven retains the existing adapted paging/read-only Skip contract and Raven reducer/store authority. No UPDS story IDs or assets were imported.
- Run: `godot --headless --path . --script res://tests/raven/vn_production_runtime_dispatch_smoke.gd --quit-after 600`.
- Run the repository PowerShell test runner and the VN runtime shard in CI; record exact head/URL before merge.

## Owner QA

Not performed. Device, owner visual, native save/relaunch and real approved-scene QA remain required. Canonical production scene statuses, route registry, foundation catalog, staging, portraits and cues were not edited.

## Status impact

`CODE-08-01` remains `ready` / `partial` in its authoritative `campaign-core` shard; this PR updates only `VN-RUNTIME-01` evidence in the `vn-runtime` shard. Task closeout belongs to the campaign-core owner after merge. The real 20 unfinished scenes remain unapproved; this PR proves only synthetic selection and prepares a traceable Agent B handoff.


## Post-#273 regression revalidation

Merged #273 corrects the prior false foreign-shard detection for PRs authored before main advanced. New run required at this PR's current head to validate both strict governance and production dispatcher tests. Historical run `43962825851` passed Godot runtime after its old hardcoded JSON-ordinal positive control was updated, but failed the obsolete PR-base governance gate. No authored production scene approval is implied; all proposed Chapter II–III scene gates and content approvals stay fail-closed. As of this note, PR #271 is still open, not merged.


## Sharded-ledger correction (2026-11-16)

Previous CI exposed an actual duplicate task ID across campaign-core and vn-runtime. The authoritative `CODE-08-01` task and `WS-CAMPAIGN` assignment were already present in `data/raven/production/progress/campaign-core.json`; this agent does not own that shared integration ledger. Removed the accidental duplicate entry and `WS-VN-STUDIO` assignment from the local vn-runtime shard. Added supporting PR #271 evidence to existing `VN-RUNTIME-01` without closing that parent. Tests: `progress_shards.py` and complete exact-head CI pending; owner/device and authored scene approvals remain unclaimed.
