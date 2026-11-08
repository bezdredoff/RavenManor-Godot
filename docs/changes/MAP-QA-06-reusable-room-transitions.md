# MAP-QA-06 — Reusable authored room transitions

Task IDs: MAP-QA-06 (technical slice; NOT a canonical dashboard registry ID). Linked owner task CODE-05-02 remains P0 partial and is not changed here.

Changes:
- New reusable room transition controller with explicit request, door gate, source/approach, footpoint-confirmed arrival, approved entry anchor, reverse transition, session reset, completion/rejection and virtual QA diagnostic.
- Small TEST_ONLY two-room JSON descriptor, F6 scene/host and Onoe integration. No real Hall/Corridor/Bedroom projection or far-side spawn.
- Deterministic Godot smoke: forward/reverse, locked/future, invalid source/entry, premature/stale/repeated/queued, cancellation, gate closure mid-segment/at endpoint, no teleport, virtual diagnostic, in-memory snapshot unchanged.
- Shared Godot check runner gets ONE blocking MAP-QA-06 smoke line; Hall, Onoe, Prototype Lab and other tests unchanged.
- Contract, gate hold policy, rollback/manual instructions, and future checkpoint handoff boundary documented.

Verification:
- Baseline main 78bcdb6f65bf2fc40a4174912aa33f53a931b0a7 (2026-11-08). PR #241–244 merged, main CI #42519411990 successful; no open PR at start.
- Local Godot: NOT_RUN (no local executable/network available here). Exact-head GitHub Actions: PENDING; inspect all six jobs plus MAP-QA-06 smoke line in godot-runtime log before merge.
- Manual real-device/visual acceptance: NOT_RUN. See docs/qa/MAP-QA-06-room-transition-manual-checklist.md.

Owner QA:
- HUMAN_PENDING for footpoints, gate animation/edge timing, viewport and touch; no production geometry or save migration accepted.
- Safe hold when gate closes in-flight never teleports to rollbackAnchorId. If already arrived, hard hold requires manual restart; production recovery remains future work.

Status impact:
- None. MAP-QA-06 is not in the canonical task registry; status shard and progress/index.json remain unchanged by contract. CODE-05-02 still P0 partial. No claim of production save/scene integration.
- Exact changed-file allowlist: scripts/raven/manor_room_transition_controller.gd, scripts/raven/room_transition_synthetic_demo.gd, data/raven/qa/room_transitions_synthetic.v1.json, scenes/raven/tests/room_transition_synthetic.tscn, tests/raven/map_qa_06_room_transitions_smoke.gd, docs/architecture/MAP_QA_06_ROOM_TRANSITIONS.md, docs/qa/MAP-QA-06-room-transition-manual-checklist.md, this note and one line in scripts/check.sh.
- Rollback by removing isolated files and the one runner line; no production migration or generated artifact.
