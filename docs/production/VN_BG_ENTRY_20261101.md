# BG-ENTRY incoming package

This package adds four Entry-family VN backgrounds for Raven Manor:

- BG-ENTRY:day:approachable
- BG-ENTRY:dusk:approachable
- BG-ENTRY:day:overgrown
- BG-ENTRY:dusk:overgrown

## Story-critical mappings
- RM-BEAT-00-03 -> BG-ENTRY:dusk:overgrown
- RM-BEAT-02-02 -> BG-ENTRY:day:approachable

## Files
- 4 WebP backgrounds in assets/raven/vn_backgrounds/entry/
- updated vn_background_catalog.json (14 -> 18 entries)
- updated vn_background_gallery_smoke.gd
- updated vn_runtime_background_smoke.gd

## Asset hashes
- dusk_approachable.webp: 727db24acd782bc3e73798439c4b2513899a2fe9d107de76b2b79b3ba646c4af
- day_approachable.webp: 4e97252d73f71b5bae00f9adc36b43374ccf9fb60098516a1afa8af32f89112c
- dusk_overgrown.webp: fd7d28661c069037d5ac22576152846d9ab2ec57072daf252e7773ae9bfab8c8
- day_overgrown.webp: 192dff481ade54600c24456226daaef66da99e0936277144cea6535bbac34cb0

Incoming R2 built from verified main SHA f0b070fe8a5b6c9347197c2f82b3e5b96a6adaee (2026-11-01); requires a fresh archive if main advances before upload. These are four independently generated candidate plates, not mathematically pixel-aligned variants. Art visual QA remains pending.


## Shared runtime and VN Studio integration
The catalog is the only new asset mapping; vn_staging.json already contains exact tuples for RM-BEAT-00-03 and RM-BEAT-02-02. Raven VN Studio imported-only browser and in-game RavenVNGameView resolve the same texture automatically via raven_vn_backgrounds.gd. No game save, VN story, map mesh or dialogue edits. Two new scene assertions in gallery smoke; gameplay VN smoke updated to expect real Entry art rather than ART PENDING.
