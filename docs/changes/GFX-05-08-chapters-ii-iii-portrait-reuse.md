# GFX-05-08 — Chapter II–III approved portrait reuse

Task IDs: GFX-05-08 (existing character-art task); implementation name VN-ART-REUSE-01 (not a new backlog task).
Changes: Replace seven unavailable exact pose × emotion requirements in the eight Chapter II–III scene shots and 43 line cues with accepted, default-for-pose entries; reconcile review-only readiness and the existing test fixture. No new or modified portrait pixels/catalog entries.
Verification: GitHub-backed data transformation validated 62 accepted catalog frames, seven existing substitute IDs, eight affected cast placements, 43 exactly matched cue appearances and all 96 scene cues resolving to accepted defaultForPose portraits; in-engine tests, scripts/check_data.sh, scripts/check.sh, Windows check.ps1, and exact PR-head CI are NOT_RUN at authoring time and must be reported separately.
Owner QA: NOT_RUN — VN composition, facial expression compromises, micro-actions, room composition, device/mobile previews and production activation require explicit owner review.
Status impact: Only character-art GFX-05-08 evidence updated; remains ready / partial / manual_pending / approval pending. No newly registered task ID or scene promotion.

## Authority and baseline

- Source baseline: `bezdredoff/RavenManor-Godot@32a8d98d2fd3e75bf7613b8391f5ea7a769abd5a` (main after merged #291).
- The owner explicitly authorized **reusing accepted art, not creating or retouching seven new images**. Catalog: `data/raven/production/vn_character_catalog.json` (62 accepted frames as of 2026-11-02). Historical contact sheet: `docs/production/VN_ART_01_REFERENCE_CONTACT_SHEET.md`.
- The original seven missing exact variants remain **unproduced**; they are **no longer required** by current staging. Their visual fidelity is not falsely claimed.
- No UPDS transfer/adaptation is applicable: this is a Raven-only canonical content mapping using existing Raven assets, not a UI renderer or donor component change.

## Exact substitutions (all already accepted, all `defaultForPose=true`)

| Original requested pose / emotion | Actual catalog entry | Real pose / emotion | Affected cues | Expressive trade-off |
|---|---|---|---:|---|
| Ada `offer_tray/dry_amused` | `RM-VN-ADA-OFFER-TRAY` | `offer_tray/neutral` | 6 | Keeps serving pose/tray, loses dry amusement |
| Rowan `point_route/wry` | `RM-VN-ROWAN-POINT-ROUTE` | `point_route/neutral` | 7 | Keeps pointing/route intent, loses wry smile |
| Evelyn `investigate/curious` | `RM-VN-EVELYN-INVESTIGATE-SMALL` | `investigate/neutral` | 10 | Keeps investigation pose, loses curious expression |
| Evelyn `investigate/worried` | `RM-VN-EVELYN-BASE-WORRIED` | `relaxed/worried` | 10 | Keeps worry, loses investigative body pose; pose changes across adjacent scenes |
| Lucas `folder_present/professional` | `RM-VN-LUCAS-FOLDER-PRESENT` | `folder_present/neutral` | 2 | Keeps folder presentation, less explicitly professional facial acting |
| Lucas `explain/professional` | `RM-VN-LUCAS-EXPLAIN` | `explain/neutral` | 3 | Keeps explain gesture, loses professional expression |
| Lucas `explain/serious` | `RM-VN-LUCAS-BASE-SERIOUS` | `formal/serious` | 5 | Keeps seriousness, loses explain gesture |

**Total: 43 cue appearances.** The two Evelyn `investigate/worried` shots are `RM-BEAT-03-03` and `RM-BEAT-03-04` (five cues each). The accepted `RM-VN-EVELYN-INVESTIGATE-WIDE` is *not* used because its `defaultForPose` is false; the small investigate entry is the authoritative default.

## Motion and compositing audit

- `evelyn_note_glance` is defined as a head/rig micro in `character_performance.json` rather than a pose-specific raster effect. It is preserved on `relaxed/worried`; however, in `RM-BEAT-03-03` there is no prop overlay and `RM-BEAT-03-04` mixes unsigned-letter overlays and no overlay. Verify the resulting visual interpretation manually; do **not** claim a physical note gesture or introduce a new unsupported effect.
- `lucas_glasses_adjust` is rig-based and the accepted `formal/serious` portrait retains the glasses; the existing micro is semantically compatible. `lucas_page_align`, `ada_precise_straighten`, and `rowan_weight_shift` retain the related props/gestures in their accepted pose variants.
- Original `transitions.enter=fade_or_cut`, `transitions.expression=face_layer_fade` and reduced-motion `instant` stay unchanged. An exact expression-only fade may not be visually achievable across full-body pose switches; staging is review-only and no renderer fallback/visual acceptance is inferred. Owner should review `investigate → relaxed` and `explain → formal`, including consecutive cue transitions and cut/fade behavior.
- No micro / transition field was modified because the signatures above do not establish a technical incompatibility by themselves. If the compositor fails visually, address it in a separately reviewed runtime/FX follow-up rather than inventing art or altering story meaning.

## Preserved non-art gates

All eight scenes remain `runtimePromotion=false` and retain their original scene status, route ordinal, interaction target, route/gate kind/ref and `approvedRuntime=false` values. Only stale Hall Tea gate **explanatory prose** was corrected to reference the approved reuse and remaining owner activation review; no gate semantics changed.

Non-art blockers remain: `scene_status_review_only`, `route_not_approved_for_runtime`, unsupported `npc_tap` / `object_tap` / `door_tap` / `specialist_result` gate kinds where applicable, and missing foundation story beat registrations for later scenes. The removed blocker is precisely `missing_accepted_portrait_variants`. The manifest stays a review artifact, not a second story-state authority.

## Verification and reviewer checklist

- **Data checks performed in GitHub-connected transformation:** 8 cast entries mapped, 43 cues mapped with 7 exact counts (6/7/10/10/2/3/5), 19 cast appearances and 96 line cues across 8 scenes resolvable to accepted, `defaultForPose=true` metadata. Immutable story lines, line IDs/order, RU/BE/EN, camera focus, route/save authority and all other unaffected cues remain unchanged by the scoped transformation.
- **Fixture changes:** remove fake `SYNTHETIC-TEST-ONLY-ADA-TRAY` catalog entry; real accepted `RM-VN-ADA-OFFER-TRAY` is the positive case, and its removal / `defaultForPose=false` are negative cases. Additional exact-ID assertions cover all 43 substitutions; readiness expected missing count is zero.
- **Automated commands still required:** `bash scripts/check_data.sh`, `bash scripts/check.sh`, `pwsh -File check.ps1` if a Windows runner is available, then all exact PR-head GitHub Actions checks. Godot 4.7.2 and Windows PowerShell are unavailable in the connected authoring environment: **NOT_RUN**, not PASS.
- **Human QA still required:** compare staging in Hall Tea, kitchen and library, inspect 2–3-actor mobile composition, prop/hand continuity, Evelyn worrying while relaxed, Lucas serious while formal, eye/blink/mouth/micro behavior and reduced-motion. Screenshots and explicit owner sign-off are not provided by automated JSON validation.
- **Rollback:** revert the focused staging, cue, manifest, fixture and documentation patch. Accepted catalog assets/provenance, files and their SHA256 are unchanged; no save migration is necessary.

**No production scene is enabled and no merge is authorized by this PR.**
