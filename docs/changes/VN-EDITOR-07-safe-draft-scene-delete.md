# VN-EDITOR-07 — safe deletion of draft-authored scenes

Task IDs: VN-EDITOR-07 (functional completion of native VN Studio), VNS5-07F2 (post-merge #216 status reconciliation and product priority decision).
Changes: Add a native "− Сцена" action for draft-authored scenes only. Confirm with explicit scope. Reject deletion when any other source scene's draft Story Map edge references the target, preserving authored branches. On success remove the scene and its own authored lines, translation patches, stage v1/v2, FX, outgoing Story Map edges and promotion ID proposal. Keep one editor Undo point, no canonical writes. Add model + editor regression to the existing smoke.
Verification: Source review against original `Raven_VN_Studio_Godot_Handoff_v5_2026-11-01.zip` workflow C. Local Godot binary unavailable: NOT_RUN; exact PR-head six-check CI pending at authoring. Tests in `tests/raven/vn_studio_new_scenes_lines_smoke.gd` invoked by `scripts/check.sh`.
Owner QA: In Godot 4.7.2 Windows create draft scene, translate, stage, try delete and Undo/Redo. Create incoming Story Map link from an existing scene to it: delete must be refused until link is removed. Never let a canonical scene be removed. No matched-pixel screenshot requirement.
Status impact: Reconcile merged #216 with six green checks; original HTML exact visual parity is NON-BLOCKING per owner, while functional reachability/safety and native UI QA remain important. Set VN-EDITOR-07 PR_review for this narrow slice, keep parent implementationState partial, and do not claim Windows acceptance.

## Provenance and scope
- HTML v5 handoff `docs/02_PRODUCT_UX_AND_WORKFLOWS.md`: Story Map explicitly requires "remove newly authored scene (confirmation + incoming refs warning)". That flow is not implemented in baseline current native `raven_story_view.gd`.
- Baseline `bezdredoff/RavenManor-Godot@31dec0e7c740fbb59073ac6b4bf20b26dcb69390`, merged #216.
- Private canonical donor `bezdredoff/UPDS-godot@3deed628efd6c22bcd1717f7c545b7d3ca865781` has no equivalent Raven-specific draft-authoring editor; reuse classification: **new editor-only behavior**. Do not copy donor content.
- Allowed paths only `addons/vn_studio/model/raven_story_authoring.gd`, `addons/vn_studio/editor/raven_story_store.gd`, `addons/vn_studio/editor/raven_story_view.gd`, targeted smoke, this note and the vn-studio shard. No runtime or canonical data files.

## Safety
- Incoming edge from another scene: **fail closed** with source ID in diagnostic and leave draft untouched. Author removes the edge explicitly first.
- Outgoing edges from deleted scene: remove with their owner scene; delete line translations, stage/FX overlays and ID mapping as one transaction on deep duplicate; all changes undoable until local save.
- `Store.validate` must succeed after deletion; canonical scenes cannot be deleted. ID can be reused by the existing next-ID algorithm after removal; no published ID is ever reassigned.
- Editor preview and Story Map remain review-only; no automatic game activation.

## Functional acceptance
1. Delete a new scene with more than one authored line, ensure all attached stage/FX/localization candidates are gone; a canonical scene cannot be deleted.
2. Incoming draft choice or scene edge from another scene stops deletion and leaves both unchanged.
3. A standalone authored scene with an outgoing graph edge can be removed (the outgoing overlay is removed with its owner).
4. Native confirm dialog describes consequences; one Undo restores all fields and Redo removes again.
5. Existing 28 scenes/280 canonical lines and source SHA unchanged. Full Godot CI + Windows manual QA required.

Rollback: revert this PR; source drafts and runtime schema never migrated.
