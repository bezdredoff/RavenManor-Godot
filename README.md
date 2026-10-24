# Raven Manor (Godot)

Cozy gothic-anime, portrait-first narrative restoration game.

[Launch the interactive Prototype Lab](https://bezdredoff.github.io/RavenManor-Godot/)

Game bible, narrative/design source and production materials live in [bezdredoff/RavenManor](https://github.com/bezdredoff/RavenManor). This repository contains the Godot runtime, tests and Web deployment.

**Repository status:** RM-HUB-001 foundation, navigation greybox, universal Prototype Lab/Pages delivery and the integrated RM-VS-01 are implemented. PR 3 adds Raven VN, deterministic Match-3, restorations, clue, night episode and reload-safe progression.

Read `AGENTS.md`, `docs/PROJECT_CONTEXT.md`, and `docs/IMPLEMENTATION_PLAN.md` before changes.

Approved source packages: Stage 1 v0.5, Stage 2 v0.2; Stage 3 research v0.2 is a planning baseline. Product-owner decisions in `docs/DECISIONS.md` supersede older conflicting design contracts. The storage, Match-3 contract and VN line player are narrowly adapted from proven UPDS patterns; Raven data, state, IDs and reducer remain isolated.

## Verify

```powershell
.\check.ps1 -GodotPath "C:\path\to\Godot_v4.7.2-stable_win64.exe"
```

See `docs/RM_HUB_001_FOUNDATION.md` for the save schema and event API.
See `docs/RM_HUB_001_NAVIGATION.md` for authored graph and greybox extension instructions.
See `docs/PROTOTYPE_LAB_AND_PAGES.md` for the shared prototype launcher, Web export and GitHub Pages deployment.
See `docs/QUICKSTART_PREVIEWS.md` for exact Match-3/VN IDs, isolated preview controls, full-flow launch and save/reset instructions.
See `docs/STATUS.md` for canonical current status and `docs/NEXT_PLAN.md` for the reconciled next gates.
