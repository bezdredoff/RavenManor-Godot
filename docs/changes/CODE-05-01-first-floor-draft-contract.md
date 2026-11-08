# CODE-05-01 — First-floor art/map draft import contract v2

Task IDs: CODE-05-01 (room-builder). Related RM-GAP-001 is integration-only, untouched.
**Base SHA:** 4c4145a935419b5cfaa69e8e1bde90a71717ed7a (2026-11-08). No open PR at audit time.
**Owner:** room-builder.
Changes: Add firstFloorDraft schemaVersion=2 optional extension to schemaVersion=1 Room Builder; load/edit full-floor PNG calibration, room outlines, door points and read-only nav anchors; strict JS/Python validation; isolated deterministic Godot draft scene and machine-readable JSON; Node/Python/browser regressions and mirrored PWA files.
**Reference authority:** data/raven/season1_world_map.json (proposed only), Agent A owns actual full-floor art/geometry/pivots, Agent C owns navigation topology. The current 1×1 PNG fixture is test-only.
**Compatibility:** Legacy v1 docs still validated/imported as before. The v2 path is opt-in; missing/unknown IDs and assets fail, no automatic coordinate repair or silent fallback. All generated outputs live under scenes/raven/generated and assets/raven/generated; they do NOT attach to canonical runtime.
**Out of scope:** No edits to project.godot, core reducer/store/snapshot, canonical map scenes, authored navigation graph, collisions, campaign state, workflows or other status shards.
Verification: Node/Python tests authored, not executed locally (checkout/network unavailable to this tool session); exact-head GitHub Actions results to be appended once observed. Godot generated first-floor scene smoke NOT_RUN locally. Browser/touch/tablet/S Pen QA NOT_RUN. Existing test suite and Godot baseline remain separate evidence gates.
Owner QA: Await image-manifest from Agent A, navigation contract from Agent C, actual image scale/rights confirmation, visual alignment review and explicit geometry/device acceptance; no inferred approval.
Status impact: CODE-05-01 remains P0 partial and PR_review once PR exists; NOT merged/accepted. RM-GAP-001 remains untouched.
**Rollback:** Revert the scoped PR; existing v1 room JSON and canonical game assets remain unchanged.
