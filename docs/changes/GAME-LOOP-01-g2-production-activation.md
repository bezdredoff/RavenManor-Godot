# GAME-LOOP-01 / G2-ACT-01 — owner-approved V4 production source activation candidate

Task IDs: GAME-LOOP-01, G2-ACT-01 (bounded production activation)
Changes: Owner-approved HC/CB V4 source activation behind exact SHA-bound receipt, plus regression updates.
Verification: Previous main exact-head CI green; this Draft PR exact-head CI and native/device checks pending.
Owner QA: V4 visual APPROVE; step-2 preliminary go-ahead only; physical phone and final G2 acceptance NOT_RUN.
Status impact: campaign-core GAME-LOOP-01 still partial and pending; Draft PR is not merged or accepted.

**Status:** DRAFT PR / review only; do not merge without physical-device and ordinary-gameplay evidence.
**Baseline:** `f43ef9169f9aeb73976451e97b3eea37fdcb7128` (17 November 2026, full main CI [44166322317](https://github.com/bezdredoff/RavenManor-Godot/actions/runs/44166322317) SUCCESS).
**Owner decision:** RM-DEC-031 records explicit V4 visual **APPROVE** and provisional permission to proceed past step 2; this is **not** an Android/iOS PASS or final G2 signoff.
**Rendering evidence:** [V4 GPU captures, 14 PNGs](https://github.com/bezdredoff/RavenManor-Godot/actions/runs/44162426407/artifacts/14364680617); PR #290; original golden CB door retained; HC wall join under original staircase landing. Native code owner-approved Evelyn and first-floor PNG remain unchanged.

## Changes

- Generate the same authored 119-anchor/120-edge G2 candidate from 09B but now promote only its provenance and room-art calibration to the separately approved RM-DEC-031 state. Preserve route topology, door locks, source PNG, 65° painted view and 12px/48px physical-design targets (not a measured structural section).
- Pin `manor_production_acceptance.v1.json` to the exact SHA-256 of the production candidate and V4 door art. `ManorNavigationSource` requires the receipt, matching production decision and active provenance before enabling the default production source. In-memory TEST_ONLY/09B/09D paths retain their independent source mode.
- Enable the separate source switch on this **draft branch only**. Keep the normal New Game introduction, 4 opening VN beats, Hall/Corridor/Bedroom physical authored routes, existing Evelyn actor, vanilla VN/Match-3, reducer and store; no synthetic user save or second authority.
- Preserve negative tests by rejecting unapproved greybox/forged injected plans or an in-memory missing receipt. Positive tests must now exercise the real default approved source (not `Fixture.install_canonical()`).
- The MAP-PROD-01 visual-QA manifest remains a non-authoritative **inactive candidate**. It is not the switched production world plan and remains useful for prior review regressions.

## Exact-file hashes

- `data/raven/manor_production_candidate.v1.json`: SHA-256 `f9c7ee86fa5e819cc3cfb1e1415537ee38c952b80d2c3b611e2346d9525d171a`
- `scripts/raven/map_prod_01_hc_cb_art.gd`: SHA-256 `c4ed79c0855ff91b04ea92a98a59e5442bf21a71966a70783b59ee761b0e8a32` (file unchanged)
- Owner decision receipt and source gate compare both at runtime; any art or plan bytes change must cause fail-closed and a renewed owner review.

## Tests and evidence — not yet executed on this draft branch

Run all on exact PR head:
```sh
python3 scripts/raven/tools/build_g2_production_candidate.py --check
python3 scripts/raven/tools/progress_shards.py
python3 scripts/raven/tools/build_production_dashboard.py --check
bash scripts/check_data.sh
RAVEN_SKIP_DATA_CHECKS=1 bash scripts/check.sh
```
On Windows additionally run `check.ps1 -GodotPath <Godot-4.7.2-console>`. Required GitHub CI: data-contracts, godot-runtime, room-builder, art-pipeline, web-package, build (+ Pages after merge only). Review real main-menu New Game → four intro beats → map with approved Evelyn, no Onoe; Hall→Corridor→Bedroom→Corridor→Hall; gates, hotspots, VN/Match-3, exact-once rewards/restoration, disk save/Continue at same safe anchor, corrupt-save/failed-write recovery, RU/BE/EN and mobile HUD.

## Remaining manual gates / rollback

**NOT_RUN:** measured physical-phone Android/iOS touch/foreground/headroom, background/resume, FPS/thermals, real Web refresh/offline, full non-fixture menu-to-Continue acceptance by owner. The CI test is isolated memory storage and is **not** phone or real disk persistence proof. Owner's step-2 provisional “yes” is not a recorded device test result. Do not auto-merge, auto-approve, mark Season 1 done or update portrait registry.

Rollback: revert the activation PR or set the independent `PRODUCTION_ACTIVATION_ENABLED := false` switch. Existing original map, G2 host/reducer/save, 09B/09D drafts, approved Evelyn and VN content are unchanged.

## Integration CI correction (PR #291)

Native Godot positive menu entry exposed the old V3-only art-layer discriminator in `raven_player_map.gd`. The V4 candidate names `hc-cb-v4`, while the approved corrected V4 drawing is rendered by the existing `map_prod_01_hc_cb_art.gd` layer code. The map now recognizes both V3 and V4 layer identifiers without altering the bitmap, door-layer file or the SHA-pinned world plan; the real menu smoke asserts foreground/background presence. Bash and PowerShell runner sentinels were updated to the renamed production-positive smoke print. Exact-head Godot/CI verification is required for this refinement.
