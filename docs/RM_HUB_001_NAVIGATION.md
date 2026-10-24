# RM-HUB-001 — authored navigation greybox

## Runtime contract

`data/raven/manor_greybox_graph.json` is the single source of truth for the first greybox anchors and edges. `ManorNavigationGraph` loads it into `AStar2D`; gameplay selects a hotspot or designated target and never supplies a custom waypoint array.

An anchor has a stable ID, room, position and kind. An interaction anchor additionally references one `RM-HS-*`. An edge connects two anchors and may require a door or restoration. Rebuilding the graph from the current Raven snapshot automatically removes unavailable edges.

`RM-DOOR-CORRIDOR-BEDROOM` is the only gated edge in this slice. `RM-DOOR-HALL-CORRIDOR` starts unlocked. Locked bedroom routes return an empty path; after the door unlock event, the solver deterministically crosses the near and far doorway anchors.

## Run

Open `scenes/raven/manor_greybox.tscn` in Godot 4.7.2 or run it as the project scene from the editor. The visual is an engineering greybox. Onoe is explicitly marked as a temporary technical placeholder and is not Evelyn canon. Ownership and authorization are recorded in `docs/ASSET_PROVENANCE.md`.

Yellow squares show authored anchors. Blue lines show currently traversable edges. Clicking a hotspot requests a graph route. The debug button unlocks and persists the bedroom door. The foreground lintel has a higher draw order than the character so the crossing demonstrates doorway occlusion.

## Add content

1. Add a room ID to `foundation_catalog.json`.
2. Add safe, transition and interaction anchors to `manor_greybox_graph.json`.
3. Connect anchors with edges. Use `doorId` or `restorationId` for state-dependent access.
4. Add a hotspot ID to the catalog and reference it from exactly one approach anchor.
5. Send progression changes through `RavenReducer`, then call `rebuild(snapshot)`.
6. Attach future VN content by reacting to the reached hotspot ID; navigation does not import VN code.
7. Extend `manor_navigation_graph_smoke.gd` with locked and unlocked expected routes.

## Current limitations

- Temporary colored geometry, not production room art.
- Camera follows the active placeholder actor; authored room framing presets can be added after the route layout is approved.
- Movement interruption continues from the last reached stable anchor; future input polish may project the current position to the nearest edge.
- Mouse behavior is visually checked in the desktop build; real touch-device validation remains part of the mobile gate.
