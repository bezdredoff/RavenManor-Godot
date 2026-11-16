# VN-RUNTIME-01 — Chapter II–III review-only scene readiness and Hall Tea regression

Task IDs: **VN-RUNTIME-01**. Dependency: **CODE-08-01** (campaign-core; do **not** duplicate its status entry). Domain: `vn-runtime`. Base: `main@0d1886b0d01491047dbd900b260757623c6ef9bc`, 2026-11-17.

## Changes

- Added `data/raven/production/vn_chapters_ii_iii_readiness.json`, an **explicitly review-only** eight-scene integration handoff. It records exact canon line IDs/counts, RU/BE/EN completeness, cast/staging/accepted background, pose×emotion deficits, affected line-cue IDs, runtime gate support, unregistered save beats and current promotion blockers.
- Added `tests/raven/vn_chapters_ii_iii_readiness_fixture.gd`. It audits all eight scenes against authoritative source data and constructs a **deep-copied synthetic** runtime-approved `RM-BEAT-02-01` from all **12 real canonical lines**. Only within the test, Ada's accepted `composed/dry_amused` art path stands in for the missing `offer_tray/dry_amused`; this tests renderer/dispatcher contract, **not acceptance of that pose**. It checks real RU/BE/EN text and speakers, predecessor gate refusal/acceptance, full VNPlayer completion, reducer event idempotence, in-memory store reload, two-line cursor/Skip resume, choice and Match-3 Skip boundaries, and rejection of absent art/approval/BE locale/manual cue/fractional ordinal/unsupported NPC gate.
- Registered the fixture by calling it from the **existing, already-wired** `tests/raven/vn_production_runtime_dispatch_smoke.gd`. No shared `scripts/check.sh`, `check.ps1`, workflow, save/reducer/dispatcher, physical map, canonical story/cue/portrait registry or approved art changed.
- PR records progress **only** in `data/raven/production/progress/vn-runtime.json`.

## Per-scene findings (current canonical catalogs)

| Scene | Lines | Accepted backdrop | Existing gate | Save beat | Missing accepted portrait variants; cue art affected |
|---|---:|---|---|---|---|
| `RM-BEAT-02-01` | 12 × RU/BE/EN | `BG-HALL` `day/habitable` (accepted) | `scene_complete:RM-BEAT-01-05` | registered | `RM-CHAR-ADA/offer_tray/dry_amused`; 6 cue lines |
| `RM-BEAT-02-02` | 13 × RU/BE/EN | `BG-ENTRY` `day/approachable` (accepted) | `npc_tap:RM-CHAR-ROWAN` | **not registered** | `RM-CHAR-ROWAN/point_route/wry`; 7 cue lines |
| `RM-BEAT-02-03` | 19 × RU/BE/EN | `BG-KITCHEN` `day/power_off` (accepted) | `object_tap:PROP-HOUSEHOLD-LEDGER` | **not registered** | `RM-CHAR-EVELYN/investigate/curious`; 10 cue lines |
| `RM-BEAT-02-04` | 13 × RU/BE/EN | `BG-KITCHEN` `evening/partial_lighting` (accepted) | `specialist_result:kitchen_power_safe` | **not registered** | none; 0 cue lines |
| `RM-BEAT-03-01` | 7 × RU/BE/EN | `BG-LIBRARY` `evening/shut_dusty` (accepted) | `door_tap:RM-DOOR-HALL-ARCHIVE` | **not registered** | `RM-CHAR-LUCAS/folder_present/professional`; 2 cue lines |
| `RM-BEAT-03-02` | 13 × RU/BE/EN | `BG-LIBRARY` `evening/usable` (accepted) | `object_tap:PROP-FAMILY-ALBUM` | **not registered** | `RM-CHAR-LUCAS/explain/professional`; 3 cue lines |
| `RM-BEAT-03-03` | 10 × RU/BE/EN | `BG-LIBRARY` `evening/usable` (accepted) | `npc_tap:RM-CHAR-LUCAS` | **not registered** | `RM-CHAR-EVELYN/investigate/worried`, `RM-CHAR-LUCAS/explain/serious`; 10 cue lines |
| `RM-BEAT-03-04` | 9 × RU/BE/EN | `BG-LIBRARY` `day/usable` (accepted) | `object_tap:PROP-LIBRARY-DESK` | **not registered** | `RM-CHAR-EVELYN/investigate/worried`; 5 cue lines |

All **96/96** Chapter II–III authored lines have nonempty `ru`, `be`, `en` cells (**288/288**). No offstage speakers, hidden cue portraits or `manualReview=true` cues were detected in these eight scenes. All eight scene background variants are catalog-accepted and point to their matching `res://assets/raven/vn_backgrounds/` files; runtime ResourceLoader existence is checked by the headless fixture. Across the eight scenes there are **7 distinct missing accepted pose×emotion variants**, affecting **43 cue lines**.

### Immediate Hall Tea promotion boundary

`RM-BEAT-02-01` has:
- `status=pilot_runtime` (not `runtime_approved`), ordinal `8`, `approvedRuntime=false`, `proposedRuntime=true`;
- a **supported** `scene_complete:RM-BEAT-01-05` gate, based on `storyBeatsSeen`; its save beat is already registered;
- target `hall_chair_table`, requiring owner-approved physical approach/arrival and playable dispatch handoff;
- accepted `BG-HALL day/habitable`, canonical Evelyn `relaxed/neutral`; missing **Ada `offer_tray/dry_amused`**, including the six exact cue IDs recorded in the manifest;
- no outstanding tri-locale text, cast, stage slot, cue-manual-review or ordinal-type issue.

**Do not** promote the scene because the synthetic test passes. Real Ada variant review and Hall/table geometry remain human/Agent B dependencies.

### Gate contracts beyond 02-01 (fail closed)

- `02-02` / `03-03`: `npc_tap` is currently **unsupported**; require an authoritative verified NPC approach/tap interaction token that survives save/restore as intended.
- `02-03`, `03-02`, `03-04`: `object_tap` is **unsupported**; require canonical physical prop/hotspot interaction completion, not merely an object existing in staging.
- `02-04`: `specialist_result:kitchen_power_safe` is **unsupported**; requires the corresponding specialist result event and validated persisted state. Match-3 completion alone is not proof of electrical repair.
- `03-01`: `door_tap:RM-DOOR-HALL-ARCHIVE` is **unsupported**; requires a physical Hall/Archive door interaction/arrival contract, not a fabricated tap or an unrelated unlocked door.
- `02-02` through `03-04`: seven beat IDs are not registered by the Foundation save whitelist. Agent B must explicitly review and register each when approved. Until then reducer/store must reject/strip their completion.

## Exact Agent B integration handoff

1. Keep the production trigger / story / scene authority in existing campaign-core and map systems. Review each manifest `gate`, `interactionTarget`, geometry and owner decision; do not auto-true any unsupported gate.
2. Acquire owner approval for the required artwork through character-art domain; do not reuse the synthetic Ada alias in real assets. Confirm each catalog asset actually loads and fits on target phone.
3. For `02-01`, after Hall chair/table arrival, verify `RM-BEAT-01-05` in authoritative `storyBeatsSeen`; *then* coordinate a reviewed `runtime_approved` scene status and route approval. Do not change all 8 scenes at once.
4. Bind scene completion to the existing `story_beat_seen` reducer event and save cursor/line history, with idempotent `eventId`, before continuing to the physical safe anchor. Keep cancel/re-entrance/restart and room position testable.
5. For `02-02`–`03-04`, add a **documented authoritative state/event contract first**, per-scene registration/approval second, and newly supported dispatcher predicates only in a coordinated follow-up after the contracts exist.
6. Re-run the registered VNS5-06D2C smoke, Season 1 audit, VN Skip and tri-locale save/reload; reconcile the manifest and CODE-08-01 audit only when approved production status changes. Owner QA for choices, line/page pagination and device background/portrait fit remains separate.

## UPDS-first reuse decision

Checked `bezdredoff/UPDS-godot@3deed628efd6c22bcd1717f7c545b7d3ca865781`, `scripts/vn/vn_screen.gd` (blob `c44edec0f4a29f05e128cf2d4005009adca0f842`) and `scripts/vn/dialogue_paging.gd` (blob `d9f22ca8533017d112a62ec174fd2c66546e4290`). Raven already incorporates the relevant line/page and read-only Skip behavior through `scripts/shared/upds/dialogue_paging.gd`, `raven_vn_game_view.gd`, `raven_vn_read_history.gd` and existing parity smoke tests. **Reuse decision: reuse existing Raven adapter/tests as-is**, add only canonical source-copy regression. No second VN controller, save source or upstream private story/assets imported.

## Verification, QA and rollback

- **Data audit:** source-catalog comparison and manifest generation over current `main`, 8 scenes, 96 lines and 43 missing cue-art occurrences — completed as static source analysis.
- **New Godot smoke:** check via registered `VN VNS5-06D2C canonical-only runtime VN dispatch` stage; Godot CLI is not available in this execution environment, so **NOT_RUN locally**. Exact-head GitHub Actions status must be checked and reported, not inferred.
- Existing smoke tests preserved: `campaign_season1_audit_smoke.gd`, `vn_read_skip_smoke.gd`, `vn_locale_save_parity_smoke.gd`, prior D2C synthetic dispatch cases. Native phone/owner QA: **NOT_RUN**.
- Rollback: revert this PR's two review/test additions, small D2C test invocation and vn-runtime shard/doc update. No migration or game-save changes, no canonical scene approval or art promotion.
- Status impact: only existing VN-RUNTIME-01 progress entry; `CODE-08-01` remains campaign-core-owned, partial. No claim of merged/accepted/device verified.
