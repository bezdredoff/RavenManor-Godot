# VNS5-07F — precise keyboard nudge in FX timeline

Task IDs: VNS5-07F (narrow editor UX increment); related VN-EDITOR-07 and VNS5-07F2 remain open.
Changes: Add left/right keyboard 50ms cue nudges to the editor-only FX timeline, targeted smoke regression and VN Studio shard PR_review evidence.
Verification: Source inspected; FX smoke is included in scripts/check.sh; local Godot NOT_RUN; exact-head GitHub CI pending after governance note correction.
Owner QA: Pending native Godot 4.7.2 Windows testing, matched HTML screenshots and actual manual keyboard/Undo/save/reopen verification.
Status impact: VNS5-07F set to PR_review/partial only for PR #207; broad VNS5-07F2 and VN-EDITOR-07 remain open, no device or parity acceptance.

Base: `bezdredoff/RavenManor-Godot@ff8760946da7bc3b0250eac1dbaad37d8b832abb`. Domain: `vn-studio`.
Scope: `addons/vn_studio/editor/raven_fx_timeline.gd`, `tests/raven/vn_studio_stage_fx_smoke.gd`, the VN Studio progress shard and this unique change note.

## Observed UX gap

`raven_fx_timeline.gd` advertises focusable `Control.FOCUS_ALL`, but `_gui_input` previously handled only mouse events. A selected FX cue could not be nudged from the keyboard. The VN Studio spec requests keyboard+mouse access. This is a narrow operational discrepancy; it is not evidence of HTML v5 pixel parity.

## Changes

- Left/right arrow keys shift **only the selected FX cue** by -/+50 ms, using the same `cue_moved` signal as mouse drag.
- Ignore release, echo, Ctrl/Alt/Meta-modified events, and absent selection; clamp to the existing `startMs <= 15000` and total 20-second cue bounds; emit no no-op edits.
- Existing StageDesigner validates edits, maintains draft Undo, and saves only via the established review-only `stageFxPatches` workflow. No schema, runtime, scene/line ID, original assets or canonical data change.
- Regression added to `vn_studio_stage_fx_smoke.gd` for both directions, upper bound, no selection and release.

## Parity evidence and limits

- Raven editor: source-level test added. Automated Godot CI must run it; local Godot and Windows Editor QA are **NOT_RUN** in this ChatGPT environment.
- Private donor: `bezdredoff/UPDS-godot@3deed628efd6c22bcd1717f7c545b7d3ca865781` identified, not modified or imported. Reuse decision: **new editor-local control gesture** on existing Raven FX timer, not a duplicate gameplay implementation. This PR does **not** certify private-donor semantic parity.
- Old saves: persisted FX schema is unchanged; actual historic save round-trip is unverified.
- Original HTML v5: source bytes and matched captures at 1024×640 and 1366×768 unavailable in this execution environment; visual parity claim remains blocked (issue #129).
- Device QA: real Godot 4.7.2 Windows interaction and screenshots remain owner acceptance tasks.

## Manual acceptance in Godot Editor

Open Raven Manor → Animation, choose/create an editor-only FX cue, click its colored timeline bar, press right/left arrow. Confirm the start field changes exactly 50 ms, bounds hold, FX Undo restores the prior time, and save/reopen retains the authorized draft. Confirm typing and arrow navigation in other focused controls are unaffected; repeat at 1024×640 and 1366×768. No draft should appear as playable story.

## Verification & status

Test command: `godot --headless --path . --script res://tests/raven/vn_studio_stage_fx_smoke.gd --quit-after 240` (already in `scripts/check.sh`).
At authoring time: source reviewed, local Godot NOT_RUN, CI PENDING. Do not close VNS5-07F2 or VN-EDITOR-07, or claim Windows/visual acceptance.

Rollback: revert this isolated editor/test/status/note PR. No draft format migration needed.
