# Hall tea VN scene — runnable art and localization pilot

**Status:** functional gameplay prototype with provisional art (NOT final character canon / layered face production).

## Entry and narrative scope

- **From map**: `RM-HUB-001` Hall -> tap `RM-HS-TEA-TABLE` -> Evelyn follows the authored `RM-NAV-HALL-SPAWN → RM-NAV-HALL-TEA` route -> localized modal appears -> press **Talk** -> Godot changes to `hall_tea_vn.tscn`. This trigger becomes available only after `RM-BEAT-01-05` (the playable RM-VS-01 closeout). The tea anchor is a distinct new node, not a rename of the grandfather-clock hotspot.
- **From Prototype Lab**: the new **VN Art Pilot** card launches the scene any time, for independent art / language QA. If Chapter I has not been completed, playback is preview-only and does not alter the Raven campaign save.
- **At final dialogue line**: `RM-BEAT-02-01` is emitted with a stable event ID **only after** `RM-BEAT-01-05` has been seen. Replays and language switches never duplicate this beat or pay currency. The existing Chapter-I director, Match-3 levels, restorations (2/4), and save schema are unchanged.
- **For now**: after the pilot finishes it returns to the current greybox map, not directly to a fully playable Chapter II kitchen. The subsequent screenplay scenes 2.2–6.3 remain unimplemented.

## Actual assets committed to the game

| File | Function |
|---|---|
| `assets/raven/vn_pilot/hall_morning.webp` | standalone painted Hall morning VN background |
| `assets/raven/vn_pilot/evelyn_relaxed.webp` | separate **transparent** Evelyn temporary VN sprite |
| `assets/raven/vn_pilot/ada_offer_tea.webp` | separate **transparent** Ada temporary VN sprite with tea tray |

All three were derived from images generated during the October 2026 prototype discussion and compressed to moderate mobile texture sizes. They are **real WebP files committed to Git**, not external hotlinks or baked text/screenshot art. The previous generated screenshots with three language captions are *visual reference only* and must **not** be used as localized runtime bitmaps.

**Visual QA concerns**: The current draft Evelyn sprite shows an apron-like panel that can be mistaken for the housekeeper's clothing. Character outfit and silhouette are therefore provisional and need canon art review. The source paintings are not calibrated as top-down gameplay map art and should never replace Room Builder's imported 65° Hall room scene.

## Runtime UI

`scripts/raven/hall_tea_vn.gd` composes the backdrop, both separate sprites and parchment-like dialogue UI responsively, with scene name, localized speaker name, next line, language switch and return button. It reads canonical line IDs `RM-BEAT-02-01-L001..L012` directly from `data/raven/production/season1_dialogue_catalog.json`, with authored translations for the **entire pilot beat** in RU/BE/EN. Changing language keeps the exact line and rebuilds text immediately; the language preference persists through `RavenProductionLocalization`.

The active speaker is emphasized via a smooth tint/fade transition. **Real facial morphs, sprite eye blinks, mouth/lipsync and per-limb gestures are not yet implemented** because generated sprites are single raster illustrations and the face/layer separation is not approved. This visual focus effect is deliberately modest rather than claiming to simulate production-grade animation. Next step is face/eye/mouth sprite layers from the same approved character master and calibrated VN anchors.

## Automated checks

- `tests/raven/hall_tea_vn_smoke.gd` covers actual WebP import, source + RU/BE/EN 12-line localization, authored route, valid new beat ID, idempotent replay and no Match-3 reward/economy change.
- Linux/Windows check scripts now parse `hall_tea_vn.gd` and execute the smoke test.
- Full translation release gate still correctly fails elsewhere: the other **268** story lines do not yet have EN/BE translation.
- The Chapter-II tea scene uses only the approved 12 screenplay lines. The generated screenshot's invented line about arguing with the house is **not** included in canonical story.

## QA walk-through

1. Open the Prototype Lab **VN Art Pilot** and check both characters, language selector and 12-line flow at 390 × 844.
2. Change RU → BE → EN mid-line; text, title and speaker name update, without resetting the line.
3. Open RM-VS-01 and complete the approved Chapter I flow; go to Navigation greybox.
4. Tap **АДА · ЧАЙ** in Hall. Evelyn must follow the anchor graph, then show the localized popup. Start the VN.
5. Finish dialogue; revisit the same hotspot and replay. Check no new reward and no duplicate beat.
6. Reset Chapter I and tap Hall tea again. Popup may show, but action is disabled until `RM-BEAT-01-05`.

**Known scope boundary:** Map avatar remains the existing Onoe test sprite, and the Hall world map remains the engineering greybox. The generated Evelyn/Ada assets currently appear in the VN, not as animated map walkers. This is intentional: it validates the map-trigger → image VN → localization → save pipeline before producing map walk cycles.
