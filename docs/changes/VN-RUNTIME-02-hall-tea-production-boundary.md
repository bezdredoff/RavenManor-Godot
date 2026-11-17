# VN-RUNTIME-02 — Hall Tea production-dispatch boundary and Chapter II–III handoff

Task IDs: VN-RUNTIME-01 (registered P1 owner; VN-RUNTIME-02 is the bounded follow-up delivery label, not yet a registered task ID).
Changes: Physically triggered production VN scenes no longer auto-play; exact-target, production-host/footpoint opt-in selector; Hall Tea tri-locale synthetic fixture; eight-scene handoff.
Verification: Local Godot NOT_RUN; exact-head GitHub CI PENDING; existing registered Chapter II–III smoke extended, no art/production promotion.
Owner QA: NOT_RUN; Ada offer_tray/dry_amused, Hall/table physical arrival, phone tri-locale presentation and save/Continue still require approval.
Status impact: vn-runtime only, existing VN-RUNTIME-01 progress evidence updated for draft PR #287; no new unknown task ID. Eight canonical Chapter II–III scenes remain disabled, CODE-08-01 untouched.

**Task IDs:** registered VN-RUNTIME-01 (vn-runtime, P1); VN-RUNTIME-02 is a follow-up delivery label pending integration-owner registration. **Baseline:** `main@ddcc8a646ffbfa60dcfea43849a592bfdddd9f24` after merged #271, #277, #280 (2026-11-17). **Owner QA:** NOT_RUN. **Production promotion:** NO.

## Changes and exact ownership

- `raven_vn_runtime_dispatch.gd`: the existing legacy `next_scene()` entrypoint now selects **only approved `auto_new_game`** scenes. It cannot silently trigger physically gated Hall Tea when Chapter I ends. Existing `find_approved()` remains the read-only/catalog-injected selector used in synthetic tests; optional target scoping and explicit auto-only mode do not affect canonical authoring.
- `next_scene_at_confirmed_hotspot(host, hotspot_id, locale)`: new **opt-in** production selector, using the actual Raven gameplay host script, non-draft source, actor not moving, no pending door transition, confirmed authored room/interaction anchor and a ≤0.25-unit physical footpoint check. It does not accept arbitrary `approved=true` or `tap=true` flags, does not mutate/reward/save, and does not expose canonical scenes lacking scene, route, foundation, locale, cue, accepted asset and predecessor approvals. Agent B must call it only after committing the real map arrival; there is **no new player-facing activation** in this PR.
- Selection returns exact `interactionTarget` and strict integral `ordinal`, making the proposed host handoff reviewable. Canonical `RM-BEAT-XX-YY-L001...` order is now required before a scene can be selected; no silent save-cursor remapping on reordered source.
- The already registered `vn_chapters_ii_iii_readiness_fixture.gd` regression exercises Hall Tea with a **deep-copy synthetic** runtime/route/art approval, all 12 real canonical lines in RU/BE/EN, correct `hall_chair_table` targeting, unrelated-target rejection, auto-play rejection and fake-host rejection. It retains existing reducer idempotence, Save/Continue, read-only Skip, choice/Match-3 boundary and missing-art/locale/cue negative tests. It is invoked from `vn_production_runtime_dispatch_smoke.gd` in normal CI.
- Only this domain's existing registered progress entry changes; VN-RUNTIME-02 is not yet a known task ID in the shared work-package catalog. No canonical text, approved assets, runtime statuses/routes, Foundation, shared gameplay host, reducer, snapshot, store, `vertical_slice.gd`, runner or generated dashboard changes.

## Why the production auto-boundary matters

`vertical_slice.gd` invokes `RuntimeDispatch.next_scene()` after the legacy director reports `done`. Before this change, a future route promotion could start Hall Tea **without** map interaction or physical arrival. This PR protects that path immediately; actual delivery from map to VN remains Agent B's reviewed integration work. The new callable refuses the current DRAFT_ONLY map source. A synthetic fixture PASS is **not** art approval, map acceptance or a normal-game end-to-end PASS.

## Explicit Agent B and Agent C handoffs

**Agent B (sole campaign-core writer):** once approved production HC/CB and the target's physical anchor exist, call `RuntimeDispatch.next_scene_at_confirmed_hotspot(self, actual_arrived_hotspot_id, locale)` at the existing *validated* `_commit_story_arrival` boundary. Cross-check the scene's returned `interactionTarget`, room/presentation mode and live target availability. Use the existing `RavenVNPlayer` + `RavenVNGameView` + `ReadHistory` line/page path, reducer `story_beat_seen` after a true final advance, and existing `RavenCampaignStore` cursor/read-history/position persistence; no new controller, schema or reward. Preserve failure/cancel/re-entry behavior; fix any mismatched ID mapping via the integration PR rather than a fabricated Boolean. Review `scene_complete` predicate against real `storyBeatsSeen`. Register seven future save beats only after their explicit contract/owner review.

**Agent C (character-art):** deliver seven exact pose×emotion variants with per-file provenance and owner acceptance. For Hall Tea, the specific `RM-CHAR-ADA/offer_tray/dry_amused` must be accepted and actually present in production catalog; the synthetic `composed/dry_amused` alias is NEVER acceptable production art.

**Agent B + VN-runtime jointly:** before enabling `npc_tap`, `object_tap`, `door_tap` or `specialist_result`, define versioned, validated interaction state/events from the authoritative navigation/reducer/save boundary. Do not dispatch from UI-provided Booleans, NPC presence, unlocked-door alone or Match-3 completion mistaken for specialist repair. Fail closed if room, NPC, object or specialist is inaccessible or not accepted.

## Scene-by-scene progression and regression matrix at this PR

| Scene | Canonical RU/BE/EN lines | Synthetic executable | Production executable | Remaining gate/art/map/state approval |
| --- | ---: | --- | --- | --- |
| `RM-BEAT-02-01` Hall Tea | 12 per locale | **YES — synthetic fixture only**, producer status untouched | **NO** | Ada `offer_tray/dry_amused` (6 cue lines); approved `hall_chair_table` physical arrival; scene/route promotion by Agent B; device QA |
| `RM-BEAT-02-02` Rowan entry | 13 | NO new runtime fixture | NO | `npc_tap:RM-CHAR-ROWAN`, accepted `point_route/wry`, Entry route/room decision, save registration |
| `RM-BEAT-02-03` Ledger | 19 | NO | NO | `object_tap:PROP-HOUSEHOLD-LEDGER`, Evelyn `investigate/curious`, Kitchen arrival, save registration |
| `RM-BEAT-02-04` Kitchen result | 13 | NO | NO | `specialist_result:kitchen_power_safe` authoritative repair, kitchen access, save registration; portraits already accepted |
| `RM-BEAT-03-01` Library | 7 | NO | NO | `door_tap:RM-DOOR-HALL-ARCHIVE`, Lucas `folder_present/professional`, physical Archive door and save registration |
| `RM-BEAT-03-02` Album | 13 | NO | NO | `object_tap:PROP-FAMILY-ALBUM`, Lucas `explain/professional`, Library access and save registration |
| `RM-BEAT-03-03` Memory | 10 | NO | NO | `npc_tap:RM-CHAR-LUCAS`, Evelyn `investigate/worried`, Lucas `explain/serious`, NPC access and save registration |
| `RM-BEAT-03-04` Letter | 9 | NO | NO | `object_tap:PROP-LIBRARY-DESK`, Evelyn `investigate/worried`, Library prop and save registration |

The existing review manifest preserves **96** canonical scene lines (288 RU/BE/EN text cells), **7** distinct missing exact portrait combinations across **43** cue appearances at this baseline. All eight background variants are accepted. The manifest remains review-only and all eight canonical scene statuses/routes remain disabled.

## Regression and acceptance checklist

1. Registered Godot smoke `tests/raven/vn_production_runtime_dispatch_smoke.gd` must PASS at PR exact head; it calls the Chapter II–III fixture. Legacy `RM-VS-01`, `vn_read_skip_smoke.gd`, `vn_locale_save_parity_smoke.gd` and G2 gameplay host smokes must remain green.
2. Full GitHub Actions: `data-contracts`, `godot-runtime`, `room-builder`, `art-pipeline`, `web-package`, aggregate `build`, all exact-head PASS before owner merge. **Not run locally**: Godot 4.7.2 binary and GitHub network are unavailable in the local container; GitHub CI evidence must be attached separately.
3. Before canonical Hall Tea promotion: owner approves Ada variant, actual Hall/table route and physical height/foreground, RU/BE/EN phone visual, read-only Skip/Auto/choice, cancel, reload mid-line and end-of-scene, repeat interaction with no duplicate beat/reward, and proper Continue safe anchor.
4. Seven other scenes stay separately blocked until each has its own state/art/map/scene acceptance. No claim “eight scenes complete”.
5. Open dependent PR #282 (VN-RUNTIME-01 status reconciliation) also writes `vn-runtime.json`; rebase after it merges before owner review if needed.

## UPDS-first reuse and rollback

Donor checked: `bezdredoff/UPDS-godot@3deed628efd6c22bcd1717f7c545b7d3ca865781`, `scripts/vn/vn_screen.gd` blob `c44edec0f4a29f05e128cf2d4005009adca0f842` and `scripts/vn/dialogue_paging.gd` blob `d9f22ca8533017d112a62ec174fd2c66546e4290`. **Decision:** reuse existing Raven UPDS paging/player/history/view/store adapters; only extend the Raven-specific scene-selection boundary. No UPDS StorySession or private assets.

**Verification now:** code/catalog read-only audit and targeted regression code added; local Godot **NOT_RUN**; CI **PENDING** until exact-head run. **Owner QA:** NOT_RUN. **Rollback:** revert this scoped PR; no save schema migration, art promotion or authoritative state changes occurred.
