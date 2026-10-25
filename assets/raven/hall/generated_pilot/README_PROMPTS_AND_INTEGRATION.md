# Raven Manor — generated Hall asset staging

These images were generated in a previous response on 2026-10-25. They have NOT been committed to Github or integrated into the Godot scene. This archive preserves actual image files only.

## Issues that block drop-in integration
- The two hall background paintings do not exactly align to the approved continuous world map; portals and stair locations must be compared and aligned to world coordinates.
- The paintings may include wall-mounted portrait/sconces that are baked into the background, while some furnishings are isolated. Avoid duplicate decor.
- Props have transparent RGBA, but pivots, collision polygons, target pixel bounds, alpha edge QA, and visual scale need calibration.
- Ancestor gallery is a single grouped illustration; production six portraits and per-portrait inspection masks are still separate tasks.
- Chair has no covered/dirty variation; its restoration states require new art.
- Generated objects use a generally consistent palette, but not all were rendered at precisely identical 65-degree camera elevation (many show more frontal faces); approval requires comparing Godot composites.
- The original model prompt strings are not retained as machine-readable prompt metadata; suggested prompts below are reproducible reconstruction, NOT verbatim generation metadata.

## Suggested base-room prompt (reconstructed)
A production-ready base artwork of the approved Raven Manor hall: an orthographic 65-degree elevated top-down 2D anime gothic game environment. Cream stone tiles with dark geometric inlays, dark oak paneling and brass fittings. Symmetrical bifurcated staircase at far edge with closed double doors beneath its central landing, library opening to the left and residential corridor opening to the right, main entrance at near edge. No carpet, chairs, tables, clocks, consoles, prop items or loose decor baked into the base. No UI, labels, character, dramatic vanishing point or photorealism. EXACTLY MATCH THE PROVIDED SINGLE-WORLD WORLD-MAP HALL FOOTPRINT, DOOR OFFSETS AND CAMERA.

## Suggested isolated prop prompt (reconstructed)
One standalone Victorian Gothic household [OBJECT], dark carved oak, brass details, burgundy textiles as relevant. Warm polished 2D anime game illustration. Camera fixed 65 degrees downward from horizontal, orthographic view matching the Raven Manor hall base. Transparent background. Correct scale, no floor, no room, no other props, no labels or typography. One object per image. Keep shape consistent across clean / dusty / repaired states. Preserve foot/pivot and alpha.

## Integration requirements
The actual assets belong under res://assets/raven/hall/generated_pilot/ after Github upload. Do not change the accepted Hall dimensions or coordinate transforms to match a drifting generated image. Keep the existing painted-vector test sprites active until background alignment and 65-degree camera compare pass.