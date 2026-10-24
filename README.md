# Raven Manor (Godot)

Cozy gothic-anime, portrait-first narrative restoration game.

**Repository status:** RM-HUB-001 PR 1 foundation and PR 2 navigation greybox are implemented and tested on dependent review branches. PR 3 integration has not started.

Read `AGENTS.md`, `docs/PROJECT_CONTEXT.md`, and `docs/IMPLEMENTATION_PLAN.md` before changes.

Approved source packages: Stage 1 v0.5, Stage 2 v0.2; Stage 3 research v0.2 is a planning baseline. Product-owner decisions in `docs/DECISIONS.md` supersede older conflicting design contracts. Only the small atomic filesystem storage adapter was adapted from UPDS; Raven state, IDs and reducer remain isolated.

## Verify

```powershell
.\check.ps1 -GodotPath "C:\path\to\Godot_v4.7.2-stable_win64.exe"
```

See `docs/RM_HUB_001_FOUNDATION.md` for the save schema and event API.
See `docs/RM_HUB_001_NAVIGATION.md` for authored graph and greybox extension instructions.
