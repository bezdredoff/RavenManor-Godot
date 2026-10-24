# Dynamic asset, state and spatial production contract

**Scope:** additional proposed first-season requirements derived from approved scenes/repair states. Exact animation lengths, compositing and physical placements are **not yet art-approved**.

## Four independent axes of state

1. **Structural restoration:** ruined → stabilized → restored. Changes major prop composition and sometimes navigation.
2. **Interaction:** hidden → visible → available → inspected → consumed/recorded; never directly inferred from structural state alone.
3. **Time/atmosphere:** day, evening, chapter-specific night; light maps and window effects independent of furniture variants.
4. **Narrative reveal:** pre-/post-reveal face, supernatural overlays, clue visual emphasis only after beat gates.

Avoid pre-rendering every product of these axes as a separate full-room background. Keep reusable object layers and referential state JSON/Resources.

## Coordinate and depth requirements
- Every room needs unique floor boundary, rear/side wall masks, world-to-screen reference and room camera presets before final art.
- Each prop has a **world anchor**, scene-plane orientation, floor pivot where applicable, approximate blocking rectangle, Y-sort/depth policy, and optional foreground-alpha occlusion segment.
- `placement_anchor` in `ROOM_OBJECT_REGISTER.csv` is a **semantic placement descriptor**, not a final coordinate. Calibrate against the existing authored graph, never silently shift route anchors.
- Furnishing clusters: **primary** story focus, **secondary** utilitarian furniture, **tertiary** small visual detail. Prefer shelves, corners and wall adjacency for clusters. Keep at least a clear interaction-footprint at each hotspot and uncluttered threshold lines.
- Multiple copies of a family (e.g. several books, dishes, pots) are variation instances, not separate high-cost unique production assets. Each room should nonetheless appear lived-in and meaningfully populated.
- No fake hotspot affordance on decorative props; distinguish interactive states by subtle reused highlight UI.
- Test chibi sprite scale at actual screen resolution against tables/door height, occlusion and stair railings before committing room master art.

## Animation decisions
| Family | Minimum behavior | Integration |
|---|---|---|
| VN characters | expression/blink/talk; static poses, gesture frame swaps where warranted | dialogue data, no full-body animation for every line |
| Map main character | idle, walk up/down/side, turn, interact, prop carry | authored route motion, feet anchored |
| Map secondary NPC | idle/turn, occasional walk only if blocked by staging | scene beats/hotspot |
| Door | locked physical panel → permanently open/visually removed | persistent door unlock flag, no repeated opening animation |
| Furniture restoration | before/after static state with short dust/lift/wipe FX | one transaction; save then composite |
| Clock | stopped → ticking/chiming | time/beat and repair gate |
| Water | dry/leaking → repaired/running | bathroom and kitchen; separate ambient sound |
| Plants | neglected → healthy; optional low-rate sway | conservatory repairs |
| Lighting | off/on/day/night with limited reusable lighting overlays | room camera and story flag |

A detailed checklist is in `DYNAMIC_ASSETS_AND_EFFECTS.csv`, with 22 planned families.

## Quantity caveat
The 117 per-room asset rows + 22 dynamic/UI/audio families and 97 character variant rows are **asset specifications**, not a literal minimum of 236 independently generated images. Shared rigs, frames, materials, shader effects and reused prop families reduce unique production work, while multiple per-object frames/occlusion masks increase exported files. Prepare a per-asset export manifest and estimate frame/texture count only after style lock.

## Pre-art validation / acceptance
- Human reviews complete room silhouette **before** and **after** repair, not just isolated object sheets.
- Show bedroom scale test: VN Evelyn, independently stylized mildly-chibi map Evelyn (temporary Onoe until approved), one full-scale door, bed and bedside cluster.
- At every door: pre-/post-unlock scene, near/far actor behind/over foreground mask, consistent trim/depth and route check.
- Verify no clipping through counters, shelves, canopy, hanging plants or stair posts.
- Compare room appearance at 390×844 and narrow/tall portrait viewports.
- Log the source of each approval and distinguish author decision from AI proposal.
