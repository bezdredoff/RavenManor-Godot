# UPDS → Raven implementation matrix (2026-11-03)

| Feature | Upstream authority | Raven boundary | Current verification / task |
|---|---|---|---|
| Match-3 rules, specials, RNG | UPDS-godot `match3_game.gd` | vendored shared engine, Raven adapter | Imported; CODE-01/02 |
| Match-3 touch, hints, help, HUD | UPDS-godot screen components | Raven theme, no rewrite | CODE-02-06, CODE-02-03; real device QA pending |
| Level catalogue / campaign UI | 22 UPDS-godot level layouts | Raven IDs, fiction, economy and unlocks | GAME-M3-01; currently 3 Raven slice levels |
| VN paging, history, choices, skip/auto | UPDS-godot VN runtime | Raven staging and story content | CODE-03, VN-RUNTIME-01; verify each feature, not just editor |
| Main menu / pause / settings | UPDS-godot menu/settings | Raven copy, routes and save | GAME-UI-01, CODE-04-01 |
| Audio and accessibility | UPDS-godot preferences/audio | Raven sound/theme | CODE-04-02, CODE-10 |
| Save / campaign session | UPDS reusable interfaces only | **Raven sole progress authority** | GAME-LOOP-01, CODE-08 |
| Manor navigation, NPC, restoration | Raven-specific | Authored anchors, map states and specialists | CODE-05/06/07 |
| Chapter content and journal | Raven game bible | reviewed story registry | CODE-08/12, GAME-JOURNAL-01 |
| Release/mobile/offline | UPDS tested patterns | Raven Web pipeline | CODE-10, GAME-RELEASE-01 |

No duplicate gameplay engine, save authority, or import of school-themed UPDS story data. Source parity and mobile acceptance are separate gates.
