# UPDS-first reuse audit and implementation gate — 2026-11-03

**Status:** source-code comparison and binding agent policy; not a claim of runtime/device parity. **Donor:** `bezdredoff/UPDS-godot@main` (pin exact commit and blob SHA in each implementation PR). Legacy `bezdredoff/UPDS` has a different export layout. **Target:** `bezdredoff/RavenManor-Godot`.

## Decision matrix

| Area | UPDS-godot donor | Existing Raven | Decision / gaps |
|---|---|---|---|
| Atomic file storage | `scripts/core/save_storage.gd` | `scripts/core/save_storage.gd` | Reused. Verify source parity, error injection, and browser/native persistence. |
| Save schema and recovery | `scripts/core/save_format.gd`, `campaign_store.gd` | `scripts/raven/raven_snapshot.gd`, `raven_campaign_store.gd` | **Adapter/extract**, not direct story import. Reuse validation, recovery backup, manual import/export patterns; preserve Raven schema/key/reducer. |
| VN session and branching | `scripts/core/story_session.gd` | `raven_vn_player.gd`, `raven_slice_director.gd`, `vertical_slice.gd` | **Extract/adapt** session lifecycle, choice and resume behavior. UPDS scene indexes and story content must not become Raven authority. |
| VN UI | `scripts/vn/vn_screen.gd`, `dialogue_paging.gd`, `portrait_motion_rig.gd` | `scripts/shared/upds/dialogue_paging.gd`, `raven_vn_game_view.gd` | Paging already reused. Audit Auto, Skip, history, manual save, layout and portrait effects for incremental extraction; do not wholesale copy large donor screen. |
| Match-3 rules | `scripts/match3/match3_game.gd` | `scripts/shared/upds/match3_game.gd`, `raven_match3_game.gd` | **Reuse-as-is + Raven adapter**; avoid a second rules engine. |
| Match-3 campaign/session | `scripts/match3/match3_campaign_session.gd` | Raven checkpoint/action replay in `raven_match3_game.gd`, `vertical_slice.gd` | **Adapter** for attempts/results; preserve deterministic action replay and canonical Raven save. |
| Menu/settings | `scripts/main_menu.gd`, `scripts/core/story_session.gd` | `scripts/raven/main_menu.gd`, `scripts/shared/upds/player_preferences.gd` | Preferences reused; reuse menu confirmation/error/recovery UX and tests without importing UPDS narrative navigation. |
| Regression | `tests/core/save_*_smoke.gd`, `tests/vn/*`, `tests/match3/*` | `tests/raven/upds_core_reuse_smoke.gd`, `session_lifecycle_e2e_smoke.gd` | Port behavior/fixtures with provenance, add native and browser E2E; CI pass is not device QA. |

## Implementation protocol
1. Check `main`, open PRs, target task ID and current CI **before editing**.
2. Read donor source and existing Raven adapters; record donor commit, path, blob SHA and decision `reuse-as-is / extract / adapter / new` in PR. New code requires explicit functional gap.
3. Keep only Raven reducer/store as authoritative progress owner. Maintain separate save keys and story IDs; never copy private UPDS story, art or translations into public Raven without rights clearance.
4. Prove parity for success **and failure** cases: failed writes/removes, corrupt JSON, scene/line continuation, choices, Match-3 retry/replay, localization, pause/menu, refresh and device behavior. Check upstream tests first.
5. Functional CI gates remain blocking. Dashboard task counts and similar administrative consistency warnings are advisory. A cancelled workflow is **not** a passed workflow.
6. Update `AGENTS.md` (if policy changes), `docs/STATUS.md`, `data/raven/production/production_progress.json` in the same PR. Record known gaps and no fabricated acceptance.

## Immediate next work
- **P0:** stabilize open GAME-UI-01 PR #165: headless E2E currently fails on VN cursor Continue after injected failed save; verify persisted raw storage before and after injection, and distinguish failure in test vs runtime. Do not merge until functional CI green.
- **P1:** make a narrow UPDS session-controller behavior/fixture parity PR, not a parallel full controller. Preserve Raven snapshot/reducer and existing VN Studio integration.
- **P1:** extract VN history/Auto/Skip/manual save from donor only where missing, in separate small PRs.
- **P2:** browser refresh/mobile QA and menu parity; only close GAME-UI-01 after verified acceptance.

**Evidence boundaries:** this audit is static source comparison, not an executed test report. Source paths and feature signatures were inspected in both repositories; exact upstream commit/blob pinning is required at the implementation step.
