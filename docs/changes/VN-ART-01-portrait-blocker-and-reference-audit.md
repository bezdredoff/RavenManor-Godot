Task IDs: VN-ART-01.

Changes: Documentation-only approved-reference audit; zero portrait variants produced.

Verification: Fix five required governance evidence headings after run 44107117381 failed. Exact updated-head CI required.

Owner QA: All seven new portraits and all 43 affected cue appearances remain blocked; owner art approval pending.

Status impact: No completed-art claim. VN-ART-01 stays ready/pending; this draft delivers documentation only.

# VN-ART-01 — Chapter II–III portrait blocker audit

**Task IDs:** VN-ART-01 · **Domain:** character-art · **Priority:** P1.

**Baseline:** `main@ddcc8a646ffbfa60dcfea43849a592bfdddd9f24` (includes merged PRs #277 and #280). Git branch: `agent/character-art/VN-ART-01-chapters-2-3-portraits`.

## Changes

- Audited canonical Chapter II–III **readiness**, 62 accepted portrait catalog entries, seven required pose × emotion combinations and their staging/cue line IDs. All eight scene localization line counts match RU, BE and EN; seven scenes contain art blockers.
- Added a visible [reference-only contact sheet](../production/VN_ART_01_REFERENCE_CONTACT_SHEET.md) pairing each accepted **pose** with the accepted **facial-expression identity**. Each row truthfully marks the **missing new candidate**, records its reserved destination, scene/line coverage, original provenance SHA-256, and a per-asset edit/QA recipe.
- Updated **only** the `character-art` task progress shard to register a P1 task in `ready` status with delivery/approval still pending. No runtime registry or actual asset was changed.

## Exact verification performed

- **Metadata contract static check: PASS (repository catalog + readiness JSON):** 62 accepted existing entries; 7 distinct missing pairs; 43 impacted cue line appearances; 96 canonical Chapter II–III lines each in RU/BE/EN. Each missing combination has an accepted exact-pose reference and separate accepted exact-emotion/identity reference.
- **GitHub source inspection:** source WebP can be retrieved in base64; Ada `offer_tray/neutral` and `composed/dry_amused` images were visually inspected. No pixel-level artifact was produced or altered.
- **Godot 4.7.2 native import, texture, staging preview and device QA: NOT RUN** — no executable Godot runtime or production image editor in this execution environment; zero new candidate files exist.
- **Local CI checks: NOT RUN** — repository not locally available, and no GitHub Actions head-run result at authoring time. Report exact-head CI results from the draft PR only after they complete.

## Explicit per-asset blockers

| Asset | Impact | Blocking reason |
|---|---:|---|
| `ada/offer_tray_dry_amused` | 6 | Actual identity-consistent expression edit and image export not produced; image/alpha/engine QA and owner approval pending |
| `rowan/point_route_wry` | 7 | Actual identity-consistent expression edit and image export not produced; image/alpha/engine QA and owner approval pending |
| `evelyn/investigate_curious` | 10 | Actual identity-consistent expression edit and image export not produced; image/alpha/engine QA and owner approval pending |
| `evelyn/investigate_worried` | 10 | Actual identity-consistent expression edit and image export not produced; image/alpha/engine QA and owner approval pending |
| `lucas/folder_present_professional` | 2 | Actual identity-consistent expression edit and image export not produced; image/alpha/engine QA and owner approval pending |
| `lucas/explain_professional` | 3 | Actual identity-consistent expression edit and image export not produced; image/alpha/engine QA and owner approval pending |
| `lucas/explain_serious` | 5 | Actual identity-consistent expression edit and image export not produced; image/alpha/engine QA and owner approval pending |
| **Total** | **43** | **0 of 7 candidate WebPs; 0 of 7 accepted** |

**Priority:** Ada `offer_tray/dry_amused` for `RM-BEAT-02-01` Hall Tea (6 blocked cue uses). Inheriting `offer_tray/neutral` as an exact match would be a silent quality/acceptance error. The synthetic VN readiness fixture is not production art.

## Owner QA / acceptance procedure

Have an image-capable artist/agent create the seven exact variants on the listed approved pose sources with approved facial identity, complete per-image provenance and export. Review 1:1 against the sheet; load all seven independently into Godot VN Studio and scene previews, verify portrait bounds and all 43 cue IDs/three languages. Record separate owner approval per candidate before Agent D can register accepted images or promote scenes. Current PR is **review-only blocker documentation**, not an asset-ready production PR.

## Status impact

`VN-ART-01`: `ready`, `implementationState=not_recorded`, `qaState=not_recorded`, `approvalState=pending`; current work blocked at image production/import capability. Existing 62 accepted assets and canonical runtime/story/save registries remain untouched. No post-merge closeout claimed.

## Reuse, rights, rollback and coordination

Raven accepted portrait/pose/identity sources are reused as references (source paths and SHA-256 linked). No UPDS private art, asset copying, scene changes, new gameplay/UI controller or registry patch. Rollback is to revert this documentation/shard-only PR; no data migration, save or gameplay effects. Agent D receives zero new accepted IDs from this PR; the exact accepted registry patch is intentionally deferred until genuine image assets and owner approvals exist.
