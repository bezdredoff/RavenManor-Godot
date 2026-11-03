# UPDS UI migration — Wave 0 donor baseline and test contract

Status: **implementation preparation**, not UI parity. Approved scope: `UPDS_UI_REUSE_APPROVED_PLAN_20261103_RU.md`.

## Pinned donor
- Repository: `bezdredoff/UPDS-godot`
- Commit: `3deed628efd6c22bcd1717f7c545b7d3ca865781`
- Main VN source: `scripts/vn/vn_screen.gd` (read at this revision for implementation); supporting files: `scripts/vn/dialogue_paging.gd`, `scripts/ui/phone_frame.gd`, `scripts/ui/ui_fonts.gd`, `scripts/ui/menu_theme.gd`, `scripts/core/story_session.gd`, `scripts/ui/player_preferences.gd`.
- Per-file blob SHAs and transitive dependencies must be captured in each implementation PR; a commit pin alone does not replace dependency inspection.

## VN donor → Raven integration boundaries

| Donor behavior | Target adapter | Required invariant |
|---|---|---|
| `_layout_vn`, header, stage, dialogue, controls | `raven_vn_game_view.gd`, `vertical_slice.gd` | Fullscreen game view, no debug scroll shell; keep approved backgrounds and VN Studio staging |
| `_paginate_dialogue`, `_update_dialogue_page` | `scripts/shared/upds/dialogue_paging.gd` | One paging algorithm; long RU/EN/BE text fits |
| `_schedule_auto`, `_next` | Raven view and `raven_vn_player.gd` | Auto persists across line view updates, pauses for choices/overlays |
| `_skip_read_lines`, `_is_choice_checkpoint` | Raven snapshot/store + director/reducer | Only persisted read line IDs; stop before unread/choice; never auto-select |
| `_show_history` | Raven history adapter | No progress mutation; history survives scene/reload |
| `_show_config`, save/load | Raven preferences/store | Preserve Raven save schema, no donor session state |
| `_build_choice_screen`, `_choose` | Raven branching UI/reducer | Events applied exactly once; no story auto-choice |
| Portrait motion, vignette, background fit | Raven FX/approved assets | No second animation runtime without justification |

### Confirmed gap / blocker
Raven `vertical_slice.gd` creates a fresh `VNGameView.new()` in `_render_vn()`. The view stores `_auto_mode` locally. Before declaring Auto parity, explicitly test cross-line continuity and either preserve the view or move playback mode to a durable UI controller. Current Raven Skip reveals only the last page, not UPDS read-only skip. Do not claim either is complete.

## Acceptance matrix (tests to implement; NOT executed yet)

| Scenario | 320 | 340 | 360 | 390 | 430 | Desktop |
|---|---|---|---|---|---|---|
| Header and bottom controls do not overlap | TODO | TODO | TODO | TODO | TODO | TODO |
| Nameplate, actor and background composition | TODO | TODO | TODO | TODO | TODO | TODO |
| Two-line pagination and progress cue | TODO | TODO | TODO | TODO | TODO | TODO |
| RU/EN/BE long text and font scaling | TODO | TODO | TODO | TODO | TODO | TODO |
| Tap, mouse, keyboard and focus | TODO | TODO | TODO | TODO | TODO | TODO |
| Save/load and history persistence | TODO | TODO | TODO | TODO | TODO | TODO |
| Auto, Skip, choice gates, overlays | TODO | TODO | TODO | TODO | TODO | TODO |

Also test landscape, mobile safe areas, reduced motion, reflow after resize, and resume from old saves. Golden screenshots should be generated for both donor and Raven at matched viewport and locale; never mark as PASS without actual artifacts.

## First implementation slices after Wave 0
1. Extract donor UI-only shell and responsive layout, using the pinned source; retain Raven staging and callbacks. Remove/feature-gate debug wrapper only in actual game mode.
2. Add persisted read-line history and choice checkpoint mapping in Raven snapshot/reducer, including migration for existing saves.
3. Replace placeholder Skip and Auto with UPDS-equivalent behavior and regression tests.
4. Extract overlays, settings, save/load and history, then other game surfaces.

## QA and PR discipline
Every slice: pin donor commit and relevant file blob SHA, list reused/adapted functions, attach real screenshots and regression results, update `docs/STATUS.md` and `production_progress.json`. Administrative dashboard-count checks must not block functional build. Keep PR #171 unmerged; it is superseded by donor-based shell extraction.
