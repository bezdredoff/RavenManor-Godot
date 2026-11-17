# GAME-LOOP-01 / VN-HALL-TEA-01 — Hall Tea runtime bridge (Draft)

**Task IDs:** GAME-LOOP-01 (registered P0 parent), VN-HALL-TEA-01 (scoped follow-up).
**Baseline:** `main@32a8d98d2fd3e75bf7613b8391f5ea7a769abd5a` after merged PR #291.
**Changes:** gameplay-host/runtime map-target bridge, fail-closed gated UI request, persisted VN cursor after physical arrival, saved-cursor Continue, existing G2 regression assertions, campaign-core status evidence only.
**Verification:** Static source/code audit performed; Godot 4.7.2 NOT_RUN locally (no binary/network in this environment); exact-head CI PENDING.
**Owner QA:** NOT_RUN; do not activate or merge without explicit approval.
**Status impact:** GAME-LOOP-01 remains `in_progress` / `partial` / P0, owner acceptance pending.

## Actual source audit and critical gap

- The approved G2 HC/CB production source is active after #291. Its `data/raven/manor_production_candidate.v1.json` graph has **no** `RM-HS-TEA-TABLE` anchor or reachable route. The historical `manor_greybox_graph.json` contains `RM-NAV-HALL-TEA`, but those historical coordinates are **not** approved production geometry. Do not copy them into the signed world plan or bypass its SHA/owner acceptance.
- The normal map view recognizes `RM-HS-TEA-TABLE`; the route catalog names the logical interaction `hall_chair_table`. Previously `next_scene_at_confirmed_hotspot` compared them verbatim and could never select `RM-BEAT-02-01`.
- The canonical dialogue carries exactly 12 stable `RM-BEAT-02-01-L001..L012` lines in RU/BE/EN. Scene status is `pilot_runtime`, route gate remains `approvedRuntime=false`, and the Ada `offer_tray/dry_amused` exact art is not accepted on this baseline. The eight Chapter II–III canonical statuses and routes are **not changed**.
- Existing `RavenSliceDirector.next_step` reaches `done` only after `RM-BEAT-01-05` and other RM-VS-01 milestones; `raven_vn_runtime_dispatch.next_scene` remains auto-only. The existing Chapter I smoke executes the legacy slice but is **not** proof of a no-fixture physical Chapter I-to-tea journey.

## Bridge and invariant

Only `raven_vn_runtime_dispatch.gd` owns the static one-to-one alias `RM-HS-TEA-TABLE → hall_chair_table`. This resolves **after** proving a real `RavenGameplayHost`, a production source (no QA/DRAFT_ONLY), Hall room ownership, the graph's matching interaction anchor, no in-flight segment or ready transition and the actor footpoint within 0.25 units. An unknown, unrelated or raw narrative-target string fails closed.

`request_runtime_hotspot` checks the authored anchor/room, completed Chapter I, no active/cancelled/replayed VN cursor/beat and canonical runtime/art/route approvals **before** enqueueing the existing route. If the gate is revoked during motion it cancels through the existing segment-safe cancel API. A real controller-confirmed arrival alone can select the scene; only a successful `RavenCampaignStore.save_campaign` of the existing `vnCursor={beatId,lineIndex:0}` allows presentation. Save failure holds rather than presenting. No new save schema, reward, reducer event, mover or fake arrival receipt.

The existing `vertical_slice.gd` / `RavenVNPlayer` / `RavenVNGameView` renders canonical lines and uses `ReadHistory` read-only Skip. It alone issues `story_beat_seen` **after the final VN advance**, saves through the sole store, retries failed writes safely and prevents replay by persisted `storyBeatsSeen`. After a real first presentation is interrupted, `resume_scene_from_saved_cursor` can restore a started, still-approved Hall scene from the **saved campaign cursor** even when Continue respawns Evelyn at the last safe Hall anchor instead of the table. Resume is continuation of an already-persisted VN, not fresh hotspot activation or a caller-supplied `approved=true`/tap flag. Manual save editing is outside the trust model.

## Verification matrix and outstanding acceptance

| Case | Automated evidence | Remaining |
| --- | --- | --- |
| Map ID vs authored narrative ID, unrelated/raw targets | Registered G2 production smoke assertions + dispatcher exact mapping | Godot execution / CI |
| Premature tap, Chapter I gate, no cursor/beat/reward | Registered G2 smoke rejects while incomplete | Full real Chapter I normal-flow proof |
| Wrong room, missing/locked/inaccessible/unreachable table | Existing controller gates + new host source/anchor checks; **no approved tea anchor exists** | Approved physical Hall table route, visual/footpoint owner review |
| Motion interrupted, cancel/pause, repeated input and checkpoint errors | Existing G2 host and production-map regression harness; new runtime cancellation guard | Positive Hall Tea device journey |
| Twelve lines, RU/BE/EN, Skip, exactly-once completion and failed-save rollback | Existing synthetic `vn_chapters_ii_iii_readiness_fixture.gd` plus `vn_production_runtime_dispatch_smoke.gd`; reused `vertical_slice` / Raven reducer | Real promoted production scene; mid-VN process restart; phone QA |
| Disabled scene/art, after-Continue replay | Canonical `find_approved` remains closed, beat/cursor checks | Agent A merge, exact-current-main verification, separate owner activation |

**Must not call this a production Hall Tea E2E PASS.** Test work for actual successful physical traversal and 12-line player-facing VN is blocked by the missing approved Hall table anchor and incomplete canonical art/scene status. Never convert this Draft PR into an automatic promotion.

## UPDS-first reuse and rollback

Donor verified at `bezdredoff/UPDS-godot@3deed628efd6c22bcd1717f7c545b7d3ca865781`: `scripts/vn/vn_screen.gd` blob `c44edec0f4a29f05e128cf2d4005009adca0f842`; Raven already has UPDS-derived shell, paging, read history and bounded Skip (#174/#176). **Decision: adapter** — reuse existing Raven gameplay host, map harness, canonical runtime selector, VN UI and single store/reducer; add only Raven-specific map-to-route target resolution and cursor entry/Continue. Do not copy donor assets, create a second UI/session or introduce a new save authority.

**Dependency on Agent A:** art/cue/staging substitutions must merge first. Separately verify accepted portrait metadata, canonical 12 lines and approved scene/route at the *current* main head; promote **only `RM-BEAT-02-01`** with explicit owner approval. Before any such promotion, a separate map/integration/owner review must place and approve an actually walkable Hall tea table interaction anchor within the SHA-bound production world plan. All other seven scene statuses stay untouched. After that, native Godot 4.7.2 + exact-head CI + physical-phone RU/BE/EN normal gameplay/manual save/restart/Skip, accessibility, pause/cancel, collision and replay checks are required. Rollback: revert this scoped bridge; no canonical content, asset or approved map geometry changed.
