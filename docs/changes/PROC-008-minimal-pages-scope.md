# PROC-008 — minimal public Pages scope (2026-11-06)

Task IDs: PROC-008 (qa-infrastructure follow-up to merged single-publisher PR #213; deployment scope only; dashboard remains optional).

Changes: Retain only the Godot Web export root and generated `build/web/dashboard/` in Pages. Remove Art Handbook, Room Builder and candidate portal packaging steps from `web-package`. Continue CI verification of Room Builder JS/Python/browser, Art Handbook provenance/unit/browser and all Godot runtime/game functionality. Remove a redundant Art Handbook site/ZIP bundle from the independent art job; its real archive generation remains validated by existing isolated unit tests. Retain explicit-dispatch candidate Web artifact behavior, which is separate from Pages. Check forbidden destination directories do not exist, report payload sizes without another artifact. Update Dashboard navigation and README/Pages documentation to avoid publishing dead links.

Verification: Baseline main `e36161b2725516d9e8f1c8830556276f383af385`, zero open PRs. Prior exact-main run 42276926859 for #213 confirmed Pages source preflight and deploy SUCCESS on earlier commit. No local Godot/browser build; PR exact-head CI must pass all six mandatory jobs. Real reduction must be measured from the next successful main `github-pages` artifact after merge, not guessed from source sizes.

Owner QA: After merge, open the game root and `/dashboard/`, confirm locale and assets work. `/builder/`, `/art-handbook/` and `/preview/` are **intentionally not deployed**; source/tools remain available via GitHub or locally. Validate candidate workflow explicitly when needed. No mobile-device artistic acceptance implied.

Status impact: No gameplay/story/task closure; no status shards touched. This is a bounded Pages/publishing policy update owned by integration/QA infrastructure.

Risk: Old public links to the three tool pages will no longer serve those pages. Dashboard stays public for now and is independent of Godot. If a separate authoring-tool site is wanted later, deploy it under a separate, explicit hosting plan; do not silently reintroduce duplicate assets to the main Pages artifact.

Rollback: Restore packaging steps from previous main if publisher requirements change; do not disable CI gates or change Godot runtime.
