# Room Builder wall and opening tool

Status: implemented as a draft-authoring path; no automatic gameplay geometry or art approval (26 October 2026).

## Approved first-act scope

`data/raven/season1_wall_kit.json` fixes the agreed budget: four wall styles, 32 room faces (about 609 map-grid units), ten physical door/arch thresholds, one stair opening, seven ordinary windows and eight conservatory glass sections. Door coordinates are exact room-local translations of `season1_world_map.json`. Window positions are authoring placements and still require room screenshot review.

The four reusable styles are `grand`, `residential`, `service` and `glass`. The art budget assumes seven structural source pieces per style: two straight orientations, mirrored inner and outer corners, and an end/pillar. Openings are sockets rather than baked wall images, so one door or window family can be reused in every compatible wall.

## Builder workflow

1. Select **Стена**, choose a wall style, then drag between two points. Endpoints snap to the room grid and the longer drag axis determines horizontal or vertical orientation.
2. Select **Проём**, choose ordinary door, double door, arch, window, glass section or stair opening. Enter an existing `RM-DOOR-*` only for a story/map threshold, then tap a wall. The opening clamps inside the wall and overlapping sockets are rejected.
3. **Стереть** removes a socket before its wall; deleting a wall also removes its dependent sockets. Undo/redo and local/JSON persistence include both arrays.
4. In plan and 65-degree views, walls are rendered from solid runs split around sockets. Wall trim and socket markers remain schematic until source tile art is approved.

Project schema remains version 1 for backward compatibility. Optional `walls` and `openings` arrays default to empty for every existing saved project. Validation rejects diagonal/out-of-room walls, unknown styles or opening kinds, duplicate IDs, oversized sockets and malformed `RM-DOOR-*` references.

## Godot boundary

The draft importer emits a `DraftWalls` node containing visible split wall runs and opening markers with stable builder IDs, styles, widths, door IDs and foreground requests. It deliberately creates no `StaticBody2D`, collision shape, navigation link, campaign mutation or new story identifier. Metadata says `DRAFT_VISUAL_ONLY_NO_PHYSICS` and `NONE_DRAFT_ONLY` so consumers cannot confuse it with approved gameplay geometry.

Promoting a room requires a separate review of door seam parity, wall foreground masks, actor depth, collision clearance and every affected route. The existing world map, navigation graph and save schema remain authoritative until that review is accepted.

## Acceptance criteria

- Mouse, pen and one-finger input can draw an orthogonal wall and place a socket; two-finger pan/zoom remains available.
- Wall gaps survive JSON validation, offline reload and Godot import without silently changing coordinates.
- A socket with `RM-DOOR-*` retains the exact existing ID; arbitrary or legacy-repurposed IDs are rejected.
- Browser and model tests cover wall drawing, opening placement, snapping, topology, gap generation and corruption rejection.
- Godot importer tests prove that openings split visual wall runs and that no physics body is generated.
- The Hall follow-up authors five separate portal intents and schematic stair foreground rails; final transparent art masks remain a separate approval gate.

The measured Hall implementation and real renderer evidence are recorded in [HALL_WALL_PARITY.md](HALL_WALL_PARITY.md).
