# GAME-M3-01: Raven Match-3 campaign adapter

## Scope and authority

The canonical Match-3 tile vocabulary is `data/raven/tile_pool.json` (eight IDs). Match-3 represents sorting, inspection and preparation; specialist repairs remain separate. `RavenCampaignStore`, snapshot, reducer and `firstClearLevels` remain the only campaign authority.

The source is `bezdredoff/UPDS-godot@3deed628efd6c22bcd1717f7c545b7d3ca865781`, `data/campaign_match3_levels.json` blob `c7637889b75c6810b14754fa8e36c1f075844ac5`. The campaign progression/UI reference is `scripts/match3/match3_campaign_screen.gd` blob `5af00e5c02eec14a25b3b1a5aa1d0f594e90927a`. Raven reuses its sequential unlock, completed replay and next-level behavior, adapting presentation to existing Raven controls and state. The donor campaign session is not imported because Raven already persists completion in its canonical snapshot.

## Tile mapping

Donor tile IDs describe clothing and related objects; those names and their fiction are excluded. Mapping uses only existing Raven tile IDs:

| Donor role | Raven tile | Rationale |
|---|---|---|
| White sports garment | `candle` | Generic sorting category |
| Orange sports garment / ordinary garment | `cup` | Generic sorting category |
| Lace garment | `rose` | Decorative category in the approved pool |
| Dark garment | `raven` | Existing dark silhouette category |
| Camisole / sports bra | `brooch` | Small accessory grouping |
| Laundry tag | `quill` | Marked/written item grouping |
| Towel | `book` | Household sorting category |
| Socks | `candle` | Generic sorting category |

Drop ingredients also map to existing Raven tiles by broad mechanical role: service keys to `key`, wearable objects to `brooch`, written records/slips/cards to `book` or `quill`, and equipment to `raven`. Source-specific evidence names, narrative profiles, scene links and labels are omitted. Group-drop objectives remain group drops and preserve target counts.

## Preserved mechanics and progression

Levels become stable Raven IDs `RM-LVL-101` through `RM-LVL-122`; `RM-LVL-001..003`, their level content, and their 2+2+2 first-clear awards are untouched. The new levels preserve source rows/columns, moves, seeds, board holes, blocker placements/layers, opening board and objective kinds/counts. Their Raven copy describes manor sorting/preparation and keeps specialist repair separate. New levels award 0 work points, preventing restoration-currency farming.

The optional campaign list is reachable from the existing vertical-slice footer. It unlocks the first level initially and each next level after first clear, shows completed replay and marks the next level. Starting or replaying a bonus level uses the existing Match-3 game/presenter. First-clear completion goes through `RavenReducer`; zero-reward bonus IDs do not satisfy existing story gates, which check `RM-LVL-001..003`. The list and game use the same Raven snapshot; there is no parallel campaign save.

## Main-menu entry and UPDS reuse

UPDS menu reference: `bezdredoff/UPDS-godot@3deed628efd6c22bcd1717f7c545b7d3ca865781`, `scripts/ui/main_menu.gd` blob `76e47a354b1ca42b4f029278382ad1e0070e7d09`; its Campaign action calls `_open_campaign()` and the screen returns via `back_requested` or starts a level via `level_requested`. Campaign list reference: `scripts/match3/match3_campaign_screen.gd` blob `5af00e5c02eec14a25b3b1a5aa1d0f594e90927a`.

Raven adapts that navigation rather than importing the UPDS menu/session: the localized `Match3Levels` action in `scripts/raven/main_menu.gd` requests the existing optional campaign in `vertical_slice.tscn`. A one-shot SceneTree route flag opens the campaign list without stepping into the VN director. When entered from the player menu, its return action goes back to `main_menu.tscn`; when entered from inside the story slice, the existing return-to-story behavior remains. The test covers opening the 22-level list, launching `RM-LVL-101`, returning to the list and menu, and verifying that browsing/starting the level does not advance the campaign save or story beats. UPDS story/session data and match-3 presentation are not imported; Raven reducer/store remain authoritative.

## Reuse decision

- Rules: **reuse-as-is**, current imported UPDS Match3Game and Raven facade.
- Campaign progression: **adapter**, taking donor lock/replay/next behavior and binding it to Raven `firstClearLevels`.
- Campaign visuals: **adapt**, using existing Raven controls, palette and tile pool. UPDS screen assets, school story, narrative/session identifiers, and source labels are excluded.

The campaign adapter is merged; direct main-menu navigation is a small follow-up. Automated Godot verification does not replace real-device input/art QA or owner acceptance.

## Existing Match-3 artwork and campaign backdrop

Six PNGs and the board surface are reused from the original `bezdredoff/RavenManor` repository at commit `643a8ec5d39812ec4a00294df6378b12d165280c` (files under `src/assets/tiles/*-v2.png` and `src/assets/board/board-surface-v2.png`). They are copied to `assets/raven/match3/legacy_art/`; mappings are candle←candle, key←key, rose←rose, brooch←crystal, raven←bat, book←scroll. ChatGPT-generated teacup and quill candidates are registered for the Raven `cup` and `quill` tile IDs at `assets/raven/match3/generated/`; these are not reused legacy assets. Both have transparent backgrounds normalized to 256×256 canvases. The cup SHA-256 is `e02cdc758e54d1715d4cdc1bcf1e6db4a5cd46e45aea130dade2d9f7f8fed44d`; the curved burgundy quill SHA-256 is `0b4074adb4cacbe8fb9cb013777263ce181ff514c09f386f0ba55edd627b1196`. They are connected in the Raven theme adapter only, preserving the shared UPDS Match-3 rules. These two icons do not complete GFX-10-01 or approve the eight-tile visual set; small-screen/readability and owner art acceptance remain open.

The board surface is drawn beneath cells at 48% opacity so the scene remains visible through it. Campaign mode uses the already approved VN `hall/evening_dusty.webp` background and a 34% dark wash for readable controls. The visual approach follows UPDS campaign background compositing: its source background is modulated to 0.24 opacity; here the VN background is the scene layer while the Raven board surface itself is translucent over it.

These imports are listed under `reusedAssets` in `data/raven/production/art_workflow_handbook.json`; `build_art_handbook.py` validates their original-repository commit, source path and byte-level SHA without inventing a generated-art recipe. The handbook catalog is regenerated from that source.
