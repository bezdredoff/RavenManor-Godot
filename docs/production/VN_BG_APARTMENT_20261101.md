# BG-APARTMENT · four candidate VN background plates (2026-11-01)

**Status:** candidate, not approved art. **Scope:** VN scene editor and Prototype Lab gallery; not top-down map texture. **Scene binding:** `RM-BEAT-00-01` → `BG-APARTMENT:day:packed_boxes`.

## Approved integration contract (not final art approval)

All assets live in `assets/raven/vn_backgrounds/apartment/` and have **1080×1920** RGB WebP resolution. `data/raven/production/vn_background_catalog.json` contains the exact `(backgroundId,lighting,roomState,path,sha256)` tuple. The `raven_vn_backgrounds.gd` resolver, VN Studio (Raven Manor → Постановка → В каталоге) and Prototype Lab gallery all read this single catalog. The canonical `vn_staging.json` master now includes declared light/day/evening/night and states packed_boxes/inhabited/rainy. The game stage/episode IDs are untouched.

| WebP | Source PNG | Lighting | State | SHA-256 |
| --- | --- | --- | --- | --- |
| `day_inhabited.webp` | `raven_manor_daylight_study.png` | `day` | `inhabited` | `bfac52b190c756e2b1177f1ec8790ef0b9902504d1cfa8aed6201000e15b3de6` |
| `evening_rainy.webp` | `rainy_evening_apartment_study.png` | `evening` | `rainy` | `732227245de9ffd0cce75958d8051f2a7a716a6c3eb378f14273d48a15cd45c1` |
| `night_rainy.webp` | `rainy_midnight_study_at_raven_manor.png` | `night` | `rainy` | `626b2efce54056df0c10ee857e48a701731f9c61da8bd6c5a8ed6d8cd714432c` |
| `day_packed_boxes.webp` | `raven_manor_morning_departure.png` | `day` | `packed_boxes` | `d8b67bc125578a44905bc3b482451937d2ceb8e6c13c3777a025fd0b96acf6d9` |

Each generated PNG was **941×1672**, delivered individually, then Lanczos-resampled to **1080×1920** and saved as WebP quality 91/method 6. They are not a mathematically identical master lighting grade: architectural detail and prop parallax must be visually compared, particularly furniture, chandelier, city view, rugs, sofa/table, and luggage. The departure variant depicts a suitcase and coat rather than clearly packed moving boxes, so the `packed_boxes` narrative requirement is only partly represented. Weather is baked into the images; not a separate runtime overlay. No in-image text/characters.

## Upload gate

This text-only PR cannot include locally generated binary files through the currently connected GitHub interface. Do **not** merge until all four prepared WebP files are placed at the exact above paths in this PR branch. Missing textures intentionally fail the gallery and editor smoke tests. GitHub UI: open branch `assets/bg-apartment-four-variants`, directory `assets/raven/vn_backgrounds/apartment/`, **Add file → Upload files**, commit **to the same branch**. Then review Godot CI and image rendering on desktop.

## QA after all files are uploaded

1. Confirm image sizes and SHA-256s from catalog; current tests load/measure **every** WebP.
2. Godot Editor → VN Studio → Raven Manor → `RM-BEAT-00-01` → Постановка: the prologue apartment departure image is visible behind Evelyn.
3. Click `В каталоге: 13 фонов…` and select each of the 4 Apartment variants. Check selected scene/staging state and image, then return without authoring an unintended change.
4. Prototype Lab → 8 · VN BACKGROUNDS: verify all 13 images, both screen orientations as appropriate, and portrait centering; user approves aesthetics.
5. Check regression Hall Tea pilot, Library, UI overlays and games saves; independent local/phone QA still pending.

## Future asset pack rule

Keep every new image as one canonical catalog entry, stage master state authorization, source metadata, exact path, fixed 1080×1920 resolution, SHA256 and smoke test coverage in the **same PR**; update `docs/STATUS.md` and `production_progress.json`. **No changing scene IDs or art fallback to a different state.**
