# Agent instructions — Raven Manor Godot

Read `docs/PROJECT_CONTEXT.md`, `docs/DECISIONS.md`, `docs/NARRATIVE_GAMEPLAY_INTEGRATION.md`, `docs/IMPLEMENTATION_PLAN.md`, then relevant Stage 1–3 specifications and audits before making changes.

## Authority
1. Explicit product-owner decisions in `docs/DECISIONS.md`.
2. Stage 1 v0.5 / Stage 2 v0.2 approved baseline except clauses explicitly superseded.
3. Stage 3 v0.2 research (planning evidence; not tested runtime).
4. Audits of *UPDS-godot*, not evidence that Raven implementation exists here.
Do not silently reconcile contradictory source files. Preserve historical source and record active override.

## Implementation rules
- Preserve established `RM-*` identifiers, including deprecated aliases. Validate catalog references.
- Godot 4.7.2 and GDScript are the target; no engine migration or third-party addon without evidence of need.
- This repo begins documentation-only; reuse/import UPDS VN, Match-3, saves and catalog deliberately, with attribution and isolation, never assume present.
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
