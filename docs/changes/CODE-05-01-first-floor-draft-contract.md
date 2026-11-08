# CODE-05-01 — First-floor art/map draft import contract v2

Task IDs: CODE-05-01 (room-builder). Related RM-GAP-001 is integration-only, untouched.
**Base SHA:** 4c4145a935419b5cfaa69e8e1bde90a71717ed7a (2026-11-08). No open PR at audit time.
**Owner:** room-builder.
Changes: Add firstFloorDraft schemaVersion=2 optional extension to schemaVersion=1 Room Builder; load/edit full-floor PNG calibration, room outlines, door points and read-only nav anchors; strict JS/Python validation; isolated deterministic Godot draft scene and machine-readable JSON; Node/Python/browser regressions and mirrored PWA files.
**Reference authority:** data/raven/season1_world_map.json (proposed only), Agent A owns actual full-floor art/geometry/pivots, Agent C owns navigation topology. The current 1×1 PNG fixture is test-only.
**Compatibility:** Legacy v1 docs still validated/imported as before. The v2 path is opt-in; missing/unknown IDs and assets fail, no automatic coordinate repair or silent fallback. All generated outputs live under scenes/raven/generated and assets/raven/generated; they do NOT attach to canonical runtime.
**Out of scope:** No edits to project.godot, core reducer/store/snapshot, canonical map scenes, authored navigation graph, collisions, campaign state, workflows or other status shards.
Verification: Node/Python tests authored, not executed locally (checkout/network unavailable to this tool session); exact-head GitHub Actions results to be appended once observed. Godot generated first-floor scene smoke NOT_RUN locally. Browser/touch/tablet/S Pen QA NOT_RUN. Existing test suite and Godot baseline remain separate evidence gates.
Owner QA: Await image-manifest from Agent A, navigation contract from Agent C, actual image scale/rights confirmation, visual alignment review and explicit geometry/device acceptance; no inferred approval.
Status impact: CODE-05-01 remains P0 partial and PR_review once PR exists; NOT merged/accepted. RM-GAP-001 remains untouched.
**Rollback:** Revert the scoped PR; existing v1 room JSON and canonical game assets remain unchanged.

## 2026-11-08 follow-up — raw Agent A v1 interoperability and mergeability

Task IDs: CODE-05-01 (room-builder); GFX-08-08 only as cross-agent read-only input; RM-GAP-001 remains integration-only.

Changes:
- Inspected A's PR #239 manifest `raven.first-floor-art` v1 and its comment in #240. Added read-only validator/adapter with preserved original manifest and real source PNG fingerprint checks. No modifications to Agent A's manifest or progress shard.
- Distinct typed spaces `image-pixel`, `world-plan`, `screen-projected` and preserved `independent_greybox`. For unresolved registration, PNG is rendered at pixel dimensions, world-plan overlays are hidden. No synthetic corner registration, pixel navigation or copying `RM-ASSET-*` to foreground instances.
- Frozen v1 producer sample in tests/fixtures/ plus Node/Python integration, source path/hash/size, wrong schema, duplicate IDs, mismatched controls and door association regressions.
- Original source PNG is measured read-only in the existing importer CI suite (Git blob SHA pinned); art bytes remain unchanged.

Verification:
- GitHub REST API checked #240 `mergeable=true`, `mergeable_state=clean`, current main/base both `4c4145a935419b5cfaa69e8e1bde90a71717ed7a`. Earlier `mergeable:false` is not currently reproducible; GitHub offers no historical conflict file list for that stale observation. Do not report a solved file conflict without evidence.
- Existing exact-head run 42497980190 succeeded before this follow-up. Follow-up exact-head CI is required on the final SHA; local repo checkout blocked by network DNS, hence local full project tests NOT_RUN. Individual generated first-floor Godot F6 and mobile/touch QA NOT_RUN, not inferred from baseline Godot smoke.

Owner QA:
- Agent A must confirm actual painting spatial registration and rights, alpha/occlusion cutouts and four or more non-collinear floor fiducials. Agent C must validate movement in its own coordinate authority; no automatic nav/geometry promotion.

Status impact:
- CODE-05-01 stays P0 partial/PR_review, not accepted. PR #240 remains open without auto-merge. Other domain shards unchanged.
