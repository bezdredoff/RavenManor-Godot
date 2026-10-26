# Room Builder volumetric rooms

Status: implemented prototype. This view changes rendering and pointer projection only; saved
wall, opening, object and `RM-*` data remain in the same schema and coordinates.

## Authoring workflow

1. Choose **Стена** and draw four orthogonal sides. Each stroke snaps to the existing grid.
2. When the fourth side closes a rectangle, Builder recognises a room and automatically switches
   to **Объёмная комната 65°/45°**.
3. Draw three more sides from two points on an existing wall to add an adjacent rectangle. The
   existing segment is the shared wall; drawing it a second time is unnecessary.
4. Choose **Проём**, select a door or arch and touch the shared wall. The opening connects the
   two visual rooms and stays attached to its original wall ID.
5. Use **План XY** for precise topology and **Игровой 65°** for the reversible Godot-aligned
   floor view. Switching views never changes saved coordinates.

## Rendering contract

- floor projection: orthographic 65° elevation / 45° azimuth;
- cutaway: north and west wall faces are shown, near south/east exterior faces are omitted;
- door and stair openings are rectangular through-holes with a header;
- arches are open to a raised pointed head;
- windows stay on a solid wall;
- closed rectangles are detected from continuous wall coverage, including walls made from
  several collinear strokes;
- a smaller rectangle may attach to only part of a longer room wall;
- exact reverse duplicate strokes are ignored;
- furniture currently uses readable projected footprints in this architectural view. Approved
  oriented prop sprites and character occlusion remain a later gate.

## Acceptance criteria

- Four sides produce exactly one detected room and automatically enable the volumetric view.
- Two adjacent rectangles produce two floor faces and one shared wall, not doubled geometry.
- A door or arch on the shared wall remains visible and belongs to the original opening record.
- Screen-to-world picking and dragging are exact inverses at fractional zoom.
- Existing JSON projects, routes, saves, `RM-*` IDs, Godot scenes and collision are unchanged.
- The canonical and published Builder copies remain byte-identical and browser smoke covers the
  new view selector.

## Limits / next steps

This is a deterministic architectural preview, not final production art. The next visual pass
is oriented Blender/ComfyUI wall materials, upright prop sprites, foreground masks and depth
sorting. Collision and navigation must be approved independently before any Godot promotion;
there is no automatic migration.
