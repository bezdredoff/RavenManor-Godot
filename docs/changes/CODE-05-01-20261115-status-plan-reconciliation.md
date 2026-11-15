# CODE-05-01 / RM-GAP-001 — post-merge plan and dashboard-status reconciliation (2026-11-15)

## Task IDs and ownership
- Owner domain: `room-builder`; live shard: `data/raven/production/progress/room-builder.json`.
- Status tasks: `CODE-05-01`, `RM-GAP-001`.
- Documentation cross-links only: `docs/NEXT_PLAN.md`, `docs/STATUS.md`, `docs/IMPLEMENTATION_PLAN.md`, `docs/INDEX.md`, `README.md`.
- This PR does **not** update `manor-map` or `campaign-core` status shards because owner-scoped reconciliations are already in review: #262 and #263.

## Verified merged baseline
GitHub API (2026-11-15; main `f0d2264e771be90f672a052dc9c169ee944607c4`) confirms:
- #254 / MAP-EDIT-04A MERGED, exact-head CI 42704711153 SUCCESS.
- #255 / MAP-EDIT-05 MERGED, exact-head CI 43747623254 SUCCESS.
- #257 / MAP-QA-08B MERGED, exact-head CI 43752271622 SUCCESS.
- #258 / MAP-QA-09 MERGED, exact-head CI 43755082705 SUCCESS.
- #259 / GAME-LOOP-01A MERGED, exact-head CI 43756255635 SUCCESS.
- #260 / MAP-GAME-01A MERGED, exact-head CI 43757540481 SUCCESS.
- #261 / MAP-QA-09B MERGED, exact-head CI 43759111860 SUCCESS.
- #262 / CODE-05-02 and #263 / GAME-LOOP-01 are OPEN evidence-only reconciliation PRs; respective exact-head CI 43760764981 and 43760367699 SUCCESS at audit. Do not claim merged.

## Changes
1. Correct stale `CODE-05-01: PR_review` from #255 to `ready` + `partial` + `automated` + `approval pending`, P0 unchanged. This is a **partial technical scope**, not a completed full floor-calibration task.
2. Record implemented draft/editor aspects of `RM-GAP-001` as `ready` + `partial` (P0 unchanged), without pretending 65-degree production Hall, elevation, doors, sprite/collision occlusion or mobile QA are approved.
3. Update current document entrypoints and replace obsolete 2026-11-03/06 task order with an explicit 2026-11-15 operational priority queue while retaining older planning text as historical baseline.
4. Enumerate known next integration blockers: owner approval of HA/HC/CB/CK architectural thresholds and art; `raven_hotspot_gameplay_bridge` / `manor_navigation_source` convergence; authoritative Save/Continue room/anchor; Evelyn chibi sprite/device QA.
5. Preserve existing task IDs and no new status/approval claims; no generated dashboard or frozen progress-file edits.

## Verification and review
- Read-only GitHub checks of PR statuses, latest main, actual files and owner shards: EXECUTED.
- JSON shard structure/parse: checked before mutation; PR-head GitHub Actions expected to verify schema, governance, dashboard generation and docs link compatibility.
- Local Godot, device and manual map QA: NOT_RUN (no runtime/art changes in this PR).
- Dashboard live Pages display: NOT_VERIFIED via browser access; the source-of-truth shard changes become visible after merge and successful normal deployment. `build_production_dashboard.py --check` cannot be run in this GitHub-connector-only environment; use CI as the gate.
- Owner must review/merge. Do not auto-merge, promote DRAFT_ONLY/TEST_ONLY architecture, or mark parent P0 accepted.
