# Raven Manor — live VN backgrounds from VN Studio catalog

Date: 2026-11-01. **PR candidate; requires CI and owner approval.**

## Problem and scope

VN Studio and Prototype Lab already displayed 14 catalog variants. Gameplay RM-VS-01 and Content Preview showed only text. The new shared component at scripts/raven/raven_vn_game_view.gd is instantiated by both game UI controllers and draws the actual painting, cast portrait placeholders and the existing Hall Tea-style Gothic dialogue. The Next control calls the existing game player's next method, retaining scene IDs, story completion events, match-3 and save handling.

## Canonical data path

- rm_vs_01_content.json beatId → vn_staging.json sceneShot → raven_vn_backgrounds.gd exact lookup → vn_background_catalog.json image → 1080x1920 WebP.
- RM-BEAT-00-01: BG-APARTMENT:day:packed_boxes
- RM-BEAT-00-02: BG-ROAD:dusk:mist
- RM-BEAT-01-01: BG-HALL:evening:dusty
- RM-BEAT-01-04: BG-HALL:night:habitable
- RM-BEAT-01-05 and RM-BEAT-02-01: BG-HALL:day:habitable
- Undrawn BG-ENTRY, BEDROOM, BATH: explicitly ART PENDING; no substitute background.
- Hall Tea pilot uses the same catalog scene lookup rather than the old hardcoded hall_morning.webp.

## Characters and constraints

Only the original Evelyn/Ada prototype sprites have approved *technical* source paths; this renderer shows those as **provisional** and marks other characters ART PENDING. Character slots and their portrait-scale areas correspond to VN staging; full user-adjusted staging offsets and production pose/emotion compositing are not yet part of this game data. New art can be added to the background catalog without any further game-side per-scene mapping.

This change does **not** claim full screenplay VN migration, localized RU/BE/EN and multi-page text parity in the slice, or mobile portrait visual acceptance. It only closes the missing live-background rendering gap while preserving older gameplay progression.

## Checks and device QA

- New tests/raven/vn_runtime_background_smoke.gd: real game canvas Road, Apartment, pending Entry, staged actor, next-line progression, vertical-slice path and Hall Tea; run by scripts/check.sh and check.ps1.
- In 390x844 browser (after merge), play RM-VS-01 from the opening letter and into Road, verify backgrounds are behind actual dialogues, no crop-distortion and button reachable; check missing Entry text still advances.
- Content Preview: choose Road, Apartment, Gates; confirm image and placeholder behavior without changing the saved campaign.
- Check existing Hall Tea, map and Match-3 progression; any UI regression must block merge.

Rollback: revert this one PR; 14 art images and VN Studio catalog remain unchanged.
