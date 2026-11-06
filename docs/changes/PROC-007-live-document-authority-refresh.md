# PROC-007 operational document authority refresh — 2026-11-06

Task IDs: PROC-007, PROC-006, GAME-UI-01
Changes: Correct live progress-shard source of truth and PR process in docs/NEXT_PLAN.md and approved UPDS UI plan. Mark old 2026-11-03 inventory historical; record merged #171 (closed without merge), #174/#176 and #175/#177 implementation slices without inferring full parity. Update PROC-006 CI document from proposed to actually merged and verified main green. No new tasks or task-status overrides.
Verification: GitHub main d9b3cacca23c9df2640c665df9b31c3066d6bd0c; verified PR #192 merged and main Actions https://github.com/bezdredoff/RavenManor-Godot/actions/runs/42246686535 and Pages https://github.com/bezdredoff/RavenManor-Godot/actions/runs/42246685672 SUCCESS. All source text replacements checked against original; local validators and this PR-head CI NOT_RUN at authoring, pending mandatory GitHub jobs.
Owner QA: No new UX, device, asset, save or production acceptance inferred. Manual merge and all original release gates remain.
Status impact: None. PROC-006/PROC-007 already merged technical scope; this documentation-only process PR does not change any domain shard, assignments, frozen production_progress.json, or generated dashboard. 
Rollback: Revert this docs-only PR.
