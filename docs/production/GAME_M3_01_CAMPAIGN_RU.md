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

## Reuse decision

- Rules: **reuse-as-is**, current imported UPDS Match3Game and Raven facade.
- Campaign progression: **adapter**, taking donor lock/replay/next behavior and binding it to Raven `firstClearLevels`.
- Campaign visuals: **adapt**, using existing Raven controls, palette and tile pool. UPDS screen assets, school story, narrative/session identifiers, and source labels are excluded.

Full Godot validation, CI, device QA and owner acceptance remain pending for this candidate.

## Existing Match-3 artwork and campaign backdrop

Six PNGs and the board surface are reused from the original `bezdredoff/RavenManor` repository at commit `643a8ec5d39812ec4a00294df6378b12d165280c` (files under `src/assets/tiles/*-v2.png` and `src/assets/board/board-surface-v2.png`). They are copied to `assets/raven/match3/legacy_art/`; no new images were generated. Raven mappings are candle←candle, key←key, rose←rose, brooch←crystal, raven←bat, book←scroll. Cup and quill retain the existing text fallback because the source set has no corresponding art.

The board surface is drawn beneath cells at 48% opacity so the scene remains visible through it. Campaign mode uses the already approved VN `hall/evening_dusty.webp` background and a 34% dark wash for readable controls. The visual approach follows UPDS campaign background compositing: its source background is modulated to 0.24 opacity; here the VN background is the scene layer while the Raven board surface itself is translucent over it.

These imports are listed under `reusedAssets` in `data/raven/production/art_workflow_handbook.json`; `build_art_handbook.py` validates their original-repository commit, source path and byte-level SHA without inventing a generated-art recipe. The handbook catalog is regenerated from that source.
