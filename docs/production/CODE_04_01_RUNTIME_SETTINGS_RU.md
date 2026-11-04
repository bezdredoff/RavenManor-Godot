# CODE-04-01 — игровые настройки Raven

Состояние: кандидат на PR; технические проверки прошли локально на Godot 4.7.2. Нативная визуальная и физическая device-приёмка владельца остаётся отдельным gate.

## Решение по UPDS

Донор: `bezdredoff/UPDS-godot@3deed628efd6c22bcd1717f7c545b7d3ca865781`.

| Донор | Blob SHA | Raven counterpart | Решение |
|---|---|---|---|
| `scripts/ui/player_preferences.gd` | `ea81a778c7adf7c0eac2834cd5be577878069153` | `scripts/shared/upds/player_preferences.gd` | Сохранён существующий адаптер; расширен обратно совместимым отдельным разделом `accessibility` |
| `scripts/ui/settings_screen.gd` | `2373147596c296631e01e43f8958a5e3a9a5fe00` | `scripts/raven/raven_settings_dialog.gd`, `scripts/raven/main_menu.gd`, `scripts/raven/vertical_slice.gd` | Адаптированы язык, музыкальная/эффектовая громкость, mute, haptics и доступность. PWA install/navigation и донорская тема не переносятся в Raven |
| `scripts/vn/vn_screen.gd` | `c44edec0f4a29f05e128cf2d4005009adca0f842` | VN header callback и runtime settings dialog | Адаптер поверх Raven `VNGameView`; игровой экран, реплики и кампания остаются Raven-owned |
| `scripts/core/reduced_motion.gd` | `a254137429cc0809cedbd24d8f0b3dd8263e3199` | Raven VN FX runtime и Match-3 presenter | Использован существующий Raven API отключения VN FX и добавлена прокидка persistent setting в два текущих экрана |

Полное донорское окно настроек специально не копируется: оно содержит платформенный PWA install и большую структуру меню, которые не соответствуют Raven runtime. Raven хранит кампанию и настройки раздельно. Реальное воспроизведение/остановка музыки и эффектов относится к `CODE-04-02`; этот пакет сохраняет значения и предоставляет доступные игроку controls.

## Изменение

Существующий `user://raven_language.cfg` остаётся единственным preference-файлом. Старые конфигурации без `[accessibility]` загружаются с безопасным default. Locale, audio и accessibility остаются в памяти без изменений, если запись нового значения завершилась ошибкой; неизвестные ключи отклоняются.

Игрок открывает настройки из VN header и из основного Match-3 интерфейса. Диалог перекрывает игру и блокирует ввод до закрытия; смена locale обновляет видимый текст, не меняя текущую реплику или Raven campaign revision. Reduced Motion сохраняется между запусками и сразу передаётся VN FX и Match-3 presenter.

## Проверки и границы

- `tests/raven/runtime_settings_smoke.gd`: old-config migration, locale/audio/accessibility round-trip, invalid key rejection, viewport 320×568 / 390×844 / 430×932, modal input lock, current VN line/revision preservation и немедленное применение Reduced Motion.
- `tests/raven/main_menu_smoke.gd`: Reduced Motion toggle из главного меню сохраняется в preference-файл.
- `tests/raven/match3_viewport_input_smoke.gd`: внешний settings modal блокирует board; восстановление ввода и persistent motion setter.
- Полный `scripts/check.sh` PASS на Godot 4.7.2.

Это не подтверждает звук на устройстве, фактическую haptics-вибрацию, физическую клавиатуру/сенсор, визуальную parity с UPDS или owner acceptance. Для отката: `git revert <commit>`; старые preference-файлы сохраняют обратную совместимость.
