# VNS5-07F2 — HTML v5 handoff recovered; Director scene/ID finder slice

Task IDs: VNS5-07F2 (scoped visual/workflow parity), VN-EDITOR-07 (post-merge reconciliation of #210; broad task remains partial).
Changes: Add a case-insensitive scene/ID finder above the native Raven Story scene list. Resolve filtered ItemList selection through a mapping to canonical scene indices; keep scene, line, stage and Story Map stable on zero results. Clearing the finder restores the current selection; creating a new scene clears the filter to show the new item. Add headless UI regression.
Verification: The user-provided handoff ZIP passes 31/31 SHA-256 manifest checks; `tools/validate_handoff.py` validates the proposed synthetic fixtures. Chromium rendered the actual HTML v5 Director, Library, Story Map, Animation at 1366×768 and Story Map at 1024×640 without JS page errors. Godot CLI not locally installed; exact PR-head CI pending at authoring. Rendering HTML does not equal rendering Godot.
Owner QA: Native Godot 4.7.2 Windows comparison and screenshot pair at 1024×640, 1366×768 pending. Full HTML pixel parity NOT accepted; original Godot screenshot not provided. Check finder by ID/title, casefold, zero-result, clear and creating a scene under an active filter.
Status impact: #210 marked delivered in VN-EDITOR-07 history but parent stays partial. VNS5-07F2 becomes PR_review for a **small** feature slice; remains partial/manual unverified, not a closed visual-parity task.

## Source and provenance

- Owner-provided: `Raven_VN_Studio_Godot_Handoff_v5_2026-11-01.zip` (dated 2026-11-01).
- HTML UX reference: `prototype/raven_vn_studio_v5.html`, SHA-256 `b79749e74a49ce3fe8319146c966317febbad06f2aec88167362aaa800e070ba`; Story Map entrance `prototype/raven_vn_studio_v5_story_authoring.html`, SHA-256 `9c4951de182896bd1fbae3ac4240532fee80b433af91aa3badaa734e2403ae24`.
- The historical handoff mentions `docs/STATUS.md` and frozen `production_progress.json` as writable. **Superseded by current root/nested AGENTS and shard governance**: only `data/raven/production/progress/vn-studio.json` is mutated here.
- Current source baseline: `bezdredoff/RavenManor-Godot@99c4032d44f02f8537d6ce48c232c44ca5a7b1ca`.
- Private UPDS donor baseline: `bezdredoff/UPDS-godot@3deed628efd6c22bcd1717f7c545b7d3ca865781`. The donor does not provide this Raven-specific editor list filtering; reuse decision **new editor-only UI behavior**, not a duplicate runtime or StorySession.

## Verified HTML → native Raven capability/gap matrix

| HTML v5 contract | Current native Raven Studio evidence | Scope/outstanding |
|---|---|---|
| Four named workspaces A/B/C/D, shared scene/line context | `raven_story_view.gd` has Stage Inspector, Library, Translations, Story Map, Animation, Promotion Review; central `_stage_column` persists across inspector tabs | Partly implemented, not visually identical top-level tabs |
| Director left column scene+line outline with **scene search** | Native has separate Scene and Line columns; no `LineEdit` finder at audit baseline | **This PR** adds finder without changing layout; full 3-column refactor still open |
| Persistent centered portrait or landscape preview, right contextual Inspector | `raven_stage_designer.gd` uses real scene plates and actors; central Stage persists. Right has tabbed inspectors | Working source-level features, visual/pixel comparison still pending |
| Library category/group/status search; A/B image compare with draggable wipe | `raven_asset_library.gd` has category/status/orientation/group filters and two static A/B TextureRects | No draggable before/after slider as shown in HTML; prop library deferred by owner |
| Story Map branches and scene authoring | `raven_story_graph_view.gd`, authoring model, scene/line wizard, condition and endings, tests | Editor-only; no automatic runtime branch promotion or owner screenshot parity |
| Animation tracks, scrub, phase FX, Undo | `raven_fx_timeline.gd` and stage FX inspector have three lanes, 50 ms arrow nudges; smoke | Native controls differ from HTML; real image-layer blinking not approved |
| 1024×640 and 1366×768 references | HTML screenshots rendered from user ZIP without JS errors | Paired native Editor screenshots still required; do not claim pixel parity |

The HTML contains browser-only mock media, locally staged assets and authoring export format `raven-vn-studio-UX-authoring-v5`; do not promote to current Raven schema or production narrative. 2026-11-03 owner decision defers separate VN prop catalog: HTML props are not a mandate to reintroduce it.

## This PR's acceptance

1. With a 28+ scene project, type `RM-BEAT-01-01` or an RU title: filter matches actual scene data (not only list labels). Case-insensitive.
2. Selecting filtered visible row 0 resolves canonical scene 3 and updates Stage/Story Map. No accidental edit of original scene index 0.
3. Zero matches leaves the current context untouched and unselected list; clearing search restores full count and highlights selected scene.
4. Creating new draft scene while filtered shows the new scene (filter cleared); removing/undoing drafts remains safe.
5. No edits to original story IDs, stage/graph models, runtime, donor sources or assets. No manual UX acceptance inferred from CI.

### Tests and rollback
Godot headless: `scripts/check.sh` invokes `res://tests/raven/vn_studio_layout_smoke.gd`. Run full six-check GitHub Actions on this exact PR head. Manual Godot 4.7.2 reviewer should test the native finder and send 1024×640 / 1366×768 matched screenshots.

Rollback: revert this PR; no draft schema or migration.
