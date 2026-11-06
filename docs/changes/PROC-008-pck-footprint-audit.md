# PROC-008 — Godot Web PCK footprint audit (2026-11-06)

Task IDs: PROC-008 (qa-infrastructure; size and export scope follow-up). Base main `99c4032d44f02f8537d6ce48c232c44ca5a7b1ca`; gameplay source/asset art unmodified. One concurrent VN Studio PR owns a different domain.

## Verified baseline
- After PR #215, real main GitHub Pages `github-pages` artifact **136,484,446 bytes**; run https://github.com/bezdredoff/RavenManor-Godot/actions/runs/42279414770, all six functional jobs and deploy PASS.
- Previous artifact: **258,885,612 bytes** before #215. This measures full compressed Pages tar artifact, **not** standalone `index.pck`.
- The export uses `export_filter="all_resources"`. Its console log listed **477 package entries**: 116 imported textures in `.godot/imported/*.ctex`, 11 compiled scenes, 60 entries from editor-only `addons/vn_studio/` (30 .gdc and 30 remaps), 16 production status shard JSONs plus production planning data, and an example Builder JSON.
- Repository source art: ~40.10 MB `assets/raven/characters/` (62 accepted portraits), ~11.16 MB `assets/raven/vn_backgrounds/` (26 accepted backgrounds), ~13.13 MB `assets/raven/hall/`, ~3.44 MB Onoe/calibration assets and ~2.00 MB Match-3 art. These are **source byte counts**, NOT mapped `.ctex` contribution.
- Godot runtime loads character/background texture paths dynamically from `vn_character_catalog.json` and `vn_background_catalog.json` through `ResourceLoader`, and Hall's maps directly reference pilot textures. **Never exclude these folders or switch to selected-scenes mode without a complete dynamic asset reachability and Web device test.**
- Production runtime genuinely needs some `data/raven/production/` JSONs: `season1_dialogue_catalog.json`, `vn_character_catalog.json`, `vn_background_catalog.json`, `vn_staging.json`, `line_performance_cues.json`, `map_narrative_routes.json`, and `hotspot_popup_copy.json`; they remain untouched.

## Scoped optimization experiment
Exclude from the Web PCK (source remains in GitHub and all CI/editor checks remain):
- `addons/vn_studio/**` (native Godot EditorPlugin, no game runtime reference; remains available to editor in the repository)
- `data/raven/production/progress/**` plus work-package/backlog dashboards, active workstreams, P2 reentry policy, frozen production progress
- `examples/**` (draft Room Builder source fixture, not the generated runtime Hall scene)

The existing game JSON, authored routes, source imagery, imported Hall preview and Match-3/VN runtime remain included. This is a narrow export change, not a content deletion or approval of fewer assets.

## New CI instrumentation
`scripts/raven/tools/report_web_pck.py` parses *actual* Godot export log entries and imports. Reports exact `index.pck` bytes, `index.wasm` bytes, whole Web package bytes, dashboard bytes, number of packed entries, raw imported `.ctex` byte sizes by original source category, and top imported textures. Fails if excluded editor/progress/draft paths still appear in the PCK. The `.ctex` source breakdown is an **estimate of import contribution**, not compressed per-file PCK bytes. Prints in workflow log and job summary, creates no new uploaded artifact.

Unit test `scripts/raven/tools/test_report_web_pck.py` checks source remapping, counts, rejected unexpected exported files and missing logs. `web-package` still exports the whole functional game, bundles only dashboard and publishes existing `github-pages` artifact on main. No separate candidate uploads or new Pages copies.

## Verification and acceptance
- Local Godot and Python tests **NOT_RUN** by author; exact-head GitHub CI required: data-contracts, godot-runtime, room-builder, art-pipeline, web-package, aggregate build. CI will test actual excluded pack content and size; do not claim a saving until measured.
- Main Pages deploy test only after owner manually merges. Compare new artifact to **136,484,446 bytes** and inspect newly logged `index.pck` size.
- Device QA pending: game main menu, three VN/M3 beats, dialogue portraits and choice, RU/EN/BE, Continue/New game, optional Match-3 levels, Hall/Room Builder *game preview* through launcher, read-state/Save, all mobile browser paths. Native Godot VN Studio must still open/edit source project with plugin present; no automatic visual QA claim.

## Rollback
Revert export filter exclusions; keep harmless measurement tool or remove it separately. No saves, storyline, art approval, template or project engine configuration changed.
