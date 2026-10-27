# Raven Manor × UPDS — shared gameplay architecture

**Decision (2026-10-27):** Raven Manor is a content/visual reskin of UPDS wherever the mechanics are equivalent. **The main Raven-specific feature is the playable manor map and restoration/metaprogression.** Do not reimplement already-solved UPDS gameplay subsystems just to change theming.

## Source of truth and update policy

- **UPDS implementation authority:** `bezdredoff/UPDS-godot`, source `main`, not historical UPDS TypeScript or speculative docs.
- Current Raven source snapshot (verified source file blob SHAs):
  - `scripts/match3/match3_game.gd` → `scripts/shared/upds/match3_game.gd` — **138382bd373bc14bf6431a051a84d49de145acf1**, byte-identical, 966 source lines.
  - `scripts/core/seeded_random.gd` → `scripts/shared/upds/seeded_random.gd` — **f5248f7036867a3406d33d0025691bffbac0043d**, byte-identical.
  - `scripts/vn/dialogue_paging.gd` → `scripts/shared/upds/dialogue_paging.gd` — **d9f22ca8533017d112a62ec174fd2c66546e4290**, byte-identical.
  - `scripts/ui/player_preferences.gd` → `scripts/shared/upds/player_preferences.gd` — upstream blob **ea81a778c7adf7c0eac2834cd5be577878069153**, with only 2 Raven path strings changed (MenuCopy preload, saved settings filename).
- Treat these as **vendored source**: when UPDS fixes a bug, review and port it to this snapshot, run Raven regression tests, and record the new source blob SHA. Do not make gameplay-rule changes in the Raven subclass. For the long term, a third repository / shared Godot addon can eliminate vendoring, but first stabilize APIs in both existing repos. Do not create or assume that addon exists yet.
- Static UPDS import paths are restored through `scripts/core/seeded_random.gd` and `scripts/match3/match3_campaign_data.gd` compatibility shims. Raven's level format is normalized **only** by `scripts/raven/upds_match3_campaign_adapter.gd`.

## Responsibility matrix

| Domain | Reuse UPDS | Raven ownership | Current status |
|---|---|---|---|
| Match-3 board rules, hints, RNG, match detection | Original UPDS Match3Game + SeededRandom | Level IDs/data, tile pool, rewards and room target | **Integrated in this PR** (replaces Raven reimplementation) |
| Match-3 specials, effects, blockers, holes, reshuffles | Same imported UPDS game; these capabilities already exist | Authored level layouts and 8 cosmetic base tiles | **Rules imported; no new authored masks or graphics yet** |
| Match-3 touch/drag, frame/cascade rendering, ASMR/audio, boosters | Extract reusable elements from UPDS Match3Screen/TileMotionLayer/ReactionRuntime | Gothic-anime art, UI theme, room-specific fiction | Next implementation PR; current Raven grid is legacy |
| VN line/locale-safe pagination | Original UPDS DialoguePaging | Raven scene/key IDs and background/cast art | **Integrated in Hall 2.1 pilot** |
| VN full UI (layout, narration, history, choices, skip, auto, save/load, 3-actor focal layout) | Extract reusable controls and input logic from UPDS VN Screen (currently >100K and app-coupled) | Raven staging, sprites, dialogue and choice content | Pending; do **not** fork and reimplement UPDS UI feature by feature |
| Settings state: language, audio sliders, mute, haptics | UPDS PlayerPreferences normalization/storage/signals | Raven locale copy, Russian fallback, settings file path | **Integrated in this PR**; screen-level controls pending |
| Settings UI, audio playback, reduced motion, accessibility | Port/extract existing UPDS controls, AudioRuntime and ReducedMotion | Raven artwork and labels | Next PR |
| Campaign level session and results | UPDS Match3CampaignSession/session-facing concepts | Raven work points, restoration costs, replay gates and save migration | Requires adapter; never create a second independent save authority |
| Navigation, object hotspots, routes, NPC waiting/movement, physical room safety | Reuse generic pathing/UI utilities only if truly equivalent | Raven Manor authored anchors, map, doors, room states | Raven-specific |
| Season/story content, characters, clue journal, map popups | Shared VN renderer, screen composition and localization infrastructure | Raven script, casts, world-state, `RM-*` IDs | Raven-specific data |
| Deployment & testing, telemetry, QA | Reuse UPDS Web/Playgama patterns and smoke-test strategy | Project-specific endpoints and screenshots | Audit next |

## Content adapter contract

The Raven story still uses `RM-LVL-001..003` and 8 **constant** base tile types (`candle`, `key`, `rose`, `book`, `raven`, `cup`, `brooch`, `quill`). Each level selects five/six. The content adapter maps `tiles → activeTiles`, `objective → objectives[]`, and supplies empty `boardHoles/blockers/ingredients` when absent. Future levels may author those fields without modifying the UPDS engine.

The legacy Raven engine class is now only a subclass with `super(normalized_level)` and a two-key `get_hint_move()` facade. All other gameplay methods (including cascades, specials, combos, blocked cells, objective values and reshuffle) are inherited directly from UPDS. The existing `RM-VS-01` 2/2/2 work rewards, 2/4 restoration costs, Director, Reducer, and save schema remain untouched.

**UPDS's Match3Screen is not imported in this PR**. Therefore new mechanics are not yet fully visualized or exposed in the Raven UI: importing an engine is not the same as finishing its screen integration. In particular, the old Raven greybox has plain colored buttons for tiles. The next visual implementation must consume UPDS's authored frames, map the original animations to Raven tile art, and avoid 8 new gameplay tile classes for each room.

## Localization & preferences

The Raven production locale resolver now **inherits UPDS PlayerPreferences**. It retains source Russian text and the file `user://raven_language.cfg` so existing language selections survive. UPDS standard audio preferences (`muted`, `musicVolume`, `effectsVolume`, `hapticsEnabled`) are available in the same persistence layer; the future Raven settings UI should connect to these instead of introducing a second config.

UPDS DialoguePaging is imported verbatim and now paginates the Hall tea VN screen based on font measurements and current language. Repeated presses of Next advance the current page before the next line; a language change redraws the current line without altering story ID; page layout is recalculated per language. This fixes the main mobile overflow contract without rewriting sentence logic.

**Remaining VN work:** no shared UPDS history/auto/skip/controller/portrait motion state has been wired into Raven. Do not describe these features as integrated.

## Release and regression gates

- Three authentic upstream RU/BE/EN paging oracle fixtures are pinned at `tests/raven/upds_paging_parity_cases.json`. The source file includes 252 examples; the current Raven smoke selects three representatives. Expand coverage when changing UI measurement or languages.
- `tests/raven/upds_core_reuse_smoke.gd` checks source-based pagination outputs, byte-equivalent UPDS-vs-Raven seeded boards and move resolution, and language/audio preference persistence.
- The existing `tests/raven/vertical_slice_smoke.gd` ensures legacy RM level IDs, gameplay completability, event economy, and saved story progression remain intact.
- The Hall VN smoke ensures runtime UI and locale switching still function.

**Merge criterion:** CI green after confirming a real complete vertical-slice run. No direct changes to existing save schema, story ID, or official art by this architecture PR.

## Next work packages

1. **UPDS Match-3 screen integration:** separate the UPDS UI/cascade renderer/input, tile motion, goal display, blockers and boosters from school-specific visuals and campaign session. Wire it to imported engine and Raven theme/tile atlas. Verify touch drag/swap, specials, cascades and level completion.
2. **UPDS VN controller/UI integration:** extract pagination-driven dialogue frame, history/skip/auto, asset/portrait layout, scene transitions, localization and reduced-motion behavior. Make the Raven staging JSON an input to it rather than rebuilding a second VN screen.
3. **UPDS settings/audio integration:** reuse tested settings controls and preferences, substitute Raven palette/copy, make audio/haptics real.
4. **Raven metaprogression bridge:** replace prototype buttons with authored hotspots, work-point rewards, specialist repair vignettes and room-state changes. Keep navigation/restorations unique to Raven.
5. **All-content rollout:** apply shared systems to Chapters II–VI and regression-test old saves, localization and mobile views.

This is a source-code reuse policy, not a claim that the entire UPDS game is already ported.


## CODE-02A — Source-identical UPDS board/motion/tutorial components (under review)

This extraction **reuses the actual UPDS Godot presentation modules**, not a rewritten Raven copy. Source snapshot pinned from `bezdredoff/UPDS-godot@main`:

| UPDS original → Raven destination (same path) | Git blob SHA | Boundary |
|---|---|---|
| `scripts/ui/css_motion.gd` | `a021a3afee3157f514ccda541b9b7fdf95a3da86` | cubic-bezier easing, no game content |
| `scripts/match3/match3_board_shape.gd` | `8f320c7f18e3a2744375a58cd11edca08b1f9a40` | hole/shape outline and translucent fill renderer |
| `scripts/match3/match3_tile_motion_layer.gd` | `0b9819cbf8d6f26b74a317678ad68e11c2c9c25e` | transient settle/spawn visual copies; board game owns state |
| `scripts/match3/match3_tutorials.gd` | `cda888d62080ec09b16f2617a1eee9604441f3d8` | tutorial event predicates, not school text |
| `scenes/match3_tile_motion_layer.tscn` | `bb5d774c1ac9d6c63109317d8e6adc0f7af7c494` | original reusable Control presentation node |

**Current integration:** `tests/raven/upds_match3_visual_primitives_smoke.gd` instantiates the real scene, drives a spawn/fall animation to completion, asserts hole masks, tutorial completion events and easing endpoints. Linux and Windows CI test the original source. No Raven story data, UI theme, input listener or save store lives in these files. No new `RM-*` ID or gameplay currency is introduced.

**Important remaining work:** CODE-02-01/02 are **not complete**. The working Raven vertical slice still uses its existing Match-3 greybox HUD. The large upstream `match3_screen.gd` (150+ KB) must be extracted into reusable input, board cell presenter, motion/feedback and objective controls with Raven theme/asset adapters; direct copying would drag in school content and save/session coupling. Connect these original primitives there and prove mouse/touch drag, invalid swap, blocker holes/special combos, cascade frames and mobile viewport QA. Do **not** mark `CODE-02-01` accepted based on this component smoke test.
