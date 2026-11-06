# VN-RUNTIME-01 — reviewed actor FX playback in Raven VN

Task IDs: VN-RUNTIME-01; related VN-EDITOR-07, VNS5-07F #226 (read-only dependency).
Changes: support Studio's 11 actor effects in runtime via opt-in deterministic shared FX sampler (without changing old `sample`); phase-aware enter/exit alpha persistence, 5 actor-only directional slide/hop motions, opt-in looped idle breathe, safe line/scene clocks beyond 20sec. Add an explicit **production-resident, reviewed opt-in** catalog entry for `RM-BEAT-02-01`: two looped breaths and first-line slides of Evelyn/Ada. Wire only Hall Tea and `vn_production` gameplay, never `user://` drafts, unrelated canon or technical VN.
Verification: Local Godot CLI unavailable NOT_RUN. `tests/raven/vn_fx_runtime_smoke.gd` extended to check live catalogue, both views, line transition, 20s+ loop, slide/alpha, invalid `loop`/target, no source writes, reduced motion, Skip. CI run pending at authoring.
Owner QA: **Do not merge without reviewing two-entry entrance choreography and two breathing loops.** On desktop/mobile: Tea L001 entry left/right; idle at >20s, L002 no repeated entrance, RU/BE/EN switch and page, Settings reducedMotion, Skip/read history, prior save and map restoration untouched. No eye-layer blink inferred.
Status impact: `data/raven/production/progress/vn-runtime.json` only. VN-RUNTIME-01 PR_review/partial, manual_pending. No modifications to vn-studio status shard, generated dashboard or frozen monolith.

## Baseline and dependency

- Raven main at branch creation `8c133b3ca415fa4b6c3d90e6a5ab4de50f3d5354`.
- **Blocking dependency**: user reported #226 merged but GitHub API still said `open` on repeated queries, `main` lacking its commit. This PR can validate independently, but **owner must merge #226 before this one** so Studio authoring of `loop`/slide/hop is present.
- Donor `bezdredoff/UPDS-godot@3deed628efd6c22bcd1717f7c545b7d3ca865781`, `scripts/vn/portrait_motion_rig.gd` blob `fcef111542a0d4bbef7ac50743a3f362efbd4782`: native looping `AnimationPlayer` respects reduced motion. **Reuse decision: adapt** semantics to existing Raven deterministic shared `MathFx` sampler and Raven FX runtime to support scene/line exact seeking; no donor asset/state import or alternative narrative controller.
- Cross-domain shared path `scripts/shared/vn/micro_fx_math.gd` touched only for a new `sample_reviewed`, requiring integration review; existing `sample()` mathematically unchanged for old editor/runtime payloads.
- Source boundaries: new `data/raven/production/vn_reviewed_fx_catalog.json` is a PR-authored presentation resource, **not automatic Studio promotion**. The literal `approvalStatus` flag is insufficient absent owner review/merge. No canonical dialogue/staging/story data modifications.

## Reviewed first-scene motion (owner accepts explicitly by merging)

| Scene | Actor | Cue | Timing | Why |
|---|---|---|---|---|
| RM-BEAT-02-01 | Evelyn | left slide-in on L001 | 0–650ms | Subtle staged introduction |
| RM-BEAT-02-01 | Ada | right slide-in on L001 | 0–650ms | Subtle staged introduction |
| RM-BEAT-02-01 | Evelyn | idle breathing | 1600ms cycle, loop | Procedural motion only |
| RM-BEAT-02-01 | Ada | idle breathing | 1600ms cycle, loop | Procedural motion only |

No explicit exit scheduled because the actual scene transition time is player-controlled. Other five motion types are supported by the engine but not assigned arbitrarily to narrative lines.

## Safety, compatibility and rollback

- Runtime accepts only `raven-vn-runtime-fx-v1` with explicit approved ref, exact scene/line IDs and known actor stage targets. Unapproved, malformed, unknown effect and prop target **fail closed** (no partial play).
- Optional `phase` and `loop` preserve old bundles. Only actor idle `breathe` may have true `loop`; slide/hop remain actor-only. FX is purely `position`, `scale`, `modulate.a` and cannot issue reducer/save events.
- Both VN surfaces continue their canonical layout reset before applying samples: no cumulative drift, focus alpha retained in Hall Tea. Skipping/reduced motion returns neutral and resets current transforms.
- Runtime clock no longer freezes at 20s; individual effect duration/offset/repeats still limited to max 20s, while breathing can run throughout reading time.
- Leaving scene/setting locale preserves existing `enter_line` semantics, and scene resets clocks.
- **No gameplay import of editor plugins/drafts**, no save-schema migrations. Revert this PR to rollback; empty/non-target scenes remain without FX.

## Developer and manual QA

- Run `bash scripts/check.sh` and/or `check.ps1`; exact PR-head workflow must pass `godot-runtime` and all six required jobs.
- Manual: on first Hall Tea line actors enter from two sides; breathe subtly while reading; inspect on 3rd+ line, locale and text pagination; toggle reduced motion, re-enable, Skip/read-only checkpoint; verify saved game/screenshot UI unchanged beyond presentation.
- Full approval to generalize FX to other scenes requires separate curated registry entries and owner review.
