# Raven Manor Prototype Lab and GitHub Pages

## Purpose

`scenes/raven/prototype_launcher.tscn` is the single entry point for all interactive Raven Manor engineering prototypes. It is also the page exported to the Web build.

Available modes:

1. **Foundation sandbox** — manipulate the shared Raven snapshot: three first-clear rewards, early bedroom access, two restorations, specialist flag, save, reload and reset.
2. **Navigation greybox** — inspect Hall → Corridor → Bedroom graph traversal, locked/unlocked bedroom route, foreground and camera behavior.
3. **Combined flow** — make state changes in the sandbox and continue to the map. Both scenes use the same Raven save namespace, so the navigation graph rebuilds from the saved door state.

This combined mode is not `RM-VS-01` PR 3: Match-3 and VN are not integrated yet, and the launcher says so explicitly.

## Local run

Open `project.godot` with Godot 4.7.2 and run the project, or start it from the command line. The launcher is the configured main scene.

Run all checks:

```powershell
.\check.ps1 -GodotPath "C:\path\to\Godot_v4.7.2-stable_win64.exe"
```

Local Web export:

```powershell
.\scripts\export-web.ps1 -GodotPath "C:\path\to\Godot_v4.7.2-stable_win64.exe"
```

Godot export templates for 4.7.2 must be installed.

## GitHub Pages

`.github/workflows/pages.yml` runs on pull requests and `main`:

- installs the pinned Godot 4.7.2 editor and matching Web templates;
- runs `scripts/check.sh`;
- exports the `GitHub Pages Web` preset;
- uploads the Web artifact;
- deploys only for non-PR runs.

The repository Pages build type is `workflow`. A push to `main` publishes the latest verified Prototype Lab.

## Adding another prototype

1. Add its runtime under `scripts/raven/` and scene under `scenes/raven/`.
2. Add a card/button in `prototype_launcher.gd`.
3. Add the scene path to `prototype_lab_smoke.gd`.
4. If it shares progression, use `RavenCampaignStore`; otherwise document its isolation.
5. Run checks and perform a local Web export before opening the PR.
