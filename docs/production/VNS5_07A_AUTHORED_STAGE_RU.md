# VNS5-07A — фон и постановка новой сцены

Основание: [issue #121](https://github.com/bezdredoff/RavenManor-Godot/issues/121). Это первая ограниченная партия; VNS5-07B–07D ждут проверки владельца. Оригинальный утверждённый HTML-прототип в `main` не найден, поэтому визуальная parity с ним не заявлена.

В `Raven Manor → Director` существующие `sceneShots` показывают точный фон из VN-каталога поверх стиля панели. Для новой `RM-DRAFT-BEAT-*` сцены Stage остаётся видимым с маркировкой `DRAFT`. Начальная пустая постановка берёт первый реально зарегистрированный вариант фона; пользователь выбирает ID, lighting и roomState, добавляет 0–3 персонажей, назначает позу, эмоцию и координаты перетаскиванием. Персонажи берутся из текущего cast registry. Точная комбинация фона обязательна для новой сцены; неподтверждённый plate остаётся `ART CANDIDATE`, а не `accepted`.

Постановка новой сцены хранится в прежнем `user://raven_story_studio/v1/<root fingerprint>/draft.json` как `stagePatches[sceneId]`. Существующие drafts без этой записи открываются с пустой начальной постановкой. `sourceSha256`, `stageSourceSha256` и `castSourceSha256` блокируют устаревший draft. Общие Undo/Redo сохраняют снимки draft. Полный `Story Map review` JSON включает `stagePatches` и остальные поля. Старые частичные exports с новой сценой отклоняются. `res://`, canonical narrative, route gates, runtime, reducer, сейвы и статусы арта не меняются.

## Ручная проверка Windows Godot 4.7.2

1. Открыть Raven Manor → Director; выбрать `RM-BEAT-00-01` и убедиться, что виден apartment/day/packed_boxes. Выбрать сцену с hall/evening/dusty и ещё один фон. Проверить, что картинка заполняет Stage и персонажи находятся поверх неё.
2. Создать тестовую сцену `RM-DRAFT-BEAT-*`; убедиться, что Stage виден с маркировкой `DRAFT`, выбрать BG-HALL/evening/dusty.
3. Добавить двух разных персонажей; выбрать каждому pose/emotion и разные позиции, затем проверить видимость портретов. Проверить отклонение четвёртого и дубликата персонажа.
4. Сохранить локальный draft; закрыть и повторно открыть Studio/редактор. Сверить sceneId, фон, lighting/state, двух актёров, pose/emotion и позиции. Изменить позицию и проверить Undo/Redo, снова сохранить и открыть.
5. Создать `Story Map review` export и проверить `stagePatches[sceneId]`, `runtimeApplied=false`. Убедиться, что файлы `data/raven/production/`, игровой прогресс и статус арта не изменились.

Автоматическая проверка: `tests/raven/vn_studio_new_scenes_lines_smoke.gd`, `tests/raven/vn_studio_backgrounds_smoke.gd`, `scripts/check.sh` и dashboard validator. Headless тест не доказывает пиксельную видимость и работу мышью; это отдельный owner QA gate. Rollback: закрыть PR или удалить локальный `user://` draft после резервной копии; production файлы не затронуты.
