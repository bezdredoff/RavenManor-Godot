# RM-ROOM-HALL — generated art pilot integration, 2026-10-25

**Status:** experimental Godot integration in `Whole Manor Map`; **not accepted production artwork**, not a final calibrated floorplan. Owner requested preserving the source images, documented prompts, and separate game objects.

## Original source / provenance

All eight generated PNGs (2 background candidates and 6 prop cutouts) are committed under `res://assets/raven/hall/generated_pilot/` **without resizing or re-encoding**.

- See `assets/raven/hall/generated_pilot/ASSET_MANIFEST.json` for source dimensions, source names, SHA-256 byte hashes and concept status.
- See `assets/raven/hall/generated_pilot/README_PROMPTS_AND_INTEGRATION.md` for reconstructed image generation instructions, room/control conditions, missing states, and known deficiencies.
- **The verbatim prompts originally submitted to the model cannot be reliably reconstructed from image metadata**; the documented prompts are explicitly labeled *reconstructed*. No claim of deterministic regeneration is made.

## Whole Manor Map art comparison

Open `res://scenes/raven/season1_map_greybox.tscn` or use Prototype Lab → **5 · Whole Manor Map**.

With `Настр.` open, repeatedly tap the **Вид** selector:

1. **AI1 (default):** primary twin staircase painting + isolated burgundy runner and furniture props.
2. **AI2:** alternate crimson-staircase background, which already has a carpet baked in, so a separate runner is omitted to avoid duplication.
3. **ПЛАН:** traditional furniture/rooms greybox.
4. **SVG:** previous dimension-matched SVG architecture and prop prototypes.

The selector updates only the displayed layers. It does **not** mutate Raven-save, the player collision footprint, world coordinates, route graph, level or repair state.

New real PNGs draw over approved world bounds:
- Generated twin staircase or alternate room artwork: Hall rectangle `(500,150,700,690)`.
- Clock: `RM-ASSET-HALL-CLOCK` existing asset footprint on Archive side.
- Seating: the single generated chair is **instanced twice** plus separate generated round table. Two chairs with one table remain a single logical interaction/collision placeholder; split colliders before final art approval.
- Entry console, ancestor portrait composite, burgundy runner: separate draw calls at existing anchors.

## Known limitations / next QA

- **Geometry mismatch:** source background is 1254×1254 square, while the approved layout prototype uses a 700×690 Hall world rectangle. Generated door positions, stairs, wall masking and sconce/portrait details do not align to exact graph/world coordinates yet. This is deliberately a compositing comparison, *not a claim of pixel-perfect continuous room stitching*.
- **Projection mismatch:** though the target Godot camera defaults to 65° down from horizontal, independent generated props were not rendered from a guaranteed unified geometric projection. Particularly clock/chair are more front-facing than floor. Needs resynthesis with a layout conditioning image and calibration.
- **Duplicated decoration:** paintings already contain some portrait/sconce art; the composited gallery is an optional pilot overlay, not the approved six independent portraits.
- **Missing states:** chair cloth covers, dusty version, working clock pendulum/hands and separate portrait reveals are not generated here.
- **Pivot/masking:** image alpha exists for 6 props but true ground-contact pivots, Y-sort and wall/furniture foreground occlusion are not yet calibrated. Currently the existing path/collision bounds win over generated pixels.
- **Gameplay unchanged:** clicking assets and launching isolated Match-3 preview uses the existing greybox selection and original authored graph. It is NOT proof of production interaction hitboxes or transactional full hub.

## Acceptance checklist

- [ ] On phone, compare AI1/AI2/SVG at 65° and 0.68×/0.74×/0.80× and capture reference screenshots.
- [ ] Assess Onoe relative to clock and two chairs, and identify where the generated art's visible feet do not match collision footprints.
- [ ] Fix stair landing, Archive/Corridor/Entry doorway alignment against world graph while retaining canonical Hall topology.
- [ ] Separate each chair into its own prop/collider, place the round table and produce cloth-covered and clean variants.
- [ ] Remove baked portraits/sconces from background or stop drawing duplicate overlay elements in the final background.
- [ ] Produce final shadow/foreground depth layers, validate route visibility, device safe insets, and only then approve full-size art.

**Do not delete or replace the original SVG prototypes** until the rendered PNGs pass visual and route QA.
