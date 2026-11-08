# MAP-QA-04 — Movement tests and Hall diagnostics

**Task IDs:** MAP-QA-04 (requested QA slice; not an existing canonical dashboard task), related MAP-QA-01 / MAP-QA-02 and GFX-08-08.

**Baseline:** main a96e3f64b54de06ba25d0de037aef91caec7860e, 2026-11-08. PR #241 and #242 merged. No open overlapping PR at start. Integration branch is used because shared scripts/check.sh and scripts/check_data.sh need integration-owner review.

**Changes:** Register Python Hall calibration validation in blocking data-contracts and both existing Hall/Onoe Godot smokes in blocking godot-runtime; no new workflow, CI job or build artifact. Python checks now use exact polygon/segment boundary classification and mutation tests for thin obstacles, topology, hotspot IDs, canonical-coordinate leakage and portal safety. Expand native tests for malformed input, duplicate clicks, idle/footpoint contract and a gate closing mid-leg. Extend the standalone read-only overlay with shortest route on authored edges, route length in source pixels, waypoint XY labels and marked virtual portal. Add M01–M15 human QA checklist.

**Reuse:** Existing Raven navigation/RouteSession, Onoe animation/movement, and dedicated smoke infrastructure extended without a duplicate game controller. UPDS native reusable movement comparison already documented in merged #241; image-specific QA calibration is Raven-only. No new gameplay code or assets.

**Verification:** Commands: python3 -m unittest assets.raven.map.tools.test_map_qa_01_hall_pilot -v; bash scripts/check_data.sh; RAVEN_SKIP_DATA_CHECKS=1 bash scripts/check.sh (Godot 4.7.2). Actual result and exact head CI job outcomes belong in the PR and Actions links. Local Godot is unavailable in author environment; no unexecuted test is represented as passed.

**Owner QA:** All 15 items in docs/qa/MAP-QA-04-movement-manual-checklist.md are MANUAL_PENDING. CI tests cannot establish visual foot clearance, portrait phone touch, occlusion, camera behavior, real doorway or owner art approval.

**Status impact:** No progress shard edited. MAP-QA-04 does not exist in the canonical task registry; Agent 1 may update its own workstream, but cross-shard task registration/status migration must be reviewed by the integration owner. Do not modify generated dashboard or frozen monolith.

**Risk / Agent 1 handoff:** A dynamic graph gate may close while the visual executor is in flight. RouteSession rejects arrival (segment-blocked, rollbackAnchorId), but OnoeSegmentMover intentionally does not teleport itself. Agent 1 host must visibly and safely reconcile the failed acknowledgement. Virtual Corridor far-side spawn remains null; no physical cross-room traversal approved. Composite PNG foreground layering, stair avoidance, touch camera and pixel clearance remain human checks. No canonical graph, approved PNG, first-floor production manifest, store/reducer, runtime scene, project.godot, or progress shard change.

**Rollback:** Revert this isolated validation/viewer documentation PR; runtime scene and saved data are untouched.
