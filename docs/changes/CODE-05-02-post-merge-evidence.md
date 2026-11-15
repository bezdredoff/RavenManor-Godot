# CODE-05-02 — post-merge evidence reconciliation for #260/#261 (2026-11-15)

Task IDs: CODE-05-02 (manor-map, P0 parent, remains partial). Bounded slices MAP-GAME-01A and
MAP-QA-09B are recorded here as evidence only; neither is promoted to a canonical backlog ID and
neither closes the parent.

Changes: Evidence/status-only reconciliation of `data/raven/production/progress/manor-map.json`.
Verified and recorded the actual merge state of the two most recent manor-map PRs, replacing stale
`PR_review` / "open, not merged" text. The parent entry moves from `PR_review` to `ready` because the
PRs it referenced are merged; this evidence-only PR is not parent-task review. `implementationState`
stays `partial`, `qaState` stays `automated`, priority stays `P0`. No runtime, navigation, geometry,
collider, scene, save-schema, catalog or art file is touched.

Verification: GitHub REST API and git history checked at `main` f0d2264e771be90f672a052dc9c169ee944607c4
with a clean working tree.

- PR #260 (MAP-GAME-01A navigation-source boundary): `merged=true`, head
  58bdc1e4f8304294d03a9ca866867a7ead485c92, merge commit
  d2fd55625e6af1c7f8448cceb8458ada1d77b990; exact-head CI run 43757540481 PASS.
- PR #261 (MAP-QA-09B opening blueprint): `merged=true`, head
  d1e4397ec68935b04fe0f48bbf2888ae8affbdb3, merge commit
  f0d2264e771be90f672a052dc9c169ee944607c4; exact-head CI run 43759111860 PASS and post-merge main
  CI run 43759282546 PASS in all seven jobs (data-contracts, room-builder, godot-runtime,
  art-pipeline, web-package, build, deploy).
- No open PRs and only `main`/`incoming` remote branches at review time; the three registrations
  MAP-GAME-01A, MAP-QA-09B and GAME-LOOP-01A are still present exactly once in `scripts/check.sh`.
- Local validation: `python scripts/raven/tools/progress_shards.py` and
  `python scripts/raven/tools/build_production_dashboard.py --check` executed before opening the PR;
  exact-head GitHub Actions remains the merge gate.
- This evidence PR #262 exact-head CI run 43760078971 PASS in data-contracts, room-builder,
  godot-runtime, art-pipeline, web-package and build (deploy skipped on PR).

Owner QA: Not run and not claimed. Physical door positions/footpoints, HA/HC/CB/CK shared sills,
the proposed HC underpass and CK service vestibule, room-art calibration, elevation and foreground
masks are still owner/art/device decisions. MAP-QA-09B contacts remain TEST_ONLY /
AI_PROPOSED_ARCHITECTURE with initially closed gates. Merged CI proves tests, not art or device
acceptance.

Status impact: `CODE-05-02` remains P0 partial; only this manor-map shard plus this evidence record
change, and this bookkeeping PR is not parent-task review. Production movement stays disabled because the canonical greybox still resolves as
`unavailable_geometry` with a hold, and QA candidate navigation still requires explicit
`allowQaCandidate`. Known follow-up gap: `raven_hotspot_gameplay_bridge.gd` (GAME-LOOP-01A,
campaign-core) still builds `ManorNavigationGraph`/`RouteSession` directly instead of consuming
`manor_navigation_source`; converging it is a separate cross-domain PR, not part of this
reconciliation.
