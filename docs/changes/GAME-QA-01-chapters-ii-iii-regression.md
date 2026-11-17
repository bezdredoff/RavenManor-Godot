# GAME-QA-01 — Chapter II–III independent production-gate regression (GAME-QA-03)

**Registered task ID:** GAME-QA-01, qa-infrastructure (P1). **Follow-up delivery:** GAME-QA-03, not a separately registered backlog task.  
**Baseline:** `main@32a8d98d2fd3e75bf7613b8391f5ea7a769abd5a` (merged #291). **Branch:** `agent/qa-infrastructure/GAME-QA-01-chapters-ii-iii-regression`.  
**Baseline CI:** [main 44173380349](https://github.com/bezdredoff/RavenManor-Godot/actions/runs/44173380349) — six mandatory jobs + Pages deploy SUCCESS; this is NOT this branch's exact-head/new-test execution.  
**New script execution:** NOT_RUN locally (Godot 4.7.2 binary unavailable). No runner registration in this PR by design. **Phone / browser / owner QA:** NOT_RUN. **Production Chapter II–III:** BLOCKED.

## Scope and changes

1. Added **one independent standalone** `tests/raven/vn_chapters_ii_iii_production_gate_smoke.gd`. It audits the eight live scenes, 96 ordered line/cue pairs × 3 locales, actor identity, accepted exact pose+emotion+`defaultForPose=true`, background availability, and no duplicate accepted catalog path/SHA identity. Missing art is dynamically recomputed/logged; it is **not** asserted to equal the baseline seven missing pose combinations forever. A missing requirement may be reported as a blocker on review-only scenes; attempts to activate a scene lacking its accepted art still must fail closed.
2. An explicitly **SYNTHETIC ONLY** Hall Tea source fixture deep-copies the canonical dialogue, map route, staging, cue and approved catalogs. It maps *only copied* staging/cues to existing accepted portrait **metadata** with exact character IDs and true pose/emotion (no invented accepted variant or file copy); enables only the copied Tea scene and route, then exercises all 12 canonical lines in RU/BE/EN, read-only Skip/cursor/choice stop, missing previous chapter completion, wrong target, blocked auto-play, final event and reducer/storage idempotence, memory-store Continue at line 2 and after beat completion.
3. Live default G2 source and real gameplay host are constructed with in-memory storage, not a QA or injected world plan. The scene selector rejects forged/no host, non-authoritative hotspot and unconfirmed spawn-as-table. Standalone negative fixture cases include missing exact cue art, locale cell, scene/route approval and unsupported NPC/object/door/specialist kinds; future scene fake approvals without authoritative gate state cannot launch that beat.
4. Isolated memory-storage checks cover failed write preserving the prior snapshot, recovery after write, and a corrupt save refusing production host configuration. No real `user://` files touched.
5. Added `docs/qa/CHAPTERS_II_III_ACCEPTANCE_MATRIX.md`: per-scene blockers, automated vs future integration cases, 320×568 / 390×844 / 430×932 × RU/BE/EN, actual device/browser/desktop/offline/manual acceptance template, and exact integration-owner runner handoff.
6. Updated **only** `data/raven/production/progress/qa-infrastructure.json` in the status ledger, using the existing registered GAME-QA-01 entry. No new unregistered task ID, no other status shards or generated dashboard.

## Preservation / hard boundaries

- **Not changed:** Agent A's `vn_chapters_ii_iii_readiness_fixture.gd`, canonical `vn_staging.json`, `line_performance_cues.json`, portrait art/catalog and story; Agent B's `raven_gameplay_host.gd`, dispatcher, map, G2 and VN integration tests; reducer/snapshot/campaign store; `scripts/check.sh`, `check.ps1`, `.github/workflows/**`.
- The static baseline still has **96 canonical lines**, **288 RU/BE/EN cells**, **7 distinct missing exact art combinations across 43 cue lines**, 8 accepted background variants, and current review-only routes. This describes inspected source, **not** new test execution or the future Agent A stage/cue result.
- G2 default production source is enabled by owner-approved #291; the Hall Tea **VN/physical activation** remains separate and cannot be declared done by observing G2 map readiness.
- The existing `vn_chapters_ii_iii_readiness_fixture.gd` is registered through `vn_production_runtime_dispatch_smoke.gd` and currently **pins 43 missing cue occurrences**. Agent A/merge integrator must reconcile that historic test/manifest with honest updated source after accepted substitutions, without editing it in this parallel PR.

## UPDS-first and authority

Use existing Raven UPDS-derived `raven_vn_player.gd`, `raven_vn_read_history.gd`, dialogue paging and Raven `raven_campaign_store.gd` / reducer; no second VN session, reward, new save format or copied donor art. Existing recorded donor comparison in `docs/changes/VN-RUNTIME-01-chapters-2-3-regression.md` points to `bezdredoff/UPDS-godot@3deed628efd6c22bcd1717f7c545b7d3ca865781` and donor `scripts/vn/dialogue_paging.gd` blob `d9f22ca8533017d112a62ec174fd2c66546e4290`. **Reuse decision:** existing Raven adapters and parity tests as-is; new Raven-specific source-contract test, no imported controller.

## Verification, acceptance and CI truth

| Gate | Status / evidence |
| --- | --- |
| #291 merged + main baseline SHA | VERIFIED, `32a8d98d2fd3e75bf7613b8391f5ea7a769abd5a` |
| Main six CI jobs and Pages | PASS, [run 44173380349](https://github.com/bezdredoff/RavenManor-Godot/actions/runs/44173380349) at baseline SHA |
| New standalone Godot 4.7.2 script | **NOT_RUN**; cannot claim green on source review or on the existing CI runners without registration |
| Full exact-head PR CI | **PENDING** on opening PR / running checks; annotate separate SHA once completed |
| Synthetic future Hall Tea | Source fixture authored; **NOT_RUN** until standalone invocation, not a production PASS |
| Real Hall Tea menu→physical arrival→VN→reducer→save/reload | BLOCKED pending Agent A portrait reuse + Agent B gameplay integration, actual target arrival and approvals |
| Seven Chapter II–III future gates/rooms | BLOCKED pending authoritative interaction and spatial approvals |
| RU/BE/EN physical device, 320×568 / 390×844 / 430×932 | **NOT_RUN** |
| Web refresh/offline/restart | **NOT_RUN** |
| Owner-approved production release | **PENDING**, Draft PR only |

**Standalone command after checkout:**  
`godot --headless --path . --script res://tests/raven/vn_chapters_ii_iii_production_gate_smoke.gd --quit-after 240`  
Target engine: **Godot 4.7.2**. The new script is a `SceneTree` test and is **not** currently registered in `scripts/check.sh` / `check.ps1`; exact registration point and full Windows/Linux/release instructions are in the QA matrix. Preserve existing six-job gating; no misleading physical-phone or synthetic-production PASS.

**Owner QA / next actions:** Review this independent test/acceptance card, wait for Agent A art metadata and Agent B/contract/map merge; integration owner adds the script to both runners and adds a **real** normal-game Hall Tea positive E2E after canonical activation. Require actual Godot CLI output, exact-head green CI and manual phone/browser evidence before marking GAME-QA-01 accepted or Chapter II–III production ready.

**Rollback:** revert this PR's independent new test, QA matrix, unique change note and qa-infrastructure shard update. No save/schema/runtime/canonical content migration is involved.
