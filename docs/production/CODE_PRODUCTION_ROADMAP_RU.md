# Raven Manor — план и roadmap производства кода

**Версия:** 0.2 (reconciliation; исходные этапы и требования сохранены)  
**Дата:** 27 октября 2026  
**Статус:** действующий engineering production plan; фактическое исполнение и evidence ведутся в `data/raven/production/production_progress.json`, а не выводятся из наличия пункта плана.  
**Парный план:** `docs/production/GRAPHICS_PRODUCTION_ROADMAP_RU.md` (GFX-00…GFX-13, версия 0.1 от 27.10.2026).  
**Цель:** довести первый сезон Raven Manor до production-ready Godot 4.7.2 через **максимальное переиспользование реального кода UPDS-godot**, добавив только уникальные механики исследуемой карты особняка, комнат, NPC, предметов и восстановления. Проводить art/code интеграцию вертикальными срезами и не масштабировать производство до совместного Hall pilot gate.

## 1. Главное решение

**UPDS = технический базис, Raven Manor = рескин/новые данные плюс отдельный слой карты и метапрогрессии.**

1. Не переписывать с нуля отлаженные UPDS функции VN, Match-3, input/drag, motion, accessibility, настройки, аудио, локализацию, UI, тесты и Web, если их можно изолировать.
2. Предпочитать UPDS исходный модуль без изменений → выделенный переиспользуемый компонент → Raven adapter → новый код только если функция действительно специфична или переносить опаснее.
3. **Не копировать монолит без анализа зависимостей:** `vn_screen.gd` (~102 КБ) и `match3_screen.gd` (~152 КБ) связаны с UPDS-презентацией, графикой и историей. Сначала отделить common renderer/controller от school-specific контента; затем подставить Raven data/art/theme/adapter.
4. Единственный владелец Raven campaign/room state — `RavenReducer / RavenSnapshot / RavenCampaignStore`. Нельзя одновременно использовать UPDS StorySession/SaveFormat как вторую систему авторитетного сохранения. UPDS session/UI использовать через порты и репозиторий состояния Raven.
5. Не ломать работающий `RM-VS-01` ради архитектуры: прежние `RM-*` IDs, денежный контракт 2/2/2 награды и 2/4 стоимости, история и загрузка старых сохранений — регрессия каждого PR.
6. Код должен быть готов **к принятию арта**, а не зависеть от завершения GFX. Заглушки, reference images и fallback не становятся approved production art.
7. Массовое написание контента II–VI начинается после **CODE-11 × GFX-11** совместного pilot approval.

План опирается на проверенные исходники `bezdredoff/UPDS-godot` и текущий `bezdredoff/RavenManor-Godot`, а не на утверждение, что все функции UPDS уже интегрированы в Raven.

## 2. Базовый статус при первоначальном составлении плана (историческая запись)

Следующие пункты фиксируют исходное состояние в момент написания версии 0.1. **Текущий статус приведён в разделе 2A ниже**; историческое указание «PR #46 открыт» нельзя считать актуальным.

- **В `main` Raven:** Godot standalone `RM-VS-01` с прологом/главой I, 3 игровыми уровнями, 2 restorations, сохранением и навигацией; Chapter-II Hall tea VN pilot `RM-BEAT-02-01` с 12 линиями RU/BE/EN и временными арт-слоями. Изолированные Room Builder, карта сезона в режиме feasibility и Hall render/import существуют; их координаты/арт всё ещё требуют acceptance.
- **На уровне документации:** 28 предложенных story scenes, 280 source RU dialogue lines, 11 background families, 37 story prop families, 28 inspect popups, character/cue/staging registries в `data/raven/production/`. Большинство `be/en` реплик будущих глав не переведено. Эти JSON не следует считать полностью подключёнными к игровому runtime.
- **UPDS действительно имеет:** `scripts/match3/match3_game.gd` (спецфишки, каскады, board holes, блокеры, подсказки, deterministic RNG), `match3_screen.gd`, `match3_tile_motion_layer.gd`, `match3_board_shape.gd`, `match3_tutorials.gd`, `match3_reaction_runtime.gd`; `scripts/vn/vn_screen.gd`, `dialogue_paging.gd`, `portrait_motion_rig.gd`; `scripts/ui/player_preferences.gd`, `settings_screen.gd`, `menu_audio.gd`; `scripts/core/story_session.gd`, `save_format.gd`, `reduced_motion.gd`. Названия конкретных API проверять по pinned source, а не предполагать их совместимость.
- **PR #46** (ветка `refactor/upds-core-reuse-phase1`) уже подготовлен и проходит CI, **но на 27.10 остаётся OPEN / NOT MERGED**. Он приносит оригинальные правила Match-3, paging, RNG и preferences. Работу CODE-01 начинать с review/merge либо пересборки PR #46 против последнего `main`, **не создавать независимый второй перенос**.
- Старый `docs/UPDS_COMPONENT_ADAPTATION.md` описывает исторический минимальный Raven-only движок и **не отражает целевую архитектуру**; не использовать его как текущий reuse-стандарт. Целевой документ в PR #46 — `docs/production/UPDS_CODE_REUSE_ARCHITECTURE.md`.

**Состояния задач:** `proposed → ready → in_progress → PR_review → merged → integrated → device_verified → accepted`. Прошедший unit/smoke test не равен device-approved продуктовой функции.

## 2A. Текущее состояние после мержа PR #54 и #56 (27.10.2026)

- **PR #46 merged:** правила Match-3, RNG, VN paging и preferences из UPDS работают через оригинальные компоненты и Raven adapters. Их наличие **не** означает готовый UPDS Match-3/VN экран.
- **PR #54 merged — CODE-02-00:** оригинальные `match3_board_shape.gd`, `match3_tile_motion_layer.gd`, `match3_tutorials.gd`, `css_motion.gd`, `match3_tile_motion_layer.tscn` и component smoke добавлены в Raven с pinned исходными SHA. Это промежуточный завершённый пакет.
- **CODE-02-01/02 — in_progress:** input/drag/swipe, полный board cell presenter, каскады, спецкомбинации, HUD/feedback, мобильный QA и подключение к действующему Raven level ещё не завершены. Следующий PR должен выделить из оригинального UPDS Match3Screen его общие контроллеры/UI, а не написать новый Raven-specific экран.
- **PR #56 merged — mobile handoff evidence:** физическая загрузка ZIP в `incoming`, автоматический PR #55, независимый Godot/UPDS/Room Builder/Web CI и non-deployed artifact подтверждены. PR #55 закрыт без мержа. **MOB-04 остаётся in_progress** для live-negative ZIP cases, phone artifact review и device acceptance; `/preview/` — безопасный просмотр CI, а не исполняемый candidate.
- **Graphics GFX-10 пока proposed:** кодовые анимационные примитивы `CODE-02-00` не утверждают тайлы, блокеры, FX или визуальный стиль. Масштабирование требует самостоятельных GFX gates.
- Источник текущих фактов — `production_progress.json`; [PR #54](https://github.com/bezdredoff/RavenManor-Godot/pull/54), [PR #56](https://github.com/bezdredoff/RavenManor-Godot/pull/56) и связанные Actions. Зелёный CI != human acceptance.

## 3. Архитектура и границы ответственности

```text
                          ART PRODUCTION (GFX-00..GFX-13)
   identity / style / VN frames / map sprites / rooms / props / tile set
                              │ accepted manifests
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                  SHARED UPDS-ORIGIN GAMEPLAY                         │
│ VN presenter + paging + controls + portrait motion                 │
│ Match-3 rules + swipe/render frames + specials + tutorial          │
│ Settings + localization + sound/haptics + accessibility + Web      │
└────────────────────────────┬────────────────────────────────────────┘
                             │ typed interfaces, no UPDS story IDs
           ┌─────────────────┼──────────────────────┐
           ▼                 ▼                      ▼
     Raven content       Raven theme             Raven progress
     28 beats, 8 tiles   sprites, sound, UI       reducer + atomic save
     37 props, popups    backgrounds/states       objectives + workPoints
           └─────────────────┬──────────────────────┘
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                       RAVEN-ONLY GAMEPLAY                            │
│ authored manor map / hotspots / A* route / room builder import      │
│ NPC position+schedule / object state / physical safety gates         │
│ restoration board / specialist jobs / interact→VN→Match-3 loop       │
└─────────────────────────────────────────────────────────────────────┘
```

### Технические интерфейсы (согласовать до кодирования)

| Контракт | Вход | Выход / кто владеет состоянием |
|---|---|---|
| `IVnSceneProvider` | `sceneId`, `lineId`, `locale`, staging manifest | speaker/text, background/slots, expression/pose/micro/prop; изменение чтения только Raven story adapter |
| `IMatch3LevelProvider` | `RM-LVL-*`, Raven config, active tile subset | UPDS normalized level: objectives[], activeTiles[], boardHoles[], blockers[], seed |
| `IMatch3ResultSink` | levelId, win/loss, attempt token, analytics | ровно одно reducer-событие `level_won`; награда idempotent, не в UI и не в tile renderer |
| `ISettingsProvider` | `ru/be/en`, audio/music/effects, reduced motion | UPDS preferences или адаптер; язык не меняет story ID |
| `IManorInteraction` | hotspot/door/NPC/object ID + world state | available/locked/revisit, target approach anchor, popup text ID, action type |
| `IRoomSceneProvider` | roomId, room-state snapshot, accepted asset manifest | карта, маски/слои, hotspots, pivots, physical geometry из независимого authority |
| `IActorPresentation` | actor ID, map/VN mode, cue or target position | renderer/game animation; не пишет сюжетный прогресс |
| `IProductionAssetResolver` | accepted asset ID, presentation, variant, state | texture/atlas/frames/pivot + fallback + errors/validation |
| `ICampaignProgress` | eventId, typed domain event | atomic Raven state + save; read-only snapshot для всех остальных компонентов |

Не обязательно объявлять буквальные GDScript interfaces с такими именами. Это **имена границ модулей** и обязательный контракт тестирования.

## 4. Матрица «перенести / адаптировать / создать»

| Подсистема | Источник UPDS | Стратегия | Что Raven добавляет | Степень готовности |
|---|---|---|---|---|
| Match-3 rules + hints, blockers, specials, cascades | `scripts/match3/match3_game.gd`, `scripts/core/seeded_random.gd` | **vendor exact / thin adapter** | JSON уровней, фикс. 8 типов, workPoints | **PR #46 merged**; game rules core integrated, full visual UI pending |
| Match-3 input, swap, board shape, animations, HUD | `match3_screen.gd`, `match3_board_shape.gd`, `match3_tile_motion_layer.gd` | **extract common UI + reskin** | gothic-art/sound, map result callback | **PR #54 merged board shape/motion primitives; full screen/input/HUD pending** |
| Match-3 tutorials, reactions, help, intro/result | `match3_tutorials.gd`, `match3_help_overlay.gd`, `match3_reaction_runtime.gd`, `match3_campaign_screen.gd` | **extract / content adapter** | story-based intro and room fiction | **PR #54 merged tutorial predicates only; help/screens/reactions pending** |
| VN pagination, layout, animation, auto/skip/history | `scripts/vn/dialogue_paging.gd`, `vn_screen.gd`, `portrait_motion_rig.gd` | **vendor paging, extract controllers/renderers** | 1–3 actor slots, cues, backgrounds | **paging merged in PR #46**; остальные pending |
| Preferences, settings UI, audio feedback | `player_preferences.gd`, `settings_screen.gd`, `menu_audio.gd` | **vendor logic / reskin UI / isolate audio** | RU default, gothic copy, save-path | **preferences merged in PR #46**; UI pending |
| Reusable UI layout, fonts, touch and motion | `phone_frame.gd`, `touch_scroll_container.gd`, `ui_fonts.gd`, `css_motion.gd`, `reduced_motion.gd` | **reuse/extract** | Raven palette, portrait-safe areas | **CSS easing merged in PR #54**; остальная адаптация pending |
| Story/campaign state & persistence | UPDS `story_session.gd`, `save_format.gd`, `campaign_store.gd` | **reuse patterns + algorithms, NOT a second save authority** | atomic Raven reducer, stable IDs, restoration | Raven implementation already active |
| Character asset layout / animation | UPDS `actor_layout_catalog.gd`, `portrait_motion_rig.gd` | **extract common layout/rig** | Raven identity/cues, map sprites | rig pending; pilot only fade |
| Map, graph navigation, Room Builder import | no UPDS manor equivalent | **Raven-only** | 65° map, authored routes, colliders, depth | engineering prototype; production calibration pending |
| NPC waiting/behavior, service jobs | no equivalent confirmed | **Raven-only** | Lucas evenings, Ada house, Rowan garden, specialists | production implementation pending |
| Restore/interactable object state machine | no UPDS manor equivalent | **Raven-only** | 37 props, restoration cost and visual states | baseline slice only |
| Platform builds, Web/offline QA, instrumentation | UPDS `scripts/check.sh` and `scripts/platform/` | **reuse practices, adapter on actual targets** | Raven PWA/Pages/export | current Raven CI present; parity expansion pending |

**Do not import:** UPDS school story, its actors, narrative scene indexes, art backgrounds, serialized progression, ad/reward behavior or platform identifiers just because they are dependencies of an imported screen. В частности, Playgama ads не являются автоматическим требованием Raven.

## 5. Этапы, задачи и engineering gates

### CODE-00 — Инвентаризация, import policy и baseline

**Параллельно GFX-00.** Сформировать source→destination manifest для reuse: upstream path, pinned blob SHA, state `verbatim / extracted / adapted`, transitive dependencies, лицензия/provenance, тестовый оракул, Raven binding. Снять baseline `main`: CI, `RM-VS-01`, Chapter-II Hall pilot, schema, Web export, screenshot reference для 390×844/412×915/430×932/tablet.

- `CODE-00-01` Проверить текущий статус PR #46 и актуальность его branch относительно `main`; выделить миграционные изменения от содержимого игры.
- `CODE-00-02` Сделать аудит всех UPDS компонентов (VN, Match-3, settings, input, audio, responsive, saving, Web). Разделить reusable ядро и game-specific dependencies.
- `CODE-00-03` Утвердить provider/sink contracts из `4` и единый Raven reducer ownership.
- `CODE-00-04` Создать compatibility/release test matrix и место для provenance/rollbacks.
- `CODE-00-05` Замерить `RM-VS-01` и Hall pilot с сохранением до и после работы; не выдавать отсутствие real-device замеров за факт.

**Gate C0:** известна судьба каждой значимой UPDS подсистемы; кодовые PR имеют источник, interface, regressions и rollback; «уже есть в UPDS» не считается автоматически «уже работает в Raven».

### CODE-01 — Перенос реального ядра UPDS Match-3, RNG, paging, preferences

**Зависит от C0; рабочая основа PR #46.**

- `CODE-01-01` Review/merge PR #46 с pinned source и безопасной синхронизацией с последним `main`.
- `CODE-01-02` Сохранить upstream rules/seeded RNG/dialogue paging без локальных fork-правок, где возможно; отличия через тонкие Raven adapters.
- `CODE-01-03` Подключить `RM-LVL-001..003` к UPDS game через `tiles→activeTiles`, `objective→objectives[]`, `boardHoles`, `blockers` и rewards-sink.
- `CODE-01-04` Провести parity: начальное поле, legal/invalid swap, cascading, win/loss, reshuffle, hint, blocker, special creation/combination и fixed seeds, включая UPDS fixture vectors.
- `CODE-01-05` Проверить idempotent win awards и старые Raven save slots; без изменения economy/save schema.
- `CODE-01-06` Подключить sentence-safe paging к Hall pilot и сохранять current line при смене языка.

**Gate C1 — RULES PARITY:** существующие три уровня выигрываются на старых сейвах; результаты boards/gameplay для одинаковых inputs детерминированны, UPDS regression и Raven smoke green; исходные engine rules не дублируются.

### CODE-02 — Общий Match-3 экран, touch, boosters и feedback

**Подготовка к GFX-10, не требует финального tile art.** Следующий кандидат CODE-02 input/frame (`code/code-02-upds-match3-interactive-board`) переносит UPDS drag model с порогом 24%, воспроизводит engine swap/clear/settle/reshuffle на общем presenter и подключается к `RM-VS-01`. До проверки CI и реального device QA эта работа остаётся `PR_review`, не `accepted`. Подзадача `CODE-02-00` (перенос неизменённых UI primitives UPDS, PR #54) смержена; `CODE-02-01/02` остаются в работе до полной integration/mobile QA.

- `CODE-02-01` Выделить input model свайп/тап, drag threshold, invalid feedback и touch capture из UPDS `match3_screen.gd`, сохранив keyboard/mouse fallback.
- `CODE-02-02` Переиспользовать `match3_board_shape.gd`: authored shape, holes, board masks, масштаб мобильного портрета.
- `CODE-02-03` Подключить UPDS `match3_tile_motion_layer.gd`/frame player к swap, matched clear, cascade, fall, reshuffle и specials. Убрать legacy статические цветные кнопки как основной экран.
- `CODE-02-04` Переиспользовать objective HUD/tutorial/help/win/loss/retry/level summary, заменить текст и графику адаптерами Raven.
- `CODE-02-05` Реализовать source-configurable восемь обычных tile IDs (candle, key, rose, book, raven, cup, brooch, quill); 5–6 на уровне, а не тематические виды под каждую комнату.
- `CODE-02-06` Вынести в конфиг три blocker families (cobweb, crate 1–2 hits, chain) и specials. Убедиться, что различаются реальные механики, а не только названия/иконки.
- `CODE-02-07` Подключить shared motion/sound/reduced motion, временные изображения и затем accepted `GFX-10` textures/FX. Сохранять приятные цепочки анимаций, а не усиливать тряску.
- `CODE-02-08` Проверить 390×844, 412×915, 430×932, tablet; подсказки, reshuffle, dead-board, специальные комбо, readability/board-occlusion.

**Gate C2 — REUSABLE M3 SCREEN:** одна и та же gameplay-сцена решает существующий Raven уровень и UPDS-inspired механические тестовые уровни с shapes/blockers/specials без изменения кода; touch/drag, каскады и UI проходят mobile proof. Final art acceptance отдельно на G10.

### CODE-03 — Общий VN presenter + controls вместо Hall-only экрана

**Подготовка к GFX-06, GFX-08 и GFX-11.**

- `CODE-03-01` Разделить UPDS `vn_screen.gd` на общие input/flow, dialogue renderer, background presenter, portrait slots и controls; школьные сюжетные `preload` и страницы отделить.
- `CODE-03-02` Подключить UPDS pagination и 1–3 portrait layout, `left/center/right`, resize/reflow, priority/focal speaker, offscreen lines, portrait-first safe areas.
- `CODE-03-03` Переиспользовать history, Auto, Skip-read-only, save/load/restore, read-state, optional choices и input navigation; Raven сцены адресуются по `RM-BEAT-*` и `lineId`, не по UPDS numeric scene indexes.
- `CODE-03-04` Переиспользовать `portrait_motion_rig.gd` и общие микродвижения, расширить **данными**, а не if-ветками: pose/emotion/gesture, 3–6 keyframes, prop overlay, reduced motion. В первом slice достаточно фактически принятых кадров.
- `CODE-03-05` Подключить staging/background registry (`vn_staging.json`, `line_performance_cues.json`) и fallback для отсутствующих approved art variants.
- `CODE-03-06` Заменить независимый `hall_tea_vn.gd` на экземпляр общего presenter с Raven theme/scene provider; избегать параллельных кодовых путей.
- `CODE-03-07` Проверить переходы scene/line/page, историю диалогов, смену языка во время строки, сохранение в середине длинного диалога, отсутствие двойных жестов/звуков при resume.

**Gate C3 — VN CORE PARITY:** Hall pilot воспроизводится через единый UPDS-origin renderer; историю, Auto/Skip, 1/2/3 portraits, language reflow и resume проверяют автоматические сценарии; отдельных hardcoded VN screens на каждую комнату нет.

### CODE-04 — Настройки, локализация, аудио, accessibility

**Подготовка к GFX-10/11.**

- `CODE-04-01` Использовать UPDS `player_preferences.gd` для locale/music/effects/mute/haptics. Вывести настройки из Prototype Lab в основной runtime; сохранить текущий Raven preference-file migration.
- `CODE-04-02` Выделить из UPDS `settings_screen.gd` reusable widgets (language, sound sliders, mute, haptics, navigation), с Raven UI theme и собственными текстами.
- `CODE-04-03` Общий dispatcher текстов: VN lines, speaker names, scene titles, journal, popup, objectives, actions и inventory state labels в `ru/be/en` с immutable keys и RU fallback только для development.
- `CODE-04-04` Использовать UPDS аудио/feedback, разрешать muted/reduced motion, pause/background/resume; исключить несанкционированное автопроигрывание звука на mobile Web.
- `CODE-04-05` Фонты с латиницей/кириллицей и белорусскими `і/ў`, реальный перенос строк и отсутствие обрезания в узких панелях.
- `CODE-04-06` Перевести и проверить остальные диалоги (большинство из 280 RU строк пока TODO для BE/EN), сцены, popups и позже quests/goals; использовать `export_translation_worklist.py`.
- `CODE-04-07` Строгий локализационный release gate: **0 обязательных пустых ключей**, native QA, safe input at all viewports.

**Gate C4 — SETTINGS/LOCALE:** язык и аудио сохраняются между запусками; изменение языка не сбрасывает line/campaign state; missing strings явно отслеживаются; pre-release QA может работать с fallback, release — нет.

### CODE-05 — Room Builder → Godot карта и production-геометрия

**Raven-only. Прямой стык с GFX-07/GFX-08 и `RM-PIPE-001`.**

- `CODE-05-01` Утвердить один строгий export JSON contract: room/door/hotspot/asset IDs, local→world transform, anchor, pivot, collider, occluder, Z-depth, visual variants. Build importer **preview-first**, без мутации runtime.
- `CODE-05-02` Не смешивать `manor_greybox_graph.json` (RM-VS-01 authored anchor graph) с `season1_world_map.json` (feasibility AStarGrid2D). Согласовать приоритет и проверяемый миграционный путь после art/geometry approval.
- `CODE-05-03` Сверить физически Hall doors, stair bounds, clock, две отдельные chairs/round table и corridor access с текущей Room Builder scene и 65°/0.74× mobile camera.
- `CODE-05-04` Проверить точную маршрутизацию от target click до approach anchor, физические door/safety gates, collision blocking, actor occlusion, foreground sorting и room-state variants.
- `CODE-05-05` Добавить гарантии JSON round-trip, import diff, invalid IDs/bounds, rollback, manual art-state override без silent change nav/collider.
- `CODE-05-06` Подключить аналогичный pipeline к Corridor/Bedroom **только после** принятой Hall geometry; bath остаётся corridor vignette в текущем slice.

**Gate C5 — MAP GEOMETRY:** Hall→Corridor→Bedroom маршруты, открытые/закрытые двери, occlusion, два кресла и столик, collisions, импорт и re-export проходят тесты и human screenshot review; layout accepted отдельно на G8. Нет free tap-to-move.

### CODE-06 — NPC staging, движения и микроанимации на карте

**Raven-only поведение, переиспользуемые motion primitives UPDS, стык с GFX-07.**

- `CODE-06-01` Map actor contract: canonical ID, active room/phase, spawn anchor, wait anchor, walk clips, target interaction, blocking rules.
- `CODE-06-02` Эвелин: reuse общего animation player, authored graph route, down/up/side/turn, inspect, pickup, interact, foot pivot; убрать Onoe после approval G7.
- `CODE-06-03` Ада/Роуэн: limited walker, один маршрут и one-shot signature action; Лукас: initially static/short approach, встречи **после заката**.
- `CODE-06-04` NPC cannot block exit/door/level target; no spawning behind physical gates; wait pose and orientation valid after save/resume.
- `CODE-06-05` No automated supernatural reveals; animation and spawn logic не показывают ghost/vampire/wolf identity прежде сюжетного решения.

**Gate C6 — NPC ROUTES:** четыре героя проходят минимальные состояния `map_narrative_routes.json`, включая идемпотентный повтор взаимодействия; identity/feet occlusion и motion approval отдельно по G7.

### CODE-07 — Objects, clue inserts, state overlays, repair interaction

**Raven-only gameplay, презентация общими UI. Стык с GFX-09.**

- `CODE-07-01` Связать все 37 logical `story_props.json` families с map instance ID, VN insert ID, visual state, inspect popup, narration/staging; не плодить дубли объектов.
- `CODE-07-02` Единый interaction pipeline: tap hotspot → route Evelyn → arrive → localized inspect → available actions → VN/Match-3/repair → reducer event → redraw room.
- `CODE-07-03` Состояния blocked/clear, dusty/clean, power_off/partial, broken/safe, hidden/discovered и соответствующие visual overlays из approved manifests.
- `CODE-07-04` Отличать prepared work points от реальных ремонтных работ специалиста: plumber/electrician/glazier/structural/clock; не «чинить» от match цвета.
- `CODE-07-05` Добавить safety и repeat/read-only policy для найденных писем, фотографий, дневника, детской карты, мокрого архива.
- `CODE-07-06` Никакой repaint/import/animation callback не пишет прогресс: state transitions только через reducer + event IDs.

**Gate C7 — OBJECT STATE:** выбранный объект верно отображается в VN, на карте и в close-up, переключается только валидным событием и сохраняет состояние после reload; повторное нажатие не даёт повторную награду.

### CODE-08 — Season flow / meta economy / migration

**Raven-only orchestration поверх UPDS UI.**

- `CODE-08-01` Машинный `28-scene` runtime story graph: prerequisites, visit/revisit, day/night phase, offscreen speaker, cooldown только если явно утверждён сюжетом.
- `CODE-08-02` Связать progression `VN → preparation level → win award → restoration offer → specialist visit → room state → next beat`; UI не знает цены и не назначает rewards.
- `CODE-08-03` Уровни получают stable `RM-LVL-*` и авторские masks/blocks/objectives из UPDS engine, но не произвольные новые tile categories или доп. валюты.
- `CODE-08-04` Сохранить first-slice ID/economy; новые scene/room/prop/repair ids регистрировать только после content approval. Формализовать schemaVersion + migration/rollback для изменяемого мира.
- `CODE-08-05` Системы retry/resume, main menu, save/load, replay scene, skip-read-only и duplicate events; корректный переход назад на карту при прерывании.
- `CODE-08-06` Полные QA сценарии: новая игра, продолжение старой, выигрыш/проигрыш, invalid taps, gated doors, optional inspection, chapter boundary, language switch.

**Gate C8 — PROGRESSION:** детерминированный full-route `RM-VS-01` и один следующий beat после него отрабатывают на fresh/old save без soft-lock, double reward, bypass physical gate и без DLC/content spoilers.

### CODE-09 — Production asset manifest, runtime renderer и placeholder policy

**Стык GFX-00/GFX-05/GFX-06/GFX-08/GFX-09/GFX-10.**

- `CODE-09-01` Согласовать с GFX immutable inputs, output manifests и `planned→…→accepted` statuses; runtime читает только accepted/game-ready assets, кроме явного preview mode.
- `CODE-09-02` Asset resolver: `assetId + presentation(VN/map/insert/tile) + state + locale(optional)` → texture/atlas, anchor, pivot, frames/duration, occlusion layer; missing fallback и diagnostics.
- `CODE-09-03` Валидация alpha/premultiply/size/texture compression, feet pivot, silhouette flip, z-depth, safe camera/crop, known source SHA/license.
- `CODE-09-04` Автоматический smoke import prefab на одну pose, emotion, prop overlay, map walk, tile state. Проверка разрешённого reduced-motion fallback.
- `CODE-09-05` Экспорт проверяемых screenshots/contact overlays для ревью человека на GFX-11.

**Gate C9 — ART HANDOFF:** accepted asset можно заменить/перегенерировать по manifest без изменения кода контроллера или сюжетных ID; неaccepted graphic не утекает в release export.

### CODE-10 — Platform, UI, observability и dev-experience

**UPDS-origin utility reuse; GFX-13 / release readiness.**

- `CODE-10-01` Extract shared phone-frame sizing, orientation/safe-area, responsive controls, labels, contrast, touch targets, focus and keyboard fallback.
- `CODE-10-02` Web/PWA build: cache strategy, offline startup, update/reload behavior и sanity Web export. Browser/Playgama capabilities — capability-detected, без скрытого ad dependency.
- `CODE-10-03` Logging/invariant diagnostics: missing art keys, locale fallback, failed event, unreachable hotspot, invalid current room/actor; redact private data.
- `CODE-10-04` Analytics only for defined opt-in/use cases: VN page/scene completion, Match-3 retry/hint, restoration/room transition, input faults; platform/privacy decisions separately.
- `CODE-10-05` Developer review tools: hot reload/lookups for scene/prop/actor, preview at selected time-of-day/state/locale, deterministic debug seed (never overriding game save).
- `CODE-10-06` CI layers: unit → asset/schema validation → integration/old saves → screen render/screenshot → mobile manual/device. Attach source revision and relevant evidence to PR.

**Gate C10 — OPERATIONAL:** Web build can boot offline after install, resumes saves, reports missing content, renders correct responsive layouts, has no unapproved third-party coupling; device evidence collected.

### CODE-11 — Совместный Hall end-to-end pilot

**Критический стык с GFX-11, не равен старому Hall tea art prototype.**

Пилот **обязательно** содержит принятые: Hall фон/состояние, VN Эвелин + Ада (≥2 позы и ≥3 эмоции каждой), два сюжетных keyframe-жеста, tea/letter prop, map-Эвелин + staging Ады, 1 popup и 1 evidence/prop insert, пригодный Map→VN→Match-3→state переход, RU/BE/EN geometry, reduced-motion и resume. Эстетические критерии — из GFX-11; технические — C1…C10.

- `CODE-11-01` Заменить Hall-only hardcoded UI единым VN renderer, реальными accepted asset IDs и позами.
- `CODE-11-02` Настроить approved map anchors/colliders/occlusion, walk and NPC wait, валидный popup после route.
- `CODE-11-03` Подключить UPDS Match-3 экран и результат к подготовительной работе, а состояние Hall объекта — через reducer (не визуальным скриптом).
- `CODE-11-04` Проверить phone/tablet RU/BE/EN, частичный выход, replay, reduced-motion, звук и offline restart.
- `CODE-11-05` Измерить стоимость одного accepted pose/expression/gesture/background/prop (generation + art review + correction + integration/device QA) и одной типовой игровой сцены; переоценить scope/PR batch.

**Gate C11 × G11 — SCALE-OUT APPROVAL:** реальная игра, а не набор разрозненных демо. Формальное «принять / отправить на доработку / отклонить». Без двух approvals массовая глава II–VI не запускается.

### CODE-12 — Продакшен по главам и room waves

**Совместно GFX-12, после C11/G11.** Один reusable renderer, один Match-3 screen, один data-driven director и map state engine; новые главы должны состоять в основном из данных, сцено-расстановки, новых room assets/level configs и ограниченных interaction hooks.

| Волна | Нарратив/локация | Engineering deliverable | Арт-зависимость |
|---|---|---|---|
| **W0 / pilot** | Пролог + I: Entry/Hall/Corridor/Bedroom/Bath vignette | основные VN, навигация, save, три Match-3 уровня, восстановление + один Hall pilot | G4/G5/G6/G8/G11 |
| **W1** | II: Kitchen и Rowan entry | доп. anchors, NPC, lighting partial/off, ledger, electrician gates, 2.1+ остальные II | G7/G8/G9 |
| **W2** | III: Library/Archive | evidence journal, photo/postcards/unsigned letter, evening Lucas NPC, staged VN | G6/G8/G9 |
| **W3** | IV: Garden/Conservatory | safe entry/exit, outdoor route, specialists/glass state, childhood box/map, evening weather cues | G7/G8/G9 |
| **W4** | V: storm + wet archive | explicit time phase, damage/repair states, paper rescue visual overlays, no new emergency minigame | G8/G9 |
| **W5** | VI: stay/estate + epilogue | irreversible narrative decision captured correctly, repair roadmap, estate forms, diary, optional postcredits | G6/G9 |
| **RC** | Entire season | QA sweep, localization, save migrations, fallback purge, screenshots, release export | G13 |

Каждая волна: `planned → data_authoring → functional → integrated_art → narrative_QA → device_QA → accepted`. Утверждённые GUI systems не форкаются между главами.

**Gate C12:** глава II даёт доказательство reuse, далее каждая волна проходит scene inventory, one-shot/revisit/old-save gates и проверку одних и тех же VN/Match-3 систем. Никакой новой уникальной механики ради одного диалога без review.

### CODE-13 — Финальный инженерный QA, локализация и RC

- Зафиксировать все обязательные сезоном события, кнопки, room/object states, sound and art manifests.
- Пройти `28 VN scenes` + replay + interruption; составить mapping к сценарным событиям с обязательным и optional visibility.
- Выполнить RU/BE/EN content/overflow proof: **в production ноль пустых обязательных локализованных строк**, кроме отдельно утверждённого fallback design.
- Проверить touch, drag, cancel, input-lock, boosters, hints/reshuffles, offboard, special combos, three blocker families and all authored board holes.
- Сохранять/загружать `old RM-VS-01` сейвы, interrupted scene, unsolved level, partially restored room, chapter finish; не терять потраченные ресурсы и не выдавать дубли.
- Проверить time phases (Lucas after dark), no early supernatural reveals, физическую правдоподобность repair gates, профессиональные работы и отсутствие tap-to-ground.
- Проверить 390×844, 412×915, 430×932 и tablet + выбранные реальные Android/iPhone устройства; Web/PWA/offline/keyboard/reduced-motion.
- Профилировать load time, frame budget, memory/Web export size и overlay texture count; **численные лимиты установить после C11 на реально измеренных устройствах**, не придумывать сейчас.
- Собрать release evidence package (commit hashes UPDS/Raven, schema version, asset manifests, QA screenshots, test reports, provenance/licensing, rollback plan).

**Gate C13 × G13 — GAME RC:** никаких placeholder assets в опубликованных обязательных сценах; zero blocking defects; английская/белорусская/русская версия прошла QA; совместимость save подтверждена; reviewer даёт явное разрешение на release.

## 6. Матрица зависимости code ↔ graphics

| Graphics gate | Engineering gate / deliverable | Что можно делать до принятия арта | Запрет на scale-out |
|---|---|---|---|
| **G0** Ledger, IDs, naming, formats | **C0** pinned upstream, schema, asset API | все общие UPDS модули и CI | нет контракта identity/IDs |
| **G1/G2/G3** tool/model/style | C1–C4 UPDS rules/paging/UI/locales | механика/рендеринг на placeholders | финальные персонажные текстуры без style lock |
| **G4** 4 character identity packs | C3/C6 animation and staging API | staging и preview renderer | финальные map/VN актеры до identity lock |
| **G5** production workflow + Godot manifest | **C9** importer/asset resolver | smoke на тестовых frames | партия без deterministic export/ID mapping |
| **G6** poses/emotions/keyframes | **C3/C9** VN cue renderer | общая микроанимация, timeline и reduced motion | production жесты без approved keyframes |
| **G7** map chibi walkers | **C5/C6** routes, foot pivots | routes/spawns/walker rig на заглушке | замена Оноэ без G7/device approval |
| **G8** room/map/VN art states | **C5/C7/C9** geometry/state/occlusion | Room Builder importer, pilot masks | комнаты без door/collider parity |
| **G9** story props | **C7/C9** prop/insert presenters | объектные IDs, state machine, inspect | prop, не связанный с map/VN identity |
| **G10** 8 tiles and effects | **C2/C4/C9** UPDS match UI/sound | full Match-3 с временными tiles | утверждение визуального уровня без читаемости |
| **G11** Hall integrated pilot | **C11** playable vertical slice | полностью функциональный pilot | главы II–VI до обоих gates |
| **G12** chapter wave art | **C12** chapter content waves | authored data, feature-safe placeholders | глава без acceptance |
| **G13** art release QA | **C13** technical/game QA | QA automation and measurements | RC без source/provenance/locale/save passes |

**Особый случай:** GFX-08 делает map and VN **две разные художественные поверхности**. C5/C9 должны соединять их через room/landmark/prop state IDs и pivot/occlusion metadata, а не подменять одну другой.

## 7. Бэклог, критический путь и PR-пакеты

Главный **code critical path**:

```text
C0 inventory/source pin
  → C1 upstream engine parity
    ├── C2 Match-3 shared screen ──────────┐
    ├── C3 VN shared presenter ────────────┤
    ├── C4 settings/audio/localization ────┤
    └── C9 asset resolver ─────────────────┤
C5 room import → C6 NPC map staging ───────┤
C7 props & repairs → C8 save/season flow ──┤
                                          ▼
                                  C11 × GFX-11 Pilot
                                          │
                              C12/GFX-12 chapter waves
                                          │
                                  C13 × GFX-13 RC
```

Границы PR важнее календарной даты. Приоритеты:

**P0 (сейчас):** C0, C1 (PR #46), C2 shared board UI с временными assets, C3 shared VN UI, C4 settings/locale, C5 importer/graph, C9 manifest API, C11 Hall pilot scaffolding. Работы P0 частично параллельны до GFX-03/04.

**P1 (после совместного Hall pilot):** C6 полный map cast, C7 расширение room/prop states, C8 сезонные и экономические связи, W1–W3, translation production.

**P2 (после первых глав):** W4–W5, full content localization proof, UX polish, performance/QA, RC.

**Рекомендуемые первые независимые PR:**

1. **CODE-00:** audit/pinned-source manifest, compatibility matrix, tests baseline; при этом не менять runtime.
2. **CODE-01:** PR #46 смержен; проверить регрессии и donor source pin при каждом обновлении Match-3/VN.
3. **CODE-02A:** board-shape/tile-motion/tutorial primitives смержены в PR #54 (`CODE-02-00`). Следующие PR: input/drag + full board/HUD/cascade/specials с placeholders и блокерами; **не** считать механический demo/full screen уже завершёнными.
4. **CODE-03A:** reusable VN renderer + Hall 2.1 reskin вместо one-off screen, 1–3 sprites, UPDS paging/history/Auto/Skip subset.
5. **CODE-04A:** settings/preferences/localization/audio component extraction с RU/BE/EN тестами.
6. **CODE-09A:** accepted-asset manifests/renderer с GFX-05 export contract, fallback and preview.
7. **CODE-05A:** Room Builder→Godot dry-run calibration для Hall anchors/colliders/occlusion.
8. **CODE-06/07A:** Evelyn/Ada map interactions, tea/letter/evidence prop, specialist-safe state.
9. **CODE-08A:** one true Map→VN→UPDS Match-3→restore→VN data flow, without changing historic RM-VS-01 economy.
10. **CODE-11:** Hall end-to-end screenshot/device gate с GFX-11.
11. **CODE-12:** W1/W2/W3/W4/W5 small chapter PRs, each with assets+data+tests.
12. **CODE-13:** release candidate, three-locale/signoff, save compatibility, accessibility, performance.

Подробные машинно-читаемые work packages в `data/raven/production/code_work_packages.json`. Это **план**, не уже назначенные issues и не выполненные PR. Одна работа может распадаться на несколько небольших reviewable PR.

## 8. QA и definition of done

Для каждого coding PR обязательно:

- **Source provenance:** UPDS file/path/blob SHA либо причина нового кода, adapter boundary, лицензия при переносе asset/data.
- **Scope impact:** список scene/room/actor/level/prop IDs, art contract/gate, новые/изменённые flags и сохранения.
- **Tests run:** реальные команды + результат CI; upstream oracle если менялась общая механика; Raven existing slice regression.
- **Behavior:** happy path, invalid state, replay, cancel/resume, offline where relevant, locale and reduced-motion.
- **Visual:** 390×844, 412×915, 430×932, tablet screenshot/recording for UI/map; разграничение desktop smoke и реального устройства.
- **Rollback:** feature flag или возможность вернуть прежний экран/renderer при сохранении state; no destructive migration без backcompat test.
- **Docs:** обновлены CODE status, GFX dependency, acceptance evidence и известные пробелы.

**Release quality indicators**, собираемые после C11: nonrecoverable save errors; duplicate award count (цель 0); unreachable mandatory hotspots (цель 0); missing translated string count (цель 0 для release); missing accepted asset IDs (цель 0); blocker bugs/scene softlocks (цель 0). Performance thresholds назначать после mobile profiling.

## 9. Оценка нагрузки и точки принятия решений

Оценивать в **S/M/L/XL**, как в графическом плане, а не обещать срок до первого измеренного Hall pilot:

- **S:** адаптер, сценарный ID, 1 popup/prop state, отдельный тест.
- **M:** settings subset, character map gesture, standalone component, localized screen.
- **L:** VN shared presenter, UPDS Match-3 board renderer/input, room importer, full chapter wave.
- **XL:** объединение map/meta + VN/M3 into one coherent gameplay loop, migration of whole save/state, whole season QA.

Для каждой задачи учитывать discovery, extraction, adaptation, tests, device QA, docs. После C11 измерить один реальный S/M/L пакет и составить W0–W5 по доступной capacity.

**Stop rules:**

- Если перенос UPDS требует копирования его school story или скрытого второго save store — остановиться и сначала определить новую границу модуля.
- Если новый код дублирует UPDS gameplay logic — остановиться и объяснить необходимость исключения.
- Если Room Builder importer переписывает утверждённые door/graph/collider states без approval — только dry-run.
- Если изменения `RM-VS-01` ломают старые save/economy/bedroom gate — rollback/repair прежде новой фичи.
- Если в Hall pilot визуально approved asset не совпадает с 65° geometry/foot pivot — не масштабировать на другие комнаты.
- Если обязательный сюжетный контент показывается без проверки prerequisites или допускает ранний supernatural reveal — блокировать merge.
- Если P1/P2 задачи разрастаются до нового универсального toolkit — ограничить выпуском текущего сезона.

## 10. Первые 12 конкретных технических задач

1. Зафиксировать inventory и pinned UPDS/Raven baselines; сопоставить версии обоих репозиториев.
2. Подготовить dependency graph UPDS Match-3 Screen/VN Screen/Settings и список common extraction boundaries.
3. PR #46 уже смержен; продолжать регрессию старых Raven saves и donor parity при переносе визуального Match-3 экрана.
4. Утвердить `IVnSceneProvider / IMatch3LevelProvider / ISettingsProvider / ICampaignProgress` contracts.
5. Создать/зафиксировать source-oracle для Match-3 специальных фишек, board holes, blockers и motion frames.
6. Показать один настоящий UPDS Match-3 screen/render sequence в Raven с фальш-тайлами и phone touch QA.
7. Показать Hall VN 2.1 через общий UPDS-origin presenter с history/auto/skip и language reflow.
8. Подключить общие UPDS language/audio/haptics settings с Russian fallback.
9. Описать accepted art manifest и сделать минимальный Godot asset resolver на тестовом персонаже/prop/room.
10. Провести Room Builder Hall import dry-run с проверкой door/anchor/occlusion/foot pivot.
11. Соединить map→popup→VN→Match-3→reward→restore в одном стабильном flow с тестом replay/save.
12. Совместно с GFX-11 получить Hall pilot на согласованных Эвелин/Аде, 2 keyframe motions, 2 позах/3 эмоциях, мобильных RU/BE/EN viewports; измерить фактическую цену следующих production waves.

После 12-й задачи пересчитать зависимости, batch size и сроки. **Ни одна строка этого документа не утверждает, что P1/P2 уже реализованы.**
