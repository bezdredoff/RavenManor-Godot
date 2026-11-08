Task IDs: MAP-QA-02
Changes: Extract common Onoe SpriteFrames/direction helper; introduce one-segment move_toward actor and standalone Godot demo; refactor legacy greybox animation callsites without changing their movement; tests and own manor-map shard.
Verification: Diagnostic head 2c6ab8bbf5255d1900961ea331feff63c25dff8d passed CI run 42515189603: all required jobs PASS, including new Onoe movement headless smoke, previous Hall navigation, Whole Manor map and Prototype Lab regressions. Final clean exact-head CI pending after restoring shared check.sh.
Owner QA: F6 res://scenes/raven/tests/onoe_movement_lab.tscn, watch four directions, left flip, pause, queued replacement, physical arrival; NOT_RUN manually.
Status impact: MAP-QA-02 PR_review / partial; no approval of map geometry, collision, art or game flow.

# MAP-QA-02 — Reusable Onoe movement & animation adapter

**Domain:** manor-map (isolated map-character integration); related character art stays separate.  
**Task:** MAP-QA-02, new scoped QA/workstream task.  
**Code paths:** \`scripts/raven/onoe_visual.gd\`, \`onoe_segment_mover.gd\`, \`onoe_movement_lab.gd\`, and minimal animation call-site refactor of two *existing greybox* scripts, preserving old movement/camera implementations.
**Other paths:** two isolated \`scenes/raven/tests\` scenes; dedicated test \`tests/raven/onoe_segment_movement_smoke.gd\`; documentation \`docs/MAP_QA_02_ONOE_ADAPTER.md\`; own \`manor-map.json\` status shard.

## Reuse matrix

- \`UPDS-godot@3deed628efd6c22bcd1717f7c545b7d3ca865781\`: donor Onoe VN portraits only; no native directional map walker/segment executor in the inspected tree. **Not applicable** for this specific behavior.
- Existing Raven Hall Onoe atlas extraction and direction switch: **extract** the same three clips and horizontal mirroring into \`OnoeVisual.build_sprite_frames/play_sprite_direction\`. The Hall scene keeps its Tween and original actor holder and legacy scale.
- Existing Raven Whole Manor Onoe clip and screen-scale code: **reuse** shared frame builder/direction selector while preserving Whole Manor map motion/grid/world→screen camera.
- Existing Whole Manor \`move_toward\`: **reuse** as the single physical leg executor; no parallel Tween.
- Existing \`manor_route_session.gd\`: **reuse as-is**; caller acknowledges **only** completed \`segment_completed\`, handles queued replacement and cancel.
- Source assets: unchanged Raven-approved **technical placeholders only**, NOT final character production art.

## Verification

- Headless dedicated smoke, existing \`manor_navigation_graph_smoke.gd\`, \`season1_map_smoke.gd\`, \`prototype_lab_smoke.gd\`, and exact-head GitHub Actions: report results after execution. Browser/mobile device manual: **NOT_RUN**.
- No save, route graph, door, collision, imported first-floor source or scene registration modified.

## Owner QA / status

Open \`scenes/raven/tests/onoe_movement_lab.tscn\` with **F6**. Confirm all directions, mirroring, interruption queue, pause/resume, and no position teleport. Integration with approved first-floor geometry is a **future** PR, after owner and Agent A/C mapping acceptance. No acceptance of first-floor geometry, final Onoe art or campaign checkpoint claimed.

MAP-QA-02 remains \`PR_review\` until merge and scene/manual QA. Scope is an independent technical component; DO NOT mark global manor-map story or physical routes complete.

## Verified automated evidence — 2026-11-08

- Temporary in-branch call in `scripts/check.sh` explicitly ran the dedicated Godot CLI smoke; **successful** result [GitHub Actions #42515189603](https://github.com/bezdredoff/RavenManor-Godot/actions/runs/42515189603), source head `2c6ab8bbf5255d1900961ea331feff63c25dff8d`.
- `godot-runtime` green with printed `MAP-QA-02 Onoe movement passed`; existing navigation smoke, Whole season1 map, Prototype Lab and original Hall import all green; data-contracts, room-builder, art-pipeline, web-package and aggregate build PASS. Art/device manual QA **NOT_RUN**.
- This shared check-script insertion was **diagnostic only** and is removed from the final diff to obey the map-agent scoped file ownership. New test remains available as `tests/raven/onoe_segment_movement_smoke.gd`; repeat it manually or through a future integration-owned permanent CI hook.
- MAP-QA-02 is a *scoped internal task label* not present in the shared canonical work package registry. Updating that central catalog is deliberately **out of scope**; live status/evidence is appended to existing map-domain `CODE-05-02`, which remains P0 partial rather than inventing a live task override that fails dashboard checks.
