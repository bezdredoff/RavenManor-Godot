# CODE-05-02 — Hall imported opening contract hardening (2026-11-06)

Task IDs: CODE-05-02 (manor-map, P0); related RM-GAP-006 remains proposed P0. Preceding Room Builder importer fix #206 is merged; separate Room Builder status bookkeeping is #209 and NOT part of this PR.

Changes: The map-side `scripts/raven/hall_import_bridge.gd` now fails closed unless each imported `Marker2D` for the existing five world-map Hall doors matches the currently authored `data/raven/hall_wall_plan.json` opening ID, wall attachment, traversable kind and opening width. `window` / `glass` are non-portals and cannot silently masquerade as an existing `RM-DOOR-*` marker. The wall plan itself is read-only and remains unapproved art/physics. The check only validates draft render-layer compatibility; it never creates gameplay navigation or colliders.

Verification: Regression added to existing `tests/raven/season1_map_smoke.gd`: starts from current imported Hall preview, confirms the valid corridor opening contract, falsifies the width, wall ID and kind in turn, then packs a tampered preview containing `opening_kind=window` at the correct corridor door coordinates and requires `HallImportBridge.load_render_data` to refuse the imported mode for an explicit semantic-mismatch reason. Existing smoke continues to verify five markers, six guide footprints, four balustrade lines, seven art nodes, two seating collider policies, orthogonal routes, locked Bedroom, and 65°/0.74 portrait camera behavior. These are CI-test assertions, not new game geometry. **Execution: pending exact-head GitHub Actions; local Godot execution NOT_RUN.** Baseline checked `main@f79e2097787ed3bde14236fd2e475ab1e12ee519` has all six required build jobs green (workflow 42260437644), but Pages deploy timed out separately. The unchanged baseline's deployment problem does not authorize modifying GitHub workflow in this PR.

Owner QA: Pending. No final art, stairs, door widths, visual masks, seat footprints, adjusted map graph, or tablet/S-Pen/touch accepted. The accepted visual intent of double east-wing doors under bifurcated staircase remains unchanged; future owner calibration must be reviewed before update to `hall_wall_plan.json`, imported geometry or gameplay map.

Status impact: `CODE-05-02` goes from ready to PR_review while this PR is open. Implementation stays partial / P0, geometry and device QA pending. Only `data/raven/production/progress/manor-map.json` is changed; do not write `room-builder.json`, other shards, `project.godot`, `vertical_slice.gd`, reducer/store, canonical geometry or art. After owner-authorized merge, reconcile only this manor-map shard; do not mark the entire map geometry feature accepted.

## Contract decision

- Map geometry authority (read-only): `data/raven/season1_world_map.json`, 700×690 Hall at (500,150), five `RM-DOOR-*` points and six original collision/guide footprints.
- Draft visualization geometry authority (read-only): `data/raven/hall_wall_plan.json` five opening records. Existing `examples/room_builder_hall_original.json` and scene `RM_ROOM_HALL_GamePreview.tscn` remain DRAFT_ONLY.
- Fail closed: opening semantic mismatch disables imported Hall render mode instead of displaying contradictory walls while retaining interactive door routes. The old AI1 comparison mode stays available.
- Camera and navigation unchanged: existing 65° render, 0.74× zoom, existing world-grid preview/authoritative vertical-slice graph and door-state reducer. No free tap-to-move added; no diagonal changes.
- Remaining gaps: physical map routes are not yet derived from the Builder; painted Archive/Corridor arches remain ~207/~242 map units above their fixed openings; distinct future East Wing/Upper Floor visual intents and alpha rail/jamb masks await owner art review; the opt-in three-piece seating collision stays opt-in.

Rollback: revert the `HallImportBridge` semantic gate and corresponding test. No save schema or migration, no map topology or asset material changes.
