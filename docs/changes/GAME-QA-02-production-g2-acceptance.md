# GAME-QA-02 — production G2 acceptance, runner guard and merge evidence

Task IDs: GAME-QA-02 (new bounded QA delivery, not yet indexed in canonical backlog); GAME-QA-01 (existing QA ledger reconciliation). Related GAME-LOOP-01, CODE-05-02, GFX-07-01, VN-RUNTIME-01.
Changes: Add the normal, real-menu New Game/Continue **legacy-path boundary smoke** and register exactly once in Bash/PowerShell; extend the existing runner-contract test. Publish actionable G2 production-vs-fixture matrix and Windows/Web/phone RU/BE/EN acceptance protocol in docs/qa/GAME-QA-02-g2-production-acceptance.md. Reconcile verified merged #276 in own qa-infrastructure shard only. No gameplay implementation, released-geometry promotion, workflow change, dashboard edit, second saver, imported assets or foreign-shard edit.
Verification: At starting main `ddcc8a646ffbfa60dcfea43849a592bfdddd9f24`, [Actions 44073202009](https://github.com/bezdredoff/RavenManor-Godot/actions/runs/44073202009) SUCCESS for six checks and Pages deploy. Every #275–#280 exact final PR head reported SUCCESS: #275 43982967767, #276 43981606512, #277 43981539917, #278 43982325462, #279 43983156255, #280 44072750669. New GAME-QA-02 test/code are NOT_RUN until this PR's exact head completes. Local Godot 4.7.2 / Windows / actual browser not available in authoring environment. No new CI PASS claim here before the actual run.
Owner QA: BLOCKED for production New Game/Continue and physical HC/CB; NOT_RUN on Windows, real browser, 320×568 / 390×844 / 430×932, phone, foreground, 3 locales and reduced motion. Owner visual approval applies only to #274 Evelyn and RM-DEC-030 architectural direction, not G2 acceptance.
Status impact: GAME-QA-01 now `merged` based on #276 and main run; retain `qaState=automated`, `approvalState=pending`. GAME-QA-02 is not yet a known canonical work-package ID: **do not create an unindexed progress override**; integration owner must register new task in source plan, then QA can add its own status/assignment. Other owners receive reconciliation handoffs below.

## Verified merged inputs (merge SHA; exact PR-head CI)

| PR / domain | Merge SHA | PR head SHA | Verified successful Actions run |
| --- | --- | --- | --- |
| [#275](https://github.com/bezdredoff/RavenManor-Godot/pull/275) chibi-animation | `ea1f3500f12db7ca3c5b2dce2331620d00418161` | `4d699d0b3ea4d255ec46a23907d5723ca63d3d5e` | [43982967767](https://github.com/bezdredoff/RavenManor-Godot/actions/runs/43982967767) |
| [#276](https://github.com/bezdredoff/RavenManor-Godot/pull/276) qa-infrastructure | `b77d282471c7c6880db99f75e2acc1776b60c6f7` | `f23fddf28fc68366e64135cb4d83a1d81359d4f2` | [43981606512](https://github.com/bezdredoff/RavenManor-Godot/actions/runs/43981606512) |
| [#277](https://github.com/bezdredoff/RavenManor-Godot/pull/277) vn-runtime | `66ad29d0eb3c6484d5c2278101f5a18c152ab28a` | `0f7ed1d7a1cfac8215f7782642ec5e706fe11fb3` | [43981539917](https://github.com/bezdredoff/RavenManor-Godot/actions/runs/43981539917) |
| [#278](https://github.com/bezdredoff/RavenManor-Godot/pull/278) manor-map | `2484f59afd542ce8640c1f9020c49d2109f854c9` | `d9b3a755da1392cbd409330eb6232e3b02d138bc` | [43982325462](https://github.com/bezdredoff/RavenManor-Godot/actions/runs/43982325462) |
| [#279](https://github.com/bezdredoff/RavenManor-Godot/pull/279) campaign-core | `e14007114f4c220bddbdb283a9614447fe12d64c` | `032afe18594057780ff3e451b58bf51729603526` | [43983156255](https://github.com/bezdredoff/RavenManor-Godot/actions/runs/43983156255) |
| [#280](https://github.com/bezdredoff/RavenManor-Godot/pull/280) integration | `ddcc8a646ffbfa60dcfea43849a592bfdddd9f24` | `7fe865b19654c9e0d2b2308103dd4241db04b3a1` | [44072750669](https://github.com/bezdredoff/RavenManor-Godot/actions/runs/44072750669) |

## Precise foreign-shard reconciliation handoff — NOT edited here

- `data/raven/production/progress/chibi-animation.json` — `GFX-07-01` currently incorrectly `PR_review` for merged #275; owner should set `merged`, retain `implementationState=partial`, `approvalState=pending`, record merge `ea1f3500...` + PR-head run 43982967767, avoid implying device/foreground acceptance.
- `data/raven/production/progress/vn-runtime.json` — `VN-RUNTIME-01` `PR_review` stale after #277; owner should set `merged`, retain partial and review-only manifest, no canonical approvals; add merge `66ad29d0...` and run 43981539917.
- `data/raven/production/progress/manor-map.json` — `CODE-05-02` `PR_review` stale after #278; owner should set `merged` for 09D candidate only, preserve partial, DRAFT_ONLY and productionReady=false; add merge `2484f59a...` and run 43982325462.
- `data/raven/production/progress/campaign-core.json` — `GAME-LOOP-01` `PR_review` stale after #279; owner should set `merged` for isolated host only, retain partial, production blocked; add merge `e1400711...` and run 43983156255.
- `GAME-QA-01` own shard reconciled here for merged #276; do not update other owners directly. #280 is an integration PR, not a new domain task acceptance.
- Integration owner: register `GAME-QA-02` in shared canonical gap/code plan through an explicitly owned integration PR, then QA add a live entry and P1 `WS-CAMPAIGN` assignment; do not hot-edit `progress/index.json` or generated `dashboard/status.json`.

**DoD remaining:** new-head CI must pass; Agent A production HC/CB, Agent B ordinary map entry/Continue, real device/browser evidence and independent owner approval. This PR is a bounded QA gate, not a G2 activation. No auto-merge.
