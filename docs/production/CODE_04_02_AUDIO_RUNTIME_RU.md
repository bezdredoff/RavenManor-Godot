# CODE-04-02 — процедурное аудио Raven

Дата: 2026-11-04. Это review-кандидат; задача не считается принятой владельцем или проверенной на физических устройствах.

## Что включено

- `RavenAudio` — общий autoload для меню, VN и Match-3. Он переиспользует настройки звука, хранит один музыкальный и один эффектный player, переключает темы при смене экранов и останавливает воспроизведение при mute, нулевой громкости и потере фокуса.
- UPDS-подобные мелодии и эффекты синтезируются как PCM `AudioStreamWAV` во время выполнения. Файлы аудио, изображения и другие медиа-ассеты не создавались и не импортировались.
- Меню и VN используют UI/advance cues; Match-3 сообщает эффекты успешного и неуспешного хода, подсказки, каскады, победы и поражения. Кнопки настроек позволяют проверить музыку и эффекты.
- Вибрация вызывается только для поддерживаемой платформы при включённой настройке. Web использует `navigator.vibrate` с обработкой отказа браузера; Android/iOS — `Input.vibrate_handheld`. Возможность устройства показывается в настройках.
- Диалог настроек прокручивается и проверяется на окне 320×568; Escape/закрытие окна закрывает его. Новая музыка не стартует до пользовательской активации.

## Donor provenance

Источник: `bezdredoff/UPDS-godot@3deed628efd6c22bcd1717f7c545b7d3ca865781`.

| Donor path | Git blob |
| --- | --- |
| `scripts/ui/menu_audio.gd` | `87ab98324dd9e0b552a0ca1daf1f6cb23f10d9ff` |
| `scripts/audio_synthesis.gd` | `e3b46f30ffae771ef79bd3361286a92a871f88bf` |
| `data/menu_audio.json` | `b5f67535de3c1fa3d8d6278153311eb462e5abff` |
| `tests/ui/audio_smoke.gd` | `c483f14231f2b5e16f30129f8e378b72a17d0483` |

Raven-пути: `scripts/raven/raven_audio_runtime.gd`, `scripts/raven/raven_audio_synthesis.gd`, `data/raven/raven_menu_audio.json`. JSON содержит параметры синтеза и музыкальные cue definitions, а не записанные аудио-файлы. Адаптер сохраняет владение campaign/save за существующим Raven store/reducer.

## Проверки и границы

Godot 4.7.2 target smokes PASS: procedural synthesis/volume/mute/focus/theme routing, settings preview/capability, persistence/modal/locale, menu wiring, Match-3 viewport. Полный `scripts/check.sh` прошёл импорт, парсинг, audio/settings/runtime и несколько десятков других smoke-тестов, после этого был найден и исправлен устаревший assertion в `tests/raven/vn_runtime_background_smoke.gd`: он сравнивал legacy source text вместо текущего production catalog RU текста, а тест зависел от случайно сохранённой локали. Preview checks now use immutable line IDs; gameplay compares the visible line directly with the active VN player, avoiding any assumption about saved locale. The test explicitly selects RU for shared settings. Полный check запущен повторно.

Физическое прослушивание уровней, баланс/наушники/устройства, реальные браузерные autoplay и vibration API остаются открытыми. Текущая возможность haptics определяется платформой, а не доказательством конкретного подключённого моторчика. Owner QA и итоговая аудио-оценка не заявлены.
