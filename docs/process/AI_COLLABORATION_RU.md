# Raven Manor — единый протокол ChatGPT / Codex / DeepSeek / human PR

**Version 1 — 2026-10-27.** Эти правила не зависят от языка/модели AI и являются частью репозитория. Точка входа — `AGENTS.md`; все платформенные entrypoints ссылаются сюда. **Инструкции в чате не имеют права незаметно переписывать подтверждённые решения `docs/DECISIONS.md`.**

## 0. До ответа или правки

1. Установить точный репозиторий и HEAD: `bezdredoff/RavenManor-Godot` — Godot/runtime + art production manifests + статусы; `bezdredoff/RavenManor` — *private* source lore/narrative; `bezdredoff/UPDS-godot` — donor common VN/Match-3/settings. Не полагаться на локальное имя каталога или старый чат. Проверить `git rev-parse --show-toplevel`, `git status --short --branch`, `git remote -v` при наличии терминала; иначе GitHub API и точный ref.
2. Fetch актуальный `origin/main`, идентификатор коммита, open PRs для задачи, `AGENTS.md`, `docs/DECISIONS.md`, `docs/STATUS.md`, `docs/INDEX.md`, две карты production `GRAPHICS_PRODUCTION_ROADMAP_RU.md` и `CODE_PRODUCTION_ROADMAP_RU.md`. Чтение остальных документов — **точечное** по задаче: `NARRATIVE_GAMEPLAY_INTEGRATION.md`, `season1_dialogue_catalog.json`, `manor_greybox_graph.json`, `story_props.json`, `vn_staging.json`, Room Builder спецификация, GFX workflow.
3. Дашборд `/dashboard/` — **только generated view**. Источники задач: `data/raven/production/code_work_packages.json`, `docs/production/GRAPHICS_PRODUCTION_ROADMAP_RU.md`, `data/raven/production/gap_work_packages.json`; текущие статусы/evidence — `data/raven/production/production_progress.json`. Нельзя править `dashboard/status.json` вместо источника. Отсутствие progress override не означает acceptance.
4. Выбрать ID существующей задачи. Если её нет — предложить новый ID и добавить backlog entry **до** реализации; не изобретать альтернативное «главное» описание проекта.
5. Посмотреть в UPDS нужный компонент **до** реализации VN, Match-3, settings, audio, assets, responsive UI, input, animation или тестов. Записать origin path/SHA и решение: `verbatim`, `extract`, `adapter`, `new` (с обоснованием). Raven-only код уместен для map/room/door/hotspot/NPC/repair/metaprogression.
6. Если task касается графики, проверить GFX stage и accepted manifest. Candidate PNG и rendering smoke не равны принятому арту; сюжетное содержание private-репозитория не копировать публично без согласованной границы.

## 1. Единый формат предложения задачи

Все агенты **до редактирования** выдают короткую proposal card (в чате или `docs/tasks/` для крупных изменений):

```text
Task: CODE-XX-YY | GFX-XX-YY | RM-GAP-XXX
Goal / user value:
Baseline: repo/ref/SHA; existing PR/related issue:
Evidence and source authority: canonical files/lines + donor UPDS SHA:
Approach: reuse (verbatim/extract/adapter/new) + trade-offs:
Scope: exact files/IDs; out-of-scope and compatibility:
Dependencies: CODE/GFX gates and accepted art:
Acceptance: behavior, visual/mobile, localization and save expectations:
Tests: commands and fixture/scenario; how to verify without tool access:
Status update plan: task ID, state, owner, evidence, updated:
Delivery: branch, PR, preview/ZIP if required, rollback:
Open questions: explicitly identified, no invented approvals:
```

Маленькие исправления могут объединить строки. Без существенного пробела в задаче **не задавать повторно вопросы, ответы на которые есть в main или в последних решениях**. Если агент без доступа к GitHub/файловой системе — предложить конкретный patch/ZIP и честно указать непроверенные шаги, не заявлять, что файл/PR создан.

## 2. Единый порядок исполнения

1. Небольшая task branch от актуального main или продолжение уже существующей branch/PR; ни один агент не должен перезаписывать чужую dirty checkout.
2. Изменения только в заявленном scope, модульный интерфейс, стабильные `RM-*` IDs, versioned format, обратная совместимость; seed и labels определяются данными. Никакой free tap-to-move, ванной как гейта спальни, магического ремонта, ранних supernatural reveals.
3. Рядом с кодом обновить тесты для нового behavior и регрессии; там, где меняется UPDS reusable logic, сравнить canonical donor oracle.
4. **В том же PR** обновить `data/raven/production/production_progress.json`: task ID, status, owner, date, evidence. Если scope/acceptance/dependencies изменился — поправить соответствующий исходный backlog + обе карты code/art только где нужно; не менять целиком старые утверждённые документы. Обновить `docs/STATUS.md` при фактически новом интегрированном behavior/quality gate, `docs/IMPLEMENTATION_PLAN.md` при существенном изменении delivery gates и `docs/INDEX.md` при новых документах.
5. Tests: `bash scripts/check.sh` либо `check.ps1 -GodotPath <path>`, targeted Godot tests, `python3 scripts/raven/tools/validate_code_plan.py`, dashboard build checker, target device/browser screenshots если визуальный diff. Указать выполнявшиеся команды **и что не запускалось**.
6. Опубликовать PR и дождаться actual CI на **последнем head SHA**. Если CI red — диагностика, исправление в той же ветке, повторная проверка. «PR открыт» ≠ «merged» ≠ «deployed» ≠ «device-approved». Не мержить без явного разрешения владельца.
7. Отчёт одним форматом: ID → цель → changed files + reusable upstream source → actual tests/CI → status в прогрессе → open risks/QA → PR/link и next dependency.

## 3. Протокол статусов / доказательств

- Предложено: `proposed`; к работе готово: `ready`; идёт работа: `in_progress`; PR ожидает ревью: `PR_review`; PR **реально объединён**: `merged`; подключён в текущем runtime: `integrated`; пройден указанный реальный девайс: `device_verified`; подтверждено пользователем/acceptance: `accepted`. Для блокировок в dashboard допускается `blocked` с причиной/evidence, после чего возобновить `ready`.
- Не помечать `accepted` по зелёному CI, скриншоту AI, фиктивному номеру PR или одному запущенному Godot smoke.
- Связанные ветки и PR не конкурируют за источник истины; merged main и status entries — authority. В `production_progress.json` обязательно `updated`, `evidence` и хотя бы task ID.
- Отчёт о рисках: затронутые сохранения, locale, story flags, новые GPX/model hashes, чужие workflow/dependencies и публичность assets/спойлеров.
- Не создавать календарные Gantt-даты задним числом: размер `S/M/L/XL`, dependency order и milestone достаточны до измеренного Hall pilot.

## 4. Доставка при ограничениях AI/GitHub

Default — connector/direct branch PR для небольших изменений, если GitHub connector действительно даёт upload. Если архив содержит много бинарных ассетов/большое число файлов, **не посылать 100 коммитов с изображениями подряд** и не пытаться скрыть пропуски. Подготовить версионированный delta archive согласно `docs/process/MOBILE_ZIP_PIPELINE_RU.md` и пропустить через read-only validate → candidate PR → independent CI → mobile QA → ручной merge. Не утверждать, что это автоматизировано, пока bootstrap ZIP importer не принят и проверен end-to-end.

Формат handoff для другого агента — ссылка на **main/PR и эти инструкции**, а не копипаста полного неактуального чата. Передача включает task IDs, known issues, exact branch SHA, QA evidence и куда положить следующие артефакты.

## 5. Различия ассистентов

| Агент | Ожидаемый режим |
|---|---|
| ChatGPT | Прочитать repo через GitHub connector, при недоступности действий — сгенерировать ZIP/patch и инструкции для mobile importer. Не притворяться, что файлы перемещены, если нет подтверждённого SHA. |
| Codex | Работать в конкретной checkout/branch, запускать Godot/JS/Python проверки, создавать PR. Не менять checkout с незакоммиченными пользовательскими файлами. |
| DeepSeek | Ревьюить/генерировать предложения в таком же Task/Acceptance формате. Если нет работающего доступа к repo, давать применимый diff/files с источниками и test plan; запросы пользователя на PR не закрывать словесным планом. |
| Human review | Принимает стиль, персонажей, canon, geometry, мобильную пригодность, бюджеты/миграции и релиз. CI не заменяет эти решения. |

**Обязательное правило:** после любой правки source/dependencies/script состояние задач и docs остаются консистентными с main. Дашборд не хранит независимую правду.
