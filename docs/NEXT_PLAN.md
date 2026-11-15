# Raven Manor — актуальный план и очередь задач

> **НОВЫЙ release-focused аудит 2026-11-15 после PR #265 (main 8f931c37, [CI PASS](https://github.com/bezdredoff/RavenManor-Godot/actions/runs/43762839236)):** открытых PR 0; #262–265 merged. Главный ограничитель финала Season 1 — 20/28 ещё неисполняемых сцен (0/28 проходит production VN dispatcher), QA-only first-floor geometry и отсутствие полного production hotspot/save/Continue пути. **[Release finish-line scope, пять параллельных потоков A–E и последовательные gates G0–G4](RELEASE_FINISH_PLAN_20261115_RU.md)** — proposed operational plan для owner approval; не меняет статусы и не утверждает арт/двери. Предыдущий блок ниже (baseline после #261 с открытыми #262/#263) исторический и не должен использоваться как текущая очередь.

> **Живое операционное обновление: 2026-11-15, main `f0d2264e` после #261.** Все разделы ниже после горизонтальной черты сохраняются как **исторический срез 2026-11-03/06**, а не инструкция начинать работу с нуля. Источник статуса задач — 15 `data/raven/production/progress/<domain>.json`; публичный [дашборд](https://bezdredoff.github.io/RavenManor-Godot/dashboard/) генерируется автоматически. Не править `dashboard/status.json` и frozen `production_progress.json`. Для каждого PR — уникальный `docs/changes/` и только собственный shard.

## Проверенный baseline, не смешивать технические срезы с production

| Evidence на main | Что реально есть | Что всё ещё не подтверждено |
| --- | --- | --- |
| [#251–255](https://github.com/bezdredoff/RavenManor-Godot/pull/255) | Godot Route Editor: room ownership, freehand, редактирование исходных WALKABLE/NO-GO и очистка черновых AI-ограничений | Утверждённая production-геометрия, коллизии/перекрытия, устройства |
| [#256–257](https://github.com/bezdredoff/RavenManor-Godot/pull/257) | Story POI контракт и отдельный визуальный **08B** черновик: 26 waypoints / 21 routes | Не все сюжетные объекты видимы; кандидаты не являются production |
| [#258](https://github.com/bezdredoff/RavenManor-Godot/pull/258) | Доказательная сверка **11** дверей, комната/сторона и увеличенные фрагменты изображения | Все 11 реальных порогов по-прежнему не утверждены |
| [#259](https://github.com/bezdredoff/RavenManor-Godot/pull/259) | Изолированный in-memory QA сценарий RM-HS-005 → RM-LVL-001 → RM-HS-002 / RM-REST-001 → RM-BEAT-01-02, реальная VN/Match-3 UI | Не подключён к production-карте/Continue и устройствам |
| [#260](https://github.com/bezdredoff/RavenManor-Godot/pull/260) | Версионированный `manor_navigation_source.gd`, явное QA opt-in, fail-closed production mode и hotspot harness | Не утверждены карты/комнаты/сохранённые позиции |
| [#261](https://github.com/bezdredoff/RavenManor-Godot/pull/261) | Отдельный **09B** архитектурный blueprint: 34 waypoints / 29 routes, четыре проектных HA/HC/CB/CK проёма с TEST_ONLY переходами без скачка XY | Нужны утверждение стен/подлестничного прохода HC, тамбура CK, масштаба/высоты/foreground и конечной графики |

Все указанные PR смержены, у каждого проверен успешный exact-head GitHub Actions. Main после #261 — `f0d2264e`; production-переходы и source switch **не включены**. Прохождение CI и ручное тестирование редактора не заменяют утверждение игровой архитектуры.

**Текущие открытые evidence-only PR:** [#262](https://github.com/bezdredoff/RavenManor-Godot/pull/262) обновляет `CODE-05-02` в **manor-map**, [#263](https://github.com/bezdredoff/RavenManor-Godot/pull/263) обновляет `GAME-LOOP-01` в **campaign-core**. На момент аудита оба открыты, имеют успешный CI на head; **не дублировать записи этих shard в другом PR**. После их мерджа повторно проверить dashboard и main CI. Этот план не предполагает автоматический merge.

## Новая очередь — сначала первая работающая игровая петля

| Очерёдность / приоритет | Владение задачами | Реальная следующая поставка и gate |
| --- | --- | --- |
| **0 — P0 / evidence** | `CODE-05-01`, `RM-GAP-001`, `CODE-05-02`, `GAME-LOOP-01` | Сверить #254–261 с live shards; merge owner-reviewed #262/#263 и status-reconciliation PR; dashboard regeneration/check. Не закрывать родительские P0 лишь потому, что тестовые срезы в main. |
| **1 — P0 / арт и карта** | `CODE-05-02`, `RM-GAP-001/006`, `GFX-08-01/02` | Owner review четырёх 09B проёмов: **HA Hall↔Archive**, **HC Hall↔Corridor** (под лестницей), **CB Corridor↔Bedroom** (без зависимости от ремонта ванной), **CK Corridor↔Kitchen** (тамбур). Для каждого: реальный рисунок стен/пола, near/far feet, высота, foreground masks, запирание, возврат. Неподтверждённые двери остаются недоступны. |
| **2 — P0 / общая интеграция** | `CODE-05-02` + `GAME-LOOP-01` (single integration owner) | Объединить `raven_hotspot_gameplay_bridge.gd` и `manor_navigation_source.gd` на едином graph/session/transition контракте. Сейчас bridge создаёт собственный тестовый graph/session; **не** переносить два источника в production. Добавить явный QA-vs-production source gate, arrival recheck, отмену, door lock, невалидный source. |
| **3 — P0 / переход в живую карту** | `CODE-05-03`, `CODE-11-01`, `CODE-07-02` | После шага 1/2 — маленький Hall→Corridor→Bedroom playable slice с real hotspot routing, корректными save/Continue/New Game, безопасным fallback позиции и использованием существующих VN/Match-3. Archive/Kitchen пока отсутствуют в save-каталоге: только явно одобренное расширение с миграцией, не silent add. |
| **4 — P0 / персонаж и экран** | `GFX-07-01/05`, `GFX-11-T09`, `GAME-QA-01` | Утвердить Evelyn chibi по VN-референсу, полный walker sprite atlas с обеими ногами/feet pivot; проверить scale, 65° карту, occlusion и мобильный portrait touch. Onoe остаётся QA placeholder до приёмки замены. |
| **5 — P1 / расширение сезона** | `GAME-LOOP-01`, `CODE-05-03` и соответствующие сюжетные/арт-пакеты | Только после стабильного вертикального среза: Library/Archive, Kitchen, часы/портреты, поздние сцены, garden/conservatory по отдельно утверждённым границам; не придумывать скрытые проходы на картинке. |

### Как выполнять параллельно без конфликтов

- **A — manor-map + environment-art:** review/калибровка 09B проёмов, изображение стен/пола, elevation/foreground. Пока нет owner решения — изолированные blueprint/draft changes, без production source switch.
- **B — campaign-core integration owner:** объединение двух уже смерженных адаптеров и restore/route/hotspot тесты; единолично владеет shared `vertical_slice`, reducer/store/save/API, согласовывает PR с A.
- **C — chibi-animation:** Evelyn sprite-sheet/анимации и проверка feet pivot в отдельном тестовом персонаже; не меняет сюжет/карты одновременно с A/B.
- **D — qa-infrastructure / ui-shell:** Windows/Android portrait QA и сохранение/Continue после сборки интеграции, переиспользуя UPDS UI и уже готовые smoke tests.

**Порядок merge:** сначала evidence-only (#262/#263), далее изолированный контракт bridge↔source (без смены production), затем approve/render дверных проёмов, затем явный opt-in production-путь с end-to-end save/Continue QA, потом chibi/device visual acceptance. Из-за зависимостей A и B могут разрабатываться параллельно, но production activation зависит от обоих.

### Критерий первого production-worthy vertical slice

1. В обычной игре (не только F6 QA) доступна одобренная комната и hotspot, движение Onoe/Evelyn идёт по **одной** авторитетной навигационной цепочке без свободного tap-to-move.
2. Утверждённый физический порог имеет поддерживаемые обе стороны, lock/unlock, правильное обратное прибытие, высоту/визуальное перекрытие и отсутствие скачка.
3. Hotspot recheck на прибытии запускает тот же VN/Match-3/reducer flow с RU/BE/EN; награда/реставрация начисляются ровно один раз.
4. Выход, Continue, отмена и corrupt/failed save восстанавливаются без потери/выдумывания anchor или второго authoritative store.
5. Проверены desktop и portrait/touch (не только headless). Только владелец может отметить art/geometry/device acceptance.

---

## Архив предыдущей очереди (2026-11-03—06, оставлен для контекста)

> **Операционное обновление 2026-11-06 (main `d9b3cacc`):** ниже сохранён срез планирования от 2026-11-03, включая исторические количества задач и решения QA. Он **не является источником текущих статусов**. Актуальные задачи/приоритеты/evidence и назначения workstream/P2 ведутся в 15 файлах [`data/raven/production/progress/<domain>.json`](../data/raven/production/progress/index.json), а [Production Dashboard](https://bezdredoff.github.io/RavenManor-Godot/dashboard/) агрегируется автоматически. `production_progress.json` заморожен. Разделение CI #192, status shards #193–196, agent runbooks #197 и Hermes policy #201 уже смержены. Игровые технические срезы #174–177 и #188–191 также смержены; это **не** подтверждение полного UPDS UI, игрового цикла или device QA. Начинать новую задачу с [AGENTS.md](../AGENTS.md) и [регламента 15 доменов](process/AGENT_ORCHESTRATION_RU.md); собственный shard + уникальный `docs/changes/` note вместо общей status-синхронизации.


> **2026-11-03 owner-approved planning reconciliation (proposed PR):** see [consistency audit](production/GAME_CONSISTENCY_AUDIT_RU.md), [feature coverage](production/GAME_FEATURE_COVERAGE_RU.md), [progression contract](production/GAME_PROGRESSION_CONTRACT_RU.md) and [UPDS reuse matrix](production/UPDS_REUSE_IMPLEMENTATION_MATRIX.md). The historical counts below are snapshots before this plan change; current authority is `data/raven/production/progress/<domain>.json` (15 shards); `production_progress.json` is frozen. No runtime/asset changes in this PR.

**New foundation packages:** GAME-UI-01, GAME-M3-01, GAME-LOOP-01, GAME-QA-01; P1 GAME-ONBOARD-01, GAME-BOOST-01, GAME-JOURNAL-01; deferred GAME-ENDING-01, GAME-RELEASE-01. Two new workstreams WS-GAME-SHELL and WS-CAMPAIGN. Existing CODE tasks remain separate; no task accepted by priority change.
**Срез:** 2026-11-03, `main` после смерженного PR #153 и owner-отчёта о пройденной QA.  
**Режим работы на 2026-11-03 (историческая запись):** очередь поддерживалась через 10 рабочих потоков; на тот момент новая генерация арта и разработка ожидали отдельного решения владельца. Для текущей очереди сверяйте live dashboard и последние owner-решения.

> Этот файл — текущая точка входа. Предыдущий длинный Hall/Room Builder `NEXT_PLAN` сохранён в [архиве](audits/NEXT_PLAN_HALL_PIPELINE_ARCHIVE_20261025.md). Текущий статус/owner evidence живёт в [`progress/<domain>.json`](../data/raven/production/progress/index.json) (см. индекс 15 shards), а не в замороженном `production_progress.json` или исторических описаниях `code_work_packages.json`. Отчёт о сверке: [BACKLOG_RECONCILIATION_20261103.md](audits/BACKLOG_RECONCILIATION_20261103.md).

## Обновление очереди 2026-11-03 · CODE/GAP P0 и зависимости

После GFX-сверки (#149) и source/status-cleanup (#150) обнаружены **88 исторических CODE/GAP P0**, из них **58** уже закрытых/заменённых пакетов либо иных архивных элементов и **24** неэкстренных задач. Приоритеты конкретных tasks теперь переопределяются в соответствующем `progress/<domain>.json` и проверяются CI; кодовые и процессные планы остаются документальным baseline.

**Шесть CODE/GAP P0:** `CODE-02-06` (touch/hint/help Match-3), `CODE-05-01/02` (Hall importer/path/collision), `CODE-11-01` (joint vertical slice), `RM-GAP-001/006` (те же Hall physical gates, не отдельная параллельная разработка). Вкупе с **семью GFX P0** текущая очередь содержит **13 P0 всего**. Это не 13 независимых PR — один Hall QA может покрывать несколько ID.

Граф зависимостей очищен от двух циклов `VNS5-09 ↔ VNS5-11/12`; в дашборде показываются отдельно **активные блокеры** и **исторические связи плана**. Подробная сверка и матрица широких issues: [CODE_GAP_P0_RECONCILIATION_20261103.md](audits/CODE_GAP_P0_RECONCILIATION_20261103.md). Пакеты QA B–D ниже остаются самым недорогим шагом после очистки. Новую разработку/арт не начинать на основании одной переоценки P0.

## Актуализация P1: 10 рабочих потоков вместо десятков параллельных списков

После #151 выполнена следующая сверка: **13 активных P0, 65 активных P1 и 44 открытых P2**. Из прежних 91 P1 **26 перенесены в P2 без изменения статуса** (future season waves, необязательные keyframe/storyboard workflows, chibi Rowan/Lucas без нужной сцены, всеобъемлющие room/material libraries, второстепенные props и effects polish). Все **78 P0/P1 на дату среза** были распределены по **10 общим потокам**; теперь членство вычисляется из live shard assignments, а [`active_workstreams.json`](../data/raven/production/active_workstreams.json) содержит только правила потоков; в дашборде можно фильтровать по потоку. [Подробная сверка и критерии](audits/P1_WORKSTREAMS_SCOPE_20261103.md).

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
2. Работа в одном релевантном task ID: обновить только свой `data/raven/production/progress/<domain>.json` и уникальный `docs/changes/<TASK-ID>-topic.md`; для общей схемы/канонического runtime — отдельный integration PR. Проверить `progress_shards.py`, `build_production_dashboard.py --check` и обязательные CI jobs. Не синхронизировать historical GAP status с live shard и не редактировать замороженный `production_progress.json`.
3. Любая статичная графика остаётся `art_approved` только для точных ранее утверждённых файлов. Новые keyframes, chibi, UV/pivots, физические состояния и мобильная приёмка — другие gates.
4. Сохраняем ID/route/save contracts, отдельно проверяем RU/BE/EN, не меняем игровые сцены ради косметического статуса.
5. Не редактировать generated `dashboard/status.json` вручную: он строится из code/gap/GFX и authoritative progress.
6. Не закрывать широкие issues [#2](https://github.com/bezdredoff/RavenManor-Godot/issues/2), [#3](https://github.com/bezdredoff/RavenManor-Godot/issues/3), [#21](https://github.com/bezdredoff/RavenManor-Godot/issues/21), [#121](https://github.com/bezdredoff/RavenManor-Godot/issues/121), [#129](https://github.com/bezdredoff/RavenManor-Godot/issues/129) до проверки **всех** соответствующих критериев.

**Текущий результат работы — не новый артовый asset и не новая механика, а чистый, воспроизводимый и недвусмысленный backlog.**
