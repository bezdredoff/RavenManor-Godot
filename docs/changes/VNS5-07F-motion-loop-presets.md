# VNS5-07F — looping portrait idle and enter/exit/hop FX

Task IDs: VNS5-07F (editor FX functionality).
Changes: Extend editor-only v1 FX cues with an optional strictly validated boolean `loop` for actor `breathe` in `idle` phase. Add five actor-only motion presets: `slide_in_left`, `slide_in_right`, `slide_out_left`, `slide_out_right`, `hop`. Preview via existing native Godot `Control.position` and `Control.modulate.a`; deterministic forward and backward scrubbing with no Tween state leaks. Update Animation buttons, editable "Дыхание: цикл до конца реплики" control, timeline infinite-marker and native UI/model test.
Verification: Read-only donor comparison: `bezdredoff/UPDS-godot@3deed628efd6c22bcd1717f7c545b7d3ca865781` `scripts/vn/portrait_motion_rig.gd` blob `fcef111542a0d4bbef7ac50743a3f362efbd4782` implements perpetual breathing via `AnimationPlayer`, with reduced-motion opt-out; gameplay/runtime is not copied into Raven's editor. Existing shared `scripts/shared/vn/micro_fx_math.gd` stays untouched and continues to support existing six effects. Local Godot CLI NOT_RUN; exact PR-head CI pending at authoring; `tests/raven/vn_studio_stage_fx_smoke.gd` executed by Godot Actions once run completes.
Owner QA: Pending native Godot 4.7.2: 2-character scene, choose second actor, test left/right incoming/outgoing directions, hop, Undo, pulse/duration and saved draft. With breathing, scrub to 8.4s and verify it still moves; disable Loop and verify old bounded behavior returns. Changes are review-only and do not automatically reach the actual game.
Status impact: #225 merged with 6/6 CI, current follow-up PR_review remains partial and manual_pending; no runtime/device acceptance.

## Baseline and ownership

- Raven main `8c133b3ca415fa4b6c3d90e6a5ab4de50f3d5354`, #225 merged, no overlapping open VN Studio PRs at branch creation.
- Writer `vn-studio` limited to `addons/vn_studio/model/stage_fx_store.gd`, `addons/vn_studio/editor/raven_stage_designer.gd`, `addons/vn_studio/editor/raven_fx_timeline.gd`, `tests/raven/vn_studio_stage_fx_smoke.gd`, own progress shard and this note.
- Donor `scripts/vn/portrait_motion_rig.gd` uses native `AnimationPlayer` infinite loop. **Reuse decision: adapt semantic idea, not code**. Draft preview already has a deterministic time sampler and required arbitrary timeline seek/undo; using independent `AnimationPlayer` or `Tween` per cue would make backward scrub/state restoration harder and add another presenter. Preview transforms reuse existing Godot Controls directly.
- No edits to `scripts/raven/raven_vn_fx_runtime.gd` or shared sample math; those belong to a separate VN Runtime integration-review contract. Existing `approved` runtime bundles **reject** new effect IDs and `loop` until explicitly supported. Editor review export remains `runtimeApplied:false`, no auto-approval.

## Semantics and explicit limits

- Default new **breathing** preset creates `loop: true` on a v1 actor cue; during the selected line it samples every `durationMs` (default 1600ms). Old cues with no `loop` stay exactly limited to their original `repeat` count. Loop checkbox can toggle this option on an existing actor breath. Loop is invalid on backgrounds, props, other effects and non-idle phases.
- Loop math can be sampled at any nonnegative elapsed time. UI previews the existing 0–20s timeline, and displays a track extending to its edge; preview playback still stops after 20s, not a claim about game session/line lifecycle.
- Slide-in controls start at up to 80 preview px of horizontal displacement and alpha 0, smoothly converge to baseline and alpha 1 over ~650ms. Slide-out starts at baseline and finishes displaced+hidden, holding final state during editor preview. Pressing Reset restores the original layout.
- Hop is a 420ms upward-and-downward displacement (negative Y), fully returns to baseline; no additional images or rigs. Only valid on actors.
- Every cue keeps the existing bounded 0–20s schema and 32-cue cap; `loop` extends **sampling** rather than serialized cue duration. Signed direction is in the effect ID. Phase is for display; editor still does not schedule actual game entry/exit.
- If several FX target the same actor simultaneously, visual offsets add, scales and alphas multiply using the existing preview composite. No gameplay/reducer/save or canonical stage mutations.

## Acceptance tests and rollback

- Validate all new cues and optional `loop` roundtrip through JSON; reject string `"true"`, other effects and background loop.
- Legacy breathe remains neutral after its original 8s; new breathe matches deterministic phase at 400ms and 8400ms.
- Motion samples before, during and after clip; per-actor targets only, direction correctness, alpha holds, hop ends at baseline, -1 reset.
- Native Editor Stage preview drag/selection remains stable; emit one Undo point per preset/loop toggle. Check 1024×640 control access and saved/reopened draft manually.
- Existing runtime-approved FX and old authored v1 drafts must remain unaffected. Rollback: revert this PR, no data migration.
