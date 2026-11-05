# Ornith 1.5 — контракт процедурного исполнения в Hermes

**Версия:** 1.0, 2026-11-05. **Статус:** рабочая рекомендация по результатам пилота [#199](https://github.com/bezdredoff/RavenManor-Godot/pull/199) и [#200](https://github.com/bezdredoff/RavenManor-Godot/pull/200), не доказанная универсальная оценка всех локальных моделей.

Этот контракт **дополняет** корневой `AGENTS.md`, вложенные `AGENTS.md` и [общий регламент](AGENT_ORCHESTRATION_RU.md). Он не запускает Hermes и не выдаёт права на GitHub. Нельзя воспринимать более дешёвую модель как автономного исследователя только потому, что задача названа «документацией».

## 1. Когда разрешено назначать Ornith

Подходящая **процедурная** задача удовлетворяет **всем** условиям:

1. Цель, входные файлы и ожидаемый результат сформулированы однозначно.
2. Заранее перечислены **1–3 конкретных writable-файла**; `docs/changes/` и обязательный shard входят в бюджет файлов или явно выделены оркестратором как служебный postprocessing. Не скрывать реальные правки.
3. Алгоритм описан пошагово, без самостоятельного проектирования и без определения неизвестных зависимостей.
4. Команды/способы проверки и ожидаемые признаки успеха указаны **до** старта.
5. Входные источники доступны, есть возможность обнаружить `UNKNOWN` и остановиться.
6. Внешний reviewer/оркестратор может сверить diff и содержательные утверждения с исходниками.

Примеры: точечная механическая правка по образцу, перечень фактов из **заранее заданных трёх тестов**, табличный инвентарь, простая документация по проверенному шаблону, запуск указанной команды с сохранением фактического вывода. «Проверить весь проект» или «доказать отсутствие тестов» — **не** процедурная задача.

## 2. Кому передавать вместо Ornith

| Условие | Рекомендованный маршрут |
|---|---|
| Все шесть входных условий выполнены, нет неизвестных API и изменений общих контрактов | Ornith (с независимым ревью) |
| Нужна ограниченная навигация и уточнение нескольких известных ссылок | Qwen **только как кандидат** после отдельного измеренного пилота; до того — проверенный сильный исполнитель |
| Диагностика дефекта, неоднозначные требования, cross-module, миграция, сохранения, безопасность, самостоятельно искать root cause или тесты | Codex/frontier |
| Проверить истинность утверждений Ornith, оценить пропущенные зависимости | Проверенный reviewer; Qwen — только после валидации его review-качества |
| Узкий task внезапно требует неизвестных файлов/исследования | **STOP → Hermes → сильная модель**, не расширять scope Ornith |

Исполнитель выбирается **по сложности операции и подтверждённому качеству**, отдельно от одного из 15 `progress/<domain>.json` доменов. Один домен может использовать разные модели. Успешность Codex в #199 не означает, что у всех последующих Codex-заданий гарантирован PASS.

## 3. Запреты внутри задания Ornith

- **Не предполагай.** Непроверенный факт записывай `UNKNOWN` вместе с тем, что требуется для проверки.
- **Изменяй только явно разрешённые файлы.** Для изменения другого файла остановись и запроси новый allowlist.
- **Не расширяй задачу** и не переопределяй критерий готовности по ходу работы.
- **Точный источник для каждого вывода:** path + функция/assertion/строка или воспроизводимый вывод команды; цитируемый диапазон должен быть реально открыт, а не угадан.
- **Чтение ≠ исполнение.** Инспектирование исходника теста не доказывает его выполнение/прохождение. Различать `READ_ONLY`, `EXECUTED_PASS`, `EXECUTED_FAIL`, `NOT_RUN`, `UNKNOWN`.
- Не утверждать «во всём репозитории отсутствует», «все тесты синтетические», «паритет доказан» и подобные глобальные обобщения без исчерпывающего поиска/свидетельств.
- Не повышать `ready`/`in_progress` до `merged`/ `accepted` на основании написанного текста, локальной команды или успешного CI. Статус родительской задачи не закрывается частичным срезом.
- Не удалять и не ослаблять тесты, чтобы завершить задачу. Не выполнять merge.

## 4. Условия остановки и количество попыток

**Немедленный STOP_AND_ESCALATE:** неоднозначная семантика, отсутствующий входной файл/fixture, несовпадающий контракт, непредвиденное изменение внешнего API, необходимость редактировать чужой/shared файл, невоспроизводимая команда, невозможность подтвердить ключевой факт, превышение бюджета путей/контекста/итераций.

Допустима **одна заранее ограниченная повторная попытка**, только если Hermes/планировщик устранил неоднозначность и сделал вход ещё более конкретным. Повторять тот же открытый запрос до исчерпания контекста нельзя. После второй неудачи задача возвращается проверенному сильному исполнителю. Это рекомендация для местного harness, а не утверждение, что retry-policy уже автоматизирована.

## 5. Постоянный шаблон выдачи task brief

Заполнять только переменные, **не переписывать постоянные ограничения** при каждом вызове.

```text
EXECUTION CONTRACT: Ornith 1.5 / procedural / no autonomy

Task ID:
Domain / progress shard:
Base main SHA:
Goal (one measurable result):
Read-only source paths (exact):
Writable paths (1–3, exact; include evidence/status if worker writes them):
Steps:
  1. Open <exact source/test>.
  2. Read <named fixture/dependency> and verify <specific assertion>.
  3. Change only <exact file> following <specified pattern>.
Forbidden:
  - No code changes outside listed paths.
  - No new tests, task expansion, architectural decisions or unlisted dependencies.
  - No claims about unseen files or unexecuted tests.
Verification:
  Command A: <exact command> / expected marker:
  Command B: <exact command> / expected marker:
Stop conditions:
  UNKNOWN, absent fixture, new dependency, failing command, scope overflow
Definition of Done:
  - Only allowlisted files changed; patch/format checks completed.
  - Facts have path/line or command-output evidence.
  - Unknowns, commands executed, failed/skipped checks separately reported.
Reviewer: <independent verified reviewer / Hermes orchestrator>
Merge: owner only
```

Пример для VN Studio: составить таблицу **ровно** по `vn_studio_full_authoring_e2e_smoke.gd`, `vn_studio_backgrounds_smoke.gd`, `vn_studio_layout_smoke.gd`; открыть сами тесты и их непосредственно используемые источники; пометить `NOT_RUN`, если не запускались; не делать выводов о всём донорском корпусе, тестировании на телефоне и реальных старых save-файлах.

## 6. Стандарт отчёта Ornith

```text
Task ID / domain / base SHA:
Files read (with verified paths):
Files changed (vs allowlist):
FACTS (source path:lines or exact command output):
UNKNOWN (what could not be established and required evidence):
ASSUMPTIONS (must not be presented as facts):
COMMANDS EXECUTED (exact, exit code, decisive output):
NOT RUN (and why):
VALIDATION (diff --check, source/test checks and their actual status):
STOP / ESCALATION (if triggered):
HANDOFF (reviewer checks required; PR/CI only if they actually exist):
```

Hermes/reviewer обязан отдельно проверить фактическое выполнение заявленных команд и источники каждого содержательного вывода; **зелёный GitHub CI доказывает прохождение CI, но не подменяет семантическое ревью документа**.

## 7. Независимое ревью и стоимость

1. Сверить **весь** diff с allowlist; убедиться, что нет посторонних изменений в runtime, общем статусе или assets.
2. Для **каждой строки** содержательной таблицы открыть исходный тест и связанные fixtures/resources. Невыведенное из исходников утверждение исправить либо `UNKNOWN`.
3. Проверить, не перепутаны ли `READ_ONLY` и `EXECUTED_PASS`; вывод CI добавляется только после завершения на exact PR head.
4. Сверить `docs/changes/` и domain shard с фактическим состоянием PR; неполный родительский scope остаётся открытым.
5. Сохранять метрики пилота: поставленный prompt, разрешённые пути, попытки, эскалации, правки reviewer, время, wall-clock, tokens и денежную стоимость **только если реально измерены**. Иначе `UNKNOWN`.
6. Оценивать **полную цену задачи** = планирование + executor + повторения + review + CI + исправления. Если она превосходит прямое выполнение сильной моделью, маршрутизировать к сильной модели.

## 8. Наблюдения из реального пилота 5 ноября 2026

| Источник | Исполнитель | Что фактически подтверждено | Ограничения вывода |
|---|---|---|---|
| [#199](https://github.com/bezdredoff/RavenManor-Godot/pull/199), [evidence](../changes/CODE-02-01-hermes-codex-input.md) | Hermes → Codex runtime/model `gpt-5.6-sol` | Исправлен `InputEventScreenTouch.canceled` в `match3_board_presenter.gd`, добавлен regression к существующему viewport smoke; PR merged, exact-head CI PASS | Срез исправления, **не** полная mobile/visual QA CODE-02-01 |
| [#200](https://github.com/bezdredoff/RavenManor-Godot/pull/200), [evidence](../changes/VN-EDITOR-07-hermes-ornith-coverage.md) | Hermes → локальный LM Studio `ornith-1.5-9b` | Три source-reviewed сценария описаны в `PARITY_COVERAGE.md`; после сужения scope и исправлений оркестратором PR merged, exact-head CI PASS | **Assisted**, не autonomous Ornith success. Godot tests **не запускались** для статического inventory; full donor/old save/device QA UNKNOWN/not established |
| Qwen | Отдельного подтверждённого пилота нет | `UNKNOWN` | Не считать компетенции и стоимость в нашем репозитории измеренными |

По данным PR, ветки и файлы #199/#200 не пересекались, merge-tree проверка была успешной. **Число часов, tokens и фактическая финансовая экономия не измерены в публичных evidence → UNKNOWN.** Эти два кейса не дают статистически значимого сравнения моделей. Проблема Ornith в #200 заключалась прежде всего в непроверенных обобщениях и необходимости внешнего смыслового ревью, не в неспособности генерировать таблицы.

**Следующие эксперименты:** повторить 3–5 одинаковых узких процедур для Ornith и проверенного fallback на сопоставимой базе, измерить долю автономно принятых результатов, false claims, число исправлений, время и общую стоимость. Только после этого менять глобальные пороги маршрутизатора.
