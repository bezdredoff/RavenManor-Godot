# CODE-02-06 — Optional Match-3 campaign list RU/BE/EN localization

Task IDs: CODE-02-06 (P0 scoped Match-3 UI parity), related GAME-M3-01 (already merged campaign, not reopened).

Changes: adapt UPDS locale-keyed list presentation to Raven optional campaign. Translates intro, next, level, locked, play, replay and story-return controls for RU/BE/EN, preserving existing Russian text, 22 level IDs, unlock/replay decisions and existing return-to-menu localization. The independent controller smoke now verifies complete, partial, locked and fallback states, mobile tap heights and callbacks.

Verification: native UPDS source compared read-only. Godot executable unavailable locally: local checks NOT_RUN. All six exact-head required GitHub CI jobs must pass before merge. Physical mobile and browser QA NOT_RUN. Known dashboard snapshot advisory not changed.

Owner QA: switch RU/BE/EN; enter bonus Match-3 campaign via main menu and story, verify all list captions, locked/completed/replay and back navigation. Test 320/340/360/390/430px for clipping (especially Belarusian). Confirm locale switching does not mutate rewards, story save, firstClearLevels or booster inventory.

Status impact: reconciled merged #211 with exact merge SHA and passing CI. CODE-02-06 remains P0, implementationState partial and owner/device approval pending. The new PR is only a scoped UI list slice.

## Baseline and exact file scope
- Raven main: a7b2b8375055873c684a17beb76bb5fb80db6808 (2026-11-06); unrelated Room Builder merged since first audit, no open Match-3 PR.
- Branch: agent/match3/CODE-02-06-optional-campaign-locale.
- Files: scripts/raven/raven_optional_campaign_controller.gd, tests/raven/optional_campaign_controller_smoke.gd, tests/raven/main_menu_match3_campaign_smoke.gd, data/raven/production/progress/match3.json and this unique note.
- Do not modify vertical_slice.gd, store/reducer/snapshot, shared UPDS, canonical IDs, art, Hall or VN Studio.

## UPDS first: provenance and reuse decision
- Donor bezdredoff/UPDS-godot@3deed628efd6c22bcd1717f7c545b7d3ca865781
- scripts/match3/match3_campaign_screen.gd blob 5af00e5c02eec14a25b3b1a5aa1d0f594e90927a; refresh_screen reads campaignLocalized and levelPresentations[].localized by locale, then labels unlocked/locked/play/replay.
- Decision: ADAPT donor locale-keyed presentation dictionary to already-existing Raven OptionalCampaign.render_list. Do not copy donor story, art, campaign/session state or default fallback (Raven defaults to RU). No new controller; no reward or save changes.

## Integration-owned gap left open
- scripts/raven/vertical_slice.gd::_render_optional_campaign writes OptionalCampaign.STATUS_COPY, a Russian-only outer status header. campaign_step() exposes a Russian metadata title. This PR deliberately does not touch the shared vertical_slice; a separate integration-owner change is needed for those strings. Do not claim complete game UI locale parity.

## Verification commands and rollback
- godot --headless --path . --script res://tests/raven/optional_campaign_controller_smoke.gd --quit-after 180
- godot --headless --path . --script res://tests/raven/main_menu_match3_campaign_smoke.gd --quit-after 180
- bash scripts/check.sh
- python3 scripts/raven/tools/progress_shards.py
- python3 scripts/raven/tools/build_production_dashboard.py --check
- Required checks: data-contracts, godot-runtime, room-builder, art-pipeline, web-package, build.
- Rollback: revert this UI-only PR; no save-schema migration or asset changes.

## First CI failure and correction
- First head 2765a2ab45b18ff35d814f40aa66f33d253d0ced: godot-runtime FAIL because the existing main-menu campaign route smoke selected the first level only when its caption began with Russian text, while localized captions legitimately differ.
- Added the route smoke to this owned test allowlist. It now selects the first enabled campaign button (existing catalog is ordered by campaignIndex), then still asserts the started level ID is exactly RM-LVL-101, menu return, and unchanged save/revision.
- Functional routing assertions were preserved; no gameplay test disabled. All six checks need rerun on the new exact head.
