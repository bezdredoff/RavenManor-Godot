# RM-MAP-S1 — Camera and modular art calibration pilot v0.1

**Owner feedback:** the animated Onoe / orthogonal map is clearer. We must settle camera elevation and begin modular backgrounds/real prop trials, without locking production architecture prematurely.

## Recommended camera
- **Orthographic projection, 65° downward from horizontal** is the **current owner-preferred hub default**, equivalent to 25° from straight top-down (nadir). This means floor-space screen Y scale = sin(65°) ≈ **0.906**; the earlier `0.82` was the superseded 55° pilot. This is NOT the same as an instruction “40° down from horizontal”.
- Preserve in-engine **45° / 55° / 65°** angle comparison (floor depth ratios ~0.707 / 0.819 / 0.906). Choose after mobile portrait validation of Onoe, wall reading, furniture footprints and finger hit areas. Avoid classic 30° isometric unless data demands it.
- Actor sprite stays upright. Keep its **feet at the same projected world point** regardless of map zoom; do not apply floor Y compression to actor body.
- True wall elevations and occlusion masks are later layer components. The current wall-fascia test is a simple diagnostic; it is not a physically rendered 3D camera.

## First controlled background and modular prop test
- `hall_shell.svg`: local (700×690) shell fitted to Hall world rect (500,150,700,690); stone tiles/dark inset, wooden wall pieces, split staircase + upper landing, locked center door beneath the landing, Hall↔Archive left, Hall↔Corridor right, Entry bottom. **No movable furniture baked in**.
- `hall_rug.svg`: separate burgundy rug, can later swap `rolled/unrolled` overlay.
- `grandfather_clock.svg`: isolated clock, left by Archive, atlas movement later.
- `seating_cluster.svg`: TWO armchairs and small round table as a composed test group. Production exports must split two chair textures and the table with independent covers and interaction masks.
- `console.svg`: entrance-side furniture.
- `ancestor_gallery.svg`: temporary three-portrait visual proxy, NOT approved canonical ancestor identity or final six-frame set.

**All SVGs are expressly handmade vector staging proxies** committed because they align precisely to world bounds. They are NOT generated canonical painterly textures; the AI-generated reference boards visible in conversation are mood explorations, not guaranteed exact room-layout assets. Replace proxies selectively with images generated at identical orthographic camera, alpha and world footprint.

## Exact generation prompts (ChatGPT Images, Nano Banana)

### Base room architecture ONLY
```text
Raven Manor game asset production, base architecture pass, 2D hand-painted anime gothic mansion art. Orthographic shallow top-down 3/4 view, virtual camera elevated 65 degrees above horizontal (25 degrees away from overhead); zero lens perspective and no converging parallel walls. SAME FLOOR PROJECTION AND SCALE AS ATTACHED WORLD-GRID LAYOUT REFERENCE. Crop to the approved Hall room footprint, exactly matching its edges and door seams. Cream limestone tile floor with restrained dark geometric inlays; dark carved oak wall panels with brass details; symmetrical bifurcated main staircase at the far wall, two flights, central landing and closed east-wing double doors UNDER the landing. Front Entry threshold centered, Archive opening LEFT, residential Corridor opening RIGHT. Soft diffuse lighting; cozy gothic Victorian, tasteful 2D anime illustrated game materials, readable top-down silhouettes. DO NOT render armchairs, clocks, tables, rugs, consoles, loose decoration, character, UI, labels, titles, measurement arrows, infographics or cast shadows for omitted furniture. No cinematic eye-level camera, no isometric diamond-grid rotation, no photorealism. Repeatable neutral architecture tile underlay; export as standalone background layer.
```

### Isolated grandfather clock, matched to same camera
```text
One freestanding antique carved oak grandfather clock with warm brass clockface, viewed from the SAME orthographic 65-degree elevated camera as the supplied Raven Manor Hall layout and style reference. One clean centered object, full silhouette, consistent 2D illustrated anime gothic game style, no floor, no room, no wall, no text, no extra objects. Transparent RGBA background; usable game prop cutout with consistent clock-foot pivot and separate movable pendulum and hands requested as later layers. Dark oak, antique brass, subtle burgundy accent, restrained detail legible when displayed around 50–90 screen pixels.
```

### Isolated upholstered chair
```text
Exactly one antique upholstered armchair, burgundy damask cushion, dark carved oak frame, restrained brass tacks; same orthographic elevated 65-degree 2D anime gothic game camera as supplied Hall base. Do not add table or second chair. 3/4 visible top and front faces with no horizon/vanishing points. No floor or environment, clean transparent RGBA alpha, isolated object, feet grounded at bottom. Keep silhouette easy to recognize at small map scale. Separate 'dusty with removable cloth cover' and 'clean exposed upholstery' outputs while preserving the identical chair identity and outline.
```

### Companion table and rug
```text
Raven Manor reusable modular game props: one small round carved-oak side table with brass accents, separate from the armchairs; and a burgundy ceremonial runner carpet as its OWN separately generated image. Match exactly the provided top-down orthographic 65-degree camera, material style, pixel density, lighting and game foot plane. Transparent background for the furniture; carpet should be fully isolated on transparent alpha. No room, no labels, no UI, no combined diorama. Generate objects separately, one per output.
```

For Nano Banana/image-to-image: supply the **precise Godot hall layout** and sample asset render as visual conditions; forbid perspective drift, invented doors or moving any fixed staircase edge. Do **not** use the broad mood-board as spatial truth.

## Art acceptance
- Camera angle label appears in live map. Screen→world picking works for all angle presets.
- Onoe readable beside clock and seating cluster on 390×844 viewport at zoom default and increased zoom.
- Hall shell drawn exactly inside shared Hall room rectangle, with door seam matching neighboring architecture.
- Props placed as separate textures with their existing collision rectangles and click interactions (not baked into shell).
- Test room still travels continuously to Corridor and Archive while selecting clock and other props; collision data unchanged.
- Distinct disabled/debug before/after overlays are clearly nonproduction.
- Record final camera preference before commissioning HD texture exports.

**Unapproved:** final painterly art, canonical cast, six ancestor identities, full character map sprite, real prop repair animations and actual 3D projection.

## Phone-scale framing update (owner preference)
The first mobile-hub framing starts with **65° + 0.74×**, not a zoomed-out architectural plan. Use the 0.68× / 0.74× / 0.80× comparison at actual 390×844 or tall/wide portrait ratios. Generate individual architecture and prop assets to the approved *world geometry* independent of screen zoom; preview all exported cutouts with existing Onae technical sprite scale in Godot. Historical 55° illustrations remain comparison references only, **not** final input for new production art. Mobile browser safety insets and art occlusion remain a separate QA gate.
