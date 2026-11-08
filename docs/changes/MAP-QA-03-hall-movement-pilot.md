Task IDs: MAP-QA-03; linked CODE-05-02 (partial P0 Hall integration)
Changes: QA-only 7-anchor pixel-space adapter over existing ManorNavigationGraph + RouteSession; isolated approved-image Godot scene; existing animated Onoe segment mover; mouse/touch authored hotspot targeting; pause/resume and camera; in-place virtual portal diagnostic; Prototype Lab card; MAP-QA-01/02/03 smoke registration in shared check.sh; owning manor-map progress evidence.
Verification: Godot 4.7.2 headless smoke commands and all 6 GitHub Actions jobs to be checked on exact PR head; no local Godot executable in this execution environment; never claim local PASS. Existing main@a96e3f64b54de06ba25d0de037aef91caec7860e CI run #42516839165 PASS before these changes.
Owner QA: NOT_RUN — F6 scenes/raven/tests/first_floor_hall_movement_pilot.tscn; desktop/mobile pan, camera zoom, touch hotspot, avatar scale/footpoint, waypoint routes and no-go appearance, portal diagnostic; owner must approve candidate geometry separately.
Status impact: MAP-QA-03 is a scoped technical slice linked to canonical CODE-05-02; P0 geometry remains partial and unapproved. PR_review only after actual PR creation, merged/accepted/device_verified must not be inferred from CI.

# MAP-QA-03 — Implementation evidence / reuse decisions

- Source: `bezdredoff/UPDS-godot@3deed628efd6c22bcd1717f7c545b7d3ca865781`, previously audited in `docs/changes/MAP-QA-02-onoe-movement-adapter.md`. No source-equivalent directional Onoe map walker/segment executor found in the donor; **not applicable** to Hall image-pixel graph navigation.
- Reuse in Raven: `onoe_visual.gd` direction frames (**reuse-as-is**), `onoe_segment_mover.gd` single physical executor (**reuse-as-is**), `manor_navigation_graph.gd` AStar2D authoring and `manor_route_session.gd` arrival protocol (**reuse-as-is**). **Adapter/new:** only QA data conversion, presentation host and test-specific pointer/overlay/camera, because canonical world-plan mapping cannot be made authoritative yet.
- Boundary: `scripts/raven/prototype_launcher.gd` and `scripts/check.sh` changed minimally as explicit integration-owned registration surfaces. No shared campaign save, IDs, reducer, default main menu, manifest, artwork or Room Builder mutation.
- Confirm CI exact head and manual QA separately in PR; do not mark geometry production ready.
