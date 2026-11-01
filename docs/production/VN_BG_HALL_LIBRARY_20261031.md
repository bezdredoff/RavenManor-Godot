# Raven Manor — Hall / Library VN background candidates (2026-10-31)

**Task:** `GFX-08-05`, `GFX-08-06`, `GFX-08-07`. **Status: candidate for in-engine art review**, not accepted final art, not map backgrounds, not a season-one VN runtime release.

## Source and scope

- Author input: the ChatGPT image-generation discussions of 2026-10-31. User requested Hall in four lighting/room states, Library in five, and corrected the initial abandoned Library to show an **empty vase**. For the storm Library, no buckets/containers replace the furniture or desk.
- Source PNG filenames, original dimensions and SHA-256 of each derived WebP are recorded in `data/raven/production/vn_background_catalog.json`. Original ChatGPT prompts and iterative art conversations are the provenance; this is **not** a reproducible seeded local ComfyUI run.
- Nine WebP files under `assets/raven/vn_backgrounds/`: **4 BG-HALL** and **5 BG-LIBRARY**, each exported as 1080×1920. WebP quality 91; Hall sources 941×1672 upscaled without meaningful aspect ratio distortion. Library initial dusty source 1024×1536 was **center-cropped to 9:16** then resized; later four were already 1080×1920 but originated from a multi-variant collage, so true detail resolution is lower.
- The dusty Library has no flowers. In the storm version, the **desk remains**, and water is indicated by wet floor, rain/leak and reflections instead of removing furniture.

## Runtime integration

1. `scripts/raven/raven_vn_backgrounds.gd` resolves **exact** `(backgroundId, lighting, roomState)` triples from a whitelist. Scene IDs are mapped by canonical `vn_staging.json` (the returned catalog is read-only and cannot change story flags).
2. Existing Hall Tea VN `RM-BEAT-02-01` uses `BG-HALL:day:habitable` via a small adapter that keeps original dialogue, UI, localization, save/replay and fallback art. This is not a 65° map background.
3. Prototype Lab card **8 · VN BACKGROUNDS** opens a save-neutral gallery of all nine variants. Unavailable textures display `ART PENDING` instead of pretending other variants exist. Library Chapter III/V/VI VN scenes remain *not implemented in the released runtime*; the artwork is registered for their eventual authored scenes.
4. `tests/raven/hall_tea_vn_smoke.gd` checks nine textures, Hall Tea and storm Library routing, and preserves no-double-reward checks. Separate `tests/raven/vn_background_gallery_smoke.gd` offers focused headless checks.

## Scene routing

| Artwork | Story scenes |
|---|---|
| Hall evening/dusty | `RM-BEAT-01-01` |
| Hall day/habitable | `RM-BEAT-01-05`, `02-01`, `05-04`, `06-02` |
| Hall night/habitable | `RM-BEAT-01-04` |
| Hall night/storm | `RM-BEAT-05-01` |
| Library evening/shut_dusty | `RM-BEAT-03-01` |
| Library evening/usable | `RM-BEAT-03-02`, `03-03`, `06-01`, `06-POST` |
| Library day/usable | `RM-BEAT-03-04` |
| Library night/usable | `RM-BEAT-05-03` |
| Library night/storm_leak | `RM-BEAT-05-02` |

## Art / QA risks and acceptance

- Hall variants originate from separate images; their architecture and portrait placements have **not been proven pixel-registered**. Library initial dusty image has a somewhat different camera from the latest four revisions; **do not claim strict one-master geometry identity**.
- Gallery and tea pilot are **preview only**, not story presentation approval. Validate 390×844, 412×915, 430×932 and tablet, verify character foot/occlusion, WebP/WebGL import, compare Hall to the Room Builder landmarks.
- Map collision, 65° game view, Match-3, campaign save and character reveal rules are unchanged. Passing CI is not mobile QA.
- Delta ZIP is pinned to a specific main SHA. If main advances before upload to `incoming`, **repackage against the updated main**; never bypass stale-base validation.
- Status source-of-truth `docs/STATUS.md` and `data/raven/production/production_progress.json` must be updated in the final review PR. The importer candidate is exempt from automatic governance but human review must still record `GFX-08-05/06/07` as `PR_review` or `in_progress`, not `accepted`.

## Follow-up — VN Studio art-source integration (2026-11-01; PR candidate)

`addons/vn_studio/editor/raven_stage_designer.gd` now resolves exact `(backgroundId, lighting, roomState)` using `scripts/raven/raven_vn_backgrounds.gd` rather than always displaying the old Hall pilot. Variant browser lists all canonical declared master combinations with imported/missing indicators; scenes and actor positions remain untouched by preview. Missing assets explicitly show ART PENDING. Add each future WebP and catalog record, run both catalog/gallery and editor stage smokes, and record source/provenance in this document; no further background-specific hardcoding in the editor. Visual QA and source/master alignment remain unapproved.
