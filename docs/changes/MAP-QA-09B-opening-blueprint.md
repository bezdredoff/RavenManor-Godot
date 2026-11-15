# MAP-QA-09B — architectural opening blueprint

Task IDs: MAP-QA-09B (bounded architectural candidate); CODE-05-02 (partial P0 parent).

Changes: Independent editable v1 34-point/29-route opening blueprint; four proposed 48px
shared sills and 10 new floor/backfill patches. Existing QA graph/session/controller/Onoe
simulate eight gated TEST_ONLY directions without relocating the actor at room handoff.
New code-native overlay and explicit editor/QA source buttons. Optional paired-contact
metadata permits only the shared endpoint in room-owned freehand; old docs unaffected.
Kitchen/Conservatory, Entry elevation, Bath vignette and future doors stay outside crossing scope.

Verification: Godot 4.7.2 targeted blueprint smoke EXECUTED_PASS. Physical substeps prove
zero-jump forward/reverse handoffs, ≥12px NO-GO feet proxy, gate/closure/pause safety,
source save/load, pairing rejection, editor/AI-clear/Undo and unchanged 08B source.
Deleting a threshold waypoint (after its routes) removes the pairing through existing
editor actions; regression checks this without manual JSON edits.
Local isolated runtime suite: 130 stages PASS, zero script errors; final guard/UI changes
targeted separately. Full local check.sh and final Linux CI evidence in published PR.
Full local check.sh stops at existing Windows test_sharded_dashboard path-separator assertion;
local progress/code/dashboard validators PASS. Native QA source / HA handoff observed,
recorded in docs/qa/map-qa-09b/native-blueprint.jpg.

Owner QA: This is new proposed architecture, not observed floor or approved art. HC underpass
requires landing/elevation/foreground work; CK vestibule requires cabinet relocation and
enclosure art. Owner must accept or reshape the concrete placements in the blueprint.
Physical foreground masks/body/elevation, final art and device approval remain pending.

Status impact: Own manor-map shard only. #258 verified merged at dbe864f; user authorized
the next placement step. No production/manifest/08B/09-art/source-flag changes or P0 closure.
No auto-merge. See docs/qa/map-qa-09b/README.md for manual review and rollback.

## Scope / provenance

- Base main dbe864f416300397a50620a97456a58f38ede93d. Actual original image and previous
  magnified door evidence inspected; blue patches explicitly replace missing floor only
  in the QA planning layer. PNG hash b50bc36c… Git blob / 5e0edf97… SHA-256 unchanged.
- New blueprint JSON, two Raven blueprint/overlay scripts; existing QA adapter/scene script;
  bounded RouteDocument/freehand/editor integration; new smoke/check.sh registration;
  QA docs/image, INDEX, this record and own progress shard.
- UPDS-godot HEAD reverified 3deed628efd6c22bcd1717f7c545b7d3ca865781; inspected native
  scripts/ui/main_menu.gd blob 76e47a354b1ca42b4f029278382ad1e0070e7d09 screen actions
  depend on donor campaign/save and do not implement Raven architectural contacts.
  Decision not-applicable; existing Raven authoring/QA runtime reused. No new gameplay engine,
  canonical save authority, donor story/art or production UI imported.
- No raster generation or original image edit: code-native polygons/lines form the greybox.
  No source mask/NO-GO is hidden or hard-coded in movement; geometry is in the editable file.

## Published review

PR https://github.com/bezdredoff/RavenManor-Godot/pull/261 is open, not merged; own shard
records PR_review with the actual URL. Final exact-head CI results are recorded in the PR.
Architecture, masks/elevation, physical doors and production approval remain unaccepted.
