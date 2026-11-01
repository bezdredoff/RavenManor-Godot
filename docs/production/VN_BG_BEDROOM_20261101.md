# BG-BEDROOM — generated art and integration (2026-11-01)

Status: **candidate** after visual approval in ChatGPT, no Godot/browser/phone final QA yet.

## Art

**Room master:** Evelyn's inherited bedroom, ornate carved dark-wood bed and nightstand on the left, large Gothic window centered, burgundy curtains, rug and bedding, antique wardrobe and vanity on the right, brass chandelier, cream plaster. Anime-painterly cozy Gothic presentation; portrait-first 1080 × 1920, no characters or baked text/UI. Two independently rendered versions preserve the staging composition but are NOT bitwise pixel-aligned.

| Scene | Exact tuple | Asset | Source PNG |
|---|---|---|---|
| RM-BEAT-01-02 | `BG-BEDROOM:day:livable` | `day_livable.webp` | `BG-BEDROOM_day_livable_source.png` |
| RM-BEAT-06-03 | `BG-BEDROOM:night:livable` | `night_livable.webp` | `raven_manor_bedroom_under_moonlight.png` |

Both source images were independently rendered 941×1672, then resized with Pillow Lanczos to 1080×1920, RGB WebP quality 91/method 6. Visual differences are mainly lighting, sky and reflections; prop/architectural alignment is not mathematically guaranteed.

## Source provenance and hashes

- `BG-BEDROOM:day:livable` → `res://assets/raven/vn_backgrounds/bedroom/day_livable.webp`; source `BG-BEDROOM_day_livable_source.png` 941×1672; SHA-256 `a69b4aa0a8e470f005ad38235a554dadab5094bfef2867f02e755aa2f2530d2a`
- `BG-BEDROOM:night:livable` → `res://assets/raven/vn_backgrounds/bedroom/night_livable.webp`; source `raven_manor_bedroom_under_moonlight.png` 941×1672; SHA-256 `432e747b46468c3f533459a02c483cdb3ecf662f2d92462ed793ac696beee035`

## Runtime and VN Studio contract

No additional hardcoded game script mapping is needed: `data/raven/production/vn_staging.json` already maps the two scenes to those exact tuples; `scripts/raven/raven_vn_backgrounds.gd` uses that shared catalogue; `scripts/raven/raven_vn_game_view.gd` renders selected VN art in gameplay; VN Studio's Raven stage previews consume the same resolver. This incoming delta changes the *registry and test code*, not game navigation/save state.

The patch extends `vn_background_gallery_smoke.gd` (20 catalog entries, both scene lookup bindings, loaded textures/1080x1920, exact SHA256) and `vn_runtime_background_smoke.gd` (actual bedroom dialogue in Content Preview + Chapter VI standalone in-game compositor). The existing VN Studio smoke still checks dynamic imported catalogue count and staged exact texture selection; it does not need per-room hardcoding.

**Unfinished variants:** BG-BEDROOM covered/dirty state has **not been generated**. Map-ready separate furniture/occlusion states are not included. `day:covered` therefore remains `ART PENDING`; do not show a clean room as a dirty room.

## Manual QA

1. After green candidate CI and merge, update Godot project from `main` and restart editor. Verify **VN Studio → Raven Manor → Постановка**, `RM-BEAT-01-02` (day/livable) and `RM-BEAT-06-03` (night/livable); browse import catalogue (20 entries).
2. Prototype Lab → 8 · VN BACKGROUNDS: both day and night textures load as full-screen portrait without stretching.
3. Content Preview → VN → Bedroom: actual dialogue over background with Evelyn and Ada; Next still works and does not touch save.
4. Vertical Slice: progress to bedroom beat, verify exact day image behind dialogue and unchanged progression/match-3; verify Chapter VI night via VN Studio until full chapter runtime entry is available.
5. Confirm phones/short screens show no clipped dialogue buttons. A CI smoke cannot approve art and mobile layout.

Rollback: revert candidate PR. No save schema or storyline changes.
