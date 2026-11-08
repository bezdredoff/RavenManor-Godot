# First floor Raven Manor map — source-art contract (Agent A)
**Task:** GFX-08-08 · **domain:** environment-art · **status:** draft calibration, NOT runtime geometry.

## Source authority
Use ONLY `a_detailed_top_down_isometric_game_map_illustratio.png` on main (Git blob `b50bc36cffd3d3aca7e81a0cea28bb3d0c0e9563`, 3,126,732 bytes).
The owner selected this illustration. **Do not** replace it, generate alternatives, or overwrite pixels.

The raster remains at the **repository root** on purpose. Moving it would break the owner-shared GitHub URL and copying it under `assets/raven/map/` would create an extra Godot-imported raster and potentially inflate the Web PCK. The manifest references the same original file by path; once consumers agree on a migration, use the existing blob SHA so no re-encoding occurs.

## Audit findings and facts versus unknowns
- Verified from GitHub **metadata**: a PNG path is present, its Git blob SHA matches the approved SHA, the byte length is 3,126,732.
- **Updated 2026-11-08:** source bytes, **1672×941** dimensions and SHA-256 are now verified through GitHub Runner (see detailed audit below). Coarse room identities are visually reviewed; precise painted door centres, floor paths, foreground alpha/masks and gameplay-safe scale remain **unapproved**. The original initial-draft metadata limitation is resolved.
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


## 2026-11-08 — actual PNG measurements and visual audit

**Exact approved root source:** 1672×941 px (~1.777:1), 3,126,732 bytes. SHA-256:
\`5e0edf97bd719fb1df95c7e9bea2f134d90adad0bc04d1771acc82a95a4d549a\`.
Git blob SHA: \`b50bc36cffd3d3aca7e81a0cea28bb3d0c0e9563\`.
Read using Godot 4.7.2 in a temporary read-only GitHub Runner diagnostic: [source-byte measurements](https://github.com/bezdredoff/RavenManor-Godot/actions/runs/42502763198) and [full-image + source-resolution cropped views](https://github.com/bezdredoff/RavenManor-Godot/actions/runs/42503148980). Original PNG bytes and path **never changed**.

**Visual annotation:** \`docs/audits/GFX-08-08-first-floor-visual-review.svg\` embeds a *reduced review JPEG* derived from this exact PNG and outlines **coarse visible regions**, not collision/walkable polygons. Source-pixel XY origin is top left. Boxes and target marks are *visual estimates* from the 1200px overview and original-sized crops. The exact filename, SHA, format and dimensions are byte-verified; individual art object boundaries/portal centres are NOT owner-accepted measurements.

The painting shows the Bedroom upper-left, adjoining Bathroom to its right, an upper horizontal Corridor, Library/Archive lower-left, central/lower grand Hall with two curved stairs, Kitchen lower-right, an additional **dark covered room** northeast, exterior Garden top, Orangery/greenhouse far northeast and front entry steps. The dark room is **not** one of eight independent proposed world-map rooms. Entry appears as exterior steps rather than a freestanding indoor room. No inference about a closed-wing gate or story assignment is accepted.

### Physical mismatch with the old room-plan proposal

\`season1_world_map.json.worldSize=[2150,2250]\` is nearly portrait (~0.956:1); source art is 16:9 landscape (~1.777:1). Unconditionally stretching it into the existing full-floor worldRect creates approximately **1.86x unequal axis scales** and visibly wrong doors/rooms. The image is a finished perspectival painting, not an engineered plan; a single linear mapping may never fit all architectural surfaces.

The visible Library–Hall partition shows no clear traversable opening; the upper Corridor cannot yet be physically connected to the Bedroom or Hall at first-floor elevation; Hall–Kitchen opening is also unconfirmed. The Garden/Orangery appears outside at the top-right, separated from kitchen by the dark room. The twin stairs and central landing have unclear elevation/connection. The actual front main entrance is visible near pixel **[833,801] ±15**. Small threshold-like seams at roughly **[629,335]** (near Bathroom) and **[1144,474]** (Kitchen/Dark room) are ambiguous and must not be taken as working doors.

These are **pixel observations**, not restored route/collision coordinates. The approved gameplay rule Hall→Corridor→Bedroom, bedroom independent of bathroom repair, remains authoritative in fiction, but **the painting cannot currently support that physical movement without explicit art/topology review**. Do not move gameplay graph anchors or silently add physical doors to solve it.

### Three independent coordinate spaces

| Space | Meaning | Status |
|---|---|---|
| \`image-pixel\` | source PNG 1672×941, top-left 0,0, downward y | **exact dimensions**, rough region estimates only |
| \`world-plan\` | non-projected authoring XY and floor-contact positions | old 2150×2250 map is reference only; new landscape registration not approved |
| \`screen-projected\` | Godot/Builder prototype display | \`sx=offsetX + zoom*x\`, \`sy=offsetY+zoom*sin(65°)*y\`; this is **not applied to the already painted PNG** |

A usable planar transform requires at least four independent, non-collinear **same-floor** pixel↔world correspondences and held-out door/feature residual checks. Current \`pixelLandmarkCandidates\` include only pixel estimates with \`worldPlanPoint:null\`; stair landings cannot calibrate first-floor floor plane without elevation. \`worldPlanToSourcePixel\` deliberately remains unresolved with null matrix and empty approved control points.

### Graphics and occlusion masks (NOT EXTRACTED)

The approved raster is one composited PNG. The annotation is **not** a mask. Separate foreground candidate families are documented in \`occlusionCandidates\`: curved stair rails/treads (multi-height), Library bookcase/desk/armchair, Bedroom bed, Kitchen island/stools/hearth, dark-room covered furniture. Cutouts require accurate alpha, a reconstructed **clean plate** behind removed objects, confirmed floor-contact pivots, separate depth sorting/geometry where multiple elevations occur and phone-size visual acceptance. Never publish crude cutouts that expose holes or sample painted shadows as collision. Main architecture walls require independently reviewed openings and sometimes no occlusion at all if they bound a physically unreachable region.

### Agent B / Agent C handoff contract

\`assets/raven/map/tools/export_first_floor_contracts.py\` is the sole **explicit** export gate from Agent A's JSON:

\`\`\`sh
# Always safe: summary of blocked reference-only geometry
python3 assets/raven/map/tools/export_first_floor_contracts.py --target review

# Both currently intentionally BLOCK (exit code 2), no guessed coordinates:
python3 assets/raven/map/tools/export_first_floor_contracts.py --target builder --output /tmp/room-builder-draft.json
python3 assets/raven/map/tools/export_first_floor_contracts.py --target navigation --output /tmp/manor-map-preview.json
\`\`\`

For **Agent B PR #240**: explicit nested \`firstFloorDraft schemaVersion=2\` export is allowed only after reviewed linear full-image worldRect, ≥4 reviewed independent non-collinear pixel/world controls, and individually reviewed room rectangles. It uses real \`baseImage.path\` and \`pixelSize=[1672,941]\`. Missing doors/widths are OMITTED, not given guessed defaults. Old plan rectangles must not silently fill approved geometry. Image is already painted: no second 65° compression. If v2's linear model fails, update B's proposed schema via separate reviewed owner branch, not a hidden fallback.

For **Agent C PR #238**: \`schemaVersion:1\`, \`coordinateSpace:"world-plan"\`, \`productionReady:false\`, \`anchors:[{id,roomId,position}]\`. Output only explicitly \`approved_for_preview\` \`calibratedWorldPlanPoint\`; **never** reinterpret \`referenceGreyboxPoint\` as landscape coordinates, project pixels into the graph, or copy runtime edges/gates. Current anchor count approved for preview: **zero**.

The interface mapping has been proposed in PR comments to B/C; their explicit approvals or incompatibility notes are **still required**. Until then, the final contract is NOT agreed, though the adapters have deterministic fail-closed schemas. Only A's asset paths/shard are modified.

### Current tests

\`\`\`sh
python3 -m unittest discover -s assets/raven/map/tools -p 'test_*.py' -v
python3 assets/raven/map/tools/validate_first_floor_manifest.py --strict
python3 assets/raven/map/tools/export_first_floor_contracts.py --target review
\`\`\`

Current release remains \`productionReady=false\` and \`integrationAllowed=false\`. Godot source-image load was tested in the CI measurement run, but **in-game character occlusion, physical movement, door thresholds, mobile viewport and owner geometry QA remain NOT_RUN**. CI workflow ownership remains integration-only; temporary diagnostic invocation will be removed from this branch after tests.

**C strict contract clarification (2026-11-08):** C requested all **13** established anchor IDs (not partial candidate overlays) for production-facing Room Builder transfer, each in its original room and with independent, reviewed world-plan XY. The source-owned export adapter now refuses B v2 and C v1 when even one of the 13 is unapproved. The connected C preview adapter may permit partial sets as debug inputs, but A's *producer contract* deliberately does not.
**Mobile framing unresolved:** Original source is 16:9 landscape while primary runtime screen is portrait. Focused room camera/pan/zoom and portal framing need human mobile QA, not a silent stretch.
