# MAP-QA-01 — First-floor Hall image-pixel calibration pilot

**Scope:** isolated DRAFT_ONLY geometry for a later Godot character-movement QA host. **Task:** MAP-QA-01 (bounded QA slice of GFX-08-08), **owner domain:** environment-art. **No runtime integration or geometry approval.**

Baseline: `main@8d0207f0e473644de6564a57b0ad990a85b3908f`, PRs #238/#239/#240 merged; no open PRs at start. Approved image at repository root: `a_detailed_top_down_isometric_game_map_illustratio.png`, **1672×941**, Git blob `b50bc36cffd3d3aca7e81a0cea28bb3d0c0e9563`, SHA-256 `5e0edf97bd719fb1df95c7e9bea2f134d90adad0bc04d1771acc82a95a4d549a`. The exact bytes are pinned in `assets/raven/map/first_floor_manifest.v1.json`, independently measured in #239. The approved PNG is untouched.

## Files and purpose

- `assets/raven/map/qa/first_floor_hall_pilot.v1.json`: **only authority** for temporary pixel-space points, walkable/no-go test polygons, 7 explicit bidirectional segments and a virtual QA portal.
- `docs/qa/MAP-QA-01-hall-preview.html`: loads the original PNG and the JSON side by side in exactly its native source-pixel coordinate frame; hover/tap shows pixel coordinates; toggles route, feet, zones and no-go overlays. Does not modify assets.
- `assets/raven/map/tools/test_map_qa_01_hall_pilot.py`: byte identity, schema, unique IDs, 13 canonical reference IDs, source-pixel bounds, full polygon/edge walkability sampling, connectivity and virtual portal contract plus rejection tests.
- `tests/raven/map_qa_01_hall_smoke.gd`: native Godot 4.7.2 JSON/image loading without a scene or map controller.
- `docs/changes/MAP-QA-01-first-floor-hall-pilot.md`: PR-specific evidence and owner review gate.

## Three coordinate spaces — never merge them

| Space | Source of truth | Allowed in this pilot |
| --- | --- | --- |
| **image-pixel** | Exact 1672×941 first-floor PNG, origin upper-left, X right, Y down | **YES**: all pilot feet, polygons and QA segments |
| **world-plan** | `season1_world_map.json` proposed 2150×2250 map | **NO**: mapping is `null`, no export to `manor_navigation_geometry_adapter.gd` |
| **screen-projected** | A viewport presentation of image pixels | Display only, not authoritative movement coordinates |

For a uniform fit/crop viewer: `screenX = imageOffsetX + zoom * pixelX`; `screenY = imageOffsetY + zoom * pixelY`. Invert with the same offset/zoom when reading a pointer. Both axes use the **same** scale; do not apply `sin(65°)` to this already-painted composition. Mobile portrait review requires camera crop/pan rather than stretching the 16:9 raster. Coordinate `pointPx` is always the **actor's foot contact**, not an image centre/top-left or a mouse screen coordinate.

The original old greybox graph is in a fourth, **independent-greybox**, coordinate basis. The 13 `RM-NAV-*` identities/room ownership/kinds are frozen under `canonicalReferences.anchorIdentities` **without positions**. Do not copy `[400,300]` for the old Hall spawn to the new art. Neither the approved Agent A producer v1 nor B's unregistered draft v2 supports approved image-pixel-to-world registration yet.

## Candidate Hall points

These are traced from the GFX-08-08 reduced approved-image review and the owner-selected image. They are deliberately conservative estimates, **not** visually or physically approved geometry.

| QA point ID | image-pixel feet XY | Intent |
| --- | --- | --- |
| `QA-HALL-SPAWN` | `[836,746]` | Safe starting footpoint inside lower Hall |
| `QA-HALL-CENTRE` | `[835,697]` | Central floor route |
| `QA-HALL-WEST` | `[759,719]` | Left of carpet, below left stairs |
| `QA-HALL-EAST` | `[925,716]` | Right of carpet, below right stairs |
| `QA-HALL-TABLE-APPROACH` | `[835,645]` | Candidate approach below tea table, ref `RM-HS-TEA-TABLE` |
| `QA-HALL-PORTAL-APPROACH` | `[959,746]` | **Virtual** Hall→Corridor trigger inside lower Hall, no claimed doorway |
| `QA-HALL-RETURN-SAFE` | `[932,746]` | Safe Hall-side return spawn after abstract Corridor→Hall area switch |

Edges are authored in JSON and connect all points; runtime consumers must move only along them, **not** treat arbitrary taps or polygon interiors as destinations. The walkable polygon is an approximate lower floor only; no-go polygons cover both staircase/railing areas, the central tea table and two lower planters. Neither polygon set constitutes a physics collider, navigation mask or final walkable floor segmentation. Stair landing `[831,444]` is upper elevation and excluded. Any painted walls/objects outside the walkable polygon are implicitly blocked.

### Virtual portal contract for Agent B / integration owner

`virtualPortal.id = QA-PORTAL-HALL-CORRIDOR`, `canonicalDoorRef = RM-DOOR-HALL-CORRIDOR` is an **identity reference only**, not a verified painted portal and not permission to edit the canonical door. Approach point: `QA-HALL-PORTAL-APPROACH`. On return from an independently QA-authorized Corridor area, place feet at `QA-HALL-RETURN-SAFE`.

- The Hall→Corridor *visible physical door is unresolved*: use a bright **QA VIRTUAL PORTAL** marker at the approach, never paint a plausible opening or silently reuse the north stair landing.
- The `farSideSpawnPointPx` is deliberately `null`, and `requiresSeparateCorridorPilot = true`. Until Agent B has a separate independently reviewed Corridor pilot, **show a diagnostic transition request rather than entering a physical corridor**.
- Hybrid movement: choose hotspot/portal ID → resolve only predefined QA edges → play the existing Onoe actor/animation in the host → acknowledge approach arrival → optional QA active-area switch. Do not use free-point tap-to-move.
- No campaign reducer/store write, unlock, real room state, lastSafeAnchorId or checkpoint events in this pilot. A later integration-owned PR may attach existing RouteSession after a reviewed coordinate translation, but **must not pass these pixel XY to the canonical NavigationGraph**.
- The position list under `canonicalReferences` contains no XY by design. Keep canonical graph, first-floor v1 manifest and B's v2 project untouched. Don't manufacture a 13-anchor world-plan candidate from these seven local QA positions.

### Rendering/pivot rules for Agent B

1. Load `source.path` from repository root and verify `source.dimensionsPx`, source Git blob/SHA-256 in data contract. Draw the **original** texture without any 65° floor transform.
2. Use the JSON `pointPx` as feet anchor. To display a sprite (e.g. the existing Onoe `AnimatedSprite2D`) set its visual bottom-centre contact at the projected screen value of this footpoint; avoid reusing the sprite texture's top-left as its feet.
3. Render walkable polygon translucent green, no-go polygons translucent red, lines cyan, point IDs in overlay. Render the virtual portal in yellow with explicit text. Keep diagnostic overlays separable from gameplay images.
4. On portrait 390×844, 412×915, 430×932 and tablet, keep uniform source-image scale and camera pan/zoom. Mouse/touch picking must invert the image display transform, not the Whole Manor old world-plan formula.
5. Fail closed if the PNG hash/size, schema/flags, room refs, point IDs, edge connectivity or virtual-portal contract change. Never promote this as `firstFloorDraft` navigationAnchors or image-registered room collision.

## Local verification and review

```sh
python3 -m unittest assets.raven.map.tools.test_map_qa_01_hall_pilot -v
godot --headless --editor --path . --import
godot --headless --path . --script res://tests/raven/map_qa_01_hall_smoke.gd --quit-after 80
python3 -m http.server 8765
# Browser: http://localhost:8765/docs/qa/MAP-QA-01-hall-preview.html
```

Automated checks verify JSON structure and conservative authored **segment samples**, not painted floor clearance. Manual Godot review must inspect seven footpoints, especially bottom edge, table reach, staircase collision, planter overlap, Hall's apparent entrance, avatar scale/pivot, legibility of QA portal, native-size viewport and touch pan. Explicitly reject/show a blocked QA transfer to Corridor until a Corridor-side destination is reviewed.

## Open manual/owner decisions

1. Approve or adjust each of the 7 pixel footpoints and the green lower-Hall polygon at the original resolution; all estimates remain tentative.
2. Confirm a real Hall→Corridor opening (currently **not identified**) or continue with the abstract scene/active-area transition explicitly chosen by the owner.
3. Separate the stair treads/landing and perspective elevation; no upstairs or stair walk for this pilot.
4. Decide whether the tea table is interactable from the proposed south approach and whether feet are occluded by table/stair rail in the composite.
5. Establish future per-room footpoint calibration, robust collisions/occlusion and all 13 verified world-plan anchors through explicit A/B/C acceptance, not this pilot.

Rollback: delete the scoped QA JSON, viewer, tests and evidence; no canonical scenes, manifests or game saves are touched.
