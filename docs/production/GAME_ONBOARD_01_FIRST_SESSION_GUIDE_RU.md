# GAME-ONBOARD-01 — памятка первого игрового сеанса

2026-11-04 · review-кандидат. Реальная проверка игры на устройствах и owner acceptance остаются открытыми.

## Поведение

Перед началом новой кампании открывается spoiler-safe руководство. Игрок закрывает его кнопкой или системным закрытием окна, после чего начинает игру. Руководство можно повторно открыть кнопкой «Как играть» в главном меню или в игровом HUD. На игровом экране окно блокирует VN/Match-3 ввод; закрытие снимает блокировку. Руководство не записывает кампанию, не выбирает действия за игрока и не раскрывает события сюжета.

Содержание объясняет доступные двери и точки интереса с authored routing, подготовку через Match-3, различие подготовки и ремонта специалистом, базовые правила/подсказки Match-3, а также сохранение и Continue. Внутренняя contextual Match-3 Help остаётся источником подробностей о специальных фишках и блокерах.

## UPDS-first decision

Donor: `bezdredoff/UPDS-godot@3deed628efd6c22bcd1717f7c545b7d3ca865781`.

| Donor component | Blob | Raven use |
| --- | --- | --- |
| `scripts/match3/match3_screen.gd` | `76b42df35d4857f242d3f6bc06b9f989d43ad0a3` | Adapt modal tutorial/help rhythm and preserve explicit acknowledgement. |
| `scripts/match3/match3_tutorials.gd` | `cda888d62080ec09b16f2617a1eee9604441f3d8` | Preserve contextual tutorial semantics; do not mutate those completion rules from the general guide. |
| `scripts/ui/menu_copy.gd` | `56772fbfe5b704e406e9dfb833be1ec093a2b939` | Reuse the localized UI copy pattern and Match-3 Help rules. |

UPDS has contextual Match-3 tutorials but no general hub/save/specialist first-session guide. The generic guide is a Raven-specific adapter over Godot `Window` and existing localization/state. No new images, sound, animation or other assets were generated/imported.

## Verification and boundaries

`tests/raven/onboarding_smoke.gd` checks RU/EN copy, narrow-window fit, close signal, VN input blocking and zero campaign revision changes. `main_menu_smoke.gd` checks the replay action and first-new-game gate. Full `scripts/check.sh` passes on Godot 4.7.2 with a unique `XDG_DATA_HOME`. Manual device readability, keyboard focus, Exact-head PR CI run 41792693186 passed. Manual device readability, keyboard focus and owner acceptance are pending. This technical delivery does not claim the full authored map, specialist interactions or entire campaign are complete.
