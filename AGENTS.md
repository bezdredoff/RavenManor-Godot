# Agent instructions — Raven Manor Godot

Read `docs/PROJECT_CONTEXT.md`, `docs/DECISIONS.md`, `docs/NARRATIVE_GAMEPLAY_INTEGRATION.md`, `docs/IMPLEMENTATION_PLAN.md`, then the paired `docs/production/GRAPHICS_PRODUCTION_ROADMAP_RU.md` and `docs/production/CODE_PRODUCTION_ROADMAP_RU.md` for any production implementation, and relevant Stage 1–3 specs/audits. Roadmaps are **plans**, not evidence that functionality has shipped.

## Authority
1. Explicit product-owner decisions in `docs/DECISIONS.md`.
2. Stage 1 v0.5 / Stage 2 v0.2 approved baseline except clauses explicitly superseded.
3. Stage 3 v0.2 research (planning evidence; not tested runtime).
4. Audits of *UPDS-godot*, not evidence that Raven implementation exists here.
Do not silently reconcile contradictory source files. Preserve historical source and record active override.

## Implementation rules
- Preserve established `RM-*` identifiers, including deprecated aliases. Validate catalog references.
- Godot 4.7.2 and GDScript are the target; no engine migration or third-party addon without evidence of need.
- Raven is now an executable Godot project. Treat UPDS-godot as the source of reusable VN, Match-3, settings, input, animation/audio, responsive and test patterns. Before new gameplay/UI code, verify whether it already exists in UPDS. Prefer source-preserving import/extraction + Raven data/theme adapters; pin upstream blob SHA and test parity. Avoid a second Raven-only copy of proven rules.
- Raven-specific engineering owns the authored manor map, hotspot/door routes, room/prop/NPC state, restoration and specialist-gated metaprogression. Only Raven reducer/store own authoritative campaign state; do not import UPDS story progression or introduce a second save authority.
- PR #46 is an *open, proposed* upstream core migration at roadmap creation time, not a merged main baseline. Check actual status before implementing work from this plan.
- No free tap-to-move. Players click hotspots/doors, then travel on connected, authored navigation anchors along plausible routes. Use reusable graph traversal, not unique hardcoded waypoint scripts for each target.
- Bedroom entry MUST NOT depend on bathroom repair. Bedroom restoration occurs after physical entry.
- Doors may remain permanently open or visually disappear once unlocked; physical portal, foreground, collision and save states remain correct.
- Bathroom is a corridor-side vignette in `RM-VS-01`, not required as a full walkable scene.
- Temporary Onoe UPDS artwork is a technical placeholder only; final characters require unified anime-style approval. Check provenance/rights before importing.
- Modular, content-driven Raven runtime; separated Raven save schema and atomic/idempotent reward, restoration and beat events.
- No toolkit publication or mass production-art generation until integrated greybox and style approval.
- Keep code clean and human-readable, with documented APIs, naming, state transitions, setup, extension and debugging instructions.
- Each PR: tests actually run, affected IDs, save migration, documentation updates, risks and acceptance evidence. Do not claim unexecuted tests pass.
- Work in small PRs, do not overwrite the main baseline; PR 2 depends on PR 1 acceptance and PR 3 depends on PR 2 acceptance.

- Match-3 is preparation work in fiction; specialist repairs remain specialist work. Do not use room art, navigation importers or Match-3 completion to invent story-state mutations outside the documented reducer events.

## Hygiene
Never commit credentials, local saves, Godot import caches, unlicensed assets, unrelated UPDS story content or generated build outputs.
