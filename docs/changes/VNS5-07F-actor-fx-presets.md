# VNS5-07F — one-click actor FX presets for Raven VN Studio

Task IDs: VNS5-07F (functional FX usability); VN-EDITOR-07 (reconcile merged #218).
Changes: Six actor-only buttons — appearance/fade-in, disappearance/fade-out, breathing, short twitch/shake, emphasis/pulse, blink whole-portrait proxy. Reuse existing validated stageFxPatches v1 cues, stages and deterministic editor preview; preserve explicitly chosen FX target across inspector refresh. Extend the existing real Godot Stage FX smoke with model/preview/Undo/JSON-regression.
Verification: Inspected StageFx model, StageDesigner, shared MathFx and approved-only Raven runtime. Local Godot CLI NOT_RUN; exact PR-head CI pending at creation. `tests/raven/vn_studio_stage_fx_smoke.gd` already runs under `scripts/check.sh`.
Owner QA: In Windows Godot 4.7.2 choose Evelyn/Ada/Rowan in Stage and use all six buttons. Verify actor-specific target, playback/scrub, Strength/Duration, Undo, save/reopen. Native QA pending. Browser HTML pixel layout is non-blocking by owner decision.
Status impact: #218 is merged (6/6 CI), so clear VN-EDITOR-07 stale PR_review but keep broad task partial. VNS5-07F set PR_review for this scoped editor-only change; does NOT mean runtime FX or manual owner acceptance.

## Baseline, reuse and safety
- Raven source baseline `bezdredoff/RavenManor-Godot@9adc2807ef304a0a1a77e0abf329200ce5db3be6`.
- Private donor `bezdredoff/UPDS-godot@3deed628efd6c22bcd1717f7c545b7d3ca865781`: no identical Raven Studio actor-preset widget. Reuse: **adapt existing Raven StageFx and editor StageDesigner**, no new FX runtime or StorySession.
- No new assets, formats, lines, IDs, source data, canonical stories or gameplay/reducer/save. Existing draft FX exports remain review-only with explicit human promotion.

## Preset semantics (all adjustable in existing inspector)

| Preset button | Effect | Track | Start / Duration / Repeat (ms) | Intensity |
|---|---|---|---|---|
| Появление | fade_in | enter | 0 / 650 / 1 | 1.0 |
| Исчезновение | fade_out | exit | 1800 / 500 / 1 | 1.0 |
| Дыхание | breathe | idle | 0 / 1600 / 5 | 0.45 |
| Подёргивание | shake | idle | 550 / 220 / 1 | 0.45 |
| Акцент | pulse | idle | 250 / 400 / 1 | 0.45 |
| Моргание* | blink | idle | 950 / 200 / 1 | 0.55 |

`Моргание*` is NOT eye animation: it uses a short whole-portrait Y-axis squash. Proper eye blinks need approved eye layers/images and a reviewed asset renderer. Current breathing is only 8 seconds (limited repeats); perpetual idle cycle would require a separate timing contract. Exit preset keeps actor invisible after fade-out IN EDITOR PREVIEW, but existing `scripts/raven/raven_vn_fx_runtime.gd` calls the shared neutral-after-end sampler. Gameplay fade persistence must be fixed in a separate VN Runtime integration PR; editor draft cues are not automatically playable.

## Tests and owner acceptance
- Actor-only effect target, no accidental background/prop animation. Select explicitly as FX target or fallback to the Stage-selected actor.
- All six presets validate and survive JSON. Invalid preset is a no-op, no scriptable FX.
- Editor preview verifies appearance opacity 0→1, exit stays alpha 0 at 3s, model breathe scale and twitch offset; Undo removes added cues.
- Original canonical SHA unmodified; Windows editor UI/real device review still required, separate runtime/owner approval.
- Rollback: revert this PR; no data migration.
