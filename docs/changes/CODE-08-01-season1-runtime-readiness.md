# CODE-08-01 — Season 1 runtime readiness

Task IDs: CODE-08-01, VN-RUNTIME-01, CODE-03-01, CODE-03-02, CODE-03-03

Changes: Harden synthetic approved-scene dispatcher ordinal and snapshot gate validation; canonical scene approvals remain unchanged.
Verification: Prior exact-head CI 43957056367 FAILED on GDScript test parse and governance fields; new-head CI must execute the Godot runtime suite before merge.
Owner QA: NOT_RUN; no physical devices, production VN scene promotion or owner content acceptance.
Status impact: CODE-08-01 remains PR_review / partial / automated-only evidence.

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

`CODE-08-01` is `PR_review` / `partial` / automated evidence only. The real 20 unfinished scenes remain unapproved; this PR proves only synthetic selection and prepares a traceable Agent B handoff.
