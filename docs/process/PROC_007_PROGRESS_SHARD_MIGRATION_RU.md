# PROC-007 — понаправленные статусы задач и единый Dashboard

**Решение владельца:** 2026-11-05. **Stage 1 #193 merged. Stage 2 (этот PR) переводит dashboard и GAP drift на shards. Stage 3 (независимое управление и workstreams) ещё впереди.**

## Зачем

Исторический `production_progress.json` ~280 KB, 213 записей + PROC-007. Одновременные агенты затрагивают один общий файл. Текущий `build_production_dashboard.py` накладывает его live statuses/evidence на определения `code_work_packages.json`, `gap_work_packages.json` и графический roadmap.

## Формат и ownership

`data/raven/production/progress/index.json`: schemaVersion, updated, authority, rules, **фиксированный список** независимых shard filenames. Индекс меняется лишь при добавлении нового направления/версии схемы.

`progress/<domain>.json`: `{"schemaVersion":1,"kind":"task_progress_shard","domain":"...","entries":[...]}`. Внутри каждой записи остаются **без изменений** `id`, `status`, `priority`, `owner`, `updated`, `evidence`, `implementationState`, `qaState`, `approvalState` и прочие исторические поля. Категория не зависит от текущего P0/P1/P2 или terminal-status, так что завершённые задачи не переезжают в архив.

Направления: VN Studio, VN Runtime, Match-3, Manor Map, Room Builder, Restoration, UI Shell, Campaign Core, Character Art, Environment Art, Art Pipeline, Chibi/Animation, Map Props, Localization, QA/Infrastructure. Назначение для уже известных ID фиксируется при миграции; новому ID агент должен назначить ровно **одну** область в своём PR.

`active_workstreams.json` пока остаётся группировкой рабочих потоков с собственными QA-gates. Не превращать его в новый источник статусов. На следующем этапе список taskIds станет производным от task.workstream (после проверки совместимости), иначе этот общий файл по-прежнему создаёт конфликты.

## Этапы миграции

1. **Stage 1 — parity, merged #193.** 214 (213 + PROC-007) записей разложены без изменений в отдельные shards. `progress_shards.py` строго проверяет уникальность ID, содержимое, список файлов и полное соответствие старому JSON, игнорируя лишь порядок записей. `check_data.sh` запускает проверку в обязательном `data-contracts` job. Dashboard пока читает legacy. Нельзя разрешать параллельным агентам редактировать shards в этой фазе.
2. **Stage 2 — переключение источника (этот PR).** Dashboard и reconcile_gap_statuses используют load_shards(); sourceFiles перечисляет все 15 shard-файлов и индекс. Временный обязательный shadow-render тест сравнивает весь результат со старой базой, кроме единственного намеренного изменения sourceFiles. Старый production_progress.json заморожен; нельзя вносить в него новые статусы. До Stage 3 независимая запись в shards ещё НЕ разрешена из-за общих gap/active workstreams.
3. **Stage 3 — write ownership и автоматическая группировка (не выполнено).** Удалить старое legacy исключение из governance, научить CI проверять diff paths по workstream, заменить обязательный handwritten `active_workstreams.taskIds` выводимым списком по задаче/отдельным group metadata. Автоматическое обновление dashboard только при сборке; merge/CI доказательства сверять отдельно. Правила статуса: `PR_review` и `merged` — техническая доставка; `accepted`/device QA только при явной приёмке.

## Инварианты и безопасность

- Один ID существует только в одном shard; ссылки на все task IDs должны соответствовать CODE/GAP/GFX authoritative planning definitions.
- История evidence, поля и зависимости не теряются. Отдельные agents никогда не редактируют общий dashboard/status.json, index или чужой shard без контракта.
- CI не должен ослабить blocking проверки данных/геймплея. `import-mobile-zip.yml`, candidate ZIP cleanup, Games Pages publishing и asset approvals неизменны.
- Main-прогресс проверяется после каждого merge. Старые незавершённые QA-задачи не должны автоматически стать accepted.

## Приёмка Stage 2

- tests/test_sharded_dashboard: полное сравнение результата legacy shadow-render и sharded-render, кроме намеренно обновлённого sourceFiles.
- Dashboard теперь реально читает shards; старый production_progress.json сохраняется только для аудита миграции.
- Правила независимых агентов не меняются до Stage 3: gap статусы и active_workstreams.taskIds пока общие, а QA/accepted требует явного evidence.
