Task IDs: GFX-07-01 (postmerge status-only follow-up).

Changes: Reconcile the chibi-animation own shard to the verified merged status for PR #275; no runtime/art modifications.

Verification: PR #275 exact-head CI 43982967767 SUCCESS, #280 exact-head CI 44072750669 SUCCESS. This follow-up's own exact-head CI remains required.

Owner QA: Corrected #274 Evelyn design/animation visually APPROVED by owner. Real phone, foreground, production geometry and New Game integration NOT_RUN/NOT_APPROVED.

Status impact: GFX-07-01 status PR_review -> merged, while implementationState partial, qaState manual_pending and approvalState pending remain unchanged.

# GFX-07-01 — merged-host status reconciliation

**Task IDs:** GFX-07-01 (bounded merged-PR evidence follow-up; no new runtime implementation).
**Domain:** chibi-animation.
**Baseline:** main `ddcc8a646ffbfa60dcfea43849a592bfdddd9f24` (after #280).

## Changes

- Reconcile `data/raven/production/progress/chibi-animation.json`: GFX-07-01 `PR_review` → `merged` **after** confirming PR #275 is merged, and append specific tested head / CI evidence.
- Preserve `implementationState=partial`, `qaState=manual_pending` and `approvalState=pending`. Preserve all independent GFX-07-05/09/10 and GFX-11-T06 entries; do not imply full chapter/game production acceptance.
- No runtime, art, navigation, menu, save, reducer, geometry, test, release pipeline or generated dashboard changes.

## Verification and evidence

- [PR #275](https://github.com/bezdredoff/RavenManor-Godot/pull/275) merged as `ea1f3500f12db7ca3c5b2dce2331620d00418161`; exact PR head `4d699d0b3ea4d255ec46a23907d5723ca63d3d5e`.
- [Exact-head CI run 43982967767](https://github.com/bezdredoff/RavenManor-Godot/actions/runs/43982967767) is completed SUCCESS: data-contracts, godot-runtime, room-builder, art-pipeline, web-package and build. The PR records GFX-07-01 Evelyn gameplay-host, historical Onoe, Hall/multi-room movement, preview and atlas regressions.
- [G2-02 #280](https://github.com/bezdredoff/RavenManor-Godot/pull/280) merged after its [CI run 44072750669](https://github.com/bezdredoff/RavenManor-Godot/actions/runs/44072750669) SUCCESS. Its integration smoke is TEST_ONLY, not evidence of production navigation activation.
- No new local Godot run: this PR changes only a progress ledger and evidence note. GitHub Actions for this status-only PR are **pending** until its own head is checked.

## Owner QA and release boundaries

**APPROVED:** The owner manually approved the corrected Evelyn chibi appearance and animation from merged #274 on 2026-11-17. Metadata is generated from `measure_frames.py` and remains `ownerApproved=true`.

**NOT APPROVED / NOT RUN:** physical-device performance/readability, foreground/door-sill occlusion, production HC/CB passage geometry, normal New Game-to-manor host, full save/Continue gameplay release. Do not change `productionReplacementAllowed=false`, `productionIntegrationVerified=false`, `deviceVerified=false`, or `foregroundOcclusionVerified=false` until their independent acceptance gates are satisfied.

## Rollback

Revert only this status-reconciliation commit and evidence note to restore prior ledger status if evidence proves incorrect. The original #275 actor integration remains unchanged. No migrations or asset generation required.
