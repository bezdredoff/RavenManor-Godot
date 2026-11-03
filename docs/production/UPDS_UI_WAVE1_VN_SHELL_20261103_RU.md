# GAME-UI-01 · Wave 1 — VN shell extraction/adaptation

Baseline Raven: `913b9cdf0afdb99538b4161a12eef9cd73299108`. Donor UPDS-godot: `3deed628efd6c22bcd1717f7c545b7d3ca865781`.

## Provenance / dependencies

| Source | Blob SHA | Decision |
|---|---|---|
| scripts/vn/vn_screen.gd | c44edec0f4a29f05e128cf2d4005009adca0f842 | extract/adapt `_layout_vn`, `_build_controls`, `_paginate_dialogue`, `_on_dialogue_gui_input` into existing compositor + pure geometry |
| scripts/ui/phone_frame.gd | 3656f7568ef5b1a8bc65c293b70386df4b467e64 | adapt 430×932 desktop cap; preserve existing Raven canvas stretch and native safe-inset conversion |
| scripts/vn/dialogue_paging.gd | d9f22ca8533017d112a62ec174fd2c66546e4290 | reuse existing shared UPDS pagination; two-line fit adapter |
| scripts/ui/ui_fonts.gd | 82258014f3111b3d2c9f778676b8b4f51c6e4bf2 | donor bundled font assets not imported; existing Raven theme font retained; no pixel/font parity claim |
| scripts/ui/menu_theme.gd | 77f15a12c551dcbe74d301141cf5b225ff6d32b8 | Raven palette adapter; no school theme/icon assets imported |
| scripts/core/story_session.gd | ac926a6fcdcbd359cdc4a36081d02be8cd7ebe02 | not applicable to layout; Raven director/store authoritative |
| scripts/ui/player_preferences.gd | ea81a778c7adf7c0eac2834cd5be577878069153 | existing preferences retained; settings expansion is Wave 3 |

Donor dependencies include story JSON, asset catalogue, portrait rig, shaders, fonts, menu copy, Match-3 campaign and audio runtime. They are deliberately not transitively copied into Raven. Artwork/FX remain the approved Raven registries. Footer actions currently map to available Raven Skip/Auto/Next; donor Save/Load overlays follow later. This increment is not full donor feature or pixel parity.

## Changes and acceptance

`raven_vn_game_view.gd`: independent bottom strip, donor compact/noncompact metrics, two-line pages, truncating title/nameplate, safe area, dialogue click/touch/key advance guard. `vertical_slice.gd`: VN outside technical scroll, one live view across lines, desktop centring; visible save-error modal. Technical controls remain available on other slice steps and in Prototype Lab.

No campaign schema or source art change. Rollback by reverting this PR. Wave 2 will implement persisted read-line Skip; Wave 3 settings/history/save-load remain open.

## Actual checks

- Godot 4.7.2 `vn_shell_layout_smoke.gd`: PASS, widths 320/340/360/390/430, landscape 844×390 (430-wide game frame), desktop 1366×768, RU/BE/EN text stress, safe area, Auto continuity, pause, touch/mouse deduplication.
- Godot 4.7.2 `session_lifecycle_e2e_smoke.gd`: PASS, including intentional write/delete/corrupt-save failures.
- Native Xvfb/Mesa Godot 4.7.2 `vn_shell_capture.gd`: 15 actual screenshots in `/tmp/raven-vn-*.png`; 320 RU inspected for no footer/text overlap. Captures are review evidence, not new production assets.
- Full check and exact-head PR CI: pending at initial authoring, see PR/status updates.
- Actual Android/iPhone, original donor screenshots, Windows owner acceptance: pending. Xvfb is not physical device QA.

Capture command: `DISPLAY=:99 godot --path . --audio-driver Dummy --script res://tests/raven/vn_shell_capture.gd`. Screenshots are reproducible, not checked into source. Run headless smoke via `scripts/check.sh` or `check.ps1`.
