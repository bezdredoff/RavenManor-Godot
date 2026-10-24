# Next plan — after accepted Prototype Lab (2026-10-24)

## Gate A — complete asset specifications (NOW)
1. Use `docs/assets/CHARACTER_PRODUCTION_BIBLE.md` for two-scale cast: VN full-size normal anime and separate mildly-chibi map sprites; emotional/pose states and animated clips.
2. Use `docs/assets/ROOM_FURNISHING_AND_PLACEMENT.md` and `docs/assets/ROOM_OBJECT_REGISTER.csv` for all room furniture, decor, interactive props, repairs and placement anchors; do not conflate 12–20 unique clue props with actual room population.
3. Review layout density, occluders, pathways, state changes and source status. All locations are proposed topology-relative anchors, not pixel coordinates or approved floor plan.
4. Confirm specialist cameo approach and approve production IDs and quantities before mass asset generation.

## Gate B — style anchors
Choose a single coherent anime style with consistent material and lighting palette. Establish one VN Evelyn sheet and *separately drawn* mildly-chibi map version; verify identity and proportions. Test one room with foreground masks, major furniture, small clutter group and changed restoration state against real portrait UI.

## Gate C — pipeline proof
Record generation model/workflow/seed/reference provenance and dimensions. Test stable pose/expression identity, map walk frames and occlusion; automate file naming/alpha/anchor checks. No bulk images until pass.

## Ongoing product engineering
Preserve approved integrated Prototype Lab and separate Raven state. Make corrections through small tested PRs with docs. Re-score old 70 requirement matrix as separate current-runtime review; real mobile touch certification remains separate.
