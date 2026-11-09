# MAP-QA-05 — AI-authored first-floor navigation coverage (QA only)

**Source:** approved image `a_detailed_top_down_isometric_game_map_illustratio.png`, 1672 × 941, SHA-256 `5e0edf97bd719fb1df95c7e9bea2f134d90adad0bc04d1771acc82a95a4d549a`; same manifest and Hall pilot source identity. **Authority:** `DRAFT_ONLY`, `AI_PROVISIONAL_UNAPPROVED`, no production map, saved game or runtime transition changes.

## Coverage

| Room | Walkable data | Waypoints | Routes | Physical portal |
| --- | --- | ---: | ---: | --- |
| `RM-ROOM-HALL` | Existing lower-Hall polygon and new orthogonal circulation strip | 9 | 10 (7 inherited + 3 authored) | Only existing **virtual QA** portal and safe return; not a painted doorway |
| `RM-ROOM-CORRIDOR` | Conservative centre of upper horizontal corridor | 4 | 3 | UNRESOLVED |
| `RM-ROOM-BEDROOM` | Narrow eastern bedside aisle outside bed/canopy | 3 | 2 | UNRESOLVED |
| `RM-ROOM-ARCHIVE` (painted Library) | Western free floor lane, desk/chair excluded | 3 | 2 | UNRESOLVED |
| `RM-ROOM-KITCHEN` | East of island, away from hearth | 3 | 2 | UNRESOLVED |
| `RM-ROOM-BATHROOM` | Initial corridor-side vignette, **not** a walkable game room | 0 | 0 | UNRESOLVED |
| `RM-ROOM-CONSERVATORY` | Glass roof hides safe footpaths | 0 | 0 | UNRESOLVED |
| `RM-ROOM-ENTRY` | Steps are multi-elevation; avoid flat nav invention | 0 | 0 | UNRESOLVED |

**Total:** 22 stable QA waypoints; 19 routes; 12 new cell-authored routes plus the unmodified seven Hall edges. Five internally connected, intentionally isolated room islands. Four new conservative walkable polygons and five new conservative object no-go proxies supplement (without replacing) the original Hall polygon and five Hall exclusions. All 12 new routes are bidirectional; no one-way claim is justified by the art.

Each new route uses the MAP-EDIT-01 **32 × 32 source-pixel grid**, orthogonally adjacent ordered cells, stable `QA-ROUTE-008` … `QA-ROUTE-019` IDs. All novel waypoints have `calibrationStatus: AI_PROVISIONAL_UNAPPROVED`. MAP-EDIT-01's `provisional: false` on new edges means only **that the cells have been explicitly authored** (the editor requires that value when cells exist); it does **not** mean geometry approved. Older seven straight Hall edges retain `provisional: true` and empty cells, their IDs, coordinates, direction and order.

## Unresolved physical transitions and places

**11 manifest doors are explicitly UNRESOLVED** (with `sourcePixelFootpoints: null`): `RM-DOOR-ENTRY-HALL`, `RM-DOOR-HALL-ARCHIVE`, `RM-DOOR-HALL-CORRIDOR`, `RM-DOOR-CORRIDOR-BEDROOM`, `RM-DOOR-CORRIDOR-BATHROOM`, `RM-DOOR-CORRIDOR-KITCHEN`, `RM-DOOR-KITCHEN-CONSERVATORY`, `RM-DOOR-HALL-EAST-WING`, `RM-DOOR-HALL-UPPER-FLOOR`, `RM-DOOR-KITCHEN-SERVICE`, `RM-DOOR-CONSERVATORY-GARDEN`. No invented door approach or far-side return spawn is written.

**Six additional unresolved records:** northeast covered/dark room identity and story gate; exterior garden route/room ID; Onoe footprint clearance; bathroom-as-vignette geometry; conservatory floor obscured by glazing; entry stair/elevation traversal. Full **17 records** are inside the editor-compatible JSON under `unresolvedLocations`. Existing Hall `QA-HALL-PORTAL-APPROACH` + `QA-HALL-RETURN-SAFE` are explicitly a **virtual test portal**, not proof of an actual Corridor door.

Image `visualApproxBoundsPx` from the manifest are **composition annotations, not approved room floor boundaries**. The four new walkable polygons are deliberately narrow **AI-proposed candidate floor clearances** rather than inferred full wall-to-wall nav meshes. No assumption of Hall→Corridor→Bedroom physical walkability is made. No room crossing, upper-floor traversal, cutout occlusion or fictional collision art.

## Load in Godot 4.7.2

1. Checkout the PR branch, open the Godot project, enable **Room Builder · Navigation / Routes** under Project → Project Settings → Plugins.
2. Open the top-level **Navigation / Routes** tab, press **Load project draft**. The editor's existing fixed project-draft path is `res://assets/raven/map/qa/drafts/hall_routes_draft.v1.json`; MAP-QA-05 extends this same file so the button works without editing the plugin.
3. Confirm 22 points, 19 routes, Hall source identity and grid size 32. Use room IDs/waypoint labels in the list to inspect the five separate areas. Turn on grid coordinates for manual corrections; use pan/zoom to reach distant rooms.
4. **Save user draft** to `user://room_builder_routes/` for local experiments. **Export project draft** overwrites the tracked candidate only when an owner explicitly chooses to export; do not assume a runtime map changes.
5. After merged **MAP-EDIT-02 (#247)**, the editor's **Play original Hall** loads the untouched seven-point regression; **Play saved user (Onoe)** and **Play project export (Onoe)** run the *persisted* draft in the Hall Movement Pilot using Onoe's existing movement adapter (unsaved edits are rejected). The pilot's **Project export** selector also loads this MAP-QA-05 document. Source PNG and floor coordinates are unchanged.
6. **Important:** the pilot is still a *Hall-hosted* QA scene, **not** a multi-room transition host. All 22 waypoint markers may be visible, but only Hall's connected component is reachable from Hall spawn. Corridor, Bedroom, Library and Kitchen each have isolated authored islands with NO playable transition from Hall; distant requests must report unreachable, not teleport Onoe. Hall's virtual Corridor portal remains virtual. This is checked in the MAP-QA-05 regression against MAP-EDIT-02's persisted-project loader.
7. **Test Route** in the editor compiles a temporary graph; cross-room paths are intentionally unreachable. The current compiler marks every anchor with `RM-ROOM-HALL` regardless of its data-only `roomId`; this is a pre-existing editor limitation, so the compiled graph must not be promoted to a true multi-room scene. Do not confuse screenshot markers or graph nodes with verified physical portals.

## Verification, residual risks

- Automated test: `godot --headless --path . --script res://tests/raven/map_qa_05_first_floor_draft_smoke.gd --quit-after 120` (also registered once in `scripts/check.sh`). Checks bounds, original Hall IDs and seven edges, orthogonal cell order, forbidden polygons/blocked cells, per-room connectivity, virtual portal pair, all 11 unresolved doors, MAP-EDIT-01 load/compile/round-trip, canonical source immutability.
- CI validates data and GDScript but **cannot** certify rendered Onoe footprint, physically correct room boundaries, stair elevation, door masking or editor UX. Review in Godot and adjust freely; all AI geometry remains unapproved.
- Revert only the QA draft to the previous seven-point sample and remove this test/runner/doc/evidence to roll back. No production map migration is involved.
