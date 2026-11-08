# MAP-QA-07A — Multi-room playable integration foundation

Date: 2026-11-08
Domain: manor-map
Base: main@0afb155e8f0528f9bd91760e4c76f38ed61a1e34

## Scope

Reusable host and standalone F6 QA demonstration; no edits to MAP-QA-06 controller, native Route Editor, firstFloorDraft, Agent A data, production campaign, project.godot or other agents' status shards.

New:
- scripts/raven/first_floor_multi_room_host.gd
- scripts/raven/first_floor_multi_room_fixture.gd
- scripts/raven/first_floor_multi_room_demo.gd
- scenes/raven/tests/first_floor_multi_room_host.tscn
- scenes/raven/tests/first_floor_multi_room_qa.tscn
- tests/raven/map_qa_07a_multi_room_smoke.gd
- docs/architecture/MAP_QA_07A_MULTI_ROOM_HOST.md

The existing authored Hall QA graph is loaded and validated; the Hall-Corridor door is MOCKED in TEST_ONLY fixture. Other two rooms are synthetic. Existing room transition and segment movement are consumed unchanged. The host owns visuals, room-specific camera, overlay and in-memory state proposals.

## Verification

Local Godot executable: NOT_AVAILABLE in this execution environment.
Scoped new headless test: provided, NOT_RUN locally and not yet registered in shared check.sh.
Existing MAP-QA-03/MAP-QA-06/Whole Manor/Prototype Lab regression commands: documented; status requires exact-head CI.
External CI: PENDING.
Owner GUI/phone/manual QA: HUMAN_PENDING.

## Risk and integration follow-up

No campaign saves/geometry were changed. Manual footpoint/occlusion/portrait inspection still required. Future geometry and draft selection from MAP-QA-05/MAP-EDIT-02 must come through a separately reviewed adapter. Integrator should add one new smoke invocation to scripts/check.sh after MAP-QA-06, then run all six CI jobs. The shared check.sh registry was deliberately left unchanged to minimize parallel-branch conflicts.

## Status

Technical subtask MAP-QA-07A does not close parent CODE-05-02 or RM-GAP-006. Keep implementation partial and owner acceptance pending.
