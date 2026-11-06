# VN-EDITOR-07 — preserve selected line identity across Undo/Redo

Task IDs: VN-EDITOR-07 (narrow Raven editor UX coverage); VNS5-07F2 / HTML visual parity remain open.
Changes: Restore selected sceneId and lineId by stable ID after Raven editor Undo/Redo, falling back to the nearest valid index when the selected item no longer exists. Add a real editor smoke regression for moving a draft-authored line and Undo/Redo, without new serialization.
Verification: Source reviewed against the current Raven editor and existing UI smoke. `tests/raven/vn_studio_new_scenes_lines_smoke.gd` is called by `scripts/check.sh`. Local Godot unavailable: NOT_RUN; exact-head six-job PR CI pending at authoring.
Owner QA: Native Godot 4.7.2 Windows manual verification pending (reorder a draft line, Undo, Redo, title/locale inspector, and absent-ID fallback). HTML v5 screenshot parity at 1024×640 and 1366×768 is blocked by missing original HTML bytes.
Status impact: Record merged #207 as a scoped VNS5-07F delivery (not broad acceptance); VN-EDITOR-07 set to PR_review for this new partial PR. No closing of VN-EDITOR-07 or VNS5-07F2, no device acceptance.

## Baseline and scope

- Repository: `bezdredoff/RavenManor-Godot@f79e2097787ed3bde14236fd2e475ab1e12ee519`
- Branch: `agent/vn-studio/VN-EDITOR-07-undo-selection`
- Mutation: `addons/vn_studio/editor/raven_story_view.gd`, narrow test `tests/raven/vn_studio_new_scenes_lines_smoke.gd`, the `vn-studio` shard, this unique change note.
- Donor: private `bezdredoff/UPDS-godot@3deed628efd6c22bcd1717f7c545b7d3ca865781`. Donor tree has no native Raven VN Studio authoring widget; reuse decision **new Raven editor-local selection restoration**, not imported gameplay/UI runtime. Full donor parity remains independently open.

## Root cause

`_on_undo` and `_on_redo` swap the draft and call `_scene_switch` after retaining `_line_idx`. For draft line reorder, the index belongs to a different line in the restored order. This silently changes the current line/translation/FX inspector context despite an unchanged stable line ID.

## Behavioral contract

- Preserve the existing selected `sceneId` and `lineId` if present after history restore.
- For lines or scenes that disappear (newly authored item undone, etc.), retain the existing nearest-index/clamping fallback.
- Do not alter draft history contents, stable IDs, translations, stage FX targets, Story Map edges, save/reopen, candidate export, or runtime state.
- Neither original Raven assets nor private UPDS data are changed.

## Checks and owner acceptance

CI command: `bash scripts/check.sh` includes `godot --headless --path . --script res://tests/raven/vn_studio_new_scenes_lines_smoke.gd --quit-after 240`.
Manual QA: In VN Studio create a draft scene with 3 lines, select the third and move it up. Undo should restore its old position but keep the same line selected; Redo should do likewise. Verify the RU/BE/EN fields and Stage/Animation context still reference that stable ID. Undo a new scene to confirm the previous fallback remains safe. HTML/source visual comparison and real Windows device acceptance are NOT inferred from CI.

Rollback: revert this PR; no migrations or changes to canonical runtime data.
