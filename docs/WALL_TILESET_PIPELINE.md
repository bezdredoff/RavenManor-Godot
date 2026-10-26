# Wall tiles: generated art vs constructed tileset

Status: **prototype comparison, not integrated** (26 October 2026). This document records an
experiment that came out of reviewing the 52-candidate ComfyUI wall batch. It does not change
any game data and does not approve art.

## Why the experiment exists

The first real generation pass produced usable discrete props (doors, windows, arches,
balustrades) but failed the modular structure: all 16 corner pieces rendered as room corners
with floor tiles and white plaster, all four end pillars rendered as black plates, and no piece
carries a guarantee about seams, trim height or light direction. Details:
`docs/RAVEN_WALL_COMFYUI_WORKFLOW.md`.

The structural failure is not a prompt defect. A diffusion model paints what a wall looks like,
while a tileset needs properties that are *invariants of construction*. That is exactly what
RPG Maker-style autotiling buys: one texture plus engine-side masks, so corners and joins are
correct because the same texture is reused, not because each piece was drawn well.

## What the prototype does

`scripts/raven/tools/build_wall_tileset.py` keeps one AI render as a **material source** and
derives every shape by construction:

1. **Material extraction.** The newest `wall_<style>_straight_h` render is the style anchor.
   Its alpha sibling gives the object bounds; three patches are cut from the raw pixels (plain
   mahogany rail, carved pilaster trim, oxblood damask panel) and the brass accent is sampled.
   No extra generation is needed and the palette matches the AI batch exactly.
2. **Module.** One framed square bay, 160×160 px at 2× game scale (80×80 in game). The outer
   2 px ring is a single dark groove drawn on **all four sides**, so the left/right and top/bottom
   edges are pixel-identical. That one property makes horizontal, vertical *and* rotated tiling
   seamless by construction rather than by luck.
3. **Shapes.** All seven pieces are whole-module composites: straight horizontal, straight
   vertical (rotated cell), four L corners, and an end pillar that replaces the damask field with
   fluting. Joints always land on the identical ring, so shapes are seamless against each other.
4. **Verification.** `seam_delta()` compares the tiling edge against the image's own internal
   variation and is written into `report.json`.

Chosen scale: a module is 80 game pixels, so a straight wall segment is 240×80 game pixels —
the same order as the world-map Hall dimensions (700×690), not a 1024² painting.

## Measured result

| | AI per-piece batch | Constructed tileset |
|---|---|---|
| Output for the 7 `grand` shapes | 7 renders | 7 derived shapes |
| Build/generation time | ~27 s per piece, ~3.2 min for seven | **0.03 s** for all seven |
| Pixel size per piece | 1024×1024 (1.05 MP) | 480×160 (0.08 MP) for `straight_h` |
| Total PNG bytes (7 shapes) | 2.89 MB | 0.86 MB |
| Seam check | not verifiable; must be eyeballed | **edge delta 0.0** vs internal 3.5 |
| Trim height | varies per candidate | identical everywhere by construction |
| Corners | room scenes, floors, enclosed alpha | L bands with clean transparent background |
| End pillar | black plate | framed fluted pillar, same trim |
| Alpha | BiRefNet-dependent, occasionally wrong | exact rectangle/L silhouette |
| Determinism | seed + model + node versions | pure code, byte-stable |

Evidence: `docs/evidence/wall_tileset/tileset_preview.png` (AI render vs constructed tile for
each shape, plus the constructed wall at 1× and 0.74× phone framing).

The constructed tiles are less richly painted than the AI renders — they reuse three material
patches. The trade is deliberate: they are consistent, immediately tileable, and reproducible
without a GPU.

## What construction does not solve yet

- **Mitred mouldings.** Corners are currently butt joints of framed cells, so the frame reads as
  a grid rather than continuous cornice. A real implementation would miter the trim lines along
  the path (the same module edge property still applies).
- **65°/top face.** The pieces are flat elevations with a bevelled frame. If the Hall needs a
  visible wall top (RPG Maker's two-row wall), a cap strip and a depth ratio must be added at
  render time.
- **Damage states.** Neither approach has them yet for structure; damage is better done as
  overlays/decals on a finished tile than as a full re-render.
- **Texture variety.** Three patches per style is thin; four styles × four patch kinds would fix
  it. PNG size is dominated by texture noise, so palette quantisation or an atlas is the next
  size win.

## How to run

```powershell
python scripts/raven/tools/build_wall_tileset.py --style grand
```

Needs Pillow and the alpha+raw renders of `wall_grand_straight_h` from the ComfyUI batch
(`--source` overrides the material source). Output goes to `build/wall_tileset/<style>/`
(git-ignored) plus `report.json`; the comparison sheet is written to
`docs/evidence/wall_tileset/tileset_preview.png`.

## Seeing it in the Room Builder

Start the builder locally (the helper serves `.mjs` with the right MIME type; plain
`python -m http.server` on Windows can leave the editor stuck on "Загрузка каталога…"):

```powershell
cd tools/room-builder
python serve.py
# open http://127.0.0.1:4173/
```

Then create a room, draw a wall with the «Стена» tool and switch on **«Текстурные стены
(превью)»** in the «Стены и проёмы» panel.

When the toggle is on, every solid wall run is drawn as an 80 px band filled with the committed
module (`tools/room-builder/reference/wall_tileset/grand_module.png`), one module per 80 world
pixels, with the style trim line on top and a contact shadow at the floor line. Openings still
cut the runs, so a doorway stays a gap.

It is a preview, not a project property: the toggle is session-only, nothing is written into
the saved JSON, and switching it off restores the schematic strokes. The same file is mirrored
into `builder/reference/wall_tileset/` for the published PWA and precached by the service
worker.

Verified in a real browser: `wallBand()` has a node test, and a headless Chrome screenshot of
the band renderer showed continuous tiling across horizontal and vertical runs.

## Recommendation

- **Keep** the AI batch for what it did well: material/style anchors, discrete props (doors,
  windows, arches, balustrades), hero backgrounds, damage overlays.
- **Build** modular structure — straight runs, corners, ends, and eventually the cap/top face —
  by construction from a small material set. Use the AI render as the material source so the
  palette stays unified.
- **Do not** spend more generations trying to make a diffusion model guarantee seams, trim
  height or a miter. Only the guide construction can do that, and code does it in milliseconds.

Next gates, in order: (1) owner reviews this prototype against the AI candidates, (2) decide
butt-joint vs mitred corners and the cap/top-face convention, (3) then wire the chosen tileset
into the Room Builder wall tool and the Godot wall kit — a separate change that must not touch
routes, saves or collision.

Only the `grand` style has been exercised. The material patch positions assume the wainscot
layout of that render; `residential`, `service` and `glass` need their own patch check before
the same generator can claim to cover the kit.
