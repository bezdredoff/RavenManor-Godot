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
