# Raven Manor — матрица приёмки текущей версии и возврат P2

> **Обновление owner QA 2026-11-03:** владелец сообщил, что проверки выполнены успешно. Scope задач `VNS5-09`, `LOC-EN-QA`, `LOC-BE-QA`, `RM-GAP-013`, `PROC-003` принят в реестр как `accepted`. Остались `GFX-11-T08` (Hall final locale geometry), `MOB-04` (phone security/full matrix) и `VNS5-07F/F2` (оригинальный HTML screenshot parity), для которых нужны отдельные артефакты или точный контроль scope. **Эта страница — исходный план**, а актуальное решение и ограничения — [`OWNER_QA_ACCEPTANCE_20261103_RU.md`](OWNER_QA_ACCEPTANCE_20261103_RU.md). Повторять пройденные шаги не требуется.

**Дата:** 2026-11-03. **Статус:** подготовленный QA-план, **не** результаты ручного тестирования. После мержа #152 исходные 238 задачи распределены: **13 P0**, **65 P1**, **44 открытых P2**. Критический текущий срез — Hall + VN + Match-3 + map, а **не** весь сезон.

> Канонические источники: [активные потоки](../../data/raven/production/active_workstreams.json), [условия возврата P2](../../data/raven/production/p2_reentry_policy.json), [актуальная очередь](../NEXT_PLAN.md) и `production_progress.json`. Мерж, smoke и утверждение художественного изображения — разные gates. Ни один чеклист здесь **не считается пройденным без отдельного evidence**.

## 1. Краткий порядок: что проверять раньше

1. **QA Batch A — VN Studio** (`WS-VN-STUDIO`): один draft сценарий, RU/EN/BE, narrator, 1–3 героя, FX, branch demo, Save → restart Godot → reopen, визуальное сравнение оригинального HTML v5 на тех же viewport. Результат: 1 скриншот по каждому viewport + checklist/расхождения, без изменения канонического сюжета.
2. **QA Batch B — локализации** (`WS-LOCALES`): одинаковая сцена/меню/popups в RU/EN/BE, типографика, переносы, fallback, редактура. Результат: матрица «строка → локаль → устройство → дефект». Не повторять перевод 280 реплик.
3. **QA Batch C — мобильный ZIP** (`WS-MOBILE-HANDOFF`): один валидный небольшой incoming ZIP и один намеренно невалидный архив, подтверждение candidate PR, безопасности и auto-cleanup; user-approved merge остаётся вручную.
4. **QA Batch D — device baseline** (`WS-DEVICE`): повторно использовать screenshots A–C; добавить 390×844, 412×915, 430×932 и tablet, reduced-motion/offline/resume. Устройство и его результаты указываются явно.
5. Только после Batches A–D выбирать разработку **Match-3, Hall/map, chibi, map props и Story Runtime**. Новые изображения не создаются для устранения недостатков таблиц/архивов.

## 2. Матрица всех 10 потоков

### 1. VN Studio, композиция и редактирование — `WS-VN-STUDIO`

**Граница задачи:** Один native Godot walkthrough: восстановить draft после рестарта, 1–3 accepted composites, narrator, Story Map/FX, UX comparison с original HTML-v5; 28 approved scene backplates и cast fallback проверять на реальном viewport

**Автоматические проверки — уже существующие, но не доказательство живого UI:**

- tests/raven/vn_studio_full_authoring_e2e_smoke.gd — draft save/reopen + RU/BE/EN + review export
- tests/raven/vn_studio_branch_demo_smoke.gd — editor-only branch and FX fixture
- tests/raven/vn_studio_layout_smoke.gd — layout structural smoke

**Проверка владельцем в Godot/на устройстве:**

- В Godot 4.7.2: создать сцену, поставить 1/2/3 утверждённых героев и narrator-only реплику, переставить строки, сохранить/перезапустить/открыть
- Сравнить реально утверждённый HTML-v5 и Godot при 1024×640, 1366×768 и большом desktop viewport; проверить колонки, высоту, scroll, превью

**Новый код или арт только при обнаруженном пробеле:**

- Исправить обнаруженные несовпадения UX/перетаскивания/анимаций и fallback; не создавать самостоятельную библиотеку VN props

**Условие закрытия:** Owner accepts native editor authoring and visual differences explicitly; technical smoke alone never closes #121/#129

**Связанные task IDs:** `CODE-03-01`, `CODE-03-02`, `CODE-03-03`, `VN-EDITOR-07`, `VN-EDITOR-08`, `VNS5-07F`, `VNS5-07F2`, `VN-CAST-MATRIX`, `VN-BG-DEVICE-QA`, `GFX-03-05`, `GFX-05-08`, `GFX-06-08`.

### 2. RU/EN/BE — полный QA интерфейса — `WS-LOCALES`

**Граница задачи:** Один tri-locale proofreading/font/overflow/device matrix; подтвердить всю UI-копию без повтора уже готового перевода 280 строк и 28 scene titles

**Автоматические проверки — уже существующие, но не доказательство живого UI:**

- scripts/raven/tools/validate_production_narrative.py --release — наличие RU/BE/EN у реплик/заголовков/popups
- tests/raven/vn_english_localization_smoke.gd и vn_belarusian_localization_smoke.gd — сохранение/разрешение переводов

**Проверка владельцем в Godot/на устройстве:**

- Пройти одинаковые сцены на RU, EN, BE: переносы, UI-подписи, авторский текст, меню, popup и типографику
- Редакторская сверка звучания реплик и отсутствия fallback там, где требуется локализованный UI

**Новый код или арт только при обнаруженном пробеле:**

- Только исправления конкретных пропущенных UI-строк/шрифтов/переносов; 280 реплик и 28 заголовков не переводить заново

**Условие закрытия:** Owner signs off separate EN and BE editorial + complete native UI layout gates

**Связанные task IDs:** `RM-GAP-013`, `LOC-EN-QA`, `LOC-BE-QA`, `GFX-11-T08`.

### 3. Мобильность и accessibility — `WS-DEVICE`

**Граница задачи:** Один набор portrait/tablet/PWA device checks: tap targets, safe zones, reduced motion, resume, Room Builder stylus and Web/offline; evidence linked to each original task

**Автоматические проверки — уже существующие, но не доказательство живого UI:**

- tests/raven/upds_match3_mobile_hud_smoke.gd — safe area/HUD limits
- tests/raven/vn_studio_layout_smoke.gd и vertical_slice_smoke.gd — структурные smoke

**Проверка владельцем в Godot/на устройстве:**

- На 390×844, 412×915, 430×932 и планшете снять evidence: ориентация, safe area, touch targets, no clipping, motion reduction
- Проверить PWA offline/resume и взаимодействие с Room Builder на реальном устройстве/стилусе, где применимо

**Новый код или арт только при обнаруженном пробеле:**

- Только реальные viewport, accessibility, pointer/stylus и offline regression fixes

**Условие закрытия:** Physical-device evidence; не заменять его эмулятором или headless screenshot

**Связанные task IDs:** `CODE-04-01`, `CODE-10-01`, `CODE-10-02`, `RM-GAP-002`, `RM-GAP-010`, `GFX-00-08`, `GFX-06-09`, `GFX-11-T09`.

### 4. Incoming ZIP и безопасная мобильная передача — `WS-MOBILE-HANDOFF`

**Граница задачи:** Один phone ZIP→incoming→candidate PR happy/error path с cleanup success/failure, adversarial archive and manual merge control

**Автоматические проверки — уже существующие, но не доказательство живого UI:**

- scripts/raven/tools/validate_mobile_patch.py и test_production_dashboard_mobile.py — archive manifest/adversarial preflight
- GitHub Actions candidate pipeline — CI-проверка импортируемого ZIP и независимого PR

**Проверка владельцем в Godot/на устройстве:**

- С телефона загрузить небольшой валидный ZIP в incoming; подтвердить candidate PR и удаление ZIP после успеха
- Негативный тест неверного ZIP/manifest: rejection, отсутствие потери данных, cleanup, отсутствие auto-merge

**Новый код или арт только при обнаруженном пробеле:**

- Правка только подтверждённого дефекта ZIP validation, cleanup или permissions; не менять game scenes

**Условие закрытия:** One phone happy path and one intentionally rejected archive proved safe

**Связанные task IDs:** `PROC-003`, `MOB-04`.

### 5. Match-3 — реальный input и графика — `WS-MATCH3`

**Граница задачи:** Проверить/исправить browser/phone swipe, hint 2 cells, modal Help, shape/blockers/specials, восемь визуально различимых tiles и mobile UI parity с UPDS

**Автоматические проверки — уже существующие, но не доказательство живого UI:**

- tests/raven/upds_match3_interactive_board_smoke.gd и upds_match3_presentation_states_smoke.gd — board/help/blocker состояния
- tests/raven/upds_match3_mobile_hud_smoke.gd и content_preview_match3_qa_smoke.gd — UI/QA shortcut

**Проверка владельцем в Godot/на устройстве:**

- Реальные swipe/touch на телефоне и pointer на desktop, один валидный и один невалидный ход
- Hint показывает обе клетки, Help открывается как modal, а не spoiler; 8 tile types и blockers различимы на малом экране

**Новый код или арт только при обнаруженном пробеле:**

- Исправления input, hint, modal Help, tile/blocker visuals с UPDS parity; headless smoke не гарантирует UI

**Условие закрытия:** Owner passes actual Match-3 input and visual parity before CODE-02-06 closure

**Связанные task IDs:** `CODE-01-02`, `CODE-02-01`, `CODE-02-03`, `CODE-02-05`, `CODE-02-06`, `RM-GAP-012`, `GFX-10-01`, `GFX-10-02`, `GFX-10-03`, `GFX-10-04`, `GFX-10-05`, `GFX-10-07`.

### 6. Hall/Room Builder — единая физическая карта — `WS-HALL`

**Граница задачи:** Одна проверка Room Builder→Godot geometry 65°, doors/stairs/footprints, collisions, authored A* routes and foreground occlusion; Hall/Corridor/Bedroom chain без переизобретения VN painting

**Автоматические проверки — уже существующие, но не доказательство живого UI:**

- scripts/raven/tools/build_original_hall_layout.py --check + import_room_builder_game.py — детерминированный Hall draft/preview
- tests/raven/manor_navigation_graph_smoke.gd и season1_map_smoke.gd — authored graph/scene smoke

**Проверка владельцем в Godot/на устройстве:**

- В 65° map viewport проверить лестницу C, двустворчатые двери под площадкой, дверь библиотеки, clock, кресла/стол и коридор
- Пройти authored Hall→Corridor→Bedroom, открыть двери, проверить независимость Bedroom от Bathroom, collisions, occlusion и pivots

**Новый код или арт только при обнаруженном пробеле:**

- Переупорядочить архитектуру Hall, Room Builder projection, map-ready physical pieces и collision/navigation только по утверждённому дефекту

**Условие закрытия:** Single owner Hall geometry/route gate covers CODE-05-01/02 and RM-GAP-001/006; VN background ≠ playable map

**Связанные task IDs:** `CODE-05-01`, `CODE-05-02`, `CODE-05-03`, `RM-GAP-001`, `RM-GAP-006`, `GFX-08-01`, `GFX-08-02`, `GFX-08-08`, `GFX-08-09`, `GFX-08-10`.

### 7. Chibi-герои — карты и позиционирование — `WS-CHIBI`

**Граница задачи:** Один короткий pilot Эвелин по approved VN refs; затем Эвелин/Ада walker & stage, foot pivots, 65° camera bounds, actor interaction and route/device test

**Автоматические проверки — уже существующие, но не доказательство живого UI:**

- Текущий CI обеспечивает контракт и визуальную загрузку VN-портретов; утверждённой серии map-chibi для теста пока нет

**Проверка владельцем в Godot/на устройстве:**

- После небольшого пилота выбрать Эвелин по approved full-body VN ref: identity, фронт/профиль/спина, 65° camera readability
- На Hall-карте проверить Эвелин/Аду idle/walk/footpoints, scale, occlusion и взаимодействие; технический Onoe не принимать как результат

**Новый код или арт только при обнаруженном пробеле:**

- Создать и утвердить новые chibi sprites Evelyn/Ada, затем импортер/анимации, без повторной генерации всех VN portraits

**Условие закрытия:** No task completed until original Raven map chibi art and real movement are approved

**Связанные task IDs:** `CODE-06-01`, `RM-GAP-011`, `GFX-03-06`, `GFX-07-01`, `GFX-07-04`, `GFX-07-05`, `GFX-07-06`, `GFX-07-09`, `GFX-07-10`, `GFX-11-T06`.

### 8. Карта, физические пропсы и реставрация — `WS-MAP-PROPS`

**Граница задачи:** Одна Hall-first map/interactable/state contract: письмо, чай, двери, часы, журналы; logical prop ID reused across surfaces but no standalone VN prop editor

**Автоматические проверки — уже существующие, но не доказательство живого UI:**

- scripts/raven/tools/validate_production_narrative.py — registry IDs/scene prop references; не подтверждает map states

**Проверка владельцем в Godot/на устройстве:**

- Hall-first inspect/repair: письмо, чай, дверь, часы/предметы; связность logical ID map/VN/insert и видимые состояния
- Проверить collision/footprints, interactions, spoiler safety и независимость от отложенного VNS5-08

**Новый код или арт только при обнаруженном пробеле:**

- Новые map prop assets/state variants и restoration interactions по реально используемой сцене, не самостоятельный prop editor VN

**Условие закрытия:** Physical map interactions and state visuals require owner review before individual prop tasks accepted

**Связанные task IDs:** `CODE-07-01`, `CODE-07-02`, `GFX-06-06`, `GFX-09-01`, `GFX-09-02`, `GFX-09-05`, `GFX-09-06`, `GFX-11-T04`, `GFX-11-T07`.

### 9. Импорт арта и технические контракты — `WS-ASSET-CONTRACT`

**Граница задачи:** Один cross-domain asset/ID/path/sha/alpha/pivot manifest audit for actual map/chibi/M3 assets; 26 backgrounds and 62 VN frames already accepted, not re-generated

**Автоматические проверки — уже существующие, но не доказательство живого UI:**

- tests/raven/vn_background_gallery_smoke.gd — 26 exact WebP hashes and 28 scene background tuples
- tests/raven/vn_character_art_smoke.gd — accepted VN portrait integration
- scripts/raven/tools/build_production_dashboard.py --check — task IDs and approved art counts

**Проверка владельцем в Godot/на устройстве:**

- Для новых map/chibi/M3 ассетов проверить actual alpha, pivot, sprite bounds, compression, category and provenance
- Подтвердить корректные лицензии/кредиты и честно перечислить потерянные original ChatGPT prompts/seeds; не заявлять pixel-locked overlays

**Новый код или арт только при обнаруженном пробеле:**

- Только конкретные недостающие map/chibi/M3 import contracts; не пересоздавать 26 approved VN plates и 62 cast frames

**Условие закрытия:** Signed manifest/import evidence without conflating immutable binary provenance and full prompt replay

**Связанные task IDs:** `CODE-09-01`, `CODE-09-02`, `GFX-00-01`, `GFX-00-02`, `GFX-00-03`, `GFX-00-05`, `GFX-03-07`, `GFX-05-11`.

### 10. Сюжет и Hall вертикальный срез — `WS-STORY-RUNTIME`

**Граница задачи:** Единый reviewed-only release gate for original routes/saves and tri-locale VN→Match3→map, explicit authored branching only after approval and save migration

**Автоматические проверки — уже существующие, но не доказательство живого UI:**

- tests/raven/vertical_slice_smoke.gd — structural slice assertions
- tests/raven/vn_production_runtime_dispatch_smoke.gd — canonical-only dispatch/locale/art checks
- tests/raven/vn_release_save_rehearsal_smoke.gd — save and rollback projection

**Проверка владельцем в Godot/на устройстве:**

- На реальном клиенте пройти VN→Match-3→map, выбор порядка доступных ремонтов и сохранение/возобновление
- Убедиться, что demo Story Map A/B/C остаётся draft-only, пока не утверждены ветки; проверять RU/BE/EN и отсутствие преждевременных spoilers

**Новый код или арт только при обнаруженном пробеле:**

- Только reviewed-only branching promotion / gameplay integration, saves and exact route fixes; не продвигать QA fixture в канон автоматически

**Условие закрытия:** Owner approves playable slice and safe migration/rollback; technical smoke ≠ finished Season 1

**Связанные task IDs:** `CODE-11-01`, `RM-GAP-008`, `VN-RUNTIME-01`.

## 3. P2 — не один «архив», а четыре правила возврата

P2 содержит **44 открытые задачи**, которые после мержа #152 сознательно не обозначены как P0/P1. Переключение приоритета не отменяет исходное требование. Полный список ID хранится в `p2_reentry_policy.json`.

### Контент и функциональность последующих глав — `P2-SEASON-CONTENT` (16)

**Когда возвращать в работу:** Включить в авторскую карту конкретную сцену/главу, подтвердить интерактив и необходимого персонажа либо изменение игровой экономики; только затем повышать приоритет.

**Решение:** Plan after vertical-slice gate, no production now.

**Задачи:** `CODE-06-02`, `CODE-07-03`, `CODE-08-01`, `CODE-12-W1`, `CODE-12-W2`, `CODE-12-W3`, `CODE-12-W4`, `CODE-12-W5`, `RM-GAP-007`, `GFX-07-07`, `GFX-07-08`, `GFX-08-03`, `GFX-08-04`, `GFX-09-03`, `GFX-09-04`, `GFX-10-08`.

### Условные способы генерации, анимации и полировки — `P2-CONDITIONAL-PIPELINE` (14)

**Когда возвращать в работу:** Появилась конкретная утверждённая сцена или повторяемый артовый дефект, который не устраняется существующими VN composites, простыми editor FX или узким чиби-пилотом.

**Решение:** Require one scoped experiment with measurable before/after, no blanket rerun of VNCCS/model bake-offs.

**Задачи:** `CODE-04-02`, `RM-GAP-005`, `ART-BATCH-AUTOMATION`, `ART-PROVENANCE-QA`, `GFX-05-03`, `GFX-06-01`, `GFX-06-04`, `GFX-06-05`, `GFX-06-07`, `GFX-06-10`, `GFX-07-02`, `GFX-07-03`, `GFX-10-06`, `GFX-11-T05`.

### Явно отложенные функции — `P2-EXPLICITLY-DEFERRED` (2)

**Когда возвращать в работу:** Отдельное решение владельца о возвращении именно этой возможности. VNS5-08 — только самостоятельный каталог VN-пропсов, не физические map props.

**Решение:** Retain existing deferred status, no implied replacement or acceptance.

**Задачи:** `RM-GAP-004`, `VNS5-08`.

### Обязательные проверки финального сезона (позже) — `P2-FULL-SEASON-RELEASE` (12)

**Когда возвращать в работу:** Полный сезонный контент и технические зависимости готовы к release-candidate; перед публикацией выполнить каждый gate и сохранить устройство/арты/лицензии/текстовое QA.

**Решение:** Not optional at full-season release; merely not on current Hall vertical-slice critical path.

**Задачи:** `CODE-13-01`, `GFX-13-T01`, `GFX-13-T02`, `GFX-13-T03`, `GFX-13-T04`, `GFX-13-T05`, `GFX-13-T06`, `GFX-13-T07`, `GFX-13-T08`, `GFX-13-T09`, `GFX-13-T10`, `GFX-13-T11`.

## 4. Как фиксировать evidence и не закрывать лишнее

- **CI:** ссылка на GitHub Actions **на точном commit SHA** и имена прошедших тестов; указывать, что headless тесты не проверяют native pointer, эстетическую читаемость или touch на физическом устройстве.
- **Manual:** дата, версия Godot/устройство и разрешение, сценарий, ожидаемое и фактическое поведение, screenshots/видео, решение владельца. При отсутствии evidence — `qaState=manual_pending`, а не `manual_verified`.
- **Art:** только точный accepted catalog ID; новые map-chibi, фактические map prop states и M3 tile set требуют отдельного approval и не получают его от VN WebP.
- **Status:** править `production_progress.json` и `gap_work_packages.json` согласованно, не восстанавливать старый CODE `PROPOSAL_NOT_RUNTIME` как live truth. После каждого PR запускать `reconcile_gap_statuses.py`, `validate_backlog_dependencies.py`, `validate_active_workstreams.py`, `validate_backlog_acceptance.py`.
- **PR review:** не продвигать draft three-way Story Map в канон без явного решения; не закрывать широкие [issues #2, #3, #21, #121, #129](https://github.com/bezdredoff/RavenManor-Godot/issues) до проверки каждого relevant gate.

## 5. Текущее решение по scope

**Никаких новых артовых batch jobs и игровых изменений в рамках аудита.** Вертикальный срез остаётся задачей отдельных P0/P1 gates: реальные свайпы/подсказки и Help, физическая Hall-карта, нужные map-чиби и props, нативная приёмка. Полный сезон остаётся отдельной обязательной release-проверкой `P2-FULL-SEASON-RELEASE`, даже если его gates пока не P0.

