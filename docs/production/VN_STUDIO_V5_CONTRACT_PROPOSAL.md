# VNS5-00 — native VN Studio v5 contract baseline (proposal)

Baseline: `bezdredoff/RavenManor-Godot` `origin/main` `9b0cbcc6d5c080b47ac43c6881161a6aa018ac4d` (2026-11-01). At branch creation there were no open PRs. Donor `bezdredoff/UPDS-godot` HEAD `3deed628efd6c22bcd1717f7c545b7d3ca865781`; `scripts/core/story_session.gd` blob `ac926a6fcdcbd359cdc4a36081d02be8cd7ebe02`. The donor audit on a clean detached worktree passed: 45 scenes, 1,026 line occurrences, 213 hidden occurrences, RU/BE/EN, 22 Match-3 gates, 8 choice gates and 3 endings. The pre-existing local donor checkout is dirty (including `data/save_contract.json`) and fails the pinned-manifest hash; it was not altered or used as parity evidence. Donor is read-only. No private script, artwork or save is copied here.

## Current implementation and reuse decision

`addons/vn_studio/plugin.gd` and `editor/studio_view.gd` already provide the native Godot EditorPlugin. `raven_story_store.gd` loads the canonical dialogue, staging, routes, cues and cast with source SHA locks; `raven_story_view.gd` and `raven_stage_designer.gd` provide Raven editing and stage preview. `draft_store.gd`, `legacy_reader.gd`, `story_graph_view.gd`, and `conversion_bundle.gd` cover private UPDS read-only inspection and versioned local overlays. `scripts/raven/raven_vn_game_view.gd` and `raven_vn_backgrounds.gd` are the runtime display components to reuse later. VNS5-00 adds a **new read-only structural adapter audit**, not another editor or renderer. UPDS StorySession remains an independent future parity oracle, not a copied implementation.

Run `py scripts/raven/tools/audit_vns5_contract.py --root .` for exact source SHA256s and IDs. At baseline: 28 scenes, 280 lines, 11 masters, 28 shots, 20 candidate background variants, 4 character definitions, 280 cues and 28 route triggers. The adapter preserves scene and line order/IDs and emits empty `transitions`: scene order, map triggers and line cues do not establish v2 graph edges. It creates no files, drafts, saves or `res://` changes.

## Contract decisions pending owner review

- Keep `raven-vn-studio-draft-v1` and `vn-studio-legacy-overlay-v1` readable; a v2 draft gets a new format/path and copy migration only. Current SHA locks must fail closed on source drift.
- Stable existing `RM-*` and UPDS `VN####` IDs are immutable. New line/instance ID allocation, typed transition enums, reducer flag names, Match-3 level mapping, clip arbitration and promotion format need separate review and tests before becoming runtime schema.
- RU/BE/EN content, hidden directions, candidate art status and original paths remain source-owned. Missing locale or art is displayed as missing/fallback, not fabricated.
- The handoff JSON Schemas and synthetic fixtures are proposal examples, not canonical data. No v2 runtime switch, game save migration or new choice topology is authorized by this audit.

Rollback: revert this document, audit and tests; no canonical game data has been modified. Godot desktop visual QA and independent UPDS 45-scene StorySession parity remain pending.
