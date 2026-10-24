# Raven Manor — canonical project status

Last reconciled: 2026-10-24. **Product owner accepted Prototype Lab** and its integrated engineering vertical slice on 2026-10-24.

## Accepted implementation
- Godot 4.7.2 standalone project, main scene `prototype_launcher.tscn`.
- RM-HUB-001 PR1 foundation: stable Raven IDs, snapshot, wallet, first-clear/reducer, atomic save and recovery.
- RM-HUB-001 PR2: authored AStar2D Hall → Corridor → Bedroom graph, permanent unlock bedroom portal, foreground occlusion, Onoe technical placeholder and save.
- RM-HUB-001 PR3: Raven Match-3 levels 001–003, five hotspots, two restorations, childhood clue, five VN beats, first night and resumable `RM-VS-01`.
- PR #9 integrated slice and PR #10 isolated content previews merged into `main` by 2026-10-24.
- The owner accepts Prototype Lab **as the engineering milestone**, not as final production art or full mobile-release certification.
- GitHub Actions Web export + Pages deployment reported success at commit `d1a72298`; published at https://bezdredoff.github.io/RavenManor-Godot/.
- Historical 70-requirement audit is *pre-implementation UPDS baseline*, not the current score.

## Art-production gate
- All canonical cast artworks including Evelyn are **unapproved**, with Onoe serving as technical placeholder.
- A **full first-season asset register** must precede style experiments. See `docs/assets/` for separate VN/map character requirements, furnishings, placements, room layers and state variants.
- Source-derived requirements and new layout/animation proposals are explicitly distinguished. New art counts are planning rows, **not** an approved production-order authorization.
- Approve character identity/style, map chibi ratio, room composition and asset states before generating in batches.

## Remaining QA / engineering
- Real-device touch, narrow/tall portrait QA and recalibration against production art still require individual evidence. Owner acceptance does not imply tests not actually run.
- Refresh the original 70-requirement coverage against standalone Raven runtime when useful.
- No full-season scene content or mass art is implemented.

## Next
Review/approve complete asset inventory and per-room placement clusters, then define coherent style anchors across VN character, mildly-chibi map character, room and prop. Validate first calibrated composite in Godot before mass production.
