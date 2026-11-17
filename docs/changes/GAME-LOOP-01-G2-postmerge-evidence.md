# GAME-LOOP-01 G2 — post-merge verification and parent-status reconciliation

**Task:** GAME-LOOP-01 · **domain:** campaign-core · **date:** 2026-11-17  
**Baseline:** `main@ddcc8a646ffbfa60dcfea43849a592bfdddd9f24`  
**Scope:** evidence-only. No runtime, geometry, menu, navigation gate, save schema, shared runner or external-domain shard changes.

## Merged delivery verified

- [PR #279](https://github.com/bezdredoff/RavenManor-Godot/pull/279) **MERGED**. Head `032afe18594057780ff3e451b58bf51729603526`; merge `e14007114f4c220bddbdb283a9614447fe12d64c`. Isolated G2 host, authored hotspot→route→observed arrival, one Raven reducer/store, safe-ground checkpoints, Continue reconstruction, QA TEST_ONLY preview and smoke. [Original change record](GAME-LOOP-01-G2-host-persistence.md) pins donor `UPDS-godot@3deed628efd6c22bcd1717f7c545b7d3ca865781` and rollback.
- [PR #280](https://github.com/bezdredoff/RavenManor-Godot/pull/280) **MERGED**. Head `7fe865b19654c9e0d2b2308103dd4241db04b3a1`; merge `ddcc8a646ffbfa60dcfea43849a592bfdddd9f24`. Fixed G2 Godot type inference and registered G2 / HC-CB smoke once on both platforms.

## Verification actually observed

[Exact-head GitHub Actions run 44072750669](https://github.com/bezdredoff/RavenManor-Godot/actions/runs/44072750669) on #280 head **SUCCESS**:
- `data-contracts`, `godot-runtime`, `room-builder`, `art-pipeline`, `web-package`, aggregate `build`: all **success**. `deploy`: skipped for PR (expected).
- Godot runtime job logs explicitly print `GAME-LOOP-01 G2 isolated host, persistence and Continue passed.`, `GFX-07-01 Evelyn gameplay host passed.`, and `CODE-05-02/09D HC-CB architectural smoke passed.` Legacy G1, MAP-QA, VN/Match-3 and menu regressions also passed.
- Repeat isolated smoke: `godot --headless --path . --script res://tests/raven/game_loop_g2_host_smoke.gd --quit-after 360`. This evidence is from Actions; no local Godot/device run was performed for this reconciliation.

## Parent-task status (no false closure)

`GAME-LOOP-01` remains **P0, implementation partial, QA automated, owner approval pending**. The stale `PR_review` state claimed an open #279, which is false after its merge; reconcile to `ready` for the next bounded production activation PR. The parent task is *not* marked merged/accepted because the normal New Game → production map → story/Match-3 → save/Continue path has not shipped.

- **Integrated now:** G2 host, source-gated QA orchestration, reusable Evelyn-capable mover/controller, safe persisted anchor, Continue, idempotent Raven story/economy transactions.
- **Tested only as QA:** synthetic Hall ↔ Corridor ↔ Bedroom routes and scene handoffs, recovery and locale/Skip smoke. QA uses isolated memory storage.
- **Production held:** canonical HC/CB `DRAFT_ONLY` geometry cannot be promoted; door render/headroom/occlusion/foot collision, owner inspection and approved production navigation source still required.
- **Dependencies:** Agent A/owner physical HC/CB review and approval; Agent D Evelyn physical-device/occlusion verification (technical host smoke passed); Agent C approved later VN scene dispatch; Agent E device/acceptance parity (runner registration now merged).
- **Follow-up:** integration owner activates menu→map only in a new bounded, reviewed PR after the hard G2 gate passes.

**Rollback:** revert this evidence-only PR. Do not modify #279/#280 runtime semantics or claim owner acceptance from smoke tests.
