# MAP-QA-07B — First-floor AI navigation draft integration

Task IDs: MAP-QA-07B, CODE-05-02 (partial P0)

Changes:
- New read-only draft→room graph adapter compiles five separate image-pixel islands using existing Route Document compiler, protects DRAFT_ONLY provenance and rejects unowned/cross-room edges.
- New F6 scene `scenes/raven/tests/first_floor_integrated_qa.tscn` overlays the approved first-floor PNG, shares MAP-QA-07A host/MAP-QA-06 transition controller/Onoe, selects saved user, exported project or original Hall QA draft.
- Explicit TEST_ONLY Hall↔Corridor↔Bedroom handoffs; no unresolved real portal is made canonical. All other authored islands test by intentional QA-only restart.
- New integration regression and one `scripts/check.sh` registration. Manual walkthrough in `docs/qa/MAP-QA-07B-first-floor-integrated-manual.md`.

Verification:
- Initial main: `27ad5002533d08425f465190c0b75fe206740214`; prior PR #247, #248 and #249 confirmed merged. Local Godot binary not available in execution environment; CI status will be recorded at exact head SHA in the PR.
- No art, canonical navigation, campaign/store/reducer, production scene, unrelated status shard or existing smoke assertions modified.

Owner QA:
- Human must run Godot F6, check all route turns, mobile touch/camera and door alignment; approve geometry/physical portals separately. **NOT_RUN** at PR creation.

Status impact:
- `manor-map` CODE-05-02 stays **P0 partial**; this is a technical QA slice, not a new production approval. Open PR status is PR_review only after PR is actually open. After merge, domain owner updates merged evidence separately.
