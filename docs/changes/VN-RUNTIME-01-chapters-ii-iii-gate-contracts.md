# VN-RUNTIME-01 / VN-GATES-01 — Chapter II–III authoritative gate contract

**Task IDs:** `VN-RUNTIME-01` (registered vn-runtime P1); `VN-GATES-01` is a delivery label, **not** a new registered task.  
**Baseline:** `main@32a8d98d2fd3e75bf7613b8391f5ea7a769abd5a` after #291 (2026-11-17).  
**Branch:** `agent/vn-runtime/VN-RUNTIME-01-chapters-ii-iii-gate-contracts`.  
**Scope:** documentation and existing vn-runtime shard evidence only; no scene/route/portrait/ID/runtime/save/CI changes.

## Changes

- Created `docs/production/VN_CHAPTERS_II_III_GATE_CONTRACTS.md`, mapping all seven **later** beats `RM-BEAT-02-02` to `RM-BEAT-03-04` to exact gate kind/ref, proposed spatial room/interaction, prerequisite, verified movement, trusted event boundary, save/reload/Continue, cancellation, one-shot/replay, present implementation gap and owner acceptance requirement.
- Explicitly separated `npc_tap`, `object_tap`, `door_tap` and `specialist_result` from generic UI taps, descriptive route `interactionTarget` and a synthetic test catalog. Highlighted that the current dispatcher does not enforce sequential predecessor for these four kinds, and `library` currently names two different scene targets.
- Described a *real*, trusted electrical specialist completion flow for `specialist_result:kitchen_power_safe`. Match-3/`workPoints` preparation and powered-room art do not prove electrician work. No speculative story flags, receipts or new save fields are authored.
- Traced missing live Entry, Kitchen and Archive production geometry/room IDs, Hall–Archive door and all seven target anchors. Recorded that Agent B owns the live Hall Tea integration, Agent A owns accepted-portrait reuse, and the campaign-core integrator owns future shared host/reducer/catalog changes.
- Added prioritized descriptive follow-ups and positive/negative acceptance inventory; **no new task registry entry** or test pretending new gameplay exists.
- Appended review-only follow-up evidence to existing `VN-RUNTIME-01` in `data/raven/production/progress/vn-runtime.json`. Preserved its historical `merged` delivery status and `partial` implementation state (prior #277/#228 merges), with manual QA still pending. This new scoped PR is **Draft, unmerged**.

## UPDS-first check

Donor: `bezdredoff/UPDS-godot@3deed628efd6c22bcd1717f7c545b7d3ca865781`; examined `scripts/core/story_session.gd` (blob `ac926a6fcdcbd359cdc4a36081d02be8cd7ebe02`), `scripts/core/campaign_store.gd` (blob `beec31048dfd721c43fa4bf53917665028ae4eed`), `scripts/match3/match3_campaign_session.gd` (blob `bda5f0468d6e070f74ef8f687097dc4524d0323e`), and `scripts/vn/dialogue_paging.gd` (blob `d9f22ca8533017d112a62ec174fd2c66546e4290`). Raven already includes matching UPDS paging blob `scripts/shared/upds/dialogue_paging.gd@d9f22ca8533017d112a62ec174fd2c66546e4290` and `raven_vn_game_view.gd`, `raven_vn_player.gd`, `raven_match3_game.gd`/adapter, own `raven_snapshot.gd`, reducer/store and production map host. **Reuse classification:** existing VN/UI mechanics = reused/adapter; existing Raven save/reducer and host = reuse as-is boundary; future typed Raven-specific map interaction and contractor validation = required **adapter extension**, not a second UPDS story session, UI or persistence implementation. This documentation PR adds no new code.

## Verification (honest state)

**Performed:** inspected root/nested agent rules and canonical route/readiness/dialogue/Foundation source, dispatcher, host, reducer/snapshot/store, map candidate and donor; ran a read-only seven-scene structured assertion against the exact main SHA. **PASS (0 failures):** all seven scene IDs and kind/ref pairs match route/readiness, none is currently registered or runtime-promoted, the four gate kinds remain unsupported, Hall–Archive door is unregistered, and the actual production room list is Hall/Corridor/Bedroom. Current snapshot version is 1.

**Not performed:** local Godot/headless regression (`NOT_RUN`: Godot not available in execution environment); exact-head GitHub PR CI (`PENDING` until PR exists); Windows/phone/browser QA (`NOT_RUN`); normal gameplay execution of any later scene (`NOT_IMPLEMENTED`). The existing `vn_chapters_ii_iii_readiness_fixture.gd`/`vn_production_runtime_dispatch_smoke.gd` synthetic coverage is documented, not mistaken for tests rerun here. No new standalone negative test was added: a fake approval/interaction success harness would not prove real physical gates.

## Owner QA and acceptance gates

**Owner QA:** `NOT_RUN`. The contract itself requests review, not scene approval. Required later: Agent A-approved substitutions integrated with true catalog pose/emotion metadata; Agent B Hall Tea normal flow and Continue; architecturally approved and truly traversable Entry/Kitchen/Archive map/props/NPCs; specialist work completion authority; per-beat scene/predicate registration; exact-head CI and physical-phone inspection. Do not relabel planned geometry or #291 V4 approval as a Chapter II–III playable room.

## Status impact and exclusions

Only `VN-RUNTIME-01` existing vn-runtime entry gets appended audit evidence; retain its current `status=merged` for **earlier merged delivery**, `implementationState=partial`, `qaState=manual_pending`, `approvalState=not_recorded`, P1. New VN-GATES-01 contract is Draft/unmerged until independently verified; status must not imply this PR merged. No CODE-08-01 duplicate, VN-RUNTIME-02 task registration, shared registry/ID modification, generated dashboard, frozen progress, asset, route approval, scene status, donor import, save migration or CI modification.

**Review risk:** implementing a gate by checking a bare `storyFlags` membership, descriptive `interactionTarget`, `unlockedDoors` membership, NPC existence or proposed map anchor alone would violate the trust boundary. In particular, 02-04 must require trusted persisted electrician completion **and** independently verified kitchen access; 03-01 needs physical Hall→Archive transition; 03-03 cannot inherit 03-01's generic `library` tap. Unimplemented conditions must remain fail closed.
