# GAME-LOOP-01A — Hotspot-to-gameplay QA vertical slice

Task IDs: GAME-LOOP-01A (scoped preparation), parent GAME-LOOP-01 (still open).
Domain: campaign-core (new gameplay integration adapter only).
Changes: Add isolated bridge, physical Onoe QA scene, gameplay/VN handoff and automated smoke while retaining single Raven store/reducer authority.
Verification: Smoke registered in scripts/check.sh; previous head Godot runtime passed, governance formatting needed fixing; exact new head CI pending.
Owner QA: Not run; no human/device, door alignment, canonical art or physical threshold approval claimed.
Status impact: GAME-LOOP-01 stays P0 partial/ready, PR #259 remains draft/unmerged; campaign-core shard evidence only.

PR: https://github.com/bezdredoff/RavenManor-Godot/pull/259
Base: main 20e17e189b81147f6368dec4339d543e7e384f96 (PR #257 merged).

## Changes

- Add `raven_hotspot_gameplay_bridge.gd` as a TEST_ONLY adapter between existing `ManorNavigationGraph`, `ManorRouteSession`, `RavenSliceDirector`, `RavenReducer` and `RavenCampaignStore`. It is not a state authority. Only real, established RM-HS-005 and RM-HS-002 IDs are accepted; other actions remain denied.
- Add `scenes/raven/tests/game_loop_01a_qa_harness.tscn` and its script. The harness uses existing `onoe_segment_actor.tscn`, the historical 13-anchor engineering greybox, and an in-memory store. It explicitly seeds the four completed intro beats via their real reducer events; this is a fixture, not campaign progression. The QA scene runs its own overlay with the **existing** `vertical_slice.tscn` for actual Match-3 board UI and VN, with the same injected Raven store object. No new board controller, VN shell, or gameplay wallet.
- Add `tests/raven/game_loop_01a_hotspot_bridge_smoke.gd` with physical segment advancement, gate checks, save boundaries and locale checks; register it once in `scripts/check.sh`.

## Actual minimal scenario and authorities

| Step | Existing ID | Trigger/authority |
|---|---|---|
| Intro already watched in QA | RM-BEAT-00-01..03, RM-BEAT-01-01 | QA-only precondition, `story_beat_seen` through RavenReducer |
| Select access hotspot | RM-HS-005 | Director must report `access`; graph can only plan the route |
| Onoe moves | RM-NAV-HALL-SPAWN -> RM-NAV-HS-005 | Authored greybox RouteSession + physical segment mover; no free tap-to-move |
| Arrive and revalidate | RM-HS-005 | Re-read single Raven store, recheck Director, active door graph and physical arrival |
| Clear physical door obstruction | RM-FLAG-BEDROOM-ACCESS-CLEARED / RM-DOOR-CORRIDOR-BEDROOM | Existing `Director.events_for("access")` sent through reducer and saved as one proposed snapshot |
| Play preparation | RM-LVL-001 | Existing vertical slice, RavenMatch3Session and UPDS-derived rules. First clear = 2 work points |
| Select restoration hotspot | RM-HS-002 | Only when Director reports `restore1`; now authorized path through bedroom door |
| Restore bedroom | RM-REST-001 | Existing reducer purchase (2 work points) and hotspot state in one saved snapshot |
| Play bedroom VN | RM-BEAT-01-02 | Existing VN player, catalog adapter, VN shell, line read history and Raven store; `story_beat_seen` only after finishing dialogue |

Two separate gameplay commits are deliberate: access after arrival; level reward after certified Match-3 win; restoration after its own arrival; VN completion after dialogue. Cancelling a route never calls any of these actions. Idempotent first-clear/purchase are already reducer invariants; repeated hotspot selection is rejected by Director, so no double reward/spend. On save failure no proposed reducer events are visible. Confirmed safe anchors alone receive a `position_checkpoint`; checkpoint write failure aborts further routing.

## Failure/interrupt contract

- Locked hotspot, unknown hotspot, unreachable graph segment: no physical command and no reducer event.
- Cancel or interrupted scene: finish current physical leg without replaying action; scene reload uses Raven saved safe anchor (not an in-flight or interaction footpoint).
- Gate changes during physical movement are revalidated before `finish_segment` (existing direct-edge contract).
- Availability rechecked on arrival from persisted state. A stale request after external progress is denied.
- Restore/reward save failed: no partially committed campaign state. Retrying from the physically reached hotspot is allowed after storage recovers.
- Existing Match-3 session owns checkpoints/booster spend and board rollback. The bridge never adds a parallel game save. VN read-only Skip remains unchanged (known completed lines only, never skips unread/choices); RU/BE/EN catalog and user preferences remain owned by the existing VN shell.

## UPDS-first reuse matrix

Inspected `bezdredoff/UPDS-godot@3deed628efd6c22bcd1717f7c545b7d3ca865781`:

| Donor source / blob | Raven path | Decision |
|---|---|---|
| `scripts/core/story_session.gd` / `ac926a6fcdcbd359cdc4a36081d02be8cd7ebe02` | `raven_slice_director.gd`, `raven_campaign_store.gd` | Not applicable for new map routing: UPDS scene indexes and save are not Raven authority |
| `scripts/vn/vn_screen.gd` / `c44edec0f4a29f05e128cf2d4005009adca0f842` | `vertical_slice.gd`, `raven_vn_game_view.gd`, `raven_vn_read_history.gd` | Reuse existing extracted Raven shell/read-history unchanged |
| `scripts/match3/match3_game.gd` / `138382bd373bc14bf6431a051a84d49de145acf1` | `scripts/shared/upds/match3_game.gd`, `raven_match3_session.gd` | Reuse existing imported rules/session unchanged |
| `scripts/core/save_storage.gd` / `37201dfebbe11854a590ea717ff3b844d2b9c48b` | `scripts/core/save_storage.gd`, `raven_campaign_store.gd` | Adapter: existing Raven-only save key and atomic interface, no schema change |

New thin bridge is justified because UPDS has no authored Raven map/hotspot-to-movement contract. This audit is not a claim of full device/UI parity.

## Verification

- Added headless Godot test to standard Linux `scripts/check.sh`, after the existing GAME-LOOP-01 characterization test.
- Automated test checks actual Onoe segment end positions, locked/unreachable/unknown actions, cancellation, interrupted route reload, first-clear idempotency, restoration cost, saved bedroom checkpoint, save-write rollback/retry, stale arrival recheck and legacy VN RU/BE/EN unread-Skip boundary.
- `Match3Session.complete(null, ...)` in this **bridge** smoke represents the post-win transaction boundary; it does not itself play or certify a winning board. Existing `game_loop_characterization_smoke.gd`, `match3_session_smoke.gd` and the manually playable QA harness cover those separate concerns.
- Exact-head Actions: **pending until run**. Local runtime: **NOT RUN** (Godot unavailable in this execution environment). Never confuse source inspection with executed tests.

## Production switch prerequisites

1. MAP-QA-09: owner-approved calibrated navigation, all real portal thresholds/handoffs/occlusion and target coordinates (MAP-QA-08B remains DRAFT_ONLY, transitions TEST_ONLY). Replace synthetic greybox adapter only after topology and gates are verified.
2. Integration owner to own production scene transition, live save restore and router wiring; do not alter `vertical_slice.gd`, main menu, shared reducer/snapshot/store, ID catalog or `project.godot` in this PR.
3. Confirm canonical hotspot availability/one-shot UX, scene interruption at every phase, full VN/Match-3 resume and failed-write policies in production with exact-head regressions.
4. Manually validate portrait/mobile navigation, input, overlay, physical actor feet, user-facing controls, RU/BE/EN dialogue and rewards; QA preview is not art/device/owner approval.
5. Validate production route against fresh main after other parallel agents merge; existing 08B draft must never silently replace an approved route.

## Owner QA, rollback and status impact

Owner QA NOT RUN. Open `scenes/raven/tests/game_loop_01a_qa_harness.tscn` with F6; select RM-HS-005, complete RM-LVL-001, select RM-HS-002, read bedroom VN; try cancel/reload/locked button. No real save is touched. Rollback: revert new adapter/test/harness/scene, runner line, this record and campaign-core shard evidence. No migration.

GAME-LOOP-01 remains P0/partial and not merged/accepted on account of this preparation PR. Shared `scripts/check.sh` test registration needs integration-owner coordination/review; no production reducer/save writes in this diff.
