# Blender wall kit: geometry first, AI second

Status: **prototype with a verified corner joint** (26 October 2026). One style, three pieces.
Not integrated into the builder or Godot yet.

## Why Blender is in the pipeline

The AI-only batch produced good props but could not guarantee the properties a wall kit needs:
seams, trim height, corners and the cap/face split that a tilted camera implies. A 3D kit gives
all of that by construction, costs nothing (Blender is free, the geometry is procedural) and
leaves AI to do what it does well — texture, mood, damage overlays.

The reference painting also supports this: its floor cells measure **240×180 px (0.75)** and
its walls are drawn as full faces, i.e. a hand-painted 3/4 view, not a physical 65° projection.

## The joint convention

`tools/blender/kit_geometry.py` (pure Python, no `bpy`) defines pieces as axis-aligned boxes:

- the room is at positive X/Y; walls grow outwards, so a wall's inner face sits on the room
  boundary;
- **a corner piece owns the exterior corner post.** The north arm starts at `-THICKNESS`, the
  west arm butts into it at `y = 0`. The previous version started both arms at zero, which left
  the quadrant `[-T,0]×[-T,0]` empty and opened a visible slit;
- **a butt joint is flush when both pieces present the same cross-section.** The arms and the
  straight run share the profile, so a joint adds no step and no gap;
- a corner pilaster covers the two wainscot ends, so the junction reads as a designed detail.

## The leak check is a number, not an opinion

`wall_kit.py` renders the corner twice — the current geometry and the previous one — from
outside the corner with a transparent film. Any hole in the silhouette becomes transparent
pixels, and the tool reports the difference:

| | Corner post | Geometry leak | Leak pixels |
|---|---|---:|---:|
| Previous | empty | 1.0 | **7 634** |
| Current | filled | 0.0 | **0** |

`scripts/raven/tools/test_blender_kit.py` locks the invariant without Blender: corner post
filled, corner and straight share the same joint profile, and a butt joint changes nothing.
CI runs it with the other Python checks.

## What the kit looks like

Evidence in `docs/evidence/blender_kit/`:

- `corner_join.png` — the same corner before and after the fix;
- `corner_piece.png`, `straight.png`, `end_pillar.png` — the three pieces at 50°/45°.

## Run it

```powershell
& "C:\Program Files\Blender Foundation\Blender 5.2\blender.exe" -b -noaudio `
  -P tools/blender/wall_kit.py
```

Output goes to `build/blender_kit/<style>/` (git-ignored) with `report.json`. Everything is
procedural: no external assets, no purchases.

## Next steps

1. Grow the kit to the seven approved shapes and four styles (materials only, same geometry); doors, windows, arches and stair openings are in place.
2. Export masks: alpha from the film and object-index/Cryptomatte passes for wall occlusion.
3. Write the orientation/pivot manifest and feed the same `wallBand()` rendering path in the
   Room Builder, so the preview shows real sprites instead of a pattern.
4. Test the AI pass: ComfyUI img2img over these renders (denoise ~0.35–0.5) with the existing
   wall batch as the style anchor, then compare against the constructed and AI-only sets.
5. Decide the camera: 50°/45° as here, the current 65°, or 2:1 isometric — it is one line.

## Openings: doors, windows, arches, stairs

An opening is a **hole in the wall geometry**, not a sprite pasted on top.
`wall_with_openings()` cuts the wall into horizontal slices at every profile and opening
boundary, so the wall stays solid above a door, below a window and between two openings;
the hole's inner faces are the sides of the remaining boxes, so the reveal depth equals the
wall thickness for free.

Each opening then owns independent layers:

Two kinds of opening, two very different treatments:

- **Doors, arches and stair openings are traversable, so they cut a real hole.**
- **Windows are not traversable, so they do not cut anything.** The frame, mullions and glass
  are proud of the wall face by a couple of units and the wall stays solid behind them. That
  is cheaper and more robust: no see-through gap, no invented exterior behind the glass, no
  extra occlusion mask, and the window is simply part of the wall sprite.

| Layer | What it is | Swapped per state |
|---|---|---|
| Wall with hole | structural piece for doors/arches/stairs; never changes | no |
| Casing / frame | trim around the reveal, part of the wall finish | damaged variant only |
| Leaf | door leaf or gate | yes: closed / open / damaged |
| Window | proud frame + mullions + glass **on a solid wall** | intact / broken / boarded |
| Threshold | floor line; for open doors and arches it is just floor | no |
| Stair opening | big hole plus a separate stair mesh; the balustrade in front is a foreground cutout with alpha | intact / damaged |

Because the hole never changes, state variants are cheap: only the leaf, casing and glass are
re-rendered. The door's pivot is the threshold centre, which is the same point the game already
uses for `RM-DOOR-*`.

Dimensions come from data the project already has: `OPENING_KINDS` in the builder
(door 75, double 110, arch 110, window 70, glass 80, stair 140) and the opening intervals from
`solidWallRuns()`. The generator takes `(x0, x1, z0, z1)` per opening so any width works; keep a
minimum pier of ~30 units so the corner post and its trim stay readable.

Occlusion is a render output, not an afterthought: the wall above an open door is a foreground
mask, so a character walking behind it can fade the way Diablo fades a wall (the D2 "wall box"
behaviour). Export the mask from the same camera.

Evidence: `docs/evidence/blender_kit/openings.png` — a wall with a door opening (leaf recessed
in the reveal) and a window opening (frame, mullions and transparent glass).
### Arches

An arch is a traversable opening, so it cuts through like a door — but with a pointed head.
`wall_with_arch(length, x0, x1, z0, z_spring, z_apex, steps)` cuts the wall into thin z slices;
below the springline the hole is a rectangle, above it each slice cuts the width of the curve.

The curve is the real **two-centred (equilateral) pointed arch**, not a stretched circle: with
two arcs centred on the opposite spring points, the clear half-width at height `dz` above the
spring is `sqrt(W² - dz²) - W/2`, which reaches zero at `0.866 · W`. The caller's apex is
rescaled onto that curve, so the same construction works for a wide arch and a tall narrow one.

`arch_surround()` adds the archivolt: a moulded band that follows the curve and stands proud of
the wall face by ~2.5 units, plus straight jambs down to the floor.

Two rendering notes that matter for quality:

- build the whole wall and the whole archivolt as **one mesh per material** before beveling.
  Per-box bevels put a groove at every slice boundary, which showed up as horizontal banding;
- `steps` sets how smooth the head reads. 48–64 steps over the rise keeps the stair-stepping
  under a pixel at sprite scale.

Evidence: `docs/evidence/blender_kit/arch.png`.
### Stairs

A staircase is a traversable opening plus a flight, and the rail is a separate layer:

- `stair_opening(length, x0, x1, z_top)` — a tall portal with a header above it, no leaf;
- `stairs(width, steps, rise, run, depth)` — solid treads climbing away from the camera. Place
  the flight centred in the opening and shifted behind the wall by `depth = THICKNESS`, so it is
  only visible through the hole;
- `balustrade(x0, x1, y, depth, height, max_gap)` — evenly spaced posts plus a handrail, drawn
  in the foreground pass with its own pivot. Two runs leave a central entry.

The rail being a separate sprite matters: it is the layer that has to fade or occlude when the
player walks in front of it, which is the same mechanism as Diablo's wall fading. It also means
the rail can be swapped per state (intact / damaged) without re-rendering the flight.

Evidence: `docs/evidence/blender_kit/stairs.png` — a stair opening, an ascending flight behind
it and two foreground rails with a central gap.