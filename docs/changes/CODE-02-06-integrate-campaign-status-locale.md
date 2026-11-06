# CODE-02-06 — Integrate the localized bonus Match-3 status with vertical_slice

Task IDs: CODE-02-06 (P0, bounded shared-shell integration slice).

Changes: make OptionalCampaign the single locale-aware status/title-copy provider and replace the Russian-only hard-coded status consumer in vertical_slice.gd. Strengthen the existing real menu → vertical-slice smoke to exercise RU, BE, EN runtime switches and list/header parity, while proving story/save revision unchanged. Add model fallback tests.

Verification: source compared with UPDS native donor. Godot not installed in the assistant runtime; local test execution NOT_RUN. Mandatory GitHub Actions full six blocking jobs must pass at exact PR head before merge. Browser/real-phone QA NOT_RUN.

Owner QA: in the public game switch RU → BE → EN while the additional campaign list is open. Verify top status string and level-list content change together; return via main-menu/story. Check narrow phone viewport, wrapping, no extra reward/points and unchanged progress.

Status impact: prior #219 merged evidence recorded in match3 shard; CODE-02-06 stays P0, partial, not owner/device approved. This integration does NOT satisfy full UPDS Match-3 visual parity.

## Baseline / ownership
- Repo: bezdredoff/RavenManor-Godot, main 511e47eb256f3f33c46199bf56f9f460e0ed9ddf, no open PR on initial scope audit.
- Branch: integration/CODE-02-06-campaign-status-locale (single writer for shared vertical_slice.gd; explicit user authorization).
- Exact files: scripts/raven/raven_optional_campaign_controller.gd, scripts/raven/vertical_slice.gd, tests/raven/optional_campaign_controller_smoke.gd, tests/raven/main_menu_match3_campaign_smoke.gd, data/raven/production/progress/match3.json, and this note.
- Excluded: snapshot/store/reducer, stable RM IDs, shared UPDS engine, rewards/boosters, Art, VN Studio or Hall.

## Donor and reuse
- UPDS-godot@3deed628efd6c22bcd1717f7c545b7d3ca865781 native campaign UI scripts/match3/match3_campaign_screen.gd blob 5af00e5c02eec14a25b3b1a5aa1d0f594e90927a; refresh_screen selects bundle.campaignLocalized and per-level localized display, and refreshes on language-changed.
- **Adapter**. Reuse Raven's previously approved UI_COPY added by #219; add status and campaign title to the same locale dictionary. Existing Russian STATUS_COPY remains as exact backward-compatible constant. No donor story/assets/session are copied.
- _render_optional_campaign obtains both status and campaign_step title using preferences.locale, so the shared shell, list and metadata are aligned after _switch_locale.

## Tests
- godot --headless --path . --script res://tests/raven/optional_campaign_controller_smoke.gd --quit-after 180
- godot --headless --path . --script res://tests/raven/main_menu_match3_campaign_smoke.gd --quit-after 180
- bash scripts/check.sh; python3 scripts/raven/tools/progress_shards.py
- Full GitHub required CI exact-head PASS: data-contracts, godot-runtime, room-builder, art-pipeline, web-package, build.
- Existing dashboard snapshot warnings are separate advisory reports; do not disable functional gates.

## Rollback / follow-up
- Revert isolated integration PR; no persistent schema or campaign progress change.
- **Separate next task:** structural/visual comparison and UPDS-first Match-3 screen parity; no claim this status fix changes main Match-3 HUD/board.
