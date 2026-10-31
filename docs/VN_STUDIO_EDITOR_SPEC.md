# Raven Story Studio — Godot VN Editor и совместимая миграция UPDS

**Статус:** архитектурная спецификация / `PROPOSED_NOT_IMPLEMENTED`; 2026-10-31. **Задача:** `VN-EDITOR-00` (проектирование), продолжение `VN-EDITOR-01..08`. Реального плагина/конвертера эта спецификация не добавляет. **Связанные gates:** `CODE-03`, `CODE-04`, `CODE-08`, `CODE-09`, `CODE-11 × GFX-11`. Исполняющий репозиторий Raven: `bezdredoff/RavenManor-Godot`; донор UPDS: **`bezdredoff/UPDS-godot@main`**, не старые TypeScript догадки.

## 1. Решение / продуктовая цель

Создать **нативный `EditorPlugin` для Godot 4.7.2** с главным рабочим экраном `VN Studio`, визуальной постановкой сцен в стиле PowerPoint, таймлайном событий/реплик, карточками персонажей и графом ветвлений. Он должен:
1. **Безопасно просматривать ВСЮ новельную часть UPDS**, без ручного переписывания или принудительной конвертации.
2. Редактировать текст, позы, эмоции, фон, расстановку, анимации и условия через визуальные controls (drag/drop, inspector, timeline), сохраняя совместимость.
3. Конвертировать старые форматы в **версионированный общий формат** по явному решению, с отчётом о потерях, сравнением и rollback.
4. Создавать новые сцены для Raven Manor на том же runtime и предоставлять согласованный data API для людей и AI-агентов.
5. Работать **внутри Godot Editor**, а не в отдельном PWA или на сайте; игровые билды не содержат editor UI.

**Не цели:** переписать UPDS screenplay и прогрессию за один PR; автоматически заменить исходники; копировать личные/private ассеты UPDS в публичный Raven репозиторий; делать отдельную систему сохранений; реализовать универсальный Ren'Py; делать ненастоящий WYSIWYG браузерный рендер; считать временные Raven-портреты утверждёнными.

## 2. Два проекта / текущая реальность (инвентаризационный seed)

### UPDS-godot, канонический donor

- В `data/` имеются **45 Godot JSON-сцен** с индексами `0..44`, от `prologue.json` до `post_convenient_case_scene.json`; финальные исходы в `ending_outcomes.json`. Эти 45 — форматные сценовые индексы, не количество отдельных драматургических эпизодов.
- `data/prologue.json` содержит `sceneId`, `sceneIndex`, `nextSceneId`, `nextSceneIndex`, `background`, `titles`, `lines[].id` (`VN0001`...), `hidden`, `actors[{character,pose,layout}]`, `localized.{ru,en,be}` с `speaker/emotion/text`. Пример исходника: `data/prologue.json`, blob `9b1391ef97edeab43aa1a01ab6e167d7c4cccb4d`.
- `data/locker_scene.json` включает `variants.A/B/C`, `choices`, `choicePrompt`, `nextLevelId`, `onWinSceneIndex` (blob `a8b2f4b7779ef4e013903ab711065eaf86c8fb03`).
- `data/actor_layouts.json` содержит именованные placement presets/геометрию (blob `06bef3e99f850fac73bc229a3992c9334e2eb428`). Обязательно использовать существующие изображения и resolved asset IDs, а не выдумывать координаты.
- `scripts/vn/vn_screen.gd` — исходный полноценный UI: история, pagination, Auto/Skip, choices, portrait motion (blob `c44edec0f4a29f05e128cf2d4005009adca0f842`). `scripts/core/story_session.gd` связывает `sceneIndex`, read/choice/gates/Match-3/save, blob `ac926a6fcdcbd359cdc4a36081d02be8cd7ebe02`.
- На уровне исходного монорепозитория `bezdredoff/UPDS` существовал экспорт Godot данных из TypeScript/Markdown через `scripts/export-godot-prologue.cjs`. **Нельзя писать в автоматически генерируемые файлы старого пайплайна, считая их главным источником правды.** Текущий канонический нативный порт находится в отдельном `UPDS-godot`; при импорте обязательно фиксировать origin repo/ref/path/sha и read-only/authoritative designation.
- Формат UPDS *уже сейчас* имеет реальные валидационные случаи: скрытые режиссёрские строки, локализованные реплики, A/B/C-варианты, сюжетные condition gates и Match-3 переходы, три концовки, сохранения. Не сводить `hidden` к видимой реплике; не терять `VN####A/B/C` и значения исходных ID.
- Полная инвентаризация уникальных строк/артов/transition variants и прогоны parity — отдельная `VN-EDITOR-01`; не выдавать этот seed за законченный аудит.

### Raven Manor

- `scripts/raven/raven_vn_player.gd` — минимальный line/advance адаптер; `scripts/raven/hall_tea_vn.gd` — отдельный UI сцены чая.
- `scripts/shared/upds/dialogue_paging.gd` уже импортирован из UPDS; следует переиспользовать, а не писать альтернативный paginator.
- Сюжетные источники: `data/raven/production/season1_dialogue_catalog.json`, `line_performance_cues.json`, `vn_staging.json`, `character_performance.json`. Их DRAFT-статус **не означает** полностью работающий runtime.
- Прогресс игры: только `RavenReducer / RavenSnapshot / RavenCampaignStore`; stable `RM-BEAT-*`, `RM-CHAR-*`, `RM-LVL-*` и `RM-*` asset/prop IDs; никаких автоматических изменений story state от drag/drop или preview.
- Для первой проверки создания Raven-сцены используем `RM-BEAT-02-01` (Эвелин/Ада за чаем), отдельно от основной кампании, без утверждения временного арта.

## 3. Рабочее пространство: главный экран плагина

Godot native `@tool EditorPlugin`, `_has_main_screen()`, `_make_visible()`, `_get_plugin_name()`, `_get_plugin_icon()`, `_enter_tree/_exit_tree`; `Control` как главная редакторская область (подключаемая через `EditorInterface.get_editor_main_screen()`). На этапе реализации проверить актуальный engine API под Godot 4.7.2. Плагин живёт в `addons/vn_studio/`, его `editor/` не включён в экспорт игры; `runtime/` остаётся обычным доступным модулем.

**Окна/области (адаптируемый layout, docking/splitters):**
- **Список сцен/иерархия:** поиск по ID, главе, персонажу и тексту, фильтры `UPDS legacy / Raven / converted`; импорт/новая сцена, открытие исходного проекта read-only.
- **Центральная Stage:** реальный портретный игровой кадр, фон + прозрачные персонажи/props + text box; мышь drag/resize/order/snapping/guides, percent/native anchors, camera focus; необязательный full-screen preview. Не сжигать текст в фон.
- **Таймлайн:** строки, speaker, смена позы/эмоции, анимации/звуки, вставки, choices и переходы, скрытые stage directions. Копирование/перестановка без переименования ID без миграции.
- **Inspector справа:** authoring свойства выбранного объекта: charId, approved status, pose/outfit/expression, asset id, слои, z/focus, camera/background/light/overlay, duration/ease; все поля с валидацией ссылок.
- **Диалоги/локализация:** RU/BE/EN side-by-side, отдельные speaker/emotion vs текст, inline correction, подсветка переполнения, missing locale, поиск/замена.
- **Characters:** каталог, master identity, костюмы/позы/эмоции, прозрачные слои лица и предметы в руках, mini thumbnails, вход/выход, blink/breath/talk/reduced-motion fallbacks; карта/chibi отдельно от VN poses.
- **Story Graph:** `GraphEdit/GraphNode`: `scene → choice → condition → match3/return-map/ending`; видны orphan/циклы, но не вводить автоматически новую сюжетную логику.
- **Migration & Review:** original vs candidate side-by-side (включая русский/английский/белорусский), changed IDs, asset map, unsupported features, preview snapshots, explicit Apply/Export/Rollback.

**UX:** Undo/Redo через `EditorUndoRedoManager`, keyboard+mouse доступность, tooltips и контекстные действия, multi-select; без обязательного знания GDScript. Сначала desktop Godot editor; работа на Android Editor — самостоятельный QA gate, не предположение.

## 4. Разделение runtime / editor / game-specific логики

```text
addons/vn_studio/
  plugin.cfg, plugin.gd
  editor/           # main screen, stage canvas, timeline, graph, inspector, migration review
  runtime/          # presenter, controller, portrait slots/animations, pagination API
  formats/          # schema/version validator, import readers, conversion model
  docs/             # human user guide, agent contract, migration runbook
Raven:
  game_adapter/     # Raven scene provider, locale/art registry, reducer event sink
UPDS-godot:
  game_adapter/     # UPDS story session, choices, match3 gates, saves
```

`VN Engine`: deterministic presentation, line/page navigation, history, auto, skip-read-only, staging, animations, choices UI; depends on injected `SceneProvider`, `AssetResolver`, `LocalizationProvider`, `GameEventSink`, `ProgressStore` interfaces, **не** хранит самостоятельно campaign state. Адаптер Raven передаёт event -> Reducer только по подтверждённым действиям игрока, preview использует `NoOpEventSink` + in-memory save. UPDS adapter сохраняет своё `StorySession` и Match-3 gates (не заменять универсальным `RavenReducer`). По умолчанию authoring не выполняет события.

**Граница импортера:** `legacy reader` → неизменяемая модель legacy + provenance → нормализованная draft модель → validate/diff → write to new destination; donor исходники не перезаписываются. На первом этапе можно читать legacy `*.json` без конвертации. История/Auto/Skip/реконструкция сохранения — функции runtime и session adapter.

## 5. Новый формат `vn-studio-scene-v1` (предложение, ещё не утверждённый runtime schema)

Основной сериализуемый формат — **строгий версионированный JSON**, пригодный для Git, AI и `FileAccess`. Godot `Resource` для выбора/предпросмотра допустим как transient wrapper, но не должен создавать параллельный источник сценария. Human-friendly editor показывает эти данные без ручного JSON. Семантические поля:
- `format`, `schemaVersion`, `sceneId`, `titleKey`, `sourceRef` (`repo/ref/path/sha/legacySceneId` optional), `localeKeys`;
- `stage`: `backgroundId`, `lighting`, `overlays`, `characters` (id, outfit/pose/expression, `slot`, normalized position/scale/anchor/z), props/close-up;
- `beats[]`: **immutable unique lineId**, speakerId, `textKey`, `type` (`dialogue`, `stage_direction`, `choice`, `command`), `cues[]` (focus, expression, pose, gesture, bg, sound);
- `edges[]`: `kind: scene/choice/match3/map/ending`, targetId, condition descriptor; transitions/side effects through game-specific adapter with typed allowed events;
- `metadata`: `draft/approved`, source hashes, provenance of assets and last conversion warnings.

**Illustrative example; not an implemented parser:**
```json
{
  "format": "vn-studio-scene-v1",
  "schemaVersion": 1,
  "sceneId": "RM-BEAT-02-01",
  "stage": {"backgroundId": "BG-HALL", "characters": [
    {"id": "RM-CHAR-EVELYN", "slot": "left", "pose": "relaxed", "expression": "curious"},
    {"id": "RM-CHAR-ADA", "slot": "right", "pose": "offer_tray", "expression": "neutral"}
  ]},
  "beats": [
    {"lineId": "RM-BEAT-02-01-L001", "type": "dialogue", "speakerId": "RM-CHAR-ADA",
     "textKey": "RM-BEAT-02-01-L001", "cues": [{"kind": "focus", "characterId": "RM-CHAR-ADA"}]}
  ],
  "edges": [{"kind": "scene", "targetId": "RM-NEXT-BEAT-PLACEHOLDER"}],
  "metadata": {"status": "draft"}
}
```
`RM-NEXT-BEAT-PLACEHOLDER` выше — **только демонстрационный несуществующий ID**; нельзя принимать пример за каноническую сцену. Валидатор обязан отвергать неизвестные targets и отсутствующие assets при production export. Тексты/переводы не дублировать без необходимости: они принадлежат локализационному каталогу, редактор работает через provider/key. Runtime `sceneId` и `lineId` никогда не выводятся из индекса массива; при реорганизации нужен explicit ID map.

## 6. UPDS import / editing / conversion — режимы безопасности

**A · Legacy Viewer (P0):** открыть `UPDS-godot` path либо read-only snapshot из project-approved location, сделать inventory и восстановить renderer без каких-либо write-back. Источники и изображения остаются в private доноре. Отметить valid/unknown/unsupported отдельно, показать все `0..44` index сцен и ветки; отсутствие разрешённой исходной папки — понятная ошибка, не silent fallback.

**B · Compatibility editing (P1):** пользователь редактирует сцену, но пишет **не в donor data**, а в overlay/draft в своём workspace с `baseSha`, `originalPath`, `patches`. Для generated/derived файлов исторического `UPDS` источник истины должен быть определён явным preflight, иначе только preview. При совпадении `baseSha` overlay можно применить к выбранной authoring authority через отдельную команду и PR; при конфликте — diff/rebase/abort, без last-write-wins.

**C · Native conversion (P1):** копировать указанную версию `UPDS-godot` в **изолированный conversion output** `vn-studio-v1`; копировать лицензированные/private картинки только в исходном проекте при подтверждённых правах, **никогда в публичный RavenManor-Godot**. Импортёр выдаёт машинный `conversion_manifest.json`: sourceSha, scene/line/asset/choice/save mapping, transformed/retained/unsupported, before/after checksums, warnings, source locations и deterministic conversion version. Отдельный dry-run и diff обязательны; переключение runtime config — только следующим user-reviewed PR после parity. Run conversion twice = same output (без timestamps в нормализуемой семантике).

**Save compatibility:** UPDS numeric sceneIndex/line→new stable sceneId/lineId через `save_migration_map` и проверенный reloader; Raven `RM-*` ID не трогать. Все старые сейвы считаются data, а не заменяются во время preview. В случае неполного mapping — conversion blocked, не частично повреждённый save.

**Edge cases, которые проверяем:** `hidden:true` (редактируемое stage direction, не обычная player-facing реплика), `variants.A/B/C`, вариантные line IDs c suffix, `nextLevelId/onWinSceneIndex`, `choiceGate`, `nextSceneIndices`, `ending`/fallback, `readLines` для skip, настройки/локали, offscreen speaker, 1–3 actor layout, portrait assets/rigs, отсутствующий арт, linked clues, вручную отменённые изменения.

## 7. Проверки и acceptance gates

| Gate | Обязательное доказательство |
| --- | --- |
| E0 — donor audit | manifest всех исходных JSON и зависимостей `UPDS-godot`, pinned source commit/file SHAs, numeric coverage/unsupported summary |
| E1 — Viewer | все 45 сцен и RU/BE/EN данные доступны в Godot editor; фильтры, скрытые lines/ветки; ни одного изменённого исходного файла |
| E2 — Authoring | открыть сцену, drag персонажа, поменять позу/эмоцию/строку, сохранить/повторно открыть, Undo/Redo, не переименовать stable IDs |
| E3 — Migration | dry-run/diff/manifest/map/checksums, deterministic idempotent export, explicit write approval, reversible rollback |
| E4 — Parity | original и converted версии: стабильные line IDs, 3 locales, все выборы/переходы/3 endings, `hidden`/staging, Match-3 gates, save/resume/read-only skip; screenshot comparison на representative 390×844/412×915/430×932 |
| E5 — Raven | `RM-BEAT-02-01` открывается в редакторе и проигрывается общим VN player; сохранение карты/ревардов не меняется в preview, approved art/IDs не подменяются |
| E6 — Scale | AI-агент создаёт/правит тестовую сцену только по docs и schema; валидатор+CI на чистом checkout; human review; CODE-03 C3 и C11/GFX-11 остаются отдельными gates |

**Ноль потерь** означает доказанную семантическую полноту на проверенной выборке/всём пакете, а не `JSON parse OK`. Поначалу migrate only read-only proof and one UPDS prologue + branching `locker_scene`, затем всю 45-сценовую кампанию. Скриншоты сравнивать через настоящий Godot рендер, не CSS canvas. Не выдавать smoke за real device QA.

### Команды проверки для будущих PR

В Raven: `python3 scripts/raven/tools/validate_code_plan.py`, `python3 scripts/raven/tools/build_production_dashboard.py --check`, `python3 -m unittest scripts/raven/tools/test_production_dashboard_mobile.py`, `bash scripts/check.sh` или `check.ps1`. В UPDS-godot: `bash scripts/check.sh` или `check.ps1` и изолированный `tests/vn_preview.tscn`. Для будущего plugin: отдельные headless tests для импортера/schema/provenance/undo и Godot editor integration tests. Записывать **только реально исполненные** команды и CI evidence. Документация сама по себе НЕ проходит E0–E6.

## 8. План поставки / зависимости

`VN-EDITOR-00`: spec + entrypoints + backlog (этот PR). `VN-EDITOR-01`: exhaustive donor inventory, frozen corpus/expected fixtures. `VN-EDITOR-02`: EditorPlugin / Legacy Viewer read-only. `VN-EDITOR-03`: stage drag & dialogue timeline. `VN-EDITOR-04`: персонажи/анимации/assets. `VN-EDITOR-05`: story graph/choices. `VN-EDITOR-06`: versioned converter/compatibility overlay/save mapping. `VN-EDITOR-07`: parity automation, review & agent/human docs. `VN-EDITOR-08`: Raven Hall 2.1 pilot + UI runtime integration. Подробные P0/P1, S–XL, зависимости и статус — `data/raven/production/code_work_packages.json` + `production_progress.json`. **Эти задачи являются companion к CODE-03, а не вторым переписанным VN runtime.**

## 9. Инструкция / handoff

См. `docs/process/VN_STUDIO_AGENT_GUIDE_RU.md` для workflow человека/AI и ограничений. Перед каждым PR читать `AGENTS.md`, `docs/process/AI_COLLABORATION_RU.md`, `docs/STATUS.md`; проверять актуальный upstream `UPDS-godot@main` SHA. В PR: task ID, source/ref/blob SHAs, план reuse/adaptation, exact tests, статус/evidence в `production_progress.json` и `docs/STATUS.md`, rollback и user acceptance. Никогда не менять уже написанный сценарий ради технического удобства без явного сюжетного решения.
