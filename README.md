# Raven Manor (Godot)

Cozy gothic-anime, portrait-first narrative restoration game.

[Launch the interactive Prototype Lab](https://bezdredoff.github.io/RavenManor-Godot/)

Game bible, narrative/design source and production materials live in [bezdredoff/RavenManor](https://github.com/bezdredoff/RavenManor). This repository contains the Godot runtime, tests and Web deployment.

**Repository status (2026-10-26):** RM-HUB-001 and integrated RM-VS-01, Content Preview, continuous season-one map feasibility mode, mobile Room Builder PWA v0.2, and experimental Hall AI1/AI2 art comparison are implemented and published. The game art, true Hall spatial calibration and authoring-to-gameplay bridge are not yet production-approved. Next work: `RM-PIPE-001`.

Open the [touch-first Room Builder PWA](https://bezdredoff.github.io/RavenManor-Godot/builder/index.html) for draft room layout (Android/tablet/desktop). It links 120 proposed catalog positions across eight rooms, saves room-specific local drafts and exports JSON/PNG. Output is not yet a calibrated gameplay scene.

Read `AGENTS.md`, `docs/PROJECT_CONTEXT.md`, and `docs/IMPLEMENTATION_PLAN.md` before changes.

Approved source packages: Stage 1 v0.5, Stage 2 v0.2; Stage 3 research v0.2 is a planning baseline. Product-owner decisions in `docs/DECISIONS.md` supersede older conflicting design contracts. The storage, Match-3 contract and VN line player are narrowly adapted from proven UPDS patterns; Raven data, state, IDs and reducer remain isolated.

## Verify

```powershell
.\check.ps1 -GodotPath "C:\path\to\Godot_v4.7.2-stable_win64.exe"
```

See `docs/NARRATIVE_GAMEPLAY_INTEGRATION.md` for the current story canon mirrored into gameplay, reveal rules and the exact RM-VS-01 narrative mapping.
See `docs/RM_HUB_001_FOUNDATION.md` for the save schema and event API.
See `docs/RM_HUB_001_NAVIGATION.md` for authored graph and greybox extension instructions.
See `docs/PROTOTYPE_LAB_AND_PAGES.md` for the shared prototype launcher, Web export and GitHub Pages deployment.
See `docs/QUICKSTART_PREVIEWS.md` for exact Match-3/VN IDs, isolated preview controls, full-flow launch and save/reset instructions.
See `docs/STATUS.md` for canonical current status, `docs/NEXT_PLAN.md` for priority order, and `docs/ROOM_PIPELINE_NEXT_GATE.md` for the next room-production acceptance gate.

## Season 1 production preparation (PR #44)

Full scene/asset/map production shotlist: `docs/production/SEASON1_VISUAL_MAP_AND_PROP_PRODUCTION.md`. RU/BE/EN source review and translation plan: `docs/production/LOCALIZATION_UPDS_ADAPTATION.md`. Machine-readable **planning** registries live under `data/raven/production/`: character performance, 28 scene shots and 280 line cues, 37 prop families, 28 popup translations, 28 narrative routes and full Russian source dialogues. New chapters' event IDs and world-map/NPC anchors are **not yet runtime-authored or art-calibrated**; this PR does not implement the full season. Use `python3 scripts/raven/tools/validate_production_narrative.py` to check contracts, and `--release` to require complete BE/EN translations (not yet supplied). `python3 scripts/raven/tools/export_translation_worklist.py` creates a translator-friendly CSV.
