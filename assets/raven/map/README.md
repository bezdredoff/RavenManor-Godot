# First floor Raven Manor map — source-art contract (Agent A)
**Task:** GFX-08-08 · **domain:** environment-art · **status:** draft calibration, NOT runtime geometry.

## Source authority
Use ONLY `a_detailed_top_down_isometric_game_map_illustratio.png` on main (Git blob `b50bc36cffd3d3aca7e81a0cea28bb3d0c0e9563`, 3,126,732 bytes).
The owner selected this illustration. **Do not** replace it, generate alternatives, or overwrite pixels.

The raster remains at the **repository root** on purpose. Moving it would break the owner-shared GitHub URL and copying it under `assets/raven/map/` would create an extra Godot-imported raster and potentially inflate the Web PCK. The manifest references the same original file by path; once consumers agree on a migration, use the existing blob SHA so no re-encoding occurs.

## Audit findings and facts versus unknowns
- Verified from GitHub **metadata**: a PNG path is present, its Git blob SHA matches the approved SHA, the byte length is 3,126,732.
- **Not verified:** exact pixel dimensions, SHA-256, rendered room count and shapes, individual furniture/doors visible in that raster, pixel landmarks, surface masks, perspective and gameplay-safe scale. The connector currently exposes only the metadata of this >1-MB binary. The manifest deliberately uses `null` for those fields.
- Existing `season1_world_map.json` supplies eight candidate rooms, eleven doors and proposal rectangles. The visible *Library* is represented as `RM-ROOM-ARCHIVE` there. It is NOT an approved physical extraction of this artwork.
- Existing `manor_greybox_graph.json` supplies separate initial-slice foot anchors. Example: `RM-NAV-HALL-SPAWN=[400,300]` in the old greybox while Hall in the world plan is `[500,150,700,690]`. These coordinate spaces must not be linked by identity.
- Hall's twin stairs, clock, chairs/table, Gallery, and doors appear in old production references. This does **not** prove these objects occupy those locations in the approved source painting.
- Bedroom must be reachable independently of Bathroom repair. Bathroom may remain a corridor-side VN focus. No free tap-to-move and no new semantic door gates.

## Proposed coordinates (pending Agent B/C agreement)
1. `sourcePixel`: (0,0) top-left, x right, y down, pixel-space floats, dimensions to be measured.
2. `worldPlan`: unprojected positions from `season1_world_map.json`; references only.
3. `greyboxGraph`: authored route anchor coordinates in **another** provisional space.
4. `worldPlanToSourcePixel`: unresolved; no matrix or falsely inferred rect-to-image stretch.
5. Godot/Builder pilot only: `screenX=offsetX+worldX*zoom`, `screenY=offsetY+worldY*zoom*sin(65°)`; inverse supported. This is the 2D floor-display contract, **not** proof the approved image has a matching perspective or 45° azimuth.
6. For final registration, choose at least four non-collinear floor-plane landmarks, then independently inspect residuals across Hall/Corridor/Bedroom/Library/Kitchen. If local perspective is inconsistent, prefer a piecewise mapping and annotated door/floor polygons rather than forcing a single affine scale.

## Art/occlusion plan
Preserve the full PNG as an opaque base. No actual source layers, silhouettes or masks currently exist. Candidate occluders are walls/arch headers, both stair rails, clock, armchairs, tables, library shelving, bedroom bed and kitchen furnishings. A usable foreground sprite requires (a) pixel-accurate alpha segmentation, (b) an independent clean background reconstruction underneath when the actor will pass behind it, (c) explicit bottom/foot pivot, (d) tested Y-sort and edge/seam quality. Otherwise keep the cutout path `null` and render only the base image. Staircase walkable treads and railing are distinct physical surfaces. Do not create decorative masks that imply collision.

## Machine contract / handoff
`assets/raven/map/first_floor_manifest.v1.json` is the *proposal for Agent B and C review*, not an adopted shared importer contract. The file preserves all known `RM-*` IDs and separates source art pixels from both existing geometry systems. Agent B may enumerate room/door candidate IDs and source path, but must not auto-import uncalibrated room footprints. Agent C may compare ID references only; `integrationAllowed=false` and `productionReady=false` must block runtime promotion.

## Verification
```sh
python3 -m unittest discover -s assets/raven/map/tools -p 'test_*.py' -v
python3 assets/raven/map/tools/validate_first_floor_manifest.py
# After a FULL repository checkout with the PNG:
python3 assets/raven/map/tools/validate_first_floor_manifest.py --hydrate
python3 assets/raven/map/tools/validate_first_floor_manifest.py --strict
```
`--hydrate` measures exact PNG width/height, full PNG chunk CRCs and SHA-256; it changes only immutable byte-fact fields in the JSON. Re-run tests and commit the hydrated manifest after reviewing its diff. It never changes a geometry approval. CI/real Godot preview and foreground mask QA are **not** performed by this script and require separate evidence.

## Open product-owner decisions
See `unresolvedQuestions` in the JSON (including Library vs Archive, actual corridor connectivity, stair access, perspective registration, and rights/provenance); Agent B and C should review the proposed schema and report incompatibilities before finalizing v1.0.
