Task IDs: CODE-10-01 (bounded increment: device-matrix reachability smoke)

Changes:
- New headless Godot smoke tests/raven/device_matrix_reachability_smoke.gd (registered in check.ps1 and scripts/check.sh; no runtime/save/catalog change, no duplicate of existing per-screen smokes).
- Boots the player menu at 320x568 / 390x844 / 430x932 in RU/BE/EN and asserts the six menu actions stay tappable and inside the viewport; opens Settings in RU/BE/EN (language persistence, sliders, toggles, back); enters the VN shell; opens the Match-3 campaign screen; opens the Match-3 QA preview; real scene routes (menu->onboarding->VN, menu->campaign, menu->PrototypeLab->QA board) run once at engine window size.
- Documents known layout limitations as limitations, not accepted behaviour: Prototype Lab hub 398px min column; QA preview fixed 315px board with one tile column partially clipped at 320px; Match-3 38px tiles at 320px below the 44px touch guideline.

Verification:
- EXECUTED_PASS: Godot 4.7.2 headless --script res://tests/raven/device_matrix_reachability_smoke.gd --quit-after 240 -> "Raven Manor device matrix 320/390/430 reachability smoke passed (468 layout checks)".
- check.ps1 NOT_RUN locally (PowerShell blocked by unattended-session approval policy); CI runs the full six-job suite.

Owner QA: not performed. Manual checks needed to close CODE-10-01 (real devices only, not CI): (1) 320px / 390px / 430px iPhones + Android ~360x800 + tablet: main menu fully in frame, 6 buttons pressable without scroll; (2) Settings RU/BE/EN at 320px, both preview buttons + Back fully pressable, locale persists after app restart; (3) VN New game->onboarding->first line in RU/BE/EN, Skip/Auto/Next >=44px, no overlap; (4) Match-3 "Уровни Match-3" at 320x568: board fits, swipe accuracy, hint/retry reachable via scroll; (5) Prototype Lab -> "ТЕСТИРОВАТЬ MATCH-3 БЕЗ СЮЖЕТА": QA card visible after scroll, RM-LVL-001 opens, no save/reward mutation; (6) airplane mode: menu->VN->Match-3 + minimize/restore keeps progress and locale; (7) Reduced Motion on 320px disables VN/Match-3 effects without changing layout. Record device/OS/resolution/locale + screenshots.

Status impact: CODE-10-01 stays ready/partial; evidence appended to the qa-infrastructure shard only.
