# Raven Manor — актуальный план и очередь задач

> **2026-11-03 owner-approved planning reconciliation (proposed PR):** see [consistency audit](production/GAME_CONSISTENCY_AUDIT_RU.md), [feature coverage](production/GAME_FEATURE_COVERAGE_RU.md), [progression contract](production/GAME_PROGRESSION_CONTRACT_RU.md) and [UPDS reuse matrix](production/UPDS_REUSE_IMPLEMENTATION_MATRIX.md). The historical counts below are snapshots before this plan change; current authority is `production_progress.json`. No runtime/asset changes in this PR.

**New foundation packages:** GAME-UI-01, GAME-M3-01, GAME-LOOP-01, GAME-QA-01; P1 GAME-ONBOARD-01, GAME-BOOST-01, GAME-JOURNAL-01; deferred GAME-ENDING-01, GAME-RELEASE-01. Two new workstreams WS-GAME-SHELL and WS-CAMPAIGN. Existing CODE tasks remain separate; no task accepted by priority change.
**Срез:** 2026-11-03, `main` после смерженного PR #153 и owner-отчёта о пройденной QA.  
**Режим работы сейчас:** очередь поддерживается через 10 проверяемых рабочих потоков и независимые ID; пока готовим QA batches и актуализируем планы, **не начинаем новую генерацию арта или игровую разработку без следующего решения владельца**.

> Этот файл — текущая точка входа. Предыдущий длинный Hall/Room Builder `NEXT_PLAN` сохранён в [архиве](audits/NEXT_PLAN_HALL_PIPELINE_ARCHIVE_20261025.md). Текущий статус/owner evidence живёт в [`production_progress.json`](../data/raven/production/production_progress.json), а не в исторических описаниях `code_work_packages.json`. Отчёт о сверке: [BACKLOG_RECONCILIATION_20261103.md](audits/BACKLOG_RECONCILIATION_20261103.md).

## Обновление очереди 2026-11-03 · CODE/GAP P0 и зависимости

После GFX-сверки (#149) и source/status-cleanup (#150) обнаружены **88 исторических CODE/GAP P0**, из них **58** уже закрытых/заменённых пакетов либо иных архивных элементов и **24** неэкстренных задач. Приоритеты конкретных tasks теперь переопределяются в `production_progress.json` и проверяются CI; кодовые и процессные планы остаются документальным baseline.

**Шесть CODE/GAP P0:** `CODE-02-06` (touch/hint/help Match-3), `CODE-05-01/02` (Hall importer/path/collision), `CODE-11-01` (joint vertical slice), `RM-GAP-001/006` (те же Hall physical gates, не отдельная параллельная разработка). Вкупе с **семью GFX P0** текущая очередь содержит **13 P0 всего**. Это не 13 независимых PR — один Hall QA может покрывать несколько ID.

Граф зависимостей очищен от двух циклов `VNS5-09 ↔ VNS5-11/12`; в дашборде показываются отдельно **активные блокеры** и **исторические связи плана**. Подробная сверка и матрица широких issues: [CODE_GAP_P0_RECONCILIATION_20261103.md](audits/CODE_GAP_P0_RECONCILIATION_20261103.md). Пакеты QA B–D ниже остаются самым недорогим шагом после очистки. Новую разработку/арт не начинать на основании одной переоценки P0.

## Актуализация P1: 10 рабочих потоков вместо десятков параллельных списков

После #151 выполнена следующая сверка: **13 активных P0, 65 активных P1 и 44 открытых P2**. Из прежних 91 P1 **26 перенесены в P2 без изменения статуса** (future season waves, необязательные keyframe/storyboard workflows, chibi Rowan/Lucas без нужной сцены, всеобъемлющие room/material libraries, второстепенные props и effects polish). Все **78 текущих P0/P1** распределены по **10 общим потокам** в [`active_workstreams.json`](../data/raven/production/active_workstreams.json); в дашборде можно фильтровать по потоку. [Подробная сверка и критерии](audits/P1_WORKSTREAMS_SCOPE_20261103.md).

Вместо отдельных параллельных приёмок одних и тех же экранов начинаем с трёх групп **QA-first**: `WS-VN-STUDIO` (оригинальный HTML-v5 и сохранение/FX), `WS-LOCALES` (RU/EN/BE whole-UI), `WS-MOBILE-HANDOFF` (ZIP incoming/device). `WS-DEVICE` перекрывает hardware matrices других групп и должен переиспользовать скриншоты/метрики, не создавать второй тест для каждой задачи.

## Четыре группы P2 и матрица приёмки для 10 потоков

После #152 все **44 открытые P2** имеют отдельное правило возврата: **16** future season/content, **14** условных pipeline/keyframe задач, **2** явно deferred и **12** обязательных проверок *полного* сезона. Последние не отменены, а только отложены до его release-candidate. Данные: [`p2_reentry_policy.json`](../data/raven/production/p2_reentry_policy.json). Ни одна из 44 задач не стала автоматически `accepted` или `superseded`.

Практический план: [**матрица приёмки для десяти потоков**](production/CURRENT_RELEASE_ACCEPTANCE_MATRIX_RU.md). Там для каждого потока есть существующие автопроверки, конкретные действия владельца в Godot/на телефоне, новая разработка только при необходимости и критерий закрытия. Дашборд показывает обе группы как сворачиваемые QA/P2 разделы. Первыми выполняются короткие партии **VN Studio → RU/EN/BE → phone ZIP**, затем повторно используем скриншоты для device baseline. **Не заявлять ручную приёмку до получения screenshots и решения владельца.**

## Результат ручной QA 2026-11-03 — закрываем только подтверждённый scope

Владелец сообщил, что ранее запрошенные проверки завершены успешно. **Пять scoped задач приняты:** `VNS5-09` (текущий workflow editor, ранее merged), `LOC-EN-QA`, `LOC-BE-QA`, `RM-GAP-013`, `PROC-003` (secure phone ZIP). **13 P0 неизменны; 61 P1 и 44 открытые P2**. Два оставшихся narrow QA gates — финальная Hall geometry of 3-locale VN text `GFX-11-T08` и полный phone ZIP adversarial/post-merge `MOB-04`.

Положительная оценка UI зафиксирована для остальных проверенных областей, но отсутствие приложенных точных скриншотов/устройств не позволяет из этого сообщения закрыть `VNS5-07F2` HTML-v5 pixel-parity, `RM-GAP-010` full device matrix или `GFX-11-T09` complete Hall mobile pilot. Никакие новые chibi, physical Hall map и Match-3 artifacts не созданы. Основание/границы: [`OWNER_QA_ACCEPTANCE_20261103_RU.md`](production/OWNER_QA_ACCEPTANCE_20261103_RU.md).

## 1. Что уже получено и не подлежит повторному заказу

- **62/62 художественно утверждённых VN-изображения** Эвелин, Ады, Лукаса и Роуэна, включая разные позы/эмоции и готовые композиты с предметами в руках (`GFX-06-02/03`). Это не чиби/спрайты карты и не полнота любой произвольной pose×emotion комбинации.
- **26/26 утверждённых VN-фонов**, покрывающих точными состояниями **28/28** исходных сюжетных сцен (`GFX-08-05`). `BG-CORRIDOR` без отдельной VN-сцены не заказывать. Исходные методы полного prompt replay и lighting overlays `GFX-08-06/07` заменены — не считать их изначально выполненными.
- Raven VN Studio: уже смержены создание сцен, narrator-only текст, авто-размещение утверждённых портретов, редактирование трёх языков, draft Story Map A/B/C и preview FX, восстановление черновиков, технический **save/reopen/review export** (`#142–147`). `VNS5-09` теперь **merged**, но весь нативный UX **не принят**.
- `#148` и `#149` смержены: 26/26 файлов проверяются по SHA; старые общие P0 GFX-процессы переведены в актуальные статусы. **7 оставшихся GFX P0** — это именно чиби/map и Hall mobile QA, не оценка готовности всей игры.

## 2. Текущая очередь — скоуп и gate, без обещания выполнения

| Порядок | Рабочий пакет | Следующий *действительно необходимый* результат | Что не утверждать преждевременно |
|---|---|---|---|
| **A · уже выполнено** | **Очистка backlog**: PR #150/#151 + P1 scope | Статусы и DAG reconciled; 10 потоков объединяют независимые task IDs и QA-gates без ложного `accepted` | Исторический CODE plan сохранён; QA всё ещё требуется |
| **B · частично принято** | **VN Studio**: `VNS5-09` owner-accepted, `VNS5-07F/07F2` открыты | Authoring/save/reopen/FX/branch QA подтверждены; осталось приложить сопоставленные HTML-v5 ↔ Godot скриншоты/control diff для формального parity | Отдельный каталог VN props не требуется; playable branch не обещан |
| **C · принято** | **Локализация**: `RM-GAP-013`, `LOC-EN-QA`, `LOC-BE-QA` | Owner подтвердил RU/EN/BE; для `GFX-11-T08` всё ещё нужен финальный Hall viewport screenshot gate | Не нужен повторный перевод готовых каталогов |
| **D · частично принято** | **Мобильный handoff**: `PROC-003` owner-accepted, `MOB-04` остаётся | Базовый secure ZIP flow подтверждён; полная attack matrix, post-merge stable и preview-origin gate отдельно | Linux CI и один ZIP не заменяют полный security/device review |
| **E · последующая разработка** | **Match-3**: `CODE-02-06` (и связанные `CODE-02-01/05`) | Реальные swipe/touch, подсказка на две клетки, модальное Help и mobile visual parity с UPDS | Нельзя закрыть одной проверкой рендерера |
| **F · последующая разработка/QA** | **Карта/Hall**: `CODE-05-01/02`, `RM-GAP-001/006`, `GFX-08-01/02` | Сверить Room Builder geometry, реальные проходы/двери/коллизии и approved art на 65° карте; по `GFX-08-02` нужен выбор конструктивного подхода | Нельзя считать VN-фон готовой картой |
| **G · новые ассеты, не сейчас** | **Chibi**: `GFX-07-01/05/06/09/10`, `GFX-11-T06` | Один короткий comparative spike Эвелин → утверждённые чиби walker Эвелин/Ада → foot/pivot/occlusion QA | Пока вместо Raven chibi — технический Onoe |
| **H · совместная приёмка** | **Hall/mobile**: `GFX-11-T09`, `CODE-11-01`, `RM-VS-01` | Реальный portrait/tablet UI, сохранение/восстановление, reduced motion, маршруты и полная последовательность VN→Match-3→map | Нельзя выводить device approval из headless smoke |

Пакеты B–D — самые дешёвые следующие проверки и не требуют нового игрового контента. Пакеты E–H начинают выполнять **только после отдельного решения** о возврате к разработке.

## 3. Явно отложено, архивировано или оставлено отдельно

| Решение | Задачи и границы |
|---|---|
| **Отложено** | `VNS5-08` — отдельный каталог пропсов в VN; предметы в руках уже находятся внутри изображений персонажей. Отдельные **map** props, `GFX-06-06/GFX-09`, не отменяются |
| **Не заказывать без сцены** | Несуществующие `BG-CORRIDOR`, `BG-BEDROOM:day:covered` и аналогичные дополнительные VN-state изображения |
| **Исторические методы заменены** | Старые VNCCS / model / style bake-offs `GFX-01–05`, а также `GFX-08-06/07`, закрытые как `superseded`, а не `accepted` |
| **Открыты, но не P0 создания VN-арта** | Полные keyframe-анимации `GFX-06-04/05/08`, карта Lucas/Rowan, Match-3 визуальные состояния `GFX-10`, физические map props, asset import/device QA |
| **Отдельная game-runtime работа** | `VN-RUNTIME-01`: включение **только явно утверждённых** draft веток в реальный сюжет; QA фикстуры не промоутятся автоматически |
| **Исторические плановые статусы** | `code_work_packages.json`: исходный `PROPOSAL_NOT_RUNTIME` + зависимость/интеграционные требования. `gap_work_packages.json`: согласованный snapshot задач; фактическое состояние определяет progress |

## 4. Порядок принятия решений и правила для следующего PR

1. Сначала фиксируем факты: merged PR / CI / approved art / нативное QA. **Ничего не закрывать только по наличию файла или зелёному тесту**.
2. Работа в одном релевантном task ID: включить `docs/STATUS.md`, `production_progress.json` и, если ID есть в discovery gap-реестре, согласовать его `status`. `reconcile_gap_statuses.py --check` проверяется Linux и Windows CI.
3. Любая статичная графика остаётся `art_approved` только для точных ранее утверждённых файлов. Новые keyframes, chibi, UV/pivots, физические состояния и мобильная приёмка — другие gates.
4. Сохраняем ID/route/save contracts, отдельно проверяем RU/BE/EN, не меняем игровые сцены ради косметического статуса.
5. Не редактировать generated `dashboard/status.json` вручную: он строится из code/gap/GFX и authoritative progress.
6. Не закрывать широкие issues [#2](https://github.com/bezdredoff/RavenManor-Godot/issues/2), [#3](https://github.com/bezdredoff/RavenManor-Godot/issues/3), [#21](https://github.com/bezdredoff/RavenManor-Godot/issues/21), [#121](https://github.com/bezdredoff/RavenManor-Godot/issues/121), [#129](https://github.com/bezdredoff/RavenManor-Godot/issues/129) до проверки **всех** соответствующих критериев.

**Текущий результат работы — не новый артовый asset и не новая механика, а чистый, воспроизводимый и недвусмысленный backlog.**
