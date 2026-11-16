# GAME-LOOP-01 — G2 host, persistence and Continue (isolated candidate)

**Task / domain:** GAME-LOOP-01 / campaign-core · **priority:** P0 · **branch:** `agent/campaign-core/GAME-LOOP-01-G2-host-persistence` · **baseline:** `main@0d1886b0d01491047dbd900b260757623c6ef9bc` · **status:** PR review only; **G2 not accepted**.

## Changes

1. `scripts/raven/raven_hotspot_gameplay_bridge.gd`: extract pure `story_available` / `story_arrival_proposal` used by both the G1 route bridge and G2 host. The arrival proposal evaluates existing `RavenSliceDirector.events_for`, stable `RM-*` IDs, and the authoritative reducer; it **never** persists progress or pretends to confirm movement. G1 event keys and persistence remain unchanged.
2. `scripts/raven/raven_gameplay_host.gd`: compose `ManorNavigationSource.resolve`, the **existing** `ManorGameplayIntegrationHarness` actor/controller, one `RavenCampaignStore`, the hotspot bridge's story gate, and the existing `vertical_slice.tscn` VN/Match-3 UI through store injection. No new graph, transition controller, match engine, campaign-state authority or free tap-to-move.
3. Enforce request, in-flight, arrival and post-presentation story-gate checks; canonical `RM-DOOR-*` unlock checks before a room transition, before dispatch, and before committing the physically ready portal. The segment mover/controller still validates actual feet and route legs.
4. Persist `position_checkpoint` **only at a confirmed authored safe anchor**, using `RavenReducer.apply` + `RavenCampaignStore.save_campaign`. Never persist a pending portal or arbitrary touch point. Continue reconstructs the room/actor at the validated safe anchor; invalid/unknown saved anchors fall back without pretending to save a replacement.
5. Reject corrupt/read-error saves; preserve the original raw save and donor-style recovery backup rather than proceeding with a silently fresh snapshot. A failed checkpoint or story write holds further input; return to Continue after the storage fault is resolved. Cancel/pause/repeated input do not grant story events.
6. `tests/raven/game_loop_g2_host_smoke.gd` and `scenes/raven/tests/game_loop_g2_qa_preview.tscn`: explicit **isolated, in-memory TEST_ONLY** source via already-reviewed 08B QA route fixture. Synthetic HC/CB passes through the real multi-room transition harness, with explicit `RM-DOOR-*` bindings for the QA controller, real existing Match-3 session and VN catalog. The fixture is not production navigation.

**No changes to:** `manor_gameplay_integration_harness.gd` (Agent D), `raven_vn_runtime_dispatch.gd` (Agent C), calibration assets (Agent A), `scripts/check.sh` / `check.ps1` (Agent E), production menus, `project.godot`, canonical narrative data, shared ID catalogs or the Raven save schema. In particular: **no production menu-to-map path is enabled by this PR**.

## UPDS-first donor audit / reuse decision

Checked the native donor **`bezdredoff/UPDS-godot@3deed628efd6c22bcd1717f7c545b7d3ca865781`**, not the older exported UPDS:

| Donor path | Blob SHA | Existing Raven consumer / reuse decision |
| --- | --- | --- |
| `scripts/core/save_storage.gd` | `37201dfebbe11854a590ea717ff3b844d2b9c48b` | `scripts/core/save_storage.gd` + Raven `raven_campaign_store.gd`; **reuse-as-is** atomic storage with Raven-specific recovery slot |
| `scripts/core/save_format.gd` | `ef88f27e66f94ef52aa488608d592b70618599fa` | `raven_snapshot.gd` normalization; **adapter**, no UPDS numeric story indexes |
| `scripts/core/story_session.gd` | `ac926a6fcdcbd359cdc4a36081d02be8cd7ebe02` | Raven `raven_slice_director.gd`, `vertical_slice.gd`; **adapter**, stable `RM-*` beats and VN resume remain authoritative |
| `scripts/match3/match3_campaign_session.gd` | `bda5f0468d6e070f74ef8f687097dc4524d0323e` | Existing `raven_match3_session.gd` and vertical slice; **reuse existing Raven adapter**, not new session |
| `scripts/ui/main_menu.gd` | `76e47a354b1ca42b4f029278382ad1e0070e7d09` | Existing `raven/main_menu.gd` donor-style error/Continue UX; **no menu changes pending production navigation acceptance** |

No UPDS story, private art, state indices or additional save key copied.

## Verification contract and evidence

**Authored standalone command (not run in this remote connector-only environment):**

```sh
godot --headless --path . --script res://tests/raven/game_loop_g2_host_smoke.gd --quit-after 360
```

**Existing full local suite (not run here):** `bash scripts/check.sh` (and Windows `check.ps1`); Agent E owns adding the G2 standalone smoke to both shared runners. The first command must print `GAME-LOOP-01 G2 isolated host/Continue/door/story/recovery smoke passed`; a file merely containing assertions is **not** evidence that a test was executed. Headless import/CI and device QA remain separately reportable.

G2 smoke assertions cover: canonical production source fail-closed/no state mutation; explicit QA opt-in and isolation; Hall → Corridor → Bedroom → Corridor → Hall using the original transition harness; locked CB until arrival/unlock; actor-contact-before-progress; cancel/no event, duplicate request rejection; safe-anchor checkpoint/Continue; failed atomic write causing safe hold and last committed room recovery; corrupt save recovery backup with no silent overwrite; actual UPDS-derived Match-3 session first-clear reward exactly once and the existing RM-REST-001 2-point cost; three-language VN catalog and previously-read-only Skip boundary.

**Manual QA:** open `res://scenes/raven/tests/game_loop_g2_qa_preview.tscn` in Godot 4.7.2. UI is deliberately labeled TEST ONLY. Observe the same route/door/scene handoffs and physically inspect actual Evelyn visual once Agent D's actor integration lands; current map harness actor is still temporary. No physical phone, touch input, web refresh, art/foreground or owner geometry acceptance is claimed.

## Hard gate, risk and follow-ups

- **Agent A / owner:** HC under central stair landing and CB threshold/floor/foreground/collision/65° footpoints remain `DRAFT_ONLY`, `productionReady=false`; owner-approved `PRODUCTION_APPROVED` world-plan/calibration and correct doors are not present. The canonical source remains fail-closed. The QA test's explicit synthetic transitions do not grant approval.
- **Agent D:** merge approved Evelyn production walker integration and check compatible actor API plus footpoint/occlusion/mobile performance. This PR does not edit D's harness.
- **Agent C:** production VN dispatcher for later Season 1 scenes; existing RM-VS-01 VN/Match-3 behavior remains unchanged. Production story/scene approvals separate.
- **Agent E:** register `tests/raven/game_loop_g2_host_smoke.gd` exactly once in the shared runners, integrate failure-mode QA, validate Web/desktop/portrait device before activation.
- **Integration owner after those gates:** bounded follow-up PR to route New Game/Continue to real map when appropriate, wire player-facing objectives/room visuals and enforce production source approval; no implicit switch to draft geometry. No forced migration of production saves into the QA fixture coordinate space.

**Rollback:** close the PR without merging; if merged later, revert this PR's commits. G1 bridge remains compatible with the previous session/reducer format; no save schema or production geometry migration is introduced.

## Status / owner acceptance

Implementation candidate for **isolated G2 QA only**. Production menu-to-map functional loop, full G2, phone/device QA and owner acceptance **pending**. Campaign-core status remains `PR_review` / partial / approval pending with per-PR evidence in the owning shard. Record actual exact-head CI/merge proof separately after GitHub Actions finishes; never infer success from test source inspection.
