# VN Studio — рабочая инструкция для человека и AI-агента

**Дата:** 2026-10-31 · **Статус:** инструкции для будущего плагина, **не** свидетельство его реализации. Авторитетный контракт: [VN_STUDIO_EDITOR_SPEC.md](../VN_STUDIO_EDITOR_SPEC.md), задачи `VN-EDITOR-00..08`, core `CODE-03`.

## Человек — как будет выглядеть рабочий процесс

1. Открыть **Godot Project → VN Studio** (после реализации плагина); выбрать `Open/Import` и игру `UPDS-godot` либо `Raven`. UPDS сначала в read-only `Legacy Viewer`.
2. Выбрать сцену по `sceneId`, открыть stage, выбрать `lineId`; переключать RU/BE/EN, variant A/B/C и preview route. Скрытые режиссёрские строки видны редактору, но не игроку.
3. Для исправления выбрать **Create draft/overlay**; изменить текст, выбрать артиста/эмоцию/позу в библиотеке, перетащить portrait; проверить алерты missing assets или transition. `Undo/Redo` и повторный `Open` должны вернуть тот же результат.
4. Выбрать **Preview (no progression writes)**: сыграть сцену через реальный VN runtime; затем `Diff` и `Validate`.
5. Для переноса проекта выбрать **Convert (dry-run)**, изучить source→target ID mapping и unsupported changes, затем явно `Export new format` в новую папку/ветку. Оригинальный `UPDS-godot` остаётся нетронутым. После сравнительных тестов и PR можно отдельно решать о switch-over.
6. Ни один draft/converted asset не становится accepted автоматически; право на публикацию приватных исходников UPDS в Raven отсутствует по умолчанию.

## AI / Codex / ChatGPT / DeepSeek — обязательные правила

- **Начать с реального `main` и задач:** проверить точный owner/repo (для донора `bezdredoff/UPDS-godot`; старый `bezdredoff/UPDS` — legacy pipeline), `git status` / API HEAD, docs/STATUS, открытый PR, canonical storyline/IDs. Не угадывать пути и не хранить локальные screenshot secrets.
- **Никогда не писать в donor по умолчанию.** Сначала immutable import/read-only; затем draft/overlay с source ref/SHA; target new format только отдельным конвертером и явным review. **Не подменять локальные сценарии Raven содержимым UPDS** или наоборот.
- **Сохранить идентичность:** scene/line IDs и locale keys immutable, если нет migration map; special `VN####A/B/C`, скрытые строки, ending gates, Match-3, readLines, save positions и `RM-*` reducer-owned события сохранять. Ни одна презентационная команда не выдаёт награду.
- **Не сочинять:** новых canon эмоций/сюжетных переходов, перевода, фонов, лицензий, approval статуса. Отсутствующий обязательный ресурс — warning/error, не выдуманный production ID. Держать `AssetResolver` как игру-зависимую границу.
- **При редактуре сценария:** менять только заданные реплики, локаль, staging или команду; не переписывать весь эпизод. В PR показать before/after IDs и проверку text parity, replay/redo, overflow, branches, no-op preview.
- **При изменении runtime/editor:** указывать источник UPDS (path + pinned blob SHA), решение `reuse/verbatim/extract/adapter/new` и его причину. Editor UI под `@tool`, core runtime без `EditorInterface` и game-specific save data.
- **Тесты:** unit schema/normalizer/determinism; imported fixture/no writes; branching/locale/hidden; Godot preview + screenshot parity; old-save migration; проверка ошибок и rollbacks. Не заявлять CI, phone/editor QA или разработанный feature без логов.
- **В каждом PR:** обновить `docs/STATUS.md` и `data/raven/production/production_progress.json`; новые scope/dependencies — исходный code backlog и дорожную карту. Дашборд генерируется, не редактировать `dashboard/status.json`. Не мержить автоматически.

## Формат задачи/PR

```text
Task ID: VN-EDITOR-XX (related CODE-03/C3)
Repo/branch/HEAD:
Donor source: bezdredoff/UPDS-godot @ commit, path + blob SHA
Source authority: original/derived/overlay/new; asset rights and status
Goal: user-visible operation in Godot
Input/Output: sceneId/lineId, schemaVersion, source SHA, target paths
Mutation scope: read-only / overlay / new converted output / explicit switch
Parity: scene/line/locale/hidden/choice/M3/ending/save mapping; visual viewports
Tests executed: command, exit code, CI URL, screenshots (if real)
Risks/rollback: immutable originals; converter diff and restore
Status: docs/STATUS + production_progress PR_review vs merged/accepted
```

**Первый демонстрационный кейс:** импортировать как read-only UPDS prologue и `locker_scene` A/B/C; затем Raven `RM-BEAT-02-01` и изменить staging/эмоцию через draft, не изменяя карту или сохранение.
