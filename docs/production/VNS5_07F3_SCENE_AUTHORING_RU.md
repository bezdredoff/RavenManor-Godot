# VNS5-07F3 — создание новой сцены и управление авторскими репликами

Источник контракта: восстановленная из истории ChatGPT HTML v5, [issue #129](https://github.com/bezdredoff/RavenManor-Godot/issues/129). **PR_review, независимый CI и owner native Godot QA не выполнены на момент записи.**

## Изменения

- Кнопка **+ Сцена** открывает мастер: **глава (00/01/… — editorial draft group)**, **существующий каталогизированный фон с точными lighting/roomState**, **название RU**, **первая реплика RU** и **говорящий**. Значение главы сохраняется как необязательное `authoredScenes[].chapter` (две цифры, никогда не создаёт runtime gate/канонический ID). Старые черновики без поля читаются без миграции. Фон одновременно и атомарно сохраняется как `stagePatches[sceneId]`; не выбрать несуществующий или неподходящий exact plate. Первая реплика — в прежнем immutable source.
- Кнопки **↑ Реплика**, **↓ Реплика**, **− Реплика** управляют только строками `authoredLines`. Для канонических строк действия disabled. Перемещение меняет порядок массива, **не** lineId и не привязанные переводы/choices/FX.
- Удаление требует ConfirmationDialog; запрещено удалять последнюю реплику новой сцены или checkpoint, на который ссылается draft Story Map / FX. Патчи локализации удалённой строки очищаются, чтобы не оставались orphan IDs. Undo/Redo повторно используют существующие snapshots редактора.
- Уже существующие canonical сцены, реплики, route gates, FX, UMDS donor, RavenReducer и GameSave не меняются; `user://` draft и export review остаются отдельными от gameplay runtime.

## Существующие ограничения

- Сцена draft пока имеет ID вида `RM-DRAFT-BEAT-0001`, **не** `RM-BEAT-02-XX`. `chapter` — метаданные для последующего review, без переименования IDs и без выдуманного runtime.
- Порядок можно менять **внутри созданных пользователем строк**. Все canonical lines остаются перед authored блоком; смешивание и удаление канонического текста требует отдельного versioned storyline edit/approval контракта.
- После удаления свободный числовой ID может быть использован новой репликой, но только если этот ID не имеет зависимостей в текущем черновике (удаление блокируется валидатором). В review необходимо проверять diff; стабильные ID существующих строк не меняются.
- Генерация новых файлов изображений и полный animation track не входят в этот PR.

## Ручной QA (Godot 4.7.2)

1. Открой VN Studio → Raven Manor → `+ Сцена`; выбери главу 02, `BG-HALL / evening / dusty`, название и первую реплику; убедись, что Stage показывает именно выбранный фон, а draft содержит выбранную главу.
2. Добавь две реплики через `+ Реплика`. Выдели третью и нажми ↑, затем ↓; убедись, что **на том же lineId** остались RU/BE/EN переводы.
3. Выдели одну draft-реплику, нажми − Реплика, подтверди. Undo вернёт строку и позицию; Redo снова удалит.
4. На канонической сцене выбери исходную (не authored) реплику: кнопки ↑/↓/− не должны работать. Новую authored реплику в исходной сцене можно перемещать только среди остальных новых строк.
5. Создай `choice` с checkpoint на authored реплику, затем попробуй её удалить: операция должна быть заблокирована с понятным объяснением. Последняя реплика новой сцены тоже должна быть защищена.
6. Сохрани `user://` черновик, перезапусти Godot, проверь chapter/background/порядок/локализации и экспорт Story Review. Canonical source SHA unchanged.
7. Проверить окна 800×640, 1024×640, 1366×768 и чтение мастера при уменьшении высоты Editor.

## Автотесты

Обновлён `tests/raven/vn_studio_new_scenes_lines_smoke.gd`: exact BG/wizard, chapter/old-draft, invalid inputs, reorder/ID/locale, referenced checkpoint delete guard, last authored line protection, canonical immutability, direct UI operations, Undo/Redo and source SHA; полный CI по `scripts/check.sh`/GitHub обязательный.

**Следующие PR:** VNS5-07F4: `condition/ending` Story Map draft schema и editor, затем VNS5-07F5 visual timeline entrance/idle/exit с безопасным preview. Точное screenshot-паритет с HTML требует локальный исходник из предыдущего Codex handoff — не заявлять pixel parity без него.
