# MAP-QA-08B — independent visual route calibration

Task IDs: MAP-QA-08B (bounded navigation QA slice); CODE-05-02 (partial P0 parent).

Changes: Independent RouteDocument v1 candidate, 5 room islands, 5 WALKABLE / 19 NO-GO,
26 waypoints / 21 bidirectional cell routes, 9 candidate story floor stops and explicit
unresolved/out-of-scope targets. Four full-size overlays, annotation keys, per-feature
evidence, desktop screenshots and owner guide in `docs/qa/map-qa-08b/`. Existing editor
and QA scene gain explicit candidate selectors; selected export/preview path avoids
overwriting MAP-QA-05. All geometry stays AI_DRAFT; real doors are unconnected metadata.

Verification: Local Godot 4.7.2 native compiler and actual Onoe movement in all five rooms
with reverse routes, 12px feet-proxy sampling, JSON round-trip, candidate editor load,
freehand conversion, room ownership, AI clear/Undo/Redo, pause/resume/cancel and overlay.
`RAVEN_SKIP_DATA_CHECKS=1 bash scripts/check.sh` completed 128 stages PASS in an isolated
APPDATA. Full `bash scripts/check.sh` attempted, blocked by existing Windows-path assertion
in `test_sharded_dashboard`; local full data suite is NOT claimed green. `validate_code_plan.py`
and `progress_shards.py` PASS. Native UI observed candidate selection/F3, Hall walking to
table approach and Bedroom island restart. Exact-head Linux GitHub Actions verification
will be recorded in the PR after publication; no unexecuted CI success is claimed here.

Owner QA: Full hands-on editing, foreground/body clearance, all furniture/frames,
physical doors/elevation, portrait/mobile and final geometry acceptance remain pending.
HS004 childhood item is unresolved, not assigned invented coordinates. Bathroom repair
never gates bedroom access. No production graph, narrative flags, game saves or source PNG
changes. See `docs/qa/map-qa-08b/README.md` for complete evidence limits and manual steps.

Status impact: Own `manor-map` shard only. CODE-05-02 remains partial P0 / manual_pending.
No task is marked accepted, no P0 closed, no real door promoted. PR must not auto-merge.

## Source and reuse decision

- Base main `5070f7349fa894b08bc7fba4a462f8a689ff5727`; #255 and #256 verified merged.
- Approved PNG SHA-256 and Git blob verified against actual local file; 1672×941 opened
  with four overlapping native crops. Old Hall and MAP-QA-05 data remain regression inputs.
- UPDS native donor inspected before QA selector/test changes:
  `bezdredoff/UPDS-godot@3deed628efd6c22bcd1717f7c545b7d3ca865781`,
  `scripts/ui/main_menu.gd`, blob `76e47a354b1ca42b4f029278382ad1e0070e7d09`.
  `_ready` / action connections route to StorySession/Match3/screens and depend on donor
  save/content/UI. Decision: **not-applicable** for Raven-specific route-document selection;
  use existing Raven `_button`, editor loaders and preview handoff. No donor UI/gameplay
  logic is duplicated or imported. NavigationGraph/RouteSession/transition controller,
  Onoe mover and Room Builder geometry tools are reused unchanged.
- Exact writable scope: new candidate JSON; `route_editor_view.gd`;
  `first_floor_integrated_qa.gd`; new smoke + single `scripts/check.sh` registration;
  this change record, QA artifacts, docs INDEX and own manor-map progress shard.
- Save/schema: no migration, optional authoring metadata only. Rollback candidate/UI
  selectors/test/docs; production behavior is unaffected.

## Iteration

Initial 32px geometry was rejected at narrow kitchen/bedroom margins. Removed kitchen
south loop, selected existing supported 16px grid, snapped waypoints to cell centres to
remove doglegs, moved Hall east stop inward. Inspected overlays and repeated movement
validation. Detailed unresolved physical topology is reserved for MAP-QA-09.
