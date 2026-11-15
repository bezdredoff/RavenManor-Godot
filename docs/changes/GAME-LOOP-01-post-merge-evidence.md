# GAME-LOOP-01 — post-merge evidence reconciliation for #259 (2026-11-15)

Task IDs: GAME-LOOP-01 (campaign-core, P0 parent, remains ready/partial). Bounded slice
GAME-LOOP-01A is recorded as evidence only and is not added as a canonical backlog ID; the parent
stays open.

Changes: Evidence-only reconciliation of `data/raven/production/progress/campaign-core.json`. The
`GAME-LOOP-01` entry previously described PR #259 as a DRAFT that was not merged. It now records the
verified merge. No runtime, bridge, scene, save-schema, reducer, catalog or geometry file is touched.

Verification: GitHub REST API and git history checked at `main`
f0d2264e771be90f672a052dc9c169ee944607c4 with a clean working tree.

- PR #259 (GAME-LOOP-01A hotspot QA bridge): `merged=true`, head
  d630d0c0fbb7021a9042cc32d59a39ce2c3f7027, merge commit
  9cfad9f4682f7598dc1fa94de908245f53e07914; exact-head CI run 43756255635 PASS.
- Post-merge main CI run 43759282546 at f0d2264 PASS in all seven jobs, including godot-runtime.
- The merged slice remains the explicit in-memory TEST_ONLY greybox path
  RM-HS-005 -> real Match-3 UI -> RM-HS-002 -> VN through the single
  `RavenCampaignStore`/`RavenReducer`, with a new bridge and smoke.
- Code inspection at this head: `raven_hotspot_gameplay_bridge.gd` still preloads and reconstructs
  `ManorNavigationGraph`/`RouteSession` from the historical greybox and does not call
  `manor_navigation_source.resolve()`. That duplication is a real, recorded follow-up gap.
- Local validation: `python scripts/raven/tools/progress_shards.py` and
  `python scripts/raven/tools/build_production_dashboard.py --check` executed before opening the PR;
  exact-head GitHub Actions remains the merge gate.
- This evidence PR #263 exact-head CI run 43760079652 PASS in all six required jobs (data-contracts,
  room-builder, godot-runtime, art-pipeline, web-package, build; deploy skipped on PR).

Owner QA: Not run and not claimed. No human/device playthrough, physical Hall door alignment,
art calibration or production map approval is implied by the merged QA slice.

Status impact: `GAME-LOOP-01` stays `ready` / `implementationState=partial` / P0. Only this
campaign-core shard plus this evidence record change. This bookkeeping PR is not parent-task review.
No production navigation is enabled; the
canonical greybox still fails closed as `unavailable_geometry`, and the QA candidate still requires
explicit `allowQaCandidate`. Converging the bridge onto `manor_navigation_source` and removing the
duplicate graph/session construction is scoped as a separate cross-domain PR.
