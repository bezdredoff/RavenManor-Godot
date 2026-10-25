# Raven Manor — canonical project status

Last reconciled: **2026-10-25** after merged PRs #17–#19. The owner confirmed that the published Prototype Lab and mobile Room Builder open and operate. This is **working preview acceptance**, not production art approval or a complete device-certification report.

## Implemented and merged

- **RM-HUB-001 foundation / navigation / RM-VS-01:** Godot 4.7.2 standalone Raven runtime, atomic Raven save, authored Hall → Corridor → Bedroom graph, VN and three deterministic Match-3 levels, two restorations, clue, first night, resumable progression. PRs #9 and #10 and the associated original RM-HUB-001 work are merged.
- **Continuous season-one map feasibility greybox:** proposed footprints of Entry, Hall, Archive, Corridor, Bedroom, Bathroom, Kitchen and Conservatory; 11 door relations, furniture obstacles, orthogonal AStarGrid2D routes; isolated Match-3 preview. This is **not** approved production geometry and is independent of the accepted vertical-slice authored graph.
- **Mobile camera pilot:** owner-preferred 65° elevation, 0.74× zoom default, 0.68×/0.74×/0.80× comparison, full-screen portrait HUD and scale calibration. Real-device screenshot/occlusion certification still pending.
- **Generated Hall artwork comparison:** PR #17 merged on 2026-10-25 after fixing the art-mode smoke test. Eight original source PNGs (two alternate backgrounds, six prop cutouts), checksums, reconstructed prompts; modes **AI1 / AI2 / ПЛАН / SVG** in Whole Manor Map. Art is **experimental and unaligned** to canonical game geometry.
- **Mobile Room Builder PWA v0.1:** PR #18 merged. Touch-first Canvas editor, asset/tile placement, layers, imported PNG/sprite sheets, local IndexedDB, JSON/PNG export, offline-capable PWA shell and independent draft-only JSON → Godot scene converter.
- **Pages /builder/ 404 fix:** PR #19 merged. Static PWA mirrored under root `builder/` and bundled with Godot Web export; both Pages publication methods now include its entrypoint and assets. User confirmed the editor subsequently opens.
- **CI:** GitHub Actions for PR #17 and the subsequent `main` merge successfully ran project checks and Web export. This validates automated smoke tests, not full art acceptance or real-device interaction behavior.
- **Temporary cast artwork:** Onoe from UPDS remains a noncanonical test placeholder; no final Raven cast identity, styles or production sprites accepted.

## Current next gate

**RM-PIPE-001 — Hall authoring-to-gameplay pipeline proof.** See `docs/NEXT_PLAN.md` and `docs/ROOM_PIPELINE_NEXT_GATE.md`.

1. Validate editor flow on Android (S Pen/touch, save/restore, offline and export; no right-click/keyboard), preserving manual backups.
2. Establish one **approved** Hall plan that respects current architectural constraints and door/world anchors; map Room Builder's flat coordinates explicitly onto the World Map Hall footprint before visual art.
3. Build a reversible, validated JSON → **preview-only** Godot bridge with per-object pivot, layer, state, hotspot and occluder mapping. Never implicitly replace either existing gameplay navigation graph.
4. Produce and evaluate ONE consistent architecture+props+states composite at current 65°/0.74× mobile framing. Preserve AI1/AI2/SVG/plan comparisons, real asset provenance and the previous graphic fallbacks.
5. Review style anchors for Evelyn VN and separately drawn mildly-chibi map art. No bulk cast/room generation until individual calibration gates pass.

## Important unapproved / outstanding

- Generated Hall geometry and individual prop projection do not yet line up with the shared world map; art is for comparison only. Independent chair/table colliders, masks, occlusion, clean/dusty/repaired variants, lighting and door seam alignment are missing.
- Room Builder `exampleProject()` is an illustrative 1000×800 flat plan, **not** the World Map Hall (500,150,700,690) nor an authoritative `RM-ASSET-*` placement register. Its draft converter does not wire runtime routes, story state or collision.
- Full Android browser/stylus/offline/export-reload matrix and real 390×844 portrait recordings are still required; user success opening the tools is recorded without inventing detailed QA evidence.
- The repository has two active GitHub Pages publication mechanisms (branch/Jekyll and custom Actions). The mirrored builder fixes the observed 404; the preferred long-term setting is **Settings → Pages → Source: GitHub Actions** if the owner wishes to remove the redundant branch workflow.
- Original 70-requirement matrix is a pre-Raven implementation UPDS baseline, not current coverage.
- Source of product/game-bible and narrative truth remains `bezdredoff/RavenManor`; executable Godot, preview art and mobile editor reside here.

## References

- `docs/NEXT_PLAN.md`
- `docs/ROOM_PIPELINE_NEXT_GATE.md`
- `docs/DECISIONS.md`
- `docs/assets/RM_HALL_GENERATED_ART_INTEGRATION.md`
- `docs/ROOM_BUILDER_PWA.md`
- `docs/assets/ROOM_OBJECT_REGISTER.csv`

## RM-CAT-001 — linked production inventory (2026-10-25)

- Added three Hall seating positions (two separately addressable armchairs, shared art family; one round table), expanding the human-owned CSV registry to **120 PROPOSED positions across eight rooms**. 245 textual state labels are recorded, not approved PNG exports.
- Room Builder v0.2 loads generated room-filtered catalog JSON, supplies proposed states/priority/concept-PNG status, and stores distinct local drafts by room ID. Previous v0.1 projects are preserved and migrated on load; experimental art remains references, not baked into production sprite slots.
- See `docs/ROOM_CATALOG_PRODUCTION.md` and `docs/assets/ROOM_OBJECT_REGISTER.csv`. This is an editor/catalog engineering addition, **not** an approval of room coordinates, media variants, camera, licensed source art or Android end-to-end QA.

## RM-EDITOR-002: game-projected Room Builder pilot (2026-10-25)

Room Builder v0.3 defaults to a **65° projected, directly editable game-floor view** (plan remains secondary), using Godot's exact reversible floor transform at arbitrary editor zoom. A 0.74× preset and optional copied Godot Hall AI1 background/door guides are available when the draft room matches the proposed 700×690 map geometry. Old 1000×800 rooms remain untouched and are visibly flagged as unaligned. No final height/occlusion/character/prop-art certification is inferred. See `docs/ROOM_BUILDER_GAME_PROJECTION.md`.


## 2026-10-25 — RM-PIPE experimental Hall rendering parity v0.4

The PWA and Godot Whole Manor Map now share a versioned preview-only 7-sprite Hall visual manifest, the original source PNGs, bottom-centre foot pivots, **upright screen-space visual height**, actor-floor foot projection and draw-order splitting around Onoe. A temporary front CanvasItem renders props in front of the game actor. Builder's new aligned Hall draft seeds the exact pilot layout; a manual exported JSON → \`sync_hall_preview.py\` conversion can override Godot **visual placement** while leaving world route/collider/save untouched. All seven artworks and unrendered state variants remain *unapproved*, and real device/per-pixel/mask/collider parity remains pending.

## 2026-10-25 · Room Builder v0.4.1 regression fix

Fixed user-reported empty new Hall (async manifest dependency), missing pilot thumbnails despite available source PNGs, and actor button that only armed a tool without placing Onoe. Added atomic 7-object seeding, explicit empty-draft recovery, built-in Hall layout fallback, and Node unit regression checks. Android screenshot acceptance remains user-side; this change does not approve art or physics.
