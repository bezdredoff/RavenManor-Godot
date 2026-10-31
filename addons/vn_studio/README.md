# VN Studio — Godot legacy authoring (VN-EDITOR-03)

**Status:** proposed native editor draft-authoring pilot, not a converter or runtime renderer. Requires Godot 4.7.2 desktop editor. UPDS-godot source files are **read-only**.

## Raven Manor — отдельный сценарий и сохранение результата (RAVEN-VN-EDITOR-01)

**В текущем Godot RavenManor-Godot откройте `VN Studio → Raven Manor`.** Эту вкладку можно открыть сразу, без приватной папки UPDS. Это **настоящий существующий Raven production screenplay**, не вымышленный тест: `data/raven/production/season1_dialogue_catalog.json` — 28 сцен / 280 реплик (8 `already_runtime`, 1 `pilot_runtime`, 18 `proposed_future_runtime`, 1 `optional`). Каталог статуса `PRODUCTION_DRAFT_NOT_RUNTIME` **не** подменяет уже работающие VN-сцены `data/raven/rm_vs_01_content.json`. Вкладка читает постановку из `vn_staging.json`, per-line directing из `line_performance_cues.json` и story/map triggers из `map_narrative_routes.json`.

**Как сохранить свою работу:**
1. Выберите сцену, затем реплику; смените `RU / BE / EN` и отредактируйте текст. Отсутствующие переводы BE/EN отображаются **как RU fallback с предупреждением**, без подмены реально отсутствующей локализации. Полные переводы есть пока только у части реплик (в этом источнике 12 из 280 для BE и EN).
2. Нажмите **«Сохранить Raven-черновик»**. Локальные правки записываются в `user://raven_story_studio/v1/<project-root-sha256>/draft.json` и автоматически восстановятся после перезапуска редактора. Этот файл содержит лишь **локальные переопределения текста**, не все 280 реплик. Кнопка не изменяет исходники Git.
3. Для review нажмите **«Экспортировать JSON-кандидат»** (сначала сохраните черновик). Создаётся версия **всего** каталога с правками: `user://raven_story_studio/v1/exports/raven-season1-<source-sha>-<patch-sha>.json`. Экспорт не перезаписывает существующий файл. Точный абсолютный путь показан под редактором. Сохранённый кандидат пригоден для сравнения с каноническим `data/raven/production/season1_dialogue_catalog.json` и отдельного review/PR; это **не** автоматическая публикация или подключение к игре. Не следует вручную заменять канон без проверки tests/PR governance.
4. Чтобы новый текст попал в репозиторий, сравните экспорт с каноническим JSON, внесите одобренные изменения через отдельный PR (с `docs/STATUS.md`, production dashboard, локализацией и тестами) и проверьте runtime-сцены отдельно. Существующие `rm_vs_01_content.json` и `Hall Tea` не получают изменений от локального draft/export.

**Безопасность:** каждый черновик связан с SHA256 канонического каталога и fingerprint пути проекта. Изменения в `season1_dialogue_catalog.json` извне блокируют сохранение/экспорт старого черновика; silent rebase/overwrite отсутствует. ID, порядок сцен и реплик, `speakerId`, `delivery`, route gates, production-stage/cues не меняются. Только `localized.ru/be/en.text`; русский текст не может быть пустым. Результаты прежнего UPDS не смешиваются с Raven — у них разные папки и схемы сохранения.

**Честные ограничения:** план постановки читается в текстовом виде, без генерации отсутствующего арта и без переноса/сохранения авторских координат. Это **редактор текстового production catalog**, ещё не полностью визуальный PowerPoint-like редактор сцены и **не** новый playable VN-runtime. Undo/Redo действует только на черновики; UI не гарантирует, что прокрутка длинных 280 реплик удобна, до ручного QA. Для внешних правок исходного JSON сначала экспортируйте локальный кандидат или сохраните свой draft, затем разрешите конфликт вручную. Статусы `already_runtime/pilot_runtime/proposed_future_runtime` не изменяются автоматически.

**Проверки:** `godot --headless --path . --script res://tests/raven/vn_studio_raven_story_smoke.gd --quit-after 120`. Тест читает **реальные** 28/280 канонических записей Raven в репозитории, затем синтетическую отдельную копию под `user://` для тестов редактирования RU/EN, fallback BE, сохранения/повторного открытия, экспорта/защиты от перезаписи, сохранения структуры и SHA drift. Основной канонический JSON, реальные UPDS файлы и сохранения не изменяются. Реальный desktop UX требует ручного QA.

## VN-EDITOR-06C — replay семантики сюжета перед приватным экспортом

После открытия **Migration & Review** и успешного dry-run нажмите **«Сравнить переходы и концовки»**. Это запускает `story_semantic_parity.gd` над **двумя независимыми представлениями данных**: read-only UPDS JSON и `vn-studio-scene-v1.payload` из текущего bundle. Проверка не изменяет источник и не включает новый runtime.

- По всем **45** сценам перебираются ветки A/B/C, позиции каждой реплики (в том числе `hidden`), состояние сюжетных выборов (до и после выбора), границы концовок. Сопоставляются ID, позиции после `resume`/`_skip_hidden`, `choiceGate` на контрольных репликах, специальная сцена 1 с прыжком на `VN0041A/B/C`, финальные маршруты, `nextSceneIndex`, `nextLevelId`, `onWinSceneIndex`, концовки с требованиями и fallback.
- Для финалов используются правила `data/ending_outcomes.json.outcomeRules` текущего **локального UPDS** (evidenceClueIds, baseTrustByChoice, storyChoiceEffects). Сравниваются итоговые evidence/teamTrust/sourceTrust и `fallbackCopy`, включая проход/провал порогов.
- Упакованный `legacyOriginal` обязан точно совпадать с источником. Изменять разрешается только локализованные тексты/эмоции/имена и позу/координаты существующих портретов; смена `choiceGate`, маршрута, уровня, финального ID, скрытой реплики или числа строк блокирует parity.
- Перед запуском результат `Bundle.prepare(project)` пересчитывается: исходные сцены/черновики не должны меняться после dry-run. **Интерфейс запрещает экспорт**, пока semantic replay не дал результат `DATA_SEMANTICS_PARITY_NOT_RUNTIME_ORACLE`. При ошибке нужно повторить анализ, а не игнорировать её.
- Успешный replay показывает число сравнённых сценариев, эпизодов выбора, Match-3, финалов и hidden/resume. Приватные реплики и тексты не попадают в отчёты CI или публичный GitHub.

**Граница доказательств:** это *data-level observational replay по изученному контракту* `UPDS-godot/scripts/core/story_session.gd`, **не** независимый прогон настоящего `StorySession` и не тест новой играбельной VN-системы. Он не выполняет внешний `CampaignData` и поэтому не подтверждает выдачу улик после Match-3, загрузку/запись сейвов, UI, визуальную постановку, пагинацию, анимации и синхронизацию `RavenReducer`. Даже при успешном replay мы **не** считаем `VN-EDITOR-06` или `VN-EDITOR-07` принятыми. Следующая задача — фактический прогон одинаковых историй в UPDS StorySession и новом общем runtime с публичными синтетическими эталонами, а затем закрытый real-donor QA.

Тест без приватного контента: `godot --headless --path . --script res://tests/raven/vn_studio_story_semantics_smoke.gd --quit-after 120`. Он искусственно создаёт 45 сцен, A/B/C, choices, 3 концовки, Match-3, hidden-строки, высокий/низкий trust, текстовую разрешённую правку и злоумышленно изменённый маршрут — последний должен завершаться ошибкой проверки. Документируется в `docs/STATUS.md` и `production_progress.json` того же PR.

## VN-EDITOR-06B — проверка существующих сохранений без импорта

Во вкладке **Migration & Review** после успешного **dry-run** доступна кнопка **«Выбрать JSON-сейв…»**. Укажите локальный JSON, экспортированный из UPDS, или собственный raw-save из разрешённой директории. Проверка читает выбранный файл **только в память**, не копирует его в Raven, не добавляет в миграционный bundle, не исправляет и не перезаписывает сохранение. Максимальный размер файла — 2 MiB.

Новая read-only `save_position_inspector.gd` сопоставляет `scene` (числовой индекс) и `line` с `save_contract.json` и `save_migration_map.json`. Для сцены 1 использует `choice` A/B/C (не `storyChoices`), для всех остальных сцен — `base`. Учитывает разрешённую позицию **после последней реплики финала**, сцену с `choiceGate`, список `completed` (числа → `levelIds`), `readLines`, `clues`, `tutorialsCompleted` и `storyChoices`; вычисляет предполагаемую следующую сцену финальной развилки при наличии стратегии. Неизвестные ID, недопустимые позиции и схемы блокируются. Hidden-позиция помечается предупреждением, потому что оригинальный `StorySession.resume()` вызывает `_skip_hidden()`.

Поддерживаются обычные story-save JSON и экспорт UPDS `{"format":"upds-campaign-save","saveKey":"...","schemaVersion":2,"state":{...}}`. Значение `saveKey` обязано соответствовать именно выбранному донору. Структуру сценария и отображаемые соответствия можно сравнить до начала миграции, но кнопки **«применить сейв» нет**. `StorySession`, `CampaignStore`, локальные/ручные сейвы UPDS остаются единственными авторитетными версиями прогрессии.

Для каждого экспортируемого файла в манифесте теперь присутствует `changePaths` — **только адреса изменённых полей, без самих приватных текстов**. Разрешены исключительно `localized.ru/en/be.speaker/emotion/text` и поля выбранной позы/координат существующих актёров (`pose`, `vnStudioX`, `vnStudioY`). Изменения `sceneId`, переходов Match-3, choices, концовок, числа/порядка реплик и произвольных полей блокируют dry-run. Это **field-level audit**, не side-by-side пользовательский diff со сравнением строк.

**Статус:** готово только статическое сопоставление позиций и защита от недопустимых изменений. Не реализовано: автоматическая миграция настоящего сейва в новую схему, восстановление игры из нового сейва, воспроизведение `StorySession` на конвертированных сценах, сравнение всех 45 реальных сцен и screenshot parity. Полная приёмка `VN-EDITOR-06` и `VN-EDITOR-07` остаётся заблокированной до этих проверок. Для проверки с локальным донором нельзя загружать его приватные сейвы, изображения или переводы в публичный PR.

Синтетические тесты: `godot --headless --path . --script res://tests/raven/vn_studio_save_position_smoke.gd --quit-after 120` плюс прежний `vn_studio_migration_smoke.gd`; повторно прогоняются Linux/Windows check scripts.

## VN-EDITOR-06 — Migration & Review, безопасный конвертер (часть 1)

В центральной панели VN Studio появилась вкладка **Migration & Review**. Конвертер работает на локальном **авторизованном** UPDS-godot, не пишет ничего в донор и **никогда не переключает игровой runtime**.

1. Сначала **сохраните локальные черновики** (`Сохранить черновик`). Unsaved edits блокируют dry-run.
2. Вкладка **Migration & Review → Проверить 45 сцен (dry-run)** читает только источник и `user://vn_studio_drafts/v1/`. Он проверяет фиксированные 45 scene IDs, число/ID строк и язык RU/EN/BE, схему и SHA исходных файлов, устаревшие черновики, а также строит индексацию сцен и веток. **При ошибке экспорт недоступен**; нет скрытого применения правок.
3. Слева показываются все будущие сцены и количество изменённых строк. Справа — список предупреждений (неблокирующих, если переход исполняется только в старом runtime), исходная/выходная SHA256 и имена файлов. **Это diff по составу/количеству правок, а не полноценный side-by-side текстовый diff.**
4. После ручного просмотра включите чекбокс **«Я проверил отчёт и подтверждаю приватный экспорт»** и нажмите **«Экспортировать новый bundle»**. Экспорт ограничен собственным `user://vn_studio_conversions/v1/<sourceRootSha256>/bundle-<bundleId>/`. Это **не** папка `res://`, не GitHub и не `UPDS-godot/data`. Директория существующего bundle **не перезаписывается**, старая версия игры не затрагивается. При неудачном staging он остаётся для ручного восстановления.
5. Для отката **не подключайте экспорт в runtime** или вручную уберите приватную папку выбранного bundle после проверки. Сцены и сейвы UPDS не менялись, поэтому откатывать саму игру не требуется. Не импортируйте приватные строки, переводы и изображения UPDS в публичный Raven.

### Формат временного bridge-v1

```text
user://vn_studio_conversions/v1/<root-fingerprint>/bundle-<bundle-id>/
  conversion_manifest.json  # source paths, per-scene old/new hashes, counts, warnings
  save_migration_map.json    # legacy numeric scene index → stable sceneId; per-group line index → legacy lineId
  scenes/
    00.json                  # format: vn-studio-scene-v1, schemaVersion:1
    ...
    44.json
```

Каждая обёртка `vn-studio-scene-v1` содержит неизменённый **`legacyOriginal`** и отдельный **`payload`**, в котором применены локальные черновики. `payload` сохраняет UPDS `localized`, `hidden`, `actors`, `variants.A/B/C`, `choiceGate`, `nextLevelId`, `onWinSceneIndex`, `nextSceneIndices` и `ending` без выдумывания семантики. Так мы можем сравнить/вернуть исходное содержимое даже когда будущая схема будет меняться. Файлы целиком включают **приватный контент**; переносить этот bundle в публичный Raven репозиторий нельзя.

**Важные ограничения:** полученная структура — **промежуточная миграционная обёртка, не готовый общий VN runtime**, даже если у неё версия v1. Миграция сохранений **не исполняется**: `save_migration_map.json` лишь проект карты соответствия со статусом `PROPOSED_NOT_VALIDATED_WITH_EXISTING_SAVES`, без реальных сохранений и реконструкции состояния. Не копируются ассеты, не пересчитываются условия `StorySession`, не проверяются визуальные переходы. `VN-EDITOR-07` должен проверить full-UPDS parity; `CODE-03` — адаптер для общей VN-системы. Поэтому утверждение о полной lossless/runtime/save миграции **пока было бы неверным**.

**Автотест:** `godot --headless --path . --script res://tests/raven/vn_studio_migration_smoke.gd --quit-after 120`. Искусственный корпус 45 сцен, A/B/C, разные локализации, `hidden`, локальный черновик, карты index/line, sha/determinism, явный экспорт только в отдельную директорию, отсутствие перезаписи, блокировка устаревшего preview. На реальном приватном доноре нужно отдельно проверить все 45 сцен и протестировать сейвы/переходы перед переключением какого-либо runtime.

## VN-EDITOR-05 — визуальный граф истории UPDS

После открытия локального `UPDS-godot` на центральном рабочем экране VN Studio появились вкладки **«Постановка»** и **«Граф сюжета»**. Граф использует штатный Godot `GraphEdit`; отдельного браузера или PWA нет.

- По умолчанию показывается **окрестность выбранной сцены**, чтобы не утонуть в 45 сценах. Выберите «Все сцены» для общей карты с панорамированием/масштабированием и мини-картой. Перемещение узлов меняет **только локальное отображение**, не сюжет.
- Узлы разного типа: сцена, **A/B/C вариант** (разные последовательности реплик одной сцены), `choiceGate` на контрольной реплике, Match-3, финал. Связи берутся из `nextSceneIndex/Id`, `nextLevelId` и `onWinSceneIndex`, `nextSceneIndices`, `ending` и `fallbackEndingId`. Нельзя считать все choices разными переходами: промежуточные `choiceGate` меняют игровые значения, но возвращаются к тому же потоку; только `final-strategy` задаёт три разные цели.
- Клик на узел показывает исходные ID, текст вопроса и названия/effect choices на выбранном языке, соответствующую контрольную реплику, требования `successRequirement` и фактические исходящие связи. Для узла-сцены есть «Открыть сцену» — переключает VN Studio на соответствующую сцену и сохраняет возможность просмотра её черновика.
- Неизвестные `sceneId`, Match-3 ID, некорректный чекпоинт, несовпадение `branchChoiceId` и контракта отражаются предупреждениями. Graph inspector выводит **описания** эффектов, не рассчитывает реальную механику доверия/улики.
- **Строго read-only**: попытка создать/разорвать связь не изменяет данные. Этот PR не редактирует граф, не импортирует сценарий в новый формат, не выдаёт наград, не модифицирует UPDS сохранения, не исполняет Godot `StorySession`.
- UI имеет реальный источник только после выбора приватного `UPDS-godot` с согласованным `save_contract.json`. Приватный текст выборов виден только локальному редактору, не копируется в публичный Raven.

Технический контракт: `editor/story_graph_model.gd` — чистое детерминированное построение узлов/рёбер; `editor/story_graph_view.gd` — независимая визуализация. Синтетическая проверка: `godot --headless --path . --script res://tests/raven/vn_studio_story_graph_smoke.gd --quit-after 120`. Проверяет варианты, gate, победные переходы Match-3, A/B/C финальные цели, fallback и отсутствие мутаций. Помимо CI нужна **ручная проверка с настоящими UPDS сценами**, масштабированием, текстом длинных выборов и навигацией. Не считать граф визуально принятым только на основании headless smoke.

## VN-EDITOR-04 · Каталог персонажей и локальный предпросмотр вариантов

На вкладке **«Персонажи»** в правой панели отображаются персонажи из `data/asset_catalog.json` **выбранного локального UPDS-godot**. Список показывает миниатюры `icon` там, где они есть; при выборе персонажа открывается галерея всех именованных *портретных* изображений (например `neutral`, `smile`, `serious`). Файлы загружаются **только из локального `assets/` UPDS**. Отсутствующий/невалидный ресурс обозначен предупреждением и недоступен для применения. `icon` и специальный `phone` не трактуются автоматически как обычные эмоции/костюмы. Превью не переносит изображения между репозиториями.

Чтобы использовать найденный портрет, сначала выберите сцену, реплику и **актёра** в редакторе. В галерее выберите **того же самого персонажа**, затем доступное изображение и нажмите «Применить изображение к актёру текущей реплики». Выбор запрещён, если ID персонажа отличается, нет файла, отсутствует черновик или исходник UPDS изменился. Применение — только патч поля `pose` в локальном черновике; Undo/Redo и «Сохранить черновик» работают как раньше. **Нельзя заменять одного персонажа другим незаметно.**

Внизу вкладки есть **preview-only микродвижения**: «Без движения», «Мягкое дыхание», «Появление». `Reduced motion` **включён по умолчанию** и подавляет все анимации; снимите флажок только для проверки. Движения редактора **не записываются** в черновики, не являются кодом `PortraitMotionRig` и не меняют анимации/сохранения игры.

**Реальность донорских данных:** в текущем `UPDS-godot@3deed628efd6c22bcd1717f7c545b7d3ca865781` каталог содержит **17 персонажей** с плоскими изображениями вариантов. Именованных нарядов, слоёв лица и отдельных клипов движения в `data/asset_catalog.json` **нет**. Интерфейс сообщает об этом, не создаёт мнимые asset IDs и не утверждает, что `smile` — полноценная послойная facial animation. Задачи по новому outfit/rig/animation schema остаются за общим VN runtime/CODE-03 и следующим production pipeline.

**Проверка:** `godot --headless --path . --script res://tests/raven/vn_studio_catalog_smoke.gd --quit-after 120` — синтетические PNG, 2 вымышленных элемента каталога, status missing, безопасные пути, редакторская pose-подмена без мутации источника. Дополнительно обязателен ручной QA в Godot desktop: список 17 настоящих персонажей, миниатюры, отсутствие missing art false-negatives, выбор подходящего актёра, Undo/Redo, Reduced Motion и сохранённый локальный черновик. CI не доказывает качество визуальных переходов.

## Workflow

1. Open RavenManor-Godot in the Godot desktop editor. Select the **VN Studio** tab, then **Открыть UPDS-godot…** and select the root of an authorized separate checkout of private `bezdredoff/UPDS-godot`.
2. Browse 45 scenes from `data/save_contract.json`, switch A/B/C branches and RU/EN/BE languages. Choose a line. If the scene has a saved local draft based on the **same source SHA**, it is reloaded automatically. If source changed, the scene is **blocked** and requires a manual diff/rebase; other scenes remain browsable.
3. Edit **speaker/emotion/dialogue text** for the currently selected language. Change a character's pose using the dropdown (only poses offered by the donor asset catalog), or drag a portrait on the stage to adjust normalized X/Y. The original legacy scene IDs, hidden stage directions, branch conditions, Match-3 gates and original line order are immutable.
4. **Undo / Redo** changes to the selected scene; typing is grouped by focus session, and each pose change/drag begins an undo step. Choose **Сохранить черновик** to persist edits. Unsaved changes stay in memory when browsing scenes; the editor blocks switching source projects if unsaved edits exist.
5. Close/reopen Godot, select the same donor root, scene and line: the draft reappears. The original UPDS source is not written, and nothing changes in campaign progression or saved player state.

## Where drafts live

`user://vn_studio_drafts/v1/<sha256-of-local-UPDS-root>/<sceneIndex>.json`

This is local Godot user data, **outside the publicly tracked Raven repository**. **Private edited UPDS text may appear in these files**. They must never be staged/committed to public Raven, uploaded as CI artifacts, attached to a PR or placed under `res://data`. Use appropriate local backup/access controls. The path is local to the Raven Godot user-data directory on that machine; these edits are not automatically synchronized or portable to another workstation.

Each `vn-studio-legacy-overlay-v1` file pins `sceneId`, source relative filename, `baseSha256` and a SHA256 fingerprint of the selected root path. Patch keys contain exact `[variant, lineIndex, lineId]`; localized changes use `speaker/emotion/text` and actors use index, original character ID, pose and normalized X/Y. Saving never touches `UPDS-godot/data`, `Raven/data`, `RavenReducer` or game saves.

Overlays are **not** imported runtime scene files. The existing UPDS VN renderer does **not** apply them. They are authoring drafts for the later reviewed converter (`VN-EDITOR-06`), not an implicit migration of gameplay or translations. They also do not grant publication rights for private UPDS assets.

### Conflicts and recovery

If a source file's content differs from the recorded base SHA, the draft is refused; the plugin does not silently rebase, discard, or overwrite it. Keep the source revision pinned or review/rebase patches in a later migration workflow. Saving uses a local temporary file, backup and rename; a backup may remain after an interrupted operation, so inspect locally before deleting it.

## Current limitations

- The stage preview is **approximate**, not pixel-perfect UPDS runtime preview. Drag uses normalized anchors, not donor `actor_layouts.json` global changes; it is per-line only. No free-added actors, new costumes or assets.
- Undo/redo covers the active scene, not a multi-scene transaction; built-in text editor shortcuts and plugin Undo button are distinct mechanisms.
- Missing/unsupported images render placeholders; an empty actor list has nothing to drag. The project must still pass the original UPDS donor path/version checks. No file chooser or right-click export for public source assets.
- Choices and level transitions are **read-only metadata**. No state mutation, save conversion, automatic GitHub upload, runtime line insertion/reorder, voice playback or interactive story graph.
- Only Godot desktop/editor UI has the visual controls; web Pages exports are not authoring surfaces.
- Re-read of the private donor in a real local Godot Editor is still a manual QA gate. CI only tests **synthetic** private-content-free fixtures.

## Tests

```bash
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/raven/vn_studio_legacy_smoke.gd --quit-after 120
godot --headless --path . --script res://tests/raven/vn_studio_drafts_smoke.gd --quit-after 120
bash scripts/check.sh
```

The draft smoke verifies line translations, pose/position, original bytes untouched, save/reopen, repeat save, wrong actor position blocked, separated A/B/C keys and SHA drift fail-closed. Manual acceptance: edit a line in UPDS prologue, pose/drag in the tea/other scene, switch languages and variants, save/restart, inspect no donor differences, check screenshot/font overflow, Undo/Redo. **Do not call acceptance passed from CI alone.**
