# G2-02 — post-merge regression activation and recorded owner decisions

Task IDs: GAME-LOOP-01; CODE-05-02; GAME-QA-01; GFX-07-01 (integration coordinator; no new task IDs or cross-shard ownership transfer).

Changes: Following explicit owner instruction, PRs #275 Evelyn, #277 VN II–III, #276 QA, #278 HC/CB architectural review and #279 isolated G2 host were merged sequentially. Record owner approval of the corrected #274 Evelyn visual and #278 HC/CB design direction in docs/DECISIONS.md (RM-DEC-029/030). Register #278's new 09D architectural smoke and #279's new isolated G2 host smoke in BOTH existing check.sh and check.ps1, without relaxing any existing gate. This is test-contract/decision integration, not production geometry activation.

Verification: Initial source PRs had six-job PASS on their own exact heads; as merged, both new scripts had not been registered or exercised in a blocking CI job. This integration PR enables them as blocking smoke commands. Full results of the exact-head integrated GitHub Actions run must be cited and reviewed before merging this integration PR. No physical phone or actual production-loop approval is implied.

Owner QA: OWNER_APPROVED only for Evelyn appearance/walk animation (#274) and proposed HC/CB architectural target ([824,400] under-landing, [528,376] bedroom partition, 48px proposed width). Actual finished door artwork/structural headroom/collision/occlusion and physical-device gameplay QA are NOT_RUN; production map activation is BLOCKED until implementation and testing, not reapproved merely by this note.

Status impact: This integration branch does not edit any of the 15 domain-owned status shards or generated dashboard. All five feature owners must reconcile the actual #275–#279 merges in their own progress shards, preserving partial/acceptance boundaries. Current G2 remains partial; PRODUCTION_APPROVED remains false for current canonical geometry.

## Exact merge evidence
- #275: https://github.com/bezdredoff/RavenManor-Godot/pull/275 merged into main at ea1f3500f12db7ca3c5b2dce2331620d00418161.
- #277: https://github.com/bezdredoff/RavenManor-Godot/pull/277 merged into main at 66ad29d0eb3c6484d5c2278101f5a18c152ab28a.
- #276: https://github.com/bezdredoff/RavenManor-Godot/pull/276 merged into main at b77d282471c7c6880db99f75e2acc1776b60c6f7.
- #278: https://github.com/bezdredoff/RavenManor-Godot/pull/278 merged into main at 2484f59afd542ce8640c1f9020c49d2109f854c9.
- #279: https://github.com/bezdredoff/RavenManor-Godot/pull/279 merged into main at e14007114f4c220bddbdb283a9614447fe12d64c.

## Exact new blocking regressions
- `tests/raven/map_qa_09d_hc_cb_architectural_smoke.gd` — original approved PNG hash, DRAFT_ONLY, two-way 09B TEST_ONLY gates/routes, 12px foot clearance, failure on missing HC route, no double projection.
- `tests/raven/game_loop_g2_host_smoke.gd` — production source denied, QA isolated opt-in, authored Hall→Corridor→Bedroom→Corridor→Hall, story/reducer on validated arrival only, save/Continue safe anchors, locked/relocked doors, paused/cancelled input, failure/recovery, first-clear Match-3 exactly once and RU/BE/EN VN boundaries.

Both tests must now **execute** in the GitHub Actions godot-runtime job on the integration branch. Their source files were authored in the merged feature PRs and are not changed here. Keep the other runner registrations and original Onoe QA baselines intact.

## Release implications / rollback
- G1 Evelyn visual owner-approved; #275 actor wiring merged. New Game still uses legacy vertical_slice; full production map host is not enabled.
- G2 QA gameplay orchestration exists as a safe, isolated host. A genuine production navigation source remains fail-closed, correctly.
- HC/CB architectural direction approved, but structural/elevation treatment, replacement painted geometry, masks, collisions and complete production camera/door QA are implementation tasks. DO NOT simply change JSON approval flags.
- VN Hall Tea is synthetic-ready only; canonical Chapter II–III approval is separate.

Rollback: revert this bounded integration PR to remove its two runner registrations and dated decision records (if the owner decision itself changes, record a superseding decision rather than silently deleting approval history). The five feature PR merges remain intact.
