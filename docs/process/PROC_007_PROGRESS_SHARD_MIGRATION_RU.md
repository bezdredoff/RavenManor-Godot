# PROC-007 — независимо обновляемый Production Dashboard
**2026-11-05: Stage 3b merged in #196.** Domain-owned shards, dynamic workstream/P2 membership and branch-scoped status governance are live. Full agent role/runbook guide: [AGENT_ORCHESTRATION_RU.md](AGENT_ORCHESTRATION_RU.md). External Hermes/LM Studio launch is not part of this merge.

## Источники истины
- `progress/<domain>.json`: актуальные `entries` (статусы, приоритеты, owner, QA, evidence, updated) и `assignments` (workstreamId либо p2ReentryGroup). Файл редактирует агент направления.
- `progress/index.json`: только неизменяемый список shard-файлов и migration floor для updated; изменение допустимо лишь через integration PR.
- `active_workstreams.json`: названия/фазы workstreams и индивидуальные acceptance/QA планы. **Нет** `taskIds`.
- `p2_reentry_policy.json`: действия/условия возврата P2. **Нет** `taskIds`.
- `gap_work_packages.json`, `code_work_packages.json`, GFX roadmap: исходные определения/исторические baseline statuses, не ledger текущих изменений.
- `production_progress.json`: замороженный historical Stage-1 snapshot. Никогда не обновлять.
- `dashboard/status.json`: только генерация при сборке, никаких ручных правок.

## Автоматическая группировка
1. Сборщик объединяет CODE/GFX/GAP определения с live-override из 15 shards. В каждом shard записаны только собственные задачи; переименование или перенос task ID требует отдельного проверяемого PR.
2. Открытые P0/P1 задачи получают группу из `assignments.workstreamId`; открытые P2 — из `assignments.p2ReentryGroup`. CI отвергает отсутствующие, дублированные и неизвестные назначения.
3. При `merged`, `accepted` и другом terminal status задача остаётся в своём JSON с history/evidence, но больше не числится активной в workstream/P2. Для перехода P2→P1 нужно в **том же файле** заменить `p2ReentryGroup` на `workstreamId`.
4. `updated` общего дашборда рассчитывается как максимум между историческим floor индекса и датами изменения отдельных task entries. Не требуется редактирование общей даты/индекса ради каждой задачи.

## Параллельные агенты и evidence
- Рабочая ветка: `agent/<domain>/<task-id>-topic`; scope: собственный shard + code/docs/tests по согласованной границе + уникальный `docs/changes/<TASK-ID>-<topic>.md`.
- CI по имени ветки запрещает изменения чужого shard, общего index и QA metadata; для общих контракто́в разрешён только отдельный coordinated integration PR с ручным review.
- В PR используется правдивый `PR_review` со ссылкой на открытый PR. После подтверждённого merge агент этого направления отдельным маленьким коммитом/следующим PR обновляет `merged`, сохраняя evidence. Это **не фоновый автозапуск**, а обязанности того же владельца. `accepted`/device QA никогда не выводится из CI автоматически.
- Историческая GAP status drift-синхронизация удалена: GAP baseline может отличаться от текущего shard, это ожидаемо, и CI не требует двух правок.

## Тесты и безопасность
- `scripts/raven/tools/progress_shards.py`: структура, уникальные IDs, assignment owner-domain consistency.
- `scripts/raven/tools/test_sharded_dashboard.py`: выходные группы и автопересчёт при смене статуса, P2→P1 с local assignment edit, missing-group blocking.
- `test_workstream_assignment_migration.py`: правила принадлежности и metadata без списков.
- `test_pr_governance.py`: domain branch ограничения, запрет frozen/generated status, сохранение исключения для numeric ZIP candidates.
- `bash scripts/check_data.sh`: production contracts + весь dashboard, и далее обязательные Godot/Room Builder/Art/Web CI jobs.
- `import-mobile-zip.yml`, consumer game runtime, save schema, assets и main-only Pages deploy не изменяются.

## История
- Stage 1 #193: 214 live progress overrides распределены без потери.
- Stage 2 #194: dashboard потребляет canonical shards, исходный монолит заморожен.
- Stage 3a #195: 80 active + 44 P2 assignments перенесены в соответствующие shards; 35 plan-only ID не получили вымышленных QA/status.
- Stage 3b #196 merged: динамическая группировка, governance, регрессионные тесты для независимых статусов.
