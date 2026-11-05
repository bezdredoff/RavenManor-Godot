# Raven Manor — роли агентов, запуск и границы параллельной работы

**Актуально на 2026-11-05, после merge PROC-007 (#193–196).** Это инструкция/контракт репозитория, **не свидетельство установленного Hermes, запущенных агентов или подключённого LM Studio**.

Начало любой задачи: корневой [AGENTS.md](../../AGENTS.md) → этот регламент → ближайшие к изменяемым путям `AGENTS.md` → контракт модуля → актуальный GitHub main/PR/CI. Вложенный AGENTS дополняет, но не отменяет корневой. Если используемый harness не читает их автоматически, включить их в task brief явно.

## Разделение ответственности

- **Домен** — логическая зона разработки и единственный `data/raven/production/progress/<domain>.json`. Доменов **15**; это не требование держать 15 LLM одновременно.
- **Исполнитель** — ChatGPT, Codex, DeepSeek, Hermes agent или локальная модель. Может менять модель, не меняя права записи.
- **Интегратор** — ведёт общий reducer/save, публичные API/ID, `project.godot`, GitHub workflow и пересекающиеся PR. Изменения в этих зонах не параллелить.
- **Ревьюер** — может анализировать чужую область без прав записи. **Владелец продукта** единственный утверждает сюжет/арт/геометрию/ручную QA и merge.
- **Оркестратор** (например Hermes) — опциональная внешняя система для маршрутизации задач, запуска worktrees/моделей и мониторинга. Репозиторий **пока не запускает** такой сервис сам.

## 15 функциональных агентов и один status shard на каждого

| Domain | Зона ответственности / ориентиры путей | Граница |
|---|---|---|
| `vn-studio` | `addons/vn_studio/**`, редакторский UI, черновики и editor tests | не продвигать draft в runtime автоматически |
| `vn-runtime` | `scripts/raven/raven_vn_*.gd`, shell, Skip, FX и VN tests | общий save, scene IDs и canonical story — интегратор |
| `match3` | `scripts/match3/**`, `raven_match3_*.gd`, `raven_optional_campaign_controller.gd` | reducer, `vertical_slice.gd` и награды — интегратор |
| `manor-map` | `manor_navigation_graph.gd`, map/greybox, authored routes | canonical map/scene geometry требует review |
| `room-builder` | `tools/room-builder/**`, draft importer | draft layout не заменяет approved map |
| `restoration` | условия ремонтов, visual states и тесты | reducer/store — single-writer интеграция |
| `ui-shell` | `main_menu.gd`, `raven_settings_dialog.gd`, `raven_onboarding_dialog.gd` | UPDS-first; shared controller через интегратора |
| `campaign-core` | `raven_snapshot.gd`, `raven_reducer.gd`, `raven_campaign_store.gd`, `raven_ids.gd` | **исключительно интеграционный PR** |
| `character-art` | `assets/raven/characters/**`, art variants | candidate не accepted |
| `environment-art` | `assets/raven/vn_backgrounds/**`, Hall/environment art | camera/scale, rights и owner art review |
| `chibi-animation` | chibi sprites, frames и animation/FX contracts | не менять VN portraits/map scenes без интеграции |
| `map-props` | prop art/states, `tools/blender/**`, map asset manifests | экспорт не определяет коллизию и hotspot |
| `art-pipeline` | `scripts/raven/comfyui/**`, `art-handbook/**`, provenance/manifest | GPU generation не доказывается CI |
| `localization` | RU/BE/EN, переводные worklists и locale tests | изменение канона/ID требует сюжетного ревью |
| `qa-infrastructure` | `scripts/raven/tools/**`, `scripts/check_data.sh`, `.github/workflows/**` | CI/security/ZIP/Pages — интегратор |

**Домен определяет ответственность за задачи, не blanket write access.** `scripts/raven/`, `tests/raven/`, `scenes/raven/`, `data/raven/production/` и `assets/raven/` содержат пересекающиеся зоны. Перед исполнением задайте exact file allowlist и read-only inputs.

## Папки с локальными инструкциями

Читать подходящие `AGENTS.md`: `addons/vn_studio/`; `scripts/match3/`; `scripts/raven/` (также `comfyui/`, `tools/`); `tools/room-builder/`; `tools/blender/`; `scripts/shared/`; `scenes/raven/`; `tests/raven/`; `assets/raven/`; `art-handbook/`; `data/raven/production/` (также `progress/`). Для каждого изменяемого пути объединять инструкции родительских папок. При противоречиях остановиться, а не выбирать удобную версию.

## Операционный цикл: задача → PR → статусы → дашборд

1. **Read-only planning.** Проверить `main` SHA, текущие PR по Task ID, backlog definitions, live shard, source/asset contracts и донорский `bezdredoff/UPDS-godot` для UI/VN/M3. Не использовать прошлый чат вместо GitHub.
2. **Выделить независимые работы.** Для каждой задачи записать `domain, task ID, base SHA, owner, allowlist, dependencies, expected artifacts, tests, QA/rollback`. Запретить одновременно писать в один файл. Shared-contract change → отдельный интеграционный PR прежде чем выпускать consumers.
3. **Worktree/branch.** Один исполнитель — один worktree от свежего `origin/main` и ветка `agent/<domain>/<task-id>-topic`. Не перезаписывать `main`, чужой worktree или незакоммиченные изменения; никакого force push чужого PR.
4. **Реализация.** Изменять только согласованные код/тесты/документы, собственный `progress/<domain>.json` и уникальный `docs/changes/<TASK-ID>-topic.md`. Открытые P0/P1 используют `assignments.workstreamId`, P2 — `p2ReentryGroup`; в другом shard нет правки.
5. **PR и evidence.** Пока PR открыт — `PR_review` с реальной ссылкой. Все обязательные CI jobs должны PASS на последнем SHA: `data-contracts`, `godot-runtime`, `room-builder`, `art-pipeline`, `web-package`, aggregate `build`. Записывать только фактически выполнявшиеся тесты.
6. **Review/merge.** Merge только после разрешения владельца проекта. После подтверждения merge **агент своего домена** следующим маленьким PR/изменением ставит `merged` и ссылку на PR/CI. `accepted`/device QA — только по отдельным доказательствам, а не по CI.
7. **Автоматическая агрегация.** Dashboard строится из 15 shards. Статус/приоритет+assignment определяют workstreams и P2. `dashboard/status.json` генерируется; **не** обновлять `production_progress.json`, `active_workstreams.taskIds` и `p2_reentry_policy.taskIds`.

### Параллельность и эскалация

**Можно:** VN Studio editor UX + Match-3 UI + Room Builder draft + независимые артовые manifests. **Нельзя без интегратора:** две правки `vertical_slice.gd`, reducer/snapshot/store, `raven_ids.gd`, `project.godot`, canonical story data, один approved asset, `.github/workflows/**`, `progress/index.json`. Конфликт: остановить второго writer → определить owner → выделить adapter/contract PR → провести интеграционный тест → продолжить.

**Возможное удешевление:** дешёвые/локальные LLM — анализ, документация, review и узкие проверки; более мощная модель — проектирование публичных контрактов, save migration, security и сложная интеграция. Выбор зависит от результатов тестов, а не от названия модели. Локальный LM Studio может быть *провайдером* через внешний harness, но сам по себе не запускает агентов и не даёт им права на репозиторий.

**Что уже проверяет CI:** branch-scoped запрет чужих **status shards**, обязательный per-PR evidence, ID/assignment validity и интеграционные тесты. **Чего он пока не гарантирует:** строгий ACL для всех исходников, автоматическое создание worktrees, фактический запуск Hermes, автослияние PR, art/device acceptance. Exact path allowlist для runtime сейчас процессный/ревью-контракт.

## Handoff card (скопировать в агентский task prompt)

```text
Repo: bezdredoff/RavenManor-Godot; main SHA:
Role / domain and Task ID:
Existing PR / dependency:
Read: root AGENTS + each relevant nested AGENTS + contracts + donor pinned SHA
Write allowlist: <exact paths> + progress/<domain>.json + unique docs/changes note
Forbidden shared files / reviewer:
Behavior and data contracts; compatibility/migration:
Tests (commands, expected result) and manual QA to leave pending:
Delivery: branch agent/<domain>/<id>-topic; PR URL and exact head CI link
No merge, no silent asset approval, no inferred device/owner acceptance.
```
